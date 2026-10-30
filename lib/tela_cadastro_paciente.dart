import 'dart:io';
import 'dart:convert'; // Para ler os dados do ViaCEP
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http; // Para buscar o CEP na internet
import 'database_helper.dart';

class TelaCadastroPaciente extends StatefulWidget {
  final Map<String, dynamic>? pacienteExistente;

  const TelaCadastroPaciente({super.key, this.pacienteExistente});

  @override
  State<TelaCadastroPaciente> createState() => _TelaCadastroPacienteState();
}

class _TelaCadastroPacienteState extends State<TelaCadastroPaciente> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  
  // Novos controllers para o endereço
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  
  String? _caminhoFoto;
  final ImagePicker _picker = ImagePicker();
  bool _buscandoCep = false; // Mostra um loading enquanto busca o CEP

  // Máscaras
  final mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy
  );
  
  final mascaraCep = MaskTextInputFormatter(
    mask: '#####-###', 
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
      _diagnosticoController.text = widget.pacienteExistente!['diagnostico'] ?? '';
      _caminhoFoto = widget.pacienteExistente!['foto'];
      
      // Como antes era tudo num campo só, colocamos no campo "Rua" provisoriamente
      _ruaController.text = widget.pacienteExistente!['localizacao'] ?? '';
    }
  }

  // Função mágica que busca o CEP
  Future<void> _buscarCep(String cep) async {
    String cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) return;

    setState(() => _buscandoCep = true);

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'));
      
      if (response.statusCode == 200) {
        final dados = json.decode(response.body);
        
        if (dados.containsKey('erro')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CEP não encontrado! Verifique o número.'), backgroundColor: Colors.red),
            );
          }
        } else {
          // Preenche os campos automaticamente se o CEP existir
          setState(() {
            _ruaController.text = dados['logradouro'] ?? '';
            _bairroController.text = dados['bairro'] ?? '';
            _cidadeController.text = dados['localidade'] ?? '';
            _estadoController.text = dados['uf'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão. Sem internet para buscar o CEP.')),
        );
      }
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _escolherFoto() async {
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Formata o endereço de volta para uma única string para salvar no banco de dados sem quebrar outras telas
    List<String> partesEndereco = [];
    if (_ruaController.text.isNotEmpty) {
      String ruaNum = _ruaController.text;
      if (_numeroController.text.isNotEmpty) ruaNum += ', ${_numeroController.text}';
      partesEndereco.add(ruaNum);
    }
    if (_bairroController.text.isNotEmpty) partesEndereco.add(_bairroController.text);
    if (_cidadeController.text.isNotEmpty) {
      String cidEst = _cidadeController.text;
      if (_estadoController.text.isNotEmpty) cidEst += ' - ${_estadoController.text}';
      partesEndereco.add(cidEst);
    }
    if (_cepController.text.isNotEmpty) partesEndereco.add('CEP: ${_cepController.text}');
    
    final localizacaoFormatada = partesEndereco.join(' | ');

    final dadosPaciente = {
      'nome': _nomeController.text,
      'telefone': _telefoneController.text,
      'email': _emailController.text,
      'localizacao': localizacaoFormatada,
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
      backgroundColor: Colors.grey[50],
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
              
              // --- ÁREA DA FOTO ---
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

              // --- DADOS PESSOAIS ---
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dados Pessoais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nome Completo *',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome do paciente' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _diagnosticoController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: 'Diagnóstico Inicial *',
                          prefixIcon: const Icon(Icons.medical_information_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Informe o diagnóstico' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- CONTATO E VALIDAÇÃO DE EMAIL ---
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contato', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [mascaraTelefone],
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
                        // VALIDAÇÃO DE EMAIL
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            // Expressão regular que checa se o formato é válido
                            final emailValido = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
                            if (!emailValido) {
                              return 'Por favor, digite um e-mail válido';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- ENDEREÇO COM BUSCA DE CEP ---
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Endereço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // CAMPO CEP
                      TextFormField(
                        controller: _cepController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [mascaraCep],
                        decoration: InputDecoration(
                          labelText: 'CEP',
                          hintText: '00000-000',
                          prefixIcon: const Icon(Icons.map_outlined),
                          suffixIcon: _buscandoCep 
                              ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (value) {
                          // Se digitar os 9 caracteres (8 números + 1 hífen), busca automático
                          if (value.length == 9) _buscarCep(value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // RUA E NÚMERO (Lado a lado)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7, // Ocupa 70% do espaço
                            child: TextFormField(
                              controller: _ruaController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Rua',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3, // Ocupa 30% do espaço
                            child: TextFormField(
                              controller: _numeroController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'Nº',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // BAIRRO
                      TextFormField(
                        controller: _bairroController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Bairro',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CIDADE E ESTADO (Lado a lado)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: TextFormField(
                              controller: _cidadeController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Cidade',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _estadoController,
                              textCapitalization: TextCapitalization.characters, // Estado fica tudo maiúsculo (SP, RJ)
                              maxLength: 2,
                              decoration: InputDecoration(
                                labelText: 'UF',
                                counterText: '', // Esconde o contador de "0/2" embaixo do campo
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // --- BOTÃO SALVAR ---
              FilledButton.icon(
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