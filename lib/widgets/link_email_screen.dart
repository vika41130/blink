import 'dart:async';
import 'dart:math';

import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/cache_service.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class LinkEmailScreen extends StatefulWidget {
  const LinkEmailScreen({super.key});

  @override
  State<LinkEmailScreen> createState() => _LinkEmailScreenState();
}

class _LinkEmailScreenState extends State<LinkEmailScreen> {
  late final TextEditingController _emailController;
  late final FocusNode _emailFocusNode;
  bool _codeSent = false;
  String _generatedCode = '';
  DateTime? _codeExpiry;
  Timer? _expiryTimer;
  bool _hasLinkedEmail = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailFocusNode = FocusNode();
    final cachedEmail =
        getIt<CacheService>().getString(cacheKeyUserEmail) ?? '';
    if (cachedEmail.isNotEmpty) {
      _emailController.text = cachedEmail;
      _hasLinkedEmail = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _expiryTimer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
    return regex.hasMatch(email.trim());
  }

  Future<void> _removeLinkedEmail() async {
    final userId = getIt<CacheService>().getString(cacheKeyUserId) ?? '';
    if (userId.isEmpty) return;

    await getIt<FirebaseFirestore>().collection('users').doc(userId).update({
      'email': FieldValue.delete(),
    });

    getIt<CacheService>().setString(cacheKeyUserEmail, '');
    _emailController.clear();
    setState(() => _hasLinkedEmail = false);

    getIt<ToastificationService>().showToast(
      getIt<AppLocalizations>().emailRemoved,
    );
  }

  String _generateCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    final userId = getIt<CacheService>().getString(cacheKeyUserId) ?? '';
    if (userId.isEmpty) return;

    _generatedCode = _generateCode();
    _codeExpiry = DateTime.now().add(const Duration(minutes: 3));

    // Store code and email in Firestore for Cloud Function to send
    await getIt<FirebaseFirestore>().collection('users').doc(userId).update({
      'pendingEmail': email,
      'verificationCode': _generatedCode,
      'verificationExpiry': Timestamp.fromDate(_codeExpiry!),
    });

    // Cache locally
    getIt<CacheService>().setString(cacheKeyVerificationCode, _generatedCode);
    getIt<CacheService>().setString(
      cacheKeyVerificationExpiry,
      _codeExpiry!.toIso8601String(),
    );
    getIt<CacheService>().setString(cacheKeyPendingEmail, email);

    setState(() => _codeSent = true);
    getIt<ToastificationService>().showToast(
      getIt<AppLocalizations>().codeSent,
    );

    // Start expiry timer
    _expiryTimer = Timer(const Duration(minutes: 3), () {
      if (!mounted) return;
      _generatedCode = '';
      _codeExpiry = null;
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().codeExpired,
      );
      setState(() => _codeSent = false);
    });
  }

  Future<void> _verifyCode(String code) async {
    if (_codeExpiry != null && DateTime.now().isAfter(_codeExpiry!)) {
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().codeExpired,
      );
      return;
    }

    if (code == _generatedCode) {
      final userId = getIt<CacheService>().getString(cacheKeyUserId) ?? '';
      if (userId.isEmpty) return;

      // Save verified email
      await getIt<FirebaseFirestore>().collection('users').doc(userId).update({
        'email': _emailController.text.trim(),
        'pendingEmail': FieldValue.delete(),
        'verificationCode': FieldValue.delete(),
        'verificationExpiry': FieldValue.delete(),
      });

      // Clear verification cache, store email
      getIt<CacheService>().setString(cacheKeyVerificationCode, '');
      getIt<CacheService>().setString(cacheKeyVerificationExpiry, '');
      getIt<CacheService>().setString(cacheKeyPendingEmail, '');
      getIt<CacheService>().setString(
        cacheKeyUserEmail,
        _emailController.text.trim(),
      );

      if (mounted) {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().emailLinked,
        );
        setState(() {
          _codeSent = false;
          _hasLinkedEmail = true;
        });
      }
    } else {
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().invalidCode,
      );
    }
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
          getIt<AppLocalizations>().linkEmail,
          style: TextStyle(
            fontSize: fontSizeLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: appPaddingSmall * 2,
            vertical: appPaddingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: appTextInputHeight,
                child: TextFormField(
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.center,
                  enabled: !_codeSent,
                  onTapOutside: (event) {
                    _emailFocusNode.unfocus();
                  },
                  focusNode: _emailFocusNode,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontSize: fontSizeSmall,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: appTextInputContentPadding * 1.5,
                    ),
                    hintStyle: TextStyle(
                      fontSize: fontSizeSmall,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    hintText: getIt<AppLocalizations>().email,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        appTextInputBorderRadius,
                      ),
                      borderSide: BorderSide(
                        width: mediumBorderWidth,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        appTextInputBorderRadius,
                      ),
                      borderSide: BorderSide(
                        width: mediumBorderWidth,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        appTextInputBorderRadius,
                      ),
                      borderSide: BorderSide(
                        width: mediumBorderWidth,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              if (!_codeSent && !_hasLinkedEmail) ...[
                SizedBox(height: appPaddingSmall),
                Row(
                  mainAxisAlignment:
                      (getIt<CacheService>().getString(cacheKeyUserEmail) ?? '')
                              .isNotEmpty
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.end,
                  children: [
                    if ((getIt<CacheService>().getString(cacheKeyUserEmail) ??
                            '')
                        .isNotEmpty)
                      TextButton(
                        onPressed: () {
                          final cachedEmail =
                              getIt<CacheService>().getString(
                                cacheKeyUserEmail,
                              ) ??
                              '';
                          _emailController.text = cachedEmail;
                          setState(() {
                            _hasLinkedEmail = cachedEmail.isNotEmpty;
                            _codeSent = false;
                          });
                        },
                        child: Text(
                          getIt<AppLocalizations>().cancel,
                          style: TextStyle(fontSize: fontSizeSmall),
                        ),
                      ),
                    TextButton(
                      onPressed: () {
                        if (!_isValidEmail(_emailController.text)) {
                          getIt<ToastificationService>().showToast(
                            getIt<AppLocalizations>().invalidEmail,
                          );
                          return;
                        }
                        _sendVerificationCode();
                      },
                      child: Text(
                        getIt<AppLocalizations>().confirm,
                        style: TextStyle(fontSize: fontSizeSmall),
                      ),
                    ),
                  ],
                ),
              ],
              if (!_codeSent && _hasLinkedEmail) ...[
                SizedBox(height: appPaddingSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _removeLinkedEmail,
                      child: Text(
                        getIt<AppLocalizations>().remove,
                        style: TextStyle(fontSize: fontSizeSmall),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _emailController.clear();
                        setState(() => _hasLinkedEmail = false);
                      },
                      child: Text(
                        getIt<AppLocalizations>().change,
                        style: TextStyle(fontSize: fontSizeSmall),
                      ),
                    ),
                  ],
                ),
              ],
              if (_codeSent) ...[
                SizedBox(height: appFormItemMargin),
                SizedBox(height: appFormItemMargin),
                Pinput(
                  length: 4,
                  autofocus: true,
                  obscureText: true,
                  defaultPinTheme: PinTheme(
                    width: pinItemHeight,
                    height: pinItemHeight,
                    textStyle: TextStyle(
                      fontSize: pinInputValueFontSize,
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
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  separatorBuilder:
                      (index) => const SizedBox(width: appPaddingMid),
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                  onCompleted: _verifyCode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
