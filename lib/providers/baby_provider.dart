import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/services/database_service.dart';
import 'package:flutter/material.dart';

class BabyProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;

  BabyProfile? babyProfile;
  bool isLoading = false;

  Future<void> loadBabyProfile() async {
    isLoading = true;
    notifyListeners();

    babyProfile = await _databaseService.getBabyProfile();

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveBabyProfile(BabyProfile profile) async {
    isLoading = true;
    notifyListeners();

    await _databaseService.saveBabyProfile(profile);
    babyProfile = await _databaseService.getBabyProfile();

    isLoading = false;
    notifyListeners();
  }
}
