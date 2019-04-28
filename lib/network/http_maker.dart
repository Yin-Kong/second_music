import 'package:second_music/network/dio_http.dart';

class HttpMakerParams {
  static const url = 'url';
  static const method = 'method';
  static const methodGet = 'get';
  static const methodPost = 'post';
}

typedef T HttpMaker<T>(Map<String, dynamic> params);

Future<T> dioHttpMaker<T extends String>(Map<String, dynamic> params) {
  var url = params.remove(HttpMakerParams.url);
  var method = params.remove(HttpMakerParams.method);
  switch (method) {
    case HttpMakerParams.methodGet:
      return dioGet<T>(url);
    case HttpMakerParams.methodPost:
      return dioPost<T>(url, params);
  }
  return null;
}
