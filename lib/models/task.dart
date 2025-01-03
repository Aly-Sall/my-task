class Task {
  int id;
  String title;
  String? description;
  String priority;
  DateTime? deadline;
  bool isComplete;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    this.deadline,
    this.isComplete = false,
  });

  // Méthode pour mettre à jour les propriétés de la tâche
  void update({
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    bool? isComplete,
  }) {
    if (title != null) this.title = title;
    if (description != null) this.description = description;
    if (priority != null) this.priority = priority;
    if (deadline != null) this.deadline = deadline;
    if (isComplete != null) this.isComplete = isComplete;
  }

  // Convertir un objet Task en Map pour l'insertion dans la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'deadline': deadline?.toIso8601String(), // Convertir DateTime en String
      'isComplete': isComplete ? 1 : 0, // Utiliser 1 pour vrai et 0 pour faux
    };
  }

  // Convertir un Map en objet Task
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      priority: map['priority'],
      deadline:
          map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      isComplete: map['isComplete'] == 1,
    );
  }
}
