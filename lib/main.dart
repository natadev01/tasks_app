import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Modelo que representa una tarea
class Task {
  final int id;
  final String title;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    required this.completed,
  });

  Task copyWith({int? id, String? title, bool? completed}) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
    );
  }
}

// Servicio para consumir la API de tareas
class TasksApiService {
  // Asegúrate de que la URL base apunte a tu API
  final String baseUrl;
  TasksApiService({this.baseUrl = 'http://127.0.0.1:3000'});

  // Método para obtener la lista de tareas
  Future<List<Task>> getTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/tasks'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((task) => Task.fromJson(task)).toList();
    } else {
      throw Exception('Error al cargar las tareas');
    }
  }

  // Método para crear una nueva tarea
  Future<Task> createTask(String title) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title, 'completed': false}),
    );

    if (response.statusCode == 201) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear la tarea');
    }
  }

  // Método para actualizar una tarea
  Future<Task> updateTask(Task task) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/${task.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': task.title, 'completed': task.completed}),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar la tarea');
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskListPage(),
    );
  }
}

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TasksApiService apiService = TasksApiService();
  late Future<List<Task>> futureTasks;

  @override
  void initState() {
    super.initState();
    futureTasks = apiService.getTasks();
  }

  void refreshTasks() {
    setState(() {
      futureTasks = apiService.getTasks();
    });
  }

  // Diálogo para agregar tarea nueva
  void _showAddTaskDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Tarea'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Título de la tarea',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Agregar'),
            onPressed: () async {
              if (_controller.text.isNotEmpty) {
                await apiService.createTask(_controller.text);
                Navigator.of(context).pop();
                refreshTasks();
              }
            },
          ),
        ],
      ),
    );
  }

  // Diálogo para editar una tarea existente
void _showEditTaskDialog(Task task) {
  final TextEditingController _controller = TextEditingController(text: task.title);
  bool completedValue = task.completed;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Editar Tarea'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Título de la tarea',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Completada'),
                    Checkbox(
                      value: completedValue,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          completedValue = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: const Text('Actualizar'),
                onPressed: () async {
                  if (_controller.text.isNotEmpty) {
                    Task updatedTask = task.copyWith(
                      title: _controller.text,
                      completed: completedValue,
                    );
                    await apiService.updateTask(updatedTask);
                    Navigator.of(context).pop();
                    refreshTasks();
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

  // Construcción de la lista de tareas
  Widget buildTaskList(List<Task> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task.title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                task.completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: task.completed ? Colors.green : null,
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditTaskDialog(task);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: FutureBuilder<List<Task>>(
        future: futureTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar tareas'));
          }
          if (snapshot.hasData) {
            return buildTaskList(snapshot.data!);
          }
          return const Center(child: Text('No hay tareas'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
