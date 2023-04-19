class Options {
  /// Throw an error if a function is unhandled.
  /// Otherwise null is returned.
  bool errorOnUnhandledFunction = false;

  /// Throw an error if a variable is not defined.
  /// Otherwise null is returned.
  bool errorOnUndefinedVariable = false;

  /// Trim the first and last empty line from a long string (default true)
  bool trimLongStrings = true;

  /// Ignore case for built-in function and variable names
  bool caseInsensitiveBuiltins = true;

  /// Preset options for relaxed mode (default)
  void relaxed() {
    errorOnUnhandledFunction = false;
    errorOnUndefinedVariable = false;
  }

  /// Preset options for strict mode
  void strict() {
    errorOnUnhandledFunction = true;
    errorOnUndefinedVariable = true;
  }
}
