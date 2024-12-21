import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:to_do_list/repositories/todo_repository.dart';
import 'package:to_do_list/widgets/todo_list_item.dart';
import 'package:to_do_list/models/todo.dart';

class ToDoListPage extends StatefulWidget {
  //construtor
  const ToDoListPage({super.key});

  @override
  State<ToDoListPage> createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  final TextEditingController todoController = TextEditingController();
  final TodoRepository todoRepository = TodoRepository();

  //Lista de tarefas
  List<Todo> toDos = [];

  var logger = Logger(
    printer: PrettyPrinter(),
  );

  int? deletedIndex;
  String? errorText;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    todoRepository.getTodoList().then((value) {
      setState(() {
        toDos = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: todoController,
                        decoration: InputDecoration(
                          labelText: 'Adicione uma tarefa',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: Estudar',
                          errorText: errorText,
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                            color: const Color.fromARGB(255, 142, 62, 173),
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        String text = todoController.text;
                        if (text.isEmpty) {
                          setState(() {
                            errorText = 'Campo obrigatório';
                          });
                          return;
                        }
                        setState(() {
                          Todo newTodo = Todo(
                            title: text,
                            date: DateTime.now(),
                          );
                          toDos.add(newTodo);
                          errorText = null;
                          todoController.clear();
                          todoRepository.saveTodoList(toDos);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 142, 62, 173),
                        padding: const EdgeInsets.all(11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (Todo toDo in toDos)
                        TodoListItem(
                          todo: toDo,
                          onDelete: onDelete,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Voce possui ${toDos.length} tarefas pendentes',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: showDeleteAllConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 142, 62, 173),
                        padding: const EdgeInsets.all(11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: const Text(
                        'Deletar todos',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ///normalmente gera exceção chamar setState no build, mas
  ///neste caso é seguro pois a chamada é feita dentro de um
  ///evento de click, com isso o setState é chamado apenas no
  ///contexto (ver onpressed no todo_list_item.dart)
  ///quando o usuário clicar no botão de deletar tarefa
  void onDelete(Todo todo) {
    logger.i('Deletando tarefa');

    deletedIndex = toDos.indexOf(todo);

    setState(() {
      toDos.remove(todo);
    });
    todoRepository.saveTodoList(toDos);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tarefa ${todo.title} deletada com sucesso',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF8E3EAD),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            setState(() {
              toDos.insert(deletedIndex!, todo);
            });
            todoRepository.saveTodoList(toDos);
          },
        ),
      ),
    );
  }

  void showDeleteAllConfirmationDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Deseja deletar todas as tarefas?'),
              content: const Text(
                  'Esta ação não pode ser desfeita, você tem certeza?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    deleteAllTodos();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Deletar todos'),
                ),
              ],
            ));
  }

  void deleteAllTodos() {
    setState(() {
      toDos.clear();
    });
    todoRepository.saveTodoList(toDos);
  }
}
