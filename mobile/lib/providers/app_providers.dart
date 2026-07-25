import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/ai_model.dart';
import '../models/conversation.dart';
import '../models/message.dart';

// --- Services ---

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiServiceProvider = Provider<ApiService?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  if (storage == null) return null;
  return ApiService(storage);
});

// --- App State ---

class ConnectionStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setConnected(bool value) => state = value;
}
final connectionStateProvider = NotifierProvider<ConnectionStateNotifier, bool>(ConnectionStateNotifier.new);

class PersonalityNotifier extends Notifier<String> {
  @override
  String build() => 'coding_partner';
  void setPersonality(String value) => state = value;
}
final personalityProvider = NotifierProvider<PersonalityNotifier, String>(PersonalityNotifier.new);

class ModelLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setLoading(bool value) => state = value;
}
final modelLoadingProvider = NotifierProvider<ModelLoadingNotifier, bool>(ModelLoadingNotifier.new);

class SelectedModelNotifier extends Notifier<AiModel?> {
  @override
  AiModel? build() => null;
  
  Future<void> setModel(AiModel? model) async {
    state = model;
    
    if (model != null) {
      final api = ref.read(apiServiceProvider);
      if (api != null) {
        ref.read(modelLoadingProvider.notifier).setLoading(true);
        await api.loadModel(model.id);
        ref.read(modelLoadingProvider.notifier).setLoading(false);
      }
    }
  }
  
  void setModelWithoutLoading(AiModel? model) {
    state = model;
  }
}
final selectedModelProvider = NotifierProvider<SelectedModelNotifier, AiModel?>(SelectedModelNotifier.new);

// --- Async Data ---

final availableModelsProvider = FutureProvider<List<AiModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  if (api == null) return [];
  
  try {
    final models = await api.getModels();
    if (models.isNotEmpty) {
      // Don't await this, just let it run in background so UI renders
      ref.read(selectedModelProvider.notifier).setModel(models.first);
    }
    return models;
  } catch (e) {
    return [];
  }
});

// --- Chat State ---

class ChatState {
  final Conversation? conversation;
  final bool isGenerating;
  final String? error;

  ChatState({
    this.conversation,
    this.isGenerating = false,
    this.error,
  });

  ChatState copyWith({
    Conversation? conversation,
    bool? isGenerating,
    String? error,
  }) {
    return ChatState(
      conversation: conversation ?? this.conversation,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => ChatState();

  void setConversation(Conversation conversation) {
    state = state.copyWith(conversation: conversation);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> sendMessage(String text) async {
    final api = ref.read(apiServiceProvider);
    if (api == null) {
      state = state.copyWith(error: 'API Service not initialized');
      return;
    }

    final model = ref.read(selectedModelProvider);
    if (model == null) {
      state = state.copyWith(error: 'No model selected');
      return;
    }

    final personality = ref.read(personalityProvider);

    // Optimistically add user message
    final tempUserMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.conversation?.id ?? '',
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    
    // Add temporary assistant message that will be updated by stream
    final tempAssistantMsg = Message(
      id: 'temp_assistant_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.conversation?.id ?? '',
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );

    List<Message> currentMessages = List.from(state.conversation?.messages ?? []);
    currentMessages.add(tempUserMsg);
    currentMessages.add(tempAssistantMsg);

    Conversation updatedConv = state.conversation != null 
        ? state.conversation!.copyWith(messages: currentMessages)
        : Conversation(
            id: '', 
            title: text, 
            model: model.id, 
            personality: personality, 
            createdAt: DateTime.now(), 
            updatedAt: DateTime.now(), 
            messages: currentMessages,
          );

    state = state.copyWith(conversation: updatedConv, isGenerating: true, error: null);

    try {
      final stream = api.streamChat(
        conversationId: state.conversation?.id, // null starts new conversation
        model: model.id,
        message: text,
        personality: personality,
      );

      String accumulatedContent = '';

      await for (final event in stream) {
        final type = event['type'];
        
        if (type == 'start') {
          // Update conversation ID if it was newly created
          if (state.conversation?.id.isEmpty ?? true) {
             updatedConv = updatedConv.copyWith(id: event['conversation_id']);
             state = state.copyWith(conversation: updatedConv);
          }
        } else if (type == 'chunk') {
          accumulatedContent += event['content'];
          
          // Update the last message (the temp assistant message) with new content
          final msgs = List<Message>.from(state.conversation!.messages);
          final lastMsg = msgs.last;
          msgs[msgs.length - 1] = Message(
            id: lastMsg.id,
            conversationId: lastMsg.conversationId,
            role: lastMsg.role,
            content: accumulatedContent,
            model: lastMsg.model,
            createdAt: lastMsg.createdAt,
          );
          
          state = state.copyWith(
            conversation: state.conversation!.copyWith(messages: msgs),
          );
        } else if (type == 'done') {
          // Could refresh from server here if needed, but streaming accumulated state is fine
          break;
        } else if (type == 'error') {
          state = state.copyWith(error: event['message'], isGenerating: false);
          return;
        }
      }
      
      state = state.copyWith(isGenerating: false);
      
    } catch (e) {
      state = state.copyWith(error: e.toString(), isGenerating: false);
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
