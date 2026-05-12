import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class QrImageScreen extends StatefulWidget {
  const QrImageScreen({super.key});

  @override
  State<QrImageScreen> createState() => _QrImageScreenState();
}

class _QrImageScreenState extends State<QrImageScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: appPadding,
            right: appPadding,
            bottom: appPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: QrImageView(
                    data: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
                    version:
                        QrVersions.auto, // Automatically calculate QR version
                    size:
                        appQrImageViewSize, // Total width and height of the widget
                    gapless: false, // Fixes alignment gaps on some screens
                    dataModuleStyle: QrDataModuleStyle(
                      color:
                          Theme.of(
                            context,
                          ).colorScheme.primary, // Color of the QR code modules
                    ),
                    eyeStyle: QrEyeStyle(
                      color: Theme.of(context).colorScheme.primary,
                      eyeShape: QrEyeShape.square,
                    ),
                  ),
                ),
              ),
              SizedBox(height: formItemMargin),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _downloadQrCode,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: appLoadingIndicatorSizeSmall,
                          height: appLoadingIndicatorSizeSmall,
                          child: CircularProgressIndicator(
                            strokeWidth: appLoadingstrokeWidthSmall,
                          ),
                        )
                        : const Icon(Icons.download),
                label: Text(
                  _isSaving
                      ? getIt<AppLocalizations>().saving
                      : getIt<AppLocalizations>().saveToGallery,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadQrCode() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final RenderRepaintBoundary? boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Boundary not found");
      final ui.Image image = await boundary.toImage(
        pixelRatio: appImagePixelRatio,
      );
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        // 2. This call remains exactly the same as before!
        final result = await ImageGallerySaverPlus.saveImage(
          pngBytes,
          quality: appImageQuality,
          name:
              "$appImageFileNamePrefix${DateTime.now().millisecondsSinceEpoch}",
        );
        if (context.mounted) {
          if (result['isSuccess'] == true) {
            getIt<ToastificationService>().showSuccess(
              getIt<AppLocalizations>().qrCodeSaved,
            );
          } else {
            throw Exception("Gallery saving failed");
          }
        }
      }
    } catch (e) {
      getIt<ToastificationService>().showError(
        getIt<AppLocalizations>().failedToSaveQRCode,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
