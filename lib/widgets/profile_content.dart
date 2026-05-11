import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: QrImageView(
            data: getIt<CacheService>().getString(cacheKeyUserId) ?? '',
            version: QrVersions.auto, // Automatically calculate QR version
            size: 200.0, // Total width and height of the widget
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
        Text('List of contacts will be here'),
      ],
    );
  }
}
