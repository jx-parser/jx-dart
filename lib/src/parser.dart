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
  number,
  boolean,
  nullValue,
  variable,
  defaultVariable,
  look,
  function,
  seperator,
  assignment,
  endOfFile,
  empty,
}

/// A token is one individual part of an expression.It could be a number,
/// a math operator, a function name, etc.
///
class Token {
  int pos = 0;
  int line = 1;
  int char = 1;
  TokenType type = TokenType.unknown;
  TokenType closingType = TokenType.unknown;
  String rawValue = '';
  List<Token> args = [];
  dynamic _value;

  /// Constructor
  Token([this.type = TokenType.unknown]);

  /// Shorthand for creating operator
  Token.asOperator(String op) {
    type = TokenType.operator;
    value = op;
  }

  /// Get value
  dynamic get value => _value;

  /// Shorthand for converting to operator
  void toOperator(String op) {
    value = op;
    type = TokenType.operator;
  }

  /// Set the actual value of the token (based on parsing rawValue, usually) and
  /// try to determine it's actual type.
  set value(dynamic v) {
    _value = v;
    if (v == null || v == double.nan) {
      _value = null;
      type = TokenType.nullValue;
    } else if (v is List) {
      type = TokenType.array;
    } else if (v is String) {
      type = TokenType.string;
    } else if (v is Map) {
      type = TokenType.object;
    } else if (v is double) {
      type = TokenType.number;
    } else if (v is int) {
      type = TokenType.number;
    } else if (v is bool) {
      type = TokenType.boolean;
    } else {
      type = TokenType.unknown;
    }
  }

  /// Reverse the sign of the value
  Token negate() {
    value = -value;
    return this;
  }

  /// Debug this token
  void trace([int tab = 0]) {
    var s = ''.padRight(tab, ' ');
    print('${s}token {');
    print('$s  line: $line, pos: $char');
    print('$s  rawValue: "$rawValue"');
    if (value is String) {
      print('$s  value: "$value"');
    } else {
      print('$s  value: $value');
    }
    switch (type) {
      case TokenType.operator:
        print('$s  type: operator($value)');
        break;
      default:
        print('$s  type: ${type.name}');
        break;
    }
    switch (closingType) {
      case TokenType.operator:
        print('$s  closingType: operator($value)');
        break;
      default:
        print('$s  closingType: ${type.name}');
        break;
    }
    print('$s}');
  }
}

/// The stack for storing and processing values and operators
class Stack {
  TokenType last = TokenType.unknown;
  List<Token> stack = [];
  int _nested = 0;
  int get nested => _nested;

  /// Check if stack is empty
  bool isEmpty() {
    return stack.isEmpty;
  }

  /// Add a token to the stack. Checks for correct token order.
  void push(Token token) {
    // Check if allowed to push token
    switch (token.type) {
      // Pushing an operator
      case TokenType.operator:
        if (token.value == '-') {
          if (stack.isEmpty || !lastIsValue()) {
            stack.add(Token()..value = 0.0);
            last = TokenType.number;
          }
        }
        switch (last) {
          // An operator can only follow a value
          case TokenType.operator:
          case TokenType.openBracket:
          case TokenType.unknown:
            unexpected(token);
            break;
          // Push the operator
          default:
            // If no other operators, always push
            if (stack.length < 2) {
              stack.add(token);
            }
            // Otherwise prcoess stack until a lower token is found
            else {
              while ((stack.length > 1) && lowerOrSame(token)) {
                process(1);
              }
              stack.add(token);
            }
            break;
        }
        break;
      // An open bracket cannot follow a value
      // A negative number can follow a value because it is likely a subtraction (e.g. 17 -8)
      default:
        {
          switch (last) {
            case TokenType.operator:
            case TokenType.openBracket:
            case TokenType.array:
            case TokenType.object:
            case TokenType.unknown:
              // if bracket, increase nesting counter
              if (token.type == TokenType.openBracket) _nested++;
              // Push token
              stack.add(token);
              break;
            case TokenType.number:
              if (token.value < 0) {
                push(Token.asOperator('-'));
                stack.add(token.negate());
              } else {
                unexpected(token);
              }
              break;
            default:
              unexpected(token);
              break;
          }
        }
    }
    // Remember last
    last = token.type;
  }

  /// Process one or more operations from the stack
  Token process([int count = 0]) {
    // Need at least three tokens on the stack to process it
    while (stack.length > 2) {
      var b = stack.removeLast();
      var op = stack.removeLast();
      var a = stack.removeLast();

      var c = Token();
      c.type = a.type;
      if (op.type == TokenType.operator) {
        switch (op.value) {
          case '+':
            if (a.type == TokenType.object) {
              if (b.type == TokenType.object) {
                c.value = {...(a.value as Map), ...(b.value as Map)};
              } else {
                throw UnexpectedTokenException('Unexpected operator "${op.value}"', op.line, op.char);
              }
            } else if (a.type == TokenType.array) {
              if (b.type == TokenType.array) {
                c.value = a.value + b.value;
              } else {
                c.value = a.value;
                c.value.add(b.value);
              }
            } else if (b.type == TokenType.array) {
              c.value = b.value;
              c.value.insert(0, a.value);
            } else if (a.type != TokenType.number || b.type != TokenType.number) {
              c.value = a.value.toString() + b.value.toString();
            } else {
              c.value = a.value + b.value;
            }
            break;
          case '-':
            if (a.type == TokenType.object) {
              if (b.type == TokenType.object) {
                c.value = a.value;
                (c.value as Map).removeWhere((key, value) => (b.value as Map).keys.contains(key));
              } else if (b.type == TokenType.array) {
                c.value = a.value;
                (c.value as Map).removeWhere((key, value) => (b.value as List).contains(key));
              } else {
                c.value = a.value;
                (c.value as Map).removeWhere((key, value) => b.value == key);
              }
            } else if (a.type == TokenType.array) {
              if (b.type == TokenType.array) {
                c.value = a.value;
                (c.value as List).removeWhere((item) => (b.value as List).contains(item));
              } else {
                c.value = a.value;
                (c.value as List).removeWhere((item) => b.value == item);
              }
            } else if (a.type != TokenType.number) {
              throw UnexpectedTokenException('Unexpected operator "${op.value}"', op.line, op.char);
            } else {
              c.value = a.value - b.value;
            }

            break;
          case '/':
            c.value = a.value / b.value;
            break;
          case '*':
            c.value = a.value * b.value;
            break;
          case '^':
            c.value = pow(a.value, b.value);
            break;
          case '%':
            c.value = a.value % b.value;
            break;
          default:
            throw UnexpectedTokenException('Unknown operator "${op.value}"', op.line, op.char);
        }
      }
      stack.add(c);
      count--;
      if (count == 0) break;
    }
    if (stack.isEmpty) {
      return Token(TokenType.empty);
    }
    return stack[0];
  }

  /// Process stack until an opening bracket is found
  void processToBracket() {
    // Otherwise process to opening bracket
    while (true) {
      // If next on stack is opening bracket, remove it and exit
      if (stack.last.type == TokenType.openBracket) {
        stack.removeLast();
        return;
      }
      // If second on stack is opening bracket, 'process' the value in between
      if (stack[stack.length - 2].type == TokenType.openBracket) {
        var t = stack.removeLast();
        stack.removeLast();
        stack.add(t);
        return;
      }
      // Otherwise process a single operation
      process(1);
      // Exit if stack is empty
      if (stack.length < 2) break;
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
      switch (t.value) {
        case '+':
        case '-':
          return 2;
        case '*':
        case '/':
          return 3;
        case '^':
        case '%':
          return 4;
      }
    }
    throw UnexpectedTokenException('Cannot calculate precendence. Unknown operator "${t.rawValue}"', t.line, t.char);
  }

  /// Check if the last token on the stack is an operator
  bool lastIsOperator() {
    return last == TokenType.operator;
  }

  /// Check if the last token on the stack is a value type
  bool lastIsValue() {
    switch (last) {
      case TokenType.array:
      case TokenType.boolean:
      case TokenType.nullValue:
      case TokenType.number:
      case TokenType.object:
      case TokenType.string:
        return true;
      default:
        return false;
    }
  }

  /// Unexpected token found
  void unexpected(Token t) {
    var desc = '';
    switch (t.type) {
      case TokenType.operator:
        desc = ' operator("${t.value}")';
        break;
      case TokenType.string:
      case TokenType.number:
      case TokenType.boolean:
      case TokenType.function:
        desc = ' "${t.rawValue}"';
        break;
      default:
        desc = ' ${t.type.name}';
        break;
    }
    throw UnexpectedTokenException('Unexpected ${t.type.name} token$desc', t.line, t.char);
  }

  /// Trace this stack
  void trace([int tab = 0]) {
    var s = ''.padRight(tab, ' ');
    print('${s}stack');
    if (stack.isEmpty) {
      print('$s  empty');
      return;
    }
    for (int i = 0; i < stack.length; i++) {
      print('$s$i:');
      stack[i].trace(tab + 2);
    }
  }
}

/// JX parser class. Call JxParser.parse(String str) to parse JX from a string. Implement
/// the onFunction callback to support custom functionality.
class JxParser {
  String str = '';
  int pos = 0;
  int line = 1;
  int char = 1;

  /// User variables
  final Map<String, dynamic> variables = {};

  /// Callback to catch any unknown functions in the equation. (e.g. myFunc( ) )
  dynamic Function(String, List<dynamic>)? onFunction;

  /// The options used by the parser
  final options = Options();

  /// Start parsing a JX expression
  dynamic parse(String str) {
    this.str = str;
    pos = 0;
    line = 1;
    char = 1;
    return parseExpr(false)?.value;
  }

  /// Parse an expression. An expression is actually a full equation, but because of
  /// function calls, multiple expressions can exist in an equation. For example:
  /// 17 + 3 * 1.22 / sin( 18.11 ^ 2 - 0.399 * 4229 )
  ///		The first expression is 17 + 3 * 1.22 / sin(...)
  ///		A second expression is 18.11 ^ 2 - 0.399 * 4229
  /// Returns The last token to be processed, which contains the value and other important info
  Token? parseExpr(bool inFunc, {bool isKey = false}) {
    Stack stack = Stack();
    late Token token;

    while (pos < str.length) {
      // Find the next token
      token = parseToken(isKey);
      //token.trace();

      // Process the found token
      switch (token.type) {
        // Parse an array (values)
        case TokenType.arrayStart:
          var arr = [];
          var found = false;
          // Parse expressions and add to array until end of array is found
          while (pos < str.length) {
            Token? t = parseExpr(false);
            if (t != null) {
              arr.add(t.value);
            }
            if (t == null || t.closingType == TokenType.arrayEnd) {
              token.value = arr;
              stack.push(token);
              found = true;
              break;
            }
          }
          if (found) continue;
          throw UnexpectedEndOfFileException(
            'Unexpected end of file after "${token.rawValue}" token',
            token.line,
            token.char,
          );
        // Parse an object (key/values)
        case TokenType.objectStart:
          Map<String, dynamic> obj = {};
          String? key;
          Token? k;
          Token? v;
          var found = false;
          while (pos < str.length) {
            // Parse expression, which is key, or end of object
            k = parseExpr(false, isKey: true);
            if (k != null) {
              if (k.closingType != TokenType.assignment) {
                throw UnexpectedTokenException('Colon expected', line, char);
              }
              key = k.value.toString();
              // Get the value
              v = parseExpr(false);
              // The key is a variable...
              if (k.type == TokenType.variable) {
                variables[key] = v?.value;
              }
              // The key is a default variable...
              else if (k.type == TokenType.defaultVariable) {
                if (!variables.keys.contains(key)) variables[key] = v?.value;
              }
              // Standard key...
              else {
                obj[key] = v?.value;
              }
            }
            // Check if the object is closed
            if ((k == null) || (v?.closingType == TokenType.objectEnd)) {
              token.value = obj;
              stack.push(token);
              found = true;
              break;
            }
          }
          if (found) continue;
          throw UnexpectedEndOfFileException('Unexpected end of file after "${token.rawValue}" token', line, char);
        // Function found. Parse the function and push the result to the stack
        case TokenType.function:
          parseFunction(token);
          stack.push(token);
          break;
        // Seperator found. Process stack
        case TokenType.seperator:
          token = stack.process();
          token.closingType = TokenType.seperator;
          return token;
        // Close bracket found
        case TokenType.closeBracket:
          // If there are opening brackets, process the stack to the opening bracket
          if (stack.nested > 0) {
            stack.processToBracket();
          }
          // The there are no opening brackets, should be last function argument. return it.
          else {
            if (!inFunc) unexpected(token);
            token = stack.process();
            token.closingType = TokenType.closeBracket;
            return token;
          }
          break;
        // End of file, array, object encountered, or assignment encountered
        case TokenType.endOfFile:
        case TokenType.arrayEnd:
        case TokenType.objectEnd:
        case TokenType.assignment:
          // Remember closing type
          var tt = token.type;
          // Check if in a function
          if (inFunc) {
            throw UnexpectedTokenException('Unexpected token within function', token.line, token.char);
          }
          // Check if last is operator
          if (stack.lastIsOperator()) {
            throw UnexpectedTokenException('Unexpected token after operator', token.line, token.char);
          }
          // If stack is empty, this is a trailing seperator and should be ignored
          if (stack.isEmpty()) {
            return null;
          }
          // Process the stack
          token = stack.process();
          token.closingType = tt;
          return token;
        // Found a mathematical operator, open bracket or value
        case TokenType.operator:
        case TokenType.openBracket:
        case TokenType.number:
        case TokenType.string:
        case TokenType.boolean:
        case TokenType.nullValue:
        case TokenType.variable:
        case TokenType.defaultVariable:
          // Push to the stack
          stack.push(token);
          break;
        // Something else has been found
        default:
          unexpected(token);
          break;
      }
    }

    return token;
  }

  /// Parse all arguments for a function. At this point we have the function
  /// name, and we are inside the bracket, about to parse the first argument.
  Token parseFunction(Token token) {
    token.args = [];
    Token? argument;
    while (true) {
      // Process the argument
      argument = parseExpr(true);
      if (argument == null) {
        throw FunctionException('Error parsing function', line, char);
      }
      token.args.add(argument);

      // Check expression was terminated correctly
      if (argument.closingType == TokenType.closeBracket) {
        token.value = processFunction(token);
        break;
      }
      // If not end of function, seperator is expected
      else if (argument.closingType != TokenType.seperator) {
        unexpected(token);
      }
    }
    return token;
  }

  /// Grab the next token. It could be a value, an operator, a function, etc.
  /// Comments and whitespace are ignored.
  Token parseToken([bool isKey = false]) {
    String quote = '';
    bool started = false;
    Token token = Token();

    string_iterator:
    while (pos < str.length) {
      // Get next character from input
      String c = next();
      if (c == '\n') {
        line++;
        char = 1;
      }

      // Have not yet started
      if (!started) {
        token.pos = pos - 1;
        token.line = line;
        token.char = char - 1;
        switch (c) {
          // Ignore linespace
          case '\n':
          case ' ':
          case '\r':
          case '\t':
            break;
          // Comment
          case '/':
            String n = peek();
            // Line comment. Ignore until newline
            if (n == '/') {
              while (pos < str.length) {
                n = next();
                if (n == '\n') {
                  line++;
                  char = 1;
                  break;
                }
              }
              break;
            }
            // Block comment. Ignore until end of block comment
            else if (n == '*') {
              while (pos < str.length) {
                n = next();
                if (n == '\n') {
                  line++;
                  char = 1;
                } else if ((n == '/') && peek(-2) == '*') {
                  break;
                }
              }
              break;
            }
            // Otherwise operator
            token.toOperator(c);
            break string_iterator;
          // Array
          case '[':
            token.type = TokenType.arrayStart;
            return token;
          case ']':
            token.type = TokenType.arrayEnd;
            return token;
          // Object
          case '{':
            token.type = TokenType.objectStart;
            return token;
          case '}':
            token.type = TokenType.objectEnd;
            return token;
          // Start string
          case '"':
          case '\'':
            token.type = TokenType.string;
            quote = c;
            started = true;
            break;
          // Operators
          case '+':
          case '*':
          case '^':
          case '%':
            token.toOperator(c);
            break string_iterator;
          // Special case, negative number or subtract operator
          case '-':
            /*
            int cc = peek().codeUnitAt(0); // Peek at next char
            if (((cc < '0'.codeUnitAt(0)) || (cc > '9'.codeUnitAt(0))) && (cc != '.'.codeUnitAt(0))) {
              token.toOperator(c);
              break string_iterator;
            }
            token.rawValue += c;
            started = true;
            break;
            */
            token.toOperator(c);
            break string_iterator;
          // Brackets
          case '(':
            token.type = TokenType.openBracket;
            return token;
          case ')':
            token.type = TokenType.closeBracket;
            return token;
          // Seperator (next argument)
          case ',':
          case ';':
            token.type = TokenType.seperator;
            return token;
          // Assignment (value follows)
          case ':':
            token.type = TokenType.assignment;
            return token;
          // Variable
          case '\$':
            if (!isKey) {
              throw UnexpectedTokenException('Unexpected variable definition "\$"', line, char);
            }
            token.type = TokenType.variable;
            started = true;
            break;
          // Default variable
          case '?':
            if (peek() == '\$') {
              if (!isKey) {
                throw UnexpectedTokenException('Unexpected variable definition "\$"', line, char);
              }
              next();
              token.type = TokenType.defaultVariable;
            } else {
              token.rawValue += c;
            }
            started = true;
            break;
          // Any other character
          default:
            token.rawValue += c;
            started = true;
            break;
        }
      }

      // Parsing string
      else if (token.type == TokenType.string) {
        switch (c) {
          // End string
          case '"':
          case '\'':
            if (quote == c) {
              break string_iterator;
            }
            token.rawValue += c;
            break;
          // Escaped character
          case '\\':
            var cc = next();
            switch (cc) {
              case 'r':
                token.rawValue += '\r';
                break;
              case 'n':
                token.rawValue += '\n';
                break;
              case 't':
                token.rawValue += '\t';
                break;
              case 'b':
                token.rawValue += String.fromCharCode(8);
                break;
              case 'f':
                token.rawValue += String.fromCharCode(12);
                break;
              case 'u':
              default:
                token.rawValue += cc; // Literally add the char
            }
            break;
          // Any other character, including inline newlines, tabs and other whitespace!
          default:
            token.rawValue += c;
        }
      }

      // Variable, function or unquoted key
      else {
        switch (c) {
          // If terminated by bracket, is a function
          case '(':
            token.type = TokenType.function;
            break string_iterator;
          // Check for exponential notation (123e+7, 123E+7), or end
          case '+':
            if (peek(-2).toLowerCase() == 'e') {
              token.rawValue += c;
              break;
            } else if (isKey) {
              token.rawValue += c;
              break;
            }
            rewind();
            break string_iterator;
          // Ends if find operator, bracket, seperator or assignment
          case '-':
          case '/':
          case '*':
          case '^':
          case '%':
          case ')':
          case ']':
          case '}':
          case ',':
          case ';':
            if (isKey) {
              token.rawValue += c;
              break;
            }
            rewind();
            break string_iterator;
          // Start end sequence if whitespace or colon found
          case ' ':
          case '\r':
          case '\n':
          case '\t':
          case ':':
            if (isKey && token.type == TokenType.unknown) {
              token.type = TokenType.string;
            }
            rewind();
            break string_iterator;
          // Other
          default:
            token.rawValue += c;
            break;
        }
      }
    }

    // Check for end of file
    if (token.rawValue == '' && pos >= str.length) {
      token.type = TokenType.endOfFile;
    }
    // Token is default variable (always assignment)
    else if (token.type == TokenType.defaultVariable) {
      if (!isKey) {
        throw VariableException('Unexpected default variable assignment', token.line, token.char);
      }
      token.value = token.rawValue;
      token.type = TokenType.defaultVariable;
    }
    // Token is a variable
    else if (token.type == TokenType.variable) {
      if (token.rawValue.isEmpty) {
        throw IllegalTokenName('Variable must have a name', token.line, token.char);
      }
      final key = options.caseInsensitiveBuiltins ? token.rawValue.toLowerCase() : token.rawValue;
      if (Builtin.variables.containsKey(key)) {
        throw IllegalTokenName('Variable name "${token.rawValue}" not allowed', token.line, token.char);
      }
      token.value = token.rawValue;
      token.type = TokenType.variable;
    }
    // Token is a string
    else if (token.type == TokenType.string) {
      String s = token.rawValue;
      if (options.trimLongStrings) {
        // Find first newline
        int newlinePos = 0;
        iterate_forward:
        for (var i = 0; i < s.length; i++) {
          switch (s[i]) {
            case ' ':
            case '\r':
            case '\t':
              // ignore
              break;
            case '\n':
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
          switch (s[i]) {
            case ' ':
            case '\r':
            case '\t':
              // ignore
              break;
            case '\n':
              newlinePos = i;
              break iterate_backward;
            default:
              break iterate_backward;
          }
        }
        if (newlinePos >= 0) {
          s = s.substring(0, newlinePos);
        }
      }
      token.value = s;
    }
    // Token is unknown (number, variable or unquoted key)
    else if (token.type == TokenType.unknown) {
      // Unquoted key
      if (isKey) {
        token.value = token.rawValue;
      }
      // Variable
      else {
        // See if it's a number
        token.value = strToNum(token.rawValue);
        final key = options.caseInsensitiveBuiltins ? token.rawValue.toLowerCase() : token.rawValue;
        if (token.value != null) {
          token.type = TokenType.number;
        } else if (Builtin.variables.containsKey(key)) {
          token.value = Builtin.variables[key];
        } else if (variables.containsKey(token.rawValue)) {
          token.value = variables[token.rawValue];
        } else if (options.errorOnUndefinedVariable) {
          throw UnhandledVariableException('Unhandled variable "${token.rawValue}"', token.line, token.char);
        } else {
          token.value = null;
        }
      }
    }
    return token;
  }

  /// Process the function described by the token
  dynamic processFunction(Token token) {
    String fn = token.rawValue;

    final key = options.caseInsensitiveBuiltins ? fn.toLowerCase() : fn;
    if (Builtin.functions.containsKey(key)) {
      Builtin builtin = Builtin.functions[key]!;
      if (checkArgs(token, builtin.types, fn)) {
        List<dynamic> args = [];
        for (var i = 0; i < token.args.length; i++) {
          switch (builtin.types[i]) {
            case ArgType.int:
              args.add((token.args[i].value as num).round());
              break;
            case ArgType.number:
              args.add((token.args[i].value as num).toDouble());
              break;
            default:
              args.add(token.args[i].value);
              break;
          }
        }
        return Function.apply(builtin.fn, args);
      }
    } else {
      if (onFunction == null) {
        if (options.errorOnUnhandledFunction) {
          throw UnhandledFunctionException('Unknown function "$fn"', token.line, token.char);
        } else {
          return null;
        }
      }
      List<dynamic> args = [];
      for (final t in token.args) {
        if (t.type != TokenType.empty) {
          args.add(t.value);
        }
      }
      dynamic res = onFunction?.call(fn, args);
      return res;
    }
  }

  /// Check that the arguments stored on this token are of the correct type
  bool checkArgs(Token token, List<ArgType> types, [String? fn]) {
    bool ok = false;
    if (token.args.length == types.length) {
      ok = true;
      check_types:
      for (var i = 0; i < types.length; i++) {
        switch (types[i]) {
          case ArgType.int:
            if (token.args[i].value is! int) {
              ok = false;
              break check_types;
            }
            break;
          case ArgType.number:
            if ((token.args[i].value is! double) && (token.args[i].value is! int)) {
              ok = false;
              break check_types;
            }
            break;
          case ArgType.string:
            if (token.args[i].value is! String) {
              ok = false;
              break check_types;
            }
            break;
        }
      }
    }
    if (!ok && fn != null) {
      List<String> typeNames = [];
      for (final t in types) {
        typeNames.add(t.name);
      }
      throw FunctionException('Incorrect args for "$fn". Expect (${typeNames.join(', ')})', token.line, token.char);
    }
    return ok;
  }

  /// Handle doubles, hex, binary 0b1001110 or #fff colors.
  dynamic strToNum(String str) {
    // Parse # colors
    if (str[0] == '#') {
      if (str.length == 4) {
        return int.parse('${str[1]}${str[1]}${str[2]}${str[2]}${str[3]}${str[3]}', radix: 16);
      } else if (str.length == 7) {
        return int.parse(str.substring(1), radix: 16);
      } else {
        throw 'Unknown hex format "$str"';
      }
    }
    // Check for 0x0 or 0b0
    else if (str[0] == '0' && str.length > 1) {
      // Parse hex format
      if (str[1] == 'x' || str[1] == 'X') {
        return int.parse(str.substring(2), radix: 16);
      }
      // Parse binary format
      if (str[1] == 'b' || str[1] == 'B') {
        return int.parse(str.substring(2), radix: 2);
      }
    }
    // Parse float or int
    double? f = double.tryParse(str);
    if (f == null) return null;
    double i = f.truncateToDouble();
    return (i == f) ? i.toInt() : f;
  }

  void unexpected(Token t) {
    var desc = '';
    switch (t.type) {
      case TokenType.operator:
        desc = ' TTOperator("${String.fromCharCode(t.value)}")';
        break;
      case TokenType.string:
      case TokenType.number:
      case TokenType.boolean:
      case TokenType.function:
        desc = ' "${t.rawValue}"';
        break;
      default:
        desc = ' ${t.type.name}';
        break;
    }
    throw UnexpectedTokenException('Unexpected ${t.type.name} token$desc', t.line, t.char);
  }

  String next() {
    char++;
    return str[pos++];
  }

  String peek([int offset = 0]) {
    return str[pos + offset];
  }

  void rewind([int amount = 1]) {
    char -= amount;
    pos -= amount;
  }
}
