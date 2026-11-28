class BrandDetector {
  const BrandDetector._();

  static const List<String> popularBrands = [
    'AHM Oil',
    'Motul',
    'Shell',
    'Yamalube',
    'Castrol',
    'Federal',
    'NGK',
    'Nissin',
    'Brembo',
    'Aspira',
    'Daytona',
    'FDR',
    'Michelin',
    'Pirelli',
    'IRC',
    'Bridgestone',
    'Denso',
    'GS Astra',
    'Original / OEM',
  ];

  static const Map<String, List<String>> _keywordMap = {
    'AHM Oil': ['ahm oil', 'spx2', 'spx 2', 'spx1', 'spx 1', 'mpx2', 'mpx 2', 'mpx1', 'mpx 1'],
    'Motul': ['motul'],
    'Shell': ['shell advance', 'shell helix', 'shell'],
    'Yamalube': ['yamalube'],
    'Castrol': ['castrol'],
    'Pertamina': ['fastron', 'enduro', 'mesran'],
    'Federal': ['federal oil', 'federal'],
    'Liqui Moly': ['liqui moly', 'liquimoly'],
    'NGK': ['ngk'],
    'Denso': ['denso'],
    'Nissin': ['nissin'],
    'Brembo': ['brembo'],
    'Elig': ['elig'],
    'Aspira': ['aspira'],
    'Daytona': ['daytona'],
    'TDR': ['tdr'],
    'FDR': ['fdr'],
    'Michelin': ['michelin'],
    'Pirelli': ['pirelli'],
    'Maxxis': ['maxxis'],
    'IRC': ['irc'],
    'Bridgestone': ['bridgestone'],
    'Dunlop': ['dunlop'],
    'GS Astra': ['gs astra'],
    'Yuasa': ['yuasa'],
    'KYB': ['kyb', 'kayaba'],
    'Ohlins': ['ohlins'],
    'Original / OEM': ['honda genuine', 'yamaha genuine', 'toyota genuine', 'original', 'ori ', 'oem'],
  };

  /// Attempts to infer a known sparepart/oil brand from free-form text.
  static String? detectFromText(String text) {
    final lower = ' ${text.toLowerCase()} ';
    for (final entry in _keywordMap.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
