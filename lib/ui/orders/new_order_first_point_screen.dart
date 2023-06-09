import 'package:booking/ui/utils/core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/main_application.dart';
import '../../models/preferences.dart';
import '../../models/route_point.dart';
import '../../services/app_blocs.dart';
import '../../services/geo_service.dart';
import '../../services/map_markers_service.dart';
import '../route_point/route_point_screen.dart';

class NewOrderFirstPointScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final ValueChanged<RoutePoint>? onChanged;
  BuildContext? _context;

  NewOrderFirstPointScreen({super.key, this.onChanged});

  void setText(String data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.text = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Stack(
      children: <Widget>[
        Positioned(
          bottom: 55,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.transparent,
            constraints: const BoxConstraints(minWidth: double.infinity),
            margin: const EdgeInsets.only(left: 8, right: 8),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: TextField(
                  readOnly: true,
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Ожидание GPS данных",
                    hintStyle: const TextStyle(color: Color(0xFF757575), fontSize: 16),
                    prefixIcon: const Icon(
                      Icons.add_location,
                      color: Color(0xFF757575),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF757575),
                      ),
                      onPressed: () async {
                        RoutePoint? pickUpRoutePoint = await Navigator.push<RoutePoint>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RoutePointScreen(
                              isFirst: true,
                            ),
                          ),
                        );
                        if (pickUpRoutePoint != null) {
                          RoutePoint? destinationRoutePoint =
                              await Navigator.push<RoutePoint>(context, MaterialPageRoute(builder: (context) => const RoutePointScreen()));
                          if (destinationRoutePoint != null) {
                            MainApplication().curOrder.addRoutePoint(pickUpRoutePoint);
                            MainApplication().curOrder.addRoutePoint(destinationRoutePoint);
                          }
                        }
                      },
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                    fillColor: const Color(0xFFEEEEEE),
                    filled: true,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Container(
            constraints: const BoxConstraints(minWidth: double.infinity),
            alignment: Alignment.center,
            height: 60,
            width: double.infinity,
            // margin: EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: StreamBuilder(
                  stream: AppBlocs().pickUpStream,
                  builder: (context, snapshot) {
                    return MaterialButton(
                      onPressed: MapMarkersService().pickUpState == PickUpState.enabled ? _mainButtonClick : null,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
                      ),
                      splashColor: Colors.yellow[200],
                      textColor: Colors.white,
                      color: Preferences().mainColor,
                      disabledColor: Colors.grey,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: <Widget>[
                          Container(width: 40, child: const Icon(Icons.find_replace)),
                          snapshot.data == PickUpState.disabled
                              ? const Expanded(
                                  child: Text(
                                    "Извините, регион не обслуживается",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const Text(
                                  "Куда?",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                        ],
                      ),
                    );
                  }),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: 8,
          child: FloatingActionButton(
            heroTag: '_moveToCurLocation',
            backgroundColor: Colors.white,
            onPressed: () => MainApplication().curOrder.moveToCurLocation(),
            child: const Icon(
              Icons.near_me,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  void onCameraMove(CameraPosition position) {
    MapMarkersService().pickUpLocation = position.target;
    MapMarkersService().zoomLevel = position.zoom;
  }

  void onCameraIdle() {
    GeoService().geocode(MapMarkersService().pickUpLocation).then((routePoint) {
      if (routePoint != MapMarkersService().pickUpRoutePoint) {
        MapMarkersService().pickUpRoutePoint = routePoint!;
        if (routePoint.type == "street_address" || routePoint.type == "premise") {
          setText(routePoint.name);
        } else {
          setText("${routePoint.name}, ${routePoint.dsc}");
        }

        if (Preferences().geocodeMove) {
          MainApplication().mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: routePoint.getLocation(),
                    zoom: MapMarkersService().zoomLevel,
                  ),
                ),
              );
        }
      } else {
        MapMarkersService().pickUpRoutePoint.checkPickUp();
      }
    });
  }

  void _mainButtonClick() async {
    RoutePoint? routePoint = await Navigator.push<RoutePoint>(_context!, MaterialPageRoute(builder: (_context) => const RoutePointScreen()));
    if (routePoint != null) {
      MainApplication().curOrder.addRoutePoint(MapMarkersService().pickUpRoutePoint);
      MainApplication().curOrder.addRoutePoint(routePoint);
    }
  }
}
