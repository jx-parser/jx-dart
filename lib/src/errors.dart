class JxException implements Exception {
  String message;
  int line;
  int char;

  JxException(this.message, this.line, this.char);

  @override
  String toString() {
    return '$message at line $line, pos $char';
  }
}

class UnexpectedTokenException extends JxException {
  UnexpectedTokenException(String message, int line, int char)
      : super(message, line, char);
}

class UnhandledFunctionException extends JxException {
  UnhandledFunctionException(String message, int line, int char)
      : super(message, line, char);
}

class FunctionException extends JxException {
  FunctionException(String message, int line, int char)
      : super(message, line, char);
}

class VariableException extends JxException {
  VariableException(String message, int line, int char)
      : super(message, line, char);
}

class UnhandledVariableException extends JxException {
  UnhandledVariableException(String message, int line, int char)
      : super(message, line, char);
}

class UnexpectedEndOfFileException extends JxException {
  UnexpectedEndOfFileException(String message, int line, int char)
      : super(message, line, char);
}

class IllegalTokenName extends JxException {
  IllegalTokenName(String message, int line, int char)
      : super(message, line, char);
}
