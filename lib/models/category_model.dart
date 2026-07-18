import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final IconData icon;
  final String label;
  final String color;

  const CategoryModel({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      icon: Icons.category,
      label: json['label'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color': color,
    };
  }
}
