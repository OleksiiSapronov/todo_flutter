import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_todo_app/model/todo.dart';

class TodosViewModel extends ChangeNotifier {
  List<Todo> _todos = [];

  List<Todo> get todos => _todos;

  Future<void> fetchAndSetTodos() async {
    try {
      List<Todo> fetchedTodos = await fetchTodos();
      _todos = fetchedTodos;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching todos: $e');
      }
    }
  }

  Future<List<Todo>> fetchTodos() async {
    final response = await http.get(Uri.parse('${dotenv.env['API_URL']}/todos'));
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
      Uri.parse('${dotenv.env['API_URL']}/todos/${todo.id}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(todo.toJson()),
    );
    if (response.statusCode == 200) {
    } else {
      throw Exception('Failed to update todo: ${response.statusCode}');
    }
  }

  Future<Todo> addTodo(Todo todo) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}/todos'),
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
    final response = await http.delete(Uri.parse('${dotenv.env['API_URL']}/todos/$todoId'));
    if (response.statusCode == 200) {
    } else {
      throw Exception('Failed to delete todo: ${response.statusCode}');
    }
  }

  void addTodoLocally(Todo todo) {
    _todos.add(todo);
    notifyListeners();
  }

  void removeTodoLocally(int index) {
    _todos.removeAt(index);
    notifyListeners();
  }
}
