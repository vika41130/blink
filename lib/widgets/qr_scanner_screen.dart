import 'package:blink/app.dart';
import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:blink/widgets/chat_screen.dart';
import 'package:blink/widgets/custom_widgets/corner_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _cameraController;
  bool _isScanCompleted = false;
  final ImagePicker _imagePicker = ImagePicker();

  bool? _permissionDenied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      var status = await Permission.camera.status;
      debugPrint('Initial camera status: $status');
      if (!status.isGranted && !status.isPermanentlyDenied) {
        status = await Permission.camera.request();
        debugPrint('After request camera status: $status');
      }
      if (!mounted) return;
      if (status.isGranted) {
        _startCamera();
      } else {
        setState(() => _permissionDenied = true);
      }
    } catch (e) {
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  void _startCamera() {
    _cameraController?.dispose();
    _cameraController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
    );
    if (mounted) {
      setState(() => _permissionDenied = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _permissionDenied == true) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final status = await Permission.camera.status;
      if (!mounted) return;
      if (status.isGranted) {
        _startCamera();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
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
    if (_permissionDenied == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, size: appBarIconSize),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_permissionDenied == true) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, size: appBarIconSize),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getIt<AppLocalizations>().cameraPermissionDenied),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                child: Text(getIt<AppLocalizations>().openSettings),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: appBarIconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController!,
            errorBuilder: (context, error) => const SizedBox.shrink(),
            onDetect: (capture) async {
              if (_isScanCompleted) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                setState(() {
                  _isScanCompleted = true;
                });
                final String? qrCodeValue = barcodes.first.rawValue;
                await _processScannedQRCode(qrCodeValue);
              } else {
                getIt<ToastificationService>().showToast(
                  getIt<AppLocalizations>().noQRCodeDetected,
                );
              }
            },
          ),
          Container(color: Colors.black.withAlpha(10)),
          Center(
            child: CustomPaint(
              painter: CornerBorderPainter(
                strokeColor: Theme.of(context).colorScheme.primary,
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
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
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
                SizedBox(
                  width: appSixedBoxSizeMedium,
                  child: SizedBox.shrink(),
                ),
                SizedBox(
                  width: appSixedBoxSizeMedium,
                  child: IconButton(
                    icon: ValueListenableBuilder<MobileScannerState>(
                      valueListenable: _cameraController!,
                      builder: (context, state, child) {
                        if (!state.isInitialized ||
                            state.torchState == TorchState.unavailable) {
                          return const SizedBox.shrink();
                        }
                        switch (state.torchState) {
                          case TorchState.off:
                            return const Icon(
                              CupertinoIcons.bolt_slash,
                              color: Colors.grey,
                              size: appIconLargeSize,
                            );
                          case TorchState.on:
                            return const Icon(
                              CupertinoIcons.bolt_fill,
                              color: Colors.yellow,
                              size: appIconLargeSize,
                            );
                          case TorchState.auto:
                            throw UnimplementedError();
                          case TorchState.unavailable:
                            throw UnimplementedError();
                        }
                      },
                    ),
                    onPressed: () => _cameraController!.toggleTorch(),
                  ),
                ),
                SizedBox(
                  width: appSixedBoxSizeMedium,
                  child: IconButton(
                    icon: const Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: appIconLargeSize,
                    ),
                    onPressed: _scanImageFromGallery,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanImageFromGallery() async {
    try {
      _cameraController?.stop();
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) {
        _cameraController?.start();
        return;
      }
      final BarcodeCapture? capture = await _cameraController?.analyzeImage(
        pickedFile.path,
      );
      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? qrCodeValue = capture.barcodes.first.rawValue;
        await _processScannedQRCode(qrCodeValue);
      } else {
        _cameraController?.start();
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().noQRCodeDetected,
        );
      }
    } catch (e) {
      _cameraController?.start();
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().noQRCodeDetected,
      );
    }
  }

  _processScannedQRCode(String? qrCodeValue) async {
    if (qrCodeValue != null) {
      HapticFeedback.vibrate();
      _cameraController?.stop();
      final user = await getIt<AuthService>().getUserById(qrCodeValue);
      final String currentUserId =
          getIt<CacheService>().getString(cacheKeyUserId) ?? '';
      if (user != null) {
        if (qrCodeValue == currentUserId) {
          getIt<ToastificationService>().showToast(
            getIt<AppLocalizations>().cannotChatWithYourself,
          );
          _cameraController?.start();
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
                    receiverName: user.username,
                  ),
            ),
          );
        }
      } else {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().userNotFound,
        );
      }
    } else {
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().failedToReadQRCode,
      );
    }
  }
}
