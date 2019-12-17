abstract class GenerateClass {
  String name;
  String classPrefix;
  String classSuffix;
  String parentClass;
  String fieldPrefix;
  Map<String, String> fields = new Map();
  StringBuffer generateClass = new StringBuffer();
  GenerateClass(this.classPrefix, {this.classSuffix, this.parentClass}) {
    this.name = this.classPrefix;
    if (this.classSuffix != null) {
      this.name += this.classSuffix;
    }
    addImports();
    _setClass();
  }

  GenerateClass addField(String type, String name, {bool persistField: false}) {
    if (persistField) {
      fields[name] = type;
    }
    generateFieldDeclaration(type, name, persistField: persistField);
    return this;
  }

  generateFieldDeclaration(type, name, {bool persistField: false}) {
    generateClass.writeln('$type $name;');
  }

  _setClass() {
    String declaredClass = 'class $name';
    if (this.parentClass != null) {
      declaredClass += ' extends $parentClass';
    }
    declaredClass += ' {';
    generateClass.writeln(declaredClass);
  }

  constructorEmpty() {
    generateClass.writeln('$name();');
  }

  String build() {
    generateClass.write('}');
    return generateClass.toString();
  }

  addImports();
}

abstract class GenerateEntityClassAbstract extends GenerateClass {
  String entityInstance;
  String entityClassInstance;
  String entityClass;
  GenerateEntityClassAbstract(String name,
      {String classSuffix, String parentClass})
      : super(name, classSuffix: classSuffix, parentClass: parentClass) {
    this.entityInstance = name.toLowerCase() + 'Entity';
    this.entityClass = this.classPrefix + 'Entity';
    this.entityClassInstance = '$entityClass $entityInstance';
  }

  importEntity() {
    importGenerate('entity');
  }

  importGenerate(String suffix) {
    String fileImport = this.classPrefix.toLowerCase() + '.$suffix.dart';
    generateClass.writeln('import \'$fileImport\';');
  }
}
