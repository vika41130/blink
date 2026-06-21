import 'dart:async';
import 'dart:math';

import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/toastification_service.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _codeController;
  late final TextEditingController _newPinController;
  late final FocusNode _emailFocusNode;
  bool _codeSent = false;
  bool _codeVerified = false;
  String _generatedCode = '';
  String _userId = '';
  DateTime? _codeExpiry;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _codeController = TextEditingController();
    _newPinController = TextEditingController();
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPinController.dispose();
    _emailFocusNode.dispose();
    _expiryTimer?.cancel();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
    return regex.hasMatch(email.trim());
  }

  String _generateCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  Future<void> _sendVerificationCode() async {
    try {
      final email = _emailController.text.trim();

      // Check if email exists in Firestore
      final querySnapshot =
          await getIt<FirebaseFirestore>()
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        getIt<ToastificationService>().showToast(
          getIt<AppLocalizations>().emailNotLinkedYet,
        );
        return;
      }

      _generatedCode = _generateCode();
      _codeExpiry = DateTime.now().add(const Duration(minutes: 3));

      // Store code in Firestore for Cloud Function to send
      _userId = querySnapshot.docs.first.id;
      await getIt<FirebaseFirestore>().collection('users').doc(_userId).update({
        'verificationCode': _generatedCode,
        'pendingEmail': email,
        'verificationExpiry': Timestamp.fromDate(_codeExpiry!),
      });

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
    } catch (e) {
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().networkError,
      );
    }
  }

  Future<void> _verifyCode(String code) async {
    if (_codeExpiry != null && DateTime.now().isAfter(_codeExpiry!)) {
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().codeExpired,
      );
      return;
    }

    if (code == _generatedCode) {
      _expiryTimer?.cancel();
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().codeVerified,
      );
      setState(() => _codeVerified = true);
    } else {
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().invalidCode,
      );
      _codeController.clear();
    }
  }

  Future<void> _setNewPin(String pin) async {
    if (_userId.isEmpty || pin.isEmpty) return;
    await getIt<FirebaseFirestore>().collection('users').doc(_userId).update({
      'pin': pin,
      'verificationCode': FieldValue.delete(),
      'pendingEmail': FieldValue.delete(),
      'verificationExpiry': FieldValue.delete(),
    });
    if (mounted) {
      getIt<ToastificationService>().showToast(
        getIt<AppLocalizations>().pinUpdated,
      );
      Navigator.of(context).pop();
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
          getIt<AppLocalizations>().reset,
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
              if (!_codeSent) ...[
                SizedBox(height: appPaddingSmall),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      if (_emailController.text.trim().isEmpty) return;
                      if (!_isValidEmail(_emailController.text)) {
                        getIt<ToastificationService>().showToast(
                          getIt<AppLocalizations>().invalidEmail,
                        );
                        return;
                      }
                      _sendVerificationCode();
                    },
                    child: Text(
                      getIt<AppLocalizations>().getVerificationCode,
                      style: TextStyle(fontSize: fontSizeSmall),
                    ),
                  ),
                ),
              ],
              if (_codeSent && !_codeVerified) ...[
                SizedBox(height: appFormItemMargin),
                SizedBox(height: appFormItemMargin),
                Pinput(
                  controller: _codeController,
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
              if (_codeVerified) ...[
                SizedBox(height: appFormItemMargin),
                SizedBox(height: appFormItemMargin),
                Pinput(
                  controller: _newPinController,
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
                  onCompleted: _setNewPin,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
