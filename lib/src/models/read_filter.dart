import 'package:mobync/src/constants/constants.dart';

class ReadFilter {
  String fieldName;
  FilterType filterBy;
  var data;
  ReadFilter(this.fieldName, this.filterBy, this.data);
}