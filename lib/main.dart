import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //Para inserirmos elementos na lista usaremos o
  //TextEditingController
  final _toDoController = TextEditingController();

  //Iniciando uma lista vazia
  List _toDoList = [];

  //removendo uma tarefa.
  late Map<String, dynamic> _lastRemoved;

  //pegando a posição em que foi removido.
  late int _lastRemovedPos;

  //Para lermos os dados do nosso arquivo
  //sempre que o app for inicializado
  //temos que chamar o metodo _readData
  //dentro do initState
  @override
  void initState() {
    super.initState();

    //Como o readData retorna demora um pouco
    //retornando uma Future usaremos o then.
    _readData().then((value) {
      //Como o readData vai atualizar na tela temos que colocar
      //o _toDoList dentro do setState.
      setState(() {
        _toDoList = jsonDecode(value!);
      });
    });
  }

  void _addTodo() {
    //Criando um mapa vazio.
    //Sempre que estivermos trabalhando com json
    //temos que usar <String,dynamic> no Map.
    Map<String, dynamic> newTodo = {};

    setState(() {
      newTodo['title'] = _toDoController.text;

      _toDoController.text = "";

      newTodo['ok'] = false;

      _toDoList.add(newTodo);

      //Salvando os elementos da lista
      _saveData();
    });
  }

  //Como o refresh nao será tao
  //rapido assim usaremos uma Future
  //Ao arrastar a tela do celular para baixo
  //atualiza a lista de tarefas não
  //concluidas colocando como primeiras na lista.
  Future<Null> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        } else if (!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de tarefas 2'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ), //AppBar

      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                //Como o TextField tem uma largura infinita
                //temos que colocar dentro de um Expanded para
                //que o TextField pegue a largura maxima da tela.
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: const InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),

                ElevatedButton(
                  onPressed: (){
                    //Para não adicionar uma tarefa vazia
                    String text = _toDoController.text;

                    if(text.isEmpty)
                    {
                      return;
                    }
                    
                    _addTodo();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ADD'),
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
              //Para a lista de tarefas não ficar colada
              //com a linha do botão adiconar tarefa
              //iremos utilizar um padding
              padding: const EdgeInsets.only(top: 10.0),

              //Pegando o tamanho da lista.
              itemCount: _toDoList.length,

              itemBuilder: _buildItem,
            ), //ListView.builder,
          )), //Expanded
        ], //<Widget>[]
      ), //Column
    ); //Scaffold
  }

  //para facilitar a visualização do codigo dentro do ListView.builder
  //criaremos um novo método chamado _buildItem
  Widget _buildItem(BuildContext context, int index) {
    //O Dismissible permitira que deslizemos
    // a tarefa para o lado para remover.
    return Dismissible(
      //A key é obrigatoria entao podemos utilizar os milissegundos
      //do DateTime para a key
      key: Key(
          DateTime.now().millisecondsSinceEpoch.toString()), //CheckboxListTile

      background: Container(
        color: Colors.red,
        //Alinhando no canto esquerdo da tela
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ), //Container

      //Deletando da esquerda para a direita
      direction: DismissDirection.startToEnd,

      //Para adicionar um botão do lado da lista
      //de tarefas iremos utilizar o CheckBoxListTile
      child: CheckboxListTile(
        //Quando mostrar erro no CheckboxListTile
        //é por que o onChanged é obrigatório com parametro bool.
        onChanged: (bool? value) {
          setState(() {
            _toDoList[index]['ok'] = value;

            //Para Salvar uma tarefa como lida ou não lida
            //chamaremos aqui o método _saveData.
            _saveData();
          });
        }, //onChanged

        title: Text(_toDoList[index]['title']),

        value: _toDoList[index]['ok'],

        //Colocando um avatar do lado da lista
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
        ),
      ), //CheckboxListTile

      //Pegando o direction da
      //deleção da esquerda para a direita.
      onDismissed: (direction) {
        setState(() {
          //Duplicando a tarefa para salvar.
          _lastRemoved = Map.from(_toDoList[index]);

          //Pegando a posição da tarefa.
          _lastRemovedPos = index;

          //removendo pela posição.
          _toDoList.removeAt(index);

          //Atualizando a lista.
          _saveData();

          //Agora iremos colocar uma mensagen
          //que será exibida ao deletar as tarefas.
          final snackBar = SnackBar(
            content: Text("Tarefa \"${_lastRemoved['title']}\" removida!"),

            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);

                    //Salvando a alteração feita atualizando a lista.
                    _saveData();
                  });
                }), //SnackBarAction

            //Duração da mensagen Desfazer
            duration: const Duration(seconds: 2),
          ); //SnackBar

          //Remove pilha de Snackbars.
          ScaffoldMessenger.of(context).removeCurrentSnackBar();

          //Mostrando a mensagen.
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } //setState
            ); //onDismissed
      },
    );
  }

  //Método para pegar o arquivo
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();

    return File('${directory.path}/data.json');
  }

  //Método para Salvar o arquivo
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);

    final file = await _getFile();

    return file.writeAsString(data);
  }

//Método para ler o arquivo
  Future<String?> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
