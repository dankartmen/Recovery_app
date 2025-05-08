import 'package:flutter/material.dart';
import '../../data/models/models.dart';

class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const ExerciseTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Icon(Icons.fitness_center, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exercise.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (exercise.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children:
                      exercise.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.blue[50],
                              labelStyle: TextStyle(fontSize: 12),
                            ),
                          )
                          .toList(),
                ),
              SizedBox(height: 10),
              Text(
                'Сложность: ${exercise.maxPainLevel}/10 боли',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
