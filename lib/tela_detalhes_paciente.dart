import 'dart:io';
import 'package:flutter/material.dart';
import 'tela_cadastro_paciente.dart'; // Importa a tela de edição para podermos editar a partir daqui

class TelaDetalhesPaciente extends StatelessWidget {
  final Map<String, dynamic> paciente;

  const TelaDetalhesPaciente({super.key, required this.paciente});

  @override
  Widget build(BuildContext context) {
    final String? caminhoFoto = paciente['foto'];
    final String nome = paciente['nome'] ?? 'Sem Nome';
    final String diagnostico = paciente['diagnostico'] ?? 'Nenhum diagnóstico';
    final String telefone = paciente['telefone'] ?? 'Não informado';
    final String email = paciente['email'] ?? 'Não informado';
    final String localizacao = paciente['localizacao'] ?? 'Não informada';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ficha do Paciente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- CABEÇALHO COM FOTO E NOME ---
            Container(
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: caminhoFoto != null ? FileImage(File(caminhoFoto)) : null,
                    child: caminhoFoto == null
                        ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nome,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CARD DIAGNÓSTICO ---
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.medical_information, color: Colors.white),
                      ),
                      title: const Text('Diagnóstico Inicial', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      subtitle: Text(
                        diagnostico,
                        style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- CARD CONTATOS E ENDEREÇO ---
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _construirLinhaDado(Icons.phone_outlined, 'Telefone', telefone),
                        const Divider(height: 1, indent: 60),
                        _construirLinhaDado(Icons.email_outlined, 'E-mail', email),
                        const Divider(height: 1, indent: 60),
                        _construirLinhaDado(Icons.location_on_outlined, 'Endereço', localizacao),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Botão flutuante para ir para a edição diretamente por aqui
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Abre a tela de cadastro passando os dados para edição
          final atualizou = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TelaCadastroPaciente(pacienteExistente: paciente),
            ),
          );
          
          if (atualizou == true) {
            // Se editou e salvou, volta para a lista para recarregar tudo
            if (context.mounted) Navigator.pop(context, true); 
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  // Função auxiliar para não repetir código visual
  Widget _construirLinhaDado(IconData icone, String titulo, String valor) {
    return ListTile(
      leading: Icon(icone, color: Colors.teal),
      title: Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      subtitle: Text(
        valor.isEmpty ? 'Não informado' : valor,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}