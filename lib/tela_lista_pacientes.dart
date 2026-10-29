import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tela_perfil_paciente.dart';

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
            .where((p) => p['nome'].toString().toLowerCase().contains(texto.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pacientes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _pesquisaController,
              onChanged: _filtrarPacientes,
              decoration: InputDecoration(
                labelText: 'Pesquisar paciente por nome',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _pacientesFiltrados.isEmpty
                ? const Center(child: Text('Nenhum paciente encontrado.'))
                : ListView.builder(
                    itemCount: _pacientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final paciente = _pacientesFiltrados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            child: Text(
                              paciente['nome'][0].toUpperCase(),
                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          title: Text(paciente['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Diagnóstico: ${paciente['diagnostico']}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Abre o perfil com os Exames!
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TelaPerfilPaciente(paciente: paciente),
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