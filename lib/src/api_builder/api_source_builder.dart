part of minerva_controller_generator;

class ApiSourceBuilder {
  const ApiSourceBuilder();

  String build(ApiData data) {
    return '''
class ${data.shortName}Api extends Api {
  final ControllerBase _controller = ${data.name}();

  @override
  Future<void> initialize(ServerContext context) async {
    await _controller.initialize(context);
  }

  @override
  void build(Endpoints endpoints) {
    ${_buildActions(data.name, data.actions)}
  }

  @override
  Future<void> dispose(ServerContext context) async {
    await _controller.dispose(context);
  }
}
''';
  }

  String? _buildActions(String name, List<ActionData> actions) {
    var result = '';

    for (final action in actions) {
      final data = action.annotationData;

      result +=
          'endpoints.${data.method.name}(\'${action.path}\', ${_buildCallActionHandler(name, action)}, errorHandler: ${_buildErrorHandler(data.errorHandler)}, authOptions: ${_buildAuthOptions(data.authOptions)}, filter: ${_buildFilter(data.filter)}); \n';
    }

    return result;
  }

  String _buildCallActionHandler(String name, ActionData data) {
    return '(context, request) { ${_buildSourceBindings(data.parameters)} return (_controller as $name).${data.methodName}${_buildCallActionParameters(data.parameters)}; }';
  }

  String _buildSourceBindings(List<ParameterElement> parameters) {
    return '';
  }

  String _buildCallActionParameters(List<ParameterElement> parameters) {
    var result = '(';

    for (var i = 0; i < parameters.length; i++) {
      if (contextChecker.isExactlyType(parameters[i].type)) {
        result += 'context';
      } else if (requestChecker.isExactlyType(parameters[i].type)) {
        result += 'request';
      } else {
        throw InvalidGenerationSourceError('');
      }

      if (i < parameters.length - 1) {
        result += ', ';
      }
    }

    result += ')';

    return result;
  }

  String? _buildErrorHandler(ExecutableElement? errorHandler) {
    if (errorHandler == null) {
      return null;
    }

    if (errorHandler is FunctionElement) {
      return errorHandler.displayName;
    }

    if (errorHandler is MethodElement) {
      return '${errorHandler.enclosingElement.displayName}.${errorHandler.displayName}';
    }

    return null;
  }

  String? _buildAuthOptions(DartObject authOptions) {
    if (authOptions.isNull) {
      return null;
    }

    final jwtAuthOptions = authOptions.getField('jwt')!;

    final cookieAuthOptions = authOptions.getField('cookie')!;

    return 'AuthOptions(jwt: ${_buildJwtAuthOptions(jwtAuthOptions)}, cookie: ${_buildCookieAuthOptions(cookieAuthOptions)})';
  }

  String? _buildJwtAuthOptions(DartObject options) {
    if (options.isNull) {
      return null;
    }

    final rolesObjects = options.getField('roles')?.toListValue();

    final permissionLevel = options.getField('permissionLevel')?.toIntValue();

    final roles = rolesObjects?.map((e) => e.toStringValue()!).toList();

    return 'JwtAuthOptions(roles: ${_buildRoles(roles)}, permissionLevel: $permissionLevel)';
  }

  String? _buildRoles(List<String>? roles) {
    if (roles == null) {
      return null;
    }

    return _convertListOfStringToString(roles);
  }

  String? _buildCookieAuthOptions(DartObject options) {
    if (options.isNull) {
      return null;
    }

    return 'CookieAuthOptions()';
  }

  String? _buildFilter(DartObject filter) {
    if (filter.isNull) {
      return null;
    }

    final contentTypeFilter = filter.getField('contentType')!;

    final bodyFilter = filter.getField('body')!;

    final queryParametersFilter = filter.getField('queryParameters')!;

    return 'RequestFilter(contentType: ${_buildContentTypeFilter(contentTypeFilter)}, body: ${_buildBodyFilter(bodyFilter)}, queryParameters: ${_buildQueryParametersFilter(queryParametersFilter)})';
  }

  String? _buildContentTypeFilter(DartObject filter) {
    if (filter.isNull) {
      return null;
    }

    final accepts = filter
        .getField('accepts')!
        .toListValue()!
        .map((e) => e.toStringValue()!)
        .toList();

    return 'ContentTypeFilter(accepts: ${_convertListOfStringToString(accepts)})';
  }

  String? _buildQueryParametersFilter(DartObject filter) {
    if (filter.isNull) {
      return null;
    }

    final parametersObject = filter.getField('parameters')!.toListValue()!;

    return 'QueryParametersFilter(parameters: ${_buildParameters(parametersObject)})';
  }

  String _buildParameters(List<DartObject> parameters) {
    var result = '[';

    for (var i = 0; i < parameters.length; i++) {
      final name = parameters[i].getField('name')!.toStringValue();

      final typeObject = parameters[i].getField('type')!.getField('index')!;

      final typeIndex = typeObject.isNull ? null : typeObject.toIntValue()!;

      final typeName =
          typeIndex != null ? QueryParameterType.values[typeIndex].name : null;

      result +=
          'QueryParameter(name: \'$name\', type: ${typeName != null ? 'QueryParameterType.$typeName' : typeName})';

      if (i < parameters.length - 1) {
        result += ', ';
      }
    }

    result += ']';

    return result;
  }

  String? _buildBodyFilter(DartObject filter) {
    if (filter.isNull) {
      return null;
    }

    final type = filter.type!;

    if (jsonFilterChecker.isExactlyType(type)) {
      return _buildJsonBodyFilter(filter);
    }

    if (formFilterChecker.isExactlyType(type)) {
      return _buildFormBodyFilter(filter);
    }

    return null;
  }

  String? _buildJsonBodyFilter(DartObject filter) {
    final fieldsObjects = filter.getField('fields')!.toListValue()!;

    return 'JsonFilter(fields: ${_buildJsonFields(fieldsObjects)})';
  }

  String _buildJsonFields(List<DartObject> fields) {
    var result = '[';

    for (var i = 0; i < fields.length; i++) {
      final name = fields[i].getField('name')!.toStringValue();

      final type = fields[i].getField('type')!;

      final indexObject = !type.isNull ? type.getField('index')! : null;

      final typeIndex = indexObject == null ? null : indexObject.toIntValue()!;

      final typeName =
          typeIndex != null ? QueryParameterType.values[typeIndex].name : null;

      result +=
          'JsonField(name: \'$name\', type: ${typeName != null ? 'JsonFieldType.$typeName' : typeName})';

      if (i < fields.length - 1) {
        result += ', ';
      }
    }

    result += ']';

    return result;
  }

  String? _buildFormBodyFilter(DartObject filter) {
    final fieldsObjects = filter.getField('fields')!.toListValue()!;

    return 'FormFilter(fields: ${_buildFormFields(fieldsObjects)})';
  }

  String _buildFormFields(List<DartObject> fields) {
    var result = '[';

    for (var i = 0; i < fields.length; i++) {
      final name = fields[i].getField('name')!.toStringValue();

      final type = fields[i].getField('type')!;

      final indexObject = !type.isNull ? type.getField('index')! : null;

      final typeIndex = indexObject == null ? null : indexObject.toIntValue()!;

      final typeName =
          typeIndex != null ? QueryParameterType.values[typeIndex].name : null;

      result +=
          'FormField(name: \'$name\', type: ${typeName != null ? 'FormFieldType.$typeName' : typeName})';

      if (i < fields.length - 1) {
        result += ', ';
      }
    }

    result += ']';

    return result;
  }

  String _convertListOfStringToString(List<String> list) {
    var result = '[';

    for (var i = 0; i < list.length; i++) {
      result += '\'${list[i]}\'';

      if (i < list.length - 1) {
        result += ', ';
      }
    }

    result += ']';

    return result;
  }
}
