import 'package:flutter/material.dart';
import '../models/task.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final Function(String, String?, String, DateTime?) onEditTask;

  const EditTaskScreen({
    super.key,
    required this.task,
    required this.onEditTask,
  });

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedPriority;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _selectedPriority =
        ['Haute', 'Moyenne', 'Basse'].contains(widget.task.priority)
            ? widget.task.priority
            : 'Moyenne';
    _selectedDate = widget.task.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la tâche'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Champ pour le titre
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),

            // Champ pour la description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16.0),

            // Liste déroulante pour la priorité
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priorité',
                border: OutlineInputBorder(),
              ),
              items: ['Haute', 'Moyenne', 'Basse']
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
              // Ajoutez ce paramètre pour gérer le cas où la valeur initiale n'existe pas dans la liste
              validator: (value) {
                if (value == null ||
                    !['Haute', 'Moyenne', 'Basse'].contains(value)) {
                  return 'Sélectionnez une priorité valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // Sélection de la date limite
            ListTile(
              title: const Text('Date limite'),
              subtitle: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} à ${_selectedDate!.hour}:${_selectedDate!.minute}'
                    : 'Aucune date sélectionnée',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            // Bouton de sauvegarde
            ElevatedButton(
              onPressed: () {
                widget.onEditTask(
                  _titleController.text,
                  _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                  _selectedPriority,
                  _selectedDate,
                );
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Modifier la tâche'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
