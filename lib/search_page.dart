import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart'; // For call and WhatsApp
import 'product_details.dart'; // Import the new page

class SearchPage extends StatefulWidget {
  final String query;
  final int id1;



  SearchPage({required this.query, required this.id1});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
   // _loadEmail();
    _searchController.text = widget.query;
    _searchProduct(widget.query,widget.id1);
  }

  // Future<void> _loadEmail() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     // _email = prefs.getString('email') ?? "";
  //     // _name = prefs.getString('student_name') ?? "";
  //     id = prefs.getInt('student_id') ?? 0;
  //   });
  // }
  Future<void> _searchProduct(String query,int id1) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url =
        'https://gctolx-api-gi75.onrender.com/getProduct_by_name_or_type?search_param=${Uri.encodeComponent(query)}&student_id=${id1}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Failed to load products: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Search Results"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for products',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _searchProduct(_searchController.text.trim(),widget.id1);
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 30),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? Center(child: Text("No products found"))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsPage(product: product),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 12),
                          _buildProductImage(product['url']),
                          SizedBox(height: 8),
                          Text(product['product_name'],
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          SizedBox(height: 4),
                          Text('₹${product['cost']}',
                              style: TextStyle(fontSize: 14, color: Colors.green)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
