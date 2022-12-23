part of minerva_controller_generator;

class WebSocketEndpointPathBuildData {
  final String template;

  final String webSocketEndpointName;

  final String controllerPath;

  final String controllerShortName;

  WebSocketEndpointPathBuildData(
      {required this.template,
      required this.webSocketEndpointName,
      required this.controllerPath,
      required this.controllerShortName});
}
