import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

const String host = 'https://api.example.com';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$host/products'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List productJson = data['products'] ?? [];
      return productJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
}