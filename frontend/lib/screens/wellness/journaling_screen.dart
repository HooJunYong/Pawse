import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/journal_model.dart';
import '../../services/journal_service.dart';

class JournalingScreen extends StatefulWidget {
  final String userId;
  
  const JournalingScreen({super.key, required this.userId});

  @override
  State<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends State<JournalingScreen> {
  final JournalService _journalService = JournalService();
  final TextEditingController _contentController = TextEditingController();
  
  JournalPrompt? _todayPrompt;
  List<JournalEntry> _pastEntries = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prompt = await _journalService.getDailyPrompt();
      final entries = await _journalService.getUserEntries(widget.userId, limit: 10);
      setState(() {
        _todayPrompt = prompt;
        _pastEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _showEditEntryDialog(JournalEntry entry) {
    final TextEditingController editController = TextEditingController(text: entry.content);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Container(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Prompt:",
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(92, 64, 51, 1),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: editController,
                  maxLines: 10,
                  minLines: 6,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(66, 32, 6, 1),
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Edit your entry...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      color: Color.fromRGBO(156, 163, 175, 1),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color.fromRGBO(249, 115, 22, 1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color.fromRGBO(249, 115, 22, 1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color.fromRGBO(249, 115, 22, 1), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color.fromRGBO(92, 64, 51, 1), fontFamily: 'Nunito')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(249, 115, 22, 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
              ),
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isEmpty) return;
                final updated = CreateJournalEntry(
                  title: entry.title,
                  content: newText,
                  promptType: _validPromptType(entry.promptType),
                  emotionalTags: entry.emotionalTags,
                );
                await _journalService.updateEntry(entry.entryId, widget.userId, updated);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Entry updated successfully')),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEntryDetail(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final now = DateTime.now();
        final canEdit = now.difference(entry.createdAt).inMinutes < 10;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Container(
            width: 375,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prompt:',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(92, 64, 51, 1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Entry:',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    color: Color.fromRGBO(92, 64, 51, 1),
                  ),
                ),
                const SizedBox(height: 24),
                if (canEdit)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(249, 115, 22, 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditEntryDialog(entry);
                      },
                      child: const Text(
                        'Edit Entry',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before saving')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final entry = CreateJournalEntry(
        title: _todayPrompt?.prompt ?? 'Journal Entry',
        content: _contentController.text.trim(),
        promptType: _validPromptType(_todayPrompt?.promptType),
        emotionalTags: [],
      );
      
      // Create new entry
      await _journalService.createEntry(widget.userId, entry);
      
      // After saving, refresh prompt for next entry and update past entries
      final newPrompt = await _journalService.getDailyPrompt();
      final entries = await _journalService.getUserEntries(widget.userId, limit: 10);
      
      setState(() {
        _todayPrompt = newPrompt;
        _pastEntries = entries;
      });
      
      _contentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _validPromptType(String? type) {
    const allowed = ['reflection', 'gratitude', 'expressive'];
    if (type != null && allowed.contains(type)) {
      return type;
    }
    return 'reflection';
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMMM dd, yyyy – hh:mm a').format(date);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Journaling',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(249, 115, 22, 1),
              ),
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: 375,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's Prompt Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Today's Prompt",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(66, 32, 6, 1),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _todayPrompt?.prompt ?? 'Loading prompt...',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  color: Color.fromRGBO(92, 64, 51, 1),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Text Input Area
                        Container(
                          width: double.infinity,
                          height: 250,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Nunito',
                              color: Color.fromRGBO(66, 32, 6, 1),
                              height: 1.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Let your thoughts flow...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                color: Color.fromRGBO(156, 163, 175, 1),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(66, 32, 6, 1),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _isSaving ? null : _saveEntry,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Entry',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Past Entries Section
                        const Text(
                          'Past Entries',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(66, 32, 6, 1),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Past Entries List
                        if (_pastEntries.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No past entries yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  color: Color.fromRGBO(156, 163, 175, 1),
                                ),
                              ),
                            ),
                          )
                        else
                          ..._pastEntries.map((entry) => _buildPastEntryCard(entry)).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPastEntryCard(JournalEntry entry) {
    return GestureDetector(
      onTap: () => _showEntryDetail(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        width: 375, // Set width for full details
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(entry.createdAt),
                    style: const TextStyle(
                      fontSize: 14, // Increased font size for date/time
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(249, 115, 22, 1),
                    ),
                  ),
                ),
                // Prompt type label hidden
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.content.length > 150
                  ? '${entry.content.substring(0, 150)}...'
                  : entry.content,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'Nunito',
                color: Color.fromRGBO(92, 64, 51, 1),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
