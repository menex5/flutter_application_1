import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Importante para a máscara do telefone
import 'database_helper.dart';

class TelaCadastroPaciente extends StatefulWidget {
  final Map<String, dynamic>? pacienteExistente;

  const TelaCadastroPaciente({super.key, this.pacienteExistente});

  @override
  State<TelaCadastroPaciente> createState() => _TelaCadastroPacienteState();
}

class _TelaCadastroPacienteState extends State<TelaCadastroPaciente> {
  final _formKey = GlobalKey<FormState>(); // Para validações

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  
  String? _caminhoFoto;
  final ImagePicker _picker = ImagePicker();

  // Máscara para telefone no formato (11) 98888-7777 ou (11) 8888-7777
  final mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy
  );

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
    // Opção para escolher entre Câmera ou Galeria
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto com a câmera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
                if (foto != null) setState(() => _caminhoFoto = foto.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? foto = await _picker.pickImage(source: ImageSource.gallery);
                if (foto != null) setState(() => _caminhoFoto = foto.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _salvar() async {
    // Valida o formulário antes de salvar
    if (!_formKey.currentState!.validate()) {
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
      backgroundColor: Colors.grey[50], // Fundo levemente cinza para destacar os cards
      appBar: AppBar(
        title: Text(widget.pacienteExistente == null ? 'Novo Paciente' : 'Editar Paciente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // --- ÁREA DA FOTO DE PERFIL ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      backgroundImage: _caminhoFoto != null ? FileImage(File(_caminhoFoto!)) : null,
                      child: _caminhoFoto == null
                          ? Icon(Icons.person, size: 55, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 20,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          onPressed: _escolherFoto,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- CARD: DADOS PESSOAIS ---
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dados Pessoais', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _nomeController,
                        textCapitalization: TextCapitalization.words, // Primeira letra sempre maiúscula
                        decoration: InputDecoration(
                          labelText: 'Nome Completo *',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Informe o nome do paciente' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _diagnosticoController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null, // Permite quebrar linha se o texto for grande
                        decoration: InputDecoration(
                          labelText: 'Diagnóstico Inicial *',
                          prefixIcon: const Icon(Icons.medical_information_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Informe o diagnóstico' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- CARD: CONTATO E LOCALIZAÇÃO ---
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contato e Localização', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [mascaraTelefone], // Aplica a máscara
                        decoration: InputDecoration(
                          labelText: 'Telefone',
                          hintText: '(00) 00000-0000',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _localizacaoController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Endereço Completo',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // --- BOTÃO SALVAR ---
              FilledButton.icon( // FilledButton é mais moderno que o ElevatedButton tradicional
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar Cadastro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _salvar,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}