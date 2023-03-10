<div align="center">

[![pub package](https://img.shields.io/pub/v/minerva_controller_generator.svg?label=minerva_controller_generator&color=blue)](https://pub.dev/packages/minerva_controller_generator)

**Языки:**
  
[![English](https://img.shields.io/badge/Language-English-blue?style=?style=flat-square)](README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blue?style=?style=flat-square)](README.ru.md)

</div>

- [О пакете](#о-пакете)
- [Использование](#использование)
- [Что такое контроллер](#что-такое-контроллер)
- [Действия](#действия)
- [Формирование пути конечной точки](#формирование-пути-конечной-точки)
- [Параметры действий](#параметры-действий)
- [Конечные точки вебсокетов](#конечные-точки-вебсокетов)

# О пакете

Пакет предназначен для облегчения конфигурирования сервера при использовании `Minerva` фреймворка.

В `Minerva` фреймворке есть два способа конфигурировать конченые точки:

- используя класс производный от класса `MinervaEndpointsBuilder`, конфигурировать каждую конечную точку по отдельности;
- используя класс производный от класса `MinervaApisBuilder`, конфигурировать сервер при помощи `Api`. `Api` это несколько объедененный конечных точек с некоторым общим контекстом в рамках класса `Api`.

Но все эти способы заставляли писать много лишнего кода. Нужен был более элегантный способ конфигурирования конечных точек, например как контроллеры в ASP.NET и других фреймворках.

Некоторые другие фреймворки реализовывали нечто подобное при помощи библиотеки для рефлексии - dart:mirrors. Однако такой вариант не позволял бы использовать AOT компиляцию.

Данный пакет реализует контроллеры построенные на генерации кода. При помощи него вы можете конфигурировать ваш сервер при помощи контроллеров, действий контроллеров, привязки данных в параметрах действий контроллеров и т.д., а затем пакет генерирует `Api`, которое строит маршруты конечных точек, генерирует код привязки данных параметров действий к данным из запроса. Вы подключаете сгенерированное `Api` в классе производном от класса `MinervaEndpointsBuilder`.

# Использование

Создаем файл `hello_controller.dart` с контроллером `HelloController` и с одним GET действием `get`, которое возвращает `Hello, world!`:

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

Используя данный пакет мы получаем файл `hello_controller.g.dart` с следующим содержанием:

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

Подключаем сгенерированное `Api`:

```dart
class ApisBuilder extends MinervaApisBuilder {
  @override
  List<Api> build() {
    final apis = <Api>[];

    apis.add(HelloApi());

    return apis;
  }
```

# Что такое контроллер

Контроллер это класс производный от класс `ControllerBase`.

Он содержит методы `initialize` и `dispose`, как и `Api`, однако не содержит метода `build`, так как вы конфигурируете конечные точки при помощи действий.

Пример создания класса контроллера:

```dart
class HelloController extends ControllerBase {}
```

# Действия

Действия это методы контроллера помеченные при помощи классов аннотаций действий для этого:

- `Get` - для действий обрабатывающего поступающие `GET` запросы;
- `Post` - для действий обрабатывающих поступающие `POST` запросы;
- `Head` - для действий обрабатывающих поступающие `HEAD` запросы;
- `Options` - для действий обрабатывающих поступающие `OPTIONS` запросы;
- `Patch` - для действий обрабатывающих поступающие `PATCH` запросы;
- `Put` - для действий обрабатывающих поступающие `PUT` запросы;
- `Delete` - для действи обрабатывающих поступающие `DELETE` запросы;
- `Trace` - для действий обрабатывающих поступающие `TRACE` запросы.

Аннотации для действий содержат такие же параметры как и конечные точки в Minerva.

В аннотация вы можете указывать:

- `authOptions` - настройки аутентефикации для конечной точки, подробнее смотрите [здесь](https://github.com/GlebBatykov/minerva#authentication);
- `filter` - фильтр для конечной точки, подробнее смотрите [здесь](https://github.com/GlebBatykov/minerva#request-filter);
- `errorHandler` - обработчик ошибок, происходящих при исполнении обработчика конечной точки.

Пример создания 'Hello, world!' контроллера с одним `GET` действием:

```dart
class HelloController extends ControllerBase {
  @Get()
  String hello() {
    return 'Hello, world!';
  }
}
```

В результате в примере выше мы получим `GET` конечную точку `/hello`. Правила формирования путей конечных точек описаны [тут](#формирование-пути-конечной-точки).

Пример создания контроллера с несколькими действиями:

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

В результате в примере выше мы получим следующие конечные точки:

- `POST` конечную точку `/users/add`;
- `GET` конечную точку `/users`;
- `PATCH` конечную точку `/users/edit`.

Пример создания действия которое будет доступно только пользователям с ролью Admin:

```dart
class UsersController extends ControllerBase {
  @Delete(authOptions: AuthOptions(jwt: JwtAuthOptions(roles: ['Admin'])))
  void delete() {
    /* execute some code */
  }
}
```

В результате в примере выше мы получим DELETE конечную точку `/users`, доступную только пользователям с ролью Admin.

# Формирование пути конечной точки

Пути конечных точек формируются на основании имени контроллера, имени действия, шаблонов пути которые задаются в аннотациях, а так же с учетом некоторых специфичных правил.

Полный путь к конечной точке состоит из пути к контроллеру, а так же пути к действию.

И контроллер и действие имеют шаблоны их пути.

В аннотации для контроллера `@Controller()` вы можете указать параметр path, который является шаблоном пути контроллера. В нем вы можете использовать имя контроллера вписав в него `{controller}`. По умолчанию шаблоном пути контроллера является `/{controller}`. Имя контроллера это имя класса контроллера, без `Controller` в конце имени, имя приводится к нижнему регистру.

В аннотациях к действиям вы можете указать параметр path, который является шаблоном пути действия. В нем вы можете использовать имя контроллера вписав в него `{action}`. По умолчанию шаблоном пути действия является `/{action}`. Имя действия это имя метода действия приведенное к нижнему регистру.

В аннотациях к конечным точкам вебсокетов `@WebSocketEndpoint()` вы можете указать параметр path, который является шаблоном пути конечной точки вебсокет подключений. В нем вы можете использовать имя метода обработчика вебсокет подключений вписав в него `{endpoint}`. По умолчанию шаблоном пути конечной точки вебсокета является `/{endpoint}`. Имя конечной точки вебсокета это имя метода обработчика приведенное к нижнему регистру.

Так же есть некоторые правила формирования пути:

Если имя действия заканчивается на название `HTTP` метода запросы которого он обрабатывает, то имя обрезается до названия HTTP метода.

Пример: было имя `GET` действия - `userGet`, стало `user`.

Если имя действия полностью совпадает с именем `HTTP` метода запросы которого он обрабатывает, а так же шаблон имени действия является стандартным, то при формировании пути конечной точки, учитывается только путь к контроллеру.

Пример: имеем контроллер UsersController, он имеет `GET` действие с именем get. Контроллер и действие имеют стандартные шаблоны пути. Путь к `GET` конечной точке будет равен `/users`.

Если имя обработчика конечных точек вебсокетов заканчивается на слово `Endpoint`, то оно обрезается до него.

Пример: было `webSocketEndpoint`, стало `webSocket`.

Пример указания собственного шаблона пути контроллера и действия:

```dart
@Controller(path: '/api/{controller}')
class TestController extends ControllerBase {
  @Get(path: '/some/test')
  void test() {}
}
```

# Параметры действий

Обработчики конечных точек в `Minerva` всегда получают два параметра, это экземпляр класса `ServerContext`, а так же контекста текущего запроса экземпляр класса `MinervaRequest`.

При конфигурировании конечных точек было не всегда удобно прописывать эти параметры, ведь они не всегда могут нам пригодится. А так же не было удобно извлекать данных из запроса, каждый раз писать один и тот же код для этого.

Действия в контроллерах могут не иметь ни одного параметра, но могут и иметь их.

Вы можете, если вам необходимо, указать в параметрах запроса параметры с типами `ServerContext`, `MinervaRequest` и получить их.

Пример получения `ServerContext` и `MinervaRequest` экземпляров в действиях:

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

Помимо получения экземпляров `ServerContext` и `MinervaRequest` вы можете связывать параметры действия, с данными запроса, а так же вы можете получать данные об аутентефикации. Данные об аутентефикации берутся из `MinervaRequest`, вы можете получать экземпляры `AuthContext`, `JwtAuthContext`, `CookieAuthContext` от туда.

Вы можете связывать параметры с данными запроса при помощи аннотаций параметров:

- `FromQuery` - связь с данными параметров запроса;
- `FromRoute` - связь с данными параметров пути запроса;
- `FromBody` - связь с данными тела запроса, подразумевается что тело запроса содержит данные типа `application/json`;
- `FromForm` - связь с данными тела запроса, подразумевается что тело запроса содержит данные типа `multipart/form-data`.

При связывании данных в качестве имени параметра/поля данных берется имя параметра. Так же вы можете задать другое имя для связывания при помощи параметра name классов аннотаций связывания данных (`FromQuery`, `FormRoute`, `FromBody`, `FormForm`).

Пример получения данных из параметров запроса:

```dart
class UsersController extends ControllerBase {
  @Get()
  dynamic get(@FromQuery() int id) {
    /* execute some code */
  }
}
```

При получении данных из параметра запроса, вы можете указывать типы параметров `String`, `bool`, `int`, `double`, `num`. Типы могут быть nullable.

Пример получения данных из параметров пути запроса:

```dart
class UsersController extends ControllerBase {
  @Get(path: '/:id')
  dynamic get(@FromRoute() int id) {
    /* execute some code */
  }
}
```

При получении данных из параметров пути запроса, вы можете указать типы параметров `num`, `int`, `double`, `bool`, `String`. Типы могут быть nullable.

При получении данных из JSON тела запроса, при помощи аннотации `@FromBody`, вы можете указывать типы параметров `String`, `int`, `double`, `num`. Так же, вы можете указывать в качестве типа произвольный тип вашей модели данных, которая содержит конструктор fromJson. Таким образом вы можете в действии контроллера в параметре сразу получить десериализованные данные в модель. Так же вы можете указывать в качестве параметров коллекции `List` и `Map`, причем они могут обладать любой степенью вложенности.

Пример получения данных из JSON тела запроса:

```dart
class UsersController extends ControllerBase {
  @Post()
  void add(@FromBody() String name, @FromBody() int age) {
    /* execute some code */
  }
}
```

Пример получения данных из JSON тела запроса, десериализация их в модель:

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

При получении данных из тела запроса которое является формой при помощи аннотации `@FromForm` вы можете указывать типы параметров `FormDataString`, `FormDataFile`. Эти типы соответствуют полям формы которые содержат строковые значения и файлы.

Пример получения данных из формы запроса:

```dart
class FilesController extends ControllerBase {
  @Post()
  void add(@FromForm() FormDataString name, @FromForm() FormDataFile file) {
    /* execute some code */
  }
}
```

# Конечные точки вебсокетов

В контроллерах помимо действий для обработки поступающих `HTTP` запросов вы можете так же задавать конечные точки для обработки вебсокет подключений.

Метод который должен служить обработчиком для конечной точки вебсокетов помечается при помощи аннотации `@WebSocketEndpoint`.

Связывание параметров с данными запроса в данном случае не работает. В параметрах метода обработчика вебсокет подключений вы должны указать параметр типа `WebSocket`, чтобы получить экземпляр вебсокета с которым вы можете работать. Так же вы можете в параметрах указать параметр типа `ServerContext`, чтобы получить экземпляр контекста сервера.

Пример создания конечной точки для обработки вебсокет подключений:

```dart
class HelloController extends ControllerBase {
  @WebSocketEndpoint()
  Future<void> hello(WebSocket socket) async {
    socket.add('Hello, world!');

    await socket.close();
  }
}
```
