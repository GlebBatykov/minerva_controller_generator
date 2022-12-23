part of minerva_controller_generator;

class ActionsSourceBuilder {
  const ActionsSourceBuilder();

  String build(String name, List<ActionData> actions) {
    final results = <String>[];

    for (final action in actions) {
      final data = action.annotationData;

      results.add(
          'endpoints.${data.method.name}(\'${action.path}\', ${_buildCallActionHandler(name, action)}, errorHandler: ${_buildErrorHandler(data.errorHandler)}, authOptions: ${_buildAuthOptions(data.authOptions)}, filter: ${_buildFilter(data.filter)});');
    }

    return results.join('\n');
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

    final parametersString = _buildParametersString(parameters);

    return CallActionData(bindingSources.join('\n'), parametersString);
  }

  String _buildParametersString(List<String> parameters) {
    var parametersString = '(';

    for (var i = 0; i < parameters.length; i++) {
      parametersString += parameters[i];

      if (i < parameters.length - 1) {
        parametersString += ', ';
      }
    }

    parametersString += ')';

    return parametersString;
  }

  String _buildFromQuerySource(int index, ParameterElement element) {
    final name = _getBindingSourceName(element, fromQueryChecker);

    return 'final parameter$index = ${_buildStringToTypeConverter('request.uri.queryParameters[\'$name\']', element.type)};';
  }

  String _buildStringToTypeConverter(String value, DartType type) {
    if (type.isDartCoreString) {
      if (type.isNotNullable) {
        return '$value!';
      } else {
        return value;
      }
    } else if (type.isDartCoreBool) {
      final converter = '$value! == \'true\'';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreInt) {
      final converter = 'int.parse($value!)';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreDouble) {
      final converter = 'double.parse($value!)';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreNum) {
      final converter = 'num.parse($value!)';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
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

  String _buildFromRouteSource(int index, ParameterElement element) {
    final name = _getBindingSourceName(element, fromRouteChecker);

    return 'final parameter$index = ${_buildNumToTypeConverter('request.pathParameters[\'$name\']', element.type)};';
  }

  String _buildNumToTypeConverter(String value, DartType type) {
    if (type.isDartCoreNum) {
      if (type.isNullable) {
        return '$value != null ? $value : null';
      } else {
        return '$value!';
      }
    } else if (type.isDartCoreInt) {
      final converter = '$value!.toInt()';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreDouble) {
      final converter = '$value!.toDouble()';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreBool) {
      final converter = '$value > 0';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (type.isDartCoreString) {
      final converter = '$value!.toString()';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else {
      throw InvalidGenerationSourceError('');
    }
  }

  String _buildFromBodySource(int index, ParameterElement element) {
    final name = _getBindingSourceName(element, fromBodyChecker);

    return 'final parameter$index = ${_buildJsonValueToTypeConverter('(await request.body.asJson())[\'$name\']', element.type)};';
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

    final converter =
        '.map<${firstGenericType.getDisplayString(withNullability: true)}, ${secondGenericType.getDisplayString(withNullability: true)}>((key, value) => MapEntry(${_buildJsonValueToTypeConverter('key', firstGenericType)}, ${_buildJsonValueToTypeConverter('value', secondGenericType)}))';

    if (type.isNullable) {
      return '($value as Map?) != null ? ($value as Map)$converter : null';
    } else {
      return '($value as Map)$converter';
    }
  }

  String _buildJsonListToTypeConverter(String value, DartType type) {
    final genericType = (type as ParameterizedType).typeArguments.first;

    final converter =
        '.map((e) => ${_buildJsonValueToTypeConverter('e', genericType)}).cast<${genericType.getDisplayString(withNullability: true)}>().toList()';

    if (type.isNullable) {
      return '($value as List?) != null ? ($value as List)$converter : null';
    } else {
      return '($value as List)$converter';
    }
  }

  String _buildFromFormSource(int index, ParameterElement element) {
    final name = _getBindingSourceName(element, fromFormChecker);

    return 'final parameter$index = ${_buildFormValueToTypeConverter('(await request.body.asForm())[\'$name\']', element.type)};';
  }

  String _buildFormValueToTypeConverter(String value, DartType type) {
    final name = type.getDisplayString(withNullability: false);

    if (name == 'FormDataFile') {
      final converter = '$value! as FormDataFile';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else if (name == 'FormDataString') {
      final converter = '$value! as FormDataString';

      if (type.isNullable) {
        return '$value != null ? $converter : null';
      } else {
        return converter;
      }
    } else {
      throw InvalidGenerationSourceError('');
    }
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

  String _getBindingSourceName(ParameterElement element, TypeChecker checker) {
    final annotations = element.getMethadataOfExectlyType(checker);

    final name = annotations.first
        .computeConstantValue()!
        .getField('name')!
        .toStringValue();

    return name ?? element.name;
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
