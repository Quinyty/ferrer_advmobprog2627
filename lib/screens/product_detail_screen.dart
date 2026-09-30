import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                product.thumbnail,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              product.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            _buildInfoRow('Category', product.category),
            _buildInfoRow('Brand', product.brand),
            _buildInfoRow('Rating', product.rating.toString()),
            _buildInfoRow('Stock', product.stock.toString()),
            _buildInfoRow('Warranty', product.warrantyInformation),
            const SizedBox(height: 20.0),
            //LabAct3 Enhancement 3: Send this product id and quantity to DummyJSON's add-cart endpoint.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to cart'),
                onPressed: () async {
                  try {
                    await CartService().addToCart(
                      userId: 1,
                      productId: product.id,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added to cart')),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not add product: $error')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
