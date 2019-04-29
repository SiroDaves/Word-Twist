import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:word_twist/data/repo.dart';

const String _kDbFileName = 'words.sqlite';

class WordsDataSource implements WordsRepository {
  Future<bool> isDbLoaded() async {
    final dbFilePath = await _getDbFilePath();
    return await (new File(dbFilePath).exists());
  }

  Future<String> _getDbFilePath() async {
    final databasePath = await getDatabasesPath();
    return join(databasePath, _kDbFileName);
  }

  Future loadDatabase() async {
    final db = await rootBundle.load('assets/' + _kDbFileName);
    final dbFilePath = await _getDbFilePath();
    final buffer = db.buffer;
    final file = new File(dbFilePath);
    try {
      await file.writeAsBytes(buffer.asUint8List(db.offsetInBytes, db.lengthInBytes),
          mode: FileMode.write, flush: true);
    } on FileSystemException {
      // if (Platform.isAndroid) {
      //   final NativeMethods _nativeMethods = new PlatformChannel();
      //   await _nativeMethods.callNative(kCopyDb, {'dbData': buffer.asUint8List()});
      // } else {
      //   throw e;
      // }
    }
  }

  Future<Database> _getDatabase() async {
    final databasePath = await getDatabasesPath();
    String path = join(databasePath, _kDbFileName);
    return await openDatabase(path, singleInstance: false);
  }

  Future<bool> wordExists(String word) async {
    final Database db = await _getDatabase();
    try {
      final String sql = '''SELECT COUNT(*) as c FROM words_en WHERE word = ?''';
      final rows = await db.rawQuery(sql, [word.toLowerCase()]);
      if (rows.length > 0) {
        return rows[0]['c'] > 0;
      }
      return false;
    } finally {
      db.close();
    }
  }

  Future<List<String>> getBuildableWords(String sortedInput) async {
    final Database db = await _getDatabase();
    try {
      final String rowsSql = 'SELECT * FROM words_fts WHERE sorted MATCH ?';
      final List<Map<String, dynamic>> rowsCursor = await db.rawQuery(rowsSql, ['^${sortedInput.toLowerCase()}']);
      List<String> result = [];
      if (rowsCursor.length == 0) return result;
      final String wordIds = rowsCursor[0]['word_ids'];
      final List<String> ids = wordIds.split(',');
      for (var id in ids) {
        final wordCursor = await db.rawQuery('SELECT rowid, word FROM words_en WHERE rowid = ?', [id]);
        result.add(wordCursor[0]['word']);
      }
      return result;
    } finally {
      db.close();
    }
  }

  Future<String> getRandomWord([int len = 6]) async {
    final Database db = await _getDatabase();
    try {
      final String sql = 'SELECT * FROM words_en WHERE length(word) = ? LIMIT 1000';
      final rows = await db.rawQuery(sql, [len]);
      final List<String> words = rows.map((r) => r['word'].toString()).toList();
      final rnd = new Random();
      var result = words[rnd.nextInt(words.length - 1)];
      var set = new Set<String>();
      set.addAll(result.split(""));
      while (result.length != set.length) {
        set.clear();
        result = words[rnd.nextInt(words.length - 1)];
        set.addAll(result.split(""));
      }
      return result;
    } finally {
      db.close();
    }
  }
}
