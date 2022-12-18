part of minerva_controller_generator;

class CallActionData {
  final String sourceBindings;

  final String parameters;

  CallActionData(this.sourceBindings, this.parameters);
}

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
    final callActionData = _getCallActionData(data.parameters);

    return '(context, request) async { ${callActionData.sourceBindings} return (_controller as $name).${data.methodName}${callActionData.parameters}; }';
  }

  CallActionData _getCallActionData(List<ParameterElement> elements) {
    final parameters = <String>[];

    final bindingSources = <String>[];

    for (var i = 0; i < elements.length; i++) {
      if (contextChecker.isExactlyType(elements[i].type)) {
        parameters.add('context');
      } else if (requestChecker.isExactlyType(elements[i].type)) {
        parameters.add('request');
      } else {
        if (fromQueryChecker.hasAnnotationOfExact(elements[i])) {
          bindingSources.add(_buildFromQuerySource(i, elements[i]));

          parameters.add('parameter$i');
        } else if (fromRouteChecker.hasAnnotationOfExact(elements[i])) {
          bindingSources.add(_buildFromRouteSource(i, elements[i]));

          parameters.add('parameter$i');
        } else if (fromBodyChecker.hasAnnotationOfExact(elements[i])) {
          bindingSources.add(_buildFromBodySource(i, elements[i]));

          parameters.add('parameter$i');
        } else if (fromFormChecker.hasAnnotationOfExact(elements[i])) {
          bindingSources.add(_buildFromFormSource(i, elements[i]));

          parameters.add('parameter$i');
        } else {
          throw InvalidGenerationSourceError('');
        }
      }
    }

    var parametersString = '(';

    for (var i = 0; i < parameters.length; i++) {
      parametersString += parameters[i];

      if (i < parameters.length - 1) {
        parametersString += ', ';
      }
    }

    parametersString += ')';

    return CallActionData(bindingSources.join('\n'), parametersString);
  }

  String _buildFromQuerySource(int index, ParameterElement element) {
    return 'final parameter$index = ${_buildStringToTypeConverter('request.uri.queryParameters[\'${element.name}\']', element.type)};';
  }

  String _buildStringToTypeConverter(String value, DartType type) {
    if (type.isDartCoreString) {
      if (type.isNotNullable) {
        return '$value!';
      } else {
        return value;
      }
    } else if (type.isDartCoreBool) {
      if (type.isNullable) {
        return '$value != null ? $value! == \'true\' : null';
      } else {
        return '$value! == \'true\'';
      }
    } else if (type.isDartCoreInt) {
      if (type.isNullable) {
        return '$value != null ? int.parse($value!) : null';
      } else {
        return 'int.parse($value!)';
      }
    } else if (type.isDartCoreDouble) {
      if (type.isNullable) {
        return '$value != null ? double.parse($value!) : null';
      } else {
        return 'double.parse($value!)';
      }
    } else if (type.isDartCoreNum) {
      if (type.isNullable) {
        return '$value != null ? num.parse($value!) : null';
      } else {
        return 'num.parse($value!)';
      }
    } else {
      if (type.isNullable) {
        return '$value != null ? ${type.getDisplayString(withNullability: false)}.fromJson(jsonDecode($value!)) : null';
      } else {
        return '${type.getDisplayString(withNullability: false)}.fromJson(jsonDecode($value!))';
      }
    }
  }

  String _buildFromRouteSource(int index, ParameterElement element) {
    return 'final parameter$index = ${_buildNumToTypeConverter('request.pathParameters[\'${element.name}\']', element.type)};';
  }

  String _buildNumToTypeConverter(String value, DartType type) {
    if (type.isDartCoreNum) {
      if (type.isNullable) {
        return '$value != null ? $value : null';
      } else {
        return '$value!';
      }
    } else if (type.isDartCoreInt) {
      if (type.isNullable) {
        return '$value != null ? $value!.toInt() : null';
      } else {
        return '$value!.toInt()';
      }
    } else if (type.isDartCoreDouble) {
      if (type.isNullable) {
        return '$value != null ? $value!.toDouble() : null';
      } else {
        return '$value!.toDouble()';
      }
    } else if (type.isDartCoreBool) {
      if (type.isNullable) {
        return '$value != null ? $value > 0 : null';
      } else {
        return '$value > 0';
      }
    } else if (type.isDartCoreString) {
      if (type.isNullable) {
        return '$value != null ? $value!.toString() : null';
      } else {
        return '$value!.toString()';
      }
    } else {
      throw InvalidGenerationSourceError('');
    }
  }

  String _buildFromBodySource(int index, ParameterElement element) {
    return 'final parameter$index = ${_buildJsonValueToTypeConverter('(await request.body.asJson())[\'${element.name}\']', element.type)};';
  }

  String _buildJsonValueToTypeConverter(String value, DartType type) {
    if (type.isDartCoreString) {
      final converter = '$value as String';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreInt) {
      final converter = '$value as int';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreDouble) {
      final converter = '$value as double';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreNum) {
      final converter = '$value as num';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreList) {
      return _buildJsonListToTypeConverter(value, type);
    } else if (type.isDartCoreMap) {
      return _buildJsonMapToTypeConverter(value, type);
    } else {
      final converter =
          '${type.getDisplayString(withNullability: false)}.fromJson(jsonDecode($value!))';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    }
  }

  String _buildJsonMapToTypeConverter(String value, DartType type) {
    final firstGenericType = (type as ParameterizedType).typeArguments[0];

    final secondGenericType = type.typeArguments[1];

    value = '($value as Map)';

    final converter =
        '$value.map<${firstGenericType.getDisplayString(withNullability: true)}, ${secondGenericType.getDisplayString(withNullability: true)}>((key, value) => MapEntry(${_buildJsonValueToTypeConverter('key', firstGenericType)}, ${_buildJsonValueToTypeConverter('value', secondGenericType)}))';

    if (type.isNullable) {
      return '$value != null ? $converter : null';
    } else {
      return converter;
    }
  }

  String _buildJsonListToTypeConverter(String value, DartType type) {
    final genericType = (type as ParameterizedType).typeArguments.first;

    value = '($value as List)';

    final converter =
        '$value.map((e) => ${_buildJsonValueToTypeConverter('e', genericType)}).cast<${genericType.getDisplayString(withNullability: true)}>().toList()';

    if (type.isNullable) {
      return '$value != null ? $converter : null';
    } else {
      return converter;
    }
  }

  String _buildFromFormSource(int index, ParameterElement element) {
    return '';
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
