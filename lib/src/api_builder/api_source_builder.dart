part of minerva_controller_generator;

class ApiSourceBuilder {
  const ApiSourceBuilder();

  String build(ApiData data) {
    final actions = const ActionsSourceBuilder().build(data.name, data.actions);

    final webSocketEndpoints = const WebSocketEndpointsSourceBuilder()
        .build(data.name, data.webSocketEndpoints);

    return '''
class ${data.shortName}Api extends Api {
  final ControllerBase _controller = ${data.name}();

  @override
  Future<void> initialize(ServerContext context) async {
    await _controller.initialize(context);
  }

  @override
  void build(Endpoints endpoints) {
    $actions
    $webSocketEndpoints
  }

  @override
  Future<void> dispose(ServerContext context) async {
    await _controller.dispose(context);
  }
}
''';
  }
}
