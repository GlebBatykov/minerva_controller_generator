part of minerva_controller_generator;

class WebSocketEndpointsSourceBuilder {
  const WebSocketEndpointsSourceBuilder();

  String build(String name, List<WebSocketEndpointData> webSocketEndpoints) {
    final results = <String>[];

    for (final endpoint in webSocketEndpoints) {
      results.add(
          'endpoints.ws(\'${endpoint.path}\', (context, socket) => (_controller as $name).${endpoint.methodName}${_getCallParameters(endpoint.parameters)});');
    }

    return results.join('\n');
  }

  String _getCallParameters(List<ParameterElement> elements) {
    final parameters = <String>[];

    for (final element in elements) {
      if (contextChecker.isExactlyType(element.type)) {
        parameters.add('context');
      } else if (webSocketChecker.isExactlyType(element.type)) {
        parameters.add('socket');
      } else {
        throw InvalidGenerationSourceError('');
      }
    }

    return _buildCallParameters(parameters);
  }

  String _buildCallParameters(List<String> parameters) {
    var result = '(';

    for (var i = 0; i < parameters.length; i++) {
      result += parameters[i];

      if (i < parameters.length - 1) {
        result += ', ';
      }
    }

    result += ')';

    return result;
  }
}
