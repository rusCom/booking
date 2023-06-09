import '../ui/utils/core.dart';
import 'main_application.dart';
import 'order_tariff.dart';

class PaymentType {
  final String TAG = (PaymentType).toString(); // ignore: non_constant_identifier_names
  final String type;
  String name = "";
  String choseName = "";
  String iconName = "";
  List<OrderTariff> orderTariffs = [];

  PaymentType({this.type = "", this.orderTariffs = const []}) {
    switch (type) {
      case "cash":
        name = "Наличные";
        choseName = "Наличный расчет";
        iconName = "assets/icons/ic_payment_cash.svg";
        break;
      case "corporation":
        name = "Организация";
        choseName = "За счет организации";
        iconName = "assets/icons/ic_payment_corporation.svg";
        break;
      case "sberbank":
        name = "Сбербанк";
        choseName = "Сбербанк Онлайн перевод водителю";
        iconName = "assets/icons/ic_payment_sberbank.svg";
        break;
      case "bonuses":
        name = "Бонусы";
        choseName = "Оплата бонусами";
        iconName = "assets/icons/ic_payment_bonus.svg";
        break;
    }
  }

  bool get selected {
    if (type == MainApplication().curOrder?.selectedPaymentType) return true;
    return false;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentType && runtimeType == other.runtimeType && type == other.type;

  @override
  int get hashCode => type.hashCode;

  factory PaymentType.fromJson(Map<String, dynamic> jsonData) {
    DebugPrint().log("PaymentType", "fromJson", jsonData.toString());

    List<OrderTariff> orderTariffs = [];
    if (jsonData.containsKey('tariffs')) {
      Iterable list = jsonData["tariffs"];
      orderTariffs = list.map((model) => OrderTariff.fromJson(model)).toList();
    }

    return PaymentType(
      type: jsonData['type'] ?? "",
      orderTariffs: orderTariffs,
    );
  }

  Map<String, dynamic> toJson() => {
        "type": type,
        "name": name,
        "tariffs": orderTariffs.toString(),
      };

  @override
  String toString() {
    return toJson().toString();
  }
}
