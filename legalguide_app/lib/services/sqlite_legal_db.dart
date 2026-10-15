import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/law.dart';
import '../models/legal_matter.dart';
import '../models/legal_section.dart';
import '../models/legal_section_version.dart';

class SqliteLegalDb {
  static const _dbName = 'legalguide_v2.db';
  static const _dbVersion = 2;

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrateColumns(db);
        await _seedInitialData(db);
      },
      onOpen: (db) async {
        await _migrateColumns(db);
        // Ensure initial seed is loaded if empty or needs update for new example system
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sections'),
        );
        final hiCount = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM sections WHERE title_hi IS NOT NULL AND title_hi != ''"),
        ) ?? 0;
        final exampleCount = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM sections WHERE example_situation IS NOT NULL AND example_situation != ''"),
        ) ?? 0;
        final sectionsCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sections'),
        ) ?? 0;

        if (count == null || count < 32 || sectionsCount < 50 || hiCount == 0 || exampleCount == 0) {
          await _seedInitialData(db);
        }

        // Clean up any historical duplicate records in SQLite
        await _cleanupDuplicateSections(db);
      },
    );
  }

  static Future<void> _cleanupDuplicateSections(Database db) async {
    try {
      // 1. Reconcile duplicate laws if any (e.g. BNS having both id=1 and id=2)
      final allLaws = await db.query('laws', orderBy: 'id ASC');
      final lawsByCanon = <int, List<Map<String, dynamic>>>{};
      for (final law in allLaws) {
        final rawId = law['id'] as int;
        final name = law['name'] as String? ?? '';
        final shortName = law['short_name'] as String? ?? '';
        final canonId = LegalSection.canonicalLawId(rawId, name, shortName);
        lawsByCanon.putIfAbsent(canonId, () => []).add(law);
      }
      for (final entry in lawsByCanon.entries) {
        if (entry.value.length > 1) {
          final canonId = entry.key;
          for (final lawRow in entry.value) {
            final rowId = lawRow['id'] as int;
            if (rowId != canonId) {
              await db.rawUpdate('UPDATE sections SET law_id = ? WHERE law_id = ?', [canonId, rowId]);
              await db.delete('laws', where: 'id = ?', whereArgs: [rowId]);
            }
          }
        }
      }

      // 2. Ensure every section has a canonical provision_key
      final allSections = await db.query('sections');
      for (final row in allSections) {
        final id = row['id'] as int;
        final lawId = row['law_id'] as int? ?? 0;
        final secNum = row['section_number']?.toString() ?? '';
        final canonicalKey = LegalSection.computeProvisionKey(lawId, secNum);
        if (row['provision_key'] != canonicalKey) {
          await db.update('sections', {'provision_key': canonicalKey}, where: 'id = ?', whereArgs: [id]);
        }
      }

      // 3. Find and cleanly merge duplicate provisions by provision_key
      final duplicates = await db.rawQuery('''
        SELECT provision_key, COUNT(*) as c
        FROM sections
        WHERE provision_key IS NOT NULL AND provision_key != ''
        GROUP BY provision_key
        HAVING c > 1
      ''');

      for (final dup in duplicates) {
        final key = dup['provision_key'] as String;
        final rows = await db.query(
          'sections',
          where: 'provision_key = ?',
          whereArgs: [key],
          orderBy: 'updated_at DESC, version DESC, id DESC',
        );

        if (rows.length > 1) {
          final sorted = List<Map<String, dynamic>>.from(rows);
          sorted.sort((a, b) {
            final aImg = (a['visual_image_url'] as String? ?? '').isNotEmpty;
            final bImg = (b['visual_image_url'] as String? ?? '').isNotEmpty;
            if (aImg != bImg) return aImg ? -1 : 1;

            final aVid = (a['video_url'] as String? ?? '').isNotEmpty;
            final bVid = (b['video_url'] as String? ?? '').isNotEmpty;
            if (aVid != bVid) return aVid ? -1 : 1;

            final aVer = a['version'] as int? ?? 1;
            final bVer = b['version'] as int? ?? 1;
            if (aVer != bVer) return bVer.compareTo(aVer);

            final aUp = a['updated_at']?.toString() ?? '';
            final bUp = b['updated_at']?.toString() ?? '';
            return bUp.compareTo(aUp);
          });

          final best = Map<String, dynamic>.from(sorted.first);
          final bestId = best['id'] as int;

          // Merge non-empty fields from duplicates into best
          final updateFields = <String, dynamic>{};
          for (int i = 1; i < sorted.length; i++) {
            final dupRow = sorted[i];
            for (final f in [
              'visual_image_url', 'visual_caption', 'visual_caption_te', 'visual_caption_hi',
              'visual_alt_text', 'video_url', 'video_title', 'video_duration', 'video_thumbnail_url',
              'example_situation', 'example_explanation', 'what_you_should_do',
              'title_te', 'simple_explanation_te', 'title_hi', 'simple_explanation_hi',
            ]) {
              final bestVal = (best[f] as String? ?? '').trim();
              final dupVal = (dupRow[f] as String? ?? '').trim();
              if (bestVal.isEmpty && dupVal.isNotEmpty) {
                best[f] = dupVal;
                updateFields[f] = dupVal;
              }
            }
          }

          if (updateFields.isNotEmpty) {
            await db.update('sections', updateFields, where: 'id = ?', whereArgs: [bestId]);
          }

          // Delete other duplicate records
          for (int i = 1; i < sorted.length; i++) {
            final removeId = sorted[i]['id'] as int;
            await db.delete('sections', where: 'id = ?', whereArgs: [removeId]);
          }
        }
      }

      // 4. Enforce unique index at database level on provision_key
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_sections_prov_key ON sections(provision_key)',
      );
    } catch (_) {}
  }

  static Future<void> _migrateColumns(Database db) async {
    final migrations = [
      'ALTER TABLE categories ADD COLUMN name_hi TEXT',
      'ALTER TABLE categories ADD COLUMN description_hi TEXT',
      'ALTER TABLE laws ADD COLUMN name_te TEXT',
      'ALTER TABLE laws ADD COLUMN short_name_te TEXT',
      'ALTER TABLE laws ADD COLUMN description_te TEXT',
      'ALTER TABLE laws ADD COLUMN name_hi TEXT',
      'ALTER TABLE laws ADD COLUMN short_name_hi TEXT',
      'ALTER TABLE laws ADD COLUMN description_hi TEXT',
      'ALTER TABLE sections ADD COLUMN title_hi TEXT',
      'ALTER TABLE sections ADD COLUMN simple_explanation_hi TEXT',
      'ALTER TABLE sections ADD COLUMN purpose_hi TEXT',
      'ALTER TABLE sections ADD COLUMN punishment_hi TEXT',
      'ALTER TABLE sections ADD COLUMN key_elements_hi TEXT',
      'ALTER TABLE sections ADD COLUMN relevant_information_hi TEXT',
      'ALTER TABLE sections ADD COLUMN relevant_documents_hi TEXT',
      'ALTER TABLE matters ADD COLUMN name_hi TEXT',
      'ALTER TABLE matters ADD COLUMN description_hi TEXT',
      'ALTER TABLE sections ADD COLUMN source_type TEXT',
      'ALTER TABLE sections ADD COLUMN quick_answer TEXT',
      'ALTER TABLE sections ADD COLUMN quick_answer_te TEXT',
      'ALTER TABLE sections ADD COLUMN quick_answer_hi TEXT',
      'ALTER TABLE sections ADD COLUMN example_title TEXT',
      'ALTER TABLE sections ADD COLUMN example_title_te TEXT',
      'ALTER TABLE sections ADD COLUMN example_title_hi TEXT',
      'ALTER TABLE sections ADD COLUMN example_situation TEXT',
      'ALTER TABLE sections ADD COLUMN example_situation_te TEXT',
      'ALTER TABLE sections ADD COLUMN example_situation_hi TEXT',
      'ALTER TABLE sections ADD COLUMN example_explanation TEXT',
      'ALTER TABLE sections ADD COLUMN example_explanation_te TEXT',
      'ALTER TABLE sections ADD COLUMN example_explanation_hi TEXT',
      'ALTER TABLE sections ADD COLUMN example_disclaimer TEXT',
      'ALTER TABLE sections ADD COLUMN visual_image_url TEXT',
      'ALTER TABLE sections ADD COLUMN visual_caption TEXT',
      'ALTER TABLE sections ADD COLUMN visual_caption_te TEXT',
      'ALTER TABLE sections ADD COLUMN visual_caption_hi TEXT',
      'ALTER TABLE sections ADD COLUMN visual_alt_text TEXT',
      'ALTER TABLE sections ADD COLUMN is_visual_illustrative INTEGER DEFAULT 1',
      'ALTER TABLE sections ADD COLUMN video_url TEXT',
      'ALTER TABLE sections ADD COLUMN video_title TEXT',
      'ALTER TABLE sections ADD COLUMN video_duration TEXT',
      'ALTER TABLE sections ADD COLUMN video_thumbnail_url TEXT',
      'ALTER TABLE sections ADD COLUMN video_transcript TEXT',
      'ALTER TABLE sections ADD COLUMN example_steps TEXT',
      'ALTER TABLE sections ADD COLUMN what_you_should_do TEXT',
      'ALTER TABLE sections ADD COLUMN what_you_should_do_te TEXT',
      'ALTER TABLE sections ADD COLUMN what_you_should_do_hi TEXT',
      'ALTER TABLE sections ADD COLUMN consequences_type TEXT',
      'ALTER TABLE sections ADD COLUMN provision_key TEXT',
    ];
    for (final sql in migrations) {
      try {
        await db.execute(sql);
      } catch (_) {
        // column already exists
      }
    }

    // Ensure chat history tables exist during migration/open
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        language TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        language TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        is_online INTEGER,
        requires_login INTEGER NOT NULL DEFAULT 0,
        response_metadata TEXT
      )
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_messages_conv ON chat_messages(conversation_id, timestamp)');
    } catch (_) {}
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        name_te TEXT,
        description_te TEXT,
        name_hi TEXT,
        description_hi TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS laws (
        id INTEGER PRIMARY KEY,
        category_id INTEGER,
        name TEXT NOT NULL,
        short_name TEXT,
        description TEXT,
        year INTEGER,
        act_number TEXT,
        source_url TEXT,
        source_name TEXT,
        status TEXT,
        last_verified TEXT,
        updated_at TEXT,
        name_te TEXT,
        short_name_te TEXT,
        description_te TEXT,
        name_hi TEXT,
        short_name_hi TEXT,
        description_hi TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sections (
        id INTEGER PRIMARY KEY,
        law_id INTEGER,
        section_number TEXT NOT NULL,
        title TEXT NOT NULL,
        legal_text TEXT NOT NULL,
        simple_explanation TEXT,
        purpose TEXT,
        punishment TEXT,
        relevant_documents TEXT,
        key_elements TEXT,
        relevant_information TEXT,
        keywords TEXT,
        badge TEXT,
        source TEXT,
        last_verified TEXT,
        related_sections TEXT,
        direct_action_url TEXT,
        direct_action_label TEXT,
        direct_action_type TEXT,
        effective_date TEXT,
        amendment_info TEXT,
        status TEXT,
        source_name TEXT,
        version INTEGER DEFAULT 1,
        previous_version_ref TEXT,
        updated_at TEXT,
        title_te TEXT,
        simple_explanation_te TEXT,
        purpose_te TEXT,
        punishment_te TEXT,
        key_elements_te TEXT,
        relevant_information_te TEXT,
        relevant_documents_te TEXT,
        title_hi TEXT,
        simple_explanation_hi TEXT,
        purpose_hi TEXT,
        punishment_hi TEXT,
        key_elements_hi TEXT,
        relevant_information_hi TEXT,
        relevant_documents_hi TEXT,
        source_type TEXT,
        quick_answer TEXT,
        quick_answer_te TEXT,
        quick_answer_hi TEXT,
        example_title TEXT,
        example_title_te TEXT,
        example_title_hi TEXT,
        example_situation TEXT,
        example_situation_te TEXT,
        example_situation_hi TEXT,
        example_explanation TEXT,
        example_explanation_te TEXT,
        example_explanation_hi TEXT,
        example_disclaimer TEXT,
        visual_image_url TEXT,
        visual_caption TEXT,
        visual_caption_te TEXT,
        visual_caption_hi TEXT,
        visual_alt_text TEXT,
        is_visual_illustrative INTEGER DEFAULT 1,
        video_url TEXT,
        video_title TEXT,
        video_duration TEXT,
        video_thumbnail_url TEXT,
        video_transcript TEXT,
        example_steps TEXT,
        what_you_should_do TEXT,
        what_you_should_do_te TEXT,
        what_you_should_do_hi TEXT,
        consequences_type TEXT,
        provision_key TEXT
      )
    ''');

    try {
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_sections_law_sec ON sections(law_id, section_number)');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS section_versions (
        id INTEGER PRIMARY KEY,
        section_id INTEGER NOT NULL,
        version INTEGER NOT NULL,
        legal_text TEXT NOT NULL,
        simple_explanation TEXT,
        purpose TEXT,
        punishment TEXT,
        effective_date TEXT,
        amendment_info TEXT,
        source_name TEXT,
        source_url TEXT,
        archived_at TEXT,
        change_summary TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS matters (
        id INTEGER PRIMARY KEY,
        category_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        name_te TEXT,
        description_te TEXT,
        name_hi TEXT,
        description_hi TEXT,
        related_sections TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        language TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        language TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        is_online INTEGER,
        requires_login INTEGER NOT NULL DEFAULT 0,
        response_metadata TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');

    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_messages_conv ON chat_messages(conversation_id, timestamp)');
    } catch (_) {}
  }

  static Future<void> _seedInitialData(Database db) async {
    try {
      // 1. Categories
      final catRaw = await rootBundle.loadString('assets/seed/categories.json');
      final List<dynamic> catList = jsonDecode(catRaw);
      final batch = db.batch();
      for (final item in catList) {
        batch.insert('categories', {
          'id': item['id'],
          'name': item['name'] ?? '',
          'description': item['description'] ?? '',
          'name_te': item['name_te'] ?? '',
          'description_te': item['description_te'] ?? '',
          'name_hi': item['name_hi'] ?? '',
          'description_hi': item['description_hi'] ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 2. Laws
      final lawRaw = await rootBundle.loadString('assets/seed/laws.json');
      final List<dynamic> lawList = jsonDecode(lawRaw);
      for (final item in lawList) {
        batch.insert('laws', {
          'id': item['id'],
          'category_id': item['category'] is int ? item['category'] : (item['category']?['id'] ?? 0),
          'name': item['name'] ?? '',
          'short_name': item['short_name'] ?? '',
          'description': item['description'] ?? '',
          'year': item['year'],
          'act_number': item['act_number'],
          'source_url': item['source_url'],
          'source_name': item['source_name'] ?? 'India Code (Official Government Source)',
          'status': item['status'] ?? 'current',
          'last_verified': item['last_verified'],
          'updated_at': item['updated_at'],
          'name_te': item['name_te'] ?? '',
          'short_name_te': item['short_name_te'] ?? '',
          'description_te': item['description_te'] ?? '',
          'name_hi': item['name_hi'] ?? '',
          'short_name_hi': item['short_name_hi'] ?? '',
          'description_hi': item['description_hi'] ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 3. Sections (Idempotent Canonical Upsert)
      final secRaw = await rootBundle.loadString('assets/seed/sections.json');
      final List<dynamic> secList = jsonDecode(secRaw);

      final existingRows = await db.query('sections', columns: ['id', 'provision_key', 'law_id', 'section_number']);
      final existingByKey = <String, int>{};
      for (final row in existingRows) {
        final key = (row['provision_key'] as String? ?? '').trim();
        final rawKey = key.isNotEmpty
            ? key
            : LegalSection.computeProvisionKey(row['law_id'] as int? ?? 0, row['section_number']?.toString() ?? '');
        if (rawKey.isNotEmpty) existingByKey[rawKey] = row['id'] as int;
      }

      for (final item in secList) {
        final rawLawId = item['law'] is int ? item['law'] : (item['law']?['id'] ?? item['law_id'] ?? 0);
        final lawName = item['law_name']?.toString() ?? '';
        final lawShortName = item['law_short_name']?.toString() ?? '';
        final canonLawId = LegalSection.canonicalLawId(rawLawId, lawName, lawShortName);
        final secNum = item['section_number'] ?? '';
        final provKey = LegalSection.computeProvisionKey(canonLawId, secNum, lawName: lawName, lawShortName: lawShortName);

        final sectionMap = <String, dynamic>{
          'law_id': canonLawId,
          'section_number': secNum,
          'title': item['title'] ?? '',
          'legal_text': item['legal_text'] ?? '',
          'simple_explanation': item['simple_explanation'] ?? '',
          'purpose': item['purpose'] ?? '',
          'punishment': item['punishment'] ?? '',
          'relevant_documents': item['relevant_documents'] ?? '',
          'key_elements': item['key_elements'] ?? '',
          'relevant_information': item['relevant_information'] ?? '',
          'keywords': item['keywords'] ?? '',
          'badge': item['badge'] ?? '',
          'source': item['source'] ?? '',
          'last_verified': item['last_verified'],
          'related_sections': jsonEncode(item['related_sections'] ?? []),
          'direct_action_url': item['direct_action_url'],
          'direct_action_label': item['direct_action_label'],
          'direct_action_type': item['direct_action_type'],
          'effective_date': item['effective_date'],
          'amendment_info': item['amendment_info'] ?? '',
          'status': item['status'] ?? 'current',
          'source_name': item['source_name'] ?? 'India Code (Official Government Source)',
          'version': item['version'] ?? 1,
          'previous_version_ref': item['previous_version_ref'],
          'updated_at': item['updated_at'],
          'title_te': item['title_te'] ?? '',
          'simple_explanation_te': item['simple_explanation_te'] ?? '',
          'purpose_te': item['purpose_te'] ?? '',
          'punishment_te': item['punishment_te'] ?? '',
          'key_elements_te': item['key_elements_te'] ?? '',
          'relevant_information_te': item['relevant_information_te'] ?? '',
          'relevant_documents_te': item['relevant_documents_te'] ?? '',
          'title_hi': item['title_hi'] ?? '',
          'simple_explanation_hi': item['simple_explanation_hi'] ?? '',
          'purpose_hi': item['purpose_hi'] ?? '',
          'punishment_hi': item['punishment_hi'] ?? '',
          'key_elements_hi': item['key_elements_hi'] ?? '',
          'relevant_information_hi': item['relevant_information_hi'] ?? '',
          'relevant_documents_hi': item['relevant_documents_hi'] ?? '',
          'source_type': item['source_type'] ?? 'Official Bare Act Gazette',
          'quick_answer': item['quick_answer'] ?? '',
          'quick_answer_te': item['quick_answer_te'] ?? '',
          'quick_answer_hi': item['quick_answer_hi'] ?? '',
          'example_title': item['example_title'] ?? '',
          'example_title_te': item['example_title_te'] ?? '',
          'example_title_hi': item['example_title_hi'] ?? '',
          'example_situation': item['example_situation'] ?? '',
          'example_situation_te': item['example_situation_te'] ?? '',
          'example_situation_hi': item['example_situation_hi'] ?? '',
          'example_explanation': item['example_explanation'] ?? '',
          'example_explanation_te': item['example_explanation_te'] ?? '',
          'example_explanation_hi': item['example_explanation_hi'] ?? '',
          'example_disclaimer': item['example_disclaimer'] ?? '',
          'visual_image_url': item['visual_image_url'] ?? '',
          'visual_caption': item['visual_caption'] ?? '',
          'visual_caption_te': item['visual_caption_te'] ?? '',
          'visual_caption_hi': item['visual_caption_hi'] ?? '',
          'visual_alt_text': item['visual_alt_text'] ?? '',
          'is_visual_illustrative': item['is_visual_illustrative'] == false ? 0 : 1,
          'video_url': item['video_url'] ?? '',
          'video_title': item['video_title'] ?? '',
          'video_duration': item['video_duration'] ?? '',
          'video_thumbnail_url': item['video_thumbnail_url'] ?? '',
          'video_transcript': item['video_transcript'] ?? '',
          'example_steps': item['example_steps'] is String ? item['example_steps'] : (item['example_steps'] != null ? jsonEncode(item['example_steps']) : ''),
          'what_you_should_do': item['what_you_should_do'] ?? '',
          'what_you_should_do_te': item['what_you_should_do_te'] ?? '',
          'what_you_should_do_hi': item['what_you_should_do_hi'] ?? '',
          'consequences_type': item['consequences_type'] ?? 'penal',
          'provision_key': provKey,
        };

        if (existingByKey.containsKey(provKey)) {
          final existingId = existingByKey[provKey]!;
          await db.update('sections', sectionMap, where: 'id = ?', whereArgs: [existingId]);
        } else {
          sectionMap['id'] = item['id'];
          await db.insert('sections', sectionMap, conflictAlgorithm: ConflictAlgorithm.replace);
          existingByKey[provKey] = sectionMap['id'] as int;
        }
      }

      // 4. Matters
      final matRaw = await rootBundle.loadString('assets/seed/matters.json');
      final List<dynamic> matList = jsonDecode(matRaw);
      for (final item in matList) {
        batch.insert('matters', {
          'id': item['id'],
          'category_id': item['category'] is int ? item['category'] : (item['category']?['id'] ?? 0),
          'name': item['name'] ?? '',
          'description': item['description'] ?? '',
          'name_te': item['name_te'] ?? '',
          'description_te': item['description_te'] ?? '',
          'name_hi': item['name_hi'] ?? '',
          'description_hi': item['description_hi'] ?? '',
          'related_sections': jsonEncode(item['related_sections'] ?? []),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 5. Initial sync metadata
      batch.insert('sync_metadata', {
        'key': 'last_sync_timestamp',
        'value': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      batch.insert('sync_metadata', {
        'key': 'server_version',
        'value': '4',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      batch.insert('sync_metadata', {
        'key': 'primary_source_name',
        'value': 'India Code (Official Government Source)',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      batch.insert('sync_metadata', {
        'key': 'primary_source_url',
        'value': 'https://www.indiacode.gov.in/',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      batch.insert('sync_metadata', {
        'key': 'last_verified',
        'value': '',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await batch.commit(noResult: true);
    } catch (e) {
      // Seed fallback
    }
  }

  // --- Incremental Delta Synchronization ---
  static Future<bool> applyDeltaSync(Map<String, dynamic> delta) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        final batch = txn.batch();

        // 1. Categories
        if (delta['categories'] is List) {
          for (final item in delta['categories']) {
            batch.insert('categories', {
              'id': item['id'],
              'name': item['name'] ?? '',
              'description': item['description'] ?? '',
              'name_te': item['name_te'] ?? '',
              'description_te': item['description_te'] ?? '',
              'name_hi': item['name_hi'] ?? '',
              'description_hi': item['description_hi'] ?? '',
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        // 2. Laws
        if (delta['laws'] is List) {
          for (final item in delta['laws']) {
            batch.insert('laws', {
              'id': item['id'],
              'category_id': item['category'] is int ? item['category'] : (item['category']?['id'] ?? 0),
              'name': item['name'] ?? '',
              'short_name': item['short_name'] ?? '',
              'description': item['description'] ?? '',
              'year': item['year'],
              'act_number': item['act_number'],
              'source_url': item['source_url'],
              'source_name': item['source_name'] ?? 'India Code (Official Government Source)',
              'status': item['status'] ?? 'current',
              'last_verified': item['last_verified'],
              'updated_at': item['updated_at'],
              'name_te': item['name_te'] ?? '',
              'short_name_te': item['short_name_te'] ?? '',
              'description_te': item['description_te'] ?? '',
              'name_hi': item['name_hi'] ?? '',
              'short_name_hi': item['short_name_hi'] ?? '',
              'description_hi': item['description_hi'] ?? '',
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        // 3. Sections (Canonical Provision Upsert)
        if (delta['sections'] is List) {
          final existingRows = await txn.query('sections', columns: ['id', 'provision_key', 'law_id', 'section_number']);
          final existingByKey = <String, int>{};
          for (final row in existingRows) {
            final key = (row['provision_key'] as String? ?? '').trim();
            final rawKey = key.isNotEmpty
                ? key
                : LegalSection.computeProvisionKey(row['law_id'] as int? ?? 0, row['section_number']?.toString() ?? '');
            if (rawKey.isNotEmpty) existingByKey[rawKey] = row['id'] as int;
          }

          for (final item in delta['sections']) {
            final rawLawId = item['law'] is int ? item['law'] : (item['law']?['id'] ?? item['law_id'] ?? 0);
            final lawName = item['law_name']?.toString() ?? '';
            final lawShortName = item['law_short_name']?.toString() ?? '';
            final canonLawId = LegalSection.canonicalLawId(rawLawId, lawName, lawShortName);
            final secNum = item['section_number'] ?? '';
            final provKey = LegalSection.computeProvisionKey(canonLawId, secNum, lawName: lawName, lawShortName: lawShortName);

            final sectionMap = <String, dynamic>{
              'law_id': canonLawId,
              'section_number': secNum,
              'title': item['title'] ?? '',
              'legal_text': item['legal_text'] ?? '',
              'simple_explanation': item['simple_explanation'] ?? '',
              'purpose': item['purpose'] ?? '',
              'punishment': item['punishment'] ?? '',
              'relevant_documents': item['relevant_documents'] ?? '',
              'key_elements': item['key_elements'] ?? '',
              'relevant_information': item['relevant_information'] ?? '',
              'keywords': item['keywords'] ?? '',
              'badge': item['badge'] ?? '',
              'source': item['source'] ?? '',
              'last_verified': item['last_verified'],
              'related_sections': jsonEncode(item['related_sections'] ?? []),
              'direct_action_url': item['direct_action_url'],
              'direct_action_label': item['direct_action_label'],
              'direct_action_type': item['direct_action_type'],
              'effective_date': item['effective_date'],
              'amendment_info': item['amendment_info'] ?? '',
              'status': item['status'] ?? 'current',
              'source_name': item['source_name'] ?? 'India Code (Official Government Source)',
              'version': item['version'] ?? 1,
              'previous_version_ref': item['previous_version_ref'],
              'updated_at': item['updated_at'],
              'title_te': item['title_te'] ?? '',
              'simple_explanation_te': item['simple_explanation_te'] ?? '',
              'purpose_te': item['purpose_te'] ?? '',
              'punishment_te': item['punishment_te'] ?? '',
              'key_elements_te': item['key_elements_te'] ?? '',
              'relevant_information_te': item['relevant_information_te'] ?? '',
              'relevant_documents_te': item['relevant_documents_te'] ?? '',
              'title_hi': item['title_hi'] ?? '',
              'simple_explanation_hi': item['simple_explanation_hi'] ?? '',
              'purpose_hi': item['purpose_hi'] ?? '',
              'punishment_hi': item['punishment_hi'] ?? '',
              'key_elements_hi': item['key_elements_hi'] ?? '',
              'relevant_information_hi': item['relevant_information_hi'] ?? '',
              'relevant_documents_hi': item['relevant_documents_hi'] ?? '',
              'source_type': item['source_type'] ?? 'Official Bare Act Gazette',
              'quick_answer': item['quick_answer'] ?? '',
              'quick_answer_te': item['quick_answer_te'] ?? '',
              'quick_answer_hi': item['quick_answer_hi'] ?? '',
              'example_title': item['example_title'] ?? '',
              'example_title_te': item['example_title_te'] ?? '',
              'example_title_hi': item['example_title_hi'] ?? '',
              'example_situation': item['example_situation'] ?? '',
              'example_situation_te': item['example_situation_te'] ?? '',
              'example_situation_hi': item['example_situation_hi'] ?? '',
              'example_explanation': item['example_explanation'] ?? '',
              'example_explanation_te': item['example_explanation_te'] ?? '',
              'example_explanation_hi': item['example_explanation_hi'] ?? '',
              'example_disclaimer': item['example_disclaimer'] ?? '',
              'visual_image_url': item['visual_image_url'] ?? '',
              'visual_caption': item['visual_caption'] ?? '',
              'visual_caption_te': item['visual_caption_te'] ?? '',
              'visual_caption_hi': item['visual_caption_hi'] ?? '',
              'visual_alt_text': item['visual_alt_text'] ?? '',
              'is_visual_illustrative': item['is_visual_illustrative'] == false ? 0 : 1,
              'video_url': item['video_url'] ?? '',
              'video_title': item['video_title'] ?? '',
              'video_duration': item['video_duration'] ?? '',
              'video_thumbnail_url': item['video_thumbnail_url'] ?? '',
              'video_transcript': item['video_transcript'] ?? '',
              'example_steps': item['example_steps'] is String ? item['example_steps'] : (item['example_steps'] != null ? jsonEncode(item['example_steps']) : ''),
              'what_you_should_do': item['what_you_should_do'] ?? '',
              'what_you_should_do_te': item['what_you_should_do_te'] ?? '',
              'what_you_should_do_hi': item['what_you_should_do_hi'] ?? '',
              'consequences_type': item['consequences_type'] ?? 'penal',
              'provision_key': provKey,
            };

            if (existingByKey.containsKey(provKey)) {
              final existingId = existingByKey[provKey]!;
              await txn.update('sections', sectionMap, where: 'id = ?', whereArgs: [existingId]);
            } else {
              sectionMap['id'] = item['id'];
              await txn.insert('sections', sectionMap, conflictAlgorithm: ConflictAlgorithm.replace);
              existingByKey[provKey] = sectionMap['id'] as int;
            }
          }
        }

        // 4. Section Versions
        if (delta['versions'] is List) {
          for (final item in delta['versions']) {
            batch.insert('section_versions', {
              'id': item['id'],
              'section_id': item['section'] is int ? item['section'] : (item['section']?['id'] ?? 0),
              'version': item['version'] ?? 1,
              'legal_text': item['legal_text'] ?? '',
              'simple_explanation': item['simple_explanation'] ?? '',
              'purpose': item['purpose'] ?? '',
              'punishment': item['punishment'] ?? '',
              'effective_date': item['effective_date'],
              'amendment_info': item['amendment_info'] ?? '',
              'source_name': item['source_name'] ?? 'India Code (Official Government Source)',
              'source_url': item['source_url'],
              'archived_at': item['archived_at'],
              'change_summary': item['change_summary'] ?? '',
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        // 5. Matters
        if (delta['matters'] is List) {
          for (final item in delta['matters']) {
            batch.insert('matters', {
              'id': item['id'],
              'category_id': item['category'] is int ? item['category'] : (item['category']?['id'] ?? 0),
              'name': item['name'] ?? '',
              'description': item['description'] ?? '',
              'name_te': item['name_te'] ?? '',
              'description_te': item['description_te'] ?? '',
              'name_hi': item['name_hi'] ?? '',
              'description_hi': item['description_hi'] ?? '',
              'related_sections': jsonEncode(item['related_sections'] ?? []),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        // 6. Deleted / Repealed Section IDs
        if (delta['deleted_section_ids'] is List) {
          for (final id in delta['deleted_section_ids']) {
            batch.update(
              'sections',
              {'status': 'repealed'},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }

        // 7. Update sync metadata
        if (delta['sync_timestamp'] != null) {
          batch.insert('sync_metadata', {
            'key': 'last_sync_timestamp',
            'value': delta['sync_timestamp'].toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        if (delta['server_version'] != null) {
          batch.insert('sync_metadata', {
            'key': 'server_version',
            'value': delta['server_version'].toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        if (delta['source_name'] != null) {
          batch.insert('sync_metadata', {
            'key': 'primary_source_name',
            'value': delta['source_name'].toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        if (delta['source_url'] != null) {
          batch.insert('sync_metadata', {
            'key': 'primary_source_url',
            'value': delta['source_url'].toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        if (delta['last_verified'] != null) {
          batch.insert('sync_metadata', {
            'key': 'last_verified',
            'value': delta['last_verified'].toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        await batch.commit(noResult: true);
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Queries ---

  static Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return rows.map((r) => Category(
      id: r['id'] as int,
      name: r['name'] as String? ?? '',
      description: r['description'] as String? ?? '',
      nameTe: r['name_te'] as String? ?? '',
      descriptionTe: r['description_te'] as String? ?? '',
      nameHi: r['name_hi'] as String? ?? '',
      descriptionHi: r['description_hi'] as String? ?? '',
    )).toList();
  }

  static Future<List<Law>> getLaws({int? categoryId}) async {
    final db = await database;
    final rows = await db.query(
      'laws',
      where: categoryId != null ? 'category_id = ?' : null,
      whereArgs: categoryId != null ? [categoryId] : null,
      orderBy: 'id ASC',
    );
    return rows.map((r) => Law(
      id: r['id'] as int,
      name: r['name'] as String? ?? '',
      shortName: r['short_name'] as String? ?? '',
      categoryId: r['category_id'] as int? ?? 0,
      description: r['description'] as String? ?? '',
      year: r['year'] as int?,
      actNumber: r['act_number'] as String?,
      sourceUrl: r['source_url'] as String?,
      sourceName: r['source_name'] as String? ?? 'India Code (Official Government Source)',
      status: r['status'] as String? ?? 'current',
      lastVerified: r['last_verified'] as String?,
      updatedAt: r['updated_at'] as String?,
      nameTe: r['name_te'] as String? ?? '',
      shortNameTe: r['short_name_te'] as String? ?? '',
      descriptionTe: r['description_te'] as String? ?? '',
      nameHi: r['name_hi'] as String? ?? '',
      shortNameHi: r['short_name_hi'] as String? ?? '',
      descriptionHi: r['description_hi'] as String? ?? '',
    )).toList();
  }

  static Future<List<LegalSection>> getSections({int? lawId, String? query}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (lawId != null && query != null && query.trim().isNotEmpty) {
      whereClause = 'law_id = ? AND (title LIKE ? OR title_te LIKE ? OR title_hi LIKE ? OR section_number LIKE ? OR keywords LIKE ? OR example_situation LIKE ? OR example_explanation LIKE ? OR quick_answer LIKE ? OR what_you_should_do LIKE ?)';
      final q = '%${query.trim()}%';
      whereArgs = [lawId, q, q, q, q, q, q, q, q, q];
    } else if (lawId != null) {
      whereClause = 'law_id = ?';
      whereArgs = [lawId];
    } else if (query != null && query.trim().isNotEmpty) {
      whereClause = 'title LIKE ? OR title_te LIKE ? OR title_hi LIKE ? OR section_number LIKE ? OR keywords LIKE ? OR example_situation LIKE ? OR example_explanation LIKE ? OR quick_answer LIKE ? OR what_you_should_do LIKE ?';
      final q = '%${query.trim()}%';
      whereArgs = [q, q, q, q, q, q, q, q, q];
    }

    final rows = await db.query(
      'sections',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id ASC',
    );
    final mapped = rows.map(_mapRowToSection).toList();
    final seen = <String>{};
    return mapped.where((s) => seen.add(s.provisionKey)).toList();
  }

  static Future<LegalSection?> getSectionById(int id) async {
    final db = await database;
    final rows = await db.query('sections', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _mapRowToSection(rows.first);
  }

  static Future<List<LegalSectionVersion>> getSectionVersions(int sectionId) async {
    final db = await database;
    final rows = await db.query(
      'section_versions',
      where: 'section_id = ?',
      whereArgs: [sectionId],
      orderBy: 'version DESC',
    );
    return rows.map((r) => LegalSectionVersion(
      id: r['id'] as int,
      sectionId: r['section_id'] as int,
      version: r['version'] as int? ?? 1,
      legalText: r['legal_text'] as String? ?? '',
      simpleExplanation: r['simple_explanation'] as String? ?? '',
      purpose: r['purpose'] as String? ?? '',
      punishment: r['punishment'] as String? ?? '',
      effectiveDate: r['effective_date'] as String?,
      amendmentInfo: r['amendment_info'] as String? ?? '',
      sourceName: r['source_name'] as String? ?? 'India Code (Official Government Source)',
      sourceUrl: r['source_url'] as String?,
      archivedAt: r['archived_at'] as String?,
      changeSummary: r['change_summary'] as String? ?? '',
    )).toList();
  }

  static Future<List<LegalMatter>> getMatters({int? categoryId}) async {
    final db = await database;
    final rows = await db.query(
      'matters',
      where: categoryId != null ? 'category_id = ?' : null,
      whereArgs: categoryId != null ? [categoryId] : null,
      orderBy: 'id ASC',
    );
    return rows.map((r) {
      List<int> rel = [];
      try {
        final raw = r['related_sections'] as String?;
        if (raw != null && raw.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(raw);
          rel = decoded.whereType<int>().toList();
        }
      } catch (_) {}

      return LegalMatter(
        id: r['id'] as int,
        categoryId: r['category_id'] as int? ?? 0,
        name: r['name'] as String? ?? '',
        description: r['description'] as String? ?? '',
        nameTe: r['name_te'] as String? ?? '',
        descriptionTe: r['description_te'] as String? ?? '',
        nameHi: r['name_hi'] as String? ?? '',
        descriptionHi: r['description_hi'] as String? ?? '',
        relatedSectionIds: rel,
      );
    }).toList();
  }

  static Future<Map<String, String>> getSyncMetadata() async {
    final db = await database;
    final rows = await db.query('sync_metadata');
    final Map<String, String> map = {};
    for (final r in rows) {
      map[r['key'] as String] = r['value'] as String? ?? '';
    }
    return map;
  }

  static Future<String?> getLastSyncTimestamp() async {
    final meta = await getSyncMetadata();
    return meta['last_sync_timestamp'];
  }

  static Future<DateTime?> getLastSyncDateTime() async {
    final str = await getLastSyncTimestamp();
    if (str == null || str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  static Future<String> getPrimarySourceName() async {
    final meta = await getSyncMetadata();
    return meta['primary_source_name'] ?? 'India Code (Official Government Source)';
  }

  static Future<String> getLastVerifiedDate() async {
    final meta = await getSyncMetadata();
    final val = meta['last_verified']?.trim();
    if (val == null || val.isEmpty || val == '2024-07-01') {
      return 'Not available';
    }
    return val;
  }

  static Future<int> updateSectionMedia({
    required int sectionId,
    required String visualImageUrl,
    required String visualCaption,
    required String visualAltText,
    required bool isVisualIllustrative,
    String? visualCaptionTe,
    String? visualCaptionHi,
    String? videoUrl,
    String? videoTitle,
    String? videoDuration,
    String? videoThumbnailUrl,
    String? videoTranscript,
    String? exampleTitle,
    String? exampleSituation,
    String? exampleExplanation,
    String? exampleDisclaimer,
    String? whatYouShouldDo,
  }) async {
    final db = await database;
    final Map<String, dynamic> updateMap = {
      'visual_image_url': visualImageUrl,
      'visual_caption': visualCaption,
      'visual_alt_text': visualAltText,
      'is_visual_illustrative': isVisualIllustrative ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (visualCaptionTe != null) updateMap['visual_caption_te'] = visualCaptionTe;
    if (visualCaptionHi != null) updateMap['visual_caption_hi'] = visualCaptionHi;
    if (videoUrl != null) updateMap['video_url'] = videoUrl;
    if (videoTitle != null) updateMap['video_title'] = videoTitle;
    if (videoDuration != null) updateMap['video_duration'] = videoDuration;
    if (videoThumbnailUrl != null) updateMap['video_thumbnail_url'] = videoThumbnailUrl;
    if (videoTranscript != null) updateMap['video_transcript'] = videoTranscript;
    if (exampleTitle != null) updateMap['example_title'] = exampleTitle;
    if (exampleSituation != null) updateMap['example_situation'] = exampleSituation;
    if (exampleExplanation != null) updateMap['example_explanation'] = exampleExplanation;
    if (exampleDisclaimer != null) updateMap['example_disclaimer'] = exampleDisclaimer;
    if (whatYouShouldDo != null) updateMap['what_you_should_do'] = whatYouShouldDo;

    return await db.update(
      'sections',
      updateMap,
      where: 'id = ?',
      whereArgs: [sectionId],
    );
  }

  static Future<Map<String, int>> getDatabaseStats() async {

    final db = await database;
    final actsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM laws')) ?? 0;
    final sectionsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sections')) ?? 0;
    final versionsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM section_versions')) ?? 0;
    return {
      'acts': actsCount,
      'sections': sectionsCount,
      'versions': versionsCount,
    };
  }

  static Future<List<Law>> getActsWithSectionCounts({
    String? status,
    String? domain,
    String? query,
  }) async {
    final db = await database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      whereClauses.add('LOWER(l.status) = ?');
      whereArgs.add(status.toLowerCase());
    }

    if (domain != null && domain.isNotEmpty && domain.toLowerCase() != 'all') {
      whereClauses.add('LOWER(c.name) = ?');
      whereArgs.add(domain.toLowerCase());
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(l.name) LIKE ? OR LOWER(l.short_name) LIKE ? OR CAST(l.year AS TEXT) LIKE ? OR LOWER(c.name) LIKE ?)');
      whereArgs.addAll([q, q, q, q]);
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final sql = '''
      SELECT l.*, c.name as category_name,
             COUNT(s.id) as sections_count,
             SUM(CASE WHEN LOWER(s.status) = 'current' THEN 1 ELSE 0 END) as current_sections_count,
             SUM(CASE WHEN LOWER(s.status) = 'amended' THEN 1 ELSE 0 END) as amended_sections_count,
             SUM(CASE WHEN LOWER(s.status) = 'historical' THEN 1 ELSE 0 END) as historical_sections_count,
             SUM(CASE WHEN LOWER(s.status) = 'repealed' THEN 1 ELSE 0 END) as repealed_sections_count
      FROM laws l
      LEFT JOIN categories c ON l.category_id = c.id
      LEFT JOIN sections s ON l.id = s.law_id
      $whereSql
      GROUP BY l.id
      ORDER BY l.id ASC
    ''';

    final rows = await db.rawQuery(sql, whereArgs);
    return rows.map((r) => Law(
      id: r['id'] as int,
      name: r['name'] as String? ?? '',
      shortName: r['short_name'] as String? ?? '',
      categoryId: r['category_id'] as int? ?? 0,
      description: r['description'] as String? ?? '',
      year: r['year'] as int?,
      actNumber: r['act_number'] as String?,
      sourceUrl: r['source_url'] as String?,
      sourceName: r['source_name'] as String? ?? 'India Code (Official Government Source)',
      status: r['status'] as String? ?? 'current',
      lastVerified: r['last_verified'] as String?,
      updatedAt: r['updated_at'] as String?,
      nameTe: r['name_te'] as String? ?? '',
      shortNameTe: r['short_name_te'] as String? ?? '',
      descriptionTe: r['description_te'] as String? ?? '',
      nameHi: r['name_hi'] as String? ?? '',
      shortNameHi: r['short_name_hi'] as String? ?? '',
      descriptionHi: r['description_hi'] as String? ?? '',
      domain: r['category_name'] as String? ?? 'General',
      sectionsCount: (r['sections_count'] as num?)?.toInt() ?? 0,
      currentSectionsCount: (r['current_sections_count'] as num?)?.toInt() ?? 0,
      amendedSectionsCount: (r['amended_sections_count'] as num?)?.toInt() ?? 0,
      historicalSectionsCount: (r['historical_sections_count'] as num?)?.toInt() ?? 0,
      repealedSectionsCount: (r['repealed_sections_count'] as num?)?.toInt() ?? 0,
    )).toList();
  }

  static Future<Map<String, dynamic>> getDetailedDatabaseStats() async {
    final db = await database;
    final totalActs = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM laws')) ?? 0;
    final totalSections = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM sections')) ?? 0;
    final currentSections = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM sections WHERE LOWER(status) = 'current'")) ?? 0;
    final amendedSections = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM sections WHERE LOWER(status) = 'amended'")) ?? 0;
    final historicalSections = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM sections WHERE LOWER(status) = 'historical'")) ?? 0;
    final repealedSections = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM sections WHERE LOWER(status) = 'repealed'")) ?? 0;
    final totalVersions = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM section_versions')) ?? 0;

    final meta = await getSyncMetadata();
    return {
      'total_acts': totalActs,
      'total_laws': totalActs,
      'total_sections': totalSections,
      'current_sections': currentSections,
      'amended_sections': amendedSections,
      'historical_sections': historicalSections,
      'repealed_sections': repealedSections,
      'versions': totalVersions,
      'version': meta['server_version'] ?? 'v1.0',
      'server_version': meta['server_version'] ?? '1',
      'last_synchronized': meta['last_sync_timestamp'] ?? DateTime.now().toIso8601String(),
      'sync_status': 'SQLite',
      'primary_source_name': meta['primary_source_name'] ?? 'India Code — Ministry of Law & Justice, Govt. of India',
      'primary_source_url': meta['primary_source_url'] ?? 'https://www.indiacode.gov.in/',
      'last_verified': meta['last_verified'] ?? '2024-07-01',
    };
  }

  static LegalSection _mapRowToSection(Map<String, dynamic> r) {
    List<int> rel = [];
    try {
      final raw = r['related_sections'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        rel = decoded.whereType<int>().toList();
      }
    } catch (_) {}

    return LegalSection(
      id: r['id'] as int,
      lawId: r['law_id'] as int? ?? 0,
      sectionNumber: r['section_number'] as String? ?? '',
      title: r['title'] as String? ?? '',
      legalText: r['legal_text'] as String? ?? '',
      simpleExplanation: r['simple_explanation'] as String? ?? '',
      purpose: r['purpose'] as String? ?? '',
      punishment: r['punishment'] as String? ?? '',
      relevantDocuments: r['relevant_documents'] as String? ?? '',
      keyElements: r['key_elements'] as String? ?? '',
      relevantInformation: r['relevant_information'] as String? ?? '',
      keywords: r['keywords'] as String? ?? '',
      badge: r['badge'] as String? ?? '',
      source: r['source'] as String? ?? '',
      lastVerified: r['last_verified'] as String?,
      relatedSectionIds: rel,
      directActionUrl: r['direct_action_url'] as String?,
      directActionLabel: r['direct_action_label'] as String?,
      directActionType: r['direct_action_type'] as String?,
      effectiveDate: r['effective_date'] as String?,
      amendmentInfo: r['amendment_info'] as String? ?? '',
      status: r['status'] as String? ?? 'current',
      sourceName: r['source_name'] as String? ?? 'India Code (Official Government Source)',
      version: r['version'] as int? ?? 1,
      previousVersionRef: r['previous_version_ref'] as String?,
      updatedAt: r['updated_at'] as String?,
      titleTe: r['title_te'] as String? ?? '',
      simpleExplanationTe: r['simple_explanation_te'] as String? ?? '',
      purposeTe: r['purpose_te'] as String? ?? '',
      punishmentTe: r['punishment_te'] as String? ?? '',
      keyElementsTe: r['key_elements_te'] as String? ?? '',
      relevantInformationTe: r['relevant_information_te'] as String? ?? '',
      relevantDocumentsTe: r['relevant_documents_te'] as String? ?? '',
      titleHi: r['title_hi'] as String? ?? '',
      simpleExplanationHi: r['simple_explanation_hi'] as String? ?? '',
      purposeHi: r['purpose_hi'] as String? ?? '',
      punishmentHi: r['punishment_hi'] as String? ?? '',
      keyElementsHi: r['key_elements_hi'] as String? ?? '',
      relevantInformationHi: r['relevant_information_hi'] as String? ?? '',
      relevantDocumentsHi: r['relevant_documents_hi'] as String? ?? '',
      sourceType: r['source_type'] as String? ?? 'Official Bare Act Gazette',
      quickAnswer: r['quick_answer'] as String? ?? '',
      quickAnswerTe: r['quick_answer_te'] as String? ?? '',
      quickAnswerHi: r['quick_answer_hi'] as String? ?? '',
      exampleTitle: r['example_title'] as String? ?? '',
      exampleTitleTe: r['example_title_te'] as String? ?? '',
      exampleTitleHi: r['example_title_hi'] as String? ?? '',
      exampleSituation: r['example_situation'] as String? ?? '',
      exampleSituationTe: r['example_situation_te'] as String? ?? '',
      exampleSituationHi: r['example_situation_hi'] as String? ?? '',
      exampleExplanation: r['example_explanation'] as String? ?? '',
      exampleExplanationTe: r['example_explanation_te'] as String? ?? '',
      exampleExplanationHi: r['example_explanation_hi'] as String? ?? '',
      exampleDisclaimer: r['example_disclaimer'] as String? ?? '',
      visualImageUrl: r['visual_image_url'] as String? ?? '',
      visualCaption: r['visual_caption'] as String? ?? '',
      visualCaptionTe: r['visual_caption_te'] as String? ?? '',
      visualCaptionHi: r['visual_caption_hi'] as String? ?? '',
      visualAltText: r['visual_alt_text'] as String? ?? '',
      isVisualIllustrative: (r['is_visual_illustrative'] as int? ?? 1) == 1,
      videoUrl: r['video_url'] as String? ?? '',
      videoTitle: r['video_title'] as String? ?? '',
      videoDuration: r['video_duration'] as String? ?? '',
      videoThumbnailUrl: r['video_thumbnail_url'] as String? ?? '',
      videoTranscript: r['video_transcript'] as String? ?? '',
      exampleSteps: r['example_steps'] as String? ?? '',
      whatYouShouldDo: r['what_you_should_do'] as String? ?? '',
      whatYouShouldDoTe: r['what_you_should_do_te'] as String? ?? '',
      whatYouShouldDoHi: r['what_you_should_do_hi'] as String? ?? '',
      consequencesType: r['consequences_type'] as String? ?? 'penal',
    );
  }

  // =========================================================================
  // CHAT HISTORY & CONVERSATION METHODS
  // =========================================================================

  static Future<List<Conversation>> getConversations({int limit = 50}) async {
    final db = await database;
    final rows = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map((r) => Conversation.fromMap(r)).toList();
  }

  static Future<Conversation?> getActiveConversation() async {
    final db = await database;
    final rows = await db.query(
      'conversations',
      where: 'is_active = 1',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return Conversation.fromMap(rows.first);
    }
    // Fallback: check most recently updated conversation
    final recent = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (recent.isNotEmpty) {
      final conv = Conversation.fromMap(recent.first);
      await setActiveConversation(conv.id);
      return conv;
    }
    return null;
  }

  static Future<void> saveConversation(Conversation conversation) async {
    final db = await database;
    await db.insert(
      'conversations',
      conversation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> setActiveConversation(String id) async {
    final db = await database;
    await db.rawUpdate('UPDATE conversations SET is_active = 0');
    if (id.isNotEmpty) {
      await db.rawUpdate('UPDATE conversations SET is_active = 1 WHERE id = ?', [id]);
    }
  }

  static Future<void> updateConversationTitle(String id, String newTitle) async {
    final db = await database;
    await db.update(
      'conversations',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete('chat_messages', where: 'conversation_id = ?', whereArgs: [id]);
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<ChatMessage>> getMessagesForConversation(String conversationId, {int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return rows.map((r) => ChatMessage.fromMap(r)).toList();
  }

  static Future<void> saveChatMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Touch conversation updated_at
    await db.update(
      'conversations',
      {'updated_at': message.timestamp.toIso8601String()},
      where: 'id = ?',
      whereArgs: [message.conversationId],
    );
  }
}
