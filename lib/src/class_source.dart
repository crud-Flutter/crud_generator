import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_persistence_api/flutter_persistence_api.dart' as api;

import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/constants/reader.dart';

abstract class GenerateClassForAnnotation<T> extends GeneratorForAnnotation<T> {
  Set<String> imports;
  Element element;
  ClassElement get elementAsClass => element as ClassElement;
  ClassBuilder _classBuilder = ClassBuilder();
  set extend(Reference extend) => _classBuilder.extend = extend;
  String get entityClass => '${element.name}${manyToManyPosFix}Entity';
  String get entityInstance =>
      '${element.name.toLowerCase()}${manyToManyPosFix}Entity';
  String get entityClassInstance => '$entityClass $entityInstance';

  ConstantReader annotation;

  bool generateImport;
  bool manyToMany;
  String manyToManyGenerate;
  String get manyToManyPosFix => manyToMany ? 'ManyToMany' : '';

  ConstantReader getAnnotationValue(String field) {
    try {
      var result = annotation?.read(field);
      if (result == null || result.isNull) return null;
      return result;
    } on FormatException {
      return null;
    }
  }

  void init(Element element, ConstantReader annotation) {
    this.element = element;
    this.annotation = annotation;
    imports = {};
    generateImport ??= true;
    manyToMany ??= false;
    _classBuilder = ClassBuilder()..name = generateName();
    manyToManyGenerate = '';
  }

  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    init(element, annotation);
    optionalClassInfo();
    generateConstructors();
    generateFields();
    generateMethods();
    generateManyToMany();
    return build();
  }

  String generateName();

  void optionalClassInfo();

  void generateConstructors();

  void generateFields();

  void generateMethods();

  GenerateClassForAnnotation instance();

  void generateManyToMany() {
    if (!manyToMany) {
      elementAsClass.fields.forEach((field) {
        if (isManyToManyField(field)) {
          var instanceGenerate = instance();
          if (instanceGenerate != null) {
            manyToManyGenerate += instanceGenerate.generateForAnnotatedElement(
                getGenericTypes(field.type).first.element, null, null);
            imports.addAll(instanceGenerate.imports);
          }
        }
      });
    }
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

  ClassBuilder get classBuilder => _classBuilder;

  String build() {
    final emitter = DartEmitter();
    return (generateImport
            ? imports.fold('', (prev, element) => prev.toString() + element)
            : '') +
        DartFormatter().format('${_classBuilder.build().accept(emitter)}') +
        manyToManyGenerate;
  }

  bool isFieldPersist(Element element) =>
      hasAnnotation(api.Field, element) ||
      hasAnnotation(api.Date, element) ||
      hasAnnotation(api.Time, element) ||
      isManyToOneField(element) ||
      isOneToManyField(element);

  bool isManyToOneField(Element element) =>
      hasAnnotation(api.ManyToOne, element);
  bool isOneToManyField(Element element) =>
      hasAnnotation(api.OneToMany, element);
  bool isManyToManyField(Element element) =>
      hasAnnotation(api.ManyToMany, element);

  bool hasAnnotation(Type type, Element element) =>
      TypeChecker.fromRuntime(type).hasAnnotationOfExact(element);

  String getDisplayField(Type type, Element element) =>
      TypeChecker.fromRuntime(type)
          .firstAnnotationOfExact(element)
          .getField('displayField')
          .toStringValue();

  void addImportPackage(String package, {String rename}) => imports
      .add("import '$package'" + (rename == null ? '' : ' as $rename') + ';');

  Iterable<DartType> getGenericTypes(DartType type) {
    return type is ParameterizedType ? type.typeArguments : const [];
  }
}

abstract class GenerateEntityClassForAnnotation<T>
    extends GenerateClassForAnnotation<T> {
  void methodDispose() {
    declareMethod('dispose', body: Code('_bloc.dispose()'), lambda: true);
  }
}

abstract class GenerateFlutterWidgetForAnnotation<T>
    extends GenerateEntityClassForAnnotation<T> {
  void methodBuild(Code body) {
    addImportPackage('package:flutter/material.dart', rename: 'flutter');
    declareMethod('build',
        returns: refer('flutter.Widget'),
        requiredParameters: [
          Parameter((b) => b
            ..name = 'context'
            ..type = refer('flutter.BuildContext'))
        ],
        body: body);
  }

  String instanceScaffold(String title,
      {Code actionBar, Code fab, Code body, bool drawer = false}) {
    var scaffoldCode = StringBuffer(
      '''return flutter.Scaffold(
      appBar: flutter.AppBar(
      title: flutter.Text('$title'),''');
    if (actionBar != null) {
      scaffoldCode.writeln(actionBar);
    }
    scaffoldCode.writeln(Code('),'));
    if (fab != null) {
      scaffoldCode.writeln(fab);
    }
    if (body != null) {
      scaffoldCode.writeln(body);
    }
    if (drawer) {
      scaffoldCode.writeln('drawer: flutter.Drawer(child: drawer(context)),');
    }
    scaffoldCode.writeln(');');
    return scaffoldCode.toString();
  }

  Code instanceFab(Code child, Code onPressed) {
    return Code('''floatingActionButton: flutter.FloatingActionButton(
      child: $child,
      onPressed: $onPressed,
      ),''');    
  }
}
