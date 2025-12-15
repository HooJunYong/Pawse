import 'package:flutter/foundation.dart';
import '../../../models/chat_history_model.dart';
import '../../../models/companion_model.dart';
import '../../../services/chat_session_service.dart';
import '../../../services/companion_service.dart';

class ChatSessionController extends ChangeNotifier {
  final String userId;
  
  List<ChatHistoryItem> _chatHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentCompanionId;
  Companion? _companionData;

  List<ChatHistoryItem> get chatHistory => _chatHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentCompanionId => _currentCompanionId;
  Companion? get companionData => _companionData;

  ChatSessionController({required this.userId});

  /// Load chat history and determine current companion
  Future<void> loadChatHistoryAndCompanion() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load chat history
      final chatHistory = await ChatSessionService.getChatHistory(userId);
      
      // Determine current companion
      String companionId;
      if (chatHistory.isNotEmpty) {
        // Get companion from most recent session
        companionId = chatHistory.first.companionId;
      } else {
        // Get default companion if no chat history
        final defaultCompanion = await CompanionService.getDefaultCompanion();
        if (defaultCompanion == null) {
          throw Exception('No default companion available');
        }
        companionId = defaultCompanion.companionId;
      }
      
      // Load companion data
      final companion = await CompanionService.getCompanionById(companionId);
      
      _chatHistory = chatHistory;
      _currentCompanionId = companionId;
      _companionData = companion;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update the current companion
  Future<void> updateCompanion(String newCompanionId) async {
    try {
      final newCompanion = await CompanionService.getCompanionById(newCompanionId);
      _currentCompanionId = newCompanionId;
      _companionData = newCompanion;
      notifyListeners();
    } catch (e) {
      rethrow; // Let UI handle the error
    }
  }

  /// Truncate message to specified number of words
  String truncateMessage(String message, int wordLimit) {
    if (message.isEmpty) return message;
    
    List<String> words = message.split(' ');
    
    if (words.length <= wordLimit) {
      return message;
    }
    
    return '${words.take(wordLimit).join(' ')}...';
  }
}
