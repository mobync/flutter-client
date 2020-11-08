import 'package:mobync/constants/constants.dart';

class ReadFilter {
  ReadFilter(this.fieldName, this.filterBy, this.data)
      : assert(fieldName != null && filterBy != null && data != null);

  final String fieldName;
  final FilterType filterBy;
  final data;
}
