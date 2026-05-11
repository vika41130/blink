import 'package:blink/get_it_setup.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/corner_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerContent extends StatefulWidget {
  const QRScannerContent({super.key});

  @override
  State<QRScannerContent> createState() => _QRScannerContentState();
}

class _QRScannerContentState extends State<QRScannerContent> {
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
  );
  bool _isScanCompleted = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // full screen camera preview
        MobileScanner(
          controller: _cameraController,
          onDetect: (capture) {
            if (_isScanCompleted) {
              return;
            }
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              setState(() {
                _isScanCompleted = true;
              });
              final String? qrCodeValue = barcodes.first.rawValue;
              if (qrCodeValue != null) {
                HapticFeedback.vibrate();
                _cameraController.stop();
                // if (mounted) {
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(
                //       content: Text('QR Code Detected: $qrCodeValue'),
                //       backgroundColor: Colors.green,
                //     ),
                //   );
                // }
                // search user and go to chat if found
                // else show error toast message
              }
            }
          },
        ),
        Container(color: Colors.black.withAlpha(10)),
        Center(
          child: CustomPaint(
            painter: CornerBorderPainter(
              strokeColor: getIt<AppThemes>().themeData.colorScheme.primary,
              strokeWidth: appBorderWidth,
              cornerLength: appCameraCornerLength,
              cornerRadius: appBorderRadius,
            ),
            child: SizedBox(
              width: appCameraScanFrameSize,
              height: appCameraScanFrameSize,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: appTorchPositionBottom,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: appSixedBoxSizeMedium, child: SizedBox.shrink()),
              SizedBox(
                width: appSixedBoxSizeMedium,
                child: IconButton(
                  icon: ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _cameraController,
                    builder: (context, state, child) {
                      if (!state.isInitialized ||
                          state.torchState == TorchState.unavailable) {
                        return const SizedBox.shrink();
                      }
                      switch (state.torchState) {
                        case TorchState.off:
                          return const Icon(
                            Icons.flash_off,
                            color: Colors.grey,
                          );
                        case TorchState.on:
                          return const Icon(
                            Icons.flash_on,
                            color: Colors.yellow,
                          );
                        case TorchState.auto:
                          throw UnimplementedError();
                        case TorchState.unavailable:
                          throw UnimplementedError();
                      }
                    },
                  ),
                  onPressed: () => _cameraController.toggleTorch(),
                ),
              ),
              SizedBox(
                width: appSixedBoxSizeMedium,
                child: IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: _scanImageFromGallery,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _scanImageFromGallery() async {
    try {
      _cameraController.stop();
      // 1. Pick an image from the device gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) {
        _cameraController.start();
        return; // User canceled the picker
      }

      // 2. Pass the file path to MobileScanner to analyze it
      final BarcodeCapture? capture = await _cameraController.analyzeImage(
        pickedFile.path,
      );

      // 3. Process the results
      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? qrCodeValue = capture.barcodes.first.rawValue;

        if (qrCodeValue != null && mounted) {
          HapticFeedback.vibrate();
          _cameraController.stop();
          // search user and go to chat if found else show error toast message
        }
      } else {
        _cameraController.start();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No QR code found in the selected image.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      _cameraController.start();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
