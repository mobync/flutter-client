import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class MobyncResponse extends Equatable {
  MobyncResponse({
    @required this.success,
    this.message,
    this.data,
  });

  final bool success;
  final String message;
  final List data;

  @override
  List<Object> get props => [success, message, data];

  @override
  String toString() {
    String msgJsonString = json.encode(data);
    return '$success $message $msgJsonString';
  }
}
