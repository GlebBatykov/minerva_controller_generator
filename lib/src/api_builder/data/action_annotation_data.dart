part of minerva_controller_generator;

class ActionAnnotationData {
  final ActionHttpMethod method;

  final String template;

  final ExecutableElement? errorHandler;

  final DartObject authOptions;

  final DartObject filter;

  ActionAnnotationData(
      {required this.method,
      required this.template,
      required this.errorHandler,
      required this.authOptions,
      required this.filter});
}
