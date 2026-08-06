import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FeatureCardModel {
  final String id;
  final String title;
  final String subtitle;
  final dynamic icon;
  final String borderColor;
  final String darkBg;
  final String lightBg;

  const FeatureCardModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.borderColor,
    required this.darkBg,
    required this.lightBg,
  });

  factory FeatureCardModel.fromJson(Map<String, dynamic> json) {
    return FeatureCardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      icon: _iconForKey(json['icon'] as String? ?? ''),
      borderColor: json['borderColor'] as String,
      darkBg: json['darkBg'] as String,
      lightBg: json['lightBg'] as String,
    );
  }

  static dynamic _iconForKey(String key) {
    switch (key) {
      case 'gift':         return FontAwesomeIcons.gift;
      case 'star':         return FontAwesomeIcons.star;
      case 'circle-check': return FontAwesomeIcons.circleCheck;
      case 'bolt':         return FontAwesomeIcons.bolt;
      case 'tag':          return FontAwesomeIcons.tag;
      case 'fire':         return FontAwesomeIcons.fire;
      case 'percent':      return FontAwesomeIcons.percent;
      case 'truck':        return FontAwesomeIcons.truck;
      default:             return FontAwesomeIcons.tag;
    }
  }
}
