import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tela_prontuario.dart';
import 'tela_cadastro_paciente.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class TelaAgenda extends StatefulWidget {
  const TelaAgenda({super.key});

  @override
  State<TelaAgenda> createState() => _TelaAgendaState();
}

class _TelaAgendaState extends State<TelaAgenda> {
  CalendarFormat _formatoCalendario = CalendarFormat.month;
  DateTime _dataFocada = DateTime.now();
  DateTime? _dataSelecionada;
  
  List<Map<String, dynamic>> _agendamentos = [];

  @override
  void initState() {
    super.initState();
    _dataSelecionada = _dataFocada;
    _carregarAgendamentos();
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  void _carregarAgendamentos() async {
    if (_dataSelecionada != null) {
      String dataStr = _formatarData(_dataSelecionada!);
      final dados = await DatabaseHelper.instance.getAgendamentosPorData(dataStr);
      setState(() {
        _agendamentos = dados;
      });
    }
  }

  Future<void> _enviarConfirmacaoWhatsApp(String telefone, String nomePaciente, String dataStr, String horaStr, String tipo) async {
    if (telefone.isEmpty) return;
    
    String numLimpo = telefone.replaceAll(RegExp(r'\D'), '');
    String mensagem = 'Olá $nomePaciente! Confirmamos sua consulta de $tipo para o dia $dataStr às $horaStr. Por favor, responda para confirmar.';
    String mensagemEncoded = Uri.encodeComponent(mensagem);

    final uriApp = Uri.parse('whatsapp://send?phone=55$numLimpo&text=$mensagemEncoded');
    final uriWeb = Uri.parse('https://wa.me/55$numLimpo?text=$mensagemEncoded');

    try {
      if (await canLaunchUrl(uriApp)) {
        await launchUrl(uriApp);
      } else {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp para enviar a mensagem.')),
        );
      }
    }
  }

  Color _corDoTipo(String? tipo) {
    switch (tipo) {
      case 'Avaliação':
        return Colors.blue;
      case 'Retorno':
        return Colors.purple;
      case 'Emergência':
        return Colors.red;
      case 'Almoço':
      case 'Reunião':
      case 'Folga':
      case 'Bloqueio':
        return Colors.grey.shade700;
      case 'Rotina':
      default:
        return Colors.teal;
    }
  }

  void _mostrarDialogoNovoAgendamento() async {
    final todosPacientes = await DatabaseHelper.instance.getTodosPacientes();
    final pacientesAtivos = todosPacientes.where((p) => p['status'] == 'tratando').toList();

    String? pacienteSelecionadoId = pacientesAtivos.isNotEmpty ? pacientesAtivos.first['id'].toString() : null;
    TimeOfDay horarioSelecionado = TimeOfDay.now();
    bool isBloqueio = false;
    String tipoSelecionado = 'Rotina';
    String tipoBloqueio = 'Almoço';
    
    // Passo 7: Controller para capturar a observação rápida
    final TextEditingController observacaoController = TextEditingController();

    final tiposAtendimento = ['Avaliação', 'Retorno', 'Rotina', 'Emergência'];
    final tiposBloqueio = ['Almoço', 'Reunião', 'Folga', 'Bloqueio'];

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('Novo Agendamento'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Paciente'),
                              selected: !isBloqueio,
                              onSelected: (selected) {
                                if (selected) setStateDialog(() => isBloqueio = false);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Bloqueio'),
                              selected: isBloqueio,
                              onSelected: (selected) {
                                if (selected) setStateDialog(() => isBloqueio = true);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      if (!isBloqueio) ...[
                        if (pacientesAtivos.isEmpty)
                          const Text('Nenhum paciente em tratamento cadastrado.', style: TextStyle(color: Colors.red))
                        else ...[
                          const Text('Paciente:', style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: pacienteSelecionadoId,
                            isExpanded: true,
                            items: pacientesAtivos.map((p) {
                              return DropdownMenuItem<String>(
                                value: p['id'].toString(),
                                child: Text(p['nome']),
                              );
                            }).toList(),
                            onChanged: (valor) {
                              setStateDialog(() {
                                pacienteSelecionadoId = valor;
                              });
                            },
                          ),
                          const SizedBox(height: 15),
                          const Text('Tipo de Atendimento:', style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: tipoSelecionado,
                            isExpanded: true,
                            items: tiposAtendimento.map((tipo) {
                              return DropdownMenuItem<String>(
                                value: tipo,
                                child: Text(tipo),
                              );
                            }).toList(),
                            onChanged: (valor) {
                              if (valor != null) {
                                setStateDialog(() {
                                  tipoSelecionado = valor;
                                });
                              }
                            },
                          ),
                        ]
                      ] else ...[
                        const Text('Motivo do Bloqueio:', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: tipoBloqueio,
                          isExpanded: true,
                          items: tiposBloqueio.map((tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo),
                            );
                          }).toList(),
                          onChanged: (valor) {
                            if (valor != null) {
                              setStateDialog(() {
                                tipoBloqueio = valor;
                              });
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: 15),
                      // Passo 7: Campo para digitar a observação rápida
                      TextField(
                        controller: observacaoController,
                        decoration: const InputDecoration(
                          labelText: 'Observação Rápida (opcional)',
                          hintText: 'Ex: Trazer exames, Focar na dor lombar',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Horário: ${horarioSelecionado.format(context)}', style: const TextStyle(fontSize: 16)),
                          ElevatedButton(
                            onPressed: () async {
                              final BuildContext pickerContext = context;
                              final TimeOfDay? tempo = await showTimePicker(
                                context: pickerContext,
                                initialTime: horarioSelecionado,
                              );
                              if (!pickerContext.mounted) return;
                              if (tempo != null) {
                                setStateDialog(() {
                                  horarioSelecionado = tempo;
                                });
                              }
                            },
                            child: const Text('Mudar'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                    onPressed: (!isBloqueio && pacientesAtivos.isEmpty) ? null : () async {
                      final BuildContext dialogContext = context;
                      String horaStr = '${horarioSelecionado.hour.toString().padLeft(2, '0')}:${horarioSelecionado.minute.toString().padLeft(2, '0')}';
                      String dataStr = _formatarData(_dataSelecionada!);
                      String obsStr = observacaoController.text.trim();

                      bool existeConflito = _agendamentos.any((a) => a['horario'] == horaStr);

                      if (existeConflito) {
                        bool? confirmarConflito = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Horário Ocupado!'),
                            content: Text('Já existe um agendamento ou bloqueio às $horaStr. Deseja agendar mesmo assim?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Voltar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Confirmar Assim Mesmo'),
                              ),
                            ],
                          ),
                        );

                        if (confirmarConflito != true) return;
                      }

                      if (isBloqueio) {
                        Map<String, dynamic> dadosBloqueio = {
                          'data_agendamento': dataStr,
                          'horario': horaStr,
                          'status': 'realizado',
                          'tipo_atendimento': tipoBloqueio,
                          'observacao': obsStr.isNotEmpty ? obsStr : null,
                        };

                        await DatabaseHelper.instance.inserirAgendamento(dadosBloqueio);

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _carregarAgendamentos();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Horário bloqueado com sucesso!')),
                          );
                        }
                      } else {
                        await DatabaseHelper.instance.inserirAgendamento({
                          'paciente_id': int.parse(pacienteSelecionadoId!),
                          'data_agendamento': dataStr,
                          'horario': horaStr,
                          'status': 'pendente',
                          'tipo_atendimento': tipoSelecionado,
                          'observacao': obsStr.isNotEmpty ? obsStr : null,
                        });
                        
                        final pacienteAgendado = pacientesAtivos.firstWhere(
                          (p) => p['id'].toString() == pacienteSelecionadoId,
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _carregarAgendamentos();

                        if (mounted && pacienteAgendado['telefone'] != null && pacienteAgendado['telefone'].toString().isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Enviar Confirmação?'),
                              content: Text('Deseja enviar mensagem no WhatsApp para ${pacienteAgendado['nome']}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Não'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _enviarConfirmacaoWhatsApp(
                                      pacienteAgendado['telefone'].toString(),
                                      pacienteAgendado['nome'].toString(),
                                      dataStr,
                                      horaStr,
                                      tipoSelecionado,
                                    );
                                  },
                                  child: const Text('Enviar'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    child: Text(isBloqueio ? 'Bloquear' : 'Agendar'),
                  ),
                ],
              );
            }
          );
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _dataFocada,
            calendarFormat: _formatoCalendario,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mês',
              CalendarFormat.twoWeeks: '2 Semanas',
              CalendarFormat.week: 'Semana'
            },
            selectedDayPredicate: (day) => isSameDay(_dataSelecionada, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _dataSelecionada = selectedDay;
                _dataFocada = focusedDay;
              });
              _carregarAgendamentos();
            },
            onFormatChanged: (format) {
              if (_formatoCalendario != format) {
                setState(() => _formatoCalendario = format);
              }
            },
          ),
          
          const Divider(thickness: 2),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('Pendente', style: TextStyle(fontWeight: FontWeight.w500)),
                
                const SizedBox(width: 24),
                
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('Realizado', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          
          Expanded(
            child: _agendamentos.isEmpty
                ? const Center(child: Text('Nenhum agendamento para este dia.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
                    itemCount: _agendamentos.length,
                    itemBuilder: (context, index) {
                      final agendamento = _agendamentos[index];
                      final bool isBloqueio = agendamento['paciente_id'] == null;
                      
                      final bool temFoto = !isBloqueio && agendamento['foto'] != null && agendamento['foto'].toString().isNotEmpty;
                      String tipo = agendamento['tipo_atendimento'] ?? (isBloqueio ? 'Bloqueio' : 'Rotina');
                      String? observacao = agendamento['observacao'];
                      Color corStatus = agendamento['status'] == 'realizado' ? Colors.green : Colors.orange;

                      String nomePaciente = agendamento['nome'] ?? '';
                      String inicialNome = nomePaciente.isNotEmpty ? nomePaciente[0].toUpperCase() : '?';

                      String titulo = isBloqueio
                          ? '${agendamento['horario']} - $tipo'
                          : '${agendamento['horario']} - $nomePaciente';

                      return Dismissible(
                        key: Key(agendamento['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: Text(isBloqueio ? 'Excluir Bloqueio' : 'Excluir Agendamento'),
                                content: Text(isBloqueio ? 'Deseja remover este bloqueio de horário?' : 'Tem certeza que deseja excluir esta consulta?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    child: const Text('Excluir'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) async {
                          await DatabaseHelper.instance.deletarAgendamento(agendamento['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isBloqueio ? 'Bloqueio removido!' : 'Agendamento excluído!')),
                            );
                          }
                          _carregarAgendamentos();
                        },
                        child: Card(
                          color: isBloqueio ? Colors.grey.shade100 : null,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: isBloqueio
                                ? CircleAvatar(
                                    backgroundColor: Colors.grey.shade400,
                                    child: const Icon(Icons.block, color: Colors.white),
                                  )
                                : CircleAvatar(
                                    backgroundImage: temFoto ? FileImage(File(agendamento['foto'])) : null,
                                    child: !temFoto ? Text(inicialNome, style: const TextStyle(fontWeight: FontWeight.bold)) : null,
                                  ),
                            title: Text(
                              titulo, 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                                fontStyle: isBloqueio ? FontStyle.italic : FontStyle.normal,
                              )
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isBloqueio) Text(agendamento['diagnostico'] ?? ''),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _corDoTipo(tipo).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _corDoTipo(tipo), width: 1),
                                      ),
                                      child: Text(
                                        tipo,
                                        style: TextStyle(
                                          color: _corDoTipo(tipo),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Passo 7: Exibição da Observação Rápida no Card
                                if (observacao != null && observacao.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Obs: $observacao',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                  ),
                                ]
                              ],
                            ),
                            trailing: isBloqueio
                                ? const Icon(Icons.lock_clock, color: Colors.grey)
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chat, color: Colors.green),
                                        onPressed: () async {
                                          final paciente = await DatabaseHelper.instance.getPaciente(agendamento['paciente_id']);
                                          
                                          if (paciente != null && paciente['telefone'] != null && paciente['telefone'].toString().isNotEmpty) {
                                            String numLimpo = paciente['telefone'].replaceAll(RegExp(r'\D'), '');
                                            
                                            final uriApp = Uri.parse('whatsapp://send?phone=55$numLimpo');
                                            final uriWeb = Uri.parse('https://wa.me/55$numLimpo');
                                            
                                            try {
                                              if (await canLaunchUrl(uriApp)) {
                                                await launchUrl(uriApp);
                                              } else {
                                                await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
                                                );
                                              }
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Este paciente não tem telefone cadastrado.')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(color: corStatus, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                            onTap: isBloqueio ? null : () async {
                              final BuildContext agendaContext = context;
                              final pacienteCompleto = await DatabaseHelper.instance.getPaciente(agendamento['paciente_id']);
                              
                              if (pacienteCompleto != null) {
                                if (!agendaContext.mounted) return;
                                await DatabaseHelper.instance.atualizarStatusAgendamento(agendamento['id'], 'realizado');
                                
                                if (!agendaContext.mounted) return;
                                await Navigator.push(
                                  agendaContext,
                                  MaterialPageRoute(
                                    builder: (context) => TelaProntuario(
                                      paciente: pacienteCompleto,
                                      isFinalizado: false,
                                    ),
                                  ),
                                );
                                
                                _carregarAgendamentos();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        spacing: 10,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.event),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            label: 'Novo Agendamento / Bloqueio',
            onTap: _mostrarDialogoNovoAgendamento,
          ),
          SpeedDialChild(
            child: const Icon(Icons.person_add),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            label: 'Novo Paciente',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaCadastroPaciente()),
              );
              _carregarAgendamentos();
            },
          ),
        ],
      ),
    );
  }
}