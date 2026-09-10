import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../database/app_database.dart';

import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class VisitorRecognitionPage extends StatefulWidget {
  const VisitorRecognitionPage({super.key});

  @override
  State<VisitorRecognitionPage> createState() => _VisitorRecognitionPageState();
}

class _VisitorRecognitionPageState extends State<VisitorRecognitionPage> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  XFile? _capturedPhoto;

  bool _isInitializing = true;
  bool _isTakingPhoto = false;
  String? _errorMessage;

  String? _matchedVisitorName;
  double? _matchedSimilarity;

  List<double>? _previousEmbedding;
  List<double>? _capturedEmbedding;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No camera available.');
      }

      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to initialize camera.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPhoto) {
      return;
    }

    setState(() {
      _isTakingPhoto = true;
    });

    try {
      final photo = await controller.takePicture();

      if (!mounted) return;

      setState(() {
        _capturedPhoto = photo;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to take photo.')));
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }
    }
  }

  Future<void> _detectFace() async {
    final photo = _capturedPhoto;

    if (photo == null) return;

    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No face detected. Please retake the photo.'),
          ),
        );
        return;
      }

      if (faces.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Multiple faces detected. Please take a photo of one visitor.',
            ),
          ),
        );
        return;
      }

      debugPrint('ONE FACE DETECTED');

      debugPrint('FACE BOX: ${faces.first.boundingBox}');

      final croppedFace = await _cropFace(photo, faces.first.boundingBox);

      if (croppedFace == null) {
        debugPrint('FACE CROP FAILED');
        return;
      }

      debugPrint(
        'FACE CROP SIZE: ${croppedFace.width} x ${croppedFace.height}',
      );

      final resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

      debugPrint(
        'RESIZED FACE SIZE: ${resizedFace.width} x ${resizedFace.height}',
      );

      final input = List.generate(
        1,
        (_) => List.generate(
          112,
          (y) => List.generate(112, (x) {
            final pixel = resizedFace.getPixel(x, y);

            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }),
        ),
      );

      debugPrint('INPUT TENSOR CREATED');

      debugPrint('ABOUT TO LOAD MOBILEFACENET');

      final interpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
      );
      debugPrint('MOBILEFACENET LOADED SUCCESSFULLY');

      final output = List.generate(1, (_) => List.filled(192, 0.0));

      debugPrint('ABOUT TO RUN MOBILEFACENET');

      interpreter.run(input, output);

      debugPrint('MOBILEFACENET INFERENCE COMPLETE');
      debugPrint('EMBEDDING LENGTH: ${output[0].length}');
      debugPrint('EMBEDDING FIRST 5: ${output[0].take(5).toList()}');

      final embedding = List<double>.from(output[0]);

      _capturedEmbedding = embedding;

      final samples = await AppDatabase.instance.getFaceSamplesWithVisitors();

      debugPrint('FACE SAMPLE COUNT: ${samples.length}');

      double? bestSimilarity;
      String? bestName;

      for (final sample in samples) {
        final savedEmbedding = (jsonDecode(
          sample['embedding'] as String,
        ) as List).map((value) => (value as num).toDouble()).toList();

        double similarity = 0;

        for (int i = 0; i < embedding.length; i++) {
          similarity += embedding[i] * savedEmbedding[i];
        }

        debugPrint(
          'FACE MATCH: ${sample['name']} '
          'similarity=${similarity.toStringAsFixed(4)}',
        );

        if (bestSimilarity == null || similarity > bestSimilarity) {
          bestSimilarity = similarity;
          bestName = sample['name'] as String;
        }
      }

      const matchThreshold = 0.80;

      if (bestSimilarity != null) {
        debugPrint(
          'BEST MATCH: $bestName '
          'similarity=${bestSimilarity.toStringAsFixed(4)}',
        );

        if (bestSimilarity >= matchThreshold) {
          _matchedVisitorName = bestName;
          _matchedSimilarity = bestSimilarity;

          debugPrint(
            'RECOGNITION: EXISTING VISITOR '
            'name=$bestName '
            'similarity=${bestSimilarity.toStringAsFixed(4)}',
          );
        } else {
          _matchedVisitorName = null;
          _matchedSimilarity = bestSimilarity;

          debugPrint(
            'RECOGNITION: NEW VISITOR '
            'bestSimilarity=${bestSimilarity.toStringAsFixed(4)} '
            'threshold=$matchThreshold',
          );
        }
      }
      final norm = math.sqrt(
        embedding.fold<double>(0.0, (sum, value) => sum + (value * value)),
      );

      debugPrint('EMBEDDING NORM: $norm');

      if (_previousEmbedding == null) {
        _previousEmbedding = embedding;
        debugPrint('FIRST EMBEDDING STORED');
      } else {
        double dotProduct = 0.0;

        for (var i = 0; i < embedding.length; i++) {
          dotProduct += _previousEmbedding![i] * embedding[i];
        }

        debugPrint('COSINE SIMILARITY: $dotProduct');

        _previousEmbedding = embedding;
      }

      interpreter.close();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face detected and MobileFaceNet loaded.'),
        ),
      );
    } catch (e) {
      debugPrint('FACE/MODEL ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to process face/model.')),
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhoto = null;
      _capturedEmbedding = null;
    });
  }

  Future<img.Image?> _cropFace(XFile photo, Rect faceBox) async {
    debugPrint('CROP: START');

    final bytes = await photo.readAsBytes();

    debugPrint('CROP: PHOTO BYTES = ${bytes.length}');

    final image = img.decodeImage(bytes);

    debugPrint(
      'CROP: DECODE RESULT = ${image == null ? 'NULL' : '${image.width}x${image.height}'}',
    );

    if (image == null) {
      return null;
    }

    final x = faceBox.left.round().clamp(0, image.width - 1);
    final y = faceBox.top.round().clamp(0, image.height - 1);
    final right = faceBox.right.round().clamp(x + 1, image.width);
    final bottom = faceBox.bottom.round().clamp(y + 1, image.height);

    final width = right - x;
    final height = bottom - y;

    final size = width < height ? width : height;

    final centerX = x + width ~/ 2;
    final centerY = y + height ~/ 2;

    final cropX = (centerX - size ~/ 2).clamp(0, image.width - size);
    final cropY = (centerY - size ~/ 2).clamp(0, image.height - size);

    return img.copyCrop(image, x: cropX, y: cropY, width: size, height: size);
  }

  Future<void> _registerCapturedVisitor() async {
    debugPrint('REGISTER: START');

    final embedding = _capturedEmbedding;

    if (embedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm the photo first.')),
      );
      return;
    }

    final nameController = TextEditingController();

    debugPrint('REGISTER: BEFORE SHOW DIALOG');

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register Visitor'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Visitor name',
              hintText: 'Enter visitor name',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.pop(context, name);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    debugPrint('REGISTER: DIALOG CLOSED');
    debugPrint('REGISTER: NAME = $name');

    if (name == null || name.isEmpty) {
      return;
    }

    try {
      debugPrint('REGISTER: BEFORE INSERT VISITOR');

      final visitorId = await AppDatabase.instance.insertVisitor(name: name);

      debugPrint('REGISTER: VISITOR INSERTED id=$visitorId');

      await AppDatabase.instance.insertFaceSample(
        visitorId: visitorId,
        embedding: embedding,
      );

      debugPrint('REGISTER: FACE SAMPLE INSERTED');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visitor "$name" registered successfully.')),
      );

      debugPrint('VISITOR SAVED: id=$visitorId, name=$name');
      debugPrint('FACE SAMPLE SAVED: embedding=${embedding.length} values');
    } catch (e) {
      debugPrint('VISITOR SAVE ERROR: $e');

      if (!mounted) return;

      debugPrint('REGISTER: BEFORE SUCCESS SNACKBAR');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to save visitor.')));
    }
  }

  Future<void> _createVisit() async {
    debugPrint('VISIT: START');

    final settings = await AppDatabase.instance.getSettings();

    if (settings == null) {
      debugPrint('VISIT: SETTINGS NOT FOUND');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load session settings.')),
      );

      return;
    }

    final sessionTime = (settings['session_time'] as num).toDouble();
    final sessionCost = (settings['session_cost'] as num).toInt();

    final startTime = DateTime.now();

    final endTime = startTime.add(
      Duration(minutes: (sessionTime * 60).round()),
    );

    debugPrint(
      'VISIT: CREATING 1 VISIT '
      'sessionTime=$sessionTime '
      'sessionCost=$sessionCost',
    );

    final visitId = await AppDatabase.instance.insertVisit(
      counter: 1,
      startTime: startTime,
      endTime: endTime,
      sessionCost: sessionCost,
    );

    debugPrint('VISIT: CREATED id=$visitId');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Visit started successfully.')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Recognition')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    debugPrint('_buildBody: Started');

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _errorMessage = null;
                  });

                  _initializeCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_capturedPhoto != null) {
      debugPrint('_capturedPhoto: PRESSED');

      return _buildCapturedPhoto();
    }

    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Text('Camera is not available.'));
    }

    return _buildCameraPreview(controller);
  }

  Widget _buildCameraPreview(CameraController controller) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: CameraPreview(controller),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Position the visitor\'s face inside the camera view.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedPhoto() {
    debugPrint('_buildCapturedPhoto: start');
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_capturedPhoto!.path),
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Is this photo clear enough?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retakePhoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      debugPrint('CONFIRM: PRESSED');

                      await _detectFace();

                      debugPrint('CONFIRM: DETECT FACE RETURNED');

                      if (!mounted) {
                        debugPrint('CONFIRM: WIDGET NOT MOUNTED');
                        return;
                      }

                      debugPrint(
                        'CONFIRM: EMBEDDING = ${_capturedEmbedding != null}',
                      );

                      if (_capturedEmbedding != null) {
                        if (_matchedVisitorName != null) {
                          debugPrint(
                            'CONFIRM: EXISTING VISITOR MATCHED '
                            'name=$_matchedVisitorName '
                            'similarity=${_matchedSimilarity?.toStringAsFixed(4)}',
                          );

                          await _createVisit();

                          return;
                        }

                        debugPrint(
                          'CONFIRM: NO EXISTING MATCH, CALLING REGISTER',
                        );

                        await _registerCapturedVisitor();

                        debugPrint('CONFIRM: REGISTER RETURNED');
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
