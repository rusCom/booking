import 'package:flutter/material.dart';

import '../../models/route_point.dart';
import '../../services/geo_service.dart';
import '../route_point/route_point_screen.dart';
import '../utils/core.dart';

class SystemGeocodeReplaceScreen extends StatefulWidget {
  final RoutePoint fromRoutePoint;

  SystemGeocodeReplaceScreen(this.fromRoutePoint);

  @override
  _SystemGeocodeReplaceScreenState createState() => _SystemGeocodeReplaceScreenState();
}

class _SystemGeocodeReplaceScreenState extends State<SystemGeocodeReplaceScreen> {
  final TAG = (SystemGeocodeReplaceScreen).toString(); // ignore: non_constant_identifier_names
  late RoutePoint toRoutePoint;

  @override
  Widget build(BuildContext context) {
    DebugPrint().log(TAG, "build", widget.fromRoutePoint.toString());
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Заменить точку геокодинга"),
            Text("name: " + widget.fromRoutePoint.name),
            Text("dsc: " + widget.fromRoutePoint.dsc),
            Text("placeID: " + widget.fromRoutePoint.placeId),
            MaterialButton(
              onPressed: () async {
                RoutePoint? destinationRoutePoint =
                    await Navigator.push<RoutePoint>(context, MaterialPageRoute(builder: (context) => RoutePointScreen()));
                if (destinationRoutePoint != null) {
                  setState(() {
                    toRoutePoint = destinationRoutePoint;
                    DebugPrint().log(TAG, "new point result = ", destinationRoutePoint.toString());
                  });
                }
              },
              child: Text("Выбрать новую точку"),
            ),
            toRoutePoint != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("На следующую точку геокодинга"),
                      Text("name: " + toRoutePoint.name),
                      Text("dsc: " + toRoutePoint.dsc),
                      Text("placeID: " + toRoutePoint.placeId),
                      MaterialButton(
                        child: Text("Заменить. Подумай, прежде чем нажать"),
                        onPressed: () async {
                          GeoService().geocodeReplace(widget.fromRoutePoint.placeId, toRoutePoint.placeId);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  )
                : Container(),
            MaterialButton(
              child: Text("Очистить кэш по геокодингу для выбранной точки."),
              onPressed: () async {
                GeoService().geocodeClear(widget.fromRoutePoint);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
