import 'dart:math';

import 'package:flutter/material.dart';

class AvatarGenerator {
  static Color generateColor(String uid) {
    final seed = uid.hashCode;
    final random = Random(seed);
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  static String getInitials(String username) {
    List<String> names = username.split(" ");
    String initials = "";
    for (var name in names) {
      if (name.isNotEmpty) {
        initials += name[0];
      }
    }
    return initials.toUpperCase();
  }
}
