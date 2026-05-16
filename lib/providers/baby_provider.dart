import 'package:baby_subscription/models/baby_profile.dart';
import 'package:baby_subscription/services/database_service.dart';
import 'package:flutter/material.dart';

class BabyProvider extends ChangeNotifier {
  List<BabyProfile> _profiles = [];
  BabyProfile? _selectedProfile;
  bool _isLoading = false;
  String? _errorMessage;

  List<BabyProfile> get profiles => List.unmodifiable(_profiles);
  BabyProfile? get selectedProfile => _selectedProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfiles => _profiles.isNotEmpty;

  Future<void> loadProfiles(int userId) async {
    _setLoading(true);
    try {
      _profiles = await DatabaseService.instance.getBabyProfiles(userId);
      if (_profiles.isNotEmpty && _selectedProfile == null) {
        _selectedProfile = _profiles.first;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error cargando perfiles: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveProfile(BabyProfile profile, int userId) async {
    _setLoading(true);
    try {
      final saved = await DatabaseService.instance.saveBabyProfile(profile, userId);
      if (profile.id != null) {
        final idx = _profiles.indexWhere((p) => p.id == profile.id);
        if (idx >= 0) _profiles[idx] = saved;
        if (_selectedProfile?.id == profile.id) _selectedProfile = saved;
      } else {
        _profiles.add(saved);
        _selectedProfile ??= saved;
      }
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error guardando perfil: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProfile(int profileId) async {
    _setLoading(true);
    try {
      await DatabaseService.instance.deleteBabyProfile(profileId);
      _profiles.removeWhere((p) => p.id == profileId);
      if (_selectedProfile?.id == profileId) {
        _selectedProfile = _profiles.isNotEmpty ? _profiles.first : null;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error eliminando perfil: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectProfile(BabyProfile profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  void clearProfiles() {
    _profiles = [];
    _selectedProfile = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
