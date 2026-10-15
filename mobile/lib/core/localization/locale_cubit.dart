import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/local_storage/secure_storage_service.dart';

enum AppLanguage {
  english(code: 'en', name: 'English', nativeName: 'English', isRtl: false),
  urdu(code: 'ur', name: 'Urdu', nativeName: 'اردو · Urdu', isRtl: true),
  hindi(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी · Hindi', isRtl: false),
  arabic(code: 'ar', name: 'Arabic', nativeName: 'العربية · Arabic', isRtl: true);

  final String code;
  final String name;
  final String nativeName;
  final bool isRtl;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.isRtl,
  });

  Locale get locale => Locale(code);
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code.toLowerCase() == code.toLowerCase(),
      orElse: () => AppLanguage.english,
    );
  }
}

class LocaleCubit extends Cubit<AppLanguage> {
  final SecureStorageService _storage;
  static const _langKey = 'pigeonfly_selected_language';

  LocaleCubit(this._storage) : super(AppLanguage.english) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final savedCode = await _storage.readCustom(_langKey);
    if (savedCode != null && savedCode.isNotEmpty) {
      emit(AppLanguage.fromCode(savedCode));
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _storage.writeCustom(_langKey, language.code);
    emit(language);
  }
}
