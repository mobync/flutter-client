import 'dart:convert';

import 'package:flutter/cupertino.dart';

/// Typed response to be returned when performing Mobync operations on the Flutter app.
/// The [success] flag can not not be null.
class MobyncResponse {
  MobyncResponse({
    @required this.success,
    this.message,
    this.data,
  }) : assert(success != null);

  /// Flag to indicate if the operation succeeded.
  final bool success;

  /// Message in case it has failed.
  final String message;

  /// Data in case it succeeded and might return data.
  final List data;

  @override
  String toString() {
    String msgJsonString = json.encode(data);
    return '$success $message $msgJsonString';
  }
}
