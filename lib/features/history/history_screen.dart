import 'package:flutter/material.dart';
import '../../data/models/exercise_history.dart';
import '../../data/repositories/history_repository.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ExerciseHistory>> _historyFuture;
  final HistoryRepository _repository = HistoryRepository.instance;

  @override
  void initState() {
    super.initState();
    _historyFuture = _repository.getAllHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = _repository.getAllHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('История упражнений'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshHistory),
        ],
      ),
      body: FutureBuilder<List<ExerciseHistory>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки истории'));
          }

          final historyList = snapshot.data!;

          if (historyList.isEmpty) {
            return Center(child: Text('Нет выполненных упражнений'));
          }

          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = historyList[index];
              return _HistoryItem(
                history: history,
                onDelete: () async {
                  await _repository.deleteHistory(history.id!);
                  _refreshHistory();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ExerciseHistory history;
  final VoidCallback onDelete;

  const _HistoryItem({required this.history, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(history.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => onDelete(),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Удалить запись?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Удалить'),
                  ),
                ],
              ),
        );
      },
      child: ListTile(
        title: Text(history.exerciseName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(history.formattedDate),
            Text('Длительность: ${history.formattedDuration}'),
            if (history.notes != null) Text('Заметки: ${history.notes!}'),
          ],
        ),
        leading: Icon(Icons.fitness_center),
        trailing: IconButton(
          icon: Icon(Icons.info_outline),
          onPressed: () => _showDetails(context),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(history.exerciseName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Дата: ${history.formattedDate}'),
                Text('Длительность: ${history.formattedDuration}'),
                if (history.notes != null) Text('Заметки: ${history.notes!}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Закрыть'),
              ),
            ],
          ),
    );
  }
}
