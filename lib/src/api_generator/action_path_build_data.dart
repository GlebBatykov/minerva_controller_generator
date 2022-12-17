part of minerva_controller_generator;

class ActionPathBuildData {
  final String template;

  final String actionName;

  final String controllerPath;

  final String controllerShortName;

  ActionPathBuildData(
      {required this.template,
      required this.actionName,
      required this.controllerPath,
      required this.controllerShortName});
}
