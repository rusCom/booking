import 'dart:async';

import 'package:booking/data/order_state.dart';
import 'package:booking/data/route_point.dart';

class AppBlocs {
  static final AppBlocs _singleton = AppBlocs._internal();

  factory AppBlocs() {
    return _singleton;
  }

  AppBlocs._internal();

  StreamController? _pickUpController;

  Stream? get pickUpStream => pickUpController?.stream;

  StreamController? get pickUpController {
    _pickUpController ??= StreamController.broadcast();
    return _pickUpController;
  }

  StreamController? _geoAutocompleteController;

  Stream? get geoAutocompleteStream => geoAutocompleteController?.stream;

  StreamController? get geoAutocompleteController {
    _geoAutocompleteController ??= StreamController.broadcast();
    return _geoAutocompleteController;
  }

  StreamController? _geoAutocompleteAddressController;

  Stream? get geoAutocompleteAddressStream =>
      geoAutocompleteAddressController?.stream;

  StreamController? get geoAutocompleteAddressController {
    _geoAutocompleteAddressController ??= StreamController.broadcast();
    return _geoAutocompleteAddressController;
  }

  StreamController<OrderState>? _orderStateController;

  Stream<OrderState>? get orderStateStream => orderStateController?.stream;

  StreamController<OrderState>? get orderStateController {
    _orderStateController ??= StreamController<OrderState>.broadcast();
    return _orderStateController;
  }

  StreamController<List<RoutePoint>>? _orderRoutePointsController;

  Stream<List<RoutePoint>>? get orderRoutePointsStream =>
      orderRoutePointsController?.stream;

  StreamController<List<RoutePoint>>? get orderRoutePointsController {
    _orderRoutePointsController ??=
        StreamController<List<RoutePoint>>.broadcast();
    return _orderRoutePointsController;
  }

  StreamController? _newOrderWishesController;

  Stream? get newOrderWishesStream => newOrderWishesController?.stream;

  StreamController? get newOrderWishesController {
    _newOrderWishesController ??= StreamController.broadcast();
    return _newOrderWishesController;
  }

  StreamController? _newOrderTariffController; // = StreamController();
  Stream? get newOrderTariffStream => newOrderTariffController?.stream;

  StreamController? get newOrderTariffController {
    _newOrderTariffController ??= StreamController.broadcast();
    return _newOrderTariffController;
  }

  StreamController? _newOrderNoteController;

  Stream? get newOrderNoteStream => newOrderNoteController?.stream;

  StreamController? get newOrderNoteController {
    _newOrderNoteController ??= StreamController.broadcast();
    return _newOrderNoteController;
  }

  StreamController? _newOrderPaymentController; // = StreamController();
  Stream? get newOrderPaymentStream => newOrderPaymentController?.stream;

  StreamController? get newOrderPaymentController {
    _newOrderPaymentController ??= StreamController.broadcast();
    return _newOrderPaymentController;
  }

  void dispose() {
    if (_pickUpController != null) _pickUpController?.close();
    if (_geoAutocompleteController != null) _geoAutocompleteController?.close();
    if (_geoAutocompleteAddressController != null) {
      _geoAutocompleteAddressController?.close();
    }
    if (_orderStateController != null) _orderStateController?.close();
    if (_orderRoutePointsController != null) {
      _orderRoutePointsController?.close();
    }
    if (_newOrderTariffController != null) _newOrderTariffController?.close();
    if (_newOrderNoteController != null) _newOrderNoteController?.close();
    if (_newOrderPaymentController != null) _newOrderPaymentController?.close();
    if (_newOrderWishesController != null) _newOrderWishesController?.close();
  }
}
