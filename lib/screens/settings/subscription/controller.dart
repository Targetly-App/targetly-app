import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:targetly/services/app_service.dart';

import '../../../models/account.dart';
import '../../../services/purchese_service.dart';

class SubscriptionController extends GetxController {
  final PurchaseService purchaseService = Get.find<PurchaseService>();

  RxBool get isAvailable => purchaseService.isAvailable;

  RxList<ProductDetails> get products => purchaseService.products;

  RxBool get purchasePending => purchaseService.purchasePending;

  RxString get purchasePendingProductId =>
      purchaseService.purchasePendingProductId;

  RxBool get loading => purchaseService.isLoading;

  RxString get error => purchaseService.error;

  final AppService _appService = Get.find();

  late Account? account;

  @override
  void onInit() async {
    super.onInit();
    account = _appService.currentAccount();
  }

  void buySubscription(ProductDetails productDetails) async {
    await purchaseService.buySubscription(productDetails);
  }

  void restorePurchases() async {
    await purchaseService.restorePurchases();
  }
}
