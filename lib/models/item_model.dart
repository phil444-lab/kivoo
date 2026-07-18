import 'dart:convert';

class ItemModel {
  final int id;
  final String title;
  final String price;
  final String location;
  final String condition;
  final String time;
  final String photo;
  final bool verified;

  const ItemModel({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.condition,
    required this.time,
    required this.photo,
    required this.verified,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int,
      title: json['title'] as String,
      price: json['price'] as String,
      location: json['location'] as String,
      condition: json['condition'] as String,
      time: json['time'] as String,
      photo: json['photo'] as String,
      verified: json['verified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'location': location,
      'condition': condition,
      'time': time,
      'photo': photo,
      'verified': verified,
    };
  }
}