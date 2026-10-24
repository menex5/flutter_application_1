import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tela_cadastro_evolucao.dart';

class TelaProntuario extends StatefulWidget {
  final Map<String, dynamic> paciente;
  final bool isFinalizado; // Adicionamos esta variável!

  const TelaProntuario({super.key, required this.paciente, this.isFinalizado = false});

  @override
  State<TelaProntuario> createState() => _TelaProntuarioState();
}

class _TelaProntuarioState extends State<TelaProntuario> {
  List<Map<String, dynamic>> evolucoes = [];

  @override
  void initState() {
    super.initState();
    _carregarEvolucoes();
  }

  void _carregarEvolucoes() async {
    final dados = await DatabaseHelper.instance.getEvolucoesDoPaciente(widget.paciente['id']);
    setState(() {
      evolucoes = dados;
    });
  }

  void _abrirCadastroSessao({Map<String, dynamic>? evolucao}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroEvolucao(
          pacienteId: widget.paciente['id'],
          evolucaoExistente: evolucao,
        ),
      ),
    );
    if (resultado == true) _carregarEvolucoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prontuário: ${widget.paciente['nome']}'),
        backgroundColor: widget.isFinalizado ? Colors.grey.shade700 : Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: evolucoes.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma sessão registrada ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: evolucoes.length,
              itemBuilder: (context, index) {
                final evolucao = evolucoes[index];
                
                final int dor = evolucao['nivel_dor'] ?? 0;
                Color corDor = Colors.green;
                if (dor >= 5 && dor <= 7) corDor = Colors.orange;
                if (dor > 7) corDor = Colors.red;

                return Dismissible(
                  key: Key(evolucao['id'].toString()),
                  // Se estiver finalizado, desabilita a função de arrastar
                  direction: widget.isFinalizado ? DismissDirection.none : DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar Exclusão'),
                        content: const Text('Tem certeza que deseja excluir esta sessão?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Excluir')),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await DatabaseHelper.instance.deletarEvolucao(evolucao['id']);
                    _carregarEvolucoes();
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sessão: ${evolucao['data_sessao']}', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: widget.isFinalizado ? Colors.grey : Colors.teal)
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: corDor.withAlpha((255 * 0.2).round()), borderRadius: BorderRadius.circular(10)),
                                    child: Text('Dor: $dor', style: TextStyle(color: corDor, fontWeight: FontWeight.bold)),
                                  ),
                                  // Esconde o botão de editar se estiver finalizado
                                  if (!widget.isFinalizado)
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                      onPressed: () => _abrirCadastroSessao(evolucao: evolucao),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              )
                            ],
                          ),
                          const Divider(),
                          const Text('Conduta:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          Text(evolucao['conduta'], style: const TextStyle(fontSize: 15)),
                          
                          if (evolucao['observacoes'] != null && evolucao['observacoes'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Observações:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            Text(evolucao['observacoes'], style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      // Esconde o botão '+' se o paciente estiver finalizado
      floatingActionButton: widget.isFinalizado 
          ? null 
          : FloatingActionButton(
              onPressed: () => _abrirCadastroSessao(),
              child: const Icon(Icons.add),
            ),
    );
  }
}