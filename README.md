A parser for jx files (extended JSON format).

## Features

jx (short for JSON eXtended, file extension `.jx`) is a file format that extends [JSON](https://www.json.org/json-en.html). jx was designed specifically for configuration files, but has a wide range of potential applications. jx is a super-set of JSON that supports core JSON but adds many more powerful features. For example:
- Inline and block comments
- Keys without quotes
- Single and double quoted strings
- Equations
- Variables, functions and user-defined functions
- String, Array and Object operations (combine, add, remove etc)
- Color support and manipulation

> **[Example jx file](https://github.com/jx-parser/jx/blob/master/examples/example.jx)**
> **[Overview of the jx specification](https://github.com/jx-parser/jx#readme)**

## Getting started

- Add `jx` to your `pubspec.yaml`

## Usage

```dart
import 'package:jx/jx.dart';

void main() {
  String jx = '''{
    // This is an example jx file
    \$code: 'jx';
    name: code + ' file format (.' + code + ')';
  }''';
  var parser = JxParser();
  var result = parser.parse(jx);

  print(result['name']); // jx file format (.jx)
  print(result.variables['code']); // jx
}
```
