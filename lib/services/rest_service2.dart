import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:global_configs/global_configs.dart';
import 'package:http/http.dart' as http;

import '../models/main_application.dart';
import '../ui/utils/core.dart';

class RestService2 {
  final String TAG = (RestService2).toString(); // ignore: non_constant_identifier_names
  static final RestService2 _singleton = RestService2._internal();

  factory RestService2() => _singleton;

  RestService2._internal();

  int _curRestIndex = 0;

  Future<Map<String, dynamic>> httpGet(path) async {
    late Map<String, dynamic> result;
    String url = GlobalConfigs().get("restHost")[_curRestIndex] + path;
    DebugPrint().log(TAG, "httpGet", "path = $url");
    result = await httpGET(url, auth: _authHeader());

    if (!result.containsKey("server_status")) {
      for (var host in GlobalConfigs().get("restHost")) {
        if ((!result.containsKey("server_status")) & (GlobalConfigs().get("restHost").indexOf(host) != _curRestIndex)) {
          url = host + path;
          // DebugPrint().log(TAG, "httpGet", "path = $url");
          result = await httpGET(url, auth: _authHeader());
          if (result.containsKey("server_status")) {
            _curRestIndex = GlobalConfigs().get("restHost").indexOf(host);
          }
        }
      }
    }

    DebugPrint().log(TAG, "httpGet", "result = $result");
    return result;
  }

  static Future<Map<String, dynamic>> httpGET(url, {auth = "auth"}) async {
    late Map<String, dynamic> result;
    late http.Response response;
    try {
      response = await http.get(
        Uri.parse(url),
        headers: {HttpHeaders.authorizationHeader: "Bearer $auth"},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return http.Response("", 504);
        },
      );
    } catch (error) {
      // Logger().v(error);
      result = <String, dynamic>{};
      result['status'] = "Service Unavailable";
      result['status_code'] = "503";
      result['error'] = error.toString();
      return result;
    }

    if (response.statusCode == 200) {
      try {
        result = json.decode(response.body);
        result["server_status"] = 'OK';
      } catch (error) {
        result = <String, dynamic>{};
        result['status'] = error.toString();
      }
    } else {
      result = <String, dynamic>{};
      result['status'] = "error";
    }

    return result;
  }

  static String _authHeader() {
    var header = {
      "deviceId": MainApplication().deviceId,
      "dispatching": GlobalConfigs().get("dispatchingToken"),
      "location": MainApplication().currentPosition?.toJson(),
      "platform": "android",
      "token": MainApplication().clientToken,
      "test": GlobalConfigs().get("isTest"),
    };

    // DebugPrint().log(TAG, "auth", header);

    var bytes = utf8.encode(header.toString());
    var res = base64.encode(bytes);
    return res;
  }
}
