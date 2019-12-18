import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

String getValueAnnotation(Element element, ConstantReader annotation, String attributeAnnotation) {
  try {
    return annotation.read(attributeAnnotation).stringValue;
  } catch (FormatException) {
    return null;
  }
}
