import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';
import 'tela_prontuario.dart'; // <-- Adicionámos a importação do prontuário aqui!

class TelaPerfilPaciente extends StatefulWidget {
  final Map<String, dynamic> paciente;

  const TelaPerfilPaciente({super.key, required this.paciente});

  @override
  State<TelaPerfilPaciente> createState() => _TelaPerfilPacienteState();
}

class _TelaPerfilPacienteState extends State<TelaPerfilPaciente> {
  List<Map<String, dynamic>> _exames = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarExames();
  }

  Future<void> _carregarExames() async {
    final exames = await DatabaseHelper.instance.getExamesPorPaciente(widget.paciente['id']);
    setState(() {
      _exames = exames;
      _carregando = false;
    });
  }

  // Função para tirar foto ou escolher da galeria
  Future<void> _adicionarExame(ImageSource fonte) async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: fonte);

    if (foto != null) {
      // Pedir um título para o exame (ex: Raio-X Joelho)
      String? titulo = await _pedirTituloExame();
      
      if (titulo != null && titulo.isNotEmpty) {
        await DatabaseHelper.instance.inserirExame({
          'paciente_id': widget.paciente['id'],
          'titulo': titulo,
          'caminho_imagem': foto.path,
          'data_upload': DateTime.now().toIso8601String(),
        });
        _carregarExames();
      }
    }
  }

  Future<String?> _pedirTituloExame() {
    TextEditingController controle = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Título do Exame'),
        content: TextField(
          controller: controle,
          decoration: const InputDecoration(hintText: 'Ex: Raio-X Ombro Direito'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controle.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _apagarExame(int id) async {
    await DatabaseHelper.instance.deletarExame(id);
    _carregarExames();
  }

  @override
  Widget build(BuildContext context) {
    bool isFinalizado = widget.paciente['status'] == 'finalizado';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paciente['nome']),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com dados do paciente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diagnóstico: ${widget.paciente['diagnostico']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Telefone: ${widget.paciente['telefone'] ?? 'Não informado'}'),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // === NOVO BOTÃO PARA ACESSAR O PRONTUÁRIO ===
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaProntuario(
                        paciente: widget.paciente, 
                        isFinalizado: isFinalizado,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment),
                label: const Text(
                  'Acessar Prontuário e Evoluções',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Galeria de Exames',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
          const Divider(height: 1),
          
          // Lista de Exames
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _exames.isEmpty
                    ? const Center(child: Text('Nenhum exame anexado ainda.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _exames.length,
                        itemBuilder: (context, index) {
                          final exame = _exames[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.image, color: Colors.teal),
                              title: Text(exame['titulo']),
                              subtitle: const Text('Clique para ver a foto'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _apagarExame(exame['id']),
                              ),
                              onTap: () {
                                // Abrir a foto em ecrã inteiro
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.file(File(exame['caminho_imagem'])),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Mostrar opções de Câmara ou Galeria
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Tirar Fotografia'),
                    onTap: () {
                      Navigator.pop(context);
                      _adicionarExame(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Escolher da Galeria'),
                    onTap: () {
                      Navigator.pop(context);
                      _adicionarExame(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Novo Exame'),
      ),
    );
  }
}