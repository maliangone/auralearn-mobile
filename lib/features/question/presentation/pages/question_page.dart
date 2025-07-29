import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../bloc/question_bloc.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/question_input_widget.dart';

class QuestionPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const QuestionPage({
    super.key,
    this.initialData,
  });

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>>? _images;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _images = widget.initialData?['images'];
    _initializeChat();
  }

  void _initializeChat() {
    // Add welcome message
    _messages.add(
      ChatMessage(
        id: 'welcome',
        content: "Hi! I'm your AI tutor. I can help you understand any question. ${_images != null ? 'I can see the images you selected.' : 'You can type your question below or capture images.'} What would you like to learn about?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    // If images were provided, show them
    if (_images != null && _images!.isNotEmpty) {
      _messages.add(
        ChatMessage(
          id: 'user_images',
          content: 'Here are the question images I captured:',
          isUser: true,
          timestamp: DateTime.now(),
          images: _images,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ask Question'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => context.go('/camera'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: BlocListener<QuestionBloc, QuestionState>(
        listener: (context, state) {
          if (state is QuestionSubmitSuccess) {
            setState(() {
              _isLoading = false;
              _messages.add(
                ChatMessage(
                  id: state.response.id,
                  content: state.response.answer ?? 'No answer provided',
                  isUser: false,
                  timestamp: DateTime.now(),
                  explanation: state.response.explanation,
                  subject: state.response.subject,
                ),
              );
            });
            _scrollToBottom();
          } else if (state is QuestionSubmitFailure) {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar(state.message);
          } else if (state is QuestionSubmitInProgress) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return ChatMessageWidget(
                      message: ChatMessage(
                        id: 'loading',
                        content: '',
                        isUser: false,
                        timestamp: DateTime.now(),
                        isLoading: true,
                      ),
                    );
                  }
                  
                  return ChatMessageWidget(
                    message: _messages[index],
                  );
                },
              ),
            ),

            // Input area
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  top: BorderSide(color: AppTheme.border),
                ),
              ),
              child: QuestionInputWidget(
                controller: _textController,
                focusNode: _focusNode,
                onSubmit: _submitQuestion,
                onAttachImage: () => context.go('/camera'),
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitQuestion(String text) {
    if (text.trim().isEmpty && (_images == null || _images!.isEmpty)) {
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      images: _images,
    );

    setState(() {
      _messages.add(userMessage);
    });

    _scrollToBottom();

    // Submit question to bloc
    context.read<QuestionBloc>().add(
      QuestionSubmitRequested(
        content: text.trim().isNotEmpty ? text.trim() : null,
        images: _images,
      ),
    );

    // Clear input and images
    _textController.clear();
    _images = null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? images;
  final String? explanation;
  final String? subject;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.images,
    this.explanation,
    this.subject,
    this.isLoading = false,
  });
} 