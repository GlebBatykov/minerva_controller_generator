part of minerva_controller_generator;

class ApiData {
  final String name;

  final String shortName;

  final List<ActionData> actions;

  final List<WebSocketEndpointData> webSocketEndpoints;

  ApiData(
      {required this.name,
      required this.shortName,
      required this.actions,
      required this.webSocketEndpoints});
}
