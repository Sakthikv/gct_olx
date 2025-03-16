import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'sell_page.dart';
import 'add_cart.dart';
import 'product_details.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = "";
  String _email = "";
  int id = 0;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
    }
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SellPage()));
    }
  }

  Future<void> _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email') ?? "";
      _name = prefs.getString('student_name') ?? "";
      id = prefs.getInt('student_id') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Sell'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 30),
                      SizedBox(width: 8),
                      Text('Hello, $_name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.add_shopping_cart_outlined, size: 30),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ShopCartPage()));
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for products',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      String query = _searchController.text.trim();
                      if (query.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchPage(query: query, id1: id),
                          ),
                        );
                      }
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    sectionTitle('Categories'),
                    horizontalListView(),
                    sectionTitle('Fresh recommendations'),
                    verticalListView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Icon(Icons.arrow_forward),
        ],
      ),
    );
  }

  Widget horizontalListView() {
    List<Map<String, dynamic>> categories = [
      {'label': 'Electronics', 'icon': Icons.tv},
      {'label': 'Mobile', 'icon': Icons.smartphone},
      {'label': 'Book', 'icon': Icons.book},
      {'label': 'Clothing', 'icon': Icons.checkroom},
      {'label': 'Fashion', 'icon': Icons.shopping_bag},
    ];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(query: categories[index]['label'], id1: id)));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.grey[300], child: Icon(categories[index]['icon'], size: 30)),
                  SizedBox(height: 5),
                  Text(categories[index]['label']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget verticalListView() {
    return FutureBuilder<List>(
      future: fetchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error loading products"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No products available"));
        }

        List products = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index];
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 12),
                    _buildProductImage(product['url']),
                    SizedBox(height: 8),
                    Text(
                      product['product_name'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '₹${product['cost']}',
                      style: TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey[300],
        child: Center(
          child: Text("Invalid Image", style: TextStyle(fontSize: 12, color: Colors.red)),
        ),
      );
    }

    try {
      Uint8List imageBytes = base64Decode(base64String);
      return Image.memory(imageBytes, width: 100, height: 100, fit: BoxFit.cover);
    } catch (e) {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey[300],
        child: Center(
          child: Text("Invalid Image", style: TextStyle(fontSize: 12, color: Colors.red)),
        ),
      );
    }
  }



  Future<List> fetchProducts() async {
    final response = await http.get(Uri.parse("https://gctolx-api-gi75.onrender.com/getProducts_except_student?student_id=$id"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load products");
    }
  }
}
