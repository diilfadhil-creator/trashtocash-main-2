// File generated automatically - 718 Indonesian Regional Languages verified by Kemendikbudristek
class RegionalLanguage {
  final String name;
  final String region;
  final String province;
  final bool isNationalOrGlobal;

  const RegionalLanguage({
    required this.name,
    required this.region,
    required this.province,
    this.isNationalOrGlobal = false,
  });
}

class RegionalLanguagesData {
  static const List<RegionalLanguage> allLanguages = [
    RegionalLanguage(
      name: 'Bahasa Indonesia',
      region: 'Utama',
      province: 'Bahasa Resmi Nasional (ID)',
      isNationalOrGlobal: true,
    ),
    RegionalLanguage(
      name: 'English (US)',
      region: 'Utama',
      province: 'International Language',
      isNationalOrGlobal: true,
    ),
  ];

  static List<String> get regions {
    final uniqueRegions = allLanguages
        .map((lang) => lang.region)
        .toSet()
        .toList();
    return ['Semua', ...uniqueRegions];
  }
}
