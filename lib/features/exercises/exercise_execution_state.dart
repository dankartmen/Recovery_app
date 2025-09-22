class ExerciseExecutionState {
  final int remainingSeconds;
  final bool isRunning;
  final int completedSets;
  final int painLevel;
  final int totalDurationSeconds;
  final bool isExerciseCompleted;
  final double progress;
  final int currentSetDuration;

  const ExerciseExecutionState({
    required this.remainingSeconds,
    required this.isRunning,
    required this.completedSets,
    required this.painLevel,
    required this.totalDurationSeconds,
    required this.isExerciseCompleted,
    required this.progress,
    required this.currentSetDuration,
  });

  ExerciseExecutionState.initial()
      : remainingSeconds = 0,
        isRunning = false,
        completedSets = 0,
        painLevel = 0,
        totalDurationSeconds = 0,
        isExerciseCompleted = false,
        progress = 0.0,
        currentSetDuration = 0;

  ExerciseExecutionState copyWith({
    int? remainingSeconds,
    bool? isRunning,
    int? completedSets,
    int? painLevel,
    int? totalDurationSeconds,
    bool? isExerciseCompleted,
    double? progress,
    int? currentSetDuration,
  }) {
    return ExerciseExecutionState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      completedSets: completedSets ?? this.completedSets,
      painLevel: painLevel ?? this.painLevel,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      isExerciseCompleted: isExerciseCompleted ?? this.isExerciseCompleted,
      progress: progress ?? this.progress,
      currentSetDuration: currentSetDuration ?? this.currentSetDuration,
    );
  }
}