import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'minerva_controller_generator.dart';

Builder apiFromControllerBuilder(BuilderOptions options) =>
    SharedPartBuilder([ApiFromControlllerGenerator()], 'api');
