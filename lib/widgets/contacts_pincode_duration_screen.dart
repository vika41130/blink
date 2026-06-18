import 'dart:ui';

import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsPincodeDurationScreen extends StatefulWidget {
  const ContactsPincodeDurationScreen({super.key});

  @override
  State<ContactsPincodeDurationScreen> createState() =>
      _ContactsPincodeDurationScreenState();
}

class _ContactsPincodeDurationScreenState
    extends State<ContactsPincodeDurationScreen> {
  late Duration _savedDuration;
  late bool _pinVerificationEnabled;

  @override
  void initState() {
    super.initState();
    final cachedMinutes = int.tryParse(
      getIt<CacheService>().getString('pincodeDurationMinutes') ?? '',
    );
    _savedDuration =
        cachedMinutes != null
            ? Duration(minutes: cachedMinutes)
            : const Duration(hours: 6);
    _pinVerificationEnabled =
        getIt<SharedPreferences>().getBool(cacheKeyPinVerificationEnabled) ??
        true;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  void _showTimerPickerDialog() {
    Duration tempDuration = _savedDuration;
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(appBorderRadius * 4),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.secondary,
                  width: mediumBorderWidth,
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: appPaddingSmall * 2,
                  vertical: appPaddingSmall * 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 180,
                      child: CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: _savedDuration,
                        onTimerDurationChanged: (Duration duration) {
                          tempDuration = duration;
                        },
                      ),
                    ),
                    SizedBox(height: appPaddingSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (tempDuration != _savedDuration) {
                              setState(() => _savedDuration = tempDuration);
                              getIt<CacheService>().setString(
                                'pincodeDurationMinutes',
                                tempDuration.inMinutes.toString(),
                              );
                              getIt<ToastificationService>().showToast(
                                getIt<AppLocalizations>().durationUpdated,
                              );
                            }
                          },
                          child: Text(getIt<AppLocalizations>().done),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: appBarIconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          getIt<AppLocalizations>().contactsPincodeDuration,
          style: TextStyle(
            fontSize: fontSizeLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: appPaddingSmall * 2,
            vertical: appPaddingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.lock,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: null,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Expanded(
                    child: Text(
                      'Pin verification',
                      style: TextStyle(
                        fontSize: fontSizeMedium,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Switch(
                    value: _pinVerificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _pinVerificationEnabled = value;
                      });
                      getIt<CacheService>().setBool(
                        cacheKeyPinVerificationEnabled,
                        value,
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: appPaddingSmall),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.info,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: null,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Expanded(
                    child: Text(
                      getIt<AppLocalizations>().defaultDurationInfo,
                      style: TextStyle(
                        fontSize: fontSizeMedium,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: appPaddingSmall),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.pencil,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed:
                        _pinVerificationEnabled ? _showTimerPickerDialog : null,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Expanded(
                    child: Text(
                      _formatDuration(_savedDuration),
                      style: TextStyle(
                        fontSize: fontSizeMedium,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
