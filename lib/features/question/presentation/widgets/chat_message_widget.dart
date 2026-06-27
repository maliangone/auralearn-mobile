import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';

/// Legacy chat-message model.
///
/// Phase A0: the question screen moved to the streaming solve flow and no
/// longer renders chat bubbles, but this widget + model are kept compiling for
/// any remaining legacy/text callers. Previously declared in `question_page.dart`.
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

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: message.isUser ? AppTheme.primary : AppTheme.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              message.isUser ? Icons.person : Icons.psychology,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name and timestamp
                Row(
                  children: [
                    Text(
                      message.isUser ? 'You' : 'AI Tutor',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Message bubble
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      topLeft: message.isUser 
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      topRight: message.isUser 
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: message.isUser 
                        ? null 
                        : Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images (if any)
                      if (message.images != null && message.images!.isNotEmpty)
                        _buildImageGallery(),

                      // Loading indicator
                      if (message.isLoading)
                        _buildLoadingIndicator()
                      else if (message.content.isNotEmpty)
                        // Text content
                        SelectableText(
                          message.content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: message.isUser 
                                ? Colors.white 
                                : AppTheme.textPrimary,
                            height: 1.5,
                          ),
                        ),

                      // Subject tag (for AI responses)
                      if (!message.isUser && message.subject != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.secondary),
                          ),
                          child: Text(
                            message.subject!,
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // Explanation (for AI responses)
                      if (!message.isUser && message.explanation != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: AppTheme.accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Detailed Explanation',
                                    style: TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                message.explanation!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons (for AI responses)
                if (!message.isUser && !message.isLoading)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.copy,
                          label: 'Copy',
                          onTap: () => _copyToClipboard(context, message.content),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.thumb_up_outlined,
                          label: 'Helpful',
                          onTap: () => _rateResponse(context, true),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.thumb_down_outlined,
                          label: 'Not helpful',
                          onTap: () => _rateResponse(context, false),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: message.images!.length,
          itemBuilder: (context, index) {
            final imageData = message.images![index];
            final imagePath = imageData['path'] as String;
            
            return Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'AI is thinking...',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _rateResponse(BuildContext context, bool isHelpful) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isHelpful ? 'Thanks for your feedback!' : 'Thanks, we\'ll improve our responses'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 