part of minerva_controller_generator;

class ActionData {
  final String methodName;

  final String path;

  final List<ParameterElement> parameters;

  final ActionAnnotationData annotationData;

  ActionData(
      {required this.methodName,
      required this.path,
      required this.parameters,
      required this.annotationData});
}
