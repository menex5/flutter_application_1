import 'dart:io';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tela_prontuario.dart';
import 'tela_cadastro_paciente.dart';
import 'tela_agenda.dart';
import 'tela_perfil_paciente.dart';

void main() {
  runApp(const FisioApp());
}

class FisioApp extends StatelessWidget {
  const FisioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fisiohub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TelaNavegacaoPrincipal(), // Mudamos a tela inicial para cá
    );
  }
}

// === NOVA TELA DE NAVEGAÇÃO COM BARRA INFERIOR ===
class TelaNavegacaoPrincipal extends StatefulWidget {
  const TelaNavegacaoPrincipal({super.key});

  @override
  State<TelaNavegacaoPrincipal> createState() => _TelaNavegacaoPrincipalState();
}

class _TelaNavegacaoPrincipalState extends State<TelaNavegacaoPrincipal> {
  int _indiceAtual = 0; // 0 = Agenda, 1 = Pacientes

  // Telas que serão exibidas
  final List<Widget> _telas = [
    const TelaAgenda(), // Vamos construir de verdade na Etapa 2
    const TelaPacientes(), // A tela de pacientes que já criamos
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (indice) {
          setState(() {
            _indiceAtual = indice;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Pacientes',
          ),
        ],
      ),
    );
  }
}

// === TELA DE PACIENTES (EXATAMENTE COMO VOCÊ JÁ TINHA FEITO) ===
class TelaPacientes extends StatefulWidget {
  const TelaPacientes({super.key});

  @override
  State<TelaPacientes> createState() => _TelaPacientesState();
}

class _TelaPacientesState extends State<TelaPacientes> {
  List<Map<String, dynamic>> pacientesTratando = [];
  List<Map<String, dynamic>> pacientesFinalizados = [];
  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _atualizarLista();
  }

  void _atualizarLista() async {
    final todosPacientes = await DatabaseHelper.instance.getTodosPacientes();
    final query = _buscaController.text.toLowerCase();
    
    setState(() {
      pacientesTratando = todosPacientes.where((p) {
        bool matchesSearch = p['nome'].toLowerCase().contains(query) || p['diagnostico'].toLowerCase().contains(query);
        return matchesSearch && p['status'] == 'tratando';
      }).toList();

      pacientesFinalizados = todosPacientes.where((p) {
        bool matchesSearch = p['nome'].toLowerCase().contains(query) || p['diagnostico'].toLowerCase().contains(query);
        return matchesSearch && p['status'] == 'finalizado';
      }).toList();
    });
  }

  void _abrirCadastro({Map<String, dynamic>? paciente}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaCadastroPaciente(pacienteExistente: paciente)),
    );
    if (resultado == true) _atualizarLista();
  }

  Widget _construirLista(List<Map<String, dynamic>> lista, bool isFinalizado) {
    if (lista.isEmpty) {
      return Center(child: Text(isFinalizado ? 'Nenhum paciente finalizado.' : 'Nenhum paciente em tratamento.', style: const TextStyle(fontSize: 16)));
    }

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final paciente = lista[index];
        final bool temFoto = paciente['foto'] != null && paciente['foto'].toString().isNotEmpty;

        return Dismissible(
          key: Key(paciente['id'].toString()),
          direction: DismissDirection.horizontal,
          background: Container(
            color: isFinalizado ? Colors.blue : Colors.green,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(isFinalizado ? Icons.replay : Icons.check_circle, color: Colors.white, size: 30),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 30),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar Exclusão'),
                  content: Text('Excluir ${paciente['nome']} e todo o histórico?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Excluir')),
                  ],
                ),
              );
            } else if (direction == DismissDirection.startToEnd) {
              bool confirmar = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(isFinalizado ? 'Retomar Tratamento' : 'Finalizar Tratamento'),
                  content: Text(isFinalizado 
                      ? 'Deseja voltar ${paciente['nome']} para a lista de Tratando?' 
                      : 'Deseja dar alta para ${paciente['nome']}? O prontuário será bloqueado para edições.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      style: TextButton.styleFrom(foregroundColor: isFinalizado ? Colors.blue : Colors.green), 
                      child: Text(isFinalizado ? 'Retomar' : 'Finalizar')
                    ),
                  ],
                ),
              ) ?? false;

              if (confirmar) {
                String novoStatus = isFinalizado ? 'tratando' : 'finalizado';
                await DatabaseHelper.instance.atualizarStatusPaciente(paciente['id'], novoStatus);
                return true;
              }
              return false;
            }
            return false;
          },
          onDismissed: (direction) async {
            if (direction == DismissDirection.endToStart) {
              await DatabaseHelper.instance.deletarPaciente(paciente['id']);
            }
            _atualizarLista();
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: isFinalizado ? Colors.grey.shade200 : Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isFinalizado ? Colors.grey.shade400 : Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: temFoto ? FileImage(File(paciente['foto'])) : null,
                child: !temFoto ? Text(paciente['nome'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)) : null,
              ),
              title: Text(paciente['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(paciente['diagnostico']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFinalizado) 
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () => _abrirCadastro(paciente: paciente),
                    ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: () {
                // AQUI ESTÁ A MUDANÇA MÁGICA:
                // Agora abre a TelaPerfilPaciente que tem o botão da câmara!
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TelaPerfilPaciente(paciente: paciente)),
                ).then((_) => _atualizarLista());
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Pacientes'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Tratando'),
              Tab(text: 'Finalizados'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _buscaController,
                onChanged: (_) => _atualizarLista(),
                decoration: InputDecoration(
                  labelText: 'Pesquisar paciente...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _construirLista(pacientesTratando, false),
                  _construirLista(pacientesFinalizados, true),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _abrirCadastro(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}