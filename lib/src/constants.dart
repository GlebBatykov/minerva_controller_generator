part of minerva_controller_generator;

const controllerChecker = TypeChecker.fromRuntime(ControllerBase);

const controllerAnnotationChecker = TypeChecker.fromRuntime(Controller);

const actionChecker = TypeChecker.fromRuntime(ActionAnnotation);

const Map<TypeChecker, ActionHttpMethod> httpMethodsTypeCheckers = {
  TypeChecker.fromRuntime(Get): ActionHttpMethod.get,
  TypeChecker.fromRuntime(Post): ActionHttpMethod.post,
  TypeChecker.fromRuntime(Head): ActionHttpMethod.head,
  TypeChecker.fromRuntime(Options): ActionHttpMethod.options,
  TypeChecker.fromRuntime(Patch): ActionHttpMethod.patch,
  TypeChecker.fromRuntime(Put): ActionHttpMethod.put,
  TypeChecker.fromRuntime(Trace): ActionHttpMethod.trace
};

const contextChecker = TypeChecker.fromRuntime(ServerContext);

const requestChecker = TypeChecker.fromRuntime(MinervaRequest);

const authOptionsChecher = TypeChecker.fromRuntime(AuthOptions);

const jwtAuthOptionsChecker = TypeChecker.fromRuntime(JwtAuthOptions);

const cookieAuthOptionsChecker = TypeChecker.fromRuntime(CookieAuthOptions);

const jsonFilterChecker = TypeChecker.fromRuntime(JsonFilter);

const formFilterChecker = TypeChecker.fromRuntime(FormFilter);

const bindingSourceAnnotationChecker =
    TypeChecker.fromRuntime(BindingSourceAnnotation);

const fromBodyChecker = TypeChecker.fromRuntime(FromBody);

const fromFormChecker = TypeChecker.fromRuntime(FromForm);

const fromRouteChecker = TypeChecker.fromRuntime(FromRoute);

const fromQueryChecker = TypeChecker.fromRuntime(FromQuery);

const webSocketEndpointChecker = TypeChecker.fromRuntime(WebSocketEndpoint);

const webSocketChecker = TypeChecker.fromRuntime(WebSocket);
