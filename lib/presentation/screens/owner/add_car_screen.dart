import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../../../services/user_service.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _mileageController = TextEditingController();
  final _seatCountController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _rentalPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Form values
  String _transmission = 'Automatic';
  String _fuelType = 'Petrol';
  String _bodyType = 'Sedan';
  bool _forRent = true;
  bool _forSale = false;
  
  // Images
  File? _coverImage;
  List<File> _images = [];
  final _imagePicker = ImagePicker();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _mileageController.dispose();
    _seatCountController.dispose();
    _plateNumberController.dispose();
    _rentalPriceController.dispose();
    _salePriceController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _pickCoverImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((e) => File(e.path)).toList());
      });
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_coverImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cover image')),
      );
      return;
    }
    
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one additional image')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Get user token
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in as an owner to add a car';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        return;
      }
      
      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:8070' : 'http://localhost:8070';
      
      // Create car JSON object
      final carData = {
        "title": _titleController.text,
        "description": _descriptionController.text,
        "brand": _brandController.text,
        "model": _modelController.text,
        "year": int.parse(_yearController.text),
        "color": _colorController.text,
        "transmission": _transmission,
        "fuelType": _fuelType,
        "mileage": int.parse(_mileageController.text),
        "seatCount": int.parse(_seatCountController.text),
        "bodyType": _bodyType,
        "plateNumber": _plateNumberController.text,
        "forRent": _forRent,
        "forSale": _forSale,
        "rentalPricePerDay": _forRent ? double.parse(_rentalPriceController.text) : 0,
        "salePrice": _forSale ? double.parse(_salePriceController.text) : 0,
        "city": _cityController.text,
        "state": _stateController.text,
        "country": _countryController.text,
        "address": _addressController.text
      };
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/v1/cars'));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer ${user.token}';
      request.headers['Content-Type'] = 'multipart/form-data';
      
      // Add car data as individual fields
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['brand'] = _brandController.text;
      request.fields['model'] = _modelController.text;
      request.fields['year'] = _yearController.text;
      request.fields['color'] = _colorController.text;
      request.fields['transmission'] = _transmission;
      request.fields['fuelType'] = _fuelType;
      request.fields['mileage'] = _mileageController.text;
      request.fields['seatCount'] = _seatCountController.text;
      request.fields['bodyType'] = _bodyType;
      request.fields['plateNumber'] = _plateNumberController.text;
      request.fields['forRent'] = _forRent.toString();
      request.fields['forSale'] = _forSale.toString();
      request.fields['rentalPricePerDay'] = _forRent ? _rentalPriceController.text : '0';
      request.fields['salePrice'] = _forSale ? _salePriceController.text : '0';
      request.fields['city'] = _cityController.text;
      request.fields['state'] = _stateController.text;
      request.fields['country'] = _countryController.text;
      request.fields['address'] = _addressController.text;
      
      // Add cover image
      var coverImageStream = http.ByteStream(_coverImage!.openRead());
      var coverImageLength = await _coverImage!.length();
      var coverImageMultipart = http.MultipartFile(
        'coverImage',
        coverImageStream,
        coverImageLength,
        filename: 'cover_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(coverImageMultipart);
      
      // Add additional images
      for (var i = 0; i < _images.length; i++) {
        var imageStream = http.ByteStream(_images[i].openRead());
        var imageLength = await _images[i].length();
        var imageMultipart = http.MultipartFile(
          'images',
          imageStream,
          imageLength,
          filename: 'image_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(imageMultipart);
      }
      
      // Send request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      setState(() {
        _isLoading = false;
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Car added successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car added successfully!')),
        );
        
        // Navigate back to owner cars screen with refresh flag
        Navigator.pop(context, true);
      } else {
        // Failed to add car
        final errorData = jsonDecode(responseBody);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to add car. Please try again.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Car'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image
                    const Text(
                      'Cover Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _coverImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _coverImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Add Cover Image'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Additional Images
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Additional Images',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Images'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_images.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_images[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Basic Information
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Brand and Model (Row)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _brandController,
                            decoration: const InputDecoration(
                              labelText: 'Brand',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Year and Color (Row)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid year';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Color',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Transmission
                    DropdownButtonFormField<String>(
                      value: _transmission,
                      decoration: const InputDecoration(
                        labelText: 'Transmission',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Automatic', 'Manual', 'CVT'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _transmission = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Fuel Type
                    DropdownButtonFormField<String>(
                      value: _fuelType,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Petrol', 'Diesel', 'Electric', 'Hybrid'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _fuelType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Mileage and Seat Count (Row)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mileageController,
                            decoration: const InputDecoration(
                              labelText: 'Mileage (km)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _seatCountController,
                            decoration: const InputDecoration(
                              labelText: 'Seat Count',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Body Type
                    DropdownButtonFormField<String>(
                      value: _bodyType,
                      decoration: const InputDecoration(
                        labelText: 'Body Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Sedan', 'SUV', 'Hatchback', 'Coupe', 'Convertible', 'Wagon', 'Van', 'Truck'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _bodyType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Plate Number
                    TextFormField(
                      controller: _plateNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Plate Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a plate number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Listing Options
                    const Text(
                      'Listing Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // For Rent Checkbox
                    CheckboxListTile(
                      title: const Text('Available for Rent'),
                      value: _forRent,
                      onChanged: (bool? value) {
                        setState(() {
                          _forRent = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Rental Price (only if for rent is checked)
                    if (_forRent)
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0, top: 8.0, bottom: 8.0),
                        child: TextFormField(
                          controller: _rentalPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Rental Price per Day (RWF)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_forRent && (value == null || value.isEmpty)) {
                              return 'Please enter a rental price';
                            }
                            if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    
                    // For Sale Checkbox
                    CheckboxListTile(
                      title: const Text('Available for Sale'),
                      value: _forSale,
                      onChanged: (bool? value) {
                        setState(() {
                          _forSale = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Sale Price (only if for sale is checked)
                    if (_forSale)
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0, top: 8.0, bottom: 8.0),
                        child: TextFormField(
                          controller: _salePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Sale Price (RWF)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_forSale && (value == null || value.isEmpty)) {
                              return 'Please enter a sale price';
                            }
                            if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Location Information
                    const Text(
                      'Location Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // City and State (Row)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: 'State/Province',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Country
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a country';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A651),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Add Car',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    
                    // Error Message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}




