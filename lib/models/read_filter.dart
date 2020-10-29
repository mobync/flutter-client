import 'package:mobync/constants/constants.dart';

class ReadFilter {
  String fieldName;
  FilterType filterBy;
  var data;
  ReadFilter(this.fieldName, this.filterBy, this.data);
}
