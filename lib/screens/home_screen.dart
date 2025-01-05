import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import '../models/task.dart';
import '../helpers/database_helper.dart';
import 'package:mapremiereapp/providers/theme_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> tasks = [];
  bool showCompletedTasks = true;
  String searchQuery = '';
  String selectedPriority = 'Tous';
  String selectedStatus = 'Tous';
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    if (!available) {
      print("Le Speech-to-Text n'est pas disponible sur cet appareil");
    }
  }

  Future<void> _listenForTask() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              setState(() => _isListening = false);
              _addTask(
                result.recognizedWords,
                null,
                'Moyenne',
                null,
              );
            }
          },
          localeId: 'fr_FR',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _loadTasks() async {
    List<Task> loadedTasks = await DatabaseHelper.instance.getAllTasks();
    setState(() {
      tasks = loadedTasks;
    });
  }

  void _addTask(String title, String? description, String priority,
      DateTime? deadline) async {
    final task = Task(
      id: tasks.length + 1,
      title: title,
      description: description,
      priority: priority,
      deadline: deadline,
      isComplete: false,
    );
    await DatabaseHelper.instance.insert(task);
    _loadTasks();
  }

  void _toggleTaskStatus(int id) async {
    final task = tasks.firstWhere((task) => task.id == id);
    task.isComplete = !task.isComplete;
    await DatabaseHelper.instance.update(task);
    _loadTasks();
  }

  void _editTask(Task task) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(
          task: task,
          onEditTask: (title, description, priority, deadline) async {
            final updatedTask = Task(
              id: task.id,
              title: title,
              description: description,
              priority: priority,
              deadline: deadline,
              isComplete: task.isComplete,
            );
            await DatabaseHelper.instance.update(updatedTask);
            _loadTasks();
          },
        ),
      ),
    );
  }

  void _deleteTask(int id) async {
    await DatabaseHelper.instance.delete(id);
    _loadTasks();
  }

  void _filterTasks() {
    final query = searchQuery.trim().toLowerCase();

    setState(() {
      tasks = tasks.where((task) {
        final matchesSearchQuery = query.isEmpty ||
            task.title.toLowerCase().contains(query) ||
            (task.description?.toLowerCase().contains(query) ?? false);

        final matchesPriority =
            selectedPriority == 'Tous' || task.priority == selectedPriority;

        final matchesStatus = selectedStatus == 'Tous' ||
            (selectedStatus == 'Complète' && task.isComplete) ||
            (selectedStatus == 'Incomplète' && !task.isComplete);

        return matchesSearchQuery && matchesPriority && matchesStatus;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      searchQuery = '';
      selectedPriority = 'Tous';
      selectedStatus = 'Tous';
    });
    _loadTasks();
  }

  Color _getPriorityColor(String priority) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (priority) {
      case "Haute":
        return isDarkMode ? Colors.red.shade700 : Colors.red;
      case "Moyenne":
        return isDarkMode ? Colors.orange.shade700 : Colors.orange;
      default:
        return isDarkMode ? Colors.blue.shade700 : Colors.blue;
    }
  }

  Widget _buildTaskSection(String title, List<Task> tasks) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.7),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Aucune tâche dans cette section.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6),
                  ),
            ),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: isDarkMode ? 2 : 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: task.isComplete
                        ? (isDarkMode
                            ? Colors.green.shade900.withOpacity(0.3)
                            : Colors.green.shade50)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: task.isComplete
                          ? (isDarkMode ? Colors.green.shade700 : Colors.green)
                          : isDarkMode
                              ? Colors.blue.shade700
                              : Colors.blue.shade100,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getPriorityColor(task.priority),
                      child: Text(
                        task.priority[0],
                        style: TextStyle(
                          color: isDarkMode ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: task.isComplete
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: task.isComplete
                            ? Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.6)
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              task.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        if (task.deadline != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Échéance : ${task.deadline?.toLocal().toString().split(' ')[0]}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 6.0,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () => _editTask(task),
                        ),
                        IconButton(
                          icon: Icon(
                            task.isComplete
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: task.isComplete
                                ? (isDarkMode
                                    ? Colors.green.shade400
                                    : Colors.green)
                                : Theme.of(context).disabledColor,
                          ),
                          onPressed: () => _toggleTaskStatus(task.id),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color:
                                isDarkMode ? Colors.red.shade400 : Colors.red,
                          ),
                          onPressed: () => _deleteTask(task.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Divider(
          height: 1,
          color: Theme.of(context).dividerColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final completedTasks = tasks.where((task) => task.isComplete).toList();
    final incompleteTasks = tasks.where((task) => !task.isComplete).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gestion des Tâches",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
              color: isDarkMode ? Colors.white : Colors.white,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          dropdownMenuTheme: DropdownMenuThemeData(
            textStyle: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Rechercher une tâche',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        labelStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      onChanged: (query) {
                        setState(() {
                          searchQuery = query;
                        });
                        _filterTasks();
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _resetFilters,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DropdownButton<String>(
                  value: selectedPriority,
                  dropdownColor: Theme.of(context).cardColor,
                  items: ['Tous', 'Haute', 'Moyenne', 'Basse']
                      .map((priority) => DropdownMenuItem<String>(
                            value: priority,
                            child: Text(
                              priority,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedPriority = newValue!;
                    });
                    _filterTasks();
                  },
                ),
                DropdownButton<String>(
                  value: selectedStatus,
                  dropdownColor: Theme.of(context).cardColor,
                  items: ['Tous', 'Complète', 'Incomplète']
                      .map((status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                    _filterTasks();
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildTaskSection("Tâches Incomplètes", incompleteTasks),
                  if (showCompletedTasks)
                    _buildTaskSection("Tâches Complètes", completedTasks),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 30,
              child: FloatingActionButton(
                onPressed: _listenForTask,
                heroTag: 'btnVoice',
                backgroundColor: _isListening
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade700
                        : Colors.red)
                    : Theme.of(context).primaryColor,
                child: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddTaskScreen(onAddTask: _addTask),
                      ),
                    );
                  },
                  heroTag: 'btnAdd',
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
