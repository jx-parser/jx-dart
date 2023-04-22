import 'package:jx/jx.dart';
import 'package:jx/src/errors.dart';
import 'package:test/test.dart';

void main() {
  group('JxParser', () {
    test('JSON Object', () {
      String jx = '''{
  "name": "jx",
  "year": 2022,
  "version": 1.0,
  "words": [
    "JSON",
    "extended"
  ],
  "attributes": {
    "extension": ".jx",
    "supported": true,
    "null": null
  }
}''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result['name'], equals('jx'));
      expect(result['year'], equals(2022));
      expect(result['version'], equals(1.0));

      expect(result['words'] is ArrayType, true);
      expect(result['words'].length, 2);

      expect(result['words'][0], equals('JSON'));
      expect(result['words'][1], equals('extended'));

      expect(result['attributes'] is ObjectType, true);
      expect(result['attributes'].keys.length, 3);

      expect(result['attributes']['extension'], equals('.jx'));
      expect(result['attributes']['supported'], equals(true));
      expect(result['attributes']['null'], equals(null));
    });

    test('JSON Array', () {
      String jx = '''[
  "jx",
  2022,
  1.0,
  [
    "JSON",
    "extended"
  ],
  {
    "extension": ".jx",
    "supported": true,
    "null": null
  }
]''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result is ArrayType, true);
      expect(result.length, equals(5));

      expect(result[0], equals('jx'));
      expect(result[1], equals(2022));
      expect(result[2], equals(1.0));

      expect(result[3] is ArrayType, true);
      expect(result[3].length, 2);

      expect(result[3][0], equals('JSON'));
      expect(result[3][1], equals('extended'));

      expect(result[4] is ObjectType, true);
      expect(result[4].keys.length, 3);

      expect(result[4]['extension'], equals('.jx'));
      expect(result[4]['supported'], equals(true));
      expect(result[4]['null'], equals(null));
    });

    test('Types', () {
      String jx = '''[
  #f90,
  #ff9900,
  0b111111111001100100000000,
  0xff9900,
  16750848,
  16750848.16750848,
  1234E+7,
  -1.0e3,
  "Hello, World!",
  true,
  false,
  null
]''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result is ArrayType, true);

      var i = 0;
      expect(result[i++], equals(16750848));
      expect(result[i++], equals(16750848));
      expect(result[i++], equals(16750848));
      expect(result[i++], equals(16750848));
      expect(result[i++], equals(16750848));
      expect(result[i++], equals(16750848.16750848));
      expect(result[i++], equals(1234E+7));
      expect(result[i++], equals(-1.0e3));
      expect(result[i++], equals('Hello, World!'));
      expect(result[i++], equals(true));
      expect(result[i++], equals(false));
      expect(result[i++], equals(null));
    });

    test('Unquoted keys', () {
      String jx = '''{
  name: "jx",
  year: 2022,
  version: 1.0,
  words: [
    "JSON",
    "extended"
  ],
  attributes: {
    extension: ".jx",
    supported: true,
    null: null
  }
}''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result['name'], equals('jx'));
      expect(result['year'], equals(2022));
      expect(result['version'], equals(1.0));

      expect(result['words'] is ArrayType, true);
      expect(result['words'].length, 2);

      expect(result['words'][0], equals('JSON'));
      expect(result['words'][1], equals('extended'));

      expect(result['attributes'] is ObjectType, true);
      expect(result['attributes'].keys.length, 3);

      expect(result['attributes']['extension'], equals('.jx'));
      expect(result['attributes']['supported'], equals(true));
      expect(result['attributes']['null'], equals(null));
    });

    test('Complex unquoted keys', () {
      String jx = '''{
  #name: "jx",
  year: 2022,
  _version: 1.0,
  words0: [
    "JSON",
    "extended"
  ],
  attributes.all: Named{
    extension: ".jx",
    supported#: true,
    0123t: null
  }
}''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result['#name'], equals('jx'));
      expect(result['year'], equals(2022));
      expect(result['_version'], equals(1.0));

      expect(result['words0'] is ArrayType, true);
      expect(result['words0'].length, 2);

      expect(result['words0'][0], equals('JSON'));
      expect(result['words0'][1], equals('extended'));

      expect(result['attributes.all'] is ObjectType, true);
      expect(result['attributes.all'].keys.length, 3);

      expect(result['attributes.all']['extension'], equals('.jx'));
      expect(result['attributes.all']['supported#'], equals(true));
      expect(result['attributes.all']['0123t'], equals(null));
    });

    test('Comments', () {
      String jx = '''
/**
 * This is a block comment header
 **/

// This is a comment header
     // This comment header has leading whitespace
[
  // A comment in an array
  "A",
  // Another array comment
  "B", // A comment after an element
  {
    /* A comment before the key */ "C" /* here */:/* there */ "C"/* Somewhere */, /* Everywhere */
    D /* More */: "D"
  }
]
/**
 * This is a block comment footer
 **/
''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result is ArrayType, true);
      expect(result.length, 3);

      expect(result[0], equals('A'));
      expect(result[1], equals('B'));

      expect(result[2] is ObjectType, true);
      expect(result[2]['C'], equals('C'));
      expect(result[2]['D'], equals('D'));
    });

    test('Separators', () {
      String jx = '''[
  'a', // Can be comma
  'b'; // Can be semicolon
  'c', // Can have trailing seperator
]''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result is ArrayType, true);
      expect(result.length, 3);

      expect(result[0], equals('a'));
      expect(result[1], equals('b'));
      expect(result[2], equals('c'));
    });

    test('Strings', () {
      String jx = '''[
  'Hello',
  "Hello",
  'This is a "quote"',
  "This is a 'quote'",
  'This is a \\'quote\\'',
  "This is a \\"quote\\"",
  'Hello' + ', World!',
  'A year is ' + 365 + ' days',
  'The outcome is ' + true + ', or is that ' + false + '?',
]''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result is ArrayType, true);

      var i = 0;
      expect(result[i++], equals('Hello'));
      expect(result[i++], equals('Hello'));
      expect(result[i++], equals('This is a "quote"'));
      expect(result[i++], equals('This is a \'quote\''));
      expect(result[i++], equals('This is a \'quote\''));
      expect(result[i++], equals('This is a "quote"'));
      expect(result[i++], equals('Hello, World!'));
      expect(result[i++], equals('A year is 365 days'));
      expect(result[i++], equals('The outcome is true, or is that false?'));
    });

    test('Multi-line strings', () {
      String jx = '''[
  'Hello, 
World!',
  "Hello, 
World!",
]''';
      var parser = JxParser()
        ..options.strict()
        ..options.trimLongStrings = false;
      var result = parser.parse(jx);

      expect(result is ArrayType, true);

      expect(result[0], equals('Hello, \nWorld!'));
      expect(result[1], equals('Hello, \nWorld!'));
    });

    test('Multi-line trimmed strings', () {
      String jx = '''[
  '
Hello, 
World!',
  "
Hello, 
World!
  ",
  '

Hello, 
World!

',
]''';
      var parser = JxParser()
        ..options.strict()
        ..options.trimLongStrings = true;
      var result = parser.parse(jx);

      expect(result is ArrayType, true);

      expect(result[0], equals('Hello, \nWorld!'));
      expect(result[1], equals('Hello, \nWorld!'));
      expect(result[2], equals('\nHello, \nWorld!\n'));
    });

    test('Arrays', () {
      String jx = '''[
  // Adding to arrays
  ['a', 'b'] + ['c', 'd'],
  ['a', 'b'] + 'c',
  ['a', 'b'] + 'c' + 'd',
  'a' + 'b' + ['c','d'],
  'z' + ('b' + ['c','d']),
  [1, 2] + 3,
  [true, false] + true,
  10 + ['a', 1.23] + true + 'b',

  // Removing from arrays
  ['a', 'b', 'c'] - ['b'],
  ['a', 'b', 'c'] - ['b', 'd'],
  ['a', 'b', 'c'] - 'b',
  ['a', 'b', 'c'] - 'b' - 'c',
  ['a', 'b', 'c'] - 'd',
  ['a', 'a', 'b', 'b', 'c'] - 'b',
  [1, 2, 3] - 2,
  [1, 2, 3] - 'a',
  [true, true, true, false, false] - true,
]''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result is ArrayType, true);

      var i = 0;
      expect(result[i++].items, equals(['a', 'b', 'c', 'd']));
      expect(result[i++].items, equals(['a', 'b', 'c']));
      expect(result[i++].items, equals(['a', 'b', 'c', 'd']));
      expect(result[i++].items, equals(['ab', 'c', 'd']));
      expect(result[i++].items, equals(['z', 'b', 'c', 'd']));
      expect(result[i++].items, equals([1, 2, 3]));
      expect(result[i++].items, equals([true, false, true]));
      expect(result[i++].items, equals([10, 'a', 1.23, true, 'b']));

      expect(result[i++].items, equals(['a', 'c']));
      expect(result[i++].items, equals(['a', 'c']));
      expect(result[i++].items, equals(['a', 'c']));
      expect(result[i++].items, equals(['a']));
      expect(result[i++].items, equals(['a', 'b', 'c']));
      expect(result[i++].items, equals(['a', 'a', 'c']));
      expect(result[i++].items, equals([1, 3]));
      expect(result[i++].items, equals([1, 2, 3]));
      expect(result[i++].items, equals([false, false]));
    });

    test('Objects', () {
      String jx = '''[
  // Concatenating objects
  {a:1, b:2} + {c:3, d:4},

  // Removing from objects
  {a:1, b:2, c:3, d:4} - {c:0, d:0},
  {a:1, b:2, c:3, d:4} - ['c', 'd'],
  {a:1, b:2, c:3, d:4} - 'c' - 'd',
  {a:1, b:2, c:3, d:4} - {e:0} - ['e'] - 'e',
]''';
      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result is ArrayType, true);

      var i = 0;
      expect(result[i++].items, equals({'a': 1, 'b': 2, 'c': 3, 'd': 4}));
      expect(result[i++].items, equals({'a': 1, 'b': 2}));
      expect(result[i++].items, equals({'a': 1, 'b': 2}));
      expect(result[i++].items, equals({'a': 1, 'b': 2}));
      expect(result[i++].items, equals({'a': 1, 'b': 2, 'c': 3, 'd': 4}));
    });

    test('Value output', () {
      String jx = '"Hello, world!"';

      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result is String, true);
      expect(result, equals('Hello, world!'));
    });

    test('Math builtin functions', () {
      String jx = '''{
  min: min(10, 20),
  max: max(10, 20),
  floor: floor(1.999999),
  ceil: ceil(0.23),
  round: round(1.4),
  cos: cos(3.14159),
  sin: sin(3.14159),
  tan: tan(3.14159),
  acos: acos(1.0),
  asin: asin(1.0),
  atan: atan(1.0),
  atan2: atan2(3.14159, -3.14159),
  sqrt: sqrt(16),
  pow: pow(2, 3),
  abs: abs(- 1.2),
  clamp: clamp(300, 0, 255),
  lerp: lerp(0, 255, 0.7),
  rad: rad(180),
  deg: deg(3.14159),
  random: random(2.0),
}''';

      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result['min'], equals(10));
      expect(result['max'], equals(20));
      expect(result['floor'], equals(1.0));
      expect(result['ceil'], equals(1.0));
      expect(result['round'], equals(1.0));
      expect(result['cos'], closeTo(-1.0, 0.0001));
      expect(result['sin'], closeTo(0.0, 0.0001));
      expect(result['tan'], closeTo(0.0, 0.0001));
      expect(result['acos'], equals(0.0));
      expect(result['asin'], closeTo(1.5707, 0.0001));
      expect(result['atan'], closeTo(0.7853, 0.0001));
      expect(result['atan2'], closeTo(2.3561, 0.0001));
      expect(result['sqrt'], equals(4));
      expect(result['pow'], equals(8));
      expect(result['abs'], equals(1.2));
      expect(result['clamp'], equals(255));
      expect(result['lerp'], equals(178.5));
      expect(result['rad'], closeTo(3.14159, 0.0001));
      expect(result['deg'], closeTo(180, 0.001));
      expect(result['random'], lessThanOrEqualTo(2.0));
      expect(result['random'], greaterThanOrEqualTo(0.0));
    });

    test('Color built-ins', () {
      String jx = '''{
  rgb: rgb(255, 153, 0),
  rgba: rgba(255, 153, 0, 0.5),
  alpha: alpha(0x80ff9900),
  red: red(0x80ff9900),
  green: green(0x80ff9900),
  blue: blue(0x80ff9900),
  opacity: opacity(0x80ff9900, 1.0),
  darken: darken(#ff9900, 0.25),
  lighten: lighten(#ff9900, 0.25),
  tint: tint(#ff9900, #0000ff, 0.25),
  grayscale: grayscale(#ff9900),
}''';

      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(result['rgb'], equals(16750848));
      expect(result['rgba'], equals(0x80ff9900));
      expect(result['alpha'], equals(128));
      expect(result['red'], equals(255));
      expect(result['green'], equals(153));
      expect(result['blue'], equals(0));
      expect(result['opacity'], equals(0xffff9900));
      expect(result['darken'], equals(0xbf7200)); // #bf7200
      expect(result['lighten'], equals(0xffb23f)); // #ffb23f
      expect(result['tint'], equals(0xbf723f)); // #bf723f
      expect(result['grayscale'], equals(0xa6a6a6)); // #a6a6a6
    });

    test('Custom functions', () {
      String jx = '''{
  name: getName();
  years: getAge();
  age: getAge('years');
  array: makeArray(a:1, b:2, c:3);
  object: makeObject(a:1, b:2, c:3);
  args: checkArgs('a', d:1, 'b', e:2, f:3, 'c', g:4);
}''';

      var parser = JxParser()
        ..options.strict()
        // Provide custom function handler
        ..onFunction = (String fn, List<dynamic> args, Map<String, dynamic> named) {
          switch (fn) {
            case 'getName':
              return 'JSON extended';
            case 'getAge':
              if (args.isEmpty) {
                return 30;
              }
              return '30 ${args[0]}';
            case 'makeArray':
              List<dynamic> vals = [];
              for (final v in named.values) {
                vals.add(v);
              }
              return vals;
            case 'makeObject':
              return named;
            case 'checkArgs':
              var a = [...args, ...named.keys];
              return a.join(' ');
            default:
              return null;
          }
        };
      var result = parser.parse(jx);

      expect(result['name'], equals('JSON extended'));
      expect(result['years'], equals(30));
      expect(result['age'], equals('30 years'));
      expect(result['array'] is ArrayType, true);
      expect(result['array'].items, equals([1, 2, 3]));
      expect(result['object'] is ObjectType, true);
      expect(result['object'].items, equals({'a': 1, 'b': 2, 'c': 3}));
      expect(result['args'], equals('a b c d e f g'));
    });

    test('Strict mode unhandled function', () {
      String jx = '{ foo: bar(1); }';

      var parser = JxParser()..options.strict();
      expect(() {
        parser.parse(jx);
      }, throwsA(isA<UnhandledFunctionException>()));
    });

    test('Relaxed mode unhandled function', () {
      String jx = '{ foo: bar(1); }';

      var parser = JxParser()..options.relaxed();
      var result = parser.parse(jx);

      expect(result is ObjectType, true);
      expect(result.keys.contains('foo'), true);
      expect(result['foo'], equals(null));
    });

    test('Builtin variables', () {
      String jx = '''[
  true,
  True,
  TRUE,
  false,
  False,
  FALSE,
  null,
  Null,
  NULL,
  pi,
  Pi,
  PI,
  inv_pi,
  Inv_Pi,
  INV_PI,
  pi_2,
  Pi_2,
  PI_2,
]''';

      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      var i = 0;
      expect(result[i++], equals(true));
      expect(result[i++], equals(true));
      expect(result[i++], equals(true));

      expect(result[i++], equals(false));
      expect(result[i++], equals(false));
      expect(result[i++], equals(false));

      expect(result[i++], equals(null));
      expect(result[i++], equals(null));
      expect(result[i++], equals(null));

      expect(result[i++], closeTo(3.14159, 0.00001));
      expect(result[i++], closeTo(3.14159, 0.00001));
      expect(result[i++], closeTo(3.14159, 0.00001));

      expect(result[i++], closeTo(1 / 3.14159, 0.00001));
      expect(result[i++], closeTo(1 / 3.14159, 0.00001));
      expect(result[i++], closeTo(1 / 3.14159, 0.00001));

      expect(result[i++], closeTo(3.14159 / 2, 0.00001));
      expect(result[i++], closeTo(3.14159 / 2, 0.00001));
      expect(result[i++], closeTo(3.14159 / 2, 0.00001));
    });

    test('Inline variables', () {
      String jx = '''{
  // Set up some variables
  \$name: "JSON extended",
  \$year: 1988,
  \$supported: true,
  \$theme: #ff9900,

  // Use the variables
  copyright: '(c) ' + name + ' ' + year,
  dart_support: supported,
  theme: {
    base: theme,
    highlight: lighten(theme, 0.5),
    shaded: darken(theme, 0.5),
    \$nested: 100,
  },
  count: nested,
  \$nested: 200,
  newCount: nested,
}''';

      var parser = JxParser()..options.strict();
      var result = parser.parse(jx);

      expect(parser.variables.length, 5);
      expect(parser.variables['name'], equals('JSON extended'));
      expect(parser.variables['year'], equals(1988));
      expect(parser.variables['supported'], equals(true));
      expect(parser.variables['theme'], equals(0xff9900));
      expect(parser.variables['nested'], equals(200));

      expect(result['copyright'], equals('(c) JSON extended 1988'));
      expect(result['dart_support'], equals(true));
      expect(result['theme']['base'], equals(0xff9900));
      expect(result['theme']['highlight'], equals(0xffcc7f));
      expect(result['theme']['shaded'], equals(0x7f4c00));
      expect(result['count'], equals(100));
      expect(result['newCount'], equals(200));
    });

    test('Variable names', () {
      String jx = '''{
  \$first: 1,
  \$second: 1,
  \$_third: 1,
  \$four_th: 1,
  \$FIFTH5: 1,
  \$6th: 1,
  \$seven#th: 1,
}''';

      var parser = JxParser()..options.strict();
      parser.parse(jx);

      for (var k in parser.variables.keys) {
        expect(parser.variables[k], equals(1), reason: 'The variable name "$k" is valid');
      }
    });

    test('Default variables', () {
      String jx = '''{
  // Default value of "JSON extended" will be overwritten by passed-in value
  ?\$name: "JSON extended",
  // Name will always be 1988, even if passed in
  \$year: 1988,
  // Default value will be used because none is passed in
  ?\$supported: true,

  name: name,
  year: year,
  supported: supported,
}''';

      var parser = JxParser()
        ..options.strict()
        ..variables.addAll({
          'name': 'Projectitis',
          'year': 2000,
        });
      var result = parser.parse(jx);

      expect(parser.variables.length, 3);
      expect(parser.variables['name'], equals('Projectitis'));
      expect(parser.variables['year'], equals(1988));
      expect(parser.variables['supported'], equals(true));

      expect(result['name'], equals('Projectitis'));
      expect(result['year'], equals(1988));
      expect(result['supported'], equals(true));
    });

    test('Strict mode unhandled variable', () {
      String jx = '{ foo: bar; }';

      var parser = JxParser()..options.strict();
      expect(() {
        parser.parse(jx);
      }, throwsA(isA<UnhandledVariableException>()));
    });

    test('Relaxed mode unhandled variable', () {
      String jx = '{ foo: bar; }';

      var parser = JxParser()..options.relaxed();
      var result = parser.parse(jx);

      expect(result is ObjectType, true);
      expect(result.keys.contains('foo'), true);
      expect(result['foo'], equals(null));
    });
  });
}
