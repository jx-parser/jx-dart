import 'dart:math';

import 'builtins.dart';
import 'errors.dart';
import 'options.dart';

/// Indicates the type of token parsed from the expression string
enum TokenType {
  unknown,
  openBracket,
  closeBracket,
  arrayStart,
  arrayEnd,
  objectStart,
  objectEnd,
  operator,
  array,
  object,
  string,
  identifier,
  number,
  boolean,
  nullValue,
  keyValuePair,
  variable,
  defaultVariable,
  look,
  function,
  separator,
  assignment,
  endOfFile,
  empty,
}

/// Character codes
class CharCode {
  static const backspace = 8;
  static const tab = 9;
  static const newline = 10;
  static const lineFeed = 12;
  static const carriageReturn = 13;
  static const space = 32;
  static const exclamationMark = 33;
  static const doubleQuote = 34;
  static const hash = 35;
  static const dollarSign = 36;
  static const percent = 37;
  static const ampersand = 38;
  static const singleQuote = 39;
  static const bracketOpen = 40;
  static const bracketClose = 41;
  static const asterisk = 42;
  static const plus = 43;
  static const comma = 44;
  static const minus = 45;
  static const period = 46;
  static const forwardSlash = 47;
  static const colon = 58;
  static const semicolon = 59;
  static const lessThan = 60;
  static const equals = 61;
  static const greaterThan = 62;
  static const questionMark = 63;
  static const at = 64;
  static const E = 69;
  static const squareBracketOpen = 91;
  static const backSlash = 92;
  static const squareBracketClose = 93;
  static const hat = 94;
  static const underscore = 95;
  static const grave = 96;
  static const b = 98;
  static const e = 101;
  static const f = 102;
  static const n = 110;
  static const r = 114;
  static const t = 116;
  static const u = 117;
  static const braceOpen = 123;
  static const pipe = 124;
  static const braceClose = 125;
  static const tilde = 126;

  /// Valid char for keys, variable names and function names
  static bool validIdentifier(int c) {
    if (c == CharCode.hash ||
        c == CharCode.underscore ||
        c == CharCode.period) {
      return true;
    } else if (c > 47 && c < 58) {
      // 0..9
      return true;
    } else if (c > 64 && c < 91) {
      // A..Z
      return true;
    } else if (c > 96 && c < 123) {
      // a..z
      return true;
    }
    return false;
  }
}

/// Array wrapper that supports type name
class ArrayType {
  final List<dynamic> items = [];
  String type = '';

  ArrayType([ArrayType? from]) {
    if (from != null) {
      items.addAll(from.items);
    }
  }

  // Wrapper methods
  int get length => items.length;
  dynamic operator [](int index) => items[index];
  @override
  String toString() {
    return type + items.toString();
  }
}

/// Object wrapper that supports type name
class ObjectType {
  final Map<String, dynamic> items = {};
  String type = '';

  ObjectType([ObjectType? from]) {
    if (from != null) {
      items.addAll(from.items);
    }
  }

  // Wrapper methods
  int get length => items.length;
  dynamic operator [](String key) => items[key];
  Iterable<String> get keys => items.keys;
  Iterable<dynamic> get values => items.values;
  @override
  String toString() {
    return type + items.toString();
  }
}

/// Extension to add functionality to string
extension StringExt on String {
  String bookend() {
    String s = toString();
    // Find first newline
    int newlinePos = 0;
    iterate_forward:
    for (var i = 0; i < s.length; i++) {
      switch (s.codeUnitAt(i)) {
        case CharCode.space:
        case CharCode.carriageReturn:
        case CharCode.tab:
          // ignore
          break;
        case CharCode.newline:
          newlinePos = i + 1;
          break iterate_forward;
        default:
          break iterate_forward;
      }
    }
    if (newlinePos > 0) {
      s = s.substring(newlinePos);
    }
    // Find last newline
    newlinePos = -1;
    iterate_backward:
    for (var i = s.length - 1; i >= 0; i--) {
      switch (s.codeUnitAt(i)) {
        case CharCode.space:
        case CharCode.carriageReturn:
        case CharCode.tab:
          // ignore
          break;
        case CharCode.newline:
          newlinePos = i;
          break iterate_backward;
        default:
          break iterate_backward;
      }
    }
    if (newlinePos >= 0) {
      s = s.substring(0, newlinePos);
    }
    return s;
  }
}

/// A token is one individual part of an expression.It could be a number,
/// a math operator, a function name, etc.
class Token {
  int line = 1;
  int char = 1;
  TokenType type = TokenType.unknown;
  dynamic _value;
  bool open = false;

  List<dynamic>? args;
  Map<String, dynamic>? namedArgs;

  /// Constructor
  Token([this.type = TokenType.unknown]);

  /// Get value
  dynamic get value => _value;

  /// Shorthand for converting to operator
  void toOperator(int op) {
    _value = op;
    type = TokenType.operator;
  }

  /// Set the actual value of the token and try to determine it's actual type.
  set value(dynamic v) {
    if (v is List) {
      _value = ArrayType()..items.addAll(v);
    } else if (v is Map) {
      _value = ObjectType()..items.addAll(v as Map<String, dynamic>);
    } else {
      _value = v;
    }
    if (type == TokenType.unknown) {
      if (v == null || v == double.nan) {
        _value = null;
        type = TokenType.nullValue;
      } else if (v is String) {
        type = TokenType.string;
      } else if (v is double) {
        type = TokenType.number;
      } else if (v is int) {
        type = TokenType.number;
      } else if (v is bool) {
        type = TokenType.boolean;
      } else if (v is ArrayType || v is List) {
        type = TokenType.array;
      } else if (v is ObjectType || v is Map) {
        type = TokenType.object;
      }
    }
  }

  @override
  String toString() {
    return '${type.name}(${value ?? ''})';
  }

  /// Debug this token
  void trace([int tab = 0]) {
    var s = ''.padRight(tab, ' ');
    print('${s}token {');
    print('$s  line: $line, pos: $char');
    if (type == TokenType.operator) {
      print('$s  type: operator(${String.fromCharCode(value)})');
    } else {
      print('$s  type: ${type.name}');
    }
    switch (type) {
      case TokenType.string:
      case TokenType.identifier:
      case TokenType.variable:
      case TokenType.defaultVariable:
      case TokenType.keyValuePair:
        print('$s  value: "$value"');
        break;
      case TokenType.array:
      case TokenType.object:
      case TokenType.boolean:
      case TokenType.number:
      case TokenType.nullValue:
        print('$s  value: $value${open ? '...' : ''}');
        break;
      case TokenType.function:
        print('$s  value: $value');
        print('$s  args: $args');
        print('$s  named: $namedArgs');
        break;
      default:
        break;
    }
    print('$s}');
  }
}

/// JX parser class. Call JxParser.parse(String str) to parse JX from a string. Implement
/// the onFunction callback to support custom functionality.
class JxParser {
  List<Token> stack = [];
  int nested = 0;
  String str = '';
  int pos = 0;
  int line = 1;
  int char = 1;

  /// User variables
  final Map<String, dynamic> variables = {};

  /// Callback to catch any unknown functions in the equation. (e.g. myFunc( ) )
  dynamic Function(String, List<dynamic>, Map<String, dynamic>)? onFunction;

  /// The options used by the parser
  final options = Options();

  /// Start parsing a JX expression
  dynamic parse(String str) {
    stack.clear();
    this.str = str;
    pos = 0;
    line = 1;
    char = 1;

    late Token token;
    while (pos < str.length) {
      token = parseToken();
      push(token);
    }

    return stack.last.value;
  }

  /// Grab the next token. It could be a value, an operator, a function, etc.
  /// Comments and whitespace are ignored.
  Token parseToken() {
    int quote = 0;
    Token token = Token();
    StringBuffer? string;

    string_iterator:
    while (pos < str.length) {
      // Get next character from input
      int c = next();
      if (c == CharCode.newline) {
        line++;
        char = 1;
      }

      // Have not yet started
      if (string == null) {
        token.line = line;
        token.char = char - 1;
        switch (c) {
          // Ignore whitespace
          case CharCode.newline:
          case CharCode.space:
          case CharCode.carriageReturn:
          case CharCode.tab:
            break;
          // Comment
          case CharCode.forwardSlash:
            int n = peek();
            // Line comment. Ignore until next newline
            if (n == CharCode.forwardSlash) {
              while (pos < str.length) {
                n = next();
                if (n == CharCode.newline) {
                  line++;
                  char = 1;
                  break;
                }
              }
              break;
            }
            // Block comment. Ignore until end of block comment
            else if (n == CharCode.asterisk) {
              while (pos < str.length) {
                n = next();
                if (n == CharCode.newline) {
                  line++;
                  char = 1;
                } else if ((n == CharCode.forwardSlash) &&
                    peek(-2) == CharCode.asterisk) {
                  break;
                }
              }
              break;
            }
            // Otherwise operator
            token.toOperator(c);
            break string_iterator;
          // Array
          case CharCode.squareBracketOpen:
            token.type = TokenType.arrayStart;
            return token;
          case CharCode.squareBracketClose:
            token.type = TokenType.arrayEnd;
            return token;
          // Object
          case CharCode.braceOpen:
            token.type = TokenType.objectStart;
            return token;
          case CharCode.braceClose:
            token.type = TokenType.objectEnd;
            return token;
          // Start string
          case CharCode.doubleQuote:
          case CharCode.singleQuote:
            token.type = TokenType.string;
            string = StringBuffer();
            quote = c;
            break;
          // Operators
          case CharCode.plus:
          case CharCode.minus:
          case CharCode.asterisk:
          case CharCode.hat:
          case CharCode.percent:
            token.toOperator(c);
            break string_iterator;
          // Brackets
          case CharCode.bracketOpen:
            token.type = TokenType.openBracket;
            return token;
          case CharCode.bracketClose:
            token.type = TokenType.closeBracket;
            return token;
          // Separator (next argument)
          case CharCode.comma:
          case CharCode.semicolon:
            token.type = TokenType.separator;
            return token;
          // Assignment
          case CharCode.colon:
            token.type = TokenType.assignment;
            return token;
          // Variable
          case CharCode.dollarSign:
            token.type = TokenType.variable;
            string = StringBuffer();
            break;
          // Default variable
          case CharCode.questionMark:
            string = StringBuffer();
            if (peek() == CharCode.dollarSign) {
              next();
              token.type = TokenType.defaultVariable;
            } else {
              string.writeCharCode(c);
            }
            break;
          // Any other character
          default:
            string = StringBuffer();
            string.writeCharCode(c);
            break;
        } // switch(c)
      } // !string

      // Quoted string
      else if (token.type == TokenType.string) {
        switch (c) {
          // End string
          case CharCode.doubleQuote:
          case CharCode.singleQuote:
            if (quote == c) {
              break string_iterator;
            }
            string.writeCharCode(c);
            break;
          // Escaped character
          case CharCode.backSlash:
            var cc = next();
            switch (cc) {
              case CharCode.r:
                string.writeCharCode(CharCode.carriageReturn);
                break;
              case CharCode.n:
                string.writeCharCode(CharCode.newline);
                break;
              case CharCode.t:
                string.writeCharCode(CharCode.tab);
                break;
              case CharCode.f:
                string.writeCharCode(CharCode.lineFeed);
                break;
              case CharCode.u:
              default:
                string.writeCharCode(cc);
            }
            break;
          // Any other character
          default:
            string.writeCharCode(c);
        }
      }

      // Unquoted string
      else if (CharCode.validIdentifier(c)) {
        string.writeCharCode(c);
      } else if (c == CharCode.plus && peek(-2) == CharCode.E) {
        string.writeCharCode(c);
      }

      // Terminator
      else {
        rewind();
        break string_iterator;
      }
    }

    // Check for end of file
    if ((string == null || string.isEmpty) && pos >= str.length) {
      token.type = TokenType.endOfFile;
      return token;
    }
    // Token is a variable or default variable
    else if (token.type == TokenType.variable ||
        token.type == TokenType.defaultVariable) {
      if (string!.isEmpty) {
        throw IllegalTokenName(
            'Variable must have a name', token.line, token.char);
      }
      token.value = string.toString();
      final String key = options.caseInsensitiveBuiltins
          ? token.value.toLowerCase()
          : token.value;
      if (Builtin.variables.containsKey(key)) {
        throw IllegalTokenName('Variable name "${token.value}" not allowed',
            token.line, token.char);
      }
    }
    // Token is a string
    else if (token.type == TokenType.string) {
      if (options.trimLongStrings) {
        token.value = string.toString().bookend();
      } else {
        token.value = string.toString();
      }
    }
    // Token is unknown (number, variable or unquoted key)
    else if (token.type == TokenType.unknown) {
      if (string == null) {
        throw UnexpectedTokenException('Unexpected token found', line, char);
      }
      final strValue = string.toString();
      final numValue = strToNum(strValue);
      if (numValue != null) {
        token.value = numValue;
        token.type = TokenType.number;
      } else {
        token.type = TokenType.identifier;
        token.value = strValue;
      }
    }
    return token;
  }

  /// Process the function described by the token
  Token processFunction(Token token) {
    String fn = token.value;

    final key = options.caseInsensitiveBuiltins ? fn.toLowerCase() : fn;
    if (Builtin.functions.containsKey(key)) {
      Builtin? builtin = Builtin.check(key, token.args!);
      if (builtin != null) {
        List<dynamic> args = [];
        for (var i = 0; i < token.args!.length; i++) {
          switch (builtin.types[i]) {
            case ArgType.int:
              args.add((token.args![i] as num).round());
              break;
            case ArgType.number:
              args.add((token.args![i] as num).toDouble());
              break;
            default:
              args.add(token.args![i]);
              break;
          }
        }
        return Token()..value = Function.apply(builtin.fn, args);
      } else {
        List<String> typeNames = [];
        for (final t in builtin!.types) {
          typeNames.add(t.name);
        }
        throw FunctionException(
            'Incorrect args for "$fn". Expect (${typeNames.join(', ')})',
            token.line,
            token.char);
      }
    } else {
      if (onFunction == null) {
        if (options.errorOnUnhandledFunction) {
          throw UnhandledFunctionException(
              'Unknown function "$fn"', token.line, token.char);
        } else {
          return Token()..value = null;
        }
      }
      return Token()
        ..value = onFunction?.call(fn, token.args!, token.namedArgs!);
    }
  }

  /// Handle doubles, hex, binary 0b1001110 or #fff colors.
  dynamic strToNum(String str) {
    // Parse # colors
    if (str[0] == '#') {
      if (str.length == 4) {
        return int.parse(
            '${str[1]}${str[1]}${str[2]}${str[2]}${str[3]}${str[3]}',
            radix: 16);
      } else if (str.length == 7) {
        return int.tryParse(str.substring(1), radix: 16);
      } else {
        return null;
      }
    }
    // Check for 0x0 or 0b0
    else if (str[0] == '0' && str.length > 1) {
      // Parse hex format
      if (str[1] == 'x' || str[1] == 'X') {
        return int.tryParse(str.substring(2), radix: 16);
      }
      // Parse binary format
      if (str[1] == 'b' || str[1] == 'B') {
        return int.tryParse(str.substring(2), radix: 2);
      }
    }
    // Parse float or int
    double? f = double.tryParse(str);
    if (f == null) return null;
    double i = f.truncateToDouble();
    return (i == f) ? i.toInt() : f;
  }

  /// Return the next character and advance
  int next() {
    char++;
    return str.codeUnitAt(pos++);
  }

  /// Return a character without advancing
  int peek([int offset = 0]) {
    return str.codeUnitAt(pos + offset);
  }

  /// Move backwards
  void rewind([int amount = 1]) {
    char -= amount;
    pos -= amount;
  }

  /// Get last token
  Token get last => stack.isEmpty ? Token(TokenType.empty) : stack.last;

  /// Get type of last token on stack
  TokenType get lastTokenType => last.type;

  /// Check if last token on stack is open
  bool get lastIsOpen => last.open;

  /// Add a token to the stack. Checks for correct token order.
  void push(Token token) {
    //print('push $token');
    switch (token.type) {
      // Pushing a value
      case TokenType.string:
      case TokenType.number:
      case TokenType.boolean:
      case TokenType.nullValue:
      case TokenType.identifier:
        stack.add(token);
        break;

      // Open array
      case TokenType.arrayStart:
        token.type = TokenType.array;
        token.value = ArrayType();
        token.open = true;
        if (lastTokenType == TokenType.identifier) {
          Token t = stack.removeLast();
          token.value.type = t.value;
        }
        stack.add(token);
        break;

      // Open object
      case TokenType.objectStart:
        token.type = TokenType.object;
        token.value = ObjectType();
        token.open = true;
        if (lastTokenType == TokenType.identifier) {
          Token t = stack.removeLast();
          token.value.type = t.value;
        }
        stack.add(token);
        break;

      // Open bracket
      case TokenType.openBracket:
        // If previous item is identifier, this is a function
        if (lastTokenType == TokenType.identifier ||
            lastTokenType == TokenType.string) {
          stack.last.type = TokenType.function;
          stack.last.open = true;
          stack.last.args = [];
          stack.last.namedArgs = {};
        }
        // Otherwise it's a bracket in an equation
        else {
          nested++;
          stack.add(token);
        }
        break;

      // Assignment
      case TokenType.assignment:
        // Check if last is operator
        if (isOperator()) {
          throw UnexpectedTokenException(
              'Unexpected token after operator', token.line, token.char);
        }
        // Process the stack
        processOperations();
        // Check if last is identifier or string
        if (lastTokenType == TokenType.identifier ||
            lastTokenType == TokenType.string) {
          stack.last.type = TokenType.keyValuePair;
          stack.last.value = stack.last.value;
          stack.last.open = true;
        }
        // Check if last is variable
        else if ((lastTokenType != TokenType.variable &&
                lastTokenType != TokenType.defaultVariable) ||
            !lastIsOpen) {
          throwOnUnexpectedToken(token);
        }
        break;

      // Pushing an operator
      case TokenType.operator:
        // Operator must follow a value
        if (!isValue() || lastIsOpen) {
          // Unless it's a minus sign
          if (token.value == CharCode.minus) {
            stack.add(Token()..value = 0.0);
          } else {
            throwOnUnexpectedToken(token);
          }
        }
        // If no other operators, always push
        if (stack.length < 2) {
          stack.add(token);
        }
        // Otherwise process stack until a lower token is found
        else {
          while ((stack.length > 1) && lowerOrSame(token)) {
            processOperations(limit: 1);
          }
          stack.add(token);
        }
        break;

      // Pushing object end
      case TokenType.objectEnd:
        processOperations(tryAssign: true);
        if (lastTokenType != TokenType.object) {
          throwOnUnexpectedToken(token);
        }
        last.open = false;
        break;

      // Pushing object end
      case TokenType.arrayEnd:
        processOperations(tryAssign: true);
        if (lastTokenType != TokenType.array) {
          throwOnUnexpectedToken(token);
        }
        last.open = false;
        break;

      // Pushing object end
      case TokenType.closeBracket:
        // If there are opening brackets, process the stack to the opening bracket
        if (nested > 0) {
          processToBracket();
        } else {
          processOperations(tryAssign: true);
          if (lastTokenType != TokenType.function) {
            throwOnUnexpectedToken(token);
          }
          stack.add(processFunction(stack.removeLast()));
          processOperations(tryAssign: true);
        }
        break;

      // Separator
      case TokenType.separator:
        processOperations(tryAssign: true, processIdentifiers: true);
        break;

      // Variable definition
      case TokenType.variable:
      case TokenType.defaultVariable:
        token.open = true;
        stack.add(token);
        break;

      // No more to parse
      case TokenType.endOfFile:
        break;

      // Uncaught token
      default:
        throwOnUnexpectedToken(token);
    }
    //traceStack(4);
  }

  /// Process one or more operations from the stack
  void processOperations(
      {int limit = 0,
      bool tryAssign = false,
      bool processIdentifiers = false}) {
    // Need at least three tokens on the stack to process it
    while (stack.length > 2) {
      if (stack[stack.length - 2].type != TokenType.operator) {
        break;
      }
      var b = stack.removeLast();
      var op = stack.removeLast();
      var a = stack.removeLast();

      var c = Token();
      //c.type = a.type;
      if (op.type == TokenType.operator) {
        processVariables(a);
        processVariables(b);
        switch (op.value as int) {
          case CharCode.plus:
            // Object
            if (a.type == TokenType.object) {
              if (b.type == TokenType.object) {
                c.value = ObjectType();
                c.value.items.addAll(a.value.items);
                c.value.items.addAll(b.value.items);
              } else {
                throw UnexpectedTokenException(
                    'Unexpected operator "${op.value}"', op.line, op.char);
              }
            }
            // Array
            else if (a.type == TokenType.array) {
              c.value = ArrayType(a.value);
              if (b.type == TokenType.array) {
                c.value.items.addAll(b.value.items);
              } else {
                c.value.items.add(b.value);
              }
            } else if (b.type == TokenType.array) {
              c.value = ArrayType(b.value);
              c.value.items.insert(0, a.value);
            }
            // String
            else if (a.type != TokenType.number || b.type != TokenType.number) {
              c.value = a.value.toString() + b.value.toString();
            }
            // Number
            else {
              c.value = a.value + b.value;
            }
            break;
          case CharCode.minus:
            // Object
            if (a.type == TokenType.object) {
              c.value = ObjectType(a.value);
              if (b.type == TokenType.object) {
                (c.value.items as Map).removeWhere(
                    (key, value) => (b.value.items as Map).keys.contains(key));
              } else if (b.type == TokenType.array) {
                (c.value.items as Map).removeWhere(
                    (key, value) => (b.value.items as List).contains(key));
              } else {
                (c.value.items as Map)
                    .removeWhere((key, value) => b.value == key);
              }
            }
            // Array
            else if (a.type == TokenType.array) {
              c.value = ArrayType(a.value);
              if (b.type == TokenType.array) {
                (c.value.items as List).removeWhere(
                    (item) => (b.value.items as List).contains(item));
              } else {
                (c.value.items as List).removeWhere((item) => b.value == item);
              }
            }
            // Number
            else if (a.type != TokenType.number) {
              throw UnexpectedTokenException(
                  'Unexpected operator "${op.value}"', op.line, op.char);
            } else {
              c.value = a.value - b.value;
            }

            break;
          case CharCode.forwardSlash:
            c.value = a.value / b.value;
            break;
          case CharCode.asterisk:
            c.value = a.value * b.value;
            break;
          case CharCode.hat:
            c.value = pow(a.value, b.value);
            break;
          case CharCode.percent:
            c.value = a.value % b.value;
            break;
          default:
            throw UnexpectedTokenException(
                'Unknown operator "${String.fromCharCode(op.value)}"',
                op.line,
                op.char);
        }
      }
      stack.add(c);
      limit--;
      if (limit == 0) break;
    }
    if (tryAssign) {
      assign(processIdentifiers: processIdentifiers);
    }
  }

  /// try to assign values to containers in the stack
  void assign({bool processIdentifiers = false}) {
    while (stack.length > 1) {
      var parent = stack[stack.length - 2];
      if (parent.open) {
        if (parent.type == TokenType.keyValuePair) {
          if (isValue() && !lastIsOpen) {
            final child = stack.removeLast();
            processVariables(child);
            parent = stack.removeLast();
            if (lastTokenType == TokenType.object) {
              last.value.items[parent.value] = child.value;
            } else if (lastTokenType == TokenType.function) {
              last.namedArgs![parent.value] = child.value;
            } else {
              throwOnUnexpectedToken(last);
            }
            continue;
          }
        } else if (parent.type == TokenType.array) {
          if (isValue() && !lastIsOpen) {
            final child = stack.removeLast();
            processVariables(child);
            parent.value.items.add(child.value);
            continue;
          }
        } else if (parent.type == TokenType.variable ||
            parent.type == TokenType.defaultVariable) {
          if (isValue() && !lastIsOpen) {
            final child = stack.removeLast();
            processVariables(child);
            parent = stack.removeLast();
            if (parent.type == TokenType.variable ||
                !variables.containsKey(parent.value)) {
              variables[parent.value] = child.value;
            }
            continue;
          }
        } else if (parent.type == TokenType.function) {
          if (isValue()) {
            final child = stack.removeLast();
            if (processIdentifiers && child.type == TokenType.identifier) {
              processVariables(child);
            }
            parent.args!.add(child.value);
            continue;
          }
        }
      }
      break;
    }
  }

  /// Process stack until an opening bracket is found
  void processToBracket() {
    // Otherwise process to opening bracket
    while (true) {
      // If next on stack is opening bracket, remove it and exit
      if (stack.last.type == TokenType.openBracket) {
        stack.removeLast();
        assign();
        break;
      }
      // If second on stack is opening bracket, 'process' the value in between
      if (stack[stack.length - 2].type == TokenType.openBracket) {
        var t = stack.removeLast();
        stack.removeLast();
        stack.add(t);
        assign();
        break;
      }
      // Otherwise process a single operation
      processOperations(limit: 1);
      // Exit if stack is empty
      if (stack.length < 2) break;
    }
    assign();
  }

  /// Resolve variable value
  void processVariables(Token token) {
    if (token.type == TokenType.identifier) {
      final String key = options.caseInsensitiveBuiltins
          ? token.value.toLowerCase()
          : token.value;
      if (Builtin.variables.containsKey(key)) {
        token.type = TokenType.unknown;
        token.value = Builtin.variables[key];
      } else if (variables.containsKey(token.value)) {
        token.type = TokenType.unknown;
        token.value = variables[token.value];
      } else if (options.errorOnUndefinedVariable) {
        throw UnhandledVariableException(
            'Unhandled variable "${token.value}"', token.line, token.char);
      } else {
        // XXX: This could break all sorts of things
        token.type = TokenType.unknown;
        token.value = null;
      }
    }
  }

  /// Check if the token is lower than the one on top of the stack
  bool lowerOrSame(Token a) {
    var b = stack[stack.length - 2];
    return order(a) <= order(b);
  }

  /// Return the precedence order of an operator
  int order(Token t) {
    if (t.type == TokenType.openBracket) {
      return 1;
    } else if (t.type == TokenType.operator) {
      switch (t.value as int) {
        case CharCode.plus:
        case CharCode.minus:
          return 2;
        case CharCode.asterisk:
        case CharCode.forwardSlash:
          return 3;
        case CharCode.hat:
        case CharCode.percent:
          return 4;
      }
    }
    return 0;
  }

  /// Check if a token on the stack is an operator
  bool isOperator([int i = -1]) {
    if (stack.isEmpty) {
      return false;
    } else if (i < 0) {
      return stack[stack.length + i].type == TokenType.operator;
    } else {
      return stack[i].type == TokenType.operator;
    }
  }

  /// Check if a token on the stack is a value type
  bool isValue([int i = -1]) {
    if (stack.isEmpty) {
      return false;
    }
    var t = (i < 0) ? stack[stack.length + i] : stack[i];
    switch (t.type) {
      case TokenType.array:
      case TokenType.boolean:
      case TokenType.nullValue:
      case TokenType.number:
      case TokenType.object:
      case TokenType.string:
      case TokenType.identifier:
        return true;
      default:
        return false;
    }
  }

  /// Unexpected token found
  void throwOnUnexpectedToken(Token t) {
    var desc = '';
    if (t.type == TokenType.operator) {
      desc = ' operator("${String.fromCharCode(t.value)}")';
    } else if (t.value != null) {
      desc = ' "${t.value}"';
    }
    throw UnexpectedTokenException(
        'Unexpected ${t.type.name} token$desc', t.line, t.char);
  }

  /// Trace this stack
  void traceStack([int tab = 0]) {
    var s = ''.padRight(tab, ' ');
    print('${s}stack [');
    for (int i = 0; i < stack.length; i++) {
      stack[i].trace(tab + 4);
    }
    print('$s]');
  }
}
