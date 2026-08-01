import 'package:flutter/material.dart';

class FeatureCardModel {
  final int id;
  final String title;
  final String subtitle;
  final dynamic icon;
  final String borderColor;
  final String darkBg;
  final String lightBg;
  final String? time;

  const FeatureCardModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.borderColor,
    required this.darkBg,
    required this.lightBg,
    this.time,
  });

  factory FeatureCardModel.fromJson(Map<String, dynamic> json) {
    return FeatureCardModel(
      id: json['id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      icon: Icons.star,
      borderColor: json['borderColor'] as String,
      darkBg: json['darkBg'] as String,
      lightBg: json['lightBg'] as String,
      time: json['time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'borderColor': borderColor,
      'darkBg': darkBg,
      'lightBg': lightBg,
      if (time != null) 'time': time,
    };
  }
}
