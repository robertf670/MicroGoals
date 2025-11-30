import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class PurchaseService {
  static final PurchaseService instance = PurchaseService._init();
  PurchaseService._init();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  
  // Stream for premium status changes
  final _premiumStatusController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;
  
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (!_isAvailable) {
      Logger.warning('In-app purchase not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => Logger.error('Purchase stream error', error),
    );

    // Load products
    await loadProducts();
    
    // Restore purchases on init
    await restorePurchases();
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      const Set<String> productIds = {
        AppConstants.premiumAnnualProductId,
        AppConstants.premiumLifetimeProductId,
      };

      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        Logger.warning('Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        Logger.error('Error loading products', response.error);
        return;
      }

      _products = response.productDetails;
      Logger.info('Loaded ${_products.length} products');
    } catch (e, stack) {
      Logger.error('Failed to load products', e, stack);
    }
  }

  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      Logger.warning('In-app purchase not available');
      return false;
    }

    // Reload products if empty (in case they weren't loaded yet)
    if (_products.isEmpty) {
      Logger.info('Products not loaded, attempting to load...');
      await loadProducts();
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId. Available products: ${_products.map((p) => p.id).join(", ")}'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Check if it's a subscription or one-time purchase
      bool success;
      if (productId == AppConstants.premiumAnnualProductId) {
        // Annual is a subscription
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        // Lifetime is a one-time purchase
        success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }

      if (!success) {
        Logger.warning('Purchase failed to initiate');
        return false;
      }

      return true;
    } catch (e, stack) {
      Logger.error('Failed to purchase product: $productId', e, stack);
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _inAppPurchase.restorePurchases();
      Logger.info('Restore purchases initiated');
      
      // Check current premium status after restore
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool(AppConstants.premiumStatusKey) ?? false;
      _premiumStatusController.add(isPremium);
    } catch (e, stack) {
      Logger.error('Failed to restore purchases', e, stack);
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        Logger.info('Purchase pending: ${purchase.productID}');
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        Logger.error('Purchase error', purchase.error);
        _handlePurchaseError(purchase);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _handlePurchaseSuccess(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _handlePurchaseSuccess(PurchaseDetails purchase) async {
    try {
      final productId = purchase.productID;
      
      // Check if it's a premium product
      if (productId == AppConstants.premiumAnnualProductId ||
          productId == AppConstants.premiumLifetimeProductId) {
        // Set premium status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.premiumStatusKey, true);
        
        // Store purchase token for verification if needed
        if (purchase.purchaseID != null) {
          await prefs.setString(AppConstants.purchaseTokenKey, purchase.purchaseID!);
        }

        // Notify listeners
        _premiumStatusController.add(true);

        Logger.info('Premium activated: $productId');
      }

      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    } catch (e, stack) {
      Logger.error('Failed to handle purchase success', e, stack);
    }
  }

  void _handlePurchaseError(PurchaseDetails purchase) {
    Logger.error(
      'Purchase error: ${purchase.error?.message}',
      purchase.error,
    );
  }

  void dispose() {
    _subscription.cancel();
  }
}

