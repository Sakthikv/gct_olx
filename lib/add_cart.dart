import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'product_details.dart';
import 'dart:typed_data';

class ShopCartPage extends StatefulWidget {
  @override
  _ShopCartPageState createState() => _ShopCartPageState();
}

class _ShopCartPageState extends State<ShopCartPage> {
  List<Map<String, dynamic>> cartItems = [];
  int? id;
  bool isLoading = true; // 🔑 Loading state

  @override
  void initState() {
    super.initState();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    await _loadEmail(); // Load student_id
    await _fetchCartItems(); // Fetch data based on loaded student_id
  }
  Widget _buildProductImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        height: 100,
        width: 100,
        alignment: Alignment.center,
        color: Colors.grey[300],
        child: Text('No Image', textAlign: TextAlign.center),
      );
    }

    try {
      Uint8List imageBytes = base64Decode(base64String);
      return Image.memory(
        imageBytes,
        height: 100,
        width: 100,
        fit: BoxFit.cover,
      );
    } catch (e) {
      print("Error decoding base64: $e");
      return Container(
        height: 100,
        width: 100,
        alignment: Alignment.center,
        color: Colors.grey[300],
        child: Text('Invalid Image', textAlign: TextAlign.center),
      );
    }
  }
  Future<void> _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    id = prefs.getInt('student_id') ?? 0;
  }

  Future<void> _fetchCartItems() async {
    final url = Uri.parse(
        "https://gctolx-api-gi75.onrender.com/getProduct_by_buying_student_id?buying_student_id_id=$id");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          cartItems = data.map((item) {
            return {
              "buying_id": item["buying_id"],
              "product_name": item["product_name"],
              "cost": item["cost"],
              "url": item["url"], // Assuming API returns an image URL
              "isFavorite": true, // Default as favorite (in cart)
            };
          }).toList();
          isLoading = false; // ✅ Stop loading
        });
      } else {
        print("Failed to load products");
        setState(() {
          isLoading = false; // ✅ Stop loading on error
        });
      }
    } catch (e) {
      print("Error fetching cart items: $e");
      setState(() {
        isLoading = false; // ✅ Stop loading on error
      });
    }
  }

  void _toggleFavorite(int index) async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    if (cartItems[index]["isFavorite"]) {
      // If item is currently favorite (in cart), proceed to delete
      int buyingId = cartItems[index]["buying_id"];
      final url = Uri.parse('https://gctolx-api-gi75.onrender.com/deleteProduct_by_buying_id?buying_id=$buyingId');

      try {
        final response = await http.delete(url); // ✅ DELETE request

        Navigator.of(context).pop(); // ❌ Remove loading dialog once done

        if (response.statusCode == 200) {
          // Success - remove item from cart
          setState(() {
            cartItems.removeAt(index);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product removed from cart.')),
          );
        } else {
          // Failed to delete
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove product. Try again.')),
          );
        }
      } catch (e) {
        Navigator.of(context).pop(); // ❌ Remove loading dialog on error
        print("Error deleting product: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred. Please check your connection.')),
        );
      }
    }
  }


  int _calculateTotal() {
    return cartItems.fold(0, (sum, item) => sum + int.parse(item['cost'].toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shopping Cart")),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 🔄 Show loading until data comes
          : cartItems.isEmpty
          ? Center(child: Text("Your cart is empty!"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                var item = cartItems[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(product: item),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      leading: _buildProductImage(item['url']),
                      title: Text(item['product_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("₹${item['cost']}", style: TextStyle(color: Colors.green)),
                      trailing: IconButton(
                        icon: Icon(
                          item["isFavorite"] ? Icons.favorite : Icons.favorite_border,
                          color: item["isFavorite"] ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _toggleFavorite(index),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Total: ₹${_calculateTotal()}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 10),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
