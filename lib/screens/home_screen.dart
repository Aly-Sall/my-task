import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Importez flutter_local_notifications
import 'package:provider/provider.dart';
import 'add_task_screen.dart';
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
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool showCompletedTasks = true;
  String searchQuery = '';
  String selectedPriority = 'Tous';
  String selectedStatus = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _initializeNotifications();
  }

  // Initialisation des notifications
  void _initializeNotifications() async {
    const android = AndroidInitializationSettings(
        'app_icon'); // Assurez-vous d'avoir un icône dans le dossier drawable
    const settings = InitializationSettings(android: android);
    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  // Charger les tâches depuis la base de données
  void _loadTasks() async {
    List<Task> loadedTasks = await DatabaseHelper.instance.getAllTasks();
    setState(() {
      tasks = loadedTasks;
    });
    _sendReminders();
  }

  void _sendReminders() async {
    for (var task in tasks) {
      if (task.deadline != null) {
        final deadline = task.deadline!;
        final currentTime = DateTime.now();

        // Si la tâche est proche de sa date limite (par exemple dans les 24 heures), envoyer une notification
        if (deadline.isAfter(currentTime) &&
            deadline.isBefore(currentTime.add(const Duration(hours: 24)))) {
          _scheduleNotification(task, deadline);
        }
      }
    }
  }

  // Planifier une notification pour une tâche
  void _scheduleNotification(Task task, DateTime deadline) async {
    var scheduledNotificationDateTime = deadline.subtract(
        const Duration(hours: 1)); // Notification 1 heure avant la date limite
    var androidDetails = const AndroidNotificationDetails(
      'task_channel_id',
      'task_channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.schedule(
      task.id, // Utilisez l'ID de la tâche pour l'identifier
      'Rappel de tâche',
      'La tâche "${task.title}" arrive à échéance dans 1 heure.',
      scheduledNotificationDateTime,
      platformDetails,
    );
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

  void _deleteTask(int id) async {
    await DatabaseHelper.instance.delete(id);
    _loadTasks();
  }

  void _filterTasks() {
    List<Task> filteredTasks = tasks.where((task) {
      bool matchesSearchQuery =
          task.title.toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesPriority =
          selectedPriority == 'Tous' || task.priority == selectedPriority;
      bool matchesStatus = selectedStatus == 'Tous' ||
          (selectedStatus == 'Complète' && task.isComplete) ||
          (selectedStatus == 'Incomplète' && !task.isComplete);
      return matchesSearchQuery && matchesPriority && matchesStatus;
    }).toList();

    setState(() {
      tasks = filteredTasks;
    });
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
          // Barre de recherche
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
          // Filtrage par priorité et statut
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(onAddTask: _addTask),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
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
                        ? Colors.red
                        : task.priority == "Moyenne"
                            ? Colors.orange
                            : Colors.green,
                    child: Text(task.priority[0]),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
