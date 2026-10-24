import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'fisio_app.db';
  static const _databaseVersion = 9;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pacientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        telefone TEXT,
        email TEXT,
        localizacao TEXT,
        diagnostico TEXT NOT NULL,
        foto TEXT,
        data_cadastro TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'tratando'
      )
    ''');

    await db.execute('''
      CREATE TABLE evolucoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paciente_id INTEGER NOT NULL,
        data_sessao TEXT NOT NULL,
        nivel_dor INTEGER,
        conduta TEXT NOT NULL,
        observacoes TEXT,
        FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE agendamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paciente_id INTEGER,
        data_agendamento TEXT NOT NULL,
        horario TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pendente',
        tipo_atendimento TEXT,
        observacao TEXT,
        FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final agendamentosExistem = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'agendamentos'",
    );

    if (agendamentosExistem.isEmpty) {
      await db.execute('''
        CREATE TABLE agendamentos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          paciente_id INTEGER,
          data_agendamento TEXT NOT NULL,
          horario TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pendente',
          tipo_atendimento TEXT,
          observacao TEXT,
          FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE
        )
      ''');
    } else {
      final colunas = await db.rawQuery('PRAGMA table_info(agendamentos)');
      final temTipoAtendimento = colunas.any(
        (coluna) => coluna['name'] == 'tipo_atendimento',
      );
      final temObservacao = colunas.any(
        (coluna) => coluna['name'] == 'observacao',
      );

      if (!temTipoAtendimento) {
        await db.execute(
          'ALTER TABLE agendamentos ADD COLUMN tipo_atendimento TEXT',
        );
      }
      if (!temObservacao) {
        await db.execute('ALTER TABLE agendamentos ADD COLUMN observacao TEXT');
      }
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE agendamentos_novo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          paciente_id INTEGER,
          data_agendamento TEXT NOT NULL,
          horario TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pendente',
          tipo_atendimento TEXT,
          observacao TEXT,
          FOREIGN KEY (paciente_id) REFERENCES pacientes (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        INSERT INTO agendamentos_novo
          (id, paciente_id, data_agendamento, horario, status, tipo_atendimento, observacao)
        SELECT
          id, paciente_id, data_agendamento, horario, status, tipo_atendimento, observacao
        FROM agendamentos
      ''');

      await db.execute('DROP TABLE agendamentos');
      await db.execute('ALTER TABLE agendamentos_novo RENAME TO agendamentos');
    }
  }

  // ================= FUNÇÕES DE PACIENTES =================
  Future<int> inserirPaciente(Map<String, dynamic> row) async {
    final db = await instance.database;
    return db.insert('pacientes', row);
  }

  Future<List<Map<String, dynamic>>> getTodosPacientes() async {
    final db = await instance.database;
    return db.query('pacientes', orderBy: 'nome ASC');
  }

  Future<int> deletarPaciente(int id) async {
    final db = await instance.database;
    return db.delete('pacientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> atualizarPaciente(int id, Map<String, dynamic> paciente) async {
    final db = await instance.database;
    return db.update('pacientes', paciente, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> atualizarStatusPaciente(int id, String novoStatus) async {
    final db = await instance.database;
    return db.update(
      'pacientes',
      {'status': novoStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= FUNÇÕES DE EVOLUÇÃO =================
  Future<int> inserirEvolucao(Map<String, dynamic> evolucao) async {
    final db = await instance.database;
    return db.insert('evolucoes', evolucao);
  }

  Future<List<Map<String, dynamic>>> getEvolucoesDoPaciente(
    int pacienteId,
  ) async {
    final db = await instance.database;
    return db.query(
      'evolucoes',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'id DESC',
    );
  }

  Future<int> atualizarEvolucao(int id, Map<String, dynamic> evolucao) async {
    final db = await instance.database;
    return db.update('evolucoes', evolucao, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletarEvolucao(int id) async {
    final db = await instance.database;
    return db.delete('evolucoes', where: 'id = ?', whereArgs: [id]);
  }

  // ================= FUNÇÕES DE AGENDAMENTO =================
  Future<int> inserirAgendamento(Map<String, dynamic> agendamento) async {
    final db = await instance.database;
    return db.insert('agendamentos', agendamento);
  }

  // Usa LEFT JOIN para retornar agendamentos com ou sem paciente (bloqueios)
  Future<List<Map<String, dynamic>>> getAgendamentosPorData(String data) async {
    final db = await instance.database;
    return db.rawQuery(
      '''
      SELECT a.*, p.nome, p.diagnostico, p.telefone, p.foto
      FROM agendamentos a
      LEFT JOIN pacientes p ON a.paciente_id = p.id
      WHERE a.data_agendamento = ?
      ORDER BY a.horario ASC
    ''',
      [data],
    );
  }

  Future<int> atualizarStatusAgendamento(int id, String novoStatus) async {
    final db = await instance.database;
    return db.update(
      'agendamentos',
      {'status': novoStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletarAgendamento(int id) async {
    final db = await instance.database;
    return db.delete('agendamentos', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getPaciente(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'pacientes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }
}
