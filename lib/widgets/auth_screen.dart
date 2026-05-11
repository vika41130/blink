import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:toggle_switch/toggle_switch.dart';

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
              Text(
                AppLocalizations.of(context)!.authTitle,
                style: TextStyle(
                  fontSize: appTitleFontSize,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: appTitleMarginLarge),
              SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ToggleSwitch(
                        customWidths: [toggleButtonWidth, toggleButtonWidth],
                        cornerRadius: appBorderRadius,
                        borderWidth: smallBorderWidth,
                        borderColor: [
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        activeFgColor: Theme.of(context).colorScheme.primary,
                        inactiveBgColor: Colors.transparent,
                        inactiveFgColor:
                            Theme.of(context).colorScheme.surfaceBright,
                        totalSwitches: 2,
                        labels: [
                          AppLocalizations.of(context)!.signIn,
                          AppLocalizations.of(context)!.signUp,
                        ],
                        onToggle: (index) {
                          isSignInMode = index == 0;
                          // setState(() {
                          //   // isSignedIn = index == 0;
                          // });
                        },
                      ),
                      SizedBox(height: formItemMargin),
                      SizedBox(height: formItemMargin),
                      SizedBox(height: formItemMargin),
                      TextFormField(
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
                          hintStyle: TextStyle(
                            fontSize: fontSizeSmall,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          hintText: 'Username',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: smallBorderWidth,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: smallBorderWidth,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
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
                          // This allows only a-z, A-Z, 0-9, and _
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9_]'),
                          ),
                        ],
                      ),
                      SizedBox(height: formItemMargin),
                      Pinput(
                        controller: pinController,
                        obscureText: true,
                        focusNode: pInputFocusNode,
                        enabled: _enablePinInput(),
                        defaultPinTheme: PinTheme(
                          width: pinItemWidth,
                          height: pinItemHeight,
                          textStyle: TextStyle(
                            fontSize: pinInputValueFontSize,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                                width: smallBorderWidth,
                              ),
                            ),
                          ),
                        ),
                        showCursor: true,
                        cursor: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: pinItemWidth,
                              height: mediumBorderWidth,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                        separatorBuilder:
                            (index) => const SizedBox(
                              width: pinInputSeparatorWidth,
                              height: pinInputSeparatorWidth,
                            ),
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
            (charCode >= 97 && charCode <= 122));
  }
}
