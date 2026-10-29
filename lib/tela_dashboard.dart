import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'tela_cadastro_paciente.dart';
import 'tela_lista_pacientes.dart';
// Caso a sua tela de lista de pacientes tenha outro nome, ajuste o import abaixo:
// import 'tela_lista_pacientes.dart'; 

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  int _totalPacientesAtivos = 0;
  int _atendimentosHoje = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() => _carregando = true);

    // Buscar Pacientes Ativos
    final pacientes = await DatabaseHelper.instance.getTodosPacientes();
    final ativos = pacientes.where((p) => p['status'] == 'tratando').length;

    // Buscar Agendamentos de Hoje
    String dataHoje = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final agendamentos = await DatabaseHelper.instance.getAgendamentosPorData(dataHoje);
    
    // Filtra apenas os agendamentos reais (ignora bloqueios sem paciente, se preferir)
    final reaisHoje = agendamentos.where((a) => a['paciente_id'] != null).length;

    setState(() {
      _totalPacientesAtivos = ativos;
      _atendimentosHoje = reaisHoje;
      _carregando = false;
    });
  }

  Widget _construirCardEstatistica(String titulo, String valor, IconData icone, Color cor) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: cor.withValues(alpha: 0.2),
                radius: 25,
                child: Icon(icone, color: cor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                valor,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Fisio App - Visão Geral'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarEstatisticas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo do Dia',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Cards de Estatísticas
                    Row(
                      children: [
                        _construirCardEstatistica(
                          'Pacientes Ativos',
                          _totalPacientesAtivos.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        _construirCardEstatistica(
                          'Consultas Hoje',
                          _atendimentosHoje.toString(),
                          Icons.event_available,
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Acesso Rápido',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Botões de Acesso Rápido
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.white,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.person_add, color: Colors.orange),
                      ),
                      title: const Text('Novo Paciente', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Cadastrar novo paciente no sistema'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TelaCadastroPaciente()),
                        );
                        _carregarEstatisticas();
                      },
                    ),
                    
                    // ==========================================
                    // ---> COLE O NOVO BOTÃO EXATAMENTE AQUI <---
                    // ==========================================
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.white,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.people, color: Colors.blue),
                      ),
                      title: const Text('Meus Pacientes', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Ver lista, perfis e exames'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TelaListaPacientes()),
                        );
                      },
                    ),
                    // ==========================================
                    
                  ], // <-- Fim da lista de botões (children)
                ),
              ),
            ),
    );
  }
}
