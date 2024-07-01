class Todo {
  final String id;
  final String title;
  bool done;

  Todo({
    required this.id,
    required this.title,
    this.done = false,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      done: json['done'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'done': done,
    };
  }

  void markDone() {
    done = !done;
  }
}
