import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:targetly/app_routes.dart';
import 'package:targetly/service_binding.dart';
import 'package:targetly/services/local_notification_service.dart';
import 'package:targetly/services/snack_bar_service.dart';
import 'package:targetly/services/tasks_service.dart';

import '../errors.dart';
import '../models/account.dart';
import '../models/task.dart';
import '../utils.dart';

class AppService extends GetxService {
  static AppService get to => Get.find();
  static TasksService get _tasksService => Get.find();
  static LocalNotificationService get _localNotificationService => Get.find();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  // Observable states
  final Rx<Account?> currentAccount = Rx<Account?>(null);
  final RxBool isInitialized = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isOnline = false.obs;

  // Stream subscriptions
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  CollectionReference get _targetsRef => _firestore.collection('targets');
  CollectionReference get _tasksRef => _firestore.collection('tasks');
  CollectionReference get _chatMessagesRef =>
      _firestore.collection('chatMessages');

  @override
  void onInit() async {
    super.onInit();
    _initializeAuthStateListener();
    _initializeConnectivityListener();
    await initializeLocalNotifications();
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    _connectivitySubscription?.cancel();
    Account.dispose();
    super.onClose();
  }

  Future<AppService> init() async {
    try {
      isLoading.value = true;

      // Set appropriate settings for each platform
      if (kIsWeb) {
        _firestore.settings = const Settings(
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          persistenceEnabled: true,
          sslEnabled: true,
        );
      } else if (Platform.isIOS || Platform.isAndroid) {
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } else {
        // For other platforms, use default settings
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      if (_auth.currentUser != null) {
        currentAccount.value = await Account.fromUser(_auth.currentUser!);
      }

      isInitialized.value = true;
      return this;
    } catch (e) {
      print('Error initializing AppService: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  void _initializeAuthStateListener() {
    _authStateSubscription =
        _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Initialize the account and its stream
        currentAccount.value = await Account.fromUser(user);
      } else if (currentAccount.value != null) {
        // logout
        await signOut();
      }
    });
  }

  void _initializeConnectivityListener() async {
    isOnline.value = await _checkConnectivity();

    if (!isOnline.value) {
      _handleConnectivityChange(isOnline.value);
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      isOnline.value = !result.contains(ConnectivityResult.none);
      _handleConnectivityChange(isOnline.value);
    });
  }

  Future<void> initializeLocalNotifications() async {
    // This class will getting all tasks that was planned and update scheduled notifications
    var planned = await _tasksRef
        .where('uid', isEqualTo: currentAccount.value!.id)
        .where('status', isEqualTo: [
      TaskStatus.planned.name,
      TaskStatus.completed.name
    ]).get();

    await _firestore.runTransaction((transaction) async {
      final batch = _firestore.batch();
      for (var task in planned.docs) {
        final updatedTask = Task.fromFirestore(task);
        await _localNotificationService.updateTaskNotification(updatedTask);
        batch.update(task.reference, updatedTask.toFirestore());
      }
      await batch.commit();
    });
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  void _handleConnectivityChange(bool isOnline) {
    if (!isOnline) {
      SnackBarService.showError(
        'You are currently offline. Some features may be limited.',
      );
    } else {
      SnackBarService.showInfo('Your connection has been restored.');
    }
  }

  Future<Account?> signIn(String email, String password) async {
    try {
      isLoading.value = true;

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final account = await Account.fromUser(userCredential.user!);
        await _updateUserLoginInfo(account);
        return account;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Account?> signInWithGoogle() async {
    try {
      isLoading.value = true;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        // TODO: https://developers.google.com/identity/protocols/googlescopes
        scopes: [
          'email',
          'https://www.googleapis.com/auth/contacts.readonly',
        ],
        serverClientId:
            '1097175702254-an197g52kpilm2cl4qbtn52rr76j11fi.apps.googleusercontent.com',
      );

      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final account = await Account.fromUser(userCredential.user!);
        await _updateUserLoginInfo(account);
        return account;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Account?> signInWithApple() async {
    try {
      isLoading.value = true;

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        final account = await Account.fromUser(userCredential.user!);
        await _updateUserProfileFromApple(account, appleCredential);
        await _updateUserLoginInfo(account);
        return account;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      print('Error signing in with Apple: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateUserProfileFromApple(
      Account account, AuthorizationCredentialAppleID credential) async {
    if (credential.givenName != null && credential.familyName != null) {
      final updatedAccount = await account.updateMetadata({
        'firstName': credential.givenName,
        'lastName': credential.familyName,
        'email': credential.email,
      });
      currentAccount.value = updatedAccount;
    }
  }

  Future<void> _updateUserLoginInfo(Account account) async {
    final deviceId = await getDeviceIdentifier();
    final updatedAccount = await account.updateMetadata({
      'deviceIds': FieldValue.arrayUnion([deviceId]),
      'lastLoginDevice': deviceId,
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
    currentAccount.value = updatedAccount;
  }

  Future<Account?> registerUser(String email, String password) async {
    try {
      isLoading.value = true;

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final account = await Account.fromUser(userCredential.user!);
        await account.updateMetadata({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _updateUserLoginInfo(account);
        return account;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;

      await GoogleSignIn().signOut();
      await _auth.signOut();
      currentAccount.value = null;

      Get.offAllNamed(AppRoutes.signIn);
      Get.reloadAll(force: true);
      ServiceBinding().dependencies();
    } catch (e) {
      print('Error signing out: $e');
      throw AppError('Failed to sign out. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updatePurchase(PurchaseDetails purchaseDetails) async {
    try {
      if (currentAccount.value == null) return false;

      final batch = _firestore.batch();

      final purchaseRef = _firestore.collection('purchases').doc();
      batch.set(purchaseRef, {
        'uid': currentAccount.value!.id,
        'receiptData': purchaseDetails.verificationData.serverVerificationData,
        'productId': purchaseDetails.productID,
        'purchaseId': purchaseDetails.purchaseID,
        'transactionDate': purchaseDetails.transactionDate,
        'platform': GetPlatform.isIOS ? 'ios' : 'android',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await currentAccount.value!.updateMetadata({
        'subscriptionStatus': 'active',
        'productId': purchaseDetails.productID,
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error updating purchase: $e');
      return false;
    }
  }

  Future<void> cleanAccountData() async {
    try {
      isLoading.value = true;
      if (currentAccount.value == null) return;

      // Remove all data from user
      final batch = _firestore.batch();
      final tasks = await _tasksRef
          .where('uid', isEqualTo: currentAccount.value!.id)
          .get();
      for (var task in tasks.docs) {
        batch.delete(task.reference);
      }
      final targets = await _targetsRef
          .where('uid', isEqualTo: currentAccount.value!.id)
          .get();
      for (var target in targets.docs) {
        batch.delete(target.reference);
      }
      final chatMessages = await _chatMessagesRef
          .where('uid', isEqualTo: currentAccount.value!.id)
          .get();
      for (var chatMessage in chatMessages.docs) {
        batch.delete(chatMessage.reference);
      }

      await currentAccount.value!.delete();
      await batch.commit();
      await signOut();
    } catch (e) {
      print('Error cleaning account data: $e');
      throw AppError('Failed to clean account data. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email,
        // Optional: Configure action code settings
        // actionCodeSettings: ActionCodeSettings(
        //   url: 'https://your-app.com/reset-password',
        //   androidPackageName: 'com.example.app',
        //   iOSBundleId: 'com.example.app',
        //   handleCodeInApp: true,
        // ),
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw 'The email address is not valid.';
        case 'user-not-found':
          throw 'No user found for this email address.';
        case 'too-many-requests':
          throw 'Too many attempts. Please try again later.';
        default:
          throw 'An error occurred. Please try again later.';
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        message = 'Email is already registered.';
        break;
      case 'invalid-email':
        message = 'Invalid email address.';
        break;
      case 'operation-not-allowed':
        message = 'Operation not allowed.';
        break;
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'invalid-credential':
        message = 'E-mail or password is incorrect.';
        break;
      default:
        message = e.message ?? 'An unknown error occurred.';
    }
    throw AuthError(message);
  }
}
