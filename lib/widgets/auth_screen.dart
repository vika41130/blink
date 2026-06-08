import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:blink/settings/fixed_settings.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final TextEditingController pinController;
  late final FocusNode userNameFocusNode;
  late final FocusNode pInputFocusNode;
  late final GlobalKey<FormState> formKey;
  late final TextEditingController usernameController;
  var isSignInMode = true;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    pinController = TextEditingController();
    pInputFocusNode = FocusNode();
    userNameFocusNode = FocusNode();
    usernameController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.authTitle,
          style: TextStyle(
            fontSize: appTitleFontSize,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: appPadding,
            right: appPadding,
            bottom: appPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 36.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            appTextInputBorderRadius,
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: smallBorderWidth,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isSignInMode = true),
                              child: Container(
                                width: toggleButtonWidth,
                                alignment: Alignment.center,
                                child: Text(
                                  AppLocalizations.of(context)!.signIn,
                                  style: TextStyle(
                                    fontSize: fontSizeSmall,
                                    color:
                                        isSignInMode
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: smallBorderWidth,
                              height: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => isSignInMode = false),
                              child: Container(
                                width: toggleButtonWidth,
                                alignment: Alignment.center,
                                child: Text(
                                  AppLocalizations.of(context)!.signUp,
                                  style: TextStyle(
                                    fontSize: fontSizeSmall,
                                    color:
                                        !isSignInMode
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: appFormItemMargin),
                      SizedBox(height: appFormItemMargin),
                      SizedBox(height: appFormItemMargin),
                      SizedBox(
                        height: appTextInputHeight,
                        child: TextFormField(
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.center,
                          onFieldSubmitted: (_) {
                            if (_enablePinInput()) {
                              pInputFocusNode.requestFocus();
                            }
                          },
                          onChanged: (value) {
                            setState(() {});
                          },
                          onTapOutside: (event) {
                            userNameFocusNode.unfocus();
                          },
                          focusNode: userNameFocusNode,
                          controller: usernameController,
                          style: TextStyle(
                            fontSize: fontSizeMedium,
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
                            hintText: 'Username',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                appTextInputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                width: smallBorderWidth,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                appTextInputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                width: smallBorderWidth,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                appTextInputBorderRadius,
                              ),
                              borderSide: BorderSide(
                                width: smallBorderWidth,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            counterText: '',
                          ),
                          maxLength: pinInputMaxLength,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9_]'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: appFormItemMargin),
                      SizedBox(height: appFormItemMargin),
                      Pinput(
                        controller: pinController,
                        obscureText: true,
                        focusNode: pInputFocusNode,
                        enabled: _enablePinInput(),
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
                              width: smallBorderWidth,
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
                            (index) => const SizedBox(width: appPaddingSmall),
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                        onCompleted: (pin) {
                          AuthService().goIn(
                            usernameController.value.text,
                            pinController.value.text,
                            isSignInMode,
                          );
                          pinController.setText('');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Text(
                AppLocalizations.of(context)!.aboutContent,
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: appPadding),
              Text.rich(
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  color: Theme.of(context).colorScheme.primary,
                ),
                TextSpan(text: AppLocalizations.of(context)!.userNameGuide),
                textAlign: TextAlign.left,
              ),
              Text(
                AppLocalizations.of(context)!.passcodeGuide,
                style: TextStyle(
                  fontSize: fontSizeSmall,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _enablePinInput() {
    if (usernameController.value.text.isEmpty) {
      return false;
    }
    int charCode = usernameController.value.text.codeUnitAt(0);
    return usernameController.value.text.length >= pinInputMinLength &&
        ((charCode >= 65 && charCode <= 90) ||
            (charCode >= 97 && charCode <= 122) ||
            (charCode >= 48 && charCode <= 57) ||
            charCode == 95);
  }
}
