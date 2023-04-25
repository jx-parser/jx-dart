/// Built-in variables and functions supported by the JX parser
///
/// Additional supported functions can be implemented here

import 'dart:math';

/// Indicates the required type for each builtin function argument
enum ArgType {
  number,
  int,
  string;

  static const List<ArgType> x0 = [];
  static const n1 = [ArgType.number];
  static const n2 = [ArgType.number, ArgType.number];
  static const n3 = [ArgType.number, ArgType.number, ArgType.number];
  static const i1 = [ArgType.int];
  static const i1n1 = [ArgType.int, ArgType.number];
  static const i2n1 = [ArgType.int, ArgType.int, ArgType.number];
  static const i3 = [ArgType.int, ArgType.int, ArgType.int];
  static const i3n1 = [ArgType.int, ArgType.int, ArgType.int, ArgType.number];
}

/// Details for a built-in function
class Builtin {
  final List<ArgType> types;
  final Function fn;

  /// Create a new builtin
  const Builtin(this.types, this.fn);

  // Supported built-in variables
  static Map<String, dynamic> variables = {
    'true': true,
    'false': false,
    'null': null,
    'pi': pi,
    'pi_2': pi / 2.0,
    'inv_pi': 1.0 / pi,
  };

  /// Supported built-in functions
  static const Map<String, Builtin> functions = {
    'min': Builtin(ArgType.n2, min),
    'max': Builtin(ArgType.n2, max),
    'floor': Builtin(ArgType.n1, floor),
    'ceil': Builtin(ArgType.n1, ceil),
    'round': Builtin(ArgType.n1, round),
    'cos': Builtin(ArgType.n1, cos),
    'sin': Builtin(ArgType.n1, sin),
    'tan': Builtin(ArgType.n1, tan),
    'acos': Builtin(ArgType.n1, acos),
    'asin': Builtin(ArgType.n1, asin),
    'atan': Builtin(ArgType.n1, atan),
    'atan2': Builtin(ArgType.n2, atan2),
    'sqrt': Builtin(ArgType.n1, sqrt),
    'pow': Builtin(ArgType.n2, pow),
    'abs': Builtin(ArgType.n1, abs),
    'clamp': Builtin(ArgType.n3, clamp),
    'lerp': Builtin(ArgType.n3, lerp),
    'rad': Builtin(ArgType.n1, degToRad),
    'deg': Builtin(ArgType.n1, radToDeg),
    'random': Builtin(ArgType.n1, random),
    'rgb': Builtin(ArgType.i3, colorFromRGB),
    'rgba': Builtin(ArgType.i3n1, colorFromRGBa),
    'alpha': Builtin(ArgType.i1, alpha),
    'red': Builtin(ArgType.i1, red),
    'green': Builtin(ArgType.i1, green),
    'blue': Builtin(ArgType.i1, blue),
    'opacity': Builtin(ArgType.i1n1, opacity),
    'darken': Builtin(ArgType.i1n1, darken),
    'lighten': Builtin(ArgType.i1n1, lighten),
    'tint': Builtin(ArgType.i2n1, tint),
    'grayscale': Builtin(ArgType.i1, grayscale),
  };

  /// Check that the arguments stored on this token are of the correct type
  static Builtin? check(String fn, List<dynamic> args) {
    final builtin = functions[fn];
    if (builtin == null) return null;
    if (args.length == builtin.types.length) {
      for (var i = 0; i < builtin.types.length; i++) {
        switch (builtin.types[i]) {
          case ArgType.int:
            if (args[i] is! int) {
              return null;
            }
            break;
          case ArgType.number:
            if ((args[i] is! double) && (args[i] is! int)) {
              return null;
            }
            break;
          case ArgType.string:
            if (args[i] is! String) {
              return null;
            }
            break;
        }
      }
    }
    return builtin;
  }

  /// Math built-ins
  static int floor(double n) {
    return n.floor();
  }

  static int ceil(double n) {
    return n.ceil();
  }

  static int round(double n) {
    return n.round();
  }

  static double abs(double n) {
    return n.abs();
  }

  static double clamp(double f, [double min = 0.0, double max = 1.0]) {
    return f < min
        ? min
        : f > max
            ? max
            : f;
  }

  static int iclamp(int v, [int min = 0, int max = 255]) {
    return v < min ? min : (v > max ? max : v);
  }

  static double lerp(double a, double b, double k) {
    return a + k * (b - a);
  }

  static double degToRad(double deg) {
    return deg * pi / 180.0;
  }

  static double radToDeg(double rad) {
    return rad * 180.0 / pi;
  }

  static double random(double n) {
    return Random().nextDouble() * n;
  }

  /// Color built-ins
  static int opacity(int color, double a) {
    int av = (clamp(a) * 255.0).round();
    return (color & 0xffffff) | (av << 24);
  }

  static int colorFromRGB(int R, int G, int B) {
    R = iclamp(R);
    G = iclamp(G);
    B = iclamp(B);
    return fastColorFromRGB(R, G, B);
  }

  static int fastColorFromRGB(int R, int G, int B) {
    return (R << 16) | (G << 8) | B;
  }

  static int colorFromRGBa(int R, int G, int B, double a) {
    R = iclamp(R);
    G = iclamp(G);
    B = iclamp(B);
    return fastColorFromRGBa(R, G, B, clamp(a));
  }

  static int fastColorFromRGBa(int R, int G, int B, double a) {
    return ((a * 255.0).round() << 24) | (R << 16) | (G << 8) | B;
  }

  static int fastColorFromRGBA(int R, int G, int B, int A) {
    return (A << 24) | (R << 16) | (G << 8) | B;
  }

  static int tint(int c, int t, double a) {
    a = clamp(a);
    int A =
        (lerp(((c >> 24) & 0xff).toDouble(), ((t >> 24) & 0xff).toDouble(), a))
            .floor();
    int R =
        (lerp(((c >> 16) & 0xff).toDouble(), ((t >> 16) & 0xff).toDouble(), a))
            .floor();
    int G =
        (lerp(((c >> 8) & 0xff).toDouble(), ((t >> 8) & 0xff).toDouble(), a))
            .floor();
    int B = (lerp((c & 0xff).toDouble(), (t & 0xff).toDouble(), a)).floor();
    return fastColorFromRGBA(R, G, B, A);
  }

  static int darken(int c, double a) {
    a = 1 - clamp(a);
    int A = (c >> 24) & 0xff;
    int R = (((c >> 16) & 0xff) * a).floor();
    int G = (((c >> 8) & 0xff) * a).floor();
    int B = ((c & 0xff) * a).floor();
    return fastColorFromRGBA(R, G, B, A);
  }

  static int lighten(int c, double a) {
    a = clamp(a);
    int A = (c >> 24) & 0xff;
    int R = (lerp(((c >> 16) & 0xff).toDouble(), 255, a)).floor();
    int G = (lerp(((c >> 8) & 0xff).toDouble(), 255, a)).floor();
    int B = (lerp((c & 0xff).toDouble(), 255.0, a)).floor();
    return fastColorFromRGBA(R, G, B, A);
  }

  static int alpha(int c) {
    return (c >> 24) & 0xff;
  }

  static int red(int c) {
    return (c >> 16) & 0xff;
  }

  static int green(int c) {
    return (c >> 8) & 0xff;
  }

  static int blue(int c) {
    return c & 0xff;
  }

  static int grayscale(int c) {
    int A = (c >> 24) & 0xff;
    int R = (c >> 16) & 0xff;
    int G = (c >> 8) & 0xff;
    int B = c & 0xff;
    int gr = iclamp((0.299 * R + 0.587 * G + 0.114 * B).round());
    return fastColorFromRGBA(gr, gr, gr, A);
  }
}
