import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'tela_perfil_paciente.dart';
import 'tela_detalhes_paciente.dart';

class TelaListaPacientes extends StatefulWidget {
  const TelaListaPacientes({super.key});

  @override
  State<TelaListaPacientes> createState() => _TelaListaPacientesState();
}

class _TelaListaPacientesState extends State<TelaListaPacientes> {
  List<Map<String, dynamic>> _todosPacientes = [];
  List<Map<String, dynamic>> _pacientesFiltrados = [];
  final TextEditingController _pesquisaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPacientes();
  }

  Future<void> _carregarPacientes() async {
    final pacientes = await DatabaseHelper.instance.getTodosPacientes();
    if (!mounted) return;
    setState(() {
      _todosPacientes = pacientes;
      _pacientesFiltrados = pacientes;
    });
  }

  void _filtrarPacientes(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _pacientesFiltrados = _todosPacientes;
      } else {
        _pacientesFiltrados = _todosPacientes
            .where(
              (p) => p['nome'].toString().toLowerCase().contains(
                texto.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Meus Pacientes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // BARRA DE PESQUISA
          Container(
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: TextField(
              controller: _pesquisaController,
              onChanged: _filtrarPacientes,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar paciente...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // LISTA DE PACIENTES
          Expanded(
            child: _pacientesFiltrados.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum paciente encontrado.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _pacientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final paciente = _pacientesFiltrados[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),

                          // Avatar do Paciente
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              paciente['nome'][0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),

                          // Nome e Diagnóstico
                          title: Text(
                            paciente['nome'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(
                              top: 4.0,
                            ), // <-- ERRO CORRIGIDO AQUI
                            child: Text(
                              'Diagnóstico: ${paciente['diagnostico']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // BOTÕES À DIREITA (Visualizar e Setinha)
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: Colors.teal,
                                ),
                                tooltip: 'Ver dados do paciente',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TelaDetalhesPaciente(
                                            paciente: paciente,
                                          ),
                                    ),
                                  ).then((atualizou) {
                                    if (atualizou == true) _carregarPacientes();
                                  });
                                },
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),

                          // Ao clicar no paciente inteiro, vai para o Perfil (Exames/Evoluções)
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TelaPerfilPaciente(paciente: paciente),
                              ),
                            ).then((_) => _carregarPacientes());
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
