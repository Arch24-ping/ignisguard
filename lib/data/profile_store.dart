import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_store.dart';

enum HomeType {
  house('House'),
  apartment('Apartment'),
  office('Office'),
  other('Other');

  const HomeType(this.label);
  final String label;
}

class ProfileStore extends ChangeNotifier {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  String name = '';
  String country = '';
  String city = '';
  String phone = '';
  HomeType homeType = HomeType.house;
  int household = 1;

  bool get hasProfile =>
      name.isNotEmpty && country.isNotEmpty && city.isNotEmpty;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  String get location => city.isEmpty ? country : '$city, $country';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    name = p.getString('profile_name') ?? '';
    country = p.getString('profile_country') ?? '';
    city = p.getString('profile_city') ?? '';
    phone = p.getString('profile_phone') ?? '';
    final h = p.getInt('profile_home') ?? 0;
    homeType = HomeType.values[h.clamp(0, HomeType.values.length - 1)];
    household = (p.getInt('profile_people') ?? 1).clamp(1, 20);
  }

  Future<void> save({
    required String name,
    required String country,
    required String city,
    required String phone,
    required HomeType homeType,
    required int household,
  }) async {
    this.name = name;
    this.country = country;
    this.city = city;
    this.phone = phone;
    this.homeType = homeType;
    this.household = household;

    final p = await SharedPreferences.getInstance();
    await p.setString('profile_name', name);
    await p.setString('profile_country', country);
    await p.setString('profile_city', city);
    await p.setString('profile_phone', phone);
    await p.setInt('profile_home', homeType.index);
    await p.setInt('profile_people', household);
    CloudStore.instance.push('profile', toMap());
    notifyListeners();
  }
    Map<String, dynamic> toMap() => {
    'name': name,
    'country': country,
    'city': city,
    'phone': phone,
    'homeType': homeType.index,
    'household': household,
  };

  /// Replaces local values with the account's cloud copy (null = blank).
  void applyCloud(Map<String, dynamic>? m) {
    name = (m?['name'] ?? '') as String;
    country = (m?['country'] ?? '') as String;
    city = (m?['city'] ?? '') as String;
    phone = (m?['phone'] ?? '') as String;
    final h = (m?['homeType'] ?? 0) as int;
    homeType = HomeType.values[h.clamp(0, HomeType.values.length - 1)];
    household = ((m?['household'] ?? 1) as int).clamp(1, 20);
    notifyListeners();
  }
}
