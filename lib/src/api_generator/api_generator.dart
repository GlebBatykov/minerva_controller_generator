part of minerva_controller_generator;

class ApiFromControlllerGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final controller = _getController(library);

    if (controller == null) {
      return '';
    }

    final name = controller.displayName;

    final shortName = name.length > 10 && name.endsWith('Controller')
        ? name.substring(0, name.length - 10)
        : name;

    final actions = _getActions(controller, shortName);

    final webSocketEndpoints = _getWebSocketEndpoints(controller, shortName);

    final data = ApiData(
        name: name,
        shortName: shortName,
        actions: actions,
        webSocketEndpoints: webSocketEndpoints);

    return const ApiSourceBuilder().build(data);
  }

  ClassElement? _getController(LibraryReader library) {
    final controllers = library.allElements
        .whereType<ClassElement>()
        .where((element) => controllerChecker.isSuperOf(element));

    if (controllers.isEmpty) {
      return null;
    }

    if (controllers.length > 1) {
      throw InvalidGenerationSourceError('');
    }

    final controller = controllers.first;

    if (controller.isAbstract) {
      throw InvalidGenerationSourceError('');
    }

    return controller;
  }

  List<ActionData> _getActions(ClassElement controller, String shortName) {
    final actionsElements =
        controller.methods.where((element) => _isActionElement(element));

    final actions = <ActionData>[];

    for (final element in actionsElements) {
      final methodName = element.displayName;

      final annotationData = _getActionAnnotationData(element);

      final controllerPath = _getControllerPath(controller, shortName);

      final actionPath = _getActionPath(ActionPathBuildData(
          method: annotationData.method,
          template: annotationData.template,
          actionName: methodName,
          controllerPath: controllerPath,
          controllerShortName: shortName));

      actions.add(ActionData(
          methodName: methodName,
          path: actionPath,
          parameters: element.parameters,
          annotationData: annotationData));
    }

    return actions;
  }

  bool _isActionElement(MethodElement element) {
    final annotations = element.metadata.where(
        (e) => actionChecker.isSuperTypeOf(e.computeConstantValue()!.type!));

    if (annotations.isEmpty) {
      return false;
    }

    if (annotations.length > 1) {
      throw InvalidGenerationSourceError('');
    }

    if (element.isPrivate) {
      throw InvalidGenerationSourceError('');
    }

    return true;
  }

  ActionAnnotationData _getActionAnnotationData(MethodElement element) {
    ActionHttpMethod? method;

    DartObject? actionAnnotation;

    for (final annotation in element.metadata) {
      for (final checker in httpMethodsTypeCheckers.keys) {
        final object = annotation.computeConstantValue()!;

        if (checker.isExactlyType(object.type!)) {
          method = httpMethodsTypeCheckers[checker]!;
          actionAnnotation = object;

          break;
        }
      }

      if (method != null) {
        break;
      }
    }

    final errorHandler = actionAnnotation!.getField('errorHandler');

    final authOptions = actionAnnotation.getField('authOptions')!;

    final filter = actionAnnotation.getField('filter')!;

    var template = actionAnnotation.getField('path')!.toStringValue()!;

    template = _handleTemplate(template);

    return ActionAnnotationData(
        method: method!,
        template: template,
        errorHandler: errorHandler?.toFunctionValue(),
        authOptions: authOptions,
        filter: filter);
  }

  String _getActionPath(ActionPathBuildData data) {
    const defaultTemplate = '/{action}';

    var actionName = data.actionName.toLowerCase();

    if (ActionHttpMethod.values.map((e) => e.name).contains(actionName) &&
        (data.template == defaultTemplate || data.template == '/$actionName')) {
      return data.controllerPath;
    }

    if (actionName.endsWith(data.method.name)) {
      actionName =
          actionName.substring(0, actionName.length - data.method.name.length);
    }

    if (data.template == defaultTemplate &&
        actionName == data.controllerShortName.toLowerCase()) {
      return data.controllerPath;
    }

    final actionPath = data.template.replaceAll('{action}', actionName);

    return '${data.controllerPath}$actionPath';
  }

  List<WebSocketEndpointData> _getWebSocketEndpoints(
      ClassElement controller, String shortName) {
    final endpointsElements = controller.methods
        .where((element) => _isWebSocketEndpointElement(element));

    final endpointsData = <WebSocketEndpointData>[];

    for (final element in endpointsElements) {
      final methodName = element.displayName;

      final controllerPath = _getControllerPath(controller, shortName);

      final template = _getWebSocketEndpointTemplate(element);

      final webSocketEndpointPath = _getWebSocketEndpointPath(
          WebSocketEndpointPathBuildData(
              template: template,
              webSocketEndpointName: methodName,
              controllerPath: controllerPath,
              controllerShortName: shortName));

      endpointsData.add(WebSocketEndpointData(
          methodName, webSocketEndpointPath, element.parameters));
    }

    return endpointsData;
  }

  bool _isWebSocketEndpointElement(MethodElement element) {
    final annotations =
        element.getMethadataOfExectlyType(webSocketEndpointChecker);

    if (annotations.isEmpty) {
      return false;
    }

    if (annotations.length > 1) {
      throw InvalidGenerationSourceError('');
    }

    if (element.isPrivate) {
      throw InvalidGenerationSourceError('');
    }

    if (element.parameters
        .where((element) => webSocketChecker.isExactlyType(element.type))
        .isEmpty) {
      throw InvalidGenerationSourceError('');
    }

    return true;
  }

  String _getWebSocketEndpointTemplate(MethodElement element) {
    final annotation =
        webSocketEndpointChecker.firstAnnotationOfExact(element)!;

    var template = annotation.getField('path')!.toStringValue()!;

    template = _handleTemplate(template);

    return template;
  }

  String _getWebSocketEndpointPath(WebSocketEndpointPathBuildData data) {
    const defaultTemplate = '/{endpoint}';

    var endpointName = data.webSocketEndpointName.toLowerCase();

    if (endpointName.endsWith('endpoint')) {
      endpointName = endpointName.substring(0, endpointName.length - 8);
    }

    if (data.template == defaultTemplate &&
        endpointName == data.controllerShortName.toLowerCase()) {
      return data.controllerPath;
    }

    final endpointPath = data.template.replaceAll('{endpoint}', endpointName);

    return '${data.controllerPath}$endpointPath';
  }

  String _getControllerPath(ClassElement controller, String shortName) {
    final annotations =
        controller.getMethadataOfExectlyType(controllerAnnotationChecker);

    if (annotations.length > 2) {
      throw InvalidGenerationSourceError('');
    }

    if (annotations.isNotEmpty) {
      final annotation = annotations.first.computeConstantValue()!;

      return _getControllerPathFromTemplate(shortName,
          template: annotation.getField('path')!.toStringValue()!);
    } else {
      return _getControllerPathFromTemplate(shortName);
    }
  }

  String _getControllerPathFromTemplate(String shortName,
      {String template = '/{controller}'}) {
    template = _handleTemplate(template);

    template = template.replaceAll('{controller}', shortName.toLowerCase());

    return template;
  }

  String _handleTemplate(String template) {
    if (!template.startsWith('/')) {
      template = '/$template';
    }

    while (template.endsWith('/')) {
      template = template.substring(0, template.length - 1);
    }

    return template;
  }
}
