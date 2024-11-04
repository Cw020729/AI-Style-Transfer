
import 'package:flutter/material.dart';


class TextObject {
  Offset textPosition;
  double size = 50;
  String text = "";
  bool isChangingText = true;
  bool isChangingColor = false;
  bool isEditingSize = false;
  Color color = Colors.black;
  TextObject({required this.textPosition});
}
