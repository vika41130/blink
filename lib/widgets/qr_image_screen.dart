import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRImageScreen extends StatefulWidget {
  const QRImageScreen({super.key});

  @override
  State<QRImageScreen> createState() => _QRImageScreenState();
}

class _QRImageScreenState extends State<QRImageScreen> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _downloadQrCode() async {
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
              getIt<AppLocalizations>().saveToGallery,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: appBarIconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: appPaddingSmall),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  onPressed: _downloadQrCode,
                  icon: const Icon(CupertinoIcons.square_arrow_down),
                  label: Text(getIt<AppLocalizations>().saveToGalleryButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
