import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter TODO App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodosList(title: 'TODO List'),
    );
  }
}

class TodosList extends StatefulWidget {
  const TodosList({super.key, required this.title});

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _TodosListState createState() => _TodosListState();
}

class _TodosListState extends State<TodosList> {
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    fetchAndSetTodos();
  }

  Future<void> fetchAndSetTodos() async {
    try {
      List<Todo> fetchedTodos = await fetchTodos();
      setState(() {
        _todos = fetchedTodos;
      });
    } catch (e) {
      // Handle error fetching todos
      if (kDebugMode) {
        print('Error fetching todos: $e');
      }
    }
  }

  Future<List<Todo>> fetchTodos() async {
    final response =
        await http.get(Uri.parse('http://198.18.0.186:8000/todos'));
    if (response.statusCode == 200) {
      List<dynamic> responseData = jsonDecode(response.body);
      List<Todo> todos = responseData.map((e) => Todo.fromJson(e)).toList();
      return todos;
    } else {
      throw Exception('Failed to load todos: ${response.statusCode}');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    final response = await http.put(
      Uri.parse(
          'http://198.18.0.186:8000/todos/${todo.id}'), // Replace with your backend endpoint
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode == 200) {
      // Update successful, no action required
    } else {
      throw Exception('Failed to update todo: ${response.statusCode}');
    }
  }

  Future<Todo> addTodo(Todo todo) async {
    final response = await http.post(
      Uri.parse('http://198.18.0.186:8000/todos'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode == 200) {
      return Todo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add todo: ${response.statusCode}');
    }
  }

  Future<void> deleteTodo(String todoId) async {
    final response =
        await http.delete(Uri.parse('http://198.18.0.186:8000/todos/$todoId'));
    if (response.statusCode == 200) {
      // Todo deleted successfully
    } else {
      throw Exception('Failed to delete todo: ${response.statusCode}');
    }
  }

  void _addTodo() async {
    final TextEditingController textEditingController = TextEditingController();

    final newTodo = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return _buildAddTodoDialog(textEditingController);
      },
    );

    if (newTodo != null && newTodo.isNotEmpty) {
      try {
        // Create a new Todo object
        Todo todo = Todo(
          id: '', // You may assign an ID if required, or handle it on server side
          title: newTodo,
          done: false,
        );

        // Call addTodo function to add the todo to backend
        Todo addedTodo = await addTodo(todo);

        // Update local state with the added todo
        setState(() {
          _todos.add(addedTodo);
        });
      } catch (e) {
        // Handle error adding todo
        if (kDebugMode) {
          print('Error adding todo: $e');
        }
      }
    } else {
      // Handle case where newTodo is null or empty
      if (kDebugMode) {
        print('New todo is null or empty: $newTodo');
      }
    }
  }

  void _deleteTodo(int index) async {
    String todoId = _todos[index].id;
    try {
      await deleteTodo(todoId);
      setState(() {
        _todos.removeAt(index);
      });
    } catch (e) {
      // Handle error deleting todo
      if (kDebugMode) {
        print('Error deleting todo: $e');
      }
    }
  }

  AlertDialog _buildAddTodoDialog(TextEditingController textEditingController) {
    return AlertDialog(
      title: const Text('Add Todo'),
      content: TextField(
        controller: textEditingController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter your todo'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newTodo = textEditingController.text;
            if (newTodo.isNotEmpty) {
              Navigator.of(context).pop(newTodo);
            } else {
              // Handle case where newTodo is empty
              if (kDebugMode) {
                print('New todo is empty');
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildTodoItem(index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodoItem(int index) {
    final todo = _todos[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          todo.markDone(); // Toggle the completion status
          updateTodo(todo);
        });
      },
      child: Dismissible(
        key: Key(todo.id),
        onDismissed: (direction) {
          _deleteTodo(index);
        },
        background: Container(
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Icon(Icons.delete, color: Colors.white),
            ),
          ),
        ),
        secondaryBackground: Container(
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Icon(Icons.delete, color: Colors.white),
            ),
          ),
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
          child: CheckboxListTile(
            title: Text(
              todo.title,
              style: TextStyle(
                decoration: todo.done ? TextDecoration.lineThrough : null,
              ),
            ),
            value: todo.done,
            onChanged: (bool? value) {
              setState(() {
                todo.done = value ?? false; // Update the completion status
                updateTodo(todo);
              });
            },
            secondary: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _deleteTodo(index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
