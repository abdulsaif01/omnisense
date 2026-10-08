import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraManager {
  CameraController? _controller;

  CameraController? get controller => _controller;

  Future<CameraStartupResult> initializeRearCamera() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      return const CameraStartupResult.denied();
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return const CameraStartupResult.failure('No camera was found on this device.');
    }

    final rearCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    for (final preset in [ResolutionPreset.medium, ResolutionPreset.low, ResolutionPreset.high]) {
      final controller = CameraController(
        rearCamera,
        preset,
        enableAudio: false,
      );

      try {
        await controller.initialize();
        _controller = controller;
        return CameraStartupResult.ready(controller);
      } catch (_) {
        await controller.dispose();
      }
    }

    return const CameraStartupResult.failure(
      'Could not initialize camera for this device hardware.',
    );
  }

  Future<XFile?> captureFrame() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }
    return controller.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}

class CameraStartupResult {
  const CameraStartupResult._({
    required this.status,
    this.controller,
    this.message,
  });

  const CameraStartupResult.denied()
      : this._(
          status: CameraStartupStatus.denied,
          message:
              'Camera permission is required for visual assistance. Please enable camera access in settings.',
        );

  const CameraStartupResult.failure(String message)
      : this._(
          status: CameraStartupStatus.failure,
          message: message,
        );

  const CameraStartupResult.ready(CameraController controller)
      : this._(
          status: CameraStartupStatus.ready,
          controller: controller,
          message: 'Camera ready.',
        );

  final CameraStartupStatus status;
  final CameraController? controller;
  final String? message;

  bool get isReady => status == CameraStartupStatus.ready;
}

enum CameraStartupStatus {
  ready,
  denied,
  failure,
}
