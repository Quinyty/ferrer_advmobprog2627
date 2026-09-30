import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cart.dart';
import '../constants.dart';

class CartService {
  // Shared state lets the detail screen publish additions to the cart screen immediately.
  static final ValueNotifier<Cart?> cartNotifier = ValueNotifier<Cart?>(null);

  // Discussion: GET /carts/{cartId} returns one cart when the cart id is known.
  Future<Cart> getCartById(int cartId) async {
    final response = await http.get(Uri.parse('$host/carts/$cartId'));

    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception('Failed to load cart $cartId');
  }

  // Enhancement 3: Fetch only the first cart belonging to the requested user.
  Future<Cart?> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final carts = (data['carts'] as List?) ?? [];
      final cart = carts.isEmpty
          ? null
          : Cart.fromJson(carts.first as Map<String, dynamic>);

      return cart;
    }

    throw Exception('Failed to load cart for user $userId');
  }

  //LabAct3 Enhancement 3: Submit product ids and quantities using DummyJSON's add-cart contract.
  Future<Cart> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final existingCart = cartNotifier.value ?? await getCartByUserId(userId);

    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final addedCart = Cart.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      final List<CartProduct> mergedProducts = List<CartProduct>.from(
        existingCart?.products ?? const <CartProduct>[],
      );

      for (final addedProduct in addedCart.products) {
        final index = mergedProducts.indexWhere(
          (existingProduct) => existingProduct.id == addedProduct.id,
        );

        if (index == -1) {
          mergedProducts.add(addedProduct);
        } else {
          mergedProducts[index] = _withQuantity(
            mergedProducts[index],
            mergedProducts[index].quantity + addedProduct.quantity,
          );
        }
      }

      final mergedCart = _recalculate(existingCart ?? addedCart, mergedProducts);
      cartNotifier.value = mergedCart;
      return mergedCart;
    }

    throw Exception('Failed to add product to cart');
  }

  Cart _recalculate(Cart cart, List<CartProduct> products) {
    final total = products.fold<double>(
      0,
      (sum, product) => sum + product.price * product.quantity,
    );
    final discount = products.fold<double>(
      0,
      (sum, product) =>
          sum +
          product.price * product.quantity * product.discountPercentage / 100,
    );
    return Cart(
      id: cart.id,
      products: products,
      total: total,
      discountedTotal: total - discount,
      userId: cart.userId,
      totalProducts: products.length,
      totalQuantity: products.fold(0, (sum, product) => sum + product.quantity),
    );
  }

  CartProduct _withQuantity(CartProduct product, int quantity) {
    final total = product.price * quantity;
    return CartProduct(
      id: product.id,
      name: product.name,
      price: product.price,
      quantity: quantity,
      total: total,
      discountPercentage: product.discountPercentage,
      discountedTotal: total * (1 - product.discountPercentage / 100),
      thumbnail: product.thumbnail,
    );
  }

  // Enhancement 3: DummyJSON uses PUT/PATCH to replace or merge the cart products.
  Future<Cart> updateCart({
    required int cartId,
    required List<CartProduct> products,
  }) async {
    final response = await http.put(
      Uri.parse('$host/carts/$cartId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'merge': false,
        'products': products
            .map((product) => {'id': product.id, 'quantity': product.quantity})
            .toList(),
      }),
    );

    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception('Failed to update cart');
  }

  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }
}
