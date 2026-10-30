import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'tela_cadastro_paciente.dart';
import 'tela_lista_pacientes.dart';
// Importa o ecrã de evolução para o botão "Iniciar Atendimento" funcionar
import 'tela_cadastro_evolucao.dart'; 

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  int _totalPacientesAtivos = 0;
  int _atendimentosHoje = 0;
  List<Map<String, dynamic>> _listaAgendamentosHoje = [];
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

    // Buscar Agendamentos de Hoje (verifica se o formato de data bate com o gravado no DB)
    // Se gravaste como yyyy-MM-dd no agendamento, altera aqui para: DateTime.now().toString().split(' ')[0]
    String dataHoje = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final agendamentos = await DatabaseHelper.instance.getAgendamentosPorData(dataHoje);
    
    // Filtra apenas os agendamentos reais (ignora bloqueios sem paciente)
    final reaisHoje = agendamentos.where((a) => a['paciente_id'] != null).toList();

    setState(() {
      _totalPacientesAtivos = ativos;
      _atendimentosHoje = reaisHoje.length;
      _listaAgendamentosHoje = reaisHoje; // Guardamos a lista para mostrar no ecrã
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

  // Novo método para construir a lista de consultas
  Widget _construirAgendaDoDia() {
    if (_listaAgendamentosHoje.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Sem pacientes agendados para hoje.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // O scroll é gerido pelo SingleChildScrollView principal
      itemCount: _listaAgendamentosHoje.length,
      itemBuilder: (context, index) {
        final agendamento = _listaAgendamentosHoje[index];
        final bool atendido = agendamento['status'] == 'concluido';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: atendido ? Colors.green.shade300 : Colors.transparent,
              width: 1.5,
            ),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          agendamento['horario'] ?? '--:--',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (atendido)
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('Concluído', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Pendente', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                  ],
                ),
                const Divider(),
                Text(
                  agendamento['nome'] ?? 'Paciente',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Diagnóstico: ${agendamento['diagnostico'] ?? 'Não informado'}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                if (!atendido) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Iniciar Atendimento', style: TextStyle(fontSize: 15)),
                      onPressed: () async {
                        // 1. Navega para a evolução e aguarda o resultado
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TelaCadastroEvolucao(
                              paciente: {
                                'id': agendamento['paciente_id'],
                                'nome': agendamento['nome'],
                                'diagnostico': agendamento['diagnostico'],
                              },
                            ),
                          ),
                        );
                        
                        // 2. Verifica se o atendimento foi realmente salvo
                        // Assumindo que a TelaCadastroEvolucao retorna 'true' quando salva com sucesso
                        if (resultado == true) {
                          // 3. Atualiza o status do agendamento para 'concluido' no banco de dados
                          await DatabaseHelper.instance.atualizarStatusAgendamento(
                            agendamento['id'], 
                            'concluido'
                          );
                        }
                        
                        // 4. Recarrega as estatísticas e a lista do dashboard
                        _carregarEstatisticas();
                      },
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
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
                    
                    const SizedBox(height: 32),
                    
                    // ==========================================
                    // NOVO BLOCO: AGENDA DE HOJE
                    // ==========================================
                    const Text(
                      'Agenda de Hoje',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _construirAgendaDoDia(),
                    // ==========================================
                    
                    const SizedBox(height: 30), // Espaço no final
                  ],
                ),
              ),
            ),
    );
  }
}