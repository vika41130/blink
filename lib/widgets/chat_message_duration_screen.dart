import 'dart:ui';

import 'package:blink/get_it_setup.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/network_error_handler.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatMessageDurationScreen extends StatefulWidget {
  const ChatMessageDurationScreen({super.key});

  @override
  State<ChatMessageDurationScreen> createState() =>
      _ChatMessageDurationScreenState();
}

class _ChatMessageDurationScreenState extends State<ChatMessageDurationScreen> {
  late int _savedMinute;

  @override
  void initState() {
    super.initState();
    final cached = getIt<CacheService>().getInt(cacheKeyChatMessageDuration);
    _savedMinute = (cached != null && cached >= 1 && cached <= 3) ? cached : 1;
  }

  Future<void> _updateFirestore(int minutes) async {
    if (await NetworkErrorHandler.isOffline()) {
      getIt<ToastificationService>().showToast('Network error');
      return;
    }
    final userId = getIt<CacheService>().getString(cacheKeyUserId) ?? '';
    if (userId.isEmpty) return;
    try {
      await getIt<FirebaseFirestore>().collection('users').doc(userId).update({
        'chatMessageDuration': minutes,
      });
    } catch (_) {}
  }

  void _showMinutePickerDialog() {
    int tempMinute = _savedMinute;
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
                      height: 150,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _savedMinute - 1,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (index) {
                          tempMinute = index + 1;
                        },
                        children: List.generate(3, (index) {
                          final minute = index + 1;
                          return Center(
                            child: Text(
                              '$minute minute${minute > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: fontSizeMedium,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        }),
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
                            if (tempMinute != _savedMinute) {
                              setState(() => _savedMinute = tempMinute);
                              getIt<CacheService>().setInt(
                                cacheKeyChatMessageDuration,
                                tempMinute,
                              );
                              _updateFirestore(tempMinute);
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
          icon: const Icon(Icons.arrow_back_ios_new, size: appBarIconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chat message duration',
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
                      Icons.info_outline,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: null,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Expanded(
                    child: Text(
                      'Default: 1 minute',
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
                      Icons.edit,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _showMinutePickerDialog,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Expanded(
                    child: Text(
                      '$_savedMinute minute${_savedMinute > 1 ? 's' : ''}',
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
