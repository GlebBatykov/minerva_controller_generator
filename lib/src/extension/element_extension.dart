part of minerva_controller_generator;

extension ElementExtension on Element {
  List<ElementAnnotation> getMethadataOfExectlyType(TypeChecker checker) {
    final list = <ElementAnnotation>[];

    for (final annotation in metadata) {
      if (checker.isExactlyType(annotation.computeConstantValue()!.type!)) {
        list.add(annotation);
      }
    }

    return list;
  }
}
