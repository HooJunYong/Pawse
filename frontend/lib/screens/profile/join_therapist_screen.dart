import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../theme/shadows.dart';
import 'therapist_verification_status_screen.dart';

class JoinTherapist extends StatefulWidget {
  final String userId;
  final bool isResubmission;
  const JoinTherapist({
    super.key,
    required this.userId,
    this.isResubmission = false,
  });

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
    'Relationships',
    'Trauma',
    'Family',
    'Self-Esteem',
    'Grief & Loss',
  ];

  // Selected languages
  final Set<String> _selectedLanguages = {};
  final List<String> _languages = ['English', 'Bahasa Melayu', 'Chinese'];

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

          // Pre-fill form if this is a resubmission
          if (widget.isResubmission) {
            _prefillForm(data);
          }

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

  void _prefillForm(Map<String, dynamic> data) {
    setState(() {
      _firstNameController.text = data['first_name'] ?? '';
      _lastNameController.text = data['last_name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _contactController.text = data['contact_number'] ?? '';
      _licenseController.text = data['license_number'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _officeNameController.text = data['office_name'] ?? '';
      _addressController.text = data['office_address'] ?? '';
      _cityController.text = data['city'] ?? '';
      _selectedState = data['state'] ?? 'Select';
      _zipController.text = data['zip']?.toString() ?? '';
      _hourlyRateController.text = data['hourly_rate']?.toString() ?? '';

      // Pre-fill specializations
      if (data['specializations'] != null) {
        _selectedSpecializations.clear();
        _selectedSpecializations.addAll(
          List<String>.from(data['specializations']),
        );
      }

      // Pre-fill languages with mapping
      if (data['languages_spoken'] != null) {
        // Changed from 'languages' to 'languages_spoken'
        _selectedLanguages.clear();
        final List<String> backendLangs = List<String>.from(
          data['languages_spoken'],
        ); // Changed here too

        // Create a normalization map for language variations
        final languageMap = {
          'english': 'English',
          'bahasa melayu': 'Bahasa Melayu',
          'bahasa': 'Bahasa Melayu',
          'malay': 'Bahasa Melayu',
          'chinese': 'Chinese',
          'mandarin': 'Chinese',
        };

        for (final backendLang in backendLangs) {
          final normalized = backendLang.toString().trim().toLowerCase();
          final mappedLang = languageMap[normalized];

          if (mappedLang != null && _languages.contains(mappedLang)) {
            _selectedLanguages.add(mappedLang);
          }
        }
      }
      // Pre-fill profile picture if exists
      if (data['profile_picture'] != null &&
          data['profile_picture'].toString().isNotEmpty) {
        try {
          _imageBytes = base64Decode(data['profile_picture']);
        } catch (e) {
          // If decoding fails, leave it empty
        }
      }
    });
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
                leading: const Icon(
                  Icons.photo_library,
                  color: Color.fromRGBO(66, 32, 6, 1),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Color.fromRGBO(66, 32, 6, 1),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteImage();
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.close,
                  color: Color.fromRGBO(107, 114, 128, 1),
                ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: const Color(0xFFF7F4F2),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF422006),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF422006),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _checkEmailExists(String email) async {
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$apiUrl/check-email-exists?email=${Uri.encodeComponent(email)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkLicenseExists(String licenseNumber) async {
    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$apiUrl/therapist/check-license?license_number=${Uri.encodeComponent(licenseNumber)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
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
    if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(_emailController.text.trim())) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }
    
    // Check email uniqueness (both user_profile and therapist_profiles collections)
    final emailExists = await _checkEmailExists(_emailController.text.trim());
    if (emailExists) {
      _showErrorDialog('This email is already registered. Please use a different email address.');
      return;
    }
    
    if (_contactController.text.isEmpty) {
      _showErrorDialog('Please enter your contact number');
      return;
    }
    
    // Malaysian phone number validation (01X-XXX XXXX or 01XXXXXXXXX)
    final cleanedContact = _contactController.text.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(cleanedContact)) {
      _showErrorDialog('Please enter a valid Malaysian contact number (e.g., 012-345 6789 or 0123456789)');
      return;
    }
    
    if (_licenseController.text.isEmpty) {
      _showErrorDialog('Please enter your license number');
      return;
    }
    
    // Check license number uniqueness (therapist_profiles collection only)
    final licenseExists = await _checkLicenseExists(_licenseController.text.trim());
    if (licenseExists) {
      _showErrorDialog('This license number is already registered. Please verify your license number.');
      return;
    }
    if (_bioController.text.isEmpty) {
      _showErrorDialog('Please enter your bio');
      return;
    }
    if (_officeNameController.text.isEmpty) {
      _showErrorDialog('Please enter your office name');
      return;
    }
    if (_addressController.text.isEmpty) {
      _showErrorDialog('Please enter your therapy center address');
      return;
    }
    if (_cityController.text.isEmpty) {
      _showErrorDialog('Please enter your city');
      return;
    }
    if (_selectedState == 'Select') {
      _showErrorDialog('Please select your state');
      return;
    }
    if (_zipController.text.isEmpty) {
      _showErrorDialog('Please enter your zip code');
      return;
    }
    if (_zipController.text.length != 5) {
      _showErrorDialog('Zip code must be exactly 5 digits');
      return;
    }
    if (!RegExp(r'^\d{5}$').hasMatch(_zipController.text)) {
      _showErrorDialog('Zip code must contain only numbers');
      return;
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
    if (_imageBytes == null) {
      _showErrorDialog('Please upload a profile picture');
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
          'office_name': _officeNameController.text,
          'office_address': _addressController.text,
          'city': _cityController.text,
          'state': _selectedState,
          'zip': int.parse(_zipController.text),
          'specializations': _selectedSpecializations.toList(),
          'languages': _selectedLanguages.toList(),
          'hourly_rate': double.tryParse(_hourlyRateController.text) ?? 0,
          if (_imageBytes != null)
            'profile_picture': base64Encode(_imageBytes!),
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: kPillShadow,
            color: Colors.white,
            border: Border.all(
              color: const Color.fromRGBO(229, 231, 235, 1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color.fromRGBO(156, 163, 175, 1),
                fontFamily: 'Nunito',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Nunito',
              color: Color.fromRGBO(66, 32, 6, 1),
            ),
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
            boxShadow: kPillShadow,
            color: Colors.white,
            border: Border.all(
              color: const Color.fromRGBO(229, 231, 235, 1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedState,
              isExpanded: true,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color.fromRGBO(66, 32, 6, 1),
              ),
              items:
                  [
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
                    'Terengganu',
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
              border: Border.all(color: const Color(0xFFF97316), width: 3),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (title == 'Specializations')
              Text(
                '${selectedItems.length}/5',
                style: TextStyle(
                  fontSize: 12,
                  color: selectedItems.length >= 5 
                    ? const Color(0xFFEF4444) 
                    : const Color.fromRGBO(107, 114, 128, 1),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            final canSelect = isSelected || selectedItems.length < 5 || title != 'Specializations';
            
            return GestureDetector(
              onTap: canSelect ? () => onToggle(item) : null,
              child: Opacity(
                opacity: canSelect ? 1.0 : 0.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromRGBO(249, 115, 22, 1)
                        : canSelect
                          ? Colors.white
                          : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color.fromRGBO(249, 115, 22, 1)
                          : canSelect
                            ? const Color.fromRGBO(229, 231, 235, 1)
                            : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      color: isSelected
                          ? Colors.white
                          : canSelect
                            ? const Color.fromRGBO(66, 32, 6, 1)
                            : Colors.grey.shade400,
                    ),
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
            icon: const Icon(
              Icons.arrow_back,
              color: Color.fromRGBO(66, 32, 6, 1),
            ),
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

    // If application exists and NOT a resubmission, show verification status screen
    // The status screen will handle showing the resubmit button for rejected applications
    if (_hasExistingApplication &&
        _existingData != null &&
        !widget.isResubmission) {
      final status = _existingData!['verification_status'] ?? 'pending';

      return TherapistVerificationStatus(
        firstName: _existingData!['first_name'] ?? '',
        lastName: _existingData!['last_name'] ?? '',
        email: _existingData!['email'] ?? '',
        userId: widget.userId,
        verificationStatus: status,
        rejectionReason: _existingData!['rejection_reason'],
      );
    }

    // Otherwise, show the application form
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
          onPressed: () {
            // If this is a resubmission and user goes back, return to status screen
            if (widget.isResubmission && _existingData != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TherapistVerificationStatus(
                    firstName: _existingData!['first_name'] ?? '',
                    lastName: _existingData!['last_name'] ?? '',
                    email: _existingData!['email'] ?? '',
                    userId: widget.userId,
                    verificationStatus:
                        _existingData!['verification_status'] ?? 'rejected',
                    rejectionReason: _existingData!['rejection_reason'],
                  ),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          widget.isResubmission
              ? 'Resubmit Application'
              : 'Join as a Therapist',
          style: const TextStyle(
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
                        Expanded(child: _buildStateDropdown()),
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
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: kButtonShadow,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
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
