import 'package:flutter/material.dart';

class MessageHelper {
  static void showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
