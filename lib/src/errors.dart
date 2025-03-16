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
  UnexpectedTokenException(super.message, super.line, super.char);
}

class UnhandledFunctionException extends JxException {
  UnhandledFunctionException(super.message, super.line, super.char);
}

class FunctionException extends JxException {
  FunctionException(super.message, super.line, super.char);
}

class VariableException extends JxException {
  VariableException(super.message, super.line, super.char);
}

class UnhandledVariableException extends JxException {
  UnhandledVariableException(super.message, super.line, super.char);
}

class UnexpectedEndOfFileException extends JxException {
  UnexpectedEndOfFileException(super.message, super.line, super.char);
}

class IllegalTokenName extends JxException {
  IllegalTokenName(super.message, super.line, super.char);
}
