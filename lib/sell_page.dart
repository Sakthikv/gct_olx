import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'package:path/path.dart' as path;

class SellPage extends StatefulWidget {
  @override
  _SellPageState createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  int id = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getInt('student_id') ?? 0;
    });
  }

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDetailsController = TextEditingController();
  final TextEditingController _productCostController = TextEditingController();
  String? _selectedCategory;
  File? _image;
  String?extension;

  final List<String> _categories = ['Electronics', 'Mobile', 'Book', 'Clothing','Fashion', 'Other'];
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length(); // Get file size in bytes

      if (fileSize > 21 * 1024) { // Check if greater than 21 KB (21 * 1024 bytes)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Image is too large. Please select an image below 21 KB.")),
        );
        return; // Stop here if image is too large
      }

      setState(() {
        _image = file;
      });
    }
  }

  String getMimeType(File imageFile) {
    String ext = path.extension(imageFile.path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream'; // Default for unknown types
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue),
              title: Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitProduct() async {
    setState(() {
      _isLoading = true;
    });

    String name = _productNameController.text.trim();
    String details = _productDetailsController.text.trim();
    String cost = _productCostController.text.trim();

    if (name.isEmpty || details.isEmpty || cost.isEmpty || _selectedCategory == null || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields and upload an image")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    String mimeType = getMimeType(_image!);
    String base64Image = base64Encode(await _image!.readAsBytes());
    String finalBase64String = "data:$mimeType;base64,$base64Image";


    // List<int> imageBytes = await _image!.readAsBytes();
    // String base64Image = base64Encode(imageBytes);//"data:image/$extension;base64,/"+

    Map<String, dynamic> productData = {
      "student_id": id,
      "product_name": name,
      "product_details": details,
      "product_type": _selectedCategory,
      "cost": cost,
      "url": finalBase64String,
    };

    try {
      final response = await http.post(
        Uri.parse("https://gctolx-api-gi75.onrender.com/addProduct"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Product submitted successfully!")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text("Sell Product"), backgroundColor: Colors.blue),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _productNameController,
                        decoration: InputDecoration(labelText: "Product Name", border: OutlineInputBorder()),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _productDetailsController,
                        decoration: InputDecoration(labelText: "Product Details", border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(labelText: "Product Type", border: OutlineInputBorder()),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _productCostController,
                        decoration: InputDecoration(labelText: "Cost", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: _image == null
                            ? Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Icon(Icons.camera_alt, size: 50, color: Colors.blue),
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_image!, height: 150, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text("Submit", style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Semi-transparent background
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white), // White loading spinner
                ),
              ),
            ),
        ],
      ),
    );
  }
}
