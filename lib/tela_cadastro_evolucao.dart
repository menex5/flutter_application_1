import 'package:flutter/material.dart';
import 'database_helper.dart';

class TelaCadastroEvolucao extends StatefulWidget {
  final Map<String, dynamic> paciente;
  final Map<String, dynamic>? evolucaoExistente;

  const TelaCadastroEvolucao({
    super.key,
    required this.paciente,
    this.evolucaoExistente,
  });

  @override
  State<TelaCadastroEvolucao> createState() => _TelaCadastroEvolucaoState();
}

class _TelaCadastroEvolucaoState extends State<TelaCadastroEvolucao> {
  double _nivelDor = 5;
  final TextEditingController _condutaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  // Modelos de conduta rápida
  final List<String> _atendimentosRapidos = [
    'Crioterapia',
    'Ultrassom 3min',
    'TENS / FES',
    'Liberação Miofascial',
    'Cinesioterapia',
    'Mobilização Articular',
    'Exercícios de Fortalecimento',
    'Treino de Propriocepção',
    'Alongamento Passivo',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.evolucaoExistente != null) {
      _nivelDor = (widget.evolucaoExistente!['nivel_dor'] ?? 5).toDouble();
      _condutaController.text = widget.evolucaoExistente!['conduta'] ?? '';
      _observacoesController.text = widget.evolucaoExistente!['observacoes'] ?? '';
    }
  }

  void _adicionarCondutaRapida(String texto) {
    if (_condutaController.text.isEmpty) {
      _condutaController.text = texto;
    } else {
      _condutaController.text += ', $texto';
    }
    _condutaController.selection = TextSelection.fromPosition(
      TextPosition(offset: _condutaController.text.length),
    );
  }

  void _salvarEvolucao() async {
    if (_condutaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe a conduta realizada.')),
      );
      return;
    }

    String dataAtual = DateTime.now().toString().split(' ')[0]; // yyyy-MM-dd

    Map<String, dynamic> dadosEvolucao = {
      'paciente_id': widget.paciente['id'],
      'data_sessao': dataAtual,
      'nivel_dor': _nivelDor.toInt(),
      'conduta': _condutaController.text.trim(),
      'observacoes': _observacoesController.text.trim(),
    };

    if (widget.evolucaoExistente != null) {
      await DatabaseHelper.instance.atualizarEvolucao(
        widget.evolucaoExistente!['id'],
        dadosEvolucao,
      );
    } else {
      await DatabaseHelper.instance.inserirEvolucao(dadosEvolucao);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdicao = widget.evolucaoExistente != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Evolução' : 'Nova Evolução'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paciente: ${widget.paciente['nome']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Nível de Dor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nível de Dor:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(
                  '${_nivelDor.toInt()} / 10',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _nivelDor > 7
                        ? Colors.red
                        : (_nivelDor > 3 ? Colors.orange : Colors.green),
                  ),
                ),
              ],
            ),
            Slider(
              value: _nivelDor,
              min: 0,
              max: 10,
              divisions: 10,
              label: _nivelDor.toInt().toString(),
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (novoValor) {
                setState(() => _nivelDor = novoValor);
              },
            ),
            const SizedBox(height: 15),

            // Condutas Rápidas (Chips)
            const Text('Condutas Rápidas:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _atendimentosRapidos.map((conduta) {
                return ActionChip(
                  label: Text(conduta),
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                  onPressed: () => _adicionarCondutaRapida(conduta),
                );
              }).toList(),
            ),
            const SizedBox(height: 15),

            // Campo de Conduta
            TextField(
              controller: _condutaController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Conduta Realizada *',
                hintText: 'Descreva os exercícios e procedimentos realizados',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // Campo de Observações
            TextField(
              controller: _observacoesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Ex: Paciente relatou melhora ao caminhar',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _salvarEvolucao,
                child: Text(
                  isEdicao ? 'Salvar Alterações' : 'Cadastrar Evolução',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}