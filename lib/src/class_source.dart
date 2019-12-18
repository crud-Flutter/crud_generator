abstract class GenerateClass {
  String name;
  String classPrefix;
  String classSuffix;
  String parentClass;
  String fieldPrefix;
  Map<String, String> fields = {};
  StringBuffer generateClass = StringBuffer();
  GenerateClass(this.classPrefix, {this.classSuffix, this.parentClass}) {
    name = classPrefix;
    if (classSuffix != null) {
      name += classSuffix;
    }
    addImports();
    _setClass();
  }

  GenerateClass addField(String type, String name,
      {bool persistField = false}) {
    if (persistField) {
      fields[name] = type;
    }
    generateFieldDeclaration(type, name, persistField: persistField);
    return this;
  }

  void generateFieldDeclaration(type, name, {bool persistField = false}) {
    generateClass.writeln('$type $name;');
  }

  void _setClass() {
    var declaredClass = 'class $name';
    if (parentClass != null) {
      declaredClass += ' extends $parentClass';
    }
    declaredClass += ' {';
    generateClass.writeln(declaredClass);
  }

  void constructorEmpty() {
    generateClass.writeln('$name();');
  }

  String build() {
    generateClass.write('}');
    return generateClass.toString();
  }

  void addImports();
}

abstract class GenerateEntityClassAbstract extends GenerateClass {
  String entityInstance;
  String entityClassInstance;
  String entityClass;
  GenerateEntityClassAbstract(String name,
      {String classSuffix, String parentClass})
      : super(name, classSuffix: classSuffix, parentClass: parentClass) {
    entityInstance = name.toLowerCase() + 'Entity';
    entityClass = classPrefix + 'Entity';
    entityClassInstance = '$entityClass $entityInstance';
  }

  void importEntity() {
    importGenerate('entity');
  }

  void importGenerate(String suffix) {
    var fileImport = classPrefix.toLowerCase() + '.$suffix.dart';
    generateClass.writeln('import \'$fileImport\';');
  }
}

abstract class GenerateFlutterWidgetAbstract
    extends GenerateEntityClassAbstract {
  GenerateFlutterWidgetAbstract(String name,
      {String classSuffix, String parentClass})
      : super(name, classSuffix: classSuffix, parentClass: parentClass);
  void generateWidget();

  @override
  void addImports() {
    generateClass.writeln('import \'package:flutter/material.dart\';');
  }

  @override
  String build() {
    generateWidget();
    return super.build();
  }
}