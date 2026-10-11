/// All user-visible strings in English and Urdu.
///
/// Layout always stays LTR (calculator convention); only the text itself
/// is localized. Add new UI copy here — never inline English in widgets.
class AppStrings {
  const AppStrings(this.languageCode);

  /// 'en' or 'ur'.
  final String languageCode;

  bool get isUrdu => languageCode == 'ur';

  static const Map<String, Map<String, String>> _t = {
    'en': {
      'tape': 'TAPE',
      'share': 'SHARE',
      'history': 'HISTORY',
      'total': 'TOTAL',
      'entries': '{n} ENTRIES',
      'image': 'Image',
      'text': 'Text',
      'copy': 'Copy',
      'copied': 'Copied',
      'copiedClipboard': 'Copied to clipboard',
      'saved': 'Saved',
      'save': 'Save',
      'cancel': 'Cancel',
      'close': 'Close',
      'continue': 'Continue',
      'startNew': 'Start New',
      'skip': 'Skip',
      'previousSession': 'Previous session',
      'continuePrevious': 'Continue previous calculation?',
      'nothingHereYet': 'Nothing here yet',
      'tapeEmptyHint':
          'Calculations you make will appear here\nfor fast visual scanning.',
      'clearTape': 'Clear tape',
      'shareCalculation': 'Share calculation',
      'savedNumbers': 'Saved numbers',
      'noSavedNumbers':
          'No saved numbers yet.\nLong-press the result and choose Save.',
      'edit': 'Edit',
      'delete': 'Delete',
      'editValue': 'Edit value',
      'totalRecalculates': 'The total recalculates automatically.',
      'steps': 'Steps',
      'showSteps': 'Show Steps',
      'shareAsImage': 'Share as image',
      'shareAsText': 'Share as text',
      'copyAsText': 'Copy as text',
      'imageShareFailed': 'Image share failed — shared as text instead',
      'settings': 'Settings',
      'fontSize': 'Font size',
      'small': 'Small',
      'medium': 'Medium',
      'large': 'Large',
      'fontWeight': 'Font weight',
      'regular': 'Regular',
      'bold': 'Bold',
      'language': 'Language',
      'theme': 'Theme',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'haptics': 'Haptics',
      'showChipOperators': 'Show +/− on chips',
      'noCalculationsYet': 'No calculations yet',
      'openTape': 'Open Tape',
      'openTapeCount': 'Open Tape, {n} entries',
      'openHistory': 'Open calculation history',
      'allClear': 'All clear',
      'deleteHint': 'Delete, long-press to clear all',
      'percent': 'Percent',
      'parenthesis': 'Parenthesis',
      'decimalPoint': 'Decimal point',
      'equalsHint': 'Equals, long-press to repeat',
      'entry': 'Entry {v}',
      'loadCalculation': 'Load calculation {e}',
      'undo': 'Undo',
      'inputCleared': 'Input cleared',
      'cleared': 'Cleared',
      'tapeCleared': 'Tape cleared',
      'entryDeleted': 'Entry deleted',
      'editUndone': 'Edit undone',
      'shareTitle': 'Title (optional)',
      'shareTitleHint': 'e.g. Karyana Khata',
      'shareStrip': 'Share',
      'swipeUpForTape': 'Swipe up for Tape',
      'errorPrefix': 'Error: ',
      'resultPrefix': 'Result: ',
      'madeWith': 'MADE WITH CALCONE',
    },
    'ur': {
      'tape': 'ٹیپ',
      'share': 'شیئر',
      'history': 'ہسٹری',
      'total': 'کل',
      'entries': '{n} اندراجات',
      'image': 'تصویر',
      'text': 'متن',
      'copy': 'کاپی',
      'copied': 'کاپی ہوگیا',
      'copiedClipboard': 'کلپ بورڈ میں کاپی ہوگیا',
      'saved': 'محفوظ ہوگیا',
      'save': 'محفوظ کریں',
      'cancel': 'منسوخ کریں',
      'close': 'بند کریں',
      'continue': 'جاری رکھیں',
      'startNew': 'نیا شروع کریں',
      'skip': 'چھوڑیں',
      'previousSession': 'پچھلا سیشن',
      'continuePrevious': 'پچھلا حساب جاری رکھیں؟',
      'nothingHereYet': 'ابھی کچھ نہیں ہے',
      'tapeEmptyHint': 'آپ کے حساب کتاب یہاں نظر آئیں گے\nفوری جائزے کے لیے۔',
      'clearTape': 'ٹیپ صاف کریں',
      'shareCalculation': 'حساب شیئر کریں',
      'savedNumbers': 'محفوظ نمبر',
      'noSavedNumbers':
          'ابھی کوئی نمبر محفوظ نہیں۔\nنتیجے کو دیر تک دبائیں اور Save منتخب کریں۔',
      'edit': 'ترمیم',
      'delete': 'حذف کریں',
      'editValue': 'قدر بدلیں',
      'totalRecalculates': 'کل خودکار طور پر دوبارہ حساب ہوگا۔',
      'steps': 'مراحل',
      'showSteps': 'مراحل دیکھیں',
      'shareAsImage': 'تصویر کے طور پر شیئر کریں',
      'shareAsText': 'متن کے طور پر شیئر کریں',
      'copyAsText': 'متن کاپی کریں',
      'imageShareFailed': 'تصویر شیئر ناکام — متن کے طور پر شیئر کیا گیا',
      'settings': 'ترتیبات',
      'fontSize': 'فونٹ کا سائز',
      'small': 'چھوٹا',
      'medium': 'درمیانہ',
      'large': 'بڑا',
      'fontWeight': 'فونٹ کا وزن',
      'regular': 'نارمل',
      'bold': 'بولڈ',
      'language': 'زبان',
      'theme': 'تھیم',
      'system': 'سسٹم',
      'light': 'ہلکی',
      'dark': 'گہری',
      'haptics': 'وائبریشن',
      'showChipOperators': 'چپس پر +/− دکھائیں',
      'noCalculationsYet': 'ابھی کوئی حساب نہیں',
      'openTape': 'ٹیپ کھولیں',
      'openTapeCount': 'ٹیپ کھولیں، {n} اندراجات',
      'openHistory': 'حساب کی ہسٹری کھولیں',
      'allClear': 'سب صاف کریں',
      'deleteHint': 'حذف کریں، سب صاف کرنے کے لیے دیر تک دبائیں',
      'percent': 'فیصد',
      'parenthesis': 'قوسین',
      'decimalPoint': 'اعشاریہ',
      'equalsHint': 'برابر، دہرانے کے لیے دیر تک دبائیں',
      'entry': 'اندراج {v}',
      'loadCalculation': 'حساب لوڈ کریں {e}',
      'undo': 'واپس کریں',
      'inputCleared': 'ان پٹ صاف کردی گئی',
      'cleared': 'صاف کردیا گیا',
      'tapeCleared': 'ٹیپ صاف کردی گئی',
      'entryDeleted': 'اندراج حذف کردیا گیا',
      'editUndone': 'ترمیم واپس کردی گئی',
      'shareTitle': 'عنوان (اختیاری)',
      'shareTitleHint': 'مثلاً کریانہ کھاتہ',
      'shareStrip': 'شیئر کریں',
      'swipeUpForTape': 'ٹیپ کے لیے سوائپ کریں',
      'errorPrefix': 'خرابی: ',
      'resultPrefix': 'نتیجہ: ',
      'madeWith': 'MADE WITH CALCONE',
    },
  };

  /// Engine error messages by key.
  static const Map<String, Map<String, String>> _errors = {
    'en': {
      'divisionByZero': 'Cannot divide by zero.',
      'malformedExpression':
          'That expression isn\'t valid. Check your operators and try again.',
      'emptyInput': 'Enter a number to calculate.',
      'unmatchedParentheses':
          'Check your parentheses — one of them isn\'t closed.',
      'overflow': 'That number is too large to display.',
      'unsupportedOperation': 'That operation isn\'t supported yet.',
      'invalidAngleValue': 'That value is out of range for this function.',
    },
    'ur': {
      'divisionByZero': 'صفر سے تقسیم نہیں ہوسکتی۔',
      'malformedExpression':
          'یہ حساب درست نہیں۔ اپنے آپریٹرز دیکھیں اور دوبارہ کوشش کریں۔',
      'emptyInput': 'حساب کے لیے ایک نمبر درج کریں۔',
      'unmatchedParentheses': 'قوسین دیکھیں — ایک بند نہیں ہے۔',
      'overflow': 'یہ نمبر دکھانے کے لیے بہت بڑا ہے۔',
      'unsupportedOperation': 'یہ آپریشن ابھی دستیاب نہیں۔',
      'invalidAngleValue': 'یہ قدر اس فنکشن کے لیے حد سے باہر ہے۔',
    },
  };

  String _get(String key) => _t[languageCode]?[key] ?? _t['en']![key]!;

  String error(String key) =>
      _errors[languageCode]?[key] ?? _errors['en']![key]!;

  // Named getters — prefer these over raw keys in widgets.
  String get tape => _get('tape');
  String get share => _get('share');
  String get history => _get('history');
  String get total => _get('total');
  String entries(int n) => _get('entries').replaceAll('{n}', '$n');
  String get image => _get('image');
  String get text => _get('text');
  String get copy => _get('copy');
  String get copied => _get('copied');
  String get copiedClipboard => _get('copiedClipboard');
  String get saved => _get('saved');
  String get save => _get('save');
  String get cancel => _get('cancel');
  String get close => _get('close');
  String get cont => _get('continue');
  String get startNew => _get('startNew');
  String get skip => _get('skip');
  String get previousSession => _get('previousSession');
  String get continuePrevious => _get('continuePrevious');
  String get nothingHereYet => _get('nothingHereYet');
  String get tapeEmptyHint => _get('tapeEmptyHint');
  String get clearTape => _get('clearTape');
  String get shareCalculation => _get('shareCalculation');
  String get savedNumbers => _get('savedNumbers');
  String get noSavedNumbers => _get('noSavedNumbers');
  String get edit => _get('edit');
  String get delete => _get('delete');
  String get editValue => _get('editValue');
  String get totalRecalculates => _get('totalRecalculates');
  String get steps => _get('steps');
  String get showSteps => _get('showSteps');
  String get shareAsImage => _get('shareAsImage');
  String get shareAsText => _get('shareAsText');
  String get copyAsText => _get('copyAsText');
  String get imageShareFailed => _get('imageShareFailed');
  String get settings => _get('settings');
  String get fontSize => _get('fontSize');
  String get small => _get('small');
  String get medium => _get('medium');
  String get large => _get('large');
  String get fontWeight => _get('fontWeight');
  String get regular => _get('regular');
  String get bold => _get('bold');
  String get language => _get('language');
  String get theme => _get('theme');
  String get system => _get('system');
  String get light => _get('light');
  String get dark => _get('dark');
  String get haptics => _get('haptics');
  String get showChipOperators => _get('showChipOperators');
  String get noCalculationsYet => _get('noCalculationsYet');
  String get openTape => _get('openTape');
  String openTapeCount(int n) => _get('openTapeCount').replaceAll('{n}', '$n');
  String get openHistory => _get('openHistory');
  String get allClear => _get('allClear');
  String get deleteHint => _get('deleteHint');
  String get percent => _get('percent');
  String get parenthesis => _get('parenthesis');
  String get decimalPoint => _get('decimalPoint');
  String get equalsHint => _get('equalsHint');
  String entry(String v) => _get('entry').replaceAll('{v}', v);
  String loadCalculation(String e) =>
      _get('loadCalculation').replaceAll('{e}', e);
  String get undo => _get('undo');
  String get inputCleared => _get('inputCleared');
  String get cleared => _get('cleared');
  String get tapeCleared => _get('tapeCleared');
  String get entryDeleted => _get('entryDeleted');
  String get editUndone => _get('editUndone');
  String get shareTitle => _get('shareTitle');
  String get shareTitleHint => _get('shareTitleHint');
  String get shareStrip => _get('shareStrip');
  String get swipeUpForTape => _get('swipeUpForTape');
  String get errorPrefix => _get('errorPrefix');
  String get resultPrefix => _get('resultPrefix');
  String get madeWith => _get('madeWith');
}
