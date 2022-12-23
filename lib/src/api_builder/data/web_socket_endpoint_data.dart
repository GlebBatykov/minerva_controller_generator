part of minerva_controller_generator;

class WebSocketEndpointData {
  final String methodName;

  final String path;

  final List<ParameterElement> parameters;

  WebSocketEndpointData(this.methodName, this.path, this.parameters);
}
