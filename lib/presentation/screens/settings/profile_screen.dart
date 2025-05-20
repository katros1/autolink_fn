import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../../../utils/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Form values
  String _gender = 'MALE';
  String _country = 'USA';
  DateTime _dob = DateTime(1990, 5, 15);
  String? _profilePicUrl;
  File? _profileImageFile;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You must be logged in to view your profile';
        });
        return;
      }
      
      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = ApiConfig.baseUrl;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['data'];
        
        setState(() {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phoneNumber'] ?? '';
          _gender = userData['gender'] ?? 'MALE';
          _country = userData['country'] ?? 'USA';
          _profilePicUrl = userData['profilePicUrl'];
          
          // Parse date of birth
          if (userData['dob'] != null) {
            try {
              _dob = DateTime.parse(userData['dob']);
            } catch (e) {
              // Use default date if parsing fails
            }
          }
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to load profile. Please try again.';
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
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'You must be logged in to update your profile';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        return;
      }
      
      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = ApiConfig.baseUrl;
      
      // Upload profile image if selected
      if (_profileImageFile != null) {
        await _uploadProfilePicture();
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phoneNumber': _phoneController.text,
          'gender': _gender,
          'country': _country,
          'dob': DateFormat('yyyy-MM-dd').format(_dob),
        }),
      );
      
      setState(() {
        _isSaving = false;
      });
      
      if (response.statusCode == 200) {
        // Update successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        
        // Update local user data
        final responseData = jsonDecode(response.body);
        final userData = responseData['data'];
        await UserService.updateUserInfo(userData);
        
        // Return to previous screen with refresh flag
        Navigator.pop(context, true);
      } else {
        // Update failed
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to update profile. Please try again.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _profileImageFile = File(image.path);
      });
      
      // Upload the image immediately after picking
      await _uploadProfilePicture();
    }
  }
  
  Future<void> _uploadProfilePicture() async {
    if (_profileImageFile == null) return;
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final user = await UserService.getUser();
      if (user == null || user.token == null) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'You must be logged in to update your profile picture';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
        return;
      }
      
      // For Android emulator, use 10.0.2.2 instead of localhost
      // For iOS simulator, use localhost
      final baseUrl = ApiConfig.baseUrl;
      
      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/v1/users/update-profile-picture'),
      );
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer ${user.token}';
      
      // Determine file extension and content type
      String fileName = _profileImageFile!.path.split('/').last;
      String extension = fileName.split('.').last.toLowerCase();
      String contentType = extension == 'png' ? 'image/png' : (extension == 'jpg' || extension == 'jpeg') ? 'image/jpeg' : 'image/jpeg';
      
      // Add the image file with the correct field name and content type
      var imageStream = http.ByteStream(_profileImageFile!.openRead());
      var imageLength = await _profileImageFile!.length();
      var imageMultipart = http.MultipartFile(
        'file',
        imageStream,
        imageLength,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );
      request.files.add(imageMultipart);
      
      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      setState(() {
        _isSaving = false;
      });
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['data'];
        
        // Update profile picture URL - add null check
        setState(() {
          _profilePicUrl = userData['profilePicUrl'] ?? '';
          _profileImageFile = null; // Clear the file after successful upload
        });
        
        // Update local user data
        await UserService.updateUserInfo(userData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'Failed to update profile picture. Please try again.';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
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
        title: const Text('Edit Profile'),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _updateProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _firstNameController.text.isEmpty
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile picture
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _profileImageFile != null
                                    ? FileImage(_profileImageFile!)
                                    : (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                                        ? NetworkImage(_profilePicUrl!)
                                        : null,
                                child: (_profileImageFile == null && (_profilePicUrl == null || _profilePicUrl!.isEmpty))
                                    ? const Icon(Icons.person, size: 60)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // First Name
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Last Name
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Email (read-only)
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            helperText: 'Email cannot be changed',
                          ),
                          readOnly: true,
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixText: '+',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Gender
                        DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                          ),
                          items: ['MALE', 'FEMALE', 'OTHER'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.substring(0, 1) + value.substring(1).toLowerCase()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _gender = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Country
                        DropdownButtonFormField<String>(
                          value: _country,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            border: OutlineInputBorder(),
                          ),
                          items: ['USA', 'Canada', 'UK', 'Australia', 'Rwanda'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _country = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Date of Birth
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _dob,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null && picked != _dob) {
                              setState(() {
                                _dob = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(DateFormat('MMM dd, yyyy').format(_dob)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Save button
                        if (_isSaving)
                          const Center(child: CircularProgressIndicator())
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

















