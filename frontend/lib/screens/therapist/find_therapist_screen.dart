import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_conversation.dart';
import '../../models/therapist_model.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../../services/therapist_service.dart';
import '../../widgets/crisis_banner.dart';
import '../../widgets/therapist_card.dart';
import '../chat/chat_contacts_screen.dart';

class FindTherapistScreen extends StatefulWidget {
  final String userId;

  const FindTherapistScreen({super.key, required this.userId});

  @override
  State<FindTherapistScreen> createState() => _FindTherapistScreenState();
}

class _FindTherapistScreenState extends State<FindTherapistScreen> {
  final TherapistService _apiService = TherapistService();
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();
  late Future<List<Therapist>> _therapistsFuture;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  PendingRatingSession? _pendingRating;
  int _selectedRating = 0;
  bool _isSubmittingRating = false;
  final DateFormat _sessionFormatter = DateFormat('MMM d, h:mm a');
  int _unreadMessageCount = 0;
  
  // Filter state
  Set<String> _selectedSpecializations = {};
  Set<String> _selectedLanguages = {};
  Set<String> _selectedStates = {};
  double? _minRate;
  double? _maxRate;

  @override
  void initState() {
    super.initState();
    _therapistsFuture = _apiService.getTherapists();
    _loadPendingRating();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchTherapists(String query) {
    setState(() {
      final trimmedQuery = query.trim();
      _therapistsFuture = _apiService.getTherapists(
        searchQuery: trimmedQuery.isEmpty ? null : trimmedQuery,
      );
    });
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // If query is empty or has 1+ characters, search after debounce
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchTherapists(query);
    });
  }

  List<Therapist> _applyFilters(List<Therapist> therapists) {
    return therapists.where((therapist) {
      // Filter by specializations
      if (_selectedSpecializations.isNotEmpty) {
        final hasMatchingSpec = _selectedSpecializations.any(
          (spec) => therapist.specialties.toLowerCase().contains(spec.toLowerCase()),
        );
        if (!hasMatchingSpec) return false;
      }

      // Filter by languages
      if (_selectedLanguages.isNotEmpty) {
        final hasMatchingLang = _selectedLanguages.any(
          (lang) => therapist.languages.toLowerCase().contains(lang.toLowerCase()),
        );
        if (!hasMatchingLang) return false;
      }

      // Filter by state
      if (_selectedStates.isNotEmpty) {
        final hasMatchingState = _selectedStates.any(
          (state) => therapist.location.toLowerCase() == state.toLowerCase(),
        );
        if (!hasMatchingState) return false;
      }

      // Filter by hourly rate
      if (_minRate != null && therapist.price < _minRate!) {
        return false;
      }
      if (_maxRate != null && therapist.price > _maxRate!) {
        return false;
      }

      return true;
    }).toList();
  }

  void _showFilterBottomSheet() {
    // Temporary filter state
    Set<String> tempSpecializations = Set.from(_selectedSpecializations);
    Set<String> tempLanguages = Set.from(_selectedLanguages);
    Set<String> tempStates = Set.from(_selectedStates);
    double? tempMinRate = _minRate;
    double? tempMaxRate = _maxRate;
    
    // Controllers for text fields
    final minRateController = TextEditingController(text: tempMinRate?.toString() ?? '');
    final maxRateController = TextEditingController(text: tempMaxRate?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFFFDFCF8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Therapists',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempSpecializations.clear();
                            tempLanguages.clear();
                            tempStates.clear();
                            tempMinRate = null;
                            tempMaxRate = null;
                            minRateController.clear();
                            maxRateController.clear();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
                
                // Filter Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Specializations
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Specializations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                            Text(
                              '${tempSpecializations.length}/3',
                              style: TextStyle(
                                fontSize: 12,
                                color: tempSpecializations.length >= 3 
                                  ? const Color(0xFFEF4444) 
                                  : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Anxiety', 'Depression', 'Stress', 'Relationships', 'Trauma', 'Family', 'Self-Esteem', 'Grief & Loss'].map((spec) {
                            final isSelected = tempSpecializations.contains(spec);
                            final canSelect = isSelected || tempSpecializations.length < 3;
                            return FilterChip(
                              label: Text(spec),
                              selected: isSelected,
                              onSelected: canSelect ? (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempSpecializations.add(spec);
                                  } else {
                                    tempSpecializations.remove(spec);
                                  }
                                });
                              } : null,
                              selectedColor: const Color(0xFFFB923C),
                              backgroundColor: Colors.white,
                              disabledColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color: !canSelect
                                  ? Colors.grey.shade400
                                  : isSelected 
                                    ? Colors.white 
                                    : const Color(0xFF3E2723),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: !canSelect
                                  ? Colors.grey.shade300
                                  : isSelected 
                                    ? const Color(0xFFFB923C) 
                                    : Colors.grey.shade300,
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Languages
                        const Text(
                          'Languages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['English', 'Bahasa Melayu', 'Chinese'].map((lang) {
                            final isSelected = tempLanguages.contains(lang);
                            return FilterChip(
                              label: Text(lang),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempLanguages.add(lang);
                                  } else {
                                    tempLanguages.remove(lang);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFFFB923C),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF3E2723),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFFFB923C) : Colors.grey.shade300,
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // State
                        const Text(
                          'State',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
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
                          ].map((state) {
                            final isSelected = tempStates.contains(state);
                            return FilterChip(
                              label: Text(state),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    tempStates.add(state);
                                  } else {
                                    tempStates.remove(state);
                                  }
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFFFED7AA),
                              checkmarkColor: const Color(0xFFFB923C),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF6B7280),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFFFB923C)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Hourly Rate
                        const Text(
                          'Hourly Rate (RM)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minRateController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Min',
                                  prefixText: 'RM ',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                onChanged: (value) {
                                  tempMinRate = double.tryParse(value);
                                },
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('—', style: TextStyle(fontSize: 20)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: maxRateController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Max',
                                  prefixText: 'RM ',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                onChanged: (value) {
                                  tempMaxRate = double.tryParse(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Apply Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedSpecializations = tempSpecializations;
                          _selectedLanguages = tempLanguages;
                          _selectedStates = tempStates;
                          _minRate = tempMinRate;
                          _maxRate = tempMaxRate;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFB923C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleSessionBooked() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking confirmed successfully!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  Future<void> _loadPendingRating() async {
    try {
      final pending = await _bookingService.getPendingRating(widget.userId);
      if (!mounted) return;
      setState(() {
        _pendingRating = pending;
        _selectedRating = 0;
      });
    } catch (_) {
      // Ignore rating fetch errors
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final List<ChatConversation> conversations = await _chatService.getConversations(
        userId: widget.userId,
        isTherapist: false,
      );
      if (!mounted) return;
      final int total = conversations.fold<int>(0, (sum, conv) => sum + conv.unreadCount);
      setState(() {
        _unreadMessageCount = total;
      });
    } catch (_) {
      // Ignore unread count fetch errors silently for now.
    }
  }

  Future<void> _submitRating() async {
    final pending = _pendingRating;
    if (pending == null) return;
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a rating before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      await _bookingService.submitSessionRating(
        sessionId: pending.sessionId,
        clientUserId: widget.userId,
        rating: _selectedRating,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanks for rating ${pending.therapistName}!')),
      );

      setState(() {
        _pendingRating = null;
        _selectedRating = 0;
        final query = _searchController.text.trim();
        _therapistsFuture = _apiService.getTherapists(
          searchQuery: query.isEmpty ? null : query,
        );
      });

      await _loadPendingRating();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingRating = false;
        });
      }
    }
  }

  Widget _buildRatingPrompt() {
    final pending = _pendingRating;
    if (pending == null) {
      return const SizedBox.shrink();
    }

    final String scheduledLabel = _sessionFormatter.format(
      pending.scheduledAt.toLocal(),
    );

    final nameParts = pending.therapistName.trim().split(' ');
    final firstName =
        nameParts.isNotEmpty ? nameParts.first : pending.therapistName;
    final displayName = "Dr. $firstName";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your session with $displayName?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Session on $scheduledLabel',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                tooltip: 'Close',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _pendingRating = null;
                    _selectedRating = 0;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final isFilled = index < _selectedRating;
                  return GestureDetector(
                    onTap: _isSubmittingRating
                        ? null
                        : () {
                            setState(() {
                              _selectedRating = index + 1;
                            });
                          },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2.0),
                      child: Icon(
                        isFilled
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              if (_isSubmittingRating)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                ElevatedButton(
                  onPressed: _isSubmittingRating ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB923C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF4E342E)),
        title: const Text(
          'Find a Therapist',
          style: TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (context) => ChatContactsScreen(
                          currentUserId: widget.userId,
                          isTherapist: false,
                        ),
                      ),
                    )
                        .then((_) => _loadUnreadCount());
                  },
                ),
                if (_unreadMessageCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _unreadMessageCount > 99
                            ? '99+'
                            : _unreadMessageCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pendingRating != null) _buildRatingPrompt(),
                const CrisisBanner(),
                const SizedBox(height: 24),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Search by name or expertise...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              _debounceTimer?.cancel();
                              _searchTherapists('');
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.tune, color: Color(0xFF4E342E)),
                                onPressed: _showFilterBottomSheet,
                              ),
                              if (_selectedSpecializations.isNotEmpty || 
                                  _selectedLanguages.isNotEmpty || 
                                  _minRate != null || 
                                  _maxRate != null)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFB923C),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Therapist List
                FutureBuilder<List<Therapist>>(
                  future: _therapistsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No therapists found.'));
                    }

                    final allTherapists = snapshot.data!;
                    final filteredTherapists = _applyFilters(allTherapists);
                    
                    if (filteredTherapists.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No therapists match your filters',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedSpecializations.clear();
                                  _selectedLanguages.clear();
                                  _selectedStates.clear();
                                  _minRate = null;
                                  _maxRate = null;
                                });
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredTherapists.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return TherapistCard(
                          therapist: filteredTherapists[index],
                          clientUserId: widget.userId,
                          onSessionBooked: _handleSessionBooked,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
