import 'dart:async';

import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:booking/constants/style.dart';
import 'package:booking/data/main_location.dart';
import 'package:booking/main_utils.dart';
import 'package:booking/services/map_markers_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:global_configs/global_configs.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/debug_print.dart';
import '../services/rest_service.dart';
import 'order.dart';
import 'order_state.dart';
import 'preferences.dart';
import 'profile.dart';
import 'route_point.dart';

class MainApplication {
  final String TAG = (MainApplication).toString(); // ignore: non_constant_identifier_names
  static final MainApplication _singleton = MainApplication._internal();

  factory MainApplication() => _singleton;

  MainApplication._internal();

  SharedPreferences? _sharedPreferences;

  Position? currentPosition;
  final Order _curOrder = Order();
  String? _clientToken;
  GoogleMapController? mapController;
  Preferences preferences = Preferences();
  bool _timerStarted = false, _lastLocation = true;
  bool _dataCycle = false;
  bool _loadingDialog = false;

  Map<String, dynamic> clientLinks = {};
  List<RoutePoint> nearbyRoutePoint = [];
  String? pushToken;
  PackageInfo? packageInfo;

  static AudioCache audioCache = AudioCache();
  static const audioAlarmOrderStateChange = "sounds/order_state_change.wav";

  final player = AudioPlayer();

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  Future<bool> init(BuildContext context) async {

    _sharedPreferences = await SharedPreferences.getInstance();

    packageInfo = await PackageInfo.fromPlatform();

    // await GlobalConfiguration().loadFromAsset("app_settings");
    await GlobalConfigs().loadJsonFromdir('assets/cfg/app_settings.json');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    currentPosition = await Geolocator.getCurrentPosition();

    if (currentPosition == null) {
      currentPosition = Position(
          latitude: 54.7184554,
          longitude: 55.9257656,
          accuracy: 0.0,
          altitude: 0.0,
          speed: 0.0,
          heading: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          timestamp: DateTime.now(),
          headingAccuracy: 0.0);
      _lastLocation = false;
    }

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null) {
          currentPosition = position;
          if (!_lastLocation) {
            _lastLocation = true;
            MainApplication().curOrder.moveToCurLocation();
          }
        }
      },
    );

    _clientToken = _sharedPreferences?.getString("_clientToken") ?? "";

    await AppMetrica.activate(const AppMetricaConfig("fafb31ab-508e-4ab1-98a4-ee4902aadcc3"));


    FirebaseMessaging messaging = FirebaseMessaging.instance;
    pushToken = await messaging.getToken();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      DebugPrint().log("FirebaseMessaging", "onNewMessage", message.data.toString());
      if (message.data.isNotEmpty){
        if (message.data["type"] == "new_state")_loadDataCycle();
        if (message.data["agent_location"]){
          MainLocation mainLocation = MainLocation.fromJson(message.data["location"]);
          MapMarkersService().addAgentLocation(mainLocation);
        }
      }
    });

    return true;
  }

  playAudioAlarmOrderStateChange() {
    // audioCache.play(audioAlarmOrderStateChange);
    player.play(AssetSource(audioAlarmOrderStateChange));
  }

  Order get curOrder {
    return _curOrder;
  }

  launchURL(String url) async {
    Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  hideProgress(BuildContext context) {
    if (_loadingDialog) {
      Navigator.pop(context);
      _loadingDialog = false;
    }
  }

  showProgress(BuildContext context) {
    if (!_loadingDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            backgroundColor: mainColor,
          ),
        ),
      );
      _loadingDialog = true;
    }
  }

  showSnackBarError(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 3),
    ));
  }

  parseData(Map<String, dynamic>? jsonData) {
    DebugPrint().log(TAG, "parseData", jsonData);
    if (jsonData == null) return;

    try {
      clientLinks['privacy_policy'] = MainUtils.jsonGetString(jsonData, 'privacy_policy');
      clientLinks['license_agreement'] = MainUtils.jsonGetString(jsonData, 'license_agreement');

      if (jsonData.containsKey("client_links")) {
        clientLinks['privacy_policy'] = jsonData['client_links']['support_phone'] ?? "";
        clientLinks['license_agreement'] = jsonData['client_links']['license_agreement'] ?? "";
      }

      if (jsonData.containsKey("nearby_geo_objects")) {
        Iterable list = jsonData['nearby_geo_objects'];
        nearbyRoutePoint = list.map((model) => RoutePoint.fromJson(model)).toList();
      }

      if (jsonData.containsKey("preferences")) preferences.parseData(jsonData["preferences"]);
      if (jsonData.containsKey("profile")) Profile().parseData(jsonData["profile"]);

      if (jsonData.containsKey("order")) {
        if (jsonData["order"].toString() != "{}") {
          curOrder.parseData(jsonData["order"]);
        } else {
          curOrder.orderState = OrderState.newOrder;
        }
      } else {
        curOrder.orderState = OrderState.newOrder;
      }

    } catch (exception, stacktrace) {
      Map<String, dynamic> data = {"method": "parserData",
        "exception": exception.toString(),
        "stacktrace": stacktrace.toString()
      };
      RestService().httpPost("/server_error", data);
      if (GlobalConfigs().get("isTest")) {
        Fluttertoast.showToast(msg: exception.toString(), gravity: ToastGravity.TOP);
      }
    }
  }

  LatLng get currentLocation => LatLng(currentPosition!.latitude, currentPosition!.longitude);

  get clientToken {
    if (_clientToken == "") return "_null";
    if (_clientToken == null) return "_null";
    return _clientToken;
  }

  set clientToken(value) {
    _clientToken = value;
    _sharedPreferences!.setString("_clientToken", value);
  }

  set dataCycle(bool value) {
    _dataCycle = value;
    if (_dataCycle == false) {
      _timerStarted = false;
    }

    if (_dataCycle) {
      if (!_timerStarted) {
        _timerStarted = true;
        Timer.periodic(
          Duration(seconds: Preferences().systemTimerTask),
          (timer) async {
            await _loadDataCycle();
            if (!_timerStarted) {
              timer.cancel();
            }
          },
        );
      }
    }
  }

  _loadDataCycle() async {
    Map<String, dynamic> restResult = await RestService().httpGet("/data");
    if ((restResult['status'] == 'OK') & (restResult.containsKey("result"))) {
      parseData(restResult['result']);
    }
  }
}
