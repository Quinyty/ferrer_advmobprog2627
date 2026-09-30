import 'package:flutter/material.dart';
// removed flutter_screenutil to avoid missing dependency; using fixed doubles instead

// models
import '../models/product.dart';

// widgets
import '../widgets/custom_text.dart';

// details screen
import 'product_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Future<List<Product>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();

  List<Product> _fallbackProducts() {
    return [
      Product(
        id: 1,
        title: 'Wireless Headphones',
        description: 'Premium wireless headphones with noise cancellation and long battery life.',
        category: 'Electronics',
        price: 129.99,
        discountPercentage: 12.0,
        rating: 4.8,
        stock: 36,
        tags: ['audio', 'wireless'],
        brand: 'SoundMax',
        sku: 'WM-1001',
        dimensions: ProductDimensions(width: 18.0, height: 8.0, depth: 20.0),
        warrantyInformation: '1 year warranty',
        shippingInformation: 'Ships in 2-3 days',
        availabilityStatus: 'In stock',
        reviews: [],
        returnPolicy: '30-day return policy',
        minimumOrderQuantity: 1,
        meta: ProductMeta(
          createdAt: '2024-01-01',
          updatedAt: '2024-01-05',
          barcode: '123456789',
          qrCode: 'QR1',
        ),
        images: ['assets/images/hw.jpg'],
        thumbnail: 'assets/images/hw.jpg',
      ),
      Product(
        id: 2,
        title: 'Smart Watch',
        description: 'A sleek smartwatch with fitness tracking, notifications, and heart-rate monitoring.',
        category: 'Wearables',
        price: 199.99,
        discountPercentage: 15.0,
        rating: 4.7,
        stock: 24,
        tags: ['watch', 'smart'],
        brand: 'PulseTech',
        sku: 'SW-2045',
        dimensions: ProductDimensions(width: 4.5, height: 1.5, depth: 1.0),
        warrantyInformation: '2 year warranty',
        shippingInformation: 'Free shipping',
        availabilityStatus: 'In stock',
        reviews: [],
        returnPolicy: '30-day return policy',
        minimumOrderQuantity: 1,
        meta: ProductMeta(
          createdAt: '2024-01-01',
          updatedAt: '2024-01-06',
          barcode: '223456789',
          qrCode: 'QR2',
        ),
        images: ['assets/images/sw.jpg'],
        thumbnail: 'assets/images/sw.jpg',
      ),
      Product(
        id: 3,
        title: 'Classic Backpack',
        description: 'Durable everyday backpack made for commuting, travel, and campus life.',
        category: 'Accessories',
        price: 79.99,
        discountPercentage: 10.0,
        rating: 4.5,
        stock: 42,
        tags: ['travel', 'bag'],
        brand: 'UrbanCarry',
        sku: 'BP-3010',
        dimensions: ProductDimensions(width: 30.0, height: 18.0, depth: 10.0),
        warrantyInformation: '6 month warranty',
        shippingInformation: 'Ships in 1-2 days',
        availabilityStatus: 'In stock',
        reviews: [],
        returnPolicy: '14-day return policy',
        minimumOrderQuantity: 1,
        meta: ProductMeta(
          createdAt: '2024-01-02',
          updatedAt: '2024-01-04',
          barcode: '323456789',
          qrCode: 'QR3',
        ),
        images: ['assets/images/cb.jpg'],
        thumbnail: 'assets/images/cb.jpg',
      ),
      Product(
        id: 4,
        title: 'Leather Wallet',
        description: 'Minimal premium wallet with multiple compartments and a slim profile.',
        category: 'Fashion',
        price: 59.99,
        discountPercentage: 8.0,
        rating: 4.4,
        stock: 18,
        tags: ['wallet', 'leather'],
        brand: 'Velour',
        sku: 'WL-4022',
        dimensions: ProductDimensions(width: 10.0, height: 9.0, depth: 2.0),
        warrantyInformation: '1 year warranty',
        shippingInformation: 'Standard delivery',
        availabilityStatus: 'In stock',
        reviews: [],
        returnPolicy: '30-day return policy',
        minimumOrderQuantity: 1,
        meta: ProductMeta(
          createdAt: '2024-01-03',
          updatedAt: '2024-01-07',
          barcode: '423456789',
          qrCode: 'QR4',
        ),
        images: ['assets/images/lw.jpg'],
        thumbnail: 'assets/images/lw.jpg',
      ),
      Product(
        id: 5,
        title: 'Running Shoes',
        description: 'Lightweight running sneakers designed for comfort and everyday performance.',
        category: 'Sports',
        price: 149.99,
        discountPercentage: 18.0,
        rating: 4.9,
        stock: 52,
        tags: ['sports', 'shoes'],
        brand: 'SprintPro',
        sku: 'RS-5011',
        dimensions: ProductDimensions(width: 30.0, height: 14.0, depth: 12.0),
        warrantyInformation: '90 day warranty',
        shippingInformation: 'Free express shipping',
        availabilityStatus: 'In stock',
        reviews: [],
        returnPolicy: '30-day return policy',
        minimumOrderQuantity: 1,
        meta: ProductMeta(
          createdAt: '2024-01-04',
          updatedAt: '2024-01-08',
          barcode: '523456789',
          qrCode: 'QR5',
        ),
        images: ['assets/images/rs.jpg'],
        thumbnail: 'assets/images/rs.jpg',
      ),
      Product(
        id: 6,
        title: 'Coffee Maker',
        description: 'Compact coffee maker for quick and delicious brews at home or in the office.',
        category: 'Home',
        price: 89.99,
        discountPercentage: 11.0,
        rating: 4.6,
        stock: 29,
        tags: ['kitchen', 'coffee'],
        brand: 'BrewCo',
        sku: 'CM-6007',
        dimensions: ProductDimensions(width: 18.0, height: 12.0, depth: 16.0),
        warrantyInformation: '1 year warranty',
        shippingInformation: 'Ships in 3-5 days',
        availabilityStatus: 'In stock',
        reviews: [],
        returnPolicy: '15-day return policy',
        minimumOrderQuantity: 1,
        meta: ProductMeta(
          createdAt: '2024-01-05',
          updatedAt: '2024-01-09',
          barcode: '623456789',
          qrCode: 'QR6',
        ),
        images: ['assets/images/cm.jpg'],
        thumbnail: 'assets/images/cm.jpg',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _productsFuture = Future.value(_fallbackProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhancement 1: Add search bar above the article list.
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error: ${snapshot.error}',
                      fontSize: 14.0,
                    ),
                  );
                }

                final allProducts = snapshot.data ?? [];
                final query = _searchController.text.trim().toLowerCase();
                final products = query.isEmpty
                    ? allProducts
                    : allProducts.where((product) {
                        final title = product.title.toLowerCase();
                        final description = product.description.toLowerCase();
                        return title.contains(query) || description.contains(query);
                      }).toList();

                if (products.isEmpty) {
                  return const Center(
                    child: CustomText(text: 'No products found.', fontSize: 14.0),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    // Enhancement 2: Add details page when clicked the card.
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.network(
                                product.thumbnail,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image, size: 24.0),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: product.title,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4.0),
                                  CustomText(
                                    text: '\$${product.price.toStringAsFixed(2)}',
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
