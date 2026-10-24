import 'dart:io';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'tela_cadastro_evolucao.dart';

// Importações para o PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TelaProntuario extends StatefulWidget {
  final Map<String, dynamic> paciente;
  final bool isFinalizado;

  const TelaProntuario({
    super.key,
    required this.paciente,
    this.isFinalizado = false,
  });

  @override
  State<TelaProntuario> createState() => _TelaProntuarioState();
}

class _TelaProntuarioState extends State<TelaProntuario> {
  List<Map<String, dynamic>> _evolucoes = [];

  @override
  void initState() {
    super.initState();
    _carregarEvolucoes();
  }

  void _carregarEvolucoes() async {
    final dados = await DatabaseHelper.instance.getEvolucoesDoPaciente(widget.paciente['id']);
    setState(() {
      _evolucoes = dados;
    });
  }

  void _abrirCadastroEvolucao([Map<String, dynamic>? evolucao]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroEvolucao(
          paciente: widget.paciente,
          evolucaoExistente: evolucao,
        ),
      ),
    );

    if (resultado == true) {
      _carregarEvolucoes();
    }
  }

  // Função para Gerar e Mostrar o PDF
  Future<void> _gerarPdf() async {
    if (_evolucoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há evoluções para gerar o PDF.')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabeçalho do PDF
            pw.Header(
              level: 0,
              child: pw.Text(
                'Prontuário de Fisioterapia',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Paciente: ${widget.paciente['nome']}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (widget.paciente['diagnostico'] != null && widget.paciente['diagnostico'].toString().isNotEmpty)
              pw.Text('Diagnóstico Clínico: ${widget.paciente['diagnostico']}', style: const pw.TextStyle(fontSize: 14)),
            if (widget.paciente['telefone'] != null && widget.paciente['telefone'].toString().isNotEmpty)
              pw.Text('Contato: ${widget.paciente['telefone']}', style: const pw.TextStyle(fontSize: 14)),
            
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('Histórico de Evoluções', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 15),

            // Lista de Evoluções no PDF
            ..._evolucoes.map((evo) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Data da Sessão: ${evo['data_sessao']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Nível de Dor: ${evo['nivel_dor']} / 10', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Conduta: ${evo['conduta']}'),
                    if (evo['observacoes'] != null && evo['observacoes'].toString().isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Obs: ${evo['observacoes']}'),
                    ]
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    // Abre a tela nativa de visualização e impressão
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prontuario_${widget.paciente['nome'].replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    bool temFoto = widget.paciente['foto'] != null && widget.paciente['foto'].toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Prontuário - ${widget.paciente['nome']}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _gerarPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Card de resumo do paciente
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: temFoto ? FileImage(File(widget.paciente['foto'])) : null,
                    child: !temFoto
                        ? Text(
                            widget.paciente['nome'][0].toUpperCase(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.paciente['nome'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (widget.paciente['diagnostico'] != null)
                          Text('Diag: ${widget.paciente['diagnostico']}'),
                        if (widget.paciente['telefone'] != null)
                          Text('Tel: ${widget.paciente['telefone']}'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Gráfico da Dor
          if (_evolucoes.length >= 2) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evolução da Dor (Escala 0-10)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: GraficoDorPainter(
                            evolucoes: _evolucoes.reversed.toList(),
                            corLinha: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text('Histórico de Evoluções', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: _evolucoes.isEmpty
                ? const Center(child: Text('Nenhuma evolução cadastrada.'))
                : ListView.builder(
                    itemCount: _evolucoes.length,
                    itemBuilder: (context, index) {
                      final evolucao = _evolucoes[index];
                      int dor = evolucao['nivel_dor'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text('Sessão: ${evolucao['data_sessao']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Conduta: ${evolucao['conduta']}'),
                              if (evolucao['observacoes'] != null && evolucao['observacoes'].toString().isNotEmpty)
                                Text('Obs: ${evolucao['observacoes']}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: dor > 7
                                  ? Colors.red.shade100
                                  : (dor > 3 ? Colors.orange.shade100 : Colors.green.shade100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Dor: $dor',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: dor > 7
                                    ? Colors.red.shade900
                                    : (dor > 3 ? Colors.orange.shade900 : Colors.green.shade900),
                              ),
                            ),
                          ),
                          onTap: widget.isFinalizado ? null : () => _abrirCadastroEvolucao(evolucao),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: widget.isFinalizado
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirCadastroEvolucao(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nova Evolução'),
            ),
    );
  }
}

// Desenhador gráfico nativo para a dor
class GraficoDorPainter extends CustomPainter {
  final List<Map<String, dynamic>> evolucoes;
  final Color corLinha;

  GraficoDorPainter({required this.evolucoes, required this.corLinha});

  @override
  void paint(Canvas canvas, Size size) {
    if (evolucoes.length < 2) return;

    final paintLinha = Paint()
      ..color = corLinha
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintPonto = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    double espacamentoX = size.width / (evolucoes.length - 1);
    Path path = Path();

    for (int i = 0; i < evolucoes.length; i++) {
      double dor = (evolucoes[i]['nivel_dor'] ?? 0).toDouble();
      double x = i * espacamentoX;
      double y = size.height - ((dor / 10) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLinha);

    // Desenhar pontos e valores
    for (int i = 0; i < evolucoes.length; i++) {
      double dor = (evolucoes[i]['nivel_dor'] ?? 0).toDouble();
      double x = i * espacamentoX;
      double y = size.height - ((dor / 10) * size.height);

      canvas.drawCircle(Offset(x, y), 4, paintPonto);

      TextSpan span = TextSpan(
        text: dor.toInt().toString(),
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), y - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}