import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoryModel {
  final String id;
  final dynamic icon;
  final String label;
  final String color;

  const CategoryModel({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final color = json['color'] as String? ?? _colorForCategory(name);
    return CategoryModel(
      id: json['id'] as String,
      icon: _iconForCategory(name),
      label: name,
      color: color,
    );
  }

  static dynamic _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('véhicule') || n.contains('vehicule') || n.contains('auto')) return FontAwesomeIcons.car;
    if (n.contains('maison') || n.contains('logement')) return FontAwesomeIcons.house;
    if (n.contains('immobilier')) return FontAwesomeIcons.building;
    if (n.contains('téléphone') || n.contains('telephone') || n.contains('mobile')) return FontAwesomeIcons.mobileScreen;
    if (n.contains('emploi') || n.contains('travail') || n.contains('job')) return FontAwesomeIcons.briefcase;
    if (n.contains('mode') || n.contains('vêtement') || n.contains('vetement')) return FontAwesomeIcons.shirt;
    if (n.contains('fashion') || n.contains('habillement')) return FontAwesomeIcons.shirt;
    if (n.contains('bébé') || n.contains('bebe') || n.contains('enfant')) return FontAwesomeIcons.baby;
    if (n.contains('équipement') || n.contains('equipement') || n.contains('industriel') || n.contains('pro')) return FontAwesomeIcons.industry;
    if (n.contains('meuble') || n.contains('maison') || n.contains('déco')) return FontAwesomeIcons.chair;
    if (n.contains('animal') || n.contains('animaux') || n.contains('pet')) return FontAwesomeIcons.paw;
    if (n.contains('service')) return FontAwesomeIcons.screwdriverWrench;
    if (n.contains('électronique') || n.contains('electronique') || n.contains('informatique')) return FontAwesomeIcons.laptop;
    if (n.contains('sport') || n.contains('loisir')) return FontAwesomeIcons.football;
    if (n.contains('agriculture') || n.contains('élevage') || n.contains('elevage')) return FontAwesomeIcons.tractor;
    if (n.contains('alimentation') || n.contains('nourriture')) return FontAwesomeIcons.utensils;
    if (n.contains('santé') || n.contains('sante') || n.contains('beauté') || n.contains('beaute')) return FontAwesomeIcons.heartPulse;
    if (n.contains('éducation') || n.contains('education') || n.contains('formation')) return FontAwesomeIcons.graduationCap;
    return FontAwesomeIcons.tag;
  }

  static String _colorForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('véhicule') || n.contains('vehicule') || n.contains('auto')) return '#ff6b35';
    if (n.contains('immobilier') || n.contains('maison') || n.contains('logement')) return '#4f8ef7';
    if (n.contains('téléphone') || n.contains('telephone') || n.contains('mobile')) return '#22c55e';
    if (n.contains('emploi') || n.contains('travail') || n.contains('job')) return '#f59e0b';
    if (n.contains('mode') || n.contains('vêtement') || n.contains('vetement')) return '#ec4899';
    if (n.contains('fashion') || n.contains('habillement')) return '#f43f5e';
    if (n.contains('bébé') || n.contains('bebe') || n.contains('enfant')) return '#fb923c';
    if (n.contains('équipement') || n.contains('equipement') || n.contains('industriel') || n.contains('pro')) return '#64748b';
    if (n.contains('meuble') || n.contains('maison') || n.contains('déco')) return '#06b6d4';
    if (n.contains('animal') || n.contains('animaux') || n.contains('pet')) return '#a855f7';
    if (n.contains('service')) return '#ef4444';
    if (n.contains('électronique') || n.contains('electronique') || n.contains('informatique')) return '#3b82f6';
    if (n.contains('sport') || n.contains('loisir')) return '#10b981';
    if (n.contains('agriculture') || n.contains('élevage') || n.contains('elevage')) return '#84cc16';
    if (n.contains('alimentation') || n.contains('nourriture')) return '#f97316';
    if (n.contains('santé') || n.contains('sante') || n.contains('beauté') || n.contains('beaute')) return '#e11d48';
    if (n.contains('éducation') || n.contains('education') || n.contains('formation')) return '#7c3aed';
    return '#64748b';
  }
}
