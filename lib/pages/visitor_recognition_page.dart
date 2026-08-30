import 'dart:io';

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

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _inspectModel();
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

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('One face detected.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to detect face.')));
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhoto = null;
    });
  }

  Future<void> _inspectModel() async {
    try {
      final interpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
      );

      debugPrint('MODEL INPUT: ${interpreter.getInputTensor(0).shape}');
      debugPrint('MODEL INPUT TYPE: ${interpreter.getInputTensor(0).type}');
      debugPrint('MODEL OUTPUT: ${interpreter.getOutputTensor(0).shape}');
      debugPrint('MODEL OUTPUT TYPE: ${interpreter.getOutputTensor(0).type}');

      interpreter.close();
    } catch (e) {
      debugPrint('MODEL ERROR: $e');
    }
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
                onPressed: _isTakingPhoto ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_isTakingPhoto ? 'Taking Photo...' : 'Take Photo'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedPhoto() {
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
                    onPressed: _detectFace,
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
