import 'dart:math';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:story_editor/models/editor_configs/story_editor_configs.dart';
import 'package:story_editor/modules/emoji_editor/utils/emoji_editor_category_view.dart';

import '../../models/layer.dart';
import '../../models/theme/theme_shared_values.dart';
import '../../utils/design_mode.dart';
import 'utils/emoji_editor_full_screen_search.dart';
import 'utils/emoji_editor_header_search.dart';

/// The `EmojiEditor` class is responsible for creating a widget that allows users to select emojis.
///
/// This widget provides an EmojiPicker that allows users to choose emojis, which are then returned
/// as `EmojiLayerData` containing the selected emoji text.
class EmojiEditor extends StatefulWidget {
  /// The image editor configs
  final StoryEditorConfigs configs;

  /// Creates an `EmojiEditor` widget.
  const EmojiEditor({
    super.key,
    this.configs = const StoryEditorConfigs(),
  });

  @override
  createState() => EmojiEditorState();
}

/// The state class for the `EmojiEditor` widget.
class EmojiEditorState extends State<EmojiEditor> {
  final _emojiPickerKey = GlobalKey<EmojiPickerState>();
  final _emojiSearchPageKey = GlobalKey<EmojiEditorFullScreenSearchViewState>();

  late final EmojiTextEditingController _controller;

  late final TextStyle _textStyle;
  final bool isApple = [TargetPlatform.iOS, TargetPlatform.macOS]
      .contains(defaultTargetPlatform);
  bool _showExternalSearchPage = false;

  @override
  void initState() {
    final fontSize = 24 * (isApple ? 1.2 : 1.0);
    _textStyle = widget.configs.emojiEditorConfigs.textStyle
        .copyWith(fontSize: fontSize);

    _controller = EmojiTextEditingController(emojiTextStyle: _textStyle);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Closes the editor without applying changes.
  void close() {
    Navigator.pop(context);
  }

  /// Search emojis
  void externSearch(String text) {
    setState(() {
      _showExternalSearchPage = text.isNotEmpty;
    });
    Future.delayed(Duration(
            milliseconds: _emojiSearchPageKey.currentState == null ? 30 : 0))
        .whenComplete(() {
      _emojiSearchPageKey.currentState?.search(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    var content = LayoutBuilder(
      builder: (context, constraints) {
        return _buildEmojiPickerSizedBox(constraints, context);
      },
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: content,
      ),
    );
  }

  /// Builds a SizedBox containing the EmojiPicker with dynamic sizing.
  Widget _buildEmojiPickerSizedBox(
      BoxConstraints constraints, BuildContext context) {
    if (_showExternalSearchPage) {
      return EmojiEditorFullScreenSearchView(
        key: _emojiSearchPageKey,
        config: _getEditorConfig(constraints),
        state: EmojiViewState(
          widget.configs.emojiEditorConfigs.emojiSet,
          (category, emoji) {
            Navigator.pop(
              context,
              EmojiLayerData(emoji: emoji.emoji),
            );
          },
          () {},
          () {},
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EmojiPicker(
          key: _emojiPickerKey,
          onEmojiSelected: (category, emoji) => {
            Navigator.pop(
              context,
              EmojiLayerData(emoji: emoji.emoji),
            ),
          },
          textEditingController: _controller,
          config: _getEditorConfig(constraints),
        ),
      ),
    );
  }

  Config _getEditorConfig(BoxConstraints constraints) {
    return Config(
      height: max(
        50,
        min(320, constraints.maxHeight) - MediaQuery.of(context).padding.bottom,
      ),
      emojiSet: widget.configs.emojiEditorConfigs.emojiSet,
      checkPlatformCompatibility:
          widget.configs.emojiEditorConfigs.checkPlatformCompatibility,
      emojiTextStyle: _textStyle.copyWith(fontSize: null),
      emojiViewConfig: widget.configs.emojiEditorConfigs.emojiViewConfig ??
          EmojiViewConfig(
            gridPadding: EdgeInsets.zero,
            horizontalSpacing: 0,
            verticalSpacing: 0,
            recentsLimit: 28,
            backgroundColor: imageEditorBackgroundColor,
            noRecents: Text(
              widget.configs.i18n.emojiEditor.noRecents,
              style: const TextStyle(fontSize: 20, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            buttonMode:
                widget.configs.designMode == ImageEditorDesignModeE.cupertino
                    ? ButtonMode.CUPERTINO
                    : ButtonMode.MATERIAL,
            loadingIndicator: const Center(child: CircularProgressIndicator()),
            columns: _calculateColumns(constraints),
            emojiSizeMax:
                widget.configs.designMode == ImageEditorDesignModeE.cupertino
                    ? 32
                    : 64,
            replaceEmojiOnLimitExceed: false,
          ),
      swapCategoryAndBottomBar:
          widget.configs.emojiEditorConfigs.swapCategoryAndBottomBar,
      skinToneConfig: widget.configs.emojiEditorConfigs.skinToneConfig,
      categoryViewConfig:
          widget.configs.emojiEditorConfigs.categoryViewConfig ??
              CategoryViewConfig(
                initCategory: Category.RECENT,
                backgroundColor: imageEditorBackgroundColor,
                indicatorColor: imageEditorPrimaryColor,
                iconColorSelected: imageEditorPrimaryColor,
                iconColor: const Color(0xFF9E9E9E),
                tabIndicatorAnimDuration: kTabScrollDuration,
                dividerColor: Colors.black,
                customCategoryView: (
                  config,
                  state,
                  tabController,
                  pageController,
                ) {
                  return EmojiEditorCategoryView(
                    config,
                    state,
                    tabController,
                    pageController,
                  );
                },
                categoryIcons: const CategoryIcons(
                  recentIcon: Icons.access_time_outlined,
                  smileyIcon: Icons.emoji_emotions_outlined,
                  animalIcon: Icons.cruelty_free_outlined,
                  foodIcon: Icons.coffee_outlined,
                  activityIcon: Icons.sports_soccer_outlined,
                  travelIcon: Icons.directions_car_filled_outlined,
                  objectIcon: Icons.lightbulb_outline,
                  symbolIcon: Icons.emoji_symbols_outlined,
                  flagIcon: Icons.flag_outlined,
                ),
              ),
      bottomActionBarConfig:
          widget.configs.emojiEditorConfigs.bottomActionBarConfig,
      searchViewConfig: widget.configs.emojiEditorConfigs.searchViewConfig ??
          SearchViewConfig(
            backgroundColor: imageEditorBackgroundColor,
            buttonIconColor: imageEditorTextColor,
            customSearchView: (
              config,
              state,
              showEmojiView,
            ) {
              return EmojiEditorHeaderSearchView(
                config,
                state,
                showEmojiView,
                i18n: widget.configs.i18n,
              );
            },
          ),
    );
  }

  /// Calculates the number of columns for the EmojiPicker.
  int _calculateColumns(BoxConstraints constraints) => max(
          1,
          (widget.configs.designMode != ImageEditorDesignModeE.cupertino
                      ? 6
                      : 10) /
                  400 *
                  constraints.maxWidth -
              1)
      .floor();
}
