import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import 'app_service.dart';

class RemoteFunctionsService extends GetxService {
  final AppService _appService = Get.find<AppService>();

  Future call(String functionName, Map<String, dynamic> data) async {
    if (!_appService.isOnline()) {
      throw RemoteExecutionException('No internet connection');
    }

    try {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable(functionName);

      var response = await callable.call(data);

      return response.data;
    } catch (e) {
      print(e);
      throw RemoteExecutionException(e.toString());
    }
  }
}

class RemoteExecutionException implements Exception {
  final String message;

  RemoteExecutionException(this.message);
}
