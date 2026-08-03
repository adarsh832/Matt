import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/chat_bubble.dart';
import 'package:mobile/providers/app_providers.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late Timer _timer;
  int _dotCount = 1;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount % 3) + 1;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(availableModelsProvider); // This triggers the FutureProvider to fetch models
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _textController.clear();
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.conversation?.messages ?? [];
    final isGenerating = chatState.isGenerating;

    ref.listen(chatProvider, (previous, next) {
      // If we got a new chunk or a new message, scroll to bottom if user is already at bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && !_showScrollToBottom) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, chatState),
            Expanded(
              child: messages.isEmpty && !isGenerating
                  ? _buildGreeting()
                  : Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            if (_scrollController.hasClients) {
                              final isAtBottom = _scrollController.position.maxScrollExtent - _scrollController.position.pixels <= 50;
                              
                              if (notification is ScrollUpdateNotification) {
                                // If user is dragging list up (away from bottom)
                                if (notification.dragDetails != null && !isAtBottom && !_showScrollToBottom) {
                                  setState(() => _showScrollToBottom = true);
                                }
                              }
                              
                              // Automatically hide button when reaching bottom
                              if (isAtBottom && _showScrollToBottom) {
                                setState(() => _showScrollToBottom = false);
                              }
                            }
                            return false;
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: messages.length + (isGenerating ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length) {
                                return _buildTypingIndicator();
                              }
                              
                              final msg = messages[index];
                              final isUser = msg.role == 'user';
                              final timeString = DateFormat('h:mm a').format(msg.createdAt);
                              
                              // Skip empty assistant messages (they appear when generation starts)
                              if (!isUser && msg.content.isEmpty && isGenerating) {
                                 return const SizedBox.shrink(); 
                              }
                              
                              final aiName = _getDisplayName(ref.read(personalityProvider));

                              return ChatBubble(
                                message: msg.content,
                                isUser: isUser,
                                timestamp: '${isUser ? "You" : aiName} $timeString',
                              );
                            },
                          ),
                        ),
                        if (_showScrollToBottom)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: FloatingActionButton(
                              mini: true,
                              onPressed: _scrollToBottom,
                              backgroundColor: AppColors.primary,
                              elevation: 4,
                              child: const Icon(Icons.arrow_downward, color: AppColors.background),
                            ),
                          ),
                      ],
                    ),
            ),
            _buildBottomInput(),
          ],
        ),
      ),
    );
  }

  String _getDisplayName(String personality) {
    if (personality.startsWith('custom:')) {
      final customData = personality.substring(7);
      if (customData.contains('|')) {
        return customData.split('|').first;
      }
      return 'Custom AI';
    }
    return personality.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _buildGreeting() {
    final aiName = _getDisplayName(ref.watch(personalityProvider));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.waving_hand, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Hello,\nI\'m $aiName.',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How can I help you today?',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ChatState chatState) {
    final personality = ref.watch(personalityProvider);
    final displayPersonality = _getDisplayName(personality);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textSecondary),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Text(
              displayPersonality,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Serif',
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _showDeleteChatConfirmation(context, chatState);
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.deleteColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final conversationsAsync = ref.watch(conversationsProvider);
                  
                  return conversationsAsync.when(
                    data: (conversations) {
                      if (conversations.isEmpty) {
                        return const Center(
                          child: Text('No past chats', style: TextStyle(color: AppColors.textSecondary)),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conv = conversations[index];
                          return Dismissible(
                            key: Key(conv.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              ref.read(conversationsProvider.notifier).deleteConversation(conv.id);
                            },
                            child: ListTile(
                              leading: const Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary),
                              title: Text(
                                conv.title.isNotEmpty ? conv.title : 'New Chat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                DateFormat('MMM d, h:mm a').format(conv.updatedAt),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              onTap: () {
                                ref.read(chatProvider.notifier).loadConversation(conv.id);
                                Navigator.pop(context); // close drawer
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                  );
                },
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(chatProvider.notifier).startNewChat();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final modelsAsync = ref.watch(availableModelsProvider);
            final selectedModel = ref.watch(selectedModelProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select AI Model',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    modelsAsync.when(
                      data: (models) {
                        if (models.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No models found on server.', style: TextStyle(color: AppColors.textSecondary)),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: models.length,
                          itemBuilder: (context, index) {
                            final model = models[index];
                            final isSelected = selectedModel?.id == model.id;
                            
                            return ListTile(
                              leading: Icon(
                                Icons.smart_toy,
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                              title: Text(
                                model.name,
                                style: TextStyle(
                                  color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              trailing: isSelected 
                                  ? const Icon(Icons.check_circle, color: AppColors.textPrimary)
                                  : null,
                              onTap: () {
                                ref.read(selectedModelProvider.notifier).setModel(model);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    String dots = '.' * _dotCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        children: [
          const Icon(
            Icons.edit,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Writing$dots',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInput() {
    final isModelLoading = ref.watch(modelLoadingProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 12.0, 12.0, 12.0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textSecondary),
            onPressed: () => _showModelPicker(context),
            tooltip: 'Switch AI Model',
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isModelLoading ? AppColors.divider.withOpacity(0.5) : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                enabled: !isModelLoading,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: isModelLoading ? 'Loading model into memory...' : 'Message Maat...',
                  hintStyle: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isModelLoading ? null : _sendMessage,
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isModelLoading ? AppColors.textTertiary : AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
              child: isModelLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.background)
                    )
                  )
                : const Icon(
                    Icons.arrow_upward,
                    color: AppColors.background,
                    size: 20,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatConfirmation(BuildContext context, ChatState chatState){
    showAdaptiveDialog(
      context: context, 
      builder: (context){
        return AlertDialog.adaptive(
          title: Text(
            "Are you sure you want to delete this conversation?"
          ),
          actions: <Widget>[
            TextButton(
              onPressed: ()=> Navigator.pop(context), 
              child: Text("No")
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if(chatState.conversation == null){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("No chat selected")
                    )
                  );
                }
                else{
                  final convId = chatState.conversation!.id;
                  final res = await ref.read(conversationsProvider.notifier).deleteConversation(convId);
                  if(res && context.mounted){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Chat deleted successfully")
                      )
                    );
                  }
                  else if(context.mounted){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Chat did not delete")
                      )
                    );
                  }
                }
              }, 
              child: const Text("Yes",
                style: TextStyle(
                  color: AppColors.deleteColor
                ),
              )
            )
          ],
        );
      }
    );
  }

}
