import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:targetly/screens/settings/controller.dart';
import 'package:targetly/services/app_service.dart';
import 'package:targetly/services/snack_bar_service.dart';

import '../models/account.dart';

class PurchaseService extends GetxService {
  final SettingsController _settingsController = Get.find();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final List<String> _productIds = ['app.targetly.month', 'app.targetly.year'];

  final error = ''.obs;
  final isAvailable = false.obs;
  final isLoading = true.obs;
  final products = <ProductDetails>[].obs;
  final purchasePending = false.obs;
  final purchasePendingProductId = ''.obs;

  late StreamSubscription<List<PurchaseDetails>> purchaseUpdated;
  final AppService _appService = Get.find();

  @override
  void onInit() async {
    super.onInit();
    purchaseUpdated = _inAppPurchase.purchaseStream
        .listen(_listenToPurchaseUpdated, onDone: () {}, onError: (error) {
      Sentry.captureException(error);
      purchaseUpdated.cancel();
    });
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (available) {
        final ProductDetailsResponse response =
            await _inAppPurchase.queryProductDetails(_productIds.toSet());
        if (response.error != null) {
          error.value = response.error!.message;
        } else {
          var productsList = response.productDetails;
          productsList.sort((a, b) => b.price.compareTo(a.price));
          products.value = productsList;
        }
        isAvailable.value = available;
      } else {
        isAvailable.value = false;
      }
    } catch (e) {
      Sentry.captureException(e);
      error.value = 'Failed to initialize purchases';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restorePurchases() async {
    isLoading.value = true;
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('restorePurchases');
      final result = await callable.call();

      if (result.data['restored']) {
        SnackBarService.showSuccess(
            title: 'Success',
            'Your subscription has been restored successfully.');
      } else {
        SnackBarService.showInfo(
            title: 'No Subscription',
            'No active subscription found to restore.');
      }
    } catch (e) {
      Sentry.captureException(e);
      SnackBarService.showError(title: 'Error', 'Failed to restore purchases');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> buySubscription(ProductDetails productDetails) async {
    if (purchasePending.value) {
      SnackBarService.showInfo('Purchase already in progress');
      Sentry.captureMessage('Purchase already in progress',
          params: ['productId', purchasePendingProductId.value]);
      return;
    }

    try {
      isLoading.value = true;
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      Sentry.captureException(e);
      SnackBarService.showError(title: 'Error', 'Failed to initiate purchase');
      isLoading.value = false;
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      final callable = _functions.httpsCallable('verifyPurchase');
      await callable.call({
        'productId': purchase.productID,
        'receiptData': purchase.verificationData.serverVerificationData,
        'transactionId': purchase.purchaseID ?? '',
        'transactionDate': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      Sentry.captureException(e);
      return false;
    }
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchaseDetails);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _handleCanceledPurchase();
          break;
        case PurchaseStatus.error:
          _handleErrorPurchase(purchaseDetails);
          break;
      }
    }
  }

  void _handlePendingPurchase(PurchaseDetails purchase) {
    purchasePending.value = true;
    purchasePendingProductId.value = purchase.productID;
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;

    Account? user = _appService.currentAccount();
    if (user == null) {
      SnackBarService.showInfo(title: 'Error', 'Please try again later');
      return;
    }

    if (user.subscription?.productId != purchase.productID) {
      final verificationSuccess = await _verifyPurchase(purchase);
      if (verificationSuccess) {
        await _inAppPurchase.completePurchase(purchase);
        await Future.delayed(const Duration(seconds: 2));
        _settingsController.onInit();

        final message = purchase.status == PurchaseStatus.purchased
            ? 'Your purchase was successful. Thank you for your support!'
            : 'Your purchase was restored successfully.';
        SnackBarService.showSuccess(title: 'Success', message);
      } else {
        SnackBarService.showError(
            title: 'Error', 'Failed to verify subscription');
      }
    } else {
      await _inAppPurchase.completePurchase(purchase);
    }

    purchasePending.value = false;
    purchasePendingProductId.value = '';
    isLoading.value = false;
  }

  void _handleCanceledPurchase() {
    purchasePending.value = false;
    purchasePendingProductId.value = '';
    isLoading.value = false;
    SnackBarService.showInfo(
        title: 'Purchase Canceled', 'Your purchase was canceled.');
  }

  void _handleErrorPurchase(PurchaseDetails purchase) {
    final errorMsg = purchase.error?.message ?? 'An error occurred';
    error.value = errorMsg;
    isLoading.value = false;
    purchasePending.value = false;
    purchasePendingProductId.value = '';
    Sentry.captureException(purchase.error);
    SnackBarService.showError(title: 'Error', errorMsg);
  }

  @override
  void onClose() {
    purchaseUpdated.cancel();
    super.onClose();
  }
}
