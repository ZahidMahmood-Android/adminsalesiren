import 'package:intl/intl.dart';

extension AppDateFormatting on DateTime {
  String get shortDate => DateFormat('MMM d, yyyy').format(this);
  String get compactDateTime => DateFormat('MMM d, yyyy, h:mm a').format(this);
}
