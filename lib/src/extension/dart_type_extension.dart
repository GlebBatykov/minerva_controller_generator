part of minerva_controller_generator;

extension DartTypeExtension on DartType {
  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;

  bool get isNotNullable => !isNullable;
}
