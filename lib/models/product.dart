import 'cart.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final List<String> tags;
  final String brand;
  final String sku;
  final ProductDimensions dimensions;
  final String warrantyInformation;
  final String shippingInformation;
  final String availabilityStatus;
  final List<ProductReview> reviews;
  final String returnPolicy;
  final int minimumOrderQuantity;
  final ProductMeta meta;
  final List<String> images;
  final String thumbnail;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.tags,
    required this.brand,
    required this.sku,
    required this.dimensions,
    required this.warrantyInformation,
    required this.shippingInformation,
    required this.availabilityStatus,
    required this.reviews,
    required this.returnPolicy,
    required this.minimumOrderQuantity,
    required this.meta,
    required this.images,
    required this.thumbnail,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      price: json['price'],
      discountPercentage: json['discountPercentage'],
      rating: json['rating'],
      stock: json['stock'],
      tags: List<String>.from(json['tags']),
      brand: json['brand'],
      sku: json['sku'],
      dimensions: ProductDimensions.fromJson(json['dimensions']),
      warrantyInformation: json['warrantyInformation'],
      shippingInformation: json['shippingInformation'],
      availabilityStatus: json['availabilityStatus'],
      reviews: (json['reviews'] as List)
          .map((review) => ProductReview.fromJson(review))
          .toList(),
      returnPolicy: json['returnPolicy'],
      minimumOrderQuantity: json['minimumOrderQuantity'],
      meta: ProductMeta.fromJson(json['meta']),
      images: List<String>.from(json['images']),
      thumbnail: json['thumbnail'],
    );
  }

  // Enhancement 1: Adapt the compact cart product into the shared detail-screen model.
  factory Product.fromCartProduct(CartProduct cartProduct) {
    return Product(
      id: cartProduct.id,
      title: cartProduct.name,
      description: 'Product loaded from your cart.',
      category: 'Cart item',
      price: cartProduct.price,
      discountPercentage: cartProduct.discountPercentage,
      rating: 0,
      stock: 0,
      tags: const [],
      brand: 'DummyJSON',
      sku: 'CART-${cartProduct.id}',
      dimensions: ProductDimensions(width: 0, height: 0, depth: 0),
      warrantyInformation: 'See product listing for warranty information.',
      shippingInformation: 'See product listing for shipping information.',
      availabilityStatus: 'In cart',
      reviews: const [],
      returnPolicy: 'See product listing for return policy.',
      minimumOrderQuantity: 1,
      meta: ProductMeta(createdAt: '', updatedAt: '', barcode: '', qrCode: ''),
      images: [cartProduct.thumbnail],
      thumbnail: cartProduct.thumbnail,
    );
  }
}

class ProductDimensions {
  final double width;
  final double height;
  final double depth;

  ProductDimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  factory ProductDimensions.fromJson(Map<String, dynamic> json) {
    return ProductDimensions(
      width: json['width'],
      height: json['height'],
      depth: json['depth'],
    );
  }
}

class ProductReview {
  final double rating;
  final String comment;
  final String date;
  final String reviewerName;
  final String reviewerEmail;

  ProductReview({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      rating: json['rating'],
      comment: json['comment'],
      date: json['date'],
      reviewerName: json['reviewerName'],
      reviewerEmail: json['reviewerEmail'],
    );
  }
}

class ProductMeta {
  final String createdAt;
  final String updatedAt;
  final String barcode;
  final String qrCode;

  ProductMeta({
    required this.createdAt,
    required this.updatedAt,
    required this.barcode,
    required this.qrCode,
  });

  factory ProductMeta.fromJson(Map<String, dynamic> json) {
    return ProductMeta(
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      barcode: json['barcode'],
      qrCode: json['qrCode'],
    );
  }
}
