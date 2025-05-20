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
  String _transmission = 'AUTOMATIC';
  String _fuelType = 'GASOLINE';
  String _bodyType = 'SEDAN';
  bool _forRent = true;
  bool _forSale = false;
  
  // Images
  File? _coverImage;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  List<String> _imagesToDelete = [];
  
  @override
  void initState() {
    super.initState();
    _fetchCarDetails();
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/cars/${widget.carId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );
      
      if (response.statusCode == 200) {
        final carData = jsonDecode(response.body);
        _car = Car.fromJson(carData);
        
        // Populate form fields with car data
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
        setState(() {
          _transmission = _car!.transmission;
          _fuelType = _car!.fuelType;
          _bodyType = _car!.bodyType;
          _forRent = _car!.forRent;
          _forSale = _car!.forSale;
          _existingImageUrls = _car!.imageUrls;
          
          // Normalize enum values to ensure they match dropdown options
          _normalizeEnumValues();
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to fetch car details';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
        _newImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
      });
    }
  }
  
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }
  
  void _markExistingImageForDeletion(int index) {
    setState(() {
      _imagesToDelete.add(_existingImageUrls[index]);
      _existingImageUrls.removeAt(index);
    });
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
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/api/v1/cars/${widget.carId}'));
      
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
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseBody = response.body;
      
      if (response.statusCode == 200) {
        // Car updated successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car updated successfully!')),
        );
        
        // Navigate back to car details screen with refresh flag
        Navigator.pop(context, true);
      } else {
        // Failed to update car
        final errorData = jsonDecode(responseBody);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to update car. Please try again.';
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
          : _errorMessage != null && _car == null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Section
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
                        const SizedBox(height: 24),
                        
                        // Car Details Section
                        const Text(
                          'Car Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Brand and Model
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
                        
                        // Year and Color
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
                                labelText: 'Rental Price per Day (USD)',
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
                                labelText: 'Sale Price (USD)',
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
                            const Text('Cover Image'),
                            const SizedBox(height: 8),
                            if (_coverImage != null)
                              Stack(
                                children: [
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _coverImage!,
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
                            else if (_car != null && _car!.coverImageUrl.isNotEmpty)
                              Stack(
                                children: [
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _car!.coverImageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(child: CircularProgressIndicator());
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(child: Text('Failed to load image'));
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text('No cover image selected'),
                                ),
                              ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickCoverImage,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Select Cover Image'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Existing Images
                        if (_existingImageUrls.isNotEmpty) ...[
                          const Text('Existing Images'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _existingImageUrls.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            _existingImageUrls[index],
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(child: Text('Failed to load'));
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => _markExistingImageForDeletion(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        
                        // New Images
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Add New Images'),
                            const SizedBox(height: 8),
                            if (_newImages.isNotEmpty)
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _newImages.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 120,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                _newImages[index],
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
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Add Images'),
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








