<div align="center">

[![pub package](https://img.shields.io/pub/v/minerva_controller_generator.svg?label=minerva_controller_generator&color=blue)](https://pub.dev/packages/minerva_controller_generator)

**Languages:**
  
[![English](https://img.shields.io/badge/Language-English-blue?style=?style=flat-square)](README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blue?style=?style=flat-square)](README.ru.md)

</div>

- [About package](#about-package)
- [Using](#using)
- [What is controller](#what-is-controller)
- [Actions](#actions)
- [Forming the endpoint path](#forming-the-endpoint-path)
- [Action parameters](#action-parameters)
- [Websocket endpoints](#websocket-endpoints)

# About package

The package is designed to facilitate server configuration when using the `Minerva` framework.

There are two ways to configure endpoints in the `Minerva` framework:

- using class derived from the `MinervaEndpointsBuilder` class, configure each endpoint individually;
- using class derived from the `MinervaApisBuilder` class, configure the server using the `Api`. An `Api` is a somewhat unified endpoint with some common context within the `Api` class.

But all these methods forced me to write a lot of extra code. A more elegant way of configuring endpoints was needed, for example, as controllers in ASP.NET and other frameworks.

Some other frameworks have implemented something similar using the library for reflection - dart:mirrors. However, such an option would not allow using AOT compilation.

This package implements controllers built on code generation. With it, you can configure your server using controllers, controller actions, data binding in controller action parameters, etc., and then the package generates an `Api` that builds endpoint routes, generates a code binding these action parameters to data from the request. You connect the generated `Api` in a class derived from the `MinervaEndpointsBuilder` class.

# Using

Creating the file `hello_controller.dart` with the controller `HelloController` and with one GET action `get`, which returns `Hello, world!`:

```dart
import 'package:minerva/minerva.dart';
import 'package:minerva_controller_annotation/minerva_controller_annotation.dart';

part 'hello_controller.g.dart';

class HelloController extends ControllerBase {
  @Get()
  String get() {
    return 'Hello, world!';
  }
}
```

Using this package we get the file `hello_controller.g.dart` with the following contents:

```dart
part of 'hello_controller.dart';

class HelloApi extends Api {
  final ControllerBase _controller = HelloController();

  @override
  Future<void> initialize(ServerContext context) async {
    await _controller.initialize(context);
  }

  @override
  void build(Endpoints endpoints) {
    endpoints.get('/hello', (context, request) async {
      return (_controller as HelloController).get();
    }, errorHandler: null, authOptions: null, filter: null);
  }

  @override
  Future<void> dispose(ServerContext context) async {
    await _controller.dispose(context);
  }
}
```

Connecting the generated `Api`:

```dart
class ApisBuilder extends MinervaApisBuilder {
  @override
  List<Api> build() {
    final apis = <Api>[];

    apis.add(HelloApi());

    return apis;
  }
```

# What is controller

The controller is class derived from the `ControllerBase` class.

It contains the `initialize` and `dispose` methods, as well as the `Api`, but it does not contain the `build` method, since you configure endpoints using actions.

Example of creating controller class:

```dart
class HelloController extends ControllerBase {}
```

# Actions

Actions are controller methods marked with action annotation classes for this:

- `Get` - for actions processing incoming `GET` requests;
- `Post` - for actions processing incoming `POST` requests;
- `Head` - for actions processing incoming `HEAD` requests;
- `Options` - for actions processing incoming `OPTIONS` requests;
- `Patch` - for actions processing incoming `PATCH` requests;
- `Put` - for actions processing incoming `PUT` requests;
- `Delete` - for actions processing incoming `DELETE` requests;
- `Trace` - for actions processing incoming `TRACE` requests.

Annotations for actions contain the same parameters as endpoints in Minerva.

In the abstract, you can specify:

- `authOptions` - authentication settings for the endpoint, for more information, see [here](https://github.com/GlebBatykov/minerva#authentication);
- `filter` - filter for the endpoint, for more information, see [here](https://github.com/GlebBatykov/minerva#request-filter);
- `ErrorHandler` - handler for errors that occur during the execution of the endpoint handler.

Example of creating 'Hello, world!' controller with single `GET` action:

```dart
class HelloController extends ControllerBase {
  @Get()
  String hello() {
    return 'Hello, world!';
  }
}
```

As result, in the example above, we will get the `GET` endpoint `/hello`. The rules for forming endpoint paths are described [here](#forming-the-endpoint-path).

Example of creating controller with multiple actions:

```dart
class UsersController extends ControllerBase {
  @Post()
  void add() {
    /* execute some code */
  }

  @Get()
  String get() {
    return 'Some user';
  }

  @Patch()
  void edit() {
    /* execute some code */
  }
}
```

As result, in the example above, we will get the following endpoints:

- `POST` endpoint `/users/add`;
- `GET` the endpoint `/users`;
- `PATCH` the endpoint `/users/edit`.

Example of creating an action that will be available only to users with the Admin role:

```dart
class UsersController extends ControllerBase {
  @Delete(authOptions: AuthOptions(jwt: JwtAuthOptions(roles: ['Admin'])))
  void delete() {
    /* execute some code */
  }
}
```

As result, in the example above, we will get the `DELETE` endpoint `/users`, accessible only to users with the Admin role.

# Forming the endpoint path

Endpoint paths are formed based on the controller name, action name, path templates that are specified in annotations, as well as taking into account some specific rules.

The full path to the endpoint consists of the path to the controller, as well as the path to the action.

Both the controller and the action have templates of their path.

In the annotation for the controller `@Controller()`, you can specify the path parameter, which is a template for the controller path. In it, you can use the controller name by typing `{controller}` into it. By default, the controller path template is `/{controller}`. Controller name is the name of the controller class, without `Controller` at the end of the name, the name is reduced to lowercase.

In the annotations to actions, you can specify the path parameter, which is the template of the action path. In it, you can use the controller name by typing `{action}` into it. By default, the action path template is `/{action}`. The action name is the name of the action method reduced to lowercase.

In the annotations to the endpoints of the websockets `@WebSocketEndpoint()`, you can specify the path parameter, which is a template for the path of the endpoint of the websocket connections. In it, you can use the method name of the websocket connection handler by typing `{endpoint}` into it. By default, the path template of the websocket endpoint is `/{endpoint}`. The name of the endpoint of the websocket is the name of the handler method reduced to lowercase.

There are also some rules for forming path:

If the action name ends with the name of the HTTP method whose requests it processes, then the name is truncated to the name of the HTTP method.

Example: the name of the `GET` action was `userGet`, it became `user`.

If the name of the action completely coincides with the name of the HTTP method whose requests it processes, as well as the template of the action name is default, then when forming the endpoint path, only the path to the controller is taken into account.

Example: we have a UsersController controller, it has a `GET` action named get. The controller and the action have default path templates. The path to the `GET` endpoint will be `/users`.

If the name of the websocket endpoint handler ends with the word `Endpoint`, then it is truncated to it.

Example: it was `webSocketEndpoint`, it became `WebSocket`.

Example of specifying your own controller path and action template:

```dart
@Controller(path: '/api/{controller}')
class TestController extends ControllerBase {
  @Get(path: '/some/test')
  void test() {}
}
```

# Action parameters

Endpoint handlers in Minerva always receive two parameters, this is an instance of the `ServerContext` class, as well as an instance of the `MinervaRequest` class for the context of the current request.

When configuring endpoints, it was not always convenient to prescribe these parameters, because they may not always be useful to us. And it was also not convenient to extract data from the query, writing the same code for this every time.

Actions in controllers may not have any parameters, but they may have them.

You can, if necessary, specify in the request parameters parameters with the types `ServerContext`, `MinervaRequest` and get them.

Example of getting `ServerContext` and `MinervaRequest` instances in actions:

```dart
class TestController extends ControllerBase {
  @Get()
  void first() {}

  @Get()
  void second(ServerContext context) {}

  @Get()
  void third(ServerContext context, MinervaRequest request) {}
}
```

In addition to receiving instances of `ServerContext` and `MinervaRequest`, you can associate action parameters with request data, and you can also receive authentication data. Authentication data is taken from `MinervaRequest`, you can get instances of `AuthContext`, `JwtAuthContext`, `CookieAuthContext` from there.

You can associate parameters with query data using parameter annotations:

- `FromQuery` - connection with the data of the query parameters;
- `FromRoute` - connection with the data of the request path parameters;
- `FromBody` - connection with the data of the request body, it is assumed that the request body contains data of the type `application/json`;
- `FromForm` - connection with the data of the request body, it is assumed that the request body contains data of the type `multipart/form-data`.

When linking data, the parameter name is taken as the parameter name/data field. You can also set another name for binding using the name parameter of the data binding annotation classes (`FromQuery`, `FormRoute`, `FromBody`, `FormForm`).

Example of getting data from query parameters:

```dart
class UsersController extends ControllerBase {
  @Get()
  dynamic get(@FromQuery() int id) {
    /* execute some code */
  }
}
```

When getting data from a query parameter, you can specify the parameter types `String`, `bool`, `int`, `double`, `num`. Types can be nullable.

Example of getting data from request path parameters:

```dart
class UsersController extends ControllerBase {
  @Get(path: '/:id')
  dynamic get(@FromRoute() int id) {
    /* execute some code */
  }
}
```

When getting data from the request path parameters, you can specify the parameter types `num`, `int`, `double`, `bool`, `String`. Types can be nullable.

When receiving data from the JSON request body, using the annotation `@FromBody`, you can specify the types of parameters `String`, `int`, `double`, `num`. Also, you can specify as a type an arbitrary type of your data model, which contains the `fromJson` constructor. Thus, you can immediately get deserialized data into the model in the controller action in the parameter. You can also specify `List` and `Map` as parameters, and they can have any degree of nesting.

Example of getting data from the JSON request body:

```dart
class UsersController extends ControllerBase {
  @Post()
  void add(@FromBody() String name, @FromBody() int age) {
    /* execute some code */
  }
}
```

Example of getting data from JSON request body, deserializing it into model:

```dart
class User {
  final String name;

  final int age;

  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        age = json['age'];
}

class UsersController extends ControllerBase {
  @Post(path: '/add/one')
  void add(@FromBody() User user) {
    /* execute some code */
  }

  @Post(path: '/add/many')
  void addMany(@FromBody() List<User> users) {
    /* execute some code */
  }
}
```

When receiving data from the request body, which is form, using the `@FromForm` annotation, you can specify the types of parameters `FormDataString`, `FormDataFile`. These types correspond to form fields that contain string values and files.

Example of getting data from request form:

```dart
class FilesController extends ControllerBase {
  @Post()
  void add(@FromForm() FormDataString name, @FromForm() FormDataFile file) {
    /* execute some code */
  }
}
```

# Websocket endpoints

In controllers, in addition to actions for processing incoming `HTTP` requests, you can also set endpoints for processing websocket connections.

The method that should serve as handler for the endpoint of websockets is marked with the annotation `@WebSocketEndpoint`.

Binding parameters to query data does not work in this case. In the parameters of the method of the websocket connection handler, you must specify parameter of the type `WebSocket` to get an instance of the websocket with which you can work. You can also specify parameter of the type `ServerContext` in the parameters to get an instance of the server context.

Example of creating an endpoint for processing websocket connections:

```dart
class HelloController extends ControllerBase {
  @WebSocketEndpoint()
  Future<void> hello(WebSocket socket) async {
    socket.add('Hello, world!');

    await socket.close();
  }
}
```
