import 'package:blink/get_it_setup.dart';
import 'package:blink/l10n/app_localizations.dart';
import 'package:blink/settings/fixed_settings.dart';
import 'package:flutter/material.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContenttState();
}

class _HomeContenttState extends State<HomeContent> {
  late final FocusNode searchFieldFocusNode;

  @override
  void initState() {
    super.initState();
    searchFieldFocusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: appTextInputHeight,
      child: TextField(
        focusNode: searchFieldFocusNode,
        onTapOutside: (event) {
          searchFieldFocusNode.unfocus();
        },
        style: const TextStyle(fontSize: appTextInputFontSize),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
          hintText: getIt<AppLocalizations>().searchHint,
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        onSubmitted: (value) {},
      ),
    );
  }
}
