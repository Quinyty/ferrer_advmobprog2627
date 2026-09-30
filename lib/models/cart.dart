class Cart {
  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      products:
          (json['products'] as List?)
              ?.map((productJson) => CartProduct.fromJson(productJson))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountedTotal: (json['discountedTotal'] as num?)?.toDouble() ?? 0.0,
      userId: json['userId'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': products.map((product) => product.toJson()).toList(),
      'total': total,
      'discountedTotal': discountedTotal,
      'userId': userId,
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
    };
  }
}

class CartProduct {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedTotal;
  final String thumbnail;

  CartProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedTotal,
    required this.thumbnail,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'] ?? 0,
      name: json['title'] ?? json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      discountedTotal: (json['discountedTotal'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'total': total,
      'discountPercentage': discountPercentage,
      'discountedTotal': discountedTotal,
      'thumbnail': thumbnail,
    };
  }
}

// Discussion:
// Cart is the data model for one API cart. It stores the cart id, user id,
// products, quantities, prices, subtotal, discount, and total values.
// CartProduct represents each product inside the cart response.
//
// CartService requests JSON from DummyJSON and converts it into Cart with
// Cart.fromJson(). CartScreen displays that model. When a cart item is tapped,
// Product.fromCartProduct() adapts the small cart item into Product, so the
// same ProductDetailScreen can be reused for both shop products and cart items.
//
// This follows a simple service-model-screen pattern:
// the service handles HTTP, the model handles JSON data, and the screen handles
// rendering and user actions. CartService.cartNotifier shares add, quantity,
// and delete changes between ProductDetailScreen and CartScreen.
//
// To get one cart by its cart id, use GET /carts/{cartId}; this returns one Cart.
// To get a user's cart, use GET /carts/user/{userId}; this returns a carts list,
// so the service selects the first cart for that user.
