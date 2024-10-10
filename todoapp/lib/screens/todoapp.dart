import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todoapp/model/taskmodel.dart';

class TodoT extends StatefulWidget {
  const TodoT({super.key});

  @override
  State<TodoT> createState() => _TodoState();
}

class _TodoState extends State<TodoT> {
  TextEditingController addController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String selectedPriority = 'High';
  List<taskmodel> tasks = [];
  String? filterPriority;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      final response = await http.get(Uri.parse(
          "https://crudcrud.com/api/d19f249392ac4f01b9186842d3a8f326/unicorns"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          tasks = data.map((item) => taskmodel.fromJson(item)).toList();
          _sortTasks();
          _filterTasks();
        });
      } else {
        _showAlertDialog("Error", "Failed to fetch tasks");
      }
    } catch (e) {
      _showAlertDialog("Error", "Failed to load tasks: $e");
    }
  }

  Future<void> postData(Map<String, dynamic> taskMap) async {
    try {
      print("Sending Task Data: $taskMap");

      final response = await http.post(
        Uri.parse(
            'https://crudcrud.com/api/d19f249392ac4f01b9186842d3a8f326/unicorns'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(taskMap),
      );

      print("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        fetchTasks();
        addController.clear();
        descriptionController.clear();
        setState(() {
          selectedPriority = 'High';
        });
      } else {
        _showAlertDialog("Error",
            "Failed to add task. Status: ${response.statusCode}, Response: ${response.body}");
      }
    } catch (e) {
      _showAlertDialog("Error", "Failed to add task: $e");
    }
  }

  Future<void> updateData(String id, Map<String, dynamic> userdata) async {
    try {
      final response = await http.put(
        Uri.parse(
            'https://crudcrud.com/api/d19f249392ac4f01b9186842d3a8f326/unicorns/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userdata),
      );
      if (response.statusCode == 200) {
        fetchTasks();
      } else {
        _showAlertDialog("Error", "Failed to update task");
      }
    } catch (e) {
      _showAlertDialog("Error", "Failed to update task: $e");
    }
  }

  Future<void> deleteData(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'https://crudcrud.com/api/d19f249392ac4f01b9186842d3a8f326/unicorns/$id'),
      );
      if (response.statusCode == 200) {
        fetchTasks();
      } else {
        _showAlertDialog("Error", "Failed to delete task");
      }
    } catch (e) {
      _showAlertDialog("Error", "Failed to delete task: $e");
    }
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(BuildContext context, taskmodel task) {
    addController.text = task.taskname ?? '';
    descriptionController.text = task.description ?? '';
    selectedPriority = task.priority ?? 'High';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: addController,
                decoration: const InputDecoration(hintText: "Enter task name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(hintText: "Enter description"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                items: const [
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedPriority = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                if (addController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  updateData(task.sId!, {
                    'taskname': addController.text,
                    'description': descriptionController.text,
                    'priority': selectedPriority,
                  });
                  Navigator.of(context).pop();
                  addController.clear();
                  descriptionController.clear();
                } else {
                  _showAlertDialog(
                      "Error", "Please fill all the fields before updating.");
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _sortTasks() {
    tasks.sort((a, b) {
      int priorityComparison =
          _priorityValue(a.priority).compareTo(_priorityValue(b.priority));
      return sortAscending ? priorityComparison : -priorityComparison;
    });
  }

  int _priorityValue(String? priority) {
    switch (priority?.toLowerCase()) { // Normalize case
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  void _filterTasks() {
    if (filterPriority != null) {
      tasks = tasks.where((task) => task.priority?.toLowerCase() == filterPriority?.toLowerCase()).toList();
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Filter by Priority"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                onTap: () {
                  setState(() {
                    filterPriority = null;
                    fetchTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('High'),
                onTap: () {
                  setState(() {
                    filterPriority = 'high';
                    fetchTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Medium'),
                onTap: () {
                  setState(() {
                    filterPriority = 'medium';
                    fetchTasks();
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Low'),
                onTap: () {
                  setState(() {
                    filterPriority = 'low';
                    fetchTasks();
                  });
                  Navigator.of(context).pop();
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
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Todo App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon:
                Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() {
                sortAscending = !sortAscending;
                _sortTasks();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: addController,
              decoration: const InputDecoration(
                labelText: "Task Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                prefixIcon: Icon(Icons.task),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPriority,
              items: const [
                DropdownMenuItem(value: 'High', child: Text('High')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'Low', child: Text('Low')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPriority = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (addController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  postData({
                    'taskname': addController.text,
                    'description': descriptionController.text,
                    'priority': selectedPriority,
                  });
                } else {
                  _showAlertDialog(
                      "Error", "Please fill all the fields before adding.");
                }
              },
              child: const Text("Add Task"),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(tasks[index].taskname ?? ''),
                      subtitle: Text(tasks[index].description ?? ''),
                      trailing: Text(tasks[index].priority ?? ''),
                      onTap: () {
                        _showUpdateDialog(context, tasks[index]);
                      },
                      onLongPress: () {
                        deleteData(tasks[index].sId!);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
