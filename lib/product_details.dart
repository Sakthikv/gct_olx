import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // For sharing

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailsPage({required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Map<String, dynamic>? owner;
  bool isLoading = true;
  int? id;
  bool isAddingToCart = false; // To track Add to Cart loading state

  @override
  void initState() {
    super.initState();

    _fetchOwnerDetails();
    _loadEmail();
  }
  Future<void> _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // _email = prefs.getString('email') ?? "";
      // _name = prefs.getString('student_name') ?? "";
      id = prefs.getInt('student_id') ?? 0;
    });
  }

  Future<void> _fetchOwnerDetails() async {
    final int studentId = widget.product['student_id'];
    final String url = "https://gctolx-api-gi75.onrender.com/getUser_by_id?student_id=$studentId";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          owner = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("Failed to load owner details: ${response.reasonPhrase}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching owner details: $e");
    }
  }
  Future<void> _addToCart() async {
    setState(() => isAddingToCart = true); // Start loading

    final url = Uri.parse("https://gctolx-api-gi75.onrender.com/addcart");

    final Map<String, dynamic> cartData = {
      "product_id": int.parse(widget.product['product_id'].toString()),
      "student_id": int.parse(widget.product['student_id'].toString()),
      "buying_student_id": id, // Replace with actual logged-in student ID
      "product_name": widget.product['product_name'].toString(),
      "product_type": widget.product['product_type'].toString(),
      "cost": int.parse(widget.product['cost'].toString()), // Ensure numeric
      "url": widget.product['url'].toString(),
    };

    print("Sending Data to Cart: $cartData"); // Debugging line

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cartData),
      );

      print("Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['message'].toString().contains('already in the cart')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This item is already in the cart!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product added to cart!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product to cart')),
        );
      }

    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product to cart')),
      );
    } finally {
      setState(() => isAddingToCart = false); // Stop loading
    }
  }


  void _shareProduct(BuildContext context) {
    final int productId = int.parse(widget.product['product_id'].toString());
    final String productName = widget.product['product_name'].toString();
    final String productCost = widget.product['cost'].toString();
    final String productLink = 'https://example.com/product/$productId';

    final String shareText =
        'Check out this product: $productName for ₹$productCost\n\nView Product: $productLink';

    print('Sharing: $shareText'); // Debugging purpose
    Share.share(shareText);
  }


  Widget _buildProductImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        alignment: Alignment.center,
        color: Colors.grey[300],
        child: Text('No Image', textAlign: TextAlign.center),
      );
    }

    try {
      Uint8List imageBytes = base64Decode(base64String);
      return Image.memory(
        imageBytes,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return Container(
        height: 250,
        width: double.infinity,
        alignment: Alignment.center,
        color: Colors.grey[300],
        child: Text('Invalid Image', textAlign: TextAlign.center),
      );
    }
  }

  void _launchWhatsApp(int phoneNumber) async {
    final Uri url = Uri.parse("https://wa.me/$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Could not open WhatsApp");
    }
  }

  void _makePhoneCall(int phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber.toString());
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print("Could not launch call");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['product_name']),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: _addToCart,
            tooltip: 'Add to Cart',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareProduct(context),
            tooltip: 'Share Product',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProductImage(widget.product['url']),
                SizedBox(height: 16),
                Text(widget.product['product_name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('₹${widget.product['cost']}', style: TextStyle(fontSize: 20, color: Colors.green)),
                SizedBox(height: 20),
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : owner != null
                    ? Column(
                  children: [
                    Text("Owner: ${owner!['student_name']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Department: ${owner!['department']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Contact: ${owner!['phone_number']} ,${id}", style: TextStyle(fontSize: 16, color: Colors.black54)),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(owner!['phone_number']),
                          icon: Icon(Icons.call),
                          label: Text("Call"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _launchWhatsApp(owner!['phone_number']),
                          icon: Icon(Icons.chat),
                          label: Text("Chat"),
                        ),
                      ],
                    ),
                  ],
                )
                    : Text("Owner details not available", style: TextStyle(fontSize: 16, color: Colors.red)),
              ],
            ),
          ),
          // Center loader when adding to cart
          if (isAddingToCart)
            Container(
              color: Colors.black.withOpacity(0.3), // Semi-transparent background
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

}
