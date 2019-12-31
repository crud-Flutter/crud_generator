import 'package:analyzer/dart/element/element.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart' as api;

import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

abstract class GenerateClassForAnnotation<T> extends GeneratorForAnnotation<T> {
  ClassBuilder _classBuilder = ClassBuilder();
  Element _element;
  ConstantReader annotation;
  Set<String> imports;

  set element(Element element) => _element = element;

  ConstantReader getAnnotationValue(String field) => annotation.read(field);

  Element get element => _element;
  ClassElement get elementAsClass => _element as ClassElement;

  set name(String name) => _classBuilder.name = name;

  String get name => _classBuilder.name;

  set extend(Reference extend) => _classBuilder.extend = extend;

  void init() {
    _classBuilder = ClassBuilder();
    imports = {};
  }

  void declareField(Reference type, String name,
      {Code assignment, FieldModifier modifier}) {
    var fieldBuilder = FieldBuilder();
    fieldBuilder.name = name;
    fieldBuilder.type = type;
    if (assignment != null) {
      fieldBuilder.assignment = assignment;
    }
    if (modifier != null) {
      fieldBuilder.modifier = modifier;
    }
    _classBuilder.fields.add(fieldBuilder.build());
  }

  void declareConstructorNamed(String name, Code body,
      {List<Parameter> optionalParameters,
      List<Parameter> requiredParameters}) {
    var constructorBuilder = ConstructorBuilder();
    constructorBuilder.name = name;
    constructorBuilder.body = body;
    if (optionalParameters != null && optionalParameters.isNotEmpty) {
      constructorBuilder.optionalParameters.addAll(optionalParameters);
    }
    if (requiredParameters != null && requiredParameters.isNotEmpty) {
      constructorBuilder.requiredParameters.addAll(requiredParameters);
    }
    _classBuilder.constructors.add(constructorBuilder.build());
  }

  void declareConstructor(
      {String name,
      Code body,
      List<Parameter> optionalParameters,
      List<Parameter> requiredParameters,
      bool lambda}) {
    var constructorBuilder = ConstructorBuilder();
    if (name != null) {
      constructorBuilder.name = name;
    }
    if (body != null) {
      constructorBuilder.body = body;
    }
    if (optionalParameters != null && optionalParameters.isNotEmpty) {
      constructorBuilder.optionalParameters.addAll(optionalParameters);
    }
    if (requiredParameters != null && requiredParameters.isNotEmpty) {
      constructorBuilder.requiredParameters.addAll(requiredParameters);
    }
    constructorBuilder.lambda = lambda;
    _classBuilder.constructors.add(constructorBuilder.build());
  }

  void declareMethod(String name,
      {Reference returns,
      List<Parameter> optionalParameters,
      List<Parameter> requiredParameters,
      MethodModifier modifier,
      MethodType type,
      Code body,
      bool lambda}) {
    var methodBuilder = MethodBuilder();
    methodBuilder.name = name;
    if (returns != null) {
      methodBuilder.returns = returns;
    }
    if (optionalParameters != null && optionalParameters.isNotEmpty) {
      methodBuilder.optionalParameters.addAll(optionalParameters);
    }
    if (requiredParameters != null && requiredParameters.isNotEmpty) {
      methodBuilder.requiredParameters.addAll(requiredParameters);
    }
    if (modifier != null) {
      methodBuilder.modifier = modifier;
    }
    if (type != null) {
      methodBuilder.type = type;
    }
    methodBuilder.body = body;
    methodBuilder.lambda = lambda;
    _classBuilder.methods.add(methodBuilder.build());
  }

  String build() {
    final emitter = DartEmitter();
    return imports.fold(
            '', (prev, element) => prev.toString() + "import '$element';") +
        DartFormatter().format('${_classBuilder.build().accept(emitter)}');
  }

  bool isFieldPersist(Element element) =>
      TypeChecker.fromRuntime(api.Field).hasAnnotationOfExact(element) ||
      TypeChecker.fromRuntime(api.Date).hasAnnotationOfExact(element) ||
      TypeChecker.fromRuntime(api.Time).hasAnnotationOfExact(element) ||
      isManyToOneField(element);

  bool isManyToOneField(Element element) =>
      TypeChecker.fromRuntime(api.ManyToOne).hasAnnotationOfExact(element);

  String getDisplayField(Type type, Element element) =>
      TypeChecker.fromRuntime(type)
          .firstAnnotationOfExact(element)
          .getField('displayField')
          .toStringValue();

  void addImportPackage(String package) => imports.add(package);
}

abstract class GenerateEntityClassForAnnotation<T>
    extends GenerateClassForAnnotation<T> {
  String get entityClass => '${element.name}Entity';
  String get entityInstance => '${element.name.toLowerCase()}Entity';
  String get entityClassInstance => '$entityClass $entityInstance';
}

abstract class GenerateFlutterWidgetForAnnotation<T>
    extends GenerateEntityClassForAnnotation<T> {
  void methodBuild(Code body) {
    addImportPackage('package:flutter/material.dart');
    declareMethod('build',
        returns: refer('Widget'),
        requiredParameters: [
          Parameter((b) => b
            ..name = 'context'
            ..type = refer('BuildContext'))
        ],
        body: body);
  }

  Code instanceScaffold(String title,
      {Code actionBar, Code fab, Code body, bool drawer = false}) {
    var scaffoldCode = [
      Code('return Scaffold('),
      Code('appBar: AppBar('),
      Code("title: Text('$title'),")
    ];
    if (actionBar != null) {
      scaffoldCode.add(actionBar);
    }
    scaffoldCode.add(Code('),'));
    if (fab != null) {
      scaffoldCode.add(fab);
    }
    if (body != null) {
      scaffoldCode.add(body);
    }
    if (drawer) {
      scaffoldCode.add(Code('drawer: Drawer(child: drawer(context)),'));
    }
    scaffoldCode.add(Code(');'));
    return Block((b) => b..statements.addAll(scaffoldCode));
  }

  Code instanceFab(Code child, Code onPressed) {
    var fabCode = [
      Code('floatingActionButton: FloatingActionButton('),
      Code('child: $child,'),
      Code('onPressed: $onPressed,'),
      Code('),')
    ];
    return Block((b) => b..statements.addAll(fabCode));
  }
}
