import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  final Function(String title, String? description, String priority,
      DateTime? deadline) onAddTask;

  const AddTaskScreen({required this.onAddTask, super.key});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String? _description;
  String _priority = 'basse';
  DateTime? _deadline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une tâche'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Description (facultatif)'),
                onSaved: (value) {
                  _description = value;
                },
              ),
              DropdownButtonFormField<String>(
                value: _priority,
                items: ['basse', 'moyenne', 'haute']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        ))
                    .toList(),
                decoration: const InputDecoration(labelText: 'Priorité'),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Date limite (facultatif)',
                  hintText: 'YYYY-MM-DD',
                ),
                keyboardType: TextInputType.datetime,
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    _deadline = DateTime.tryParse(value);
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.onAddTask(
                        _title, _description, _priority, _deadline);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
