import 'package:flutter/material.dart';
import 'database_helper.dart';

class TelaCadastroEvolucao extends StatefulWidget {
  final int pacienteId;
  final Map<String, dynamic>? evolucaoExistente;

  const TelaCadastroEvolucao({super.key, required this.pacienteId, this.evolucaoExistente});

  @override
  State<TelaCadastroEvolucao> createState() => _TelaCadastroEvolucaoState();
}

class _TelaCadastroEvolucaoState extends State<TelaCadastroEvolucao> {
  final _condutaController = TextEditingController();
  final _observacoesController = TextEditingController();
  double _nivelDor = 0; // Vai de 0 a 10

  @override
  void initState() {
    super.initState();
    if (widget.evolucaoExistente != null) {
      _condutaController.text = widget.evolucaoExistente!['conduta'] ?? '';
      _observacoesController.text = widget.evolucaoExistente!['observacoes'] ?? '';
      _nivelDor = (widget.evolucaoExistente!['nivel_dor'] ?? 0).toDouble();
    }
  }

  void _salvarSessao() async {
    if (_condutaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A conduta/tratamento é obrigatória!')),
      );
      return;
    }

    final dadosSessao = {
      'paciente_id': widget.pacienteId,
      'nivel_dor': _nivelDor.toInt(),
      'conduta': _condutaController.text,
      'observacoes': _observacoesController.text,
    };

    if (widget.evolucaoExistente == null) {
      // Pega a data formatada
      final agora = DateTime.now();
      dadosSessao['data_sessao'] = "${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year}";
      
      await DatabaseHelper.instance.inserirEvolucao(dadosSessao);
    } else {
      await DatabaseHelper.instance.atualizarEvolucao(widget.evolucaoExistente!['id'], dadosSessao);
    }

    if (mounted) Navigator.pop(context, true); // Retorna 'true' para avisar que salvou
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evolucaoExistente == null ? 'Nova Sessão' : 'Editar Sessão'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Escala de Dor
            const Text('Nível de Dor Hoje (0 a 10):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.sentiment_very_satisfied, color: Colors.green),
                Expanded(
                  child: Slider(
                    value: _nivelDor,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: _nivelDor > 7 ? Colors.red : (_nivelDor > 4 ? Colors.orange : Colors.green),
                    label: _nivelDor.round().toString(),
                    onChanged: (double valor) {
                      setState(() {
                        _nivelDor = valor;
                      });
                    },
                  ),
                ),
                const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red),
              ],
            ),
            Center(
              child: Text(
                'Dor: ${_nivelDor.round()}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _nivelDor > 7 ? Colors.red : Colors.black),
              ),
            ),
            const SizedBox(height: 25),

            // Conduta
            const Text('Conduta / Exercícios *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _condutaController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ex: TENS lombar (20min), Alongamento de isquiotibiais, Fortalecimento de core...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Observações
            const Text('Observações / Relato do Paciente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Paciente relatou melhora na fisgada matinal. Sentiu fadiga no final.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _salvarSessao,
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                child: const Text('Salvar Prontuário', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}