import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class TherapistEditProfileScreen extends StatefulWidget {
  final String userId;
  const TherapistEditProfileScreen({super.key, required this.userId});

  @override
  State<TherapistEditProfileScreen> createState() => _TherapistEditProfileScreenState();
}

class _TherapistEditProfileScreenState extends State<TherapistEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _officeNameController = TextEditingController();
  final TextEditingController _officeAddressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();

  bool _isLoading = true;
  String _initials = 'S';
  String? _profilePictureUrl;
  String _selectedState = 'Select';
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _bioController.dispose();
    _officeNameController.dispose();
    _officeAddressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(Uri.parse('$apiUrl/therapist/profile/${widget.userId}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        setState(() {
          _firstNameController.text = (data['first_name'] as String?) ?? '';
          _lastNameController.text = (data['last_name'] as String?) ?? '';
          _emailController.text = (data['email'] as String?) ?? '';
          _contactNumberController.text = (data['contact_number'] as String?) ?? '';
          _bioController.text = (data['bio'] as String?) ?? '';
          _officeNameController.text = (data['office_name'] as String?) ?? '';
          _officeAddressController.text = (data['office_address'] as String?) ?? '';
          _cityController.text = (data['city'] as String?) ?? '';
          _selectedState = (data['state'] as String?) ?? 'Select';
          if (_selectedState.isEmpty) _selectedState = 'Select';
          final zip = data['zip'];
          _zipController.text = zip != null ? zip.toString() : '';
          final hourlyRate = data['hourly_rate'];
          _hourlyRateController.text = hourlyRate != null ? hourlyRate.toString() : '';
          
          _profilePictureUrl = data['profile_picture_url'] as String?;
          
          // Calculate initials
          final firstName = _firstNameController.text.trim();
          final lastName = _lastNameController.text.trim();
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            _initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
          }
          
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color.fromRGBO(66, 32, 6, 1)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color.fromRGBO(66, 32, 6, 1)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_profilePictureUrl != null || _imageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close, color: Color.fromRGBO(107, 114, 128, 1)),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _profilePictureUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _deleteImage() {
    setState(() {
      _imageBytes = null;
      _profilePictureUrl = null;
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
        
        String? imageBase64;
        if (_imageBytes != null) {
          imageBase64 = base64Encode(_imageBytes!);
        }

        final body = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'contact_number': _contactNumberController.text.trim(),
          'bio': _bioController.text.trim(),
          'office_name': _officeNameController.text.trim(),
          'office_address': _officeAddressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _selectedState != 'Select' ? _selectedState : '',
          'zip': _zipController.text.trim().isNotEmpty ? int.tryParse(_zipController.text.trim()) : null,
          'hourly_rate': _hourlyRateController.text.trim().isNotEmpty ? double.tryParse(_hourlyRateController.text.trim()) : null,
          'delete_profile_picture': _imageBytes == null && _profilePictureUrl == null,
        };

        if (imageBase64 != null) {
          body['profile_picture_base64'] = imageBase64;
        }

        final response = await http.put(
          Uri.parse('$apiUrl/therapist/profile/${widget.userId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
        }

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        } else {
          final error = jsonDecode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save: ${error['detail'] ?? 'Unknown error'}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e')),
          );
        }
      }
    }
  }

  Widget _buildAvatar() {
    Widget avatarWidget;
    
    if (_imageBytes != null) {
      avatarWidget = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFF97316),
            width: 3,
          ),
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFFED7AA),
          backgroundImage: MemoryImage(_imageBytes!),
        ),
      );
    } else if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty) {
      avatarWidget = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFF97316),
            width: 3,
          ),
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFFED7AA),
          backgroundImage: NetworkImage(_profilePictureUrl!),
        ),
      );
    } else {
      avatarWidget = _initialsCircle();
    }

    return GestureDetector(
      onTap: _showImageOptions,
      child: Stack(
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsCircle() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFED7AA),
        border: Border.all(
          color: const Color(0xFFF97316),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            fontSize: 40,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State',
          style: TextStyle(
            color: Color.fromRGBO(75, 85, 99, 1),
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
            color: Colors.white,
            border: Border.all(
              color: const Color.fromRGBO(229, 231, 235, 1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedState,
              isExpanded: true,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Color.fromRGBO(66, 32, 6, 1)),
              items: [
                'Select',
                'Johor',
                'Kedah',
                'Kelantan',
                'Kuala Lumpur',
                'Labuan',
                'Malacca',
                'Negeri Sembilan',
                'Pahang',
                'Penang',
                'Perak',
                'Perlis',
                'Putrajaya',
                'Sabah',
                'Sarawak',
                'Selangor',
                'Terengganu'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: value == 'Select' 
                        ? const Color.fromRGBO(156, 163, 175, 1)
                        : const Color.fromRGBO(66, 32, 6, 1),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedState = newValue ?? 'Select';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color.fromRGBO(75, 85, 99, 1),
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
            color: Colors.white,
            border: Border.all(
              color: const Color.fromRGBO(229, 231, 235, 1),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color.fromRGBO(156, 163, 175, 1),
                fontFamily: 'Nunito',
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: Color.fromRGBO(66, 32, 6, 1),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(66, 32, 6, 1)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color.fromRGBO(66, 32, 6, 1),
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: 375,
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildAvatar(),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _firstNameController,
                                  label: 'First Name',
                                  hintText: 'Alya',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _lastNameController,
                                  label: 'Last Name',
                                  hintText: 'Ibrahim',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'alya@domain.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(value.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _contactNumberController,
                            label: 'Contact Number',
                            hintText: '012-345 6789',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Contact number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _bioController,
                            label: 'Bio',
                            hintText: 'My goal is to provide a safe and supportive space for you to explore your thoughts and feelings.',
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bio is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _officeNameController,
                            label: 'Therapy Center Address',
                            hintText: 'e.g., 123 Jalan Ampang',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _cityController,
                                  label: 'City',
                                  hintText: 'e.g., Kuala Lumpur',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStateDropdown(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _zipController,
                            label: 'Zip Code',
                            hintText: 'e.g., 50450',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (!RegExp(r'^\d{5}$').hasMatch(value.trim())) {
                                  return 'Must be 5 digits';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _hourlyRateController,
                            label: 'Hourly Rate (RM)',
                            hintText: 'e.g., 150',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (double.tryParse(value.trim()) == null) {
                                  return 'Enter a valid number';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                              onPressed: _saveChanges,
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
