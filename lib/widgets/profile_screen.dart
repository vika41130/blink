import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            getIt<CacheService>().getString(cacheKeyUsername) ?? '',
            style: TextStyle(
              fontSize: appTitleFontSize * 1.2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: appFormItemMargin),
          SizedBox(height: appFormItemMargin),
          RepaintBoundary(
            key: _qrKey,
            child: QrImageView(
              data: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
              version: QrVersions.auto,
              size: appQrImageViewSize,
              gapless: false,
              dataModuleStyle: QrDataModuleStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              eyeStyle: QrEyeStyle(
                color: Theme.of(context).colorScheme.primary,
                eyeShape: QrEyeShape.square,
              ),
            ),
          ),
          SizedBox(height: appFormItemMargin),
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
        final result = await ImageGallerySaverPlus.saveImage(
          pngBytes,
          quality: appImageQuality,
          name:
              "$appImageFileNamePrefix${DateTime.now().millisecondsSinceEpoch}",
        );
        if (mounted) {
          if (result['isSuccess'] == true) {
            getIt<ToastificationService>().showToast(
              getIt<AppLocalizations>().qrCodeSaved,
            );
          } else {
            throw Exception("Gallery saving failed");
          }
        }
      }
    } catch (e) {
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().failedToSaveQRCode,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
