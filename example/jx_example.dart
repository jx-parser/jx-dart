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
