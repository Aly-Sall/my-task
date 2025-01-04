import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import '../models/task.dart';
import '../helpers/database_helper.dart';
import 'package:mapremiereapp/providers/theme_provider.dart';

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
    setState(() {
      tasks = tasks.where((task) {
        bool matchesSearchQuery = searchQuery.isEmpty ||
            task.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (task.description != null &&
                task.description!
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()));
        bool matchesPriority =
            selectedPriority == 'Tous' || task.priority == selectedPriority;
        bool matchesStatus = selectedStatus == 'Tous' ||
            (selectedStatus == 'Complète' && task.isComplete) ||
            (selectedStatus == 'Incomplète' && !task.isComplete);
        return matchesSearchQuery && matchesPriority && matchesStatus;
      }).toList();
    });
  }

  Widget _buildTaskSection(String title, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("Aucune tâche dans cette section."),
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Card(
                elevation: 3,
                child: ListTile(
                  title: Text(task.title),
                  subtitle:
                      task.description != null ? Text(task.description!) : null,
                  trailing: Wrap(
                    spacing: 8.0,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editTask(task),
                      ),
                      IconButton(
                        icon: Icon(
                          task.isComplete
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: task.isComplete ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _toggleTaskStatus(task.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTask(task.id),
                      ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: task.priority == "Haute"
                        ? Colors
                            .red // Si la priorité est "Haute", couleur rouge
                        : task.priority == "Moyenne"
                            ? Colors
                                .orange // Si la priorité est "Moyenne", couleur orange
                            : Colors
                                .blue, // Si la priorité est "Basse", couleur bleue
                    child: Text(
                      task.priority[
                          0], // Affiche la première lettre de la priorité
                      style: const TextStyle(
                          color: Colors.white), // Texte en blanc pour contraste
                    ),
                  ),
                ),
              ),
            ),
          ),
        const Divider(height: 1, color: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final completedTasks = tasks.where((task) => task.isComplete).toList();
    final incompleteTasks = tasks.where((task) => !task.isComplete).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Tâches"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher une tâche',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
                _filterTasks();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DropdownButton<String>(
                value: selectedPriority,
                items: ['Tous', 'Haute', 'Moyenne', 'Basse']
                    .map((priority) => DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority),
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
                items: ['Tous', 'Complète', 'Incomplète']
                    .map((status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Stack(
          children: [
            // Mic button on the left
            Positioned(
              bottom: 0,
              left: 30,
              child: FloatingActionButton(
                onPressed: _listenForTask,
                heroTag: 'btnVoice',
                backgroundColor: _isListening ? Colors.red : Colors.blue,
                child: Icon(_isListening ? Icons.mic_off : Icons.mic),
              ),
            ),
            // Add task button on the right
            Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                padding:
                    const EdgeInsets.only(right: 10.0), // Adjust right padding
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
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
