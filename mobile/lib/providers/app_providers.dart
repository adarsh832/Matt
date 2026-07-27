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

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(storage);
});

// --- App State ---

class ConnectionStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setConnected(bool value) => state = value;
  
  Future<void> checkConnection() async {
    final storage = ref.read(storageServiceProvider);
    
    final token = await storage.getDeviceToken();
    if (token != null && token.isNotEmpty) {
      final serverUrl = await storage.getServerUrl();
      if (serverUrl != null && serverUrl.isNotEmpty) {
         final api = ref.read(apiServiceProvider);
         final isHealthy = await api.checkHealth(serverUrl);
         state = isHealthy;
         return;
      }
    }
    state = false;
  }
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

// --- Conversations State ---

class ConversationsNotifier extends Notifier<AsyncValue<List<Conversation>>> {
  @override
  AsyncValue<List<Conversation>> build() {
    _fetchConversations();
    return const AsyncValue.loading();
  }

  Future<void> _fetchConversations() async {
    final api = ref.read(apiServiceProvider);
    if (api == null) {
      state = AsyncValue.error('API service not available', StackTrace.current);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final conversations = await api.getConversations();
      // Sort by updatedAt descending
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = AsyncValue.data(conversations);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _fetchConversations();
  }

  Future<bool> deleteConversation(String id) async {
    final api = ref.read(apiServiceProvider);
    if (api == null) return false;

    try {
      final success = await api.deleteConversation(id);
      if (success) {
        // Optimistically remove from state
        state.whenData((conversations) {
          final updated = conversations.where((c) => c.id != id).toList();
          state = AsyncValue.data(updated);
        });
        
        // Check if the deleted conversation is the active one
        final currentChatId = ref.read(chatProvider).conversation?.id;
        if (currentChatId == id) {
          ref.read(chatProvider.notifier).startNewChat();
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

final conversationsProvider = NotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>(ConversationsNotifier.new);

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

  void startNewChat() {
    state = ChatState(); // Resets to initial empty state
  }

  Future<void> loadConversation(String id) async {
    final api = ref.read(apiServiceProvider);
    if (api == null) return;
    
    try {
      state = state.copyWith(isGenerating: true, error: null);
      final conversation = await api.getConversation(id);
      
      // Update the personality based on the loaded conversation
      if (conversation.personality.isNotEmpty) {
        ref.read(personalityProvider.notifier).setPersonality(conversation.personality);
      }
      
      state = state.copyWith(conversation: conversation, isGenerating: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isGenerating: false);
    }
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

    String currentTargetId = state.conversation?.id ?? '';

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
          if (currentTargetId.isEmpty) {
             currentTargetId = event['conversation_id'];
             if (state.conversation?.id.isEmpty ?? true) {
                 updatedConv = updatedConv.copyWith(id: currentTargetId);
                 state = state.copyWith(conversation: updatedConv);
                 // Refresh the conversation list in the drawer
                 ref.read(conversationsProvider.notifier).refresh();
             }
          }
        } 
        
        // If the user switched away from this conversation, just consume the stream silently
        // so the backend can finish generating and save it to the DB.
        if ((state.conversation?.id ?? '') != currentTargetId) {
          if (type == 'done' || type == 'error') {
             break;
          }
          continue;
        }

        if (type == 'chunk') {
          accumulatedContent += event['content'];
          
          final msgs = List<Message>.from(state.conversation!.messages);
          if (msgs.isNotEmpty) {
            if (msgs.last.role != 'assistant') {
               // The temp message was lost (e.g. user navigated away and back). Recreate it.
               msgs.add(Message(
                 id: 'temp_assistant_${DateTime.now().millisecondsSinceEpoch}',
                 conversationId: currentTargetId,
                 role: 'assistant',
                 content: '',
                 createdAt: DateTime.now(),
               ));
            }
            
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
          }
        } else if (type == 'done') {
          break;
        } else if (type == 'error') {
          // Only show error if we are still on the same conversation
          if ((state.conversation?.id ?? '') == currentTargetId) {
            state = state.copyWith(error: event['message'], isGenerating: false);
          }
          return;
        }
      }
      
      // Only reset generating state if we are still on the same conversation
      if ((state.conversation?.id ?? '') == currentTargetId) {
        state = state.copyWith(isGenerating: false);
      }
      
    } catch (e) {
      state = state.copyWith(error: e.toString(), isGenerating: false);
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
