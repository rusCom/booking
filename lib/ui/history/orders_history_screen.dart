import 'package:booking/constants/style.dart';
import 'package:booking/data/order.dart';
import 'package:booking/services/rest_service.dart';
import 'package:flutter/material.dart';
import 'package:progress_indicators/progress_indicators.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  _OrdersHistoryScreenState createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  late ScrollController scrollController;
  List<Order> listOrders = [];
  late bool hasData, loading = true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController()..addListener(_scrollListener);

    RestService().httpGet("/orders/history").then((result) {
      if (result['status'] == 'OK') {
        Iterable list = result['result'];
        List<Order> loadedOrders = list.map((model) => Order.fromJson(model)).toList();
        setState(() {
          if (loadedOrders.isEmpty) {
            hasData = false;
          } else {
            listOrders.addAll(loadedOrders);
            hasData = true;
          }
          loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("История моих поездок"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                backgroundColor: mainColor,
              ),
            )
          : hasData
              ? Scrollbar(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: listOrders.length + 1,
                    itemBuilder: (context, item) {
                      if (item == listOrders.length) {
                        return Center(
                          child: JumpingDotsProgressIndicator(
                            fontSize: 20.0,
                          ),
                        );
                      }
                      return _orderWidget(listOrders[item]);
                    },
                  ),
                )
              : const Center(
                  child: Text("К сожалению, Вы у нас еще ничего не заказывали."),
                ),
    );
  }

  Widget _orderWidget(Order order) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Text(order.cost.toString()),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollListener() {
    // DebugPrint().flog("_scrollListener position = " + scrollController.position.toString());
    // DebugPrint().flog("_scrollListener positionextentAfter = " + scrollController.position.extentAfter.toString());
    // print(scrollController.position.extentAfter);
    if (scrollController.position.extentAfter < 200) {
      // DebugPrint().flog("_scrollListener at last");
    }
    /*
    if (scrollController.position.extentAfter < 500) {
      setState(() {
        items.addAll(new List.generate(42, (index) => 'Inserted $index'));
      });
    }
     */
  }
}
