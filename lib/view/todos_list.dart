import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_todo_app/model/todo.dart';
import 'package:my_todo_app/view_model/todos_view_model.dart';
import 'package:provider/provider.dart';

class TodosList extends StatefulWidget {
  const TodosList({super.key, required this.title});

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _TodosListState createState() => _TodosListState();
}

class _TodosListState extends State<TodosList> {
  late TodosViewModel _todosViewModel;

  @override
  void initState() {
    super.initState();
    _todosViewModel = TodosViewModel();
    _todosViewModel.fetchAndSetTodos();
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
        Todo todo = Todo(
          id: '',
          title: newTodo,
          done: false,
        );

        Todo addedTodo = await _todosViewModel.addTodo(todo);
        _todosViewModel.addTodoLocally(addedTodo);
      } catch (e) {
        if (kDebugMode) {
          print('Error adding todo: $e');
        }
      }
    }
  }

  void _deleteTodo(int index) async {
    String todoId = _todosViewModel.todos[index].id;
    try {
      await _todosViewModel.deleteTodo(todoId);
      _todosViewModel.removeTodoLocally(index);
    } catch (e) {
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
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _todosViewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Consumer<TodosViewModel>(
          builder: (context, todosViewModel, child) {
            return ListView.builder(
              itemCount: todosViewModel.todos.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildTodoItem(todosViewModel, index);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addTodo,
          tooltip: 'Add Todo',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTodoItem(TodosViewModel todosViewModel, int index) {
    final todo = todosViewModel.todos[index];
    return GestureDetector(
      onTap: () {
        setState(() {
          todo.markDone();
          todosViewModel.updateTodo(todo);
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
                todo.done = value ?? false;
                todosViewModel.updateTodo(todo);
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
