// import 'package:crud_generator/crud_generator.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dart_style/dart_style.dart';

import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

abstract class GenerateClassForAnnotation<T> extends GeneratorForAnnotation<T> {
  final ClassBuilder _classBuilder = ClassBuilder();
  Element _element;

  set element(Element element) {
    _element = element;
    
  }

  Element get element => _element;
  ClassElement get elementAsClass => _element as ClassElement;

  set name(String name) => _classBuilder.name = name;

  String get name => _classBuilder.name;

  set extend(Reference extend) => _classBuilder.extend = extend;

  void declareField(Reference type, String name, {Code assignment}) {
    var fieldBuilder = FieldBuilder();
    fieldBuilder.name = name;
    fieldBuilder.type = type;
    if (assignment != null) {
      fieldBuilder.assignment = assignment;
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

  void declareConstructor({String name, Code body}) {
    var constructorBuilder = ConstructorBuilder();
    if (name != null) {
      constructorBuilder.name = name;
    }
    if (body != null) {
      constructorBuilder.body = body;
    }
    _classBuilder.constructors.add(constructorBuilder.build());
  }

  void declareMethod(String name,
      {Reference returns,
      List<Parameter> optionalParameters,
      List<Parameter> requiredParameters,
      MethodModifier modifier,
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
    methodBuilder.body = body;
    methodBuilder.lambda = lambda;
    _classBuilder.methods.add(methodBuilder.build());
  }

  String build() {
    final emitter = DartEmitter();
    return DartFormatter().format('${_classBuilder.build().accept(emitter)}');
  }
}

abstract class GenerateEntityClassForAnnotation<T>
    extends GenerateClassForAnnotation<T> {
  String get entityClass => '${element.name}Entity';
  String get entityInstance => '${element.name.toLowerCase()}Entity';
  String get entityClassInstance => '$entityClass $entityInstance';

  @override
  String build() {
    return "import 'package:cloud_firestore/cloud_firestore.dart';\n"
            "import '${element.name.toLowerCase()}.entity.dart';" +
        super.build();
  }
}

// // abstract class GenerateFlutterWidgetAbstract
// //     extends GenerateEntityClassAbstract {
// //   GenerateFlutterWidgetAbstract(String name,
// //       {String classSuffix, String parentClass})
// //       : super(name, classSuffix: classSuffix, parentClass: parentClass);
// //   void generateWidget();

// //   @override
// //   void addImports() {
// //     generateClass.writeln('import \'package:flutter/material.dart\';');
// //   }

// //   @override
// //   String build() {
// //     generateWidget();
// //     return super.build();
// //   }
// // }
