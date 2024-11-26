import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

// Custom exception for account-related errors
class AccountException implements Exception {
  final String message;
  final dynamic originalError;

  AccountException(this.message, [this.originalError]);

  @override
  String toString() =>
      'AccountException: $message${originalError != null ? ' ($originalError)' : ''}';
}

// Enum for account status
enum AccountStatus { active, suspended, deleted }

// Enum for subscription status
enum SubscriptionStatus { active, expired, cancelled, none }

class Subscription {
  final String productId;
  final DateTime transactionDate;
  final SubscriptionStatus status;
  final String? transactionId;
  final String platform;
  final DateTime? expiresAt;

  Subscription({
    required this.productId,
    required this.transactionDate,
    required this.status,
    this.transactionId,
    required this.platform,
    this.expiresAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      productId: json['productId'] as String,
      transactionDate: DateTime.parse(json['transactionDate']),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
        orElse: () => SubscriptionStatus.none,
      ),
      transactionId: json['transactionId'] as String?,
      platform: json['platform'] as String,
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'transactionDate': Timestamp.fromDate(transactionDate),
        'status': status.name,
        'transactionId': transactionId,
        'platform': platform,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      };
}

class Account {
  final String id;
  final User user;
  final String? displayName;
  final String? avatarUrl;
  final Map<String, dynamic> settings;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;
  final Subscription? subscription;

  // Computed property for settings
  late final AccountSettings accountSettings;

  bool get isSubscribed {
    return subscription?.status == SubscriptionStatus.active;
  }

  SubscriptionStatus get subscriptionStatus =>
      subscription?.status ?? SubscriptionStatus.none;

  Account({
    required this.id,
    required this.user,
    this.displayName,
    this.avatarUrl,
    Map<String, dynamic>? settings,
    this.status = AccountStatus.active,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.subscription,
  })  : settings = settings ?? {},
        metadata = metadata ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    accountSettings = AccountSettings(this.settings);
  }

  // Create Account from Firebase User
  static Future<Account> fromUser(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final account = Account.fromFirestore(doc, user);
        // Initialize stream subscription for this account
        _initializeStreamForUser(user.uid);
        return account;
      }

      // Create new account if doesn't exist
      final account = Account(
        id: user.uid,
        user: user,
        displayName: user.displayName,
        avatarUrl: user.photoURL,
      );
      await account.save();
      // Initialize stream subscription for new account
      _initializeStreamForUser(user.uid);
      return account;
    } catch (e) {
      throw AccountException('Failed to create account from user', e);
    }
  }

  // Static stream controller to manage the current account stream
  static final BehaviorSubject<Account?> _currentAccountController =
      BehaviorSubject<Account?>();

  static StreamSubscription<Account?>? _currentAccountSubscription;

  // Initialize the stream for a specific user
  static void _initializeStreamForUser(String userId) {
    _currentAccountSubscription?.cancel();

    _currentAccountSubscription = FirebaseFirestore.instance
        .collection('accounts')
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return null;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return Account.fromFirestore(doc, user);
    }).listen(_currentAccountController.add, onError: (error) {
      print('Error in account stream: $error');
      _currentAccountController.addError(error);
    });
  }

  // Public method to access the stream
  static Stream<Account?> get stream => _currentAccountController.stream;

  // Clean up method - should be called when signing out
  static void dispose() {
    _currentAccountSubscription?.cancel();
    _currentAccountSubscription = null;
    _currentAccountController.add(null);
  }

  // Create Account from Firestore document
  factory Account.fromFirestore(DocumentSnapshot doc, User user) {
    final data = doc.data() as Map<String, dynamic>;
    var subscription = data['subscription'] != null
        ? Subscription.fromJson(data['subscription'])
        : null;

    return Account(
      id: doc.id,
      user: user,
      displayName: data['displayName'],
      avatarUrl: data['avatarUrl'],
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      status: AccountStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => AccountStatus.active,
      ),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      subscription: subscription,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Account to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'settings': settings,
      'status': status.name,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Save account to Firestore with optimistic locking
  Future<void> save() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('accounts').doc(id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          final existingData = doc.data() as Map<String, dynamic>;
          final existingUpdatedAt =
              (existingData['updatedAt'] as Timestamp).toDate();

          if (existingUpdatedAt.isAfter(updatedAt)) {
            throw AccountException('Account was modified by another process');
          }
        }

        transaction.set(docRef, toFirestore(), SetOptions(merge: true));
      });
    } catch (e) {
      throw AccountException('Failed to save account', e);
    }
  }

  // Update account settings
  Future<Account> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      final updatedSettings = {...settings, ...newSettings};
      final updatedAccount = copyWith(settings: updatedSettings);
      await updatedAccount.save();
      return updatedAccount;
    } catch (e) {
      throw AccountException('Failed to update settings', e);
    }
  }

  // Update account metadata
  Future<Account> updateMetadata(Map<String, dynamic> newMetadata) async {
    try {
      final updatedMetadata = {...metadata, ...newMetadata};
      final updatedAccount = copyWith(metadata: updatedMetadata);
      await updatedAccount.save();
      return updatedAccount;
    } catch (e) {
      throw AccountException('Failed to update metadata', e);
    }
  }

  // Copy with pattern for immutability
  Account copyWith({
    String? displayName,
    String? avatarUrl,
    Map<String, dynamic>? settings,
    AccountStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return Account(
      id: id,
      user: user,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Get current authenticated account
  static Future<Account?> current() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return Account.fromUser(user);
    } catch (e) {
      throw AccountException('Failed to get current account', e);
    }
  }

  // Delete account
  Future<void> delete() async {
    try {
      await FirebaseFirestore.instance.collection('accounts').doc(id).delete();
      await user.delete();
    } catch (e) {
      throw AccountException('Failed to delete account', e);
    }
  }
}

// Improved AccountSettings class with more features
class AccountSettings {
  final Map<String, dynamic> _settings;

  AccountSettings(this._settings);

  // Locale settings
  String get language => _settings['locale']?['language'] ?? 'en';
  String get region => _settings['locale']?['region'] ?? 'US';

  // Notification settings
  String get defaultNotificationsTime =>
      _settings['defaultNotificationsTime'] ?? '9:00 AM';

  bool get hideCompletedTasks => _settings['hideCompletedTasks'] ?? false;

  bool get hideAwaitingTasks => _settings['hideAwaitingTasks'] ?? false;

  int get hoursPerDayForTasks => _settings['hoursPerDayForTasks'] ?? 8;

  // Convert settings to map
  Map<String, dynamic> toMap() => _settings;

  // Create settings from default template
  static Map<String, dynamic> defaultSettings() => {
        'locale': {
          'language': 'en',
          'region': 'US',
        },
        'defaultNotificationsTime': '9:00 AM',
        'hideCompletedTasks': false,
        'hideAwaitingTasks': false,
        'hoursPerDayForTasks': 8,
      };
}
