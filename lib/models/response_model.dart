import 'dart:convert';

import 'package:flutter/cupertino.dart';

class MobyncResponse {
  MobyncResponse({
    @required this.success,
    this.message,
    this.data,
  }) : assert(success != null);

  final bool success;
  final String message;
  final List data;

  @override
  String toString() {
    String msgJsonString = json.encode(data);
    return '$success $message $msgJsonString';
  }
}
