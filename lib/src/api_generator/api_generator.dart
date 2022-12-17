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

    final data = ApiData(name: name, shortName: shortName, actions: actions);

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
          template: annotationData.template,
          actionName: methodName,
          controllerPath: controllerPath,
          controllerShortName: shortName));

      actions.add(ActionData(
          methodName: methodName,
          path: actionPath,
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

    if (element.parameters.length != 2) {
      throw InvalidGenerationSourceError('');
    }

    if (contextChecker.isExactlyType(element.parameters[0].type) &&
        requestChecker.isExactlyType(element.parameters[1].type)) {
      return true;
    } else {
      throw InvalidGenerationSourceError('');
    }
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
    template = template.replaceAll('{controller}', shortName.toLowerCase());

    return template;
  }

  String _getActionPath(ActionPathBuildData data) {
    var actionName = data.actionName.toLowerCase();

    final httpMethodsNames = ActionHttpMethod.values.map((e) => e.name);

    if (httpMethodsNames.contains(actionName)) {
      return data.controllerPath;
    }

    for (final name in httpMethodsNames) {
      if (actionName.endsWith(name)) {
        actionName = actionName.substring(0, actionName.length - name.length);
        break;
      }
    }

    if (data.template == '/{action}' &&
        actionName == data.controllerShortName.toLowerCase()) {
      return data.controllerPath;
    }

    final actionPath = data.template.replaceAll('{action}', actionName);

    return '${data.controllerPath}$actionPath';
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

    final template = actionAnnotation.getField('path')!.toStringValue()!;

    return ActionAnnotationData(
        method: method!,
        template: template,
        errorHandler: errorHandler?.toFunctionValue(),
        authOptions: authOptions,
        filter: filter);
  }
}
