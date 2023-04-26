import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/main_application.dart';
import '../models/order.dart';
import '../models/preferences.dart';
import '../services/app_blocs.dart';
import '../services/map_markers_service.dart';
import 'drawer/app_drawer.dart';
import 'orders/new_order_calc_screen.dart';
import 'orders/new_order_first_point_screen.dart';
import 'orders/sliding_panel/order_sliding_panel.dart';
import 'system/system_geocde_replace_screen.dart';
import 'system/system_geocode_address_replace_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late GoogleMapController _mapController;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  MapType _currentMapType = MapType.normal;
  late Set<Marker> _markers;
  Map<PolylineId, Polyline> _polylines = {};
  late NewOrderFirstPointScreen newOrderFirstPointScreen;
  late NewOrderCalcScreen newOrderCalcScreen;

  @override
  void initState() {
    super.initState();
    _markers = MapMarkersService().markers();
    AppBlocs().mapMarkersStream?.listen((markers) {
      MapMarkersService().getMapPolyline();
      setState(() {
        _markers = markers;
      });
    });

    AppBlocs().mapPolylinesStream?.listen((polylines) {
      setState(() {
        if (polylines == null) {
          _polylines.clear();
        } else {
          _polylines = polylines;
        }
      });
    });

    newOrderFirstPointScreen = NewOrderFirstPointScreen();
    newOrderCalcScreen = NewOrderCalcScreen();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: scaffoldKey,
        resizeToAvoidBottomInset: false,
        drawer: GlobalConfiguration().getValue("tmp_drawer") ? AppDrawer() : Container(),
        drawerEnableOpenDragGesture: false,
        body: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: MainApplication().currentLocation,
                zoom: 17.0,
              ),
              onMapCreated: _onMapCreated,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: _currentMapType,
              compassEnabled: true,
              markers: _markers,
              polylines: Set<Polyline>.of(_polylines.values),
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              onTap: _onMapTap,
            ),
            Center(
              child: StreamBuilder<Object>(
                stream: AppBlocs().orderStateStream,
                builder: (context, snapshot) {
                  switch (MainApplication().curOrder.orderState) {
                    case OrderState.new_order:
                      return newOrderFirstPointScreen;
                    case OrderState.new_order_calculating:
                      newOrderCalcScreen.mapBounds();
                      return newOrderCalcScreen;
                    case OrderState.new_order_calculated:
                      return newOrderCalcScreen;
                    default:
                      return OrderSlidingPanel();
                  }
                },
              ),
            ),
            GlobalConfiguration().getValue("tmp_drawer")
                ? Positioned(
                    top: 40,
                    left: 8,
                    child: FloatingActionButton(
                      mini: true,
                      heroTag: 'openDrawer',
                      onPressed: () => scaffoldKey.currentState?.openDrawer(),
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.menu,
                        color: Colors.black,
                      ),
                    ),
                  )
                : Container(),
            Positioned(
              top: 40,
              right: 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: '_onMapTypeButtonPressed',
                onPressed: _onMapTypeButtonPressed,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.landscape,
                  color: Colors.black,
                ),
              ),
            ),
            MainApplication().curOrder.mapBoundsIcon
                ? Positioned(
                    top: 100,
                    right: 8,
                    child: FloatingActionButton(
                      mini: true,
                      heroTag: '_mapBounds',
                      onPressed: _onMapBoundsButtonPressed,
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.zoom_out_map,
                        color: Colors.black,
                      ),
                    ),
                  )
                : Container(),
            Preferences().systemMapAdmin
                ? Stack(
                    children: [
                      Positioned(
                        top: 200,
                        right: 8,
                        child: FloatingActionButton(
                          mini: true,
                          heroTag: '_mapAdminGeocodeReplace',
                          onPressed: () => Navigator.push(
                              context, MaterialPageRoute(builder: (context) => SystemGeocodeReplaceScreen(MapMarkersService().pickUpRoutePoint))),
                          backgroundColor: Colors.green,
                          child: const Icon(
                            Icons.find_replace,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 260,
                        right: 8,
                        child: FloatingActionButton(
                          mini: true,
                          heroTag: '_mapAdminGeocodeAddressReplace',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SystemGeocodeAddressReplaceScreen(
                                routePoint: MapMarkersService().pickUpRoutePoint,
                                location: MapMarkersService().pickUpLocation,
                              ),
                            ),
                          ),
                          backgroundColor: Colors.green,
                          child: const Icon(
                            Icons.fireplace,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  } // build

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    MainApplication().mapController = controller;
    if (MainApplication().curOrder.orderState == OrderState.new_order) {
      MapMarkersService().pickUpLocation = MainApplication().currentLocation;
    }
    _onCameraIdle();
    if (MainApplication().curOrder.mapBoundsIcon) {
      MainApplication().mapController?.animateCamera(CameraUpdate.newLatLngBounds(MapMarkersService().mapBounds(), Preferences().systemMapBounds));
    }
  }

  void _onCameraMove(CameraPosition position) {
    if (MainApplication().curOrder.orderState == OrderState.new_order) {
      newOrderFirstPointScreen.onCameraMove(position);
    }
  }

  void _onCameraIdle() {
    if (MainApplication().curOrder.orderState == OrderState.new_order) {
      newOrderFirstPointScreen.onCameraIdle();
    }
  }

  void _onMapTap(LatLng location) {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 17.0,
        ),
      ),
    );
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  Future<bool> _onWillPop() async {
    if (scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.pop(context);
      return false;
    }

    // Если статус заказа - идет расчёт стоимости, то ничего не делаем
    if (MainApplication().curOrder.orderState == OrderState.new_order_calculating) {
      return false;
    }
    // Если расчёт стоимости произведен, то возвращаем на новый заказ
    if (MainApplication().curOrder.orderState == OrderState.new_order_calculated) {
      newOrderCalcScreen.backPressed();
      return false;
    }

    return true;
  }

  void _onMapBoundsButtonPressed() {
    MainApplication().mapController?.animateCamera(CameraUpdate.newLatLngBounds(MapMarkersService().mapBounds(), Preferences().systemMapBounds));
  }
}
