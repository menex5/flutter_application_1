import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';

class TelaCadastroPaciente extends StatefulWidget {
  final Map<String, dynamic>? pacienteExistente;

  const TelaCadastroPaciente({super.key, this.pacienteExistente});

  @override
  State<TelaCadastroPaciente> createState() => _TelaCadastroPacienteState();
}

class _TelaCadastroPacienteState extends State<TelaCadastroPaciente> {
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  
  String? _caminhoFoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.pacienteExistente != null) {
      _nomeController.text = widget.pacienteExistente!['nome'] ?? '';
      _telefoneController.text = widget.pacienteExistente!['telefone'] ?? '';
      _emailController.text = widget.pacienteExistente!['email'] ?? '';
      _localizacaoController.text = widget.pacienteExistente!['localizacao'] ?? '';
      _diagnosticoController.text = widget.pacienteExistente!['diagnostico'] ?? '';
      _caminhoFoto = widget.pacienteExistente!['foto'];
    }
  }

  Future<void> _escolherFoto() async {
    final XFile? fotoSelecionada = await _picker.pickImage(source: ImageSource.gallery);
    if (fotoSelecionada != null) {
      setState(() {
        _caminhoFoto = fotoSelecionada.path;
      });
    }
  }

  void _salvar() async {
    if (_nomeController.text.isEmpty || _diagnosticoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e Diagnóstico são obrigatórios!')),
      );
      return;
    }

    final dadosPaciente = {
      'nome': _nomeController.text,
      'telefone': _telefoneController.text,
      'email': _emailController.text,
      'localizacao': _localizacaoController.text,
      'diagnostico': _diagnosticoController.text,
      'foto': _caminhoFoto,
    };

    if (widget.pacienteExistente == null) {
      dadosPaciente['data_cadastro'] = DateTime.now().toIso8601String();
      await DatabaseHelper.instance.inserirPaciente(dadosPaciente);
    } else {
      await DatabaseHelper.instance.atualizarPaciente(widget.pacienteExistente!['id'], dadosPaciente);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pacienteExistente == null ? 'Novo Paciente' : 'Editar Paciente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _escolherFoto,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal.shade100,
                backgroundImage: _caminhoFoto != null ? FileImage(File(_caminhoFoto!)) : null,
                child: _caminhoFoto == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.teal)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Toque para adicionar foto'),
            const SizedBox(height: 20),
            TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _diagnosticoController, decoration: const InputDecoration(labelText: 'Diagnóstico Inicial *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _telefoneController, decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail (Gmail)', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            TextField(controller: _localizacaoController, decoration: const InputDecoration(labelText: 'Localização (Endereço)', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _salvar,
                child: const Text('Salvar Paciente', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}