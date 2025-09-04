import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../styles/style.dart';

class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const ExerciseTile({super.key, required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return buildCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: healthTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exercise.generalDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: healthSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (exercise.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children:
                      exercise.tags.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: healthPrimaryColor.withValues(
                            alpha: 0.1,
                          ),
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
