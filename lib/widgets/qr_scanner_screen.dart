import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/themes/app_theme.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:blink/widgets/corner_border.dart';
import 'package:blink/widgets/socket_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
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
          onDetect: (capture) async {
            if (_isScanCompleted) {
              return;
            }
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              setState(() {
                _isScanCompleted = true;
              });
              final String? qrCodeValue = barcodes.first.rawValue;
              await _processScannedQRCode(qrCodeValue);
            } else {
              getIt<ToastificationService>().showError(
                getIt<AppLocalizations>().noQRCodeDetected,
              );
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
        await _processScannedQRCode(qrCodeValue);
      } else {
        _cameraController.start();
        getIt<ToastificationService>().showError(
          getIt<AppLocalizations>().noQRCodeDetected,
        );
      }
    } catch (e) {
      _cameraController.start();
      getIt<ToastificationService>().showError(
        getIt<AppLocalizations>().noQRCodeDetected,
      );
    }
  }

  _processScannedQRCode(String? qrCodeValue) async {
    if (qrCodeValue != null) {
      HapticFeedback.vibrate();
      _cameraController.stop();
      final user = await getIt<AuthService>().getUserById(qrCodeValue);
      final String currentUserId =
          getIt<CacheService>().getString(cacheKeyUserId) ?? '';
      if (user != null) {
        if (qrCodeValue == currentUserId) {
          getIt<ToastificationService>().showError(
            getIt<AppLocalizations>().cannotChatWithYourself,
          );
          _cameraController.start();
          setState(() {
            _isScanCompleted = false;
          });
          return;
        } else {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    currentUserId: currentUserId,
                    receiverId: qrCodeValue,
                    receiverName: user['username'],
                  ),
                  // (context) => SocketChatScreen(),
            ),
          );
        }
      } else {
        getIt<ToastificationService>().showError(
          getIt<AppLocalizations>().userNotFound,
        );
      }
    } else {
      getIt<ToastificationService>().showError(
        getIt<AppLocalizations>().failedToReadQRCode,
      );
    }
  }
}
