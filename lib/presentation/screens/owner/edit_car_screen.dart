import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/user_service.dart';
import '../../models/car.dart';
import '../../../utils/api_config.dart';

class EditCarScreen extends StatefulWidget {
  final String carId;

  const EditCarScreen({Key? key, required this.carId}) : super(key: key);

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = true;
  String? _errorMessage;
  Car? _car;
  
  // Controllers for text fields
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
  
  // Dropdown values
  String _transmission = 'AUTOMATIC';
  String _fuelType = 'PETROL';
  String _bodyType = 'SEDAN';
  
  // Checkbox values
  bool _forRent = false;
  bool _forSale = false;
  
  // Images
  File? _coverImage;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  List<String> _imagesToDelete = []; // Initialize this list
  
  @override
  void initState() {
    super.initState();
    // Fetch car details after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCarDetails();
    });
  }
  
  void _normalizeEnumValues() {
    // Ensure the enum values match exactly what's in the dropdown
    // Print current values for debugging
    print('Before normalization: $_transmission, $_fuelType, $_bodyType');
    
    // Normalize transmission
    if (_transmission != 'AUTOMATIC' && _transmission != 'MANUAL') {
      _transmission = 'AUTOMATIC'; // Default value
    }
    
    // Normalize fuel type
    if (_fuelType != 'GASOLINE' && _fuelType != 'DIESEL' && 
        _fuelType != 'ELECTRIC' && _fuelType != 'HYBRID') {
      _fuelType = 'GASOLINE'; // Default value
    }
    
    // Normalize body type
    if (_bodyType != 'SEDAN' && _bodyType != 'SUV' && 
        _bodyType != 'HATCHBACK' && _bodyType != 'COUPE' && 
        _bodyType != 'CONVERTIBLE' && _bodyType != 'PICKUP' && 
        _bodyType != 'VAN') {
      _bodyType = 'SEDAN'; // Default value
    }
    
    print('After normalization: $_transmission, $_fuelType, $_bodyType');
  }
  
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
  
  Future<void> _fetchCarDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in to edit a car';
        });
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      print('Fetching car details from: $baseUrl/api/v1/cars/${widget.carId}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/cars/${widget.carId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final carData = jsonData['data']; // Make sure we're accessing the 'data' field
        _car = Car.fromJson(carData);
        
        print('Car object: $_car');
        
        // Populate form fields with car data
        setState(() {
          _titleController.text = _car!.title;
          _descriptionController.text = _car!.description;
          _brandController.text = _car!.brand;
          _modelController.text = _car!.model;
          _yearController.text = _car!.year.toString();
          _colorController.text = _car!.color;
          _mileageController.text = _car!.mileage.toString();
          _seatCountController.text = _car!.seatCount.toString();
          _plateNumberController.text = _car!.plateNumber;
          _rentalPriceController.text = _car!.rentalPricePerDay.toString();
          _salePriceController.text = _car!.salePrice.toString();
          _cityController.text = _car!.city;
          _stateController.text = _car!.state;
          _countryController.text = _car!.country;
          _addressController.text = _car!.address;
          
          // Set form values
          _transmission = _car!.transmission;
          _fuelType = _car!.fuelType;
          _bodyType = _car!.bodyType;
          _forRent = _car!.forRent;
          _forSale = _car!.forSale;
          
          // Filter out any empty image URLs
          _existingImageUrls = _car!.imageUrls.where((url) => url.isNotEmpty).toList();
          
          // Normalize enum values to ensure they match dropdown options
          _normalizeEnumValues();
          
          _isLoading = false;
        });
        
        print('Form fields populated:');
        print('Title: ${_titleController.text}');
        print('Brand: ${_brandController.text}');
        print('Year: ${_yearController.text}');
        print('Transmission: $_transmission');
        print('Fuel Type: $_fuelType');
        print('Body Type: $_bodyType');
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _errorMessage = errorData['message'] ?? 'Failed to fetch car details';
        });
        print('Failed to fetch car details: $_errorMessage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      print('Error fetching car details: $e');
    }
  }
  
  Future<void> _pickCoverImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
      print('Cover image selected: ${pickedFile.path}');
    }
  }
  
  Future<void> _pickImages() async {
    final pickedFiles = await _imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
      });
      print('${pickedFiles.length} new images selected. Total new images: ${_newImages.length}');
    }
  }
  
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
    print('Removed new image. Remaining new images: ${_newImages.length}');
  }
  
  void _markExistingImageForDeletion(int index) {
    setState(() {
      String imageUrl = _existingImageUrls[index];
      _imagesToDelete.add(imageUrl);
      _existingImageUrls.removeAt(index);
    });
    print('Marked image for deletion. Total to delete: ${_imagesToDelete.length}');
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in as an owner to edit a car';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        return;
      }
      
      final baseUrl = ApiConfig.baseUrl;
      
      // Create multipart request
      var request = http.MultipartRequest(
        'PUT', 
        Uri.parse('$baseUrl/api/v1/cars/${widget.carId}')
      );
      
      // Add headers
      request.headers['Authorization'] = 'Bearer ${user.token}';
      
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
      
      // Add images to delete
      if (_imagesToDelete.isNotEmpty) {
        request.fields['imagesToDelete'] = jsonEncode(_imagesToDelete);
      }
      
      // Add cover image if selected
      if (_coverImage != null) {
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
      }
      
      // Add new images
      for (var i = 0; i < _newImages.length; i++) {
        var imageStream = http.ByteStream(_newImages[i].openRead());
        var imageLength = await _newImages[i].length();
        var imageMultipart = http.MultipartFile(
          'images',
          imageStream,
          imageLength,
          filename: 'image_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(imageMultipart);
      }
      
      print('Sending update request to: ${request.url}');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.length}');
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Car updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car updated successfully!')),
        );
        
        // Navigate back to car details screen with refresh flag
        Navigator.pop(context, true);
      } else {
        // Failed to update car
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to update car. Please try again.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      print('Error updating car: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
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
      appBar: AppBar(
        title: const Text('Edit Car'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 24),
                        
                        // Car Details
                        const Text(
                          'Car Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                    return 'Enter a valid year';
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
                          items: const [
                            DropdownMenuItem(value: 'AUTOMATIC', child: Text('Automatic')),
                            DropdownMenuItem(value: 'MANUAL', child: Text('Manual')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _transmission = value!;
                            });
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
                          items: const [
                            DropdownMenuItem(value: 'GASOLINE', child: Text('Gasoline')),
                            DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                            DropdownMenuItem(value: 'ELECTRIC', child: Text('Electric')),
                            DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _fuelType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Body Type
                        DropdownButtonFormField<String>(
                          value: _bodyType,
                          decoration: const InputDecoration(
                            labelText: 'Body Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'SEDAN', child: Text('Sedan')),
                            DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                            DropdownMenuItem(value: 'HATCHBACK', child: Text('Hatchback')),
                            DropdownMenuItem(value: 'COUPE', child: Text('Coupe')),
                            DropdownMenuItem(value: 'CONVERTIBLE', child: Text('Convertible')),
                            DropdownMenuItem(value: 'PICKUP', child: Text('Pickup')),
                            DropdownMenuItem(value: 'VAN', child: Text('Van')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _bodyType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Mileage and Seat Count
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
                        
                        // Pricing Section
                        const Text(
                          'Pricing',
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
                          onChanged: (value) {
                            setState(() {
                              _forRent = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        
                        // Rental Price (only if for rent is checked)
                        if (_forRent)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
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
                          onChanged: (value) {
                            setState(() {
                              _forSale = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        
                        // Sale Price (only if for sale is checked)
                        if (_forSale)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
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
                        
                        // Location Section
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // City and State
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
                        const SizedBox(height: 24),
                        
                        // Images Section
                        const Text(
                          'Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cover Image
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cover Image', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _coverImage != null
                                ? Stack(
                                    children: [
                                      Container(
                                        height: 150,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(_coverImage!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _coverImage = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : _car != null && _car!.coverImageUrl.isNotEmpty
                                    ? Stack(
                                        children: [
                                          Container(
                                            height: 150,
                                            width: double.infinity,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                _car!.coverImageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('Error loading cover image: $error');
                                                  return Container(
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child: Icon(Icons.error, size: 50, color: Colors.grey),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 5,
                                            right: 5,
                                            child: ElevatedButton.icon(
                                              onPressed: _pickCoverImage,
                                              icon: const Icon(Icons.edit),
                                              label: const Text('Change'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black.withOpacity(0.7),
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(
                                        height: 150,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: IconButton(
                                            icon: const Icon(Icons.add_photo_alternate, size: 50),
                                            onPressed: _pickCoverImage,
                                          ),
                                        ),
                                      ),
                            const SizedBox(height: 8),
                            if (_coverImage == null && (_car == null || _car!.coverImageUrl.isEmpty))
                              ElevatedButton.icon(
                                onPressed: _pickCoverImage,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Add Cover Image'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Additional Images
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Additional Images', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            
                            // Existing images
                            if (_existingImageUrls.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Current Images:'),
                                  const SizedBox(height: 8),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: _existingImageUrls.length,
                                    itemBuilder: (context, index) {
                                      final imageUrl = _existingImageUrls[index];
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder: (context, error, stackTrace) {
                                                print('Error loading image at index $index: $error');
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: const Center(
                                                    child: Icon(Icons.error, size: 30, color: Colors.grey),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                                onPressed: () => _markExistingImageForDeletion(index),
                                                constraints: const BoxConstraints(
                                                  minWidth: 30,
                                                  minHeight: 30,
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            
                            // New images
                            if (_newImages.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('New Images to Add:'),
                                  const SizedBox(height: 8),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: _newImages.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: FileImage(_newImages[index]),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 5,
                                            right: 5,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => _removeNewImage(index),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Add More Images'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update Car'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}





