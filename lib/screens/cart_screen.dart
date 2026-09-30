// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.userId = 1,
    this.showConfirmOrder = true,
  });

  final int userId;
  final bool showConfirmOrder;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Cart?> _cartFuture;
  Cart? _cart;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _cart = CartService.cartNotifier.value;
    _cartFuture = _cart != null
        ? Future.value(_cart)
        : CartService().getCartByUserId(widget.userId);
    CartService.cartNotifier.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartService.cartNotifier.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted && CartService.cartNotifier.value != null) {
      setState(() {
        _cart = CartService.cartNotifier.value;
        _cartFuture = Future.value(_cart);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<Cart?>(
      future: _cartFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load cart: ${snapshot.error}'));
        }

        // Enhancement 3: Keep the loaded cart in mutable state so +/- and delete can update it.
        if (_cart == null && snapshot.hasData) {
          _cart = snapshot.data;
        }
        final cart = CartService.cartNotifier.value ?? _cart ?? snapshot.data;
        if (cart == null || cart.products.isEmpty) {
          return const Center(child: Text('Your cart is empty.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            final preferredCart = CartService.cartNotifier.value ?? _cart;
            setState(() {
              _cartFuture = preferredCart != null
                  ? Future.value(preferredCart)
                  : CartService().getCartByUserId(widget.userId);
            });
            final refreshedCart = await _cartFuture;
            if (mounted && refreshedCart != null) {
              setState(() => _cart = refreshedCart);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${cart.totalQuantity} items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ...cart.products.map(
                (product) => _CartItem(
                  product: product,
                  onIncrease: () => _changeQuantity(product, 1),
                  onDecrease: () => _changeQuantity(product, -1),
                  onDelete: () => _deleteProduct(product),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: Product.fromCartProduct(product),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : const Color(0xFFEEF0F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      label: 'Subtotal',
                      value: _subtotal(cart),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      label: 'Delivery Fee',
                      value: 0,
                      isDark: isDark,
                    ),
                    const Divider(height: 24),
                    _summaryRow(
                      label: 'Total',
                      value: _discountedTotal(cart),
                      isTotal: true,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              if (widget.showConfirmOrder) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE9C52A),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Confirm Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              if (_isUpdating)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  double _subtotal(Cart cart) => cart.products.fold(
    0,
    (total, product) => total + product.price * product.quantity,
  );

  double _discount(Cart cart) => cart.products.fold(
    0,
    (total, product) =>
        total +
        (product.price * product.quantity * product.discountPercentage / 100),
  );

  double _discountedTotal(Cart cart) => _subtotal(cart) - _discount(cart);

  Widget _summaryRow({
    required String label,
    required double value,
    bool isTotal = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _changeQuantity(CartProduct product, int change) async {
    final cart = _cart;
    if (cart == null) return;

    final newQuantity = product.quantity + change;
    if (newQuantity < 1) {
      await _deleteProduct(product);
      return;
    }

    // Enhancement 3: +/- changes the item quantity and recalculates visible totals.
    final updatedProducts = cart.products
        .map(
          (item) =>
              item.id == product.id ? _withQuantity(item, newQuantity) : item,
        )
        .toList();
    await _saveProducts(cart, updatedProducts);
  }

  Future<void> _deleteProduct(CartProduct product) async {
    final cart = _cart;
    if (cart == null) return;

    // Enhancement 3: Deleting an item removes it locally and synchronizes remaining items.
    await _saveProducts(
      cart,
      cart.products.where((item) => item.id != product.id).toList(),
    );
  }

  Future<void> _saveProducts(Cart cart, List<CartProduct> products) async {
    setState(() {
      _isUpdating = true;
      _cart = _cartWithProducts(cart, products);
    });
    // Enhancement 3: Publish local edits so every cart view uses the changed items and totals.
    CartService.cartNotifier.value = _cart;
    try {
      await CartService().updateCart(cartId: cart.id, products: products);
      if (mounted) {
        final updatedCart = _cartWithProducts(cart, products);
        CartService.cartNotifier.value = updatedCart;
        setState(() => _cart = updatedCart);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cart update failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Cart _cartWithProducts(Cart cart, List<CartProduct> products) {
    final subtotal = products.fold<double>(
      0,
      (total, product) => total + product.price * product.quantity,
    );
    final discount = products.fold<double>(
      0,
      (total, product) =>
          total +
          product.price * product.quantity * product.discountPercentage / 100,
    );
    return Cart(
      id: cart.id,
      products: products,
      total: subtotal,
      discountedTotal: subtotal - discount,
      userId: cart.userId,
      totalProducts: products.length,
      totalQuantity: products.fold(0, (sum, item) => sum + item.quantity),
    );
  }

  CartProduct _withQuantity(CartProduct product, int quantity) {
    final total = product.price * quantity;
    final discountedTotal = total * (1 - product.discountPercentage / 100);
    return CartProduct(
      id: product.id,
      name: product.name,
      price: product.price,
      quantity: quantity,
      total: total,
      discountPercentage: product.discountPercentage,
      discountedTotal: discountedTotal,
      thumbnail: product.thumbnail,
    );
  }
}

class _CartItem extends StatelessWidget {
  const _CartItem({
    required this.product,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
    required this.onTap,
  });

  final CartProduct product;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(0, 0, 0, 0),
          items: [
            PopupMenuItem<void>(
              onTap: onDelete,
              child: const Text('Delete item'),
            ),
          ],
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : const Color(0xFFF5F1FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product.thumbnail,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 36),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${product.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Qty: ${product.quantity}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CompactQuantityControl(
                        quantity: product.quantity,
                        onIncrease: onIncrease,
                        onDecrease: onDecrease,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactQuantityControl extends StatelessWidget {
  const CompactQuantityControl({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Icon(
                Icons.remove,
                size: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          quantity.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onIncrease,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Icon(
                Icons.add,
                size: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
