import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'therapist_verification_status_screen.dart';

class JoinTherapist extends StatefulWidget {
  final String userId;
  const JoinTherapist({super.key, required this.userId});

  @override
  State<JoinTherapist> createState() => _JoinTherapistState();
}

class _JoinTherapistState extends State<JoinTherapist> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _officeNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String _selectedState = 'Select';
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();

  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // Selected specializations
  final Set<String> _selectedSpecializations = {};
  final List<String> _specializations = [
    'Anxiety',
    'Depression',
    'Stress',
    'Trauma',
    'Relationships',
    'Grief',
  ];

  // Selected languages
  final Set<String> _selectedLanguages = {};
  final List<String> _languages = [
    'English',
    'Bahasa Melayu',
    'Chinese',
  ];

  bool _isLoading = true;
  bool _hasExistingApplication = false;
  Map<String, dynamic>? _existingData;

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$apiUrl/therapist/profile/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        // Application exists
        final data = jsonDecode(response.body);
        setState(() {
          _hasExistingApplication = true;
          _existingData = data;
          _isLoading = false;
        });
      } else {
        // No application found
        setState(() {
          _hasExistingApplication = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      // No application or error
      setState(() {
        _hasExistingApplication = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _licenseController.dispose();
    _bioController.dispose();
    _officeNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
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
              if (_imageBytes != null)
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
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromRGBO(249, 115, 22, 1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitApplication() async {
    // Validation
    if (_firstNameController.text.isEmpty) {
      _showErrorDialog('Please enter your first name');
      return;
    }
    if (_lastNameController.text.isEmpty) {
      _showErrorDialog('Please enter your last name');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Please enter your official email');
      return;
    }
    if (_contactController.text.isEmpty) {
      _showErrorDialog('Please enter your contact number');
      return;
    }
    if (_licenseController.text.isEmpty) {
      _showErrorDialog('Please enter your license number');
      return;
    }
    if (_bioController.text.isEmpty) {
      _showErrorDialog('Please enter your bio');
      return;
    }
    if (_zipController.text.isNotEmpty) {
      if (_zipController.text.length != 5) {
        _showErrorDialog('Zip code must be exactly 5 digits');
        return;
      }
      if (!RegExp(r'^\d{5}$').hasMatch(_zipController.text)) {
        _showErrorDialog('Zip code must contain only numbers');
        return;
      }
    }
    if (_selectedSpecializations.isEmpty) {
      _showErrorDialog('Please select at least one specialization');
      return;
    }
    if (_selectedLanguages.isEmpty) {
      _showErrorDialog('Please select at least one language');
      return;
    }
    if (_hourlyRateController.text.isEmpty) {
      _showErrorDialog('Please enter your hourly rate');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$apiUrl/therapist/application'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'email': _emailController.text,
          'contact_number': _contactController.text,
          'license_number': _licenseController.text,
          'bio': _bioController.text,
          'office_name': _officeNameController.text.isNotEmpty ? _officeNameController.text : null,
          'office_address': _addressController.text.isNotEmpty ? _addressController.text : null,
          'city': _cityController.text.isNotEmpty ? _cityController.text : null,
          'state': _selectedState != 'Select' ? _selectedState : null,
          'zip': _zipController.text.isNotEmpty ? int.tryParse(_zipController.text) : null,
          'specializations': _selectedSpecializations.toList(),
          'languages': _selectedLanguages.toList(),
          'hourly_rate': double.tryParse(_hourlyRateController.text) ?? 0,
          if (_imageBytes != null) 'profile_picture': base64Encode(_imageBytes!),
        }),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Navigate to verification status screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TherapistVerificationStatus(
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                email: _emailController.text,
                userId: widget.userId,
              ),
            ),
          );
        } else {
          final error = jsonDecode(response.body);
          _showErrorDialog(error['detail'] ?? 'Failed to submit application');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog('Error: $e');
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: Color.fromRGBO(156, 163, 175, 1),
              fontFamily: 'Nunito',
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromRGBO(229, 231, 235, 1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromRGBO(229, 231, 235, 1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromRGBO(249, 115, 22, 1)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Nunito',
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(66, 32, 6, 1),
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

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _showImageOptions,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFED7AA),
              border: Border.all(
                color: const Color(0xFFF97316),
                width: 3,
              ),
            ),
            child: _imageBytes != null
                ? ClipOval(
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: 96,
                      height: 96,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 48,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(249, 115, 22, 1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSection({
    required String title,
    required List<String> items,
    required Set<String> selectedItems,
    required Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return GestureDetector(
              onTap: () => onToggle(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color.fromRGBO(249, 115, 22, 1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color.fromRGBO(249, 115, 22, 1)
                        : const Color.fromRGBO(229, 231, 235, 1),
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: isSelected ? Colors.white : const Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(66, 32, 6, 1)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Join as a Therapist',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(66, 32, 6, 1),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(249, 115, 22, 1),
          ),
        ),
      );
    }

    // If application exists and NOT rejected, show verification status screen
    // If rejected, user can resubmit by seeing the form
    if (_hasExistingApplication && _existingData != null) {
      final status = _existingData!['verification_status'] ?? 'pending';
      
      // Show status screen only for pending or approved applications
      if (status == 'pending' || status == 'approved') {
        return TherapistVerificationStatus(
          firstName: _existingData!['first_name'] ?? '',
          lastName: _existingData!['last_name'] ?? '',
          email: _existingData!['email'] ?? '',
          userId: widget.userId,
          verificationStatus: status,
          rejectionReason: _existingData!['rejection_reason'],
        );
      }
      // For rejected status, continue to show the form below for resubmission
    }

    // Otherwise, show the application form
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(66, 32, 6, 1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join as a Therapist',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 375,
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload Profile Picture',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Nunito',
                        color: Color.fromRGBO(107, 114, 128, 1),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'First Name',
                            controller: _firstNameController,
                            placeholder: 'e.g., Alya',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            placeholder: 'e.g., Ibrahim',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Official Email',
                      controller: _emailController,
                      placeholder: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Contact Number',
                      controller: _contactController,
                      placeholder: 'e.g., 012-345 6789',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'License Number',
                      controller: _licenseController,
                      placeholder: 'e.g., LAW-01234',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Bio',
                      controller: _bioController,
                      placeholder: 'Tell us a bit about your approach...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Office Name',
                      controller: _officeNameController,
                      placeholder: 'e.g., Mindful Therapy Center',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Therapy Center Address',
                      controller: _addressController,
                      placeholder: 'e.g., 123 Jalan Damai',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'City',
                            controller: _cityController,
                            placeholder: 'e.g., Kuala Lumpur',
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
                      label: 'Zip Code',
                      controller: _zipController,
                      placeholder: 'e.g., 50450',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    _buildChipSection(
                      title: 'Specializations',
                      items: _specializations,
                      selectedItems: _selectedSpecializations,
                      onToggle: (item) {
                        setState(() {
                          if (_selectedSpecializations.contains(item)) {
                            _selectedSpecializations.remove(item);
                          } else {
                            _selectedSpecializations.add(item);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildChipSection(
                      title: 'Languages Spoken',
                      items: _languages,
                      selectedItems: _selectedLanguages,
                      onToggle: (item) {
                        setState(() {
                          if (_selectedLanguages.contains(item)) {
                            _selectedLanguages.remove(item);
                          } else {
                            _selectedLanguages.add(item);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Hourly Rate (RM)',
                      controller: _hourlyRateController,
                      placeholder: 'e.g., 150',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        onPressed: _submitApplication,
                        child: const Text(
                          'Submit for Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
