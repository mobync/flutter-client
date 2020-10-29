import 'package:mobync/constants/constants.dart';

class ReadFilter {
  ReadFilter(this.fieldName, this.filterBy, this.data);

  final String fieldName;
  final FilterType filterBy;
  final data;
}
