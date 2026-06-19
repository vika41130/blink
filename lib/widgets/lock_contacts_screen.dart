import 'dart:ui';

import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class LockContactsScreen extends StatefulWidget {
  const LockContactsScreen({super.key});

  @override
  State<LockContactsScreen> createState() => _LockContactsScreenState();
}

class _LockContactsScreenState extends State<LockContactsScreen> {
  late bool _isLocked;

  @override
  void initState() {
    super.initState();
    _isLocked = getIt<CacheService>().getBool(cacheKeyContactsLocked);
  }

  void _onToggleLock() {
    _showPinDialog();
  }

  void _showPinDialog() {
    final pinController = TextEditingController();
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
              insetPadding: const EdgeInsets.symmetric(horizontal: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: appPaddingSmall * 2,
                  vertical: appPaddingSmall * 3,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter pin',
                      style: TextStyle(fontSize: fontSizeSmall),
                    ),
                    const SizedBox(height: appPaddingSmall * 2),
                    Pinput(
                      controller: pinController,
                      autofocus: true,
                      obscureText: true,
                      defaultPinTheme: PinTheme(
                        width: 28,
                        height: 28,
                        textStyle: TextStyle(
                          fontSize: fontSizeMedium,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: mediumBorderWidth,
                          ),
                        ),
                      ),
                      showCursor: true,
                      cursor: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      separatorBuilder:
                          (index) => const SizedBox(width: appPaddingMid),
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      onCompleted: (pin) async {
                        final cachedPin =
                            getIt<CacheService>().getString(cacheKeyUserPin) ??
                            '';
                        if (cachedPin == pin) {
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          final newLocked = !_isLocked;
                          setState(() {
                            _isLocked = newLocked;
                          });
                          await getIt<CacheService>().setBool(
                            cacheKeyContactsLocked,
                            newLocked,
                          );
                          // Save to Firestore
                          final userId =
                              getIt<CacheService>().getString(cacheKeyUserId) ??
                              '';
                          if (userId.isNotEmpty) {
                            getIt<FirebaseFirestore>()
                                .collection('users')
                                .doc(userId)
                                .update({'contactsLocked': newLocked});
                          }
                        } else {
                          getIt<ToastificationService>().showToast(
                            getIt<AppLocalizations>().pinNotCorrect,
                          );
                          pinController.clear();
                        }
                      },
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
          getIt<AppLocalizations>().lockContacts,
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
                      _isLocked
                          ? CupertinoIcons.lock
                          : CupertinoIcons.lock_open,
                      size: appIconMidSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _onToggleLock,
                  ),
                  SizedBox(width: appPaddingSmall),
                  Expanded(
                    child: Text(
                      _isLocked ? 'Locked' : 'Unlocked',
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
