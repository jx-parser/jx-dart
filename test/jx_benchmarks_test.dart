import 'package:jx/jx.dart';
import 'dart:convert';

import 'package:test/test.dart';

const String exampleJson = '''{
  "strings": {
    "empty": "",
    "simple": "hello",
    "quoted": "\\"quoted\\"",
    "unicode": "Hello 世界"
  },
  "numbers": {
    "integer": 42,
    "negative": -17,
    "float": 3.14159,
    "scientific": 1.23e-4,
    "zero": 0
  },
  "booleans": {
    "true": true,
    "false": false
  },
  "nullValue": null,
  "arrays": [
    123,
    "text",
    true,
    null,
    ["nested", "array"],
    {"key": "object in array"}
  ],
  "nestedObjects": {
    "level1": {
      "level2": {
        "level3": "deep"
      }
    }
  },
  "mixedArrays": [
    [1, 2, ["deep", "array"]],
    {"name": "obj", "data": [1, 2, 3]},
    [{"x": 1}, {"x": 2}]
  ]
}''';
num executions = 1000;

void main() {
  group('benchmarks', () {
    test('benchmarks', () {
      print('Running benchmarks...');
      DateTime startAll = DateTime.now();

      // JxParser
      print('JxParser');
      DateTime start = DateTime.now();
      dynamic result;
      var parser = JxParser()..options.strict();
      for (var i = 0; i < executions; i++) {
        result = parser.parse(exampleJson);
      }
      print('  ${DateTime.now().difference(start).inMilliseconds}ms');

      // Built-in JSON parser
      print('Built-in JSON parser (dart.convert)');
      start = DateTime.now();
      for (var i = 0; i < executions; i++) {
        result = json.decode(exampleJson);
      }
      print('  ${DateTime.now().difference(start).inMilliseconds}ms');

      // Print time it took to run benchmarks, in ms
      print(
          'Total time ${DateTime.now().difference(startAll).inMilliseconds}ms');

      expect(true, isTrue);
    });
  });
}
