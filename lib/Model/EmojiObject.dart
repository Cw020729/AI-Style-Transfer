
import 'package:flutter/material.dart';
import 'package:emoji_selector/emoji_selector.dart';


class EmojiObject {
  Offset emojiPosition;
  double size = 50;
  EmojiData emojiData;
  bool isChangingEmoji = true;
  bool isEditingSize = false;

  EmojiObject({required this.emojiPosition, required this.emojiData});
}