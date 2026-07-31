class Country {
  final String id;
  final String name;
  final String code;

  Country({
    required this.id,
    required this.name,
    required this.code,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Country && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Department {
  final String id;
  final String name;
  final String countryId;

  Department({
    required this.id,
    required this.name,
    required this.countryId,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      name: json['name'] as String,
      countryId: json['countryId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Department && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class City {
  final String id;
  final String name;
  final String departmentId;

  City({
    required this.id,
    required this.name,
    required this.departmentId,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      departmentId: json['departmentId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is City && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class District {
  final String id;
  final String name;
  final String cityId;

  District({
    required this.id,
    required this.name,
    required this.cityId,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as String,
      name: json['name'] as String,
      cityId: json['cityId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is District && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Représente la localisation complète d'un utilisateur
class UserLocation {
  final String country;
  final String department;
  final String city;
  final String district;

  UserLocation({
    required this.country,
    required this.department,
    required this.city,
    required this.district,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      country: json['country'] as String? ?? '',
      department: json['department'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'department': department,
      'city': city,
      'district': district,
    };
  }

  bool get isEmpty =>
      country.isEmpty &&
      department.isEmpty &&
      city.isEmpty &&
      district.isEmpty;

  String get formatted {
    if (isEmpty) return 'Non renseignée';
    final parts = [country, department, city, district]
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}