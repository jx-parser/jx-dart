import 'package:jx/jx.dart';

void main() {
  String jx = '{ foo: "bar"; }';

  var parser = JxParser()..options.relaxed();
  var result = parser.parse(jx);

  print(result);
}
