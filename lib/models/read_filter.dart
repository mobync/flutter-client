import 'package:mobync/constants/constants.dart';

/// Typed filters to be given as parameters to the read function.
class ReadFilter {
  ReadFilter(this.fieldName, this.filterBy, this.data)
      : assert(fieldName != null && filterBy != null && data != null);

  /// Field that will be used to filter out some element.
  final String fieldName;

  /// Criteria that will be used to compare the field from the element and the
  /// provided data.
  final FilterType filterBy;

  /// Data data will be used to make the comparision.
  final data;
}
