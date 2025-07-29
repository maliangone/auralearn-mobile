import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RecentQuestionCard extends StatelessWidget {
  final String question;
  final String subject;
  final String time;
  final bool hasImages;
  final VoidCallback onTap;

  const RecentQuestionCard({
    super.key,
    required this.question,
    required this.subject,
    required this.time,
    required this.hasImages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSubjectColor(subject).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        color: _getSubjectColor(subject),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  if (hasImages)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image,
                            size: 12,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'IMG',
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                question,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppTheme.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
      case 'algebra':
      case 'geometry':
      case 'calculus':
        return const Color(0xFF2563EB); // Blue
      case 'physics':
        return const Color(0xFF7C3AED); // Purple
      case 'chemistry':
        return const Color(0xFF059669); // Green
      case 'biology':
        return const Color(0xFFDC2626); // Red
      case 'english':
      case 'literature':
        return const Color(0xFFEA580C); // Orange
      case 'history':
        return const Color(0xFF7C2D12); // Brown
      case 'geography':
        return const Color(0xFF0891B2); // Teal
      case 'computer science':
      case 'programming':
        return const Color(0xFF4338CA); // Indigo
      default:
        return AppTheme.primary;
    }
  }
} 