import 'package:intl/intl.dart';

/// Formatage des dates et durées en français.
///
/// Les formats sont construits sans dépendre des données de locale d'`intl`
/// (aucune initialisation requise), afin de rester utilisables dans les tests.
class Formatters {
  const Formatters._();

  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _clock = DateFormat('HH:mm');

  static const List<String> _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  static String shortDate(DateTime? date) =>
      date == null ? '—' : _shortDate.format(date);

  static String longDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  static String clock(DateTime? date) =>
      date == null ? '' : _clock.format(date);

  /// Heure relative compacte : « à l’instant », « il y a 5 min », « hier », …
  static String relative(DateTime? date) {
    if (date == null) return '';
    final Duration diff = DateTime.now().difference(date);
    if (diff.isNegative) return 'à l’instant';
    if (diff.inSeconds < 60) return 'à l’instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return shortDate(date);
  }
}
