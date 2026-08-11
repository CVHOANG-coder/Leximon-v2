// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TopicModelsTable extends TopicModels
    with TableInfo<$TopicModelsTable, TopicRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _translatedNameMeta = const VerificationMeta(
    'translatedName',
  );
  @override
  late final GeneratedColumn<String> translatedName = GeneratedColumn<String>(
    'translated_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSelectedMeta = const VerificationMeta(
    'isSelected',
  );
  @override
  late final GeneratedColumn<bool> isSelected = GeneratedColumn<bool>(
    'is_selected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_selected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalName,
    translatedName,
    isEnabled,
    sortOrder,
    isSelected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'TopicModel';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    }
    if (data.containsKey('translated_name')) {
      context.handle(
        _translatedNameMeta,
        translatedName.isAcceptableOrUnknown(
          data['translated_name']!,
          _translatedNameMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    } else if (isInserting) {
      context.missing(_isEnabledMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_selected')) {
      context.handle(
        _isSelectedMeta,
        isSelected.isAcceptableOrUnknown(data['is_selected']!, _isSelectedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TopicRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      ),
      translatedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translated_name'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      isSelected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_selected'],
      )!,
    );
  }

  @override
  $TopicModelsTable createAlias(String alias) {
    return $TopicModelsTable(attachedDatabase, alias);
  }
}

class TopicRow extends DataClass implements Insertable<TopicRow> {
  final int id;
  final String? originalName;
  final String? translatedName;
  final bool isEnabled;
  final int sortOrder;
  final bool isSelected;
  const TopicRow({
    required this.id,
    this.originalName,
    this.translatedName,
    required this.isEnabled,
    required this.sortOrder,
    required this.isSelected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || originalName != null) {
      map['original_name'] = Variable<String>(originalName);
    }
    if (!nullToAbsent || translatedName != null) {
      map['translated_name'] = Variable<String>(translatedName);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['order'] = Variable<int>(sortOrder);
    map['is_selected'] = Variable<bool>(isSelected);
    return map;
  }

  TopicModelsCompanion toCompanion(bool nullToAbsent) {
    return TopicModelsCompanion(
      id: Value(id),
      originalName: originalName == null && nullToAbsent
          ? const Value.absent()
          : Value(originalName),
      translatedName: translatedName == null && nullToAbsent
          ? const Value.absent()
          : Value(translatedName),
      isEnabled: Value(isEnabled),
      sortOrder: Value(sortOrder),
      isSelected: Value(isSelected),
    );
  }

  factory TopicRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicRow(
      id: serializer.fromJson<int>(json['id']),
      originalName: serializer.fromJson<String?>(json['originalName']),
      translatedName: serializer.fromJson<String?>(json['translatedName']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isSelected: serializer.fromJson<bool>(json['isSelected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalName': serializer.toJson<String?>(originalName),
      'translatedName': serializer.toJson<String?>(translatedName),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isSelected': serializer.toJson<bool>(isSelected),
    };
  }

  TopicRow copyWith({
    int? id,
    Value<String?> originalName = const Value.absent(),
    Value<String?> translatedName = const Value.absent(),
    bool? isEnabled,
    int? sortOrder,
    bool? isSelected,
  }) => TopicRow(
    id: id ?? this.id,
    originalName: originalName.present ? originalName.value : this.originalName,
    translatedName: translatedName.present
        ? translatedName.value
        : this.translatedName,
    isEnabled: isEnabled ?? this.isEnabled,
    sortOrder: sortOrder ?? this.sortOrder,
    isSelected: isSelected ?? this.isSelected,
  );
  TopicRow copyWithCompanion(TopicModelsCompanion data) {
    return TopicRow(
      id: data.id.present ? data.id.value : this.id,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      translatedName: data.translatedName.present
          ? data.translatedName.value
          : this.translatedName,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isSelected: data.isSelected.present
          ? data.isSelected.value
          : this.isSelected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicRow(')
          ..write('id: $id, ')
          ..write('originalName: $originalName, ')
          ..write('translatedName: $translatedName, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSelected: $isSelected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalName,
    translatedName,
    isEnabled,
    sortOrder,
    isSelected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicRow &&
          other.id == this.id &&
          other.originalName == this.originalName &&
          other.translatedName == this.translatedName &&
          other.isEnabled == this.isEnabled &&
          other.sortOrder == this.sortOrder &&
          other.isSelected == this.isSelected);
}

class TopicModelsCompanion extends UpdateCompanion<TopicRow> {
  final Value<int> id;
  final Value<String?> originalName;
  final Value<String?> translatedName;
  final Value<bool> isEnabled;
  final Value<int> sortOrder;
  final Value<bool> isSelected;
  const TopicModelsCompanion({
    this.id = const Value.absent(),
    this.originalName = const Value.absent(),
    this.translatedName = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isSelected = const Value.absent(),
  });
  TopicModelsCompanion.insert({
    this.id = const Value.absent(),
    this.originalName = const Value.absent(),
    this.translatedName = const Value.absent(),
    required bool isEnabled,
    required int sortOrder,
    this.isSelected = const Value.absent(),
  }) : isEnabled = Value(isEnabled),
       sortOrder = Value(sortOrder);
  static Insertable<TopicRow> custom({
    Expression<int>? id,
    Expression<String>? originalName,
    Expression<String>? translatedName,
    Expression<bool>? isEnabled,
    Expression<int>? sortOrder,
    Expression<bool>? isSelected,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalName != null) 'original_name': originalName,
      if (translatedName != null) 'translated_name': translatedName,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (sortOrder != null) 'order': sortOrder,
      if (isSelected != null) 'is_selected': isSelected,
    });
  }

  TopicModelsCompanion copyWith({
    Value<int>? id,
    Value<String?>? originalName,
    Value<String?>? translatedName,
    Value<bool>? isEnabled,
    Value<int>? sortOrder,
    Value<bool>? isSelected,
  }) {
    return TopicModelsCompanion(
      id: id ?? this.id,
      originalName: originalName ?? this.originalName,
      translatedName: translatedName ?? this.translatedName,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (translatedName.present) {
      map['translated_name'] = Variable<String>(translatedName.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (sortOrder.present) {
      map['order'] = Variable<int>(sortOrder.value);
    }
    if (isSelected.present) {
      map['is_selected'] = Variable<bool>(isSelected.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicModelsCompanion(')
          ..write('id: $id, ')
          ..write('originalName: $originalName, ')
          ..write('translatedName: $translatedName, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isSelected: $isSelected')
          ..write(')'))
        .toString();
  }
}

class $WordModelsTable extends WordModels
    with TableInfo<$WordModelsTable, WordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _writingMeta = const VerificationMeta(
    'writing',
  );
  @override
  late final GeneratedColumn<String> writing = GeneratedColumn<String>(
    'writing',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transcriptionMeta = const VerificationMeta(
    'transcription',
  );
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
    'transcription',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transliterationMeta = const VerificationMeta(
    'transliteration',
  );
  @override
  late final GeneratedColumn<String> transliteration = GeneratedColumn<String>(
    'transliteration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _showCountMeta = const VerificationMeta(
    'showCount',
  );
  @override
  late final GeneratedColumn<int> showCount = GeneratedColumn<int>(
    'show_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    writing,
    translation,
    transcription,
    transliteration,
    isEnabled,
    priority,
    level,
    showCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'WordModel';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('writing')) {
      context.handle(
        _writingMeta,
        writing.isAcceptableOrUnknown(data['writing']!, _writingMeta),
      );
    } else if (isInserting) {
      context.missing(_writingMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    if (data.containsKey('transcription')) {
      context.handle(
        _transcriptionMeta,
        transcription.isAcceptableOrUnknown(
          data['transcription']!,
          _transcriptionMeta,
        ),
      );
    }
    if (data.containsKey('transliteration')) {
      context.handle(
        _transliterationMeta,
        transliteration.isAcceptableOrUnknown(
          data['transliteration']!,
          _transliterationMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    } else if (isInserting) {
      context.missing(_isEnabledMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('show_count')) {
      context.handle(
        _showCountMeta,
        showCount.isAcceptableOrUnknown(data['show_count']!, _showCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, topicId};
  @override
  WordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_id'],
      )!,
      writing: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}writing'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
      transcription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcription'],
      ),
      transliteration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transliteration'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      showCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}show_count'],
      )!,
    );
  }

  @override
  $WordModelsTable createAlias(String alias) {
    return $WordModelsTable(attachedDatabase, alias);
  }
}

class WordRow extends DataClass implements Insertable<WordRow> {
  final int id;
  final int topicId;
  final String writing;
  final String translation;
  final String? transcription;
  final String? transliteration;
  final bool isEnabled;
  final int priority;
  final int level;
  final int showCount;
  const WordRow({
    required this.id,
    required this.topicId,
    required this.writing,
    required this.translation,
    this.transcription,
    this.transliteration,
    required this.isEnabled,
    required this.priority,
    required this.level,
    required this.showCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic_id'] = Variable<int>(topicId);
    map['writing'] = Variable<String>(writing);
    map['translation'] = Variable<String>(translation);
    if (!nullToAbsent || transcription != null) {
      map['transcription'] = Variable<String>(transcription);
    }
    if (!nullToAbsent || transliteration != null) {
      map['transliteration'] = Variable<String>(transliteration);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['priority'] = Variable<int>(priority);
    map['level'] = Variable<int>(level);
    map['show_count'] = Variable<int>(showCount);
    return map;
  }

  WordModelsCompanion toCompanion(bool nullToAbsent) {
    return WordModelsCompanion(
      id: Value(id),
      topicId: Value(topicId),
      writing: Value(writing),
      translation: Value(translation),
      transcription: transcription == null && nullToAbsent
          ? const Value.absent()
          : Value(transcription),
      transliteration: transliteration == null && nullToAbsent
          ? const Value.absent()
          : Value(transliteration),
      isEnabled: Value(isEnabled),
      priority: Value(priority),
      level: Value(level),
      showCount: Value(showCount),
    );
  }

  factory WordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRow(
      id: serializer.fromJson<int>(json['id']),
      topicId: serializer.fromJson<int>(json['topicId']),
      writing: serializer.fromJson<String>(json['writing']),
      translation: serializer.fromJson<String>(json['translation']),
      transcription: serializer.fromJson<String?>(json['transcription']),
      transliteration: serializer.fromJson<String?>(json['transliteration']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      priority: serializer.fromJson<int>(json['priority']),
      level: serializer.fromJson<int>(json['level']),
      showCount: serializer.fromJson<int>(json['showCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topicId': serializer.toJson<int>(topicId),
      'writing': serializer.toJson<String>(writing),
      'translation': serializer.toJson<String>(translation),
      'transcription': serializer.toJson<String?>(transcription),
      'transliteration': serializer.toJson<String?>(transliteration),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'priority': serializer.toJson<int>(priority),
      'level': serializer.toJson<int>(level),
      'showCount': serializer.toJson<int>(showCount),
    };
  }

  WordRow copyWith({
    int? id,
    int? topicId,
    String? writing,
    String? translation,
    Value<String?> transcription = const Value.absent(),
    Value<String?> transliteration = const Value.absent(),
    bool? isEnabled,
    int? priority,
    int? level,
    int? showCount,
  }) => WordRow(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    writing: writing ?? this.writing,
    translation: translation ?? this.translation,
    transcription: transcription.present
        ? transcription.value
        : this.transcription,
    transliteration: transliteration.present
        ? transliteration.value
        : this.transliteration,
    isEnabled: isEnabled ?? this.isEnabled,
    priority: priority ?? this.priority,
    level: level ?? this.level,
    showCount: showCount ?? this.showCount,
  );
  WordRow copyWithCompanion(WordModelsCompanion data) {
    return WordRow(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      writing: data.writing.present ? data.writing.value : this.writing,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
      transliteration: data.transliteration.present
          ? data.transliteration.value
          : this.transliteration,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      priority: data.priority.present ? data.priority.value : this.priority,
      level: data.level.present ? data.level.value : this.level,
      showCount: data.showCount.present ? data.showCount.value : this.showCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRow(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('writing: $writing, ')
          ..write('translation: $translation, ')
          ..write('transcription: $transcription, ')
          ..write('transliteration: $transliteration, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('priority: $priority, ')
          ..write('level: $level, ')
          ..write('showCount: $showCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topicId,
    writing,
    translation,
    transcription,
    transliteration,
    isEnabled,
    priority,
    level,
    showCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRow &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.writing == this.writing &&
          other.translation == this.translation &&
          other.transcription == this.transcription &&
          other.transliteration == this.transliteration &&
          other.isEnabled == this.isEnabled &&
          other.priority == this.priority &&
          other.level == this.level &&
          other.showCount == this.showCount);
}

class WordModelsCompanion extends UpdateCompanion<WordRow> {
  final Value<int> id;
  final Value<int> topicId;
  final Value<String> writing;
  final Value<String> translation;
  final Value<String?> transcription;
  final Value<String?> transliteration;
  final Value<bool> isEnabled;
  final Value<int> priority;
  final Value<int> level;
  final Value<int> showCount;
  final Value<int> rowid;
  const WordModelsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.writing = const Value.absent(),
    this.translation = const Value.absent(),
    this.transcription = const Value.absent(),
    this.transliteration = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.priority = const Value.absent(),
    this.level = const Value.absent(),
    this.showCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordModelsCompanion.insert({
    required int id,
    required int topicId,
    required String writing,
    required String translation,
    this.transcription = const Value.absent(),
    this.transliteration = const Value.absent(),
    required bool isEnabled,
    required int priority,
    required int level,
    this.showCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       topicId = Value(topicId),
       writing = Value(writing),
       translation = Value(translation),
       isEnabled = Value(isEnabled),
       priority = Value(priority),
       level = Value(level);
  static Insertable<WordRow> custom({
    Expression<int>? id,
    Expression<int>? topicId,
    Expression<String>? writing,
    Expression<String>? translation,
    Expression<String>? transcription,
    Expression<String>? transliteration,
    Expression<bool>? isEnabled,
    Expression<int>? priority,
    Expression<int>? level,
    Expression<int>? showCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (writing != null) 'writing': writing,
      if (translation != null) 'translation': translation,
      if (transcription != null) 'transcription': transcription,
      if (transliteration != null) 'transliteration': transliteration,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (priority != null) 'priority': priority,
      if (level != null) 'level': level,
      if (showCount != null) 'show_count': showCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordModelsCompanion copyWith({
    Value<int>? id,
    Value<int>? topicId,
    Value<String>? writing,
    Value<String>? translation,
    Value<String?>? transcription,
    Value<String?>? transliteration,
    Value<bool>? isEnabled,
    Value<int>? priority,
    Value<int>? level,
    Value<int>? showCount,
    Value<int>? rowid,
  }) {
    return WordModelsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      writing: writing ?? this.writing,
      translation: translation ?? this.translation,
      transcription: transcription ?? this.transcription,
      transliteration: transliteration ?? this.transliteration,
      isEnabled: isEnabled ?? this.isEnabled,
      priority: priority ?? this.priority,
      level: level ?? this.level,
      showCount: showCount ?? this.showCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (writing.present) {
      map['writing'] = Variable<String>(writing.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (transliteration.present) {
      map['transliteration'] = Variable<String>(transliteration.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (showCount.present) {
      map['show_count'] = Variable<int>(showCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordModelsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('writing: $writing, ')
          ..write('translation: $translation, ')
          ..write('transcription: $transcription, ')
          ..write('transliteration: $transliteration, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('priority: $priority, ')
          ..write('level: $level, ')
          ..write('showCount: $showCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningProgressModelsTable extends LearningProgressModels
    with TableInfo<$LearningProgressModelsTable, LearningProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningProgressModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creationDateMeta = const VerificationMeta(
    'creationDate',
  );
  @override
  late final GeneratedColumn<int> creationDate = GeneratedColumn<int>(
    'creation_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trainingProgressMeta = const VerificationMeta(
    'trainingProgress',
  );
  @override
  late final GeneratedColumn<int> trainingProgress = GeneratedColumn<int>(
    'training_progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _trainingErrorMeta = const VerificationMeta(
    'trainingError',
  );
  @override
  late final GeneratedColumn<int> trainingError = GeneratedColumn<int>(
    'training_error',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionStepMeta = const VerificationMeta(
    'repetitionStep',
  );
  @override
  late final GeneratedColumn<int> repetitionStep = GeneratedColumn<int>(
    'repetition_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionDateMeta = const VerificationMeta(
    'repetitionDate',
  );
  @override
  late final GeneratedColumn<int> repetitionDate = GeneratedColumn<int>(
    'repetition_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _learnedDateMeta = const VerificationMeta(
    'learnedDate',
  );
  @override
  late final GeneratedColumn<int> learnedDate = GeneratedColumn<int>(
    'learned_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onFastBrainMeta = const VerificationMeta(
    'onFastBrain',
  );
  @override
  late final GeneratedColumn<bool> onFastBrain = GeneratedColumn<bool>(
    'on_fast_brain',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_fast_brain" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _repetitionFastBrainStepMeta =
      const VerificationMeta('repetitionFastBrainStep');
  @override
  late final GeneratedColumn<int> repetitionFastBrainStep =
      GeneratedColumn<int>(
        'repetition_fast_brain_step',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _repetitionFastBrainDateMeta =
      const VerificationMeta('repetitionFastBrainDate');
  @override
  late final GeneratedColumn<int> repetitionFastBrainDate =
      GeneratedColumn<int>(
        'repetition_fast_brain_date',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _markedAsKnownMeta = const VerificationMeta(
    'markedAsKnown',
  );
  @override
  late final GeneratedColumn<bool> markedAsKnown = GeneratedColumn<bool>(
    'marked_as_known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("marked_as_known" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedByUserMeta = const VerificationMeta(
    'deletedByUser',
  );
  @override
  late final GeneratedColumn<bool> deletedByUser = GeneratedColumn<bool>(
    'deleted_by_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted_by_user" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    creationDate,
    trainingProgress,
    trainingError,
    repetitionStep,
    repetitionDate,
    learnedDate,
    onFastBrain,
    repetitionFastBrainStep,
    repetitionFastBrainDate,
    markedAsKnown,
    deletedByUser,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'LearningProgressModel';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('creation_date')) {
      context.handle(
        _creationDateMeta,
        creationDate.isAcceptableOrUnknown(
          data['creation_date']!,
          _creationDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creationDateMeta);
    }
    if (data.containsKey('training_progress')) {
      context.handle(
        _trainingProgressMeta,
        trainingProgress.isAcceptableOrUnknown(
          data['training_progress']!,
          _trainingProgressMeta,
        ),
      );
    }
    if (data.containsKey('training_error')) {
      context.handle(
        _trainingErrorMeta,
        trainingError.isAcceptableOrUnknown(
          data['training_error']!,
          _trainingErrorMeta,
        ),
      );
    }
    if (data.containsKey('repetition_step')) {
      context.handle(
        _repetitionStepMeta,
        repetitionStep.isAcceptableOrUnknown(
          data['repetition_step']!,
          _repetitionStepMeta,
        ),
      );
    }
    if (data.containsKey('repetition_date')) {
      context.handle(
        _repetitionDateMeta,
        repetitionDate.isAcceptableOrUnknown(
          data['repetition_date']!,
          _repetitionDateMeta,
        ),
      );
    }
    if (data.containsKey('learned_date')) {
      context.handle(
        _learnedDateMeta,
        learnedDate.isAcceptableOrUnknown(
          data['learned_date']!,
          _learnedDateMeta,
        ),
      );
    }
    if (data.containsKey('on_fast_brain')) {
      context.handle(
        _onFastBrainMeta,
        onFastBrain.isAcceptableOrUnknown(
          data['on_fast_brain']!,
          _onFastBrainMeta,
        ),
      );
    }
    if (data.containsKey('repetition_fast_brain_step')) {
      context.handle(
        _repetitionFastBrainStepMeta,
        repetitionFastBrainStep.isAcceptableOrUnknown(
          data['repetition_fast_brain_step']!,
          _repetitionFastBrainStepMeta,
        ),
      );
    }
    if (data.containsKey('repetition_fast_brain_date')) {
      context.handle(
        _repetitionFastBrainDateMeta,
        repetitionFastBrainDate.isAcceptableOrUnknown(
          data['repetition_fast_brain_date']!,
          _repetitionFastBrainDateMeta,
        ),
      );
    }
    if (data.containsKey('marked_as_known')) {
      context.handle(
        _markedAsKnownMeta,
        markedAsKnown.isAcceptableOrUnknown(
          data['marked_as_known']!,
          _markedAsKnownMeta,
        ),
      );
    }
    if (data.containsKey('deleted_by_user')) {
      context.handle(
        _deletedByUserMeta,
        deletedByUser.isAcceptableOrUnknown(
          data['deleted_by_user']!,
          _deletedByUserMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningProgressRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      creationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}creation_date'],
      )!,
      trainingProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}training_progress'],
      )!,
      trainingError: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}training_error'],
      )!,
      repetitionStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetition_step'],
      )!,
      repetitionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetition_date'],
      ),
      learnedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learned_date'],
      ),
      onFastBrain: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_fast_brain'],
      )!,
      repetitionFastBrainStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetition_fast_brain_step'],
      )!,
      repetitionFastBrainDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetition_fast_brain_date'],
      ),
      markedAsKnown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}marked_as_known'],
      )!,
      deletedByUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted_by_user'],
      )!,
    );
  }

  @override
  $LearningProgressModelsTable createAlias(String alias) {
    return $LearningProgressModelsTable(attachedDatabase, alias);
  }
}

class LearningProgressRow extends DataClass
    implements Insertable<LearningProgressRow> {
  final int id;
  final int creationDate;
  final int trainingProgress;
  final int trainingError;
  final int repetitionStep;
  final int? repetitionDate;
  final int? learnedDate;
  final bool onFastBrain;
  final int repetitionFastBrainStep;
  final int? repetitionFastBrainDate;
  final bool markedAsKnown;
  final bool deletedByUser;
  const LearningProgressRow({
    required this.id,
    required this.creationDate,
    required this.trainingProgress,
    required this.trainingError,
    required this.repetitionStep,
    this.repetitionDate,
    this.learnedDate,
    required this.onFastBrain,
    required this.repetitionFastBrainStep,
    this.repetitionFastBrainDate,
    required this.markedAsKnown,
    required this.deletedByUser,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['creation_date'] = Variable<int>(creationDate);
    map['training_progress'] = Variable<int>(trainingProgress);
    map['training_error'] = Variable<int>(trainingError);
    map['repetition_step'] = Variable<int>(repetitionStep);
    if (!nullToAbsent || repetitionDate != null) {
      map['repetition_date'] = Variable<int>(repetitionDate);
    }
    if (!nullToAbsent || learnedDate != null) {
      map['learned_date'] = Variable<int>(learnedDate);
    }
    map['on_fast_brain'] = Variable<bool>(onFastBrain);
    map['repetition_fast_brain_step'] = Variable<int>(repetitionFastBrainStep);
    if (!nullToAbsent || repetitionFastBrainDate != null) {
      map['repetition_fast_brain_date'] = Variable<int>(
        repetitionFastBrainDate,
      );
    }
    map['marked_as_known'] = Variable<bool>(markedAsKnown);
    map['deleted_by_user'] = Variable<bool>(deletedByUser);
    return map;
  }

  LearningProgressModelsCompanion toCompanion(bool nullToAbsent) {
    return LearningProgressModelsCompanion(
      id: Value(id),
      creationDate: Value(creationDate),
      trainingProgress: Value(trainingProgress),
      trainingError: Value(trainingError),
      repetitionStep: Value(repetitionStep),
      repetitionDate: repetitionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(repetitionDate),
      learnedDate: learnedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(learnedDate),
      onFastBrain: Value(onFastBrain),
      repetitionFastBrainStep: Value(repetitionFastBrainStep),
      repetitionFastBrainDate: repetitionFastBrainDate == null && nullToAbsent
          ? const Value.absent()
          : Value(repetitionFastBrainDate),
      markedAsKnown: Value(markedAsKnown),
      deletedByUser: Value(deletedByUser),
    );
  }

  factory LearningProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningProgressRow(
      id: serializer.fromJson<int>(json['id']),
      creationDate: serializer.fromJson<int>(json['creationDate']),
      trainingProgress: serializer.fromJson<int>(json['trainingProgress']),
      trainingError: serializer.fromJson<int>(json['trainingError']),
      repetitionStep: serializer.fromJson<int>(json['repetitionStep']),
      repetitionDate: serializer.fromJson<int?>(json['repetitionDate']),
      learnedDate: serializer.fromJson<int?>(json['learnedDate']),
      onFastBrain: serializer.fromJson<bool>(json['onFastBrain']),
      repetitionFastBrainStep: serializer.fromJson<int>(
        json['repetitionFastBrainStep'],
      ),
      repetitionFastBrainDate: serializer.fromJson<int?>(
        json['repetitionFastBrainDate'],
      ),
      markedAsKnown: serializer.fromJson<bool>(json['markedAsKnown']),
      deletedByUser: serializer.fromJson<bool>(json['deletedByUser']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'creationDate': serializer.toJson<int>(creationDate),
      'trainingProgress': serializer.toJson<int>(trainingProgress),
      'trainingError': serializer.toJson<int>(trainingError),
      'repetitionStep': serializer.toJson<int>(repetitionStep),
      'repetitionDate': serializer.toJson<int?>(repetitionDate),
      'learnedDate': serializer.toJson<int?>(learnedDate),
      'onFastBrain': serializer.toJson<bool>(onFastBrain),
      'repetitionFastBrainStep': serializer.toJson<int>(
        repetitionFastBrainStep,
      ),
      'repetitionFastBrainDate': serializer.toJson<int?>(
        repetitionFastBrainDate,
      ),
      'markedAsKnown': serializer.toJson<bool>(markedAsKnown),
      'deletedByUser': serializer.toJson<bool>(deletedByUser),
    };
  }

  LearningProgressRow copyWith({
    int? id,
    int? creationDate,
    int? trainingProgress,
    int? trainingError,
    int? repetitionStep,
    Value<int?> repetitionDate = const Value.absent(),
    Value<int?> learnedDate = const Value.absent(),
    bool? onFastBrain,
    int? repetitionFastBrainStep,
    Value<int?> repetitionFastBrainDate = const Value.absent(),
    bool? markedAsKnown,
    bool? deletedByUser,
  }) => LearningProgressRow(
    id: id ?? this.id,
    creationDate: creationDate ?? this.creationDate,
    trainingProgress: trainingProgress ?? this.trainingProgress,
    trainingError: trainingError ?? this.trainingError,
    repetitionStep: repetitionStep ?? this.repetitionStep,
    repetitionDate: repetitionDate.present
        ? repetitionDate.value
        : this.repetitionDate,
    learnedDate: learnedDate.present ? learnedDate.value : this.learnedDate,
    onFastBrain: onFastBrain ?? this.onFastBrain,
    repetitionFastBrainStep:
        repetitionFastBrainStep ?? this.repetitionFastBrainStep,
    repetitionFastBrainDate: repetitionFastBrainDate.present
        ? repetitionFastBrainDate.value
        : this.repetitionFastBrainDate,
    markedAsKnown: markedAsKnown ?? this.markedAsKnown,
    deletedByUser: deletedByUser ?? this.deletedByUser,
  );
  LearningProgressRow copyWithCompanion(LearningProgressModelsCompanion data) {
    return LearningProgressRow(
      id: data.id.present ? data.id.value : this.id,
      creationDate: data.creationDate.present
          ? data.creationDate.value
          : this.creationDate,
      trainingProgress: data.trainingProgress.present
          ? data.trainingProgress.value
          : this.trainingProgress,
      trainingError: data.trainingError.present
          ? data.trainingError.value
          : this.trainingError,
      repetitionStep: data.repetitionStep.present
          ? data.repetitionStep.value
          : this.repetitionStep,
      repetitionDate: data.repetitionDate.present
          ? data.repetitionDate.value
          : this.repetitionDate,
      learnedDate: data.learnedDate.present
          ? data.learnedDate.value
          : this.learnedDate,
      onFastBrain: data.onFastBrain.present
          ? data.onFastBrain.value
          : this.onFastBrain,
      repetitionFastBrainStep: data.repetitionFastBrainStep.present
          ? data.repetitionFastBrainStep.value
          : this.repetitionFastBrainStep,
      repetitionFastBrainDate: data.repetitionFastBrainDate.present
          ? data.repetitionFastBrainDate.value
          : this.repetitionFastBrainDate,
      markedAsKnown: data.markedAsKnown.present
          ? data.markedAsKnown.value
          : this.markedAsKnown,
      deletedByUser: data.deletedByUser.present
          ? data.deletedByUser.value
          : this.deletedByUser,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningProgressRow(')
          ..write('id: $id, ')
          ..write('creationDate: $creationDate, ')
          ..write('trainingProgress: $trainingProgress, ')
          ..write('trainingError: $trainingError, ')
          ..write('repetitionStep: $repetitionStep, ')
          ..write('repetitionDate: $repetitionDate, ')
          ..write('learnedDate: $learnedDate, ')
          ..write('onFastBrain: $onFastBrain, ')
          ..write('repetitionFastBrainStep: $repetitionFastBrainStep, ')
          ..write('repetitionFastBrainDate: $repetitionFastBrainDate, ')
          ..write('markedAsKnown: $markedAsKnown, ')
          ..write('deletedByUser: $deletedByUser')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    creationDate,
    trainingProgress,
    trainingError,
    repetitionStep,
    repetitionDate,
    learnedDate,
    onFastBrain,
    repetitionFastBrainStep,
    repetitionFastBrainDate,
    markedAsKnown,
    deletedByUser,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningProgressRow &&
          other.id == this.id &&
          other.creationDate == this.creationDate &&
          other.trainingProgress == this.trainingProgress &&
          other.trainingError == this.trainingError &&
          other.repetitionStep == this.repetitionStep &&
          other.repetitionDate == this.repetitionDate &&
          other.learnedDate == this.learnedDate &&
          other.onFastBrain == this.onFastBrain &&
          other.repetitionFastBrainStep == this.repetitionFastBrainStep &&
          other.repetitionFastBrainDate == this.repetitionFastBrainDate &&
          other.markedAsKnown == this.markedAsKnown &&
          other.deletedByUser == this.deletedByUser);
}

class LearningProgressModelsCompanion
    extends UpdateCompanion<LearningProgressRow> {
  final Value<int> id;
  final Value<int> creationDate;
  final Value<int> trainingProgress;
  final Value<int> trainingError;
  final Value<int> repetitionStep;
  final Value<int?> repetitionDate;
  final Value<int?> learnedDate;
  final Value<bool> onFastBrain;
  final Value<int> repetitionFastBrainStep;
  final Value<int?> repetitionFastBrainDate;
  final Value<bool> markedAsKnown;
  final Value<bool> deletedByUser;
  const LearningProgressModelsCompanion({
    this.id = const Value.absent(),
    this.creationDate = const Value.absent(),
    this.trainingProgress = const Value.absent(),
    this.trainingError = const Value.absent(),
    this.repetitionStep = const Value.absent(),
    this.repetitionDate = const Value.absent(),
    this.learnedDate = const Value.absent(),
    this.onFastBrain = const Value.absent(),
    this.repetitionFastBrainStep = const Value.absent(),
    this.repetitionFastBrainDate = const Value.absent(),
    this.markedAsKnown = const Value.absent(),
    this.deletedByUser = const Value.absent(),
  });
  LearningProgressModelsCompanion.insert({
    this.id = const Value.absent(),
    required int creationDate,
    this.trainingProgress = const Value.absent(),
    this.trainingError = const Value.absent(),
    this.repetitionStep = const Value.absent(),
    this.repetitionDate = const Value.absent(),
    this.learnedDate = const Value.absent(),
    this.onFastBrain = const Value.absent(),
    this.repetitionFastBrainStep = const Value.absent(),
    this.repetitionFastBrainDate = const Value.absent(),
    this.markedAsKnown = const Value.absent(),
    this.deletedByUser = const Value.absent(),
  }) : creationDate = Value(creationDate);
  static Insertable<LearningProgressRow> custom({
    Expression<int>? id,
    Expression<int>? creationDate,
    Expression<int>? trainingProgress,
    Expression<int>? trainingError,
    Expression<int>? repetitionStep,
    Expression<int>? repetitionDate,
    Expression<int>? learnedDate,
    Expression<bool>? onFastBrain,
    Expression<int>? repetitionFastBrainStep,
    Expression<int>? repetitionFastBrainDate,
    Expression<bool>? markedAsKnown,
    Expression<bool>? deletedByUser,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (creationDate != null) 'creation_date': creationDate,
      if (trainingProgress != null) 'training_progress': trainingProgress,
      if (trainingError != null) 'training_error': trainingError,
      if (repetitionStep != null) 'repetition_step': repetitionStep,
      if (repetitionDate != null) 'repetition_date': repetitionDate,
      if (learnedDate != null) 'learned_date': learnedDate,
      if (onFastBrain != null) 'on_fast_brain': onFastBrain,
      if (repetitionFastBrainStep != null)
        'repetition_fast_brain_step': repetitionFastBrainStep,
      if (repetitionFastBrainDate != null)
        'repetition_fast_brain_date': repetitionFastBrainDate,
      if (markedAsKnown != null) 'marked_as_known': markedAsKnown,
      if (deletedByUser != null) 'deleted_by_user': deletedByUser,
    });
  }

  LearningProgressModelsCompanion copyWith({
    Value<int>? id,
    Value<int>? creationDate,
    Value<int>? trainingProgress,
    Value<int>? trainingError,
    Value<int>? repetitionStep,
    Value<int?>? repetitionDate,
    Value<int?>? learnedDate,
    Value<bool>? onFastBrain,
    Value<int>? repetitionFastBrainStep,
    Value<int?>? repetitionFastBrainDate,
    Value<bool>? markedAsKnown,
    Value<bool>? deletedByUser,
  }) {
    return LearningProgressModelsCompanion(
      id: id ?? this.id,
      creationDate: creationDate ?? this.creationDate,
      trainingProgress: trainingProgress ?? this.trainingProgress,
      trainingError: trainingError ?? this.trainingError,
      repetitionStep: repetitionStep ?? this.repetitionStep,
      repetitionDate: repetitionDate ?? this.repetitionDate,
      learnedDate: learnedDate ?? this.learnedDate,
      onFastBrain: onFastBrain ?? this.onFastBrain,
      repetitionFastBrainStep:
          repetitionFastBrainStep ?? this.repetitionFastBrainStep,
      repetitionFastBrainDate:
          repetitionFastBrainDate ?? this.repetitionFastBrainDate,
      markedAsKnown: markedAsKnown ?? this.markedAsKnown,
      deletedByUser: deletedByUser ?? this.deletedByUser,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (creationDate.present) {
      map['creation_date'] = Variable<int>(creationDate.value);
    }
    if (trainingProgress.present) {
      map['training_progress'] = Variable<int>(trainingProgress.value);
    }
    if (trainingError.present) {
      map['training_error'] = Variable<int>(trainingError.value);
    }
    if (repetitionStep.present) {
      map['repetition_step'] = Variable<int>(repetitionStep.value);
    }
    if (repetitionDate.present) {
      map['repetition_date'] = Variable<int>(repetitionDate.value);
    }
    if (learnedDate.present) {
      map['learned_date'] = Variable<int>(learnedDate.value);
    }
    if (onFastBrain.present) {
      map['on_fast_brain'] = Variable<bool>(onFastBrain.value);
    }
    if (repetitionFastBrainStep.present) {
      map['repetition_fast_brain_step'] = Variable<int>(
        repetitionFastBrainStep.value,
      );
    }
    if (repetitionFastBrainDate.present) {
      map['repetition_fast_brain_date'] = Variable<int>(
        repetitionFastBrainDate.value,
      );
    }
    if (markedAsKnown.present) {
      map['marked_as_known'] = Variable<bool>(markedAsKnown.value);
    }
    if (deletedByUser.present) {
      map['deleted_by_user'] = Variable<bool>(deletedByUser.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningProgressModelsCompanion(')
          ..write('id: $id, ')
          ..write('creationDate: $creationDate, ')
          ..write('trainingProgress: $trainingProgress, ')
          ..write('trainingError: $trainingError, ')
          ..write('repetitionStep: $repetitionStep, ')
          ..write('repetitionDate: $repetitionDate, ')
          ..write('learnedDate: $learnedDate, ')
          ..write('onFastBrain: $onFastBrain, ')
          ..write('repetitionFastBrainStep: $repetitionFastBrainStep, ')
          ..write('repetitionFastBrainDate: $repetitionFastBrainDate, ')
          ..write('markedAsKnown: $markedAsKnown, ')
          ..write('deletedByUser: $deletedByUser')
          ..write(')'))
        .toString();
  }
}

class $WordSentenceProgressModelsTable extends WordSentenceProgressModels
    with TableInfo<$WordSentenceProgressModelsTable, WordSentenceProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordSentenceProgressModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedCountMeta = const VerificationMeta(
    'finishedCount',
  );
  @override
  late final GeneratedColumn<int> finishedCount = GeneratedColumn<int>(
    'finished_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [wordId, finishedCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_sentence_progress_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordSentenceProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('finished_count')) {
      context.handle(
        _finishedCountMeta,
        finishedCount.isAcceptableOrUnknown(
          data['finished_count']!,
          _finishedCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  WordSentenceProgressRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordSentenceProgressRow(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      finishedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_count'],
      )!,
    );
  }

  @override
  $WordSentenceProgressModelsTable createAlias(String alias) {
    return $WordSentenceProgressModelsTable(attachedDatabase, alias);
  }
}

class WordSentenceProgressRow extends DataClass
    implements Insertable<WordSentenceProgressRow> {
  final int wordId;
  final int finishedCount;
  const WordSentenceProgressRow({
    required this.wordId,
    required this.finishedCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['finished_count'] = Variable<int>(finishedCount);
    return map;
  }

  WordSentenceProgressModelsCompanion toCompanion(bool nullToAbsent) {
    return WordSentenceProgressModelsCompanion(
      wordId: Value(wordId),
      finishedCount: Value(finishedCount),
    );
  }

  factory WordSentenceProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordSentenceProgressRow(
      wordId: serializer.fromJson<int>(json['wordId']),
      finishedCount: serializer.fromJson<int>(json['finishedCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'finishedCount': serializer.toJson<int>(finishedCount),
    };
  }

  WordSentenceProgressRow copyWith({int? wordId, int? finishedCount}) =>
      WordSentenceProgressRow(
        wordId: wordId ?? this.wordId,
        finishedCount: finishedCount ?? this.finishedCount,
      );
  WordSentenceProgressRow copyWithCompanion(
    WordSentenceProgressModelsCompanion data,
  ) {
    return WordSentenceProgressRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      finishedCount: data.finishedCount.present
          ? data.finishedCount.value
          : this.finishedCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordSentenceProgressRow(')
          ..write('wordId: $wordId, ')
          ..write('finishedCount: $finishedCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, finishedCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordSentenceProgressRow &&
          other.wordId == this.wordId &&
          other.finishedCount == this.finishedCount);
}

class WordSentenceProgressModelsCompanion
    extends UpdateCompanion<WordSentenceProgressRow> {
  final Value<int> wordId;
  final Value<int> finishedCount;
  const WordSentenceProgressModelsCompanion({
    this.wordId = const Value.absent(),
    this.finishedCount = const Value.absent(),
  });
  WordSentenceProgressModelsCompanion.insert({
    this.wordId = const Value.absent(),
    this.finishedCount = const Value.absent(),
  });
  static Insertable<WordSentenceProgressRow> custom({
    Expression<int>? wordId,
    Expression<int>? finishedCount,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (finishedCount != null) 'finished_count': finishedCount,
    });
  }

  WordSentenceProgressModelsCompanion copyWith({
    Value<int>? wordId,
    Value<int>? finishedCount,
  }) {
    return WordSentenceProgressModelsCompanion(
      wordId: wordId ?? this.wordId,
      finishedCount: finishedCount ?? this.finishedCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (finishedCount.present) {
      map['finished_count'] = Variable<int>(finishedCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordSentenceProgressModelsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('finishedCount: $finishedCount')
          ..write(')'))
        .toString();
  }
}

class $SentenceExposureModelsTable extends SentenceExposureModels
    with TableInfo<$SentenceExposureModelsTable, SentenceExposureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SentenceExposureModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sentenceIdMeta = const VerificationMeta(
    'sentenceId',
  );
  @override
  late final GeneratedColumn<int> sentenceId = GeneratedColumn<int>(
    'sentence_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedCountMeta = const VerificationMeta(
    'finishedCount',
  );
  @override
  late final GeneratedColumn<int> finishedCount = GeneratedColumn<int>(
    'finished_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _insertWordTaskMeta = const VerificationMeta(
    'insertWordTask',
  );
  @override
  late final GeneratedColumn<int> insertWordTask = GeneratedColumn<int>(
    'insert_word_task',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _constructorTaskMeta = const VerificationMeta(
    'constructorTask',
  );
  @override
  late final GeneratedColumn<int> constructorTask = GeneratedColumn<int>(
    'constructor_task',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _constructorAudioTaskMeta =
      const VerificationMeta('constructorAudioTask');
  @override
  late final GeneratedColumn<int> constructorAudioTask = GeneratedColumn<int>(
    'constructor_audio_task',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _constructorInverseTaskMeta =
      const VerificationMeta('constructorInverseTask');
  @override
  late final GeneratedColumn<int> constructorInverseTask = GeneratedColumn<int>(
    'constructor_inverse_task',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sentenceId,
    wordId,
    finishedCount,
    insertWordTask,
    constructorTask,
    constructorAudioTask,
    constructorInverseTask,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sentence_exposure_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<SentenceExposureRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sentence_id')) {
      context.handle(
        _sentenceIdMeta,
        sentenceId.isAcceptableOrUnknown(data['sentence_id']!, _sentenceIdMeta),
      );
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('finished_count')) {
      context.handle(
        _finishedCountMeta,
        finishedCount.isAcceptableOrUnknown(
          data['finished_count']!,
          _finishedCountMeta,
        ),
      );
    }
    if (data.containsKey('insert_word_task')) {
      context.handle(
        _insertWordTaskMeta,
        insertWordTask.isAcceptableOrUnknown(
          data['insert_word_task']!,
          _insertWordTaskMeta,
        ),
      );
    }
    if (data.containsKey('constructor_task')) {
      context.handle(
        _constructorTaskMeta,
        constructorTask.isAcceptableOrUnknown(
          data['constructor_task']!,
          _constructorTaskMeta,
        ),
      );
    }
    if (data.containsKey('constructor_audio_task')) {
      context.handle(
        _constructorAudioTaskMeta,
        constructorAudioTask.isAcceptableOrUnknown(
          data['constructor_audio_task']!,
          _constructorAudioTaskMeta,
        ),
      );
    }
    if (data.containsKey('constructor_inverse_task')) {
      context.handle(
        _constructorInverseTaskMeta,
        constructorInverseTask.isAcceptableOrUnknown(
          data['constructor_inverse_task']!,
          _constructorInverseTaskMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sentenceId};
  @override
  SentenceExposureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SentenceExposureRow(
      sentenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sentence_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      finishedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_count'],
      )!,
      insertWordTask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}insert_word_task'],
      )!,
      constructorTask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}constructor_task'],
      )!,
      constructorAudioTask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}constructor_audio_task'],
      )!,
      constructorInverseTask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}constructor_inverse_task'],
      )!,
    );
  }

  @override
  $SentenceExposureModelsTable createAlias(String alias) {
    return $SentenceExposureModelsTable(attachedDatabase, alias);
  }
}

class SentenceExposureRow extends DataClass
    implements Insertable<SentenceExposureRow> {
  final int sentenceId;
  final int wordId;
  final int finishedCount;
  final int insertWordTask;
  final int constructorTask;
  final int constructorAudioTask;
  final int constructorInverseTask;
  const SentenceExposureRow({
    required this.sentenceId,
    required this.wordId,
    required this.finishedCount,
    required this.insertWordTask,
    required this.constructorTask,
    required this.constructorAudioTask,
    required this.constructorInverseTask,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sentence_id'] = Variable<int>(sentenceId);
    map['word_id'] = Variable<int>(wordId);
    map['finished_count'] = Variable<int>(finishedCount);
    map['insert_word_task'] = Variable<int>(insertWordTask);
    map['constructor_task'] = Variable<int>(constructorTask);
    map['constructor_audio_task'] = Variable<int>(constructorAudioTask);
    map['constructor_inverse_task'] = Variable<int>(constructorInverseTask);
    return map;
  }

  SentenceExposureModelsCompanion toCompanion(bool nullToAbsent) {
    return SentenceExposureModelsCompanion(
      sentenceId: Value(sentenceId),
      wordId: Value(wordId),
      finishedCount: Value(finishedCount),
      insertWordTask: Value(insertWordTask),
      constructorTask: Value(constructorTask),
      constructorAudioTask: Value(constructorAudioTask),
      constructorInverseTask: Value(constructorInverseTask),
    );
  }

  factory SentenceExposureRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SentenceExposureRow(
      sentenceId: serializer.fromJson<int>(json['sentenceId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      finishedCount: serializer.fromJson<int>(json['finishedCount']),
      insertWordTask: serializer.fromJson<int>(json['insertWordTask']),
      constructorTask: serializer.fromJson<int>(json['constructorTask']),
      constructorAudioTask: serializer.fromJson<int>(
        json['constructorAudioTask'],
      ),
      constructorInverseTask: serializer.fromJson<int>(
        json['constructorInverseTask'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sentenceId': serializer.toJson<int>(sentenceId),
      'wordId': serializer.toJson<int>(wordId),
      'finishedCount': serializer.toJson<int>(finishedCount),
      'insertWordTask': serializer.toJson<int>(insertWordTask),
      'constructorTask': serializer.toJson<int>(constructorTask),
      'constructorAudioTask': serializer.toJson<int>(constructorAudioTask),
      'constructorInverseTask': serializer.toJson<int>(constructorInverseTask),
    };
  }

  SentenceExposureRow copyWith({
    int? sentenceId,
    int? wordId,
    int? finishedCount,
    int? insertWordTask,
    int? constructorTask,
    int? constructorAudioTask,
    int? constructorInverseTask,
  }) => SentenceExposureRow(
    sentenceId: sentenceId ?? this.sentenceId,
    wordId: wordId ?? this.wordId,
    finishedCount: finishedCount ?? this.finishedCount,
    insertWordTask: insertWordTask ?? this.insertWordTask,
    constructorTask: constructorTask ?? this.constructorTask,
    constructorAudioTask: constructorAudioTask ?? this.constructorAudioTask,
    constructorInverseTask:
        constructorInverseTask ?? this.constructorInverseTask,
  );
  SentenceExposureRow copyWithCompanion(SentenceExposureModelsCompanion data) {
    return SentenceExposureRow(
      sentenceId: data.sentenceId.present
          ? data.sentenceId.value
          : this.sentenceId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      finishedCount: data.finishedCount.present
          ? data.finishedCount.value
          : this.finishedCount,
      insertWordTask: data.insertWordTask.present
          ? data.insertWordTask.value
          : this.insertWordTask,
      constructorTask: data.constructorTask.present
          ? data.constructorTask.value
          : this.constructorTask,
      constructorAudioTask: data.constructorAudioTask.present
          ? data.constructorAudioTask.value
          : this.constructorAudioTask,
      constructorInverseTask: data.constructorInverseTask.present
          ? data.constructorInverseTask.value
          : this.constructorInverseTask,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SentenceExposureRow(')
          ..write('sentenceId: $sentenceId, ')
          ..write('wordId: $wordId, ')
          ..write('finishedCount: $finishedCount, ')
          ..write('insertWordTask: $insertWordTask, ')
          ..write('constructorTask: $constructorTask, ')
          ..write('constructorAudioTask: $constructorAudioTask, ')
          ..write('constructorInverseTask: $constructorInverseTask')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sentenceId,
    wordId,
    finishedCount,
    insertWordTask,
    constructorTask,
    constructorAudioTask,
    constructorInverseTask,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SentenceExposureRow &&
          other.sentenceId == this.sentenceId &&
          other.wordId == this.wordId &&
          other.finishedCount == this.finishedCount &&
          other.insertWordTask == this.insertWordTask &&
          other.constructorTask == this.constructorTask &&
          other.constructorAudioTask == this.constructorAudioTask &&
          other.constructorInverseTask == this.constructorInverseTask);
}

class SentenceExposureModelsCompanion
    extends UpdateCompanion<SentenceExposureRow> {
  final Value<int> sentenceId;
  final Value<int> wordId;
  final Value<int> finishedCount;
  final Value<int> insertWordTask;
  final Value<int> constructorTask;
  final Value<int> constructorAudioTask;
  final Value<int> constructorInverseTask;
  const SentenceExposureModelsCompanion({
    this.sentenceId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.finishedCount = const Value.absent(),
    this.insertWordTask = const Value.absent(),
    this.constructorTask = const Value.absent(),
    this.constructorAudioTask = const Value.absent(),
    this.constructorInverseTask = const Value.absent(),
  });
  SentenceExposureModelsCompanion.insert({
    this.sentenceId = const Value.absent(),
    required int wordId,
    this.finishedCount = const Value.absent(),
    this.insertWordTask = const Value.absent(),
    this.constructorTask = const Value.absent(),
    this.constructorAudioTask = const Value.absent(),
    this.constructorInverseTask = const Value.absent(),
  }) : wordId = Value(wordId);
  static Insertable<SentenceExposureRow> custom({
    Expression<int>? sentenceId,
    Expression<int>? wordId,
    Expression<int>? finishedCount,
    Expression<int>? insertWordTask,
    Expression<int>? constructorTask,
    Expression<int>? constructorAudioTask,
    Expression<int>? constructorInverseTask,
  }) {
    return RawValuesInsertable({
      if (sentenceId != null) 'sentence_id': sentenceId,
      if (wordId != null) 'word_id': wordId,
      if (finishedCount != null) 'finished_count': finishedCount,
      if (insertWordTask != null) 'insert_word_task': insertWordTask,
      if (constructorTask != null) 'constructor_task': constructorTask,
      if (constructorAudioTask != null)
        'constructor_audio_task': constructorAudioTask,
      if (constructorInverseTask != null)
        'constructor_inverse_task': constructorInverseTask,
    });
  }

  SentenceExposureModelsCompanion copyWith({
    Value<int>? sentenceId,
    Value<int>? wordId,
    Value<int>? finishedCount,
    Value<int>? insertWordTask,
    Value<int>? constructorTask,
    Value<int>? constructorAudioTask,
    Value<int>? constructorInverseTask,
  }) {
    return SentenceExposureModelsCompanion(
      sentenceId: sentenceId ?? this.sentenceId,
      wordId: wordId ?? this.wordId,
      finishedCount: finishedCount ?? this.finishedCount,
      insertWordTask: insertWordTask ?? this.insertWordTask,
      constructorTask: constructorTask ?? this.constructorTask,
      constructorAudioTask: constructorAudioTask ?? this.constructorAudioTask,
      constructorInverseTask:
          constructorInverseTask ?? this.constructorInverseTask,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sentenceId.present) {
      map['sentence_id'] = Variable<int>(sentenceId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (finishedCount.present) {
      map['finished_count'] = Variable<int>(finishedCount.value);
    }
    if (insertWordTask.present) {
      map['insert_word_task'] = Variable<int>(insertWordTask.value);
    }
    if (constructorTask.present) {
      map['constructor_task'] = Variable<int>(constructorTask.value);
    }
    if (constructorAudioTask.present) {
      map['constructor_audio_task'] = Variable<int>(constructorAudioTask.value);
    }
    if (constructorInverseTask.present) {
      map['constructor_inverse_task'] = Variable<int>(
        constructorInverseTask.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SentenceExposureModelsCompanion(')
          ..write('sentenceId: $sentenceId, ')
          ..write('wordId: $wordId, ')
          ..write('finishedCount: $finishedCount, ')
          ..write('insertWordTask: $insertWordTask, ')
          ..write('constructorTask: $constructorTask, ')
          ..write('constructorAudioTask: $constructorAudioTask, ')
          ..write('constructorInverseTask: $constructorInverseTask')
          ..write(')'))
        .toString();
  }
}

class $LearningSessionsTable extends LearningSessions
    with TableInfo<$LearningSessionsTable, LearningSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
    'topic_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _requiredMaskMeta = const VerificationMeta(
    'requiredMask',
  );
  @override
  late final GeneratedColumn<int> requiredMask = GeneratedColumn<int>(
    'required_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalExerciseCountMeta =
      const VerificationMeta('originalExerciseCount');
  @override
  late final GeneratedColumn<int> originalExerciseCount = GeneratedColumn<int>(
    'original_exercise_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentIndexMeta = const VerificationMeta(
    'currentIndex',
  );
  @override
  late final GeneratedColumn<int> currentIndex = GeneratedColumn<int>(
    'current_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completionAppliedAtMeta =
      const VerificationMeta('completionAppliedAt');
  @override
  late final GeneratedColumn<int> completionAppliedAt = GeneratedColumn<int>(
    'completion_applied_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _successfulWordCountMeta =
      const VerificationMeta('successfulWordCount');
  @override
  late final GeneratedColumn<int> successfulWordCount = GeneratedColumn<int>(
    'successful_word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unresolvedWrongWordCountMeta =
      const VerificationMeta('unresolvedWrongWordCount');
  @override
  late final GeneratedColumn<int> unresolvedWrongWordCount =
      GeneratedColumn<int>(
        'unresolved_wrong_word_count',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _completedWordCountMeta =
      const VerificationMeta('completedWordCount');
  @override
  late final GeneratedColumn<int> completedWordCount = GeneratedColumn<int>(
    'completed_word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _newlyLearnedWordCountMeta =
      const VerificationMeta('newlyLearnedWordCount');
  @override
  late final GeneratedColumn<int> newlyLearnedWordCount = GeneratedColumn<int>(
    'newly_learned_word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    status,
    requiredMask,
    originalExerciseCount,
    currentIndex,
    startedAt,
    completedAt,
    completionAppliedAt,
    successfulWordCount,
    unresolvedWrongWordCount,
    completedWordCount,
    newlyLearnedWordCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'LearningSession';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('required_mask')) {
      context.handle(
        _requiredMaskMeta,
        requiredMask.isAcceptableOrUnknown(
          data['required_mask']!,
          _requiredMaskMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requiredMaskMeta);
    }
    if (data.containsKey('original_exercise_count')) {
      context.handle(
        _originalExerciseCountMeta,
        originalExerciseCount.isAcceptableOrUnknown(
          data['original_exercise_count']!,
          _originalExerciseCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalExerciseCountMeta);
    }
    if (data.containsKey('current_index')) {
      context.handle(
        _currentIndexMeta,
        currentIndex.isAcceptableOrUnknown(
          data['current_index']!,
          _currentIndexMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('completion_applied_at')) {
      context.handle(
        _completionAppliedAtMeta,
        completionAppliedAt.isAcceptableOrUnknown(
          data['completion_applied_at']!,
          _completionAppliedAtMeta,
        ),
      );
    }
    if (data.containsKey('successful_word_count')) {
      context.handle(
        _successfulWordCountMeta,
        successfulWordCount.isAcceptableOrUnknown(
          data['successful_word_count']!,
          _successfulWordCountMeta,
        ),
      );
    }
    if (data.containsKey('unresolved_wrong_word_count')) {
      context.handle(
        _unresolvedWrongWordCountMeta,
        unresolvedWrongWordCount.isAcceptableOrUnknown(
          data['unresolved_wrong_word_count']!,
          _unresolvedWrongWordCountMeta,
        ),
      );
    }
    if (data.containsKey('completed_word_count')) {
      context.handle(
        _completedWordCountMeta,
        completedWordCount.isAcceptableOrUnknown(
          data['completed_word_count']!,
          _completedWordCountMeta,
        ),
      );
    }
    if (data.containsKey('newly_learned_word_count')) {
      context.handle(
        _newlyLearnedWordCountMeta,
        newlyLearnedWordCount.isAcceptableOrUnknown(
          data['newly_learned_word_count']!,
          _newlyLearnedWordCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      requiredMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}required_mask'],
      )!,
      originalExerciseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_exercise_count'],
      )!,
      currentIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_index'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      completionAppliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completion_applied_at'],
      ),
      successfulWordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}successful_word_count'],
      )!,
      unresolvedWrongWordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unresolved_wrong_word_count'],
      )!,
      completedWordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_word_count'],
      )!,
      newlyLearnedWordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}newly_learned_word_count'],
      )!,
    );
  }

  @override
  $LearningSessionsTable createAlias(String alias) {
    return $LearningSessionsTable(attachedDatabase, alias);
  }
}

class LearningSession extends DataClass implements Insertable<LearningSession> {
  final String id;
  final int? topicId;
  final int status;
  final int requiredMask;
  final int originalExerciseCount;
  final int currentIndex;
  final int startedAt;
  final int? completedAt;
  final int? completionAppliedAt;
  final int successfulWordCount;
  final int unresolvedWrongWordCount;
  final int completedWordCount;
  final int newlyLearnedWordCount;
  const LearningSession({
    required this.id,
    this.topicId,
    required this.status,
    required this.requiredMask,
    required this.originalExerciseCount,
    required this.currentIndex,
    required this.startedAt,
    this.completedAt,
    this.completionAppliedAt,
    required this.successfulWordCount,
    required this.unresolvedWrongWordCount,
    required this.completedWordCount,
    required this.newlyLearnedWordCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<int>(topicId);
    }
    map['status'] = Variable<int>(status);
    map['required_mask'] = Variable<int>(requiredMask);
    map['original_exercise_count'] = Variable<int>(originalExerciseCount);
    map['current_index'] = Variable<int>(currentIndex);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || completionAppliedAt != null) {
      map['completion_applied_at'] = Variable<int>(completionAppliedAt);
    }
    map['successful_word_count'] = Variable<int>(successfulWordCount);
    map['unresolved_wrong_word_count'] = Variable<int>(
      unresolvedWrongWordCount,
    );
    map['completed_word_count'] = Variable<int>(completedWordCount);
    map['newly_learned_word_count'] = Variable<int>(newlyLearnedWordCount);
    return map;
  }

  LearningSessionsCompanion toCompanion(bool nullToAbsent) {
    return LearningSessionsCompanion(
      id: Value(id),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      status: Value(status),
      requiredMask: Value(requiredMask),
      originalExerciseCount: Value(originalExerciseCount),
      currentIndex: Value(currentIndex),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completionAppliedAt: completionAppliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completionAppliedAt),
      successfulWordCount: Value(successfulWordCount),
      unresolvedWrongWordCount: Value(unresolvedWrongWordCount),
      completedWordCount: Value(completedWordCount),
      newlyLearnedWordCount: Value(newlyLearnedWordCount),
    );
  }

  factory LearningSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningSession(
      id: serializer.fromJson<String>(json['id']),
      topicId: serializer.fromJson<int?>(json['topicId']),
      status: serializer.fromJson<int>(json['status']),
      requiredMask: serializer.fromJson<int>(json['requiredMask']),
      originalExerciseCount: serializer.fromJson<int>(
        json['originalExerciseCount'],
      ),
      currentIndex: serializer.fromJson<int>(json['currentIndex']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      completionAppliedAt: serializer.fromJson<int?>(
        json['completionAppliedAt'],
      ),
      successfulWordCount: serializer.fromJson<int>(
        json['successfulWordCount'],
      ),
      unresolvedWrongWordCount: serializer.fromJson<int>(
        json['unresolvedWrongWordCount'],
      ),
      completedWordCount: serializer.fromJson<int>(json['completedWordCount']),
      newlyLearnedWordCount: serializer.fromJson<int>(
        json['newlyLearnedWordCount'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'topicId': serializer.toJson<int?>(topicId),
      'status': serializer.toJson<int>(status),
      'requiredMask': serializer.toJson<int>(requiredMask),
      'originalExerciseCount': serializer.toJson<int>(originalExerciseCount),
      'currentIndex': serializer.toJson<int>(currentIndex),
      'startedAt': serializer.toJson<int>(startedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'completionAppliedAt': serializer.toJson<int?>(completionAppliedAt),
      'successfulWordCount': serializer.toJson<int>(successfulWordCount),
      'unresolvedWrongWordCount': serializer.toJson<int>(
        unresolvedWrongWordCount,
      ),
      'completedWordCount': serializer.toJson<int>(completedWordCount),
      'newlyLearnedWordCount': serializer.toJson<int>(newlyLearnedWordCount),
    };
  }

  LearningSession copyWith({
    String? id,
    Value<int?> topicId = const Value.absent(),
    int? status,
    int? requiredMask,
    int? originalExerciseCount,
    int? currentIndex,
    int? startedAt,
    Value<int?> completedAt = const Value.absent(),
    Value<int?> completionAppliedAt = const Value.absent(),
    int? successfulWordCount,
    int? unresolvedWrongWordCount,
    int? completedWordCount,
    int? newlyLearnedWordCount,
  }) => LearningSession(
    id: id ?? this.id,
    topicId: topicId.present ? topicId.value : this.topicId,
    status: status ?? this.status,
    requiredMask: requiredMask ?? this.requiredMask,
    originalExerciseCount: originalExerciseCount ?? this.originalExerciseCount,
    currentIndex: currentIndex ?? this.currentIndex,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    completionAppliedAt: completionAppliedAt.present
        ? completionAppliedAt.value
        : this.completionAppliedAt,
    successfulWordCount: successfulWordCount ?? this.successfulWordCount,
    unresolvedWrongWordCount:
        unresolvedWrongWordCount ?? this.unresolvedWrongWordCount,
    completedWordCount: completedWordCount ?? this.completedWordCount,
    newlyLearnedWordCount: newlyLearnedWordCount ?? this.newlyLearnedWordCount,
  );
  LearningSession copyWithCompanion(LearningSessionsCompanion data) {
    return LearningSession(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      status: data.status.present ? data.status.value : this.status,
      requiredMask: data.requiredMask.present
          ? data.requiredMask.value
          : this.requiredMask,
      originalExerciseCount: data.originalExerciseCount.present
          ? data.originalExerciseCount.value
          : this.originalExerciseCount,
      currentIndex: data.currentIndex.present
          ? data.currentIndex.value
          : this.currentIndex,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      completionAppliedAt: data.completionAppliedAt.present
          ? data.completionAppliedAt.value
          : this.completionAppliedAt,
      successfulWordCount: data.successfulWordCount.present
          ? data.successfulWordCount.value
          : this.successfulWordCount,
      unresolvedWrongWordCount: data.unresolvedWrongWordCount.present
          ? data.unresolvedWrongWordCount.value
          : this.unresolvedWrongWordCount,
      completedWordCount: data.completedWordCount.present
          ? data.completedWordCount.value
          : this.completedWordCount,
      newlyLearnedWordCount: data.newlyLearnedWordCount.present
          ? data.newlyLearnedWordCount.value
          : this.newlyLearnedWordCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningSession(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('status: $status, ')
          ..write('requiredMask: $requiredMask, ')
          ..write('originalExerciseCount: $originalExerciseCount, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('completionAppliedAt: $completionAppliedAt, ')
          ..write('successfulWordCount: $successfulWordCount, ')
          ..write('unresolvedWrongWordCount: $unresolvedWrongWordCount, ')
          ..write('completedWordCount: $completedWordCount, ')
          ..write('newlyLearnedWordCount: $newlyLearnedWordCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topicId,
    status,
    requiredMask,
    originalExerciseCount,
    currentIndex,
    startedAt,
    completedAt,
    completionAppliedAt,
    successfulWordCount,
    unresolvedWrongWordCount,
    completedWordCount,
    newlyLearnedWordCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningSession &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.status == this.status &&
          other.requiredMask == this.requiredMask &&
          other.originalExerciseCount == this.originalExerciseCount &&
          other.currentIndex == this.currentIndex &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.completionAppliedAt == this.completionAppliedAt &&
          other.successfulWordCount == this.successfulWordCount &&
          other.unresolvedWrongWordCount == this.unresolvedWrongWordCount &&
          other.completedWordCount == this.completedWordCount &&
          other.newlyLearnedWordCount == this.newlyLearnedWordCount);
}

class LearningSessionsCompanion extends UpdateCompanion<LearningSession> {
  final Value<String> id;
  final Value<int?> topicId;
  final Value<int> status;
  final Value<int> requiredMask;
  final Value<int> originalExerciseCount;
  final Value<int> currentIndex;
  final Value<int> startedAt;
  final Value<int?> completedAt;
  final Value<int?> completionAppliedAt;
  final Value<int> successfulWordCount;
  final Value<int> unresolvedWrongWordCount;
  final Value<int> completedWordCount;
  final Value<int> newlyLearnedWordCount;
  final Value<int> rowid;
  const LearningSessionsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.status = const Value.absent(),
    this.requiredMask = const Value.absent(),
    this.originalExerciseCount = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completionAppliedAt = const Value.absent(),
    this.successfulWordCount = const Value.absent(),
    this.unresolvedWrongWordCount = const Value.absent(),
    this.completedWordCount = const Value.absent(),
    this.newlyLearnedWordCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningSessionsCompanion.insert({
    required String id,
    this.topicId = const Value.absent(),
    this.status = const Value.absent(),
    required int requiredMask,
    required int originalExerciseCount,
    this.currentIndex = const Value.absent(),
    required int startedAt,
    this.completedAt = const Value.absent(),
    this.completionAppliedAt = const Value.absent(),
    this.successfulWordCount = const Value.absent(),
    this.unresolvedWrongWordCount = const Value.absent(),
    this.completedWordCount = const Value.absent(),
    this.newlyLearnedWordCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       requiredMask = Value(requiredMask),
       originalExerciseCount = Value(originalExerciseCount),
       startedAt = Value(startedAt);
  static Insertable<LearningSession> custom({
    Expression<String>? id,
    Expression<int>? topicId,
    Expression<int>? status,
    Expression<int>? requiredMask,
    Expression<int>? originalExerciseCount,
    Expression<int>? currentIndex,
    Expression<int>? startedAt,
    Expression<int>? completedAt,
    Expression<int>? completionAppliedAt,
    Expression<int>? successfulWordCount,
    Expression<int>? unresolvedWrongWordCount,
    Expression<int>? completedWordCount,
    Expression<int>? newlyLearnedWordCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (status != null) 'status': status,
      if (requiredMask != null) 'required_mask': requiredMask,
      if (originalExerciseCount != null)
        'original_exercise_count': originalExerciseCount,
      if (currentIndex != null) 'current_index': currentIndex,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (completionAppliedAt != null)
        'completion_applied_at': completionAppliedAt,
      if (successfulWordCount != null)
        'successful_word_count': successfulWordCount,
      if (unresolvedWrongWordCount != null)
        'unresolved_wrong_word_count': unresolvedWrongWordCount,
      if (completedWordCount != null)
        'completed_word_count': completedWordCount,
      if (newlyLearnedWordCount != null)
        'newly_learned_word_count': newlyLearnedWordCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningSessionsCompanion copyWith({
    Value<String>? id,
    Value<int?>? topicId,
    Value<int>? status,
    Value<int>? requiredMask,
    Value<int>? originalExerciseCount,
    Value<int>? currentIndex,
    Value<int>? startedAt,
    Value<int?>? completedAt,
    Value<int?>? completionAppliedAt,
    Value<int>? successfulWordCount,
    Value<int>? unresolvedWrongWordCount,
    Value<int>? completedWordCount,
    Value<int>? newlyLearnedWordCount,
    Value<int>? rowid,
  }) {
    return LearningSessionsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      status: status ?? this.status,
      requiredMask: requiredMask ?? this.requiredMask,
      originalExerciseCount:
          originalExerciseCount ?? this.originalExerciseCount,
      currentIndex: currentIndex ?? this.currentIndex,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completionAppliedAt: completionAppliedAt ?? this.completionAppliedAt,
      successfulWordCount: successfulWordCount ?? this.successfulWordCount,
      unresolvedWrongWordCount:
          unresolvedWrongWordCount ?? this.unresolvedWrongWordCount,
      completedWordCount: completedWordCount ?? this.completedWordCount,
      newlyLearnedWordCount:
          newlyLearnedWordCount ?? this.newlyLearnedWordCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (requiredMask.present) {
      map['required_mask'] = Variable<int>(requiredMask.value);
    }
    if (originalExerciseCount.present) {
      map['original_exercise_count'] = Variable<int>(
        originalExerciseCount.value,
      );
    }
    if (currentIndex.present) {
      map['current_index'] = Variable<int>(currentIndex.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (completionAppliedAt.present) {
      map['completion_applied_at'] = Variable<int>(completionAppliedAt.value);
    }
    if (successfulWordCount.present) {
      map['successful_word_count'] = Variable<int>(successfulWordCount.value);
    }
    if (unresolvedWrongWordCount.present) {
      map['unresolved_wrong_word_count'] = Variable<int>(
        unresolvedWrongWordCount.value,
      );
    }
    if (completedWordCount.present) {
      map['completed_word_count'] = Variable<int>(completedWordCount.value);
    }
    if (newlyLearnedWordCount.present) {
      map['newly_learned_word_count'] = Variable<int>(
        newlyLearnedWordCount.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningSessionsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('status: $status, ')
          ..write('requiredMask: $requiredMask, ')
          ..write('originalExerciseCount: $originalExerciseCount, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('completionAppliedAt: $completionAppliedAt, ')
          ..write('successfulWordCount: $successfulWordCount, ')
          ..write('unresolvedWrongWordCount: $unresolvedWrongWordCount, ')
          ..write('completedWordCount: $completedWordCount, ')
          ..write('newlyLearnedWordCount: $newlyLearnedWordCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionExercisesTable extends SessionExercises
    with TableInfo<$SessionExercisesTable, SessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseTypeMeta = const VerificationMeta(
    'exerciseType',
  );
  @override
  late final GeneratedColumn<int> exerciseType = GeneratedColumn<int>(
    'exercise_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRetryMeta = const VerificationMeta(
    'isRetry',
  );
  @override
  late final GeneratedColumn<bool> isRetry = GeneratedColumn<bool>(
    'is_retry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_retry" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _parentExerciseIdMeta = const VerificationMeta(
    'parentExerciseId',
  );
  @override
  late final GeneratedColumn<int> parentExerciseId = GeneratedColumn<int>(
    'parent_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<int> answer = GeneratedColumn<int>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<int> answeredAt = GeneratedColumn<int>(
    'answered_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    wordId,
    exerciseType,
    orderIndex,
    isRetry,
    parentExerciseId,
    answer,
    answeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SessionExercise';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('exercise_type')) {
      context.handle(
        _exerciseTypeMeta,
        exerciseType.isAcceptableOrUnknown(
          data['exercise_type']!,
          _exerciseTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseTypeMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('is_retry')) {
      context.handle(
        _isRetryMeta,
        isRetry.isAcceptableOrUnknown(data['is_retry']!, _isRetryMeta),
      );
    }
    if (data.containsKey('parent_exercise_id')) {
      context.handle(
        _parentExerciseIdMeta,
        parentExerciseId.isAcceptableOrUnknown(
          data['parent_exercise_id']!,
          _parentExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      exerciseType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_type'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      isRetry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_retry'],
      )!,
      parentExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_exercise_id'],
      ),
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answer'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answered_at'],
      ),
    );
  }

  @override
  $SessionExercisesTable createAlias(String alias) {
    return $SessionExercisesTable(attachedDatabase, alias);
  }
}

class SessionExercise extends DataClass implements Insertable<SessionExercise> {
  final int id;
  final String sessionId;
  final int wordId;
  final int exerciseType;
  final int orderIndex;
  final bool isRetry;
  final int? parentExerciseId;
  final int answer;
  final int? answeredAt;
  const SessionExercise({
    required this.id,
    required this.sessionId,
    required this.wordId,
    required this.exerciseType,
    required this.orderIndex,
    required this.isRetry,
    this.parentExerciseId,
    required this.answer,
    this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['word_id'] = Variable<int>(wordId);
    map['exercise_type'] = Variable<int>(exerciseType);
    map['order_index'] = Variable<int>(orderIndex);
    map['is_retry'] = Variable<bool>(isRetry);
    if (!nullToAbsent || parentExerciseId != null) {
      map['parent_exercise_id'] = Variable<int>(parentExerciseId);
    }
    map['answer'] = Variable<int>(answer);
    if (!nullToAbsent || answeredAt != null) {
      map['answered_at'] = Variable<int>(answeredAt);
    }
    return map;
  }

  SessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return SessionExercisesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      wordId: Value(wordId),
      exerciseType: Value(exerciseType),
      orderIndex: Value(orderIndex),
      isRetry: Value(isRetry),
      parentExerciseId: parentExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentExerciseId),
      answer: Value(answer),
      answeredAt: answeredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredAt),
    );
  }

  factory SessionExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExercise(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      exerciseType: serializer.fromJson<int>(json['exerciseType']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      isRetry: serializer.fromJson<bool>(json['isRetry']),
      parentExerciseId: serializer.fromJson<int?>(json['parentExerciseId']),
      answer: serializer.fromJson<int>(json['answer']),
      answeredAt: serializer.fromJson<int?>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'wordId': serializer.toJson<int>(wordId),
      'exerciseType': serializer.toJson<int>(exerciseType),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'isRetry': serializer.toJson<bool>(isRetry),
      'parentExerciseId': serializer.toJson<int?>(parentExerciseId),
      'answer': serializer.toJson<int>(answer),
      'answeredAt': serializer.toJson<int?>(answeredAt),
    };
  }

  SessionExercise copyWith({
    int? id,
    String? sessionId,
    int? wordId,
    int? exerciseType,
    int? orderIndex,
    bool? isRetry,
    Value<int?> parentExerciseId = const Value.absent(),
    int? answer,
    Value<int?> answeredAt = const Value.absent(),
  }) => SessionExercise(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    wordId: wordId ?? this.wordId,
    exerciseType: exerciseType ?? this.exerciseType,
    orderIndex: orderIndex ?? this.orderIndex,
    isRetry: isRetry ?? this.isRetry,
    parentExerciseId: parentExerciseId.present
        ? parentExerciseId.value
        : this.parentExerciseId,
    answer: answer ?? this.answer,
    answeredAt: answeredAt.present ? answeredAt.value : this.answeredAt,
  );
  SessionExercise copyWithCompanion(SessionExercisesCompanion data) {
    return SessionExercise(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      exerciseType: data.exerciseType.present
          ? data.exerciseType.value
          : this.exerciseType,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      isRetry: data.isRetry.present ? data.isRetry.value : this.isRetry,
      parentExerciseId: data.parentExerciseId.present
          ? data.parentExerciseId.value
          : this.parentExerciseId,
      answer: data.answer.present ? data.answer.value : this.answer,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercise(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('wordId: $wordId, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isRetry: $isRetry, ')
          ..write('parentExerciseId: $parentExerciseId, ')
          ..write('answer: $answer, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    wordId,
    exerciseType,
    orderIndex,
    isRetry,
    parentExerciseId,
    answer,
    answeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExercise &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.wordId == this.wordId &&
          other.exerciseType == this.exerciseType &&
          other.orderIndex == this.orderIndex &&
          other.isRetry == this.isRetry &&
          other.parentExerciseId == this.parentExerciseId &&
          other.answer == this.answer &&
          other.answeredAt == this.answeredAt);
}

class SessionExercisesCompanion extends UpdateCompanion<SessionExercise> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<int> wordId;
  final Value<int> exerciseType;
  final Value<int> orderIndex;
  final Value<bool> isRetry;
  final Value<int?> parentExerciseId;
  final Value<int> answer;
  final Value<int?> answeredAt;
  const SessionExercisesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isRetry = const Value.absent(),
    this.parentExerciseId = const Value.absent(),
    this.answer = const Value.absent(),
    this.answeredAt = const Value.absent(),
  });
  SessionExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required int wordId,
    required int exerciseType,
    required int orderIndex,
    this.isRetry = const Value.absent(),
    this.parentExerciseId = const Value.absent(),
    this.answer = const Value.absent(),
    this.answeredAt = const Value.absent(),
  }) : sessionId = Value(sessionId),
       wordId = Value(wordId),
       exerciseType = Value(exerciseType),
       orderIndex = Value(orderIndex);
  static Insertable<SessionExercise> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<int>? wordId,
    Expression<int>? exerciseType,
    Expression<int>? orderIndex,
    Expression<bool>? isRetry,
    Expression<int>? parentExerciseId,
    Expression<int>? answer,
    Expression<int>? answeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (wordId != null) 'word_id': wordId,
      if (exerciseType != null) 'exercise_type': exerciseType,
      if (orderIndex != null) 'order_index': orderIndex,
      if (isRetry != null) 'is_retry': isRetry,
      if (parentExerciseId != null) 'parent_exercise_id': parentExerciseId,
      if (answer != null) 'answer': answer,
      if (answeredAt != null) 'answered_at': answeredAt,
    });
  }

  SessionExercisesCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<int>? wordId,
    Value<int>? exerciseType,
    Value<int>? orderIndex,
    Value<bool>? isRetry,
    Value<int?>? parentExerciseId,
    Value<int>? answer,
    Value<int?>? answeredAt,
  }) {
    return SessionExercisesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      wordId: wordId ?? this.wordId,
      exerciseType: exerciseType ?? this.exerciseType,
      orderIndex: orderIndex ?? this.orderIndex,
      isRetry: isRetry ?? this.isRetry,
      parentExerciseId: parentExerciseId ?? this.parentExerciseId,
      answer: answer ?? this.answer,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (exerciseType.present) {
      map['exercise_type'] = Variable<int>(exerciseType.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (isRetry.present) {
      map['is_retry'] = Variable<bool>(isRetry.value);
    }
    if (parentExerciseId.present) {
      map['parent_exercise_id'] = Variable<int>(parentExerciseId.value);
    }
    if (answer.present) {
      map['answer'] = Variable<int>(answer.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<int>(answeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('wordId: $wordId, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isRetry: $isRetry, ')
          ..write('parentExerciseId: $parentExerciseId, ')
          ..write('answer: $answer, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }
}

class $SimilarWordModelsTable extends SimilarWordModels
    with TableInfo<$SimilarWordModelsTable, SimilarWordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SimilarWordModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, options];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SimilarWordModel';
  @override
  VerificationContext validateIntegrity(
    Insertable<SimilarWordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    } else if (isInserting) {
      context.missing(_optionsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SimilarWordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SimilarWordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      )!,
    );
  }

  @override
  $SimilarWordModelsTable createAlias(String alias) {
    return $SimilarWordModelsTable(attachedDatabase, alias);
  }
}

class SimilarWordRow extends DataClass implements Insertable<SimilarWordRow> {
  final int id;
  final String options;
  const SimilarWordRow({required this.id, required this.options});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['options'] = Variable<String>(options);
    return map;
  }

  SimilarWordModelsCompanion toCompanion(bool nullToAbsent) {
    return SimilarWordModelsCompanion(id: Value(id), options: Value(options));
  }

  factory SimilarWordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SimilarWordRow(
      id: serializer.fromJson<int>(json['id']),
      options: serializer.fromJson<String>(json['options']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'options': serializer.toJson<String>(options),
    };
  }

  SimilarWordRow copyWith({int? id, String? options}) =>
      SimilarWordRow(id: id ?? this.id, options: options ?? this.options);
  SimilarWordRow copyWithCompanion(SimilarWordModelsCompanion data) {
    return SimilarWordRow(
      id: data.id.present ? data.id.value : this.id,
      options: data.options.present ? data.options.value : this.options,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SimilarWordRow(')
          ..write('id: $id, ')
          ..write('options: $options')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, options);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SimilarWordRow &&
          other.id == this.id &&
          other.options == this.options);
}

class SimilarWordModelsCompanion extends UpdateCompanion<SimilarWordRow> {
  final Value<int> id;
  final Value<String> options;
  const SimilarWordModelsCompanion({
    this.id = const Value.absent(),
    this.options = const Value.absent(),
  });
  SimilarWordModelsCompanion.insert({
    this.id = const Value.absent(),
    required String options,
  }) : options = Value(options);
  static Insertable<SimilarWordRow> custom({
    Expression<int>? id,
    Expression<String>? options,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (options != null) 'options': options,
    });
  }

  SimilarWordModelsCompanion copyWith({
    Value<int>? id,
    Value<String>? options,
  }) {
    return SimilarWordModelsCompanion(
      id: id ?? this.id,
      options: options ?? this.options,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SimilarWordModelsCompanion(')
          ..write('id: $id, ')
          ..write('options: $options')
          ..write(')'))
        .toString();
  }
}

class $SttMisspellingModelsTable extends SttMisspellingModels
    with TableInfo<$SttMisspellingModelsTable, SttMisspellingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SttMisspellingModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _misspellingsMeta = const VerificationMeta(
    'misspellings',
  );
  @override
  late final GeneratedColumn<String> misspellings = GeneratedColumn<String>(
    'misspellings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, misspellings];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SttMisspellingModel';
  @override
  VerificationContext validateIntegrity(
    Insertable<SttMisspellingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('misspellings')) {
      context.handle(
        _misspellingsMeta,
        misspellings.isAcceptableOrUnknown(
          data['misspellings']!,
          _misspellingsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_misspellingsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SttMisspellingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SttMisspellingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      misspellings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}misspellings'],
      )!,
    );
  }

  @override
  $SttMisspellingModelsTable createAlias(String alias) {
    return $SttMisspellingModelsTable(attachedDatabase, alias);
  }
}

class SttMisspellingRow extends DataClass
    implements Insertable<SttMisspellingRow> {
  final int id;
  final String misspellings;
  const SttMisspellingRow({required this.id, required this.misspellings});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['misspellings'] = Variable<String>(misspellings);
    return map;
  }

  SttMisspellingModelsCompanion toCompanion(bool nullToAbsent) {
    return SttMisspellingModelsCompanion(
      id: Value(id),
      misspellings: Value(misspellings),
    );
  }

  factory SttMisspellingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SttMisspellingRow(
      id: serializer.fromJson<int>(json['id']),
      misspellings: serializer.fromJson<String>(json['misspellings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'misspellings': serializer.toJson<String>(misspellings),
    };
  }

  SttMisspellingRow copyWith({int? id, String? misspellings}) =>
      SttMisspellingRow(
        id: id ?? this.id,
        misspellings: misspellings ?? this.misspellings,
      );
  SttMisspellingRow copyWithCompanion(SttMisspellingModelsCompanion data) {
    return SttMisspellingRow(
      id: data.id.present ? data.id.value : this.id,
      misspellings: data.misspellings.present
          ? data.misspellings.value
          : this.misspellings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SttMisspellingRow(')
          ..write('id: $id, ')
          ..write('misspellings: $misspellings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, misspellings);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SttMisspellingRow &&
          other.id == this.id &&
          other.misspellings == this.misspellings);
}

class SttMisspellingModelsCompanion extends UpdateCompanion<SttMisspellingRow> {
  final Value<int> id;
  final Value<String> misspellings;
  const SttMisspellingModelsCompanion({
    this.id = const Value.absent(),
    this.misspellings = const Value.absent(),
  });
  SttMisspellingModelsCompanion.insert({
    this.id = const Value.absent(),
    required String misspellings,
  }) : misspellings = Value(misspellings);
  static Insertable<SttMisspellingRow> custom({
    Expression<int>? id,
    Expression<String>? misspellings,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (misspellings != null) 'misspellings': misspellings,
    });
  }

  SttMisspellingModelsCompanion copyWith({
    Value<int>? id,
    Value<String>? misspellings,
  }) {
    return SttMisspellingModelsCompanion(
      id: id ?? this.id,
      misspellings: misspellings ?? this.misspellings,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (misspellings.present) {
      map['misspellings'] = Variable<String>(misspellings.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SttMisspellingModelsCompanion(')
          ..write('id: $id, ')
          ..write('misspellings: $misspellings')
          ..write(')'))
        .toString();
  }
}

class $LetterModelsTable extends LetterModels
    with TableInfo<$LetterModelsTable, LetterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LetterModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _writingMeta = const VerificationMeta(
    'writing',
  );
  @override
  late final GeneratedColumn<String> writing = GeneratedColumn<String>(
    'writing',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptionMeta = const VerificationMeta(
    'transcription',
  );
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
    'transcription',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alphabetOrderMeta = const VerificationMeta(
    'alphabetOrder',
  );
  @override
  late final GeneratedColumn<int> alphabetOrder = GeneratedColumn<int>(
    'alphabet_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _educationOrderMeta = const VerificationMeta(
    'educationOrder',
  );
  @override
  late final GeneratedColumn<int> educationOrder = GeneratedColumn<int>(
    'education_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioFilenameMeta = const VerificationMeta(
    'audioFilename',
  );
  @override
  late final GeneratedColumn<String> audioFilename = GeneratedColumn<String>(
    'audio_filename',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _digitValueMeta = const VerificationMeta(
    'digitValue',
  );
  @override
  late final GeneratedColumn<String> digitValue = GeneratedColumn<String>(
    'digit_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variationsMeta = const VerificationMeta(
    'variations',
  );
  @override
  late final GeneratedColumn<String> variations = GeneratedColumn<String>(
    'variations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vowelsMeta = const VerificationMeta('vowels');
  @override
  late final GeneratedColumn<String> vowels = GeneratedColumn<String>(
    'vowels',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    writing,
    transcription,
    alphabetOrder,
    educationOrder,
    audioFilename,
    digitValue,
    type,
    variations,
    vowels,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'LetterModel';
  @override
  VerificationContext validateIntegrity(
    Insertable<LetterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('writing')) {
      context.handle(
        _writingMeta,
        writing.isAcceptableOrUnknown(data['writing']!, _writingMeta),
      );
    }
    if (data.containsKey('transcription')) {
      context.handle(
        _transcriptionMeta,
        transcription.isAcceptableOrUnknown(
          data['transcription']!,
          _transcriptionMeta,
        ),
      );
    }
    if (data.containsKey('alphabet_order')) {
      context.handle(
        _alphabetOrderMeta,
        alphabetOrder.isAcceptableOrUnknown(
          data['alphabet_order']!,
          _alphabetOrderMeta,
        ),
      );
    }
    if (data.containsKey('education_order')) {
      context.handle(
        _educationOrderMeta,
        educationOrder.isAcceptableOrUnknown(
          data['education_order']!,
          _educationOrderMeta,
        ),
      );
    }
    if (data.containsKey('audio_filename')) {
      context.handle(
        _audioFilenameMeta,
        audioFilename.isAcceptableOrUnknown(
          data['audio_filename']!,
          _audioFilenameMeta,
        ),
      );
    }
    if (data.containsKey('digit_value')) {
      context.handle(
        _digitValueMeta,
        digitValue.isAcceptableOrUnknown(data['digit_value']!, _digitValueMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('variations')) {
      context.handle(
        _variationsMeta,
        variations.isAcceptableOrUnknown(data['variations']!, _variationsMeta),
      );
    } else if (isInserting) {
      context.missing(_variationsMeta);
    }
    if (data.containsKey('vowels')) {
      context.handle(
        _vowelsMeta,
        vowels.isAcceptableOrUnknown(data['vowels']!, _vowelsMeta),
      );
    } else if (isInserting) {
      context.missing(_vowelsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LetterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LetterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      writing: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}writing'],
      ),
      transcription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcription'],
      ),
      alphabetOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}alphabet_order'],
      ),
      educationOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}education_order'],
      ),
      audioFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_filename'],
      ),
      digitValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}digit_value'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      variations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variations'],
      )!,
      vowels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vowels'],
      )!,
    );
  }

  @override
  $LetterModelsTable createAlias(String alias) {
    return $LetterModelsTable(attachedDatabase, alias);
  }
}

class LetterRow extends DataClass implements Insertable<LetterRow> {
  final int id;
  final String? writing;
  final String? transcription;
  final int? alphabetOrder;
  final int? educationOrder;
  final String? audioFilename;
  final String? digitValue;
  final String type;
  final String variations;
  final String vowels;
  const LetterRow({
    required this.id,
    this.writing,
    this.transcription,
    this.alphabetOrder,
    this.educationOrder,
    this.audioFilename,
    this.digitValue,
    required this.type,
    required this.variations,
    required this.vowels,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || writing != null) {
      map['writing'] = Variable<String>(writing);
    }
    if (!nullToAbsent || transcription != null) {
      map['transcription'] = Variable<String>(transcription);
    }
    if (!nullToAbsent || alphabetOrder != null) {
      map['alphabet_order'] = Variable<int>(alphabetOrder);
    }
    if (!nullToAbsent || educationOrder != null) {
      map['education_order'] = Variable<int>(educationOrder);
    }
    if (!nullToAbsent || audioFilename != null) {
      map['audio_filename'] = Variable<String>(audioFilename);
    }
    if (!nullToAbsent || digitValue != null) {
      map['digit_value'] = Variable<String>(digitValue);
    }
    map['type'] = Variable<String>(type);
    map['variations'] = Variable<String>(variations);
    map['vowels'] = Variable<String>(vowels);
    return map;
  }

  LetterModelsCompanion toCompanion(bool nullToAbsent) {
    return LetterModelsCompanion(
      id: Value(id),
      writing: writing == null && nullToAbsent
          ? const Value.absent()
          : Value(writing),
      transcription: transcription == null && nullToAbsent
          ? const Value.absent()
          : Value(transcription),
      alphabetOrder: alphabetOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(alphabetOrder),
      educationOrder: educationOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(educationOrder),
      audioFilename: audioFilename == null && nullToAbsent
          ? const Value.absent()
          : Value(audioFilename),
      digitValue: digitValue == null && nullToAbsent
          ? const Value.absent()
          : Value(digitValue),
      type: Value(type),
      variations: Value(variations),
      vowels: Value(vowels),
    );
  }

  factory LetterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LetterRow(
      id: serializer.fromJson<int>(json['id']),
      writing: serializer.fromJson<String?>(json['writing']),
      transcription: serializer.fromJson<String?>(json['transcription']),
      alphabetOrder: serializer.fromJson<int?>(json['alphabetOrder']),
      educationOrder: serializer.fromJson<int?>(json['educationOrder']),
      audioFilename: serializer.fromJson<String?>(json['audioFilename']),
      digitValue: serializer.fromJson<String?>(json['digitValue']),
      type: serializer.fromJson<String>(json['type']),
      variations: serializer.fromJson<String>(json['variations']),
      vowels: serializer.fromJson<String>(json['vowels']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'writing': serializer.toJson<String?>(writing),
      'transcription': serializer.toJson<String?>(transcription),
      'alphabetOrder': serializer.toJson<int?>(alphabetOrder),
      'educationOrder': serializer.toJson<int?>(educationOrder),
      'audioFilename': serializer.toJson<String?>(audioFilename),
      'digitValue': serializer.toJson<String?>(digitValue),
      'type': serializer.toJson<String>(type),
      'variations': serializer.toJson<String>(variations),
      'vowels': serializer.toJson<String>(vowels),
    };
  }

  LetterRow copyWith({
    int? id,
    Value<String?> writing = const Value.absent(),
    Value<String?> transcription = const Value.absent(),
    Value<int?> alphabetOrder = const Value.absent(),
    Value<int?> educationOrder = const Value.absent(),
    Value<String?> audioFilename = const Value.absent(),
    Value<String?> digitValue = const Value.absent(),
    String? type,
    String? variations,
    String? vowels,
  }) => LetterRow(
    id: id ?? this.id,
    writing: writing.present ? writing.value : this.writing,
    transcription: transcription.present
        ? transcription.value
        : this.transcription,
    alphabetOrder: alphabetOrder.present
        ? alphabetOrder.value
        : this.alphabetOrder,
    educationOrder: educationOrder.present
        ? educationOrder.value
        : this.educationOrder,
    audioFilename: audioFilename.present
        ? audioFilename.value
        : this.audioFilename,
    digitValue: digitValue.present ? digitValue.value : this.digitValue,
    type: type ?? this.type,
    variations: variations ?? this.variations,
    vowels: vowels ?? this.vowels,
  );
  LetterRow copyWithCompanion(LetterModelsCompanion data) {
    return LetterRow(
      id: data.id.present ? data.id.value : this.id,
      writing: data.writing.present ? data.writing.value : this.writing,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
      alphabetOrder: data.alphabetOrder.present
          ? data.alphabetOrder.value
          : this.alphabetOrder,
      educationOrder: data.educationOrder.present
          ? data.educationOrder.value
          : this.educationOrder,
      audioFilename: data.audioFilename.present
          ? data.audioFilename.value
          : this.audioFilename,
      digitValue: data.digitValue.present
          ? data.digitValue.value
          : this.digitValue,
      type: data.type.present ? data.type.value : this.type,
      variations: data.variations.present
          ? data.variations.value
          : this.variations,
      vowels: data.vowels.present ? data.vowels.value : this.vowels,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LetterRow(')
          ..write('id: $id, ')
          ..write('writing: $writing, ')
          ..write('transcription: $transcription, ')
          ..write('alphabetOrder: $alphabetOrder, ')
          ..write('educationOrder: $educationOrder, ')
          ..write('audioFilename: $audioFilename, ')
          ..write('digitValue: $digitValue, ')
          ..write('type: $type, ')
          ..write('variations: $variations, ')
          ..write('vowels: $vowels')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    writing,
    transcription,
    alphabetOrder,
    educationOrder,
    audioFilename,
    digitValue,
    type,
    variations,
    vowels,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LetterRow &&
          other.id == this.id &&
          other.writing == this.writing &&
          other.transcription == this.transcription &&
          other.alphabetOrder == this.alphabetOrder &&
          other.educationOrder == this.educationOrder &&
          other.audioFilename == this.audioFilename &&
          other.digitValue == this.digitValue &&
          other.type == this.type &&
          other.variations == this.variations &&
          other.vowels == this.vowels);
}

class LetterModelsCompanion extends UpdateCompanion<LetterRow> {
  final Value<int> id;
  final Value<String?> writing;
  final Value<String?> transcription;
  final Value<int?> alphabetOrder;
  final Value<int?> educationOrder;
  final Value<String?> audioFilename;
  final Value<String?> digitValue;
  final Value<String> type;
  final Value<String> variations;
  final Value<String> vowels;
  const LetterModelsCompanion({
    this.id = const Value.absent(),
    this.writing = const Value.absent(),
    this.transcription = const Value.absent(),
    this.alphabetOrder = const Value.absent(),
    this.educationOrder = const Value.absent(),
    this.audioFilename = const Value.absent(),
    this.digitValue = const Value.absent(),
    this.type = const Value.absent(),
    this.variations = const Value.absent(),
    this.vowels = const Value.absent(),
  });
  LetterModelsCompanion.insert({
    this.id = const Value.absent(),
    this.writing = const Value.absent(),
    this.transcription = const Value.absent(),
    this.alphabetOrder = const Value.absent(),
    this.educationOrder = const Value.absent(),
    this.audioFilename = const Value.absent(),
    this.digitValue = const Value.absent(),
    required String type,
    required String variations,
    required String vowels,
  }) : type = Value(type),
       variations = Value(variations),
       vowels = Value(vowels);
  static Insertable<LetterRow> custom({
    Expression<int>? id,
    Expression<String>? writing,
    Expression<String>? transcription,
    Expression<int>? alphabetOrder,
    Expression<int>? educationOrder,
    Expression<String>? audioFilename,
    Expression<String>? digitValue,
    Expression<String>? type,
    Expression<String>? variations,
    Expression<String>? vowels,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (writing != null) 'writing': writing,
      if (transcription != null) 'transcription': transcription,
      if (alphabetOrder != null) 'alphabet_order': alphabetOrder,
      if (educationOrder != null) 'education_order': educationOrder,
      if (audioFilename != null) 'audio_filename': audioFilename,
      if (digitValue != null) 'digit_value': digitValue,
      if (type != null) 'type': type,
      if (variations != null) 'variations': variations,
      if (vowels != null) 'vowels': vowels,
    });
  }

  LetterModelsCompanion copyWith({
    Value<int>? id,
    Value<String?>? writing,
    Value<String?>? transcription,
    Value<int?>? alphabetOrder,
    Value<int?>? educationOrder,
    Value<String?>? audioFilename,
    Value<String?>? digitValue,
    Value<String>? type,
    Value<String>? variations,
    Value<String>? vowels,
  }) {
    return LetterModelsCompanion(
      id: id ?? this.id,
      writing: writing ?? this.writing,
      transcription: transcription ?? this.transcription,
      alphabetOrder: alphabetOrder ?? this.alphabetOrder,
      educationOrder: educationOrder ?? this.educationOrder,
      audioFilename: audioFilename ?? this.audioFilename,
      digitValue: digitValue ?? this.digitValue,
      type: type ?? this.type,
      variations: variations ?? this.variations,
      vowels: vowels ?? this.vowels,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (writing.present) {
      map['writing'] = Variable<String>(writing.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (alphabetOrder.present) {
      map['alphabet_order'] = Variable<int>(alphabetOrder.value);
    }
    if (educationOrder.present) {
      map['education_order'] = Variable<int>(educationOrder.value);
    }
    if (audioFilename.present) {
      map['audio_filename'] = Variable<String>(audioFilename.value);
    }
    if (digitValue.present) {
      map['digit_value'] = Variable<String>(digitValue.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (variations.present) {
      map['variations'] = Variable<String>(variations.value);
    }
    if (vowels.present) {
      map['vowels'] = Variable<String>(vowels.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LetterModelsCompanion(')
          ..write('id: $id, ')
          ..write('writing: $writing, ')
          ..write('transcription: $transcription, ')
          ..write('alphabetOrder: $alphabetOrder, ')
          ..write('educationOrder: $educationOrder, ')
          ..write('audioFilename: $audioFilename, ')
          ..write('digitValue: $digitValue, ')
          ..write('type: $type, ')
          ..write('variations: $variations, ')
          ..write('vowels: $vowels')
          ..write(')'))
        .toString();
  }
}

class $VisitModelsTable extends VisitModels
    with TableInfo<$VisitModelsTable, VisitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areDailyTasksFinishedMeta =
      const VerificationMeta('areDailyTasksFinished');
  @override
  late final GeneratedColumn<bool> areDailyTasksFinished =
      GeneratedColumn<bool>(
        'are_daily_tasks_finished',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("are_daily_tasks_finished" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _atLeastOneTaskFinishedMeta =
      const VerificationMeta('atLeastOneTaskFinished');
  @override
  late final GeneratedColumn<bool> atLeastOneTaskFinished =
      GeneratedColumn<bool>(
        'at_least_one_task_finished',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("at_least_one_task_finished" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _repeatWordsGoalMeta = const VerificationMeta(
    'repeatWordsGoal',
  );
  @override
  late final GeneratedColumn<int> repeatWordsGoal = GeneratedColumn<int>(
    'repeat_words_goal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _learnWordsGoalMeta = const VerificationMeta(
    'learnWordsGoal',
  );
  @override
  late final GeneratedColumn<int> learnWordsGoal = GeneratedColumn<int>(
    'learn_words_goal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _trainWordsGoalMeta = const VerificationMeta(
    'trainWordsGoal',
  );
  @override
  late final GeneratedColumn<int> trainWordsGoal = GeneratedColumn<int>(
    'train_words_goal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _difficultWordsGoalMeta =
      const VerificationMeta('difficultWordsGoal');
  @override
  late final GeneratedColumn<int> difficultWordsGoal = GeneratedColumn<int>(
    'difficult_words_goal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wordsInSentencesGoalMeta =
      const VerificationMeta('wordsInSentencesGoal');
  @override
  late final GeneratedColumn<int> wordsInSentencesGoal = GeneratedColumn<int>(
    'words_in_sentences_goal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repeatedWordsCountMeta =
      const VerificationMeta('repeatedWordsCount');
  @override
  late final GeneratedColumn<int> repeatedWordsCount = GeneratedColumn<int>(
    'repeated_words_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _learnedWordsCountMeta = const VerificationMeta(
    'learnedWordsCount',
  );
  @override
  late final GeneratedColumn<int> learnedWordsCount = GeneratedColumn<int>(
    'learned_words_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _trainedWordsCountMeta = const VerificationMeta(
    'trainedWordsCount',
  );
  @override
  late final GeneratedColumn<int> trainedWordsCount = GeneratedColumn<int>(
    'trained_words_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _difficultWordsTrainedCountMeta =
      const VerificationMeta('difficultWordsTrainedCount');
  @override
  late final GeneratedColumn<int> difficultWordsTrainedCount =
      GeneratedColumn<int>(
        'difficult_words_trained_count',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _wordsInSentencesCountMeta =
      const VerificationMeta('wordsInSentencesCount');
  @override
  late final GeneratedColumn<int> wordsInSentencesCount = GeneratedColumn<int>(
    'words_in_sentences_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sentencesTrainedCountMeta =
      const VerificationMeta('sentencesTrainedCount');
  @override
  late final GeneratedColumn<int> sentencesTrainedCount = GeneratedColumn<int>(
    'sentences_trained_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sentencesTrainedExtraCountMeta =
      const VerificationMeta('sentencesTrainedExtraCount');
  @override
  late final GeneratedColumn<int> sentencesTrainedExtraCount =
      GeneratedColumn<int>(
        'sentences_trained_extra_count',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _problemWordsHealedCountMeta =
      const VerificationMeta('problemWordsHealedCount');
  @override
  late final GeneratedColumn<int> problemWordsHealedCount =
      GeneratedColumn<int>(
        'problem_words_healed_count',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _learningsWithoutMistakesMeta =
      const VerificationMeta('learningsWithoutMistakes');
  @override
  late final GeneratedColumn<int> learningsWithoutMistakes =
      GeneratedColumn<int>(
        'learnings_without_mistakes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _learnedWordsWithoutMistakesMeta =
      const VerificationMeta('learnedWordsWithoutMistakes');
  @override
  late final GeneratedColumn<int> learnedWordsWithoutMistakes =
      GeneratedColumn<int>(
        'learned_words_without_mistakes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    areDailyTasksFinished,
    atLeastOneTaskFinished,
    repeatWordsGoal,
    learnWordsGoal,
    trainWordsGoal,
    difficultWordsGoal,
    wordsInSentencesGoal,
    repeatedWordsCount,
    learnedWordsCount,
    trainedWordsCount,
    difficultWordsTrainedCount,
    wordsInSentencesCount,
    sentencesTrainedCount,
    sentencesTrainedExtraCount,
    problemWordsHealedCount,
    learningsWithoutMistakes,
    learnedWordsWithoutMistakes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'VisitModel';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('are_daily_tasks_finished')) {
      context.handle(
        _areDailyTasksFinishedMeta,
        areDailyTasksFinished.isAcceptableOrUnknown(
          data['are_daily_tasks_finished']!,
          _areDailyTasksFinishedMeta,
        ),
      );
    }
    if (data.containsKey('at_least_one_task_finished')) {
      context.handle(
        _atLeastOneTaskFinishedMeta,
        atLeastOneTaskFinished.isAcceptableOrUnknown(
          data['at_least_one_task_finished']!,
          _atLeastOneTaskFinishedMeta,
        ),
      );
    }
    if (data.containsKey('repeat_words_goal')) {
      context.handle(
        _repeatWordsGoalMeta,
        repeatWordsGoal.isAcceptableOrUnknown(
          data['repeat_words_goal']!,
          _repeatWordsGoalMeta,
        ),
      );
    }
    if (data.containsKey('learn_words_goal')) {
      context.handle(
        _learnWordsGoalMeta,
        learnWordsGoal.isAcceptableOrUnknown(
          data['learn_words_goal']!,
          _learnWordsGoalMeta,
        ),
      );
    }
    if (data.containsKey('train_words_goal')) {
      context.handle(
        _trainWordsGoalMeta,
        trainWordsGoal.isAcceptableOrUnknown(
          data['train_words_goal']!,
          _trainWordsGoalMeta,
        ),
      );
    }
    if (data.containsKey('difficult_words_goal')) {
      context.handle(
        _difficultWordsGoalMeta,
        difficultWordsGoal.isAcceptableOrUnknown(
          data['difficult_words_goal']!,
          _difficultWordsGoalMeta,
        ),
      );
    }
    if (data.containsKey('words_in_sentences_goal')) {
      context.handle(
        _wordsInSentencesGoalMeta,
        wordsInSentencesGoal.isAcceptableOrUnknown(
          data['words_in_sentences_goal']!,
          _wordsInSentencesGoalMeta,
        ),
      );
    }
    if (data.containsKey('repeated_words_count')) {
      context.handle(
        _repeatedWordsCountMeta,
        repeatedWordsCount.isAcceptableOrUnknown(
          data['repeated_words_count']!,
          _repeatedWordsCountMeta,
        ),
      );
    }
    if (data.containsKey('learned_words_count')) {
      context.handle(
        _learnedWordsCountMeta,
        learnedWordsCount.isAcceptableOrUnknown(
          data['learned_words_count']!,
          _learnedWordsCountMeta,
        ),
      );
    }
    if (data.containsKey('trained_words_count')) {
      context.handle(
        _trainedWordsCountMeta,
        trainedWordsCount.isAcceptableOrUnknown(
          data['trained_words_count']!,
          _trainedWordsCountMeta,
        ),
      );
    }
    if (data.containsKey('difficult_words_trained_count')) {
      context.handle(
        _difficultWordsTrainedCountMeta,
        difficultWordsTrainedCount.isAcceptableOrUnknown(
          data['difficult_words_trained_count']!,
          _difficultWordsTrainedCountMeta,
        ),
      );
    }
    if (data.containsKey('words_in_sentences_count')) {
      context.handle(
        _wordsInSentencesCountMeta,
        wordsInSentencesCount.isAcceptableOrUnknown(
          data['words_in_sentences_count']!,
          _wordsInSentencesCountMeta,
        ),
      );
    }
    if (data.containsKey('sentences_trained_count')) {
      context.handle(
        _sentencesTrainedCountMeta,
        sentencesTrainedCount.isAcceptableOrUnknown(
          data['sentences_trained_count']!,
          _sentencesTrainedCountMeta,
        ),
      );
    }
    if (data.containsKey('sentences_trained_extra_count')) {
      context.handle(
        _sentencesTrainedExtraCountMeta,
        sentencesTrainedExtraCount.isAcceptableOrUnknown(
          data['sentences_trained_extra_count']!,
          _sentencesTrainedExtraCountMeta,
        ),
      );
    }
    if (data.containsKey('problem_words_healed_count')) {
      context.handle(
        _problemWordsHealedCountMeta,
        problemWordsHealedCount.isAcceptableOrUnknown(
          data['problem_words_healed_count']!,
          _problemWordsHealedCountMeta,
        ),
      );
    }
    if (data.containsKey('learnings_without_mistakes')) {
      context.handle(
        _learningsWithoutMistakesMeta,
        learningsWithoutMistakes.isAcceptableOrUnknown(
          data['learnings_without_mistakes']!,
          _learningsWithoutMistakesMeta,
        ),
      );
    }
    if (data.containsKey('learned_words_without_mistakes')) {
      context.handle(
        _learnedWordsWithoutMistakesMeta,
        learnedWordsWithoutMistakes.isAcceptableOrUnknown(
          data['learned_words_without_mistakes']!,
          _learnedWordsWithoutMistakesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      areDailyTasksFinished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}are_daily_tasks_finished'],
      )!,
      atLeastOneTaskFinished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}at_least_one_task_finished'],
      )!,
      repeatWordsGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_words_goal'],
      )!,
      learnWordsGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learn_words_goal'],
      )!,
      trainWordsGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}train_words_goal'],
      )!,
      difficultWordsGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficult_words_goal'],
      )!,
      wordsInSentencesGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}words_in_sentences_goal'],
      )!,
      repeatedWordsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeated_words_count'],
      )!,
      learnedWordsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learned_words_count'],
      )!,
      trainedWordsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trained_words_count'],
      )!,
      difficultWordsTrainedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficult_words_trained_count'],
      )!,
      wordsInSentencesCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}words_in_sentences_count'],
      )!,
      sentencesTrainedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sentences_trained_count'],
      )!,
      sentencesTrainedExtraCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sentences_trained_extra_count'],
      )!,
      problemWordsHealedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}problem_words_healed_count'],
      )!,
      learningsWithoutMistakes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learnings_without_mistakes'],
      )!,
      learnedWordsWithoutMistakes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learned_words_without_mistakes'],
      )!,
    );
  }

  @override
  $VisitModelsTable createAlias(String alias) {
    return $VisitModelsTable(attachedDatabase, alias);
  }
}

class VisitRow extends DataClass implements Insertable<VisitRow> {
  final int id;
  final int date;
  final bool areDailyTasksFinished;
  final bool atLeastOneTaskFinished;
  final int repeatWordsGoal;
  final int learnWordsGoal;
  final int trainWordsGoal;
  final int difficultWordsGoal;
  final int wordsInSentencesGoal;
  final int repeatedWordsCount;
  final int learnedWordsCount;
  final int trainedWordsCount;
  final int difficultWordsTrainedCount;
  final int wordsInSentencesCount;
  final int sentencesTrainedCount;
  final int sentencesTrainedExtraCount;
  final int problemWordsHealedCount;
  final int learningsWithoutMistakes;
  final int learnedWordsWithoutMistakes;
  const VisitRow({
    required this.id,
    required this.date,
    required this.areDailyTasksFinished,
    required this.atLeastOneTaskFinished,
    required this.repeatWordsGoal,
    required this.learnWordsGoal,
    required this.trainWordsGoal,
    required this.difficultWordsGoal,
    required this.wordsInSentencesGoal,
    required this.repeatedWordsCount,
    required this.learnedWordsCount,
    required this.trainedWordsCount,
    required this.difficultWordsTrainedCount,
    required this.wordsInSentencesCount,
    required this.sentencesTrainedCount,
    required this.sentencesTrainedExtraCount,
    required this.problemWordsHealedCount,
    required this.learningsWithoutMistakes,
    required this.learnedWordsWithoutMistakes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    map['are_daily_tasks_finished'] = Variable<bool>(areDailyTasksFinished);
    map['at_least_one_task_finished'] = Variable<bool>(atLeastOneTaskFinished);
    map['repeat_words_goal'] = Variable<int>(repeatWordsGoal);
    map['learn_words_goal'] = Variable<int>(learnWordsGoal);
    map['train_words_goal'] = Variable<int>(trainWordsGoal);
    map['difficult_words_goal'] = Variable<int>(difficultWordsGoal);
    map['words_in_sentences_goal'] = Variable<int>(wordsInSentencesGoal);
    map['repeated_words_count'] = Variable<int>(repeatedWordsCount);
    map['learned_words_count'] = Variable<int>(learnedWordsCount);
    map['trained_words_count'] = Variable<int>(trainedWordsCount);
    map['difficult_words_trained_count'] = Variable<int>(
      difficultWordsTrainedCount,
    );
    map['words_in_sentences_count'] = Variable<int>(wordsInSentencesCount);
    map['sentences_trained_count'] = Variable<int>(sentencesTrainedCount);
    map['sentences_trained_extra_count'] = Variable<int>(
      sentencesTrainedExtraCount,
    );
    map['problem_words_healed_count'] = Variable<int>(problemWordsHealedCount);
    map['learnings_without_mistakes'] = Variable<int>(learningsWithoutMistakes);
    map['learned_words_without_mistakes'] = Variable<int>(
      learnedWordsWithoutMistakes,
    );
    return map;
  }

  VisitModelsCompanion toCompanion(bool nullToAbsent) {
    return VisitModelsCompanion(
      id: Value(id),
      date: Value(date),
      areDailyTasksFinished: Value(areDailyTasksFinished),
      atLeastOneTaskFinished: Value(atLeastOneTaskFinished),
      repeatWordsGoal: Value(repeatWordsGoal),
      learnWordsGoal: Value(learnWordsGoal),
      trainWordsGoal: Value(trainWordsGoal),
      difficultWordsGoal: Value(difficultWordsGoal),
      wordsInSentencesGoal: Value(wordsInSentencesGoal),
      repeatedWordsCount: Value(repeatedWordsCount),
      learnedWordsCount: Value(learnedWordsCount),
      trainedWordsCount: Value(trainedWordsCount),
      difficultWordsTrainedCount: Value(difficultWordsTrainedCount),
      wordsInSentencesCount: Value(wordsInSentencesCount),
      sentencesTrainedCount: Value(sentencesTrainedCount),
      sentencesTrainedExtraCount: Value(sentencesTrainedExtraCount),
      problemWordsHealedCount: Value(problemWordsHealedCount),
      learningsWithoutMistakes: Value(learningsWithoutMistakes),
      learnedWordsWithoutMistakes: Value(learnedWordsWithoutMistakes),
    );
  }

  factory VisitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitRow(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      areDailyTasksFinished: serializer.fromJson<bool>(
        json['areDailyTasksFinished'],
      ),
      atLeastOneTaskFinished: serializer.fromJson<bool>(
        json['atLeastOneTaskFinished'],
      ),
      repeatWordsGoal: serializer.fromJson<int>(json['repeatWordsGoal']),
      learnWordsGoal: serializer.fromJson<int>(json['learnWordsGoal']),
      trainWordsGoal: serializer.fromJson<int>(json['trainWordsGoal']),
      difficultWordsGoal: serializer.fromJson<int>(json['difficultWordsGoal']),
      wordsInSentencesGoal: serializer.fromJson<int>(
        json['wordsInSentencesGoal'],
      ),
      repeatedWordsCount: serializer.fromJson<int>(json['repeatedWordsCount']),
      learnedWordsCount: serializer.fromJson<int>(json['learnedWordsCount']),
      trainedWordsCount: serializer.fromJson<int>(json['trainedWordsCount']),
      difficultWordsTrainedCount: serializer.fromJson<int>(
        json['difficultWordsTrainedCount'],
      ),
      wordsInSentencesCount: serializer.fromJson<int>(
        json['wordsInSentencesCount'],
      ),
      sentencesTrainedCount: serializer.fromJson<int>(
        json['sentencesTrainedCount'],
      ),
      sentencesTrainedExtraCount: serializer.fromJson<int>(
        json['sentencesTrainedExtraCount'],
      ),
      problemWordsHealedCount: serializer.fromJson<int>(
        json['problemWordsHealedCount'],
      ),
      learningsWithoutMistakes: serializer.fromJson<int>(
        json['learningsWithoutMistakes'],
      ),
      learnedWordsWithoutMistakes: serializer.fromJson<int>(
        json['learnedWordsWithoutMistakes'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<int>(date),
      'areDailyTasksFinished': serializer.toJson<bool>(areDailyTasksFinished),
      'atLeastOneTaskFinished': serializer.toJson<bool>(atLeastOneTaskFinished),
      'repeatWordsGoal': serializer.toJson<int>(repeatWordsGoal),
      'learnWordsGoal': serializer.toJson<int>(learnWordsGoal),
      'trainWordsGoal': serializer.toJson<int>(trainWordsGoal),
      'difficultWordsGoal': serializer.toJson<int>(difficultWordsGoal),
      'wordsInSentencesGoal': serializer.toJson<int>(wordsInSentencesGoal),
      'repeatedWordsCount': serializer.toJson<int>(repeatedWordsCount),
      'learnedWordsCount': serializer.toJson<int>(learnedWordsCount),
      'trainedWordsCount': serializer.toJson<int>(trainedWordsCount),
      'difficultWordsTrainedCount': serializer.toJson<int>(
        difficultWordsTrainedCount,
      ),
      'wordsInSentencesCount': serializer.toJson<int>(wordsInSentencesCount),
      'sentencesTrainedCount': serializer.toJson<int>(sentencesTrainedCount),
      'sentencesTrainedExtraCount': serializer.toJson<int>(
        sentencesTrainedExtraCount,
      ),
      'problemWordsHealedCount': serializer.toJson<int>(
        problemWordsHealedCount,
      ),
      'learningsWithoutMistakes': serializer.toJson<int>(
        learningsWithoutMistakes,
      ),
      'learnedWordsWithoutMistakes': serializer.toJson<int>(
        learnedWordsWithoutMistakes,
      ),
    };
  }

  VisitRow copyWith({
    int? id,
    int? date,
    bool? areDailyTasksFinished,
    bool? atLeastOneTaskFinished,
    int? repeatWordsGoal,
    int? learnWordsGoal,
    int? trainWordsGoal,
    int? difficultWordsGoal,
    int? wordsInSentencesGoal,
    int? repeatedWordsCount,
    int? learnedWordsCount,
    int? trainedWordsCount,
    int? difficultWordsTrainedCount,
    int? wordsInSentencesCount,
    int? sentencesTrainedCount,
    int? sentencesTrainedExtraCount,
    int? problemWordsHealedCount,
    int? learningsWithoutMistakes,
    int? learnedWordsWithoutMistakes,
  }) => VisitRow(
    id: id ?? this.id,
    date: date ?? this.date,
    areDailyTasksFinished: areDailyTasksFinished ?? this.areDailyTasksFinished,
    atLeastOneTaskFinished:
        atLeastOneTaskFinished ?? this.atLeastOneTaskFinished,
    repeatWordsGoal: repeatWordsGoal ?? this.repeatWordsGoal,
    learnWordsGoal: learnWordsGoal ?? this.learnWordsGoal,
    trainWordsGoal: trainWordsGoal ?? this.trainWordsGoal,
    difficultWordsGoal: difficultWordsGoal ?? this.difficultWordsGoal,
    wordsInSentencesGoal: wordsInSentencesGoal ?? this.wordsInSentencesGoal,
    repeatedWordsCount: repeatedWordsCount ?? this.repeatedWordsCount,
    learnedWordsCount: learnedWordsCount ?? this.learnedWordsCount,
    trainedWordsCount: trainedWordsCount ?? this.trainedWordsCount,
    difficultWordsTrainedCount:
        difficultWordsTrainedCount ?? this.difficultWordsTrainedCount,
    wordsInSentencesCount: wordsInSentencesCount ?? this.wordsInSentencesCount,
    sentencesTrainedCount: sentencesTrainedCount ?? this.sentencesTrainedCount,
    sentencesTrainedExtraCount:
        sentencesTrainedExtraCount ?? this.sentencesTrainedExtraCount,
    problemWordsHealedCount:
        problemWordsHealedCount ?? this.problemWordsHealedCount,
    learningsWithoutMistakes:
        learningsWithoutMistakes ?? this.learningsWithoutMistakes,
    learnedWordsWithoutMistakes:
        learnedWordsWithoutMistakes ?? this.learnedWordsWithoutMistakes,
  );
  VisitRow copyWithCompanion(VisitModelsCompanion data) {
    return VisitRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      areDailyTasksFinished: data.areDailyTasksFinished.present
          ? data.areDailyTasksFinished.value
          : this.areDailyTasksFinished,
      atLeastOneTaskFinished: data.atLeastOneTaskFinished.present
          ? data.atLeastOneTaskFinished.value
          : this.atLeastOneTaskFinished,
      repeatWordsGoal: data.repeatWordsGoal.present
          ? data.repeatWordsGoal.value
          : this.repeatWordsGoal,
      learnWordsGoal: data.learnWordsGoal.present
          ? data.learnWordsGoal.value
          : this.learnWordsGoal,
      trainWordsGoal: data.trainWordsGoal.present
          ? data.trainWordsGoal.value
          : this.trainWordsGoal,
      difficultWordsGoal: data.difficultWordsGoal.present
          ? data.difficultWordsGoal.value
          : this.difficultWordsGoal,
      wordsInSentencesGoal: data.wordsInSentencesGoal.present
          ? data.wordsInSentencesGoal.value
          : this.wordsInSentencesGoal,
      repeatedWordsCount: data.repeatedWordsCount.present
          ? data.repeatedWordsCount.value
          : this.repeatedWordsCount,
      learnedWordsCount: data.learnedWordsCount.present
          ? data.learnedWordsCount.value
          : this.learnedWordsCount,
      trainedWordsCount: data.trainedWordsCount.present
          ? data.trainedWordsCount.value
          : this.trainedWordsCount,
      difficultWordsTrainedCount: data.difficultWordsTrainedCount.present
          ? data.difficultWordsTrainedCount.value
          : this.difficultWordsTrainedCount,
      wordsInSentencesCount: data.wordsInSentencesCount.present
          ? data.wordsInSentencesCount.value
          : this.wordsInSentencesCount,
      sentencesTrainedCount: data.sentencesTrainedCount.present
          ? data.sentencesTrainedCount.value
          : this.sentencesTrainedCount,
      sentencesTrainedExtraCount: data.sentencesTrainedExtraCount.present
          ? data.sentencesTrainedExtraCount.value
          : this.sentencesTrainedExtraCount,
      problemWordsHealedCount: data.problemWordsHealedCount.present
          ? data.problemWordsHealedCount.value
          : this.problemWordsHealedCount,
      learningsWithoutMistakes: data.learningsWithoutMistakes.present
          ? data.learningsWithoutMistakes.value
          : this.learningsWithoutMistakes,
      learnedWordsWithoutMistakes: data.learnedWordsWithoutMistakes.present
          ? data.learnedWordsWithoutMistakes.value
          : this.learnedWordsWithoutMistakes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('areDailyTasksFinished: $areDailyTasksFinished, ')
          ..write('atLeastOneTaskFinished: $atLeastOneTaskFinished, ')
          ..write('repeatWordsGoal: $repeatWordsGoal, ')
          ..write('learnWordsGoal: $learnWordsGoal, ')
          ..write('trainWordsGoal: $trainWordsGoal, ')
          ..write('difficultWordsGoal: $difficultWordsGoal, ')
          ..write('wordsInSentencesGoal: $wordsInSentencesGoal, ')
          ..write('repeatedWordsCount: $repeatedWordsCount, ')
          ..write('learnedWordsCount: $learnedWordsCount, ')
          ..write('trainedWordsCount: $trainedWordsCount, ')
          ..write('difficultWordsTrainedCount: $difficultWordsTrainedCount, ')
          ..write('wordsInSentencesCount: $wordsInSentencesCount, ')
          ..write('sentencesTrainedCount: $sentencesTrainedCount, ')
          ..write('sentencesTrainedExtraCount: $sentencesTrainedExtraCount, ')
          ..write('problemWordsHealedCount: $problemWordsHealedCount, ')
          ..write('learningsWithoutMistakes: $learningsWithoutMistakes, ')
          ..write('learnedWordsWithoutMistakes: $learnedWordsWithoutMistakes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    areDailyTasksFinished,
    atLeastOneTaskFinished,
    repeatWordsGoal,
    learnWordsGoal,
    trainWordsGoal,
    difficultWordsGoal,
    wordsInSentencesGoal,
    repeatedWordsCount,
    learnedWordsCount,
    trainedWordsCount,
    difficultWordsTrainedCount,
    wordsInSentencesCount,
    sentencesTrainedCount,
    sentencesTrainedExtraCount,
    problemWordsHealedCount,
    learningsWithoutMistakes,
    learnedWordsWithoutMistakes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.areDailyTasksFinished == this.areDailyTasksFinished &&
          other.atLeastOneTaskFinished == this.atLeastOneTaskFinished &&
          other.repeatWordsGoal == this.repeatWordsGoal &&
          other.learnWordsGoal == this.learnWordsGoal &&
          other.trainWordsGoal == this.trainWordsGoal &&
          other.difficultWordsGoal == this.difficultWordsGoal &&
          other.wordsInSentencesGoal == this.wordsInSentencesGoal &&
          other.repeatedWordsCount == this.repeatedWordsCount &&
          other.learnedWordsCount == this.learnedWordsCount &&
          other.trainedWordsCount == this.trainedWordsCount &&
          other.difficultWordsTrainedCount == this.difficultWordsTrainedCount &&
          other.wordsInSentencesCount == this.wordsInSentencesCount &&
          other.sentencesTrainedCount == this.sentencesTrainedCount &&
          other.sentencesTrainedExtraCount == this.sentencesTrainedExtraCount &&
          other.problemWordsHealedCount == this.problemWordsHealedCount &&
          other.learningsWithoutMistakes == this.learningsWithoutMistakes &&
          other.learnedWordsWithoutMistakes ==
              this.learnedWordsWithoutMistakes);
}

class VisitModelsCompanion extends UpdateCompanion<VisitRow> {
  final Value<int> id;
  final Value<int> date;
  final Value<bool> areDailyTasksFinished;
  final Value<bool> atLeastOneTaskFinished;
  final Value<int> repeatWordsGoal;
  final Value<int> learnWordsGoal;
  final Value<int> trainWordsGoal;
  final Value<int> difficultWordsGoal;
  final Value<int> wordsInSentencesGoal;
  final Value<int> repeatedWordsCount;
  final Value<int> learnedWordsCount;
  final Value<int> trainedWordsCount;
  final Value<int> difficultWordsTrainedCount;
  final Value<int> wordsInSentencesCount;
  final Value<int> sentencesTrainedCount;
  final Value<int> sentencesTrainedExtraCount;
  final Value<int> problemWordsHealedCount;
  final Value<int> learningsWithoutMistakes;
  final Value<int> learnedWordsWithoutMistakes;
  const VisitModelsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.areDailyTasksFinished = const Value.absent(),
    this.atLeastOneTaskFinished = const Value.absent(),
    this.repeatWordsGoal = const Value.absent(),
    this.learnWordsGoal = const Value.absent(),
    this.trainWordsGoal = const Value.absent(),
    this.difficultWordsGoal = const Value.absent(),
    this.wordsInSentencesGoal = const Value.absent(),
    this.repeatedWordsCount = const Value.absent(),
    this.learnedWordsCount = const Value.absent(),
    this.trainedWordsCount = const Value.absent(),
    this.difficultWordsTrainedCount = const Value.absent(),
    this.wordsInSentencesCount = const Value.absent(),
    this.sentencesTrainedCount = const Value.absent(),
    this.sentencesTrainedExtraCount = const Value.absent(),
    this.problemWordsHealedCount = const Value.absent(),
    this.learningsWithoutMistakes = const Value.absent(),
    this.learnedWordsWithoutMistakes = const Value.absent(),
  });
  VisitModelsCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    this.areDailyTasksFinished = const Value.absent(),
    this.atLeastOneTaskFinished = const Value.absent(),
    this.repeatWordsGoal = const Value.absent(),
    this.learnWordsGoal = const Value.absent(),
    this.trainWordsGoal = const Value.absent(),
    this.difficultWordsGoal = const Value.absent(),
    this.wordsInSentencesGoal = const Value.absent(),
    this.repeatedWordsCount = const Value.absent(),
    this.learnedWordsCount = const Value.absent(),
    this.trainedWordsCount = const Value.absent(),
    this.difficultWordsTrainedCount = const Value.absent(),
    this.wordsInSentencesCount = const Value.absent(),
    this.sentencesTrainedCount = const Value.absent(),
    this.sentencesTrainedExtraCount = const Value.absent(),
    this.problemWordsHealedCount = const Value.absent(),
    this.learningsWithoutMistakes = const Value.absent(),
    this.learnedWordsWithoutMistakes = const Value.absent(),
  }) : date = Value(date);
  static Insertable<VisitRow> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<bool>? areDailyTasksFinished,
    Expression<bool>? atLeastOneTaskFinished,
    Expression<int>? repeatWordsGoal,
    Expression<int>? learnWordsGoal,
    Expression<int>? trainWordsGoal,
    Expression<int>? difficultWordsGoal,
    Expression<int>? wordsInSentencesGoal,
    Expression<int>? repeatedWordsCount,
    Expression<int>? learnedWordsCount,
    Expression<int>? trainedWordsCount,
    Expression<int>? difficultWordsTrainedCount,
    Expression<int>? wordsInSentencesCount,
    Expression<int>? sentencesTrainedCount,
    Expression<int>? sentencesTrainedExtraCount,
    Expression<int>? problemWordsHealedCount,
    Expression<int>? learningsWithoutMistakes,
    Expression<int>? learnedWordsWithoutMistakes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (areDailyTasksFinished != null)
        'are_daily_tasks_finished': areDailyTasksFinished,
      if (atLeastOneTaskFinished != null)
        'at_least_one_task_finished': atLeastOneTaskFinished,
      if (repeatWordsGoal != null) 'repeat_words_goal': repeatWordsGoal,
      if (learnWordsGoal != null) 'learn_words_goal': learnWordsGoal,
      if (trainWordsGoal != null) 'train_words_goal': trainWordsGoal,
      if (difficultWordsGoal != null)
        'difficult_words_goal': difficultWordsGoal,
      if (wordsInSentencesGoal != null)
        'words_in_sentences_goal': wordsInSentencesGoal,
      if (repeatedWordsCount != null)
        'repeated_words_count': repeatedWordsCount,
      if (learnedWordsCount != null) 'learned_words_count': learnedWordsCount,
      if (trainedWordsCount != null) 'trained_words_count': trainedWordsCount,
      if (difficultWordsTrainedCount != null)
        'difficult_words_trained_count': difficultWordsTrainedCount,
      if (wordsInSentencesCount != null)
        'words_in_sentences_count': wordsInSentencesCount,
      if (sentencesTrainedCount != null)
        'sentences_trained_count': sentencesTrainedCount,
      if (sentencesTrainedExtraCount != null)
        'sentences_trained_extra_count': sentencesTrainedExtraCount,
      if (problemWordsHealedCount != null)
        'problem_words_healed_count': problemWordsHealedCount,
      if (learningsWithoutMistakes != null)
        'learnings_without_mistakes': learningsWithoutMistakes,
      if (learnedWordsWithoutMistakes != null)
        'learned_words_without_mistakes': learnedWordsWithoutMistakes,
    });
  }

  VisitModelsCompanion copyWith({
    Value<int>? id,
    Value<int>? date,
    Value<bool>? areDailyTasksFinished,
    Value<bool>? atLeastOneTaskFinished,
    Value<int>? repeatWordsGoal,
    Value<int>? learnWordsGoal,
    Value<int>? trainWordsGoal,
    Value<int>? difficultWordsGoal,
    Value<int>? wordsInSentencesGoal,
    Value<int>? repeatedWordsCount,
    Value<int>? learnedWordsCount,
    Value<int>? trainedWordsCount,
    Value<int>? difficultWordsTrainedCount,
    Value<int>? wordsInSentencesCount,
    Value<int>? sentencesTrainedCount,
    Value<int>? sentencesTrainedExtraCount,
    Value<int>? problemWordsHealedCount,
    Value<int>? learningsWithoutMistakes,
    Value<int>? learnedWordsWithoutMistakes,
  }) {
    return VisitModelsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      areDailyTasksFinished:
          areDailyTasksFinished ?? this.areDailyTasksFinished,
      atLeastOneTaskFinished:
          atLeastOneTaskFinished ?? this.atLeastOneTaskFinished,
      repeatWordsGoal: repeatWordsGoal ?? this.repeatWordsGoal,
      learnWordsGoal: learnWordsGoal ?? this.learnWordsGoal,
      trainWordsGoal: trainWordsGoal ?? this.trainWordsGoal,
      difficultWordsGoal: difficultWordsGoal ?? this.difficultWordsGoal,
      wordsInSentencesGoal: wordsInSentencesGoal ?? this.wordsInSentencesGoal,
      repeatedWordsCount: repeatedWordsCount ?? this.repeatedWordsCount,
      learnedWordsCount: learnedWordsCount ?? this.learnedWordsCount,
      trainedWordsCount: trainedWordsCount ?? this.trainedWordsCount,
      difficultWordsTrainedCount:
          difficultWordsTrainedCount ?? this.difficultWordsTrainedCount,
      wordsInSentencesCount:
          wordsInSentencesCount ?? this.wordsInSentencesCount,
      sentencesTrainedCount:
          sentencesTrainedCount ?? this.sentencesTrainedCount,
      sentencesTrainedExtraCount:
          sentencesTrainedExtraCount ?? this.sentencesTrainedExtraCount,
      problemWordsHealedCount:
          problemWordsHealedCount ?? this.problemWordsHealedCount,
      learningsWithoutMistakes:
          learningsWithoutMistakes ?? this.learningsWithoutMistakes,
      learnedWordsWithoutMistakes:
          learnedWordsWithoutMistakes ?? this.learnedWordsWithoutMistakes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (areDailyTasksFinished.present) {
      map['are_daily_tasks_finished'] = Variable<bool>(
        areDailyTasksFinished.value,
      );
    }
    if (atLeastOneTaskFinished.present) {
      map['at_least_one_task_finished'] = Variable<bool>(
        atLeastOneTaskFinished.value,
      );
    }
    if (repeatWordsGoal.present) {
      map['repeat_words_goal'] = Variable<int>(repeatWordsGoal.value);
    }
    if (learnWordsGoal.present) {
      map['learn_words_goal'] = Variable<int>(learnWordsGoal.value);
    }
    if (trainWordsGoal.present) {
      map['train_words_goal'] = Variable<int>(trainWordsGoal.value);
    }
    if (difficultWordsGoal.present) {
      map['difficult_words_goal'] = Variable<int>(difficultWordsGoal.value);
    }
    if (wordsInSentencesGoal.present) {
      map['words_in_sentences_goal'] = Variable<int>(
        wordsInSentencesGoal.value,
      );
    }
    if (repeatedWordsCount.present) {
      map['repeated_words_count'] = Variable<int>(repeatedWordsCount.value);
    }
    if (learnedWordsCount.present) {
      map['learned_words_count'] = Variable<int>(learnedWordsCount.value);
    }
    if (trainedWordsCount.present) {
      map['trained_words_count'] = Variable<int>(trainedWordsCount.value);
    }
    if (difficultWordsTrainedCount.present) {
      map['difficult_words_trained_count'] = Variable<int>(
        difficultWordsTrainedCount.value,
      );
    }
    if (wordsInSentencesCount.present) {
      map['words_in_sentences_count'] = Variable<int>(
        wordsInSentencesCount.value,
      );
    }
    if (sentencesTrainedCount.present) {
      map['sentences_trained_count'] = Variable<int>(
        sentencesTrainedCount.value,
      );
    }
    if (sentencesTrainedExtraCount.present) {
      map['sentences_trained_extra_count'] = Variable<int>(
        sentencesTrainedExtraCount.value,
      );
    }
    if (problemWordsHealedCount.present) {
      map['problem_words_healed_count'] = Variable<int>(
        problemWordsHealedCount.value,
      );
    }
    if (learningsWithoutMistakes.present) {
      map['learnings_without_mistakes'] = Variable<int>(
        learningsWithoutMistakes.value,
      );
    }
    if (learnedWordsWithoutMistakes.present) {
      map['learned_words_without_mistakes'] = Variable<int>(
        learnedWordsWithoutMistakes.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitModelsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('areDailyTasksFinished: $areDailyTasksFinished, ')
          ..write('atLeastOneTaskFinished: $atLeastOneTaskFinished, ')
          ..write('repeatWordsGoal: $repeatWordsGoal, ')
          ..write('learnWordsGoal: $learnWordsGoal, ')
          ..write('trainWordsGoal: $trainWordsGoal, ')
          ..write('difficultWordsGoal: $difficultWordsGoal, ')
          ..write('wordsInSentencesGoal: $wordsInSentencesGoal, ')
          ..write('repeatedWordsCount: $repeatedWordsCount, ')
          ..write('learnedWordsCount: $learnedWordsCount, ')
          ..write('trainedWordsCount: $trainedWordsCount, ')
          ..write('difficultWordsTrainedCount: $difficultWordsTrainedCount, ')
          ..write('wordsInSentencesCount: $wordsInSentencesCount, ')
          ..write('sentencesTrainedCount: $sentencesTrainedCount, ')
          ..write('sentencesTrainedExtraCount: $sentencesTrainedExtraCount, ')
          ..write('problemWordsHealedCount: $problemWordsHealedCount, ')
          ..write('learningsWithoutMistakes: $learningsWithoutMistakes, ')
          ..write('learnedWordsWithoutMistakes: $learnedWordsWithoutMistakes')
          ..write(')'))
        .toString();
  }
}

class $OnboardingTestAnswerModelsTable extends OnboardingTestAnswerModels
    with TableInfo<$OnboardingTestAnswerModelsTable, OnboardingTestAnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OnboardingTestAnswerModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCorrectAnsweredMeta = const VerificationMeta(
    'isCorrectAnswered',
  );
  @override
  late final GeneratedColumn<bool> isCorrectAnswered = GeneratedColumn<bool>(
    'is_correct_answered',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct_answered" IN (0, 1))',
    ),
  );
  static const VerificationMeta _answerIdMeta = const VerificationMeta(
    'answerId',
  );
  @override
  late final GeneratedColumn<String> answerId = GeneratedColumn<String>(
    'answer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    isCorrectAnswered,
    answerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'OnboardingTestAnswerModel';
  @override
  VerificationContext validateIntegrity(
    Insertable<OnboardingTestAnswerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('is_correct_answered')) {
      context.handle(
        _isCorrectAnsweredMeta,
        isCorrectAnswered.isAcceptableOrUnknown(
          data['is_correct_answered']!,
          _isCorrectAnsweredMeta,
        ),
      );
    }
    if (data.containsKey('answer_id')) {
      context.handle(
        _answerIdMeta,
        answerId.isAcceptableOrUnknown(data['answer_id']!, _answerIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  OnboardingTestAnswerRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OnboardingTestAnswerRow(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      isCorrectAnswered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct_answered'],
      ),
      answerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_id'],
      ),
    );
  }

  @override
  $OnboardingTestAnswerModelsTable createAlias(String alias) {
    return $OnboardingTestAnswerModelsTable(attachedDatabase, alias);
  }
}

class OnboardingTestAnswerRow extends DataClass
    implements Insertable<OnboardingTestAnswerRow> {
  final String questionId;
  final bool? isCorrectAnswered;
  final String? answerId;
  const OnboardingTestAnswerRow({
    required this.questionId,
    this.isCorrectAnswered,
    this.answerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    if (!nullToAbsent || isCorrectAnswered != null) {
      map['is_correct_answered'] = Variable<bool>(isCorrectAnswered);
    }
    if (!nullToAbsent || answerId != null) {
      map['answer_id'] = Variable<String>(answerId);
    }
    return map;
  }

  OnboardingTestAnswerModelsCompanion toCompanion(bool nullToAbsent) {
    return OnboardingTestAnswerModelsCompanion(
      questionId: Value(questionId),
      isCorrectAnswered: isCorrectAnswered == null && nullToAbsent
          ? const Value.absent()
          : Value(isCorrectAnswered),
      answerId: answerId == null && nullToAbsent
          ? const Value.absent()
          : Value(answerId),
    );
  }

  factory OnboardingTestAnswerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OnboardingTestAnswerRow(
      questionId: serializer.fromJson<String>(json['questionId']),
      isCorrectAnswered: serializer.fromJson<bool?>(json['isCorrectAnswered']),
      answerId: serializer.fromJson<String?>(json['answerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'isCorrectAnswered': serializer.toJson<bool?>(isCorrectAnswered),
      'answerId': serializer.toJson<String?>(answerId),
    };
  }

  OnboardingTestAnswerRow copyWith({
    String? questionId,
    Value<bool?> isCorrectAnswered = const Value.absent(),
    Value<String?> answerId = const Value.absent(),
  }) => OnboardingTestAnswerRow(
    questionId: questionId ?? this.questionId,
    isCorrectAnswered: isCorrectAnswered.present
        ? isCorrectAnswered.value
        : this.isCorrectAnswered,
    answerId: answerId.present ? answerId.value : this.answerId,
  );
  OnboardingTestAnswerRow copyWithCompanion(
    OnboardingTestAnswerModelsCompanion data,
  ) {
    return OnboardingTestAnswerRow(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      isCorrectAnswered: data.isCorrectAnswered.present
          ? data.isCorrectAnswered.value
          : this.isCorrectAnswered,
      answerId: data.answerId.present ? data.answerId.value : this.answerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingTestAnswerRow(')
          ..write('questionId: $questionId, ')
          ..write('isCorrectAnswered: $isCorrectAnswered, ')
          ..write('answerId: $answerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(questionId, isCorrectAnswered, answerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OnboardingTestAnswerRow &&
          other.questionId == this.questionId &&
          other.isCorrectAnswered == this.isCorrectAnswered &&
          other.answerId == this.answerId);
}

class OnboardingTestAnswerModelsCompanion
    extends UpdateCompanion<OnboardingTestAnswerRow> {
  final Value<String> questionId;
  final Value<bool?> isCorrectAnswered;
  final Value<String?> answerId;
  final Value<int> rowid;
  const OnboardingTestAnswerModelsCompanion({
    this.questionId = const Value.absent(),
    this.isCorrectAnswered = const Value.absent(),
    this.answerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OnboardingTestAnswerModelsCompanion.insert({
    required String questionId,
    this.isCorrectAnswered = const Value.absent(),
    this.answerId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId);
  static Insertable<OnboardingTestAnswerRow> custom({
    Expression<String>? questionId,
    Expression<bool>? isCorrectAnswered,
    Expression<String>? answerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (isCorrectAnswered != null) 'is_correct_answered': isCorrectAnswered,
      if (answerId != null) 'answer_id': answerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OnboardingTestAnswerModelsCompanion copyWith({
    Value<String>? questionId,
    Value<bool?>? isCorrectAnswered,
    Value<String?>? answerId,
    Value<int>? rowid,
  }) {
    return OnboardingTestAnswerModelsCompanion(
      questionId: questionId ?? this.questionId,
      isCorrectAnswered: isCorrectAnswered ?? this.isCorrectAnswered,
      answerId: answerId ?? this.answerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (isCorrectAnswered.present) {
      map['is_correct_answered'] = Variable<bool>(isCorrectAnswered.value);
    }
    if (answerId.present) {
      map['answer_id'] = Variable<String>(answerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OnboardingTestAnswerModelsCompanion(')
          ..write('questionId: $questionId, ')
          ..write('isCorrectAnswered: $isCorrectAnswered, ')
          ..write('answerId: $answerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentRevisionsTable extends ContentRevisions
    with TableInfo<$ContentRevisionsTable, ContentRevisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [source, revision, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentRevisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source};
  @override
  ContentRevisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentRevisionRow(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $ContentRevisionsTable createAlias(String alias) {
    return $ContentRevisionsTable(attachedDatabase, alias);
  }
}

class ContentRevisionRow extends DataClass
    implements Insertable<ContentRevisionRow> {
  final String source;
  final int revision;
  final int syncedAt;
  const ContentRevisionRow({
    required this.source,
    required this.revision,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['revision'] = Variable<int>(revision);
    map['synced_at'] = Variable<int>(syncedAt);
    return map;
  }

  ContentRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ContentRevisionsCompanion(
      source: Value(source),
      revision: Value(revision),
      syncedAt: Value(syncedAt),
    );
  }

  factory ContentRevisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentRevisionRow(
      source: serializer.fromJson<String>(json['source']),
      revision: serializer.fromJson<int>(json['revision']),
      syncedAt: serializer.fromJson<int>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'revision': serializer.toJson<int>(revision),
      'syncedAt': serializer.toJson<int>(syncedAt),
    };
  }

  ContentRevisionRow copyWith({String? source, int? revision, int? syncedAt}) =>
      ContentRevisionRow(
        source: source ?? this.source,
        revision: revision ?? this.revision,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  ContentRevisionRow copyWithCompanion(ContentRevisionsCompanion data) {
    return ContentRevisionRow(
      source: data.source.present ? data.source.value : this.source,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentRevisionRow(')
          ..write('source: $source, ')
          ..write('revision: $revision, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, revision, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentRevisionRow &&
          other.source == this.source &&
          other.revision == this.revision &&
          other.syncedAt == this.syncedAt);
}

class ContentRevisionsCompanion extends UpdateCompanion<ContentRevisionRow> {
  final Value<String> source;
  final Value<int> revision;
  final Value<int> syncedAt;
  final Value<int> rowid;
  const ContentRevisionsCompanion({
    this.source = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentRevisionsCompanion.insert({
    required String source,
    required int revision,
    required int syncedAt,
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       revision = Value(revision),
       syncedAt = Value(syncedAt);
  static Insertable<ContentRevisionRow> custom({
    Expression<String>? source,
    Expression<int>? revision,
    Expression<int>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (revision != null) 'revision': revision,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentRevisionsCompanion copyWith({
    Value<String>? source,
    Value<int>? revision,
    Value<int>? syncedAt,
    Value<int>? rowid,
  }) {
    return ContentRevisionsCompanion(
      source: source ?? this.source,
      revision: revision ?? this.revision,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentRevisionsCompanion(')
          ..write('source: $source, ')
          ..write('revision: $revision, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppUsageDaysTable extends AppUsageDays
    with TableInfo<$AppUsageDaysTable, AppUsageDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppUsageDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foregroundMillisecondsMeta =
      const VerificationMeta('foregroundMilliseconds');
  @override
  late final GeneratedColumn<int> foregroundMilliseconds = GeneratedColumn<int>(
    'foreground_milliseconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [date, foregroundMilliseconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_usage_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppUsageDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('foreground_milliseconds')) {
      context.handle(
        _foregroundMillisecondsMeta,
        foregroundMilliseconds.isAcceptableOrUnknown(
          data['foreground_milliseconds']!,
          _foregroundMillisecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  AppUsageDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUsageDayRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      foregroundMilliseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}foreground_milliseconds'],
      )!,
    );
  }

  @override
  $AppUsageDaysTable createAlias(String alias) {
    return $AppUsageDaysTable(attachedDatabase, alias);
  }
}

class AppUsageDayRow extends DataClass implements Insertable<AppUsageDayRow> {
  /// Local midnight, stored as milliseconds since epoch.
  final int date;
  final int foregroundMilliseconds;
  const AppUsageDayRow({
    required this.date,
    required this.foregroundMilliseconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<int>(date);
    map['foreground_milliseconds'] = Variable<int>(foregroundMilliseconds);
    return map;
  }

  AppUsageDaysCompanion toCompanion(bool nullToAbsent) {
    return AppUsageDaysCompanion(
      date: Value(date),
      foregroundMilliseconds: Value(foregroundMilliseconds),
    );
  }

  factory AppUsageDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUsageDayRow(
      date: serializer.fromJson<int>(json['date']),
      foregroundMilliseconds: serializer.fromJson<int>(
        json['foregroundMilliseconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<int>(date),
      'foregroundMilliseconds': serializer.toJson<int>(foregroundMilliseconds),
    };
  }

  AppUsageDayRow copyWith({int? date, int? foregroundMilliseconds}) =>
      AppUsageDayRow(
        date: date ?? this.date,
        foregroundMilliseconds:
            foregroundMilliseconds ?? this.foregroundMilliseconds,
      );
  AppUsageDayRow copyWithCompanion(AppUsageDaysCompanion data) {
    return AppUsageDayRow(
      date: data.date.present ? data.date.value : this.date,
      foregroundMilliseconds: data.foregroundMilliseconds.present
          ? data.foregroundMilliseconds.value
          : this.foregroundMilliseconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageDayRow(')
          ..write('date: $date, ')
          ..write('foregroundMilliseconds: $foregroundMilliseconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, foregroundMilliseconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUsageDayRow &&
          other.date == this.date &&
          other.foregroundMilliseconds == this.foregroundMilliseconds);
}

class AppUsageDaysCompanion extends UpdateCompanion<AppUsageDayRow> {
  final Value<int> date;
  final Value<int> foregroundMilliseconds;
  const AppUsageDaysCompanion({
    this.date = const Value.absent(),
    this.foregroundMilliseconds = const Value.absent(),
  });
  AppUsageDaysCompanion.insert({
    this.date = const Value.absent(),
    this.foregroundMilliseconds = const Value.absent(),
  });
  static Insertable<AppUsageDayRow> custom({
    Expression<int>? date,
    Expression<int>? foregroundMilliseconds,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (foregroundMilliseconds != null)
        'foreground_milliseconds': foregroundMilliseconds,
    });
  }

  AppUsageDaysCompanion copyWith({
    Value<int>? date,
    Value<int>? foregroundMilliseconds,
  }) {
    return AppUsageDaysCompanion(
      date: date ?? this.date,
      foregroundMilliseconds:
          foregroundMilliseconds ?? this.foregroundMilliseconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (foregroundMilliseconds.present) {
      map['foreground_milliseconds'] = Variable<int>(
        foregroundMilliseconds.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageDaysCompanion(')
          ..write('date: $date, ')
          ..write('foregroundMilliseconds: $foregroundMilliseconds')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, email, avatarPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'UserProfile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final int id;
  final String name;
  final String email;
  final String? avatarPath;
  const UserProfileRow({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      name: Value(name),
      email: Value(email),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'avatarPath': serializer.toJson<String?>(avatarPath),
    };
  }

  UserProfileRow copyWith({
    int? id,
    String? name,
    String? email,
    Value<String?> avatarPath = const Value.absent(),
  }) => UserProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
  );
  UserProfileRow copyWithCompanion(UserProfilesCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('avatarPath: $avatarPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, email, avatarPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.avatarPath == this.avatarPath);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> avatarPath;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.avatarPath = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String email,
    this.avatarPath = const Value.absent(),
  }) : name = Value(name),
       email = Value(email);
  static Insertable<UserProfileRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? avatarPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (avatarPath != null) 'avatar_path': avatarPath,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? email,
    Value<String?>? avatarPath,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('avatarPath: $avatarPath')
          ..write(')'))
        .toString();
  }
}

class $ListeningLessonProgressModelsTable extends ListeningLessonProgressModels
    with
        TableInfo<
          $ListeningLessonProgressModelsTable,
          ListeningLessonProgressRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningLessonProgressModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<int> lessonId = GeneratedColumn<int>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentChallengePositionMeta =
      const VerificationMeta('currentChallengePosition');
  @override
  late final GeneratedColumn<int> currentChallengePosition =
      GeneratedColumn<int>(
        'current_challenge_position',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      );
  static const VerificationMeta _completedChallengesMeta =
      const VerificationMeta('completedChallenges');
  @override
  late final GeneratedColumn<int> completedChallenges = GeneratedColumn<int>(
    'completed_challenges',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalChallengesMeta = const VerificationMeta(
    'totalChallenges',
  );
  @override
  late final GeneratedColumn<int> totalChallenges = GeneratedColumn<int>(
    'total_challenges',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMillisecondsMeta =
      const VerificationMeta('activeMilliseconds');
  @override
  late final GeneratedColumn<int> activeMilliseconds = GeneratedColumn<int>(
    'active_milliseconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    courseId,
    lessonId,
    currentChallengePosition,
    completedChallenges,
    totalChallenges,
    status,
    startedAt,
    updatedAt,
    completedAt,
    activeMilliseconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_lesson_progress_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListeningLessonProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('current_challenge_position')) {
      context.handle(
        _currentChallengePositionMeta,
        currentChallengePosition.isAcceptableOrUnknown(
          data['current_challenge_position']!,
          _currentChallengePositionMeta,
        ),
      );
    }
    if (data.containsKey('completed_challenges')) {
      context.handle(
        _completedChallengesMeta,
        completedChallenges.isAcceptableOrUnknown(
          data['completed_challenges']!,
          _completedChallengesMeta,
        ),
      );
    }
    if (data.containsKey('total_challenges')) {
      context.handle(
        _totalChallengesMeta,
        totalChallenges.isAcceptableOrUnknown(
          data['total_challenges']!,
          _totalChallengesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalChallengesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('active_milliseconds')) {
      context.handle(
        _activeMillisecondsMeta,
        activeMilliseconds.isAcceptableOrUnknown(
          data['active_milliseconds']!,
          _activeMillisecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseId, lessonId};
  @override
  ListeningLessonProgressRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningLessonProgressRow(
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lesson_id'],
      )!,
      currentChallengePosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_challenge_position'],
      )!,
      completedChallenges: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_challenges'],
      )!,
      totalChallenges: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_challenges'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      activeMilliseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_milliseconds'],
      )!,
    );
  }

  @override
  $ListeningLessonProgressModelsTable createAlias(String alias) {
    return $ListeningLessonProgressModelsTable(attachedDatabase, alias);
  }
}

class ListeningLessonProgressRow extends DataClass
    implements Insertable<ListeningLessonProgressRow> {
  final int courseId;
  final int lessonId;
  final int currentChallengePosition;
  final int completedChallenges;
  final int totalChallenges;
  final int status;
  final int startedAt;
  final int updatedAt;
  final int? completedAt;
  final int activeMilliseconds;
  const ListeningLessonProgressRow({
    required this.courseId,
    required this.lessonId,
    required this.currentChallengePosition,
    required this.completedChallenges,
    required this.totalChallenges,
    required this.status,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
    required this.activeMilliseconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_id'] = Variable<int>(courseId);
    map['lesson_id'] = Variable<int>(lessonId);
    map['current_challenge_position'] = Variable<int>(currentChallengePosition);
    map['completed_challenges'] = Variable<int>(completedChallenges);
    map['total_challenges'] = Variable<int>(totalChallenges);
    map['status'] = Variable<int>(status);
    map['started_at'] = Variable<int>(startedAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['active_milliseconds'] = Variable<int>(activeMilliseconds);
    return map;
  }

  ListeningLessonProgressModelsCompanion toCompanion(bool nullToAbsent) {
    return ListeningLessonProgressModelsCompanion(
      courseId: Value(courseId),
      lessonId: Value(lessonId),
      currentChallengePosition: Value(currentChallengePosition),
      completedChallenges: Value(completedChallenges),
      totalChallenges: Value(totalChallenges),
      status: Value(status),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      activeMilliseconds: Value(activeMilliseconds),
    );
  }

  factory ListeningLessonProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningLessonProgressRow(
      courseId: serializer.fromJson<int>(json['courseId']),
      lessonId: serializer.fromJson<int>(json['lessonId']),
      currentChallengePosition: serializer.fromJson<int>(
        json['currentChallengePosition'],
      ),
      completedChallenges: serializer.fromJson<int>(
        json['completedChallenges'],
      ),
      totalChallenges: serializer.fromJson<int>(json['totalChallenges']),
      status: serializer.fromJson<int>(json['status']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      activeMilliseconds: serializer.fromJson<int>(json['activeMilliseconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseId': serializer.toJson<int>(courseId),
      'lessonId': serializer.toJson<int>(lessonId),
      'currentChallengePosition': serializer.toJson<int>(
        currentChallengePosition,
      ),
      'completedChallenges': serializer.toJson<int>(completedChallenges),
      'totalChallenges': serializer.toJson<int>(totalChallenges),
      'status': serializer.toJson<int>(status),
      'startedAt': serializer.toJson<int>(startedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'activeMilliseconds': serializer.toJson<int>(activeMilliseconds),
    };
  }

  ListeningLessonProgressRow copyWith({
    int? courseId,
    int? lessonId,
    int? currentChallengePosition,
    int? completedChallenges,
    int? totalChallenges,
    int? status,
    int? startedAt,
    int? updatedAt,
    Value<int?> completedAt = const Value.absent(),
    int? activeMilliseconds,
  }) => ListeningLessonProgressRow(
    courseId: courseId ?? this.courseId,
    lessonId: lessonId ?? this.lessonId,
    currentChallengePosition:
        currentChallengePosition ?? this.currentChallengePosition,
    completedChallenges: completedChallenges ?? this.completedChallenges,
    totalChallenges: totalChallenges ?? this.totalChallenges,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    activeMilliseconds: activeMilliseconds ?? this.activeMilliseconds,
  );
  ListeningLessonProgressRow copyWithCompanion(
    ListeningLessonProgressModelsCompanion data,
  ) {
    return ListeningLessonProgressRow(
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      currentChallengePosition: data.currentChallengePosition.present
          ? data.currentChallengePosition.value
          : this.currentChallengePosition,
      completedChallenges: data.completedChallenges.present
          ? data.completedChallenges.value
          : this.completedChallenges,
      totalChallenges: data.totalChallenges.present
          ? data.totalChallenges.value
          : this.totalChallenges,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      activeMilliseconds: data.activeMilliseconds.present
          ? data.activeMilliseconds.value
          : this.activeMilliseconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningLessonProgressRow(')
          ..write('courseId: $courseId, ')
          ..write('lessonId: $lessonId, ')
          ..write('currentChallengePosition: $currentChallengePosition, ')
          ..write('completedChallenges: $completedChallenges, ')
          ..write('totalChallenges: $totalChallenges, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('activeMilliseconds: $activeMilliseconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    courseId,
    lessonId,
    currentChallengePosition,
    completedChallenges,
    totalChallenges,
    status,
    startedAt,
    updatedAt,
    completedAt,
    activeMilliseconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningLessonProgressRow &&
          other.courseId == this.courseId &&
          other.lessonId == this.lessonId &&
          other.currentChallengePosition == this.currentChallengePosition &&
          other.completedChallenges == this.completedChallenges &&
          other.totalChallenges == this.totalChallenges &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.activeMilliseconds == this.activeMilliseconds);
}

class ListeningLessonProgressModelsCompanion
    extends UpdateCompanion<ListeningLessonProgressRow> {
  final Value<int> courseId;
  final Value<int> lessonId;
  final Value<int> currentChallengePosition;
  final Value<int> completedChallenges;
  final Value<int> totalChallenges;
  final Value<int> status;
  final Value<int> startedAt;
  final Value<int> updatedAt;
  final Value<int?> completedAt;
  final Value<int> activeMilliseconds;
  final Value<int> rowid;
  const ListeningLessonProgressModelsCompanion({
    this.courseId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.currentChallengePosition = const Value.absent(),
    this.completedChallenges = const Value.absent(),
    this.totalChallenges = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.activeMilliseconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListeningLessonProgressModelsCompanion.insert({
    required int courseId,
    required int lessonId,
    this.currentChallengePosition = const Value.absent(),
    this.completedChallenges = const Value.absent(),
    required int totalChallenges,
    this.status = const Value.absent(),
    required int startedAt,
    required int updatedAt,
    this.completedAt = const Value.absent(),
    this.activeMilliseconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       lessonId = Value(lessonId),
       totalChallenges = Value(totalChallenges),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<ListeningLessonProgressRow> custom({
    Expression<int>? courseId,
    Expression<int>? lessonId,
    Expression<int>? currentChallengePosition,
    Expression<int>? completedChallenges,
    Expression<int>? totalChallenges,
    Expression<int>? status,
    Expression<int>? startedAt,
    Expression<int>? updatedAt,
    Expression<int>? completedAt,
    Expression<int>? activeMilliseconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseId != null) 'course_id': courseId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (currentChallengePosition != null)
        'current_challenge_position': currentChallengePosition,
      if (completedChallenges != null)
        'completed_challenges': completedChallenges,
      if (totalChallenges != null) 'total_challenges': totalChallenges,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (activeMilliseconds != null) 'active_milliseconds': activeMilliseconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListeningLessonProgressModelsCompanion copyWith({
    Value<int>? courseId,
    Value<int>? lessonId,
    Value<int>? currentChallengePosition,
    Value<int>? completedChallenges,
    Value<int>? totalChallenges,
    Value<int>? status,
    Value<int>? startedAt,
    Value<int>? updatedAt,
    Value<int?>? completedAt,
    Value<int>? activeMilliseconds,
    Value<int>? rowid,
  }) {
    return ListeningLessonProgressModelsCompanion(
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      currentChallengePosition:
          currentChallengePosition ?? this.currentChallengePosition,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      totalChallenges: totalChallenges ?? this.totalChallenges,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      activeMilliseconds: activeMilliseconds ?? this.activeMilliseconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<int>(lessonId.value);
    }
    if (currentChallengePosition.present) {
      map['current_challenge_position'] = Variable<int>(
        currentChallengePosition.value,
      );
    }
    if (completedChallenges.present) {
      map['completed_challenges'] = Variable<int>(completedChallenges.value);
    }
    if (totalChallenges.present) {
      map['total_challenges'] = Variable<int>(totalChallenges.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (activeMilliseconds.present) {
      map['active_milliseconds'] = Variable<int>(activeMilliseconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningLessonProgressModelsCompanion(')
          ..write('courseId: $courseId, ')
          ..write('lessonId: $lessonId, ')
          ..write('currentChallengePosition: $currentChallengePosition, ')
          ..write('completedChallenges: $completedChallenges, ')
          ..write('totalChallenges: $totalChallenges, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('activeMilliseconds: $activeMilliseconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListeningChallengeProgressModelsTable
    extends ListeningChallengeProgressModels
    with
        TableInfo<
          $ListeningChallengeProgressModelsTable,
          ListeningChallengeProgressRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningChallengeProgressModelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<int> lessonId = GeneratedColumn<int>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _challengeIdMeta = const VerificationMeta(
    'challengeId',
  );
  @override
  late final GeneratedColumn<int> challengeId = GeneratedColumn<int>(
    'challenge_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSkippedMeta = const VerificationMeta(
    'isSkipped',
  );
  @override
  late final GeneratedColumn<bool> isSkipped = GeneratedColumn<bool>(
    'is_skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAnswerMeta = const VerificationMeta(
    'lastAnswer',
  );
  @override
  late final GeneratedColumn<String> lastAnswer = GeneratedColumn<String>(
    'last_answer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    courseId,
    lessonId,
    challengeId,
    position,
    isCompleted,
    isSkipped,
    attemptCount,
    lastAnswer,
    updatedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_challenge_progress_models';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListeningChallengeProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('challenge_id')) {
      context.handle(
        _challengeIdMeta,
        challengeId.isAcceptableOrUnknown(
          data['challenge_id']!,
          _challengeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_challengeIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('is_skipped')) {
      context.handle(
        _isSkippedMeta,
        isSkipped.isAcceptableOrUnknown(data['is_skipped']!, _isSkippedMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_answer')) {
      context.handle(
        _lastAnswerMeta,
        lastAnswer.isAcceptableOrUnknown(data['last_answer']!, _lastAnswerMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseId, lessonId, challengeId};
  @override
  ListeningChallengeProgressRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningChallengeProgressRow(
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lesson_id'],
      )!,
      challengeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}challenge_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      isSkipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_skipped'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_answer'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $ListeningChallengeProgressModelsTable createAlias(String alias) {
    return $ListeningChallengeProgressModelsTable(attachedDatabase, alias);
  }
}

class ListeningChallengeProgressRow extends DataClass
    implements Insertable<ListeningChallengeProgressRow> {
  final int courseId;
  final int lessonId;
  final int challengeId;
  final int position;
  final bool isCompleted;
  final bool isSkipped;
  final int attemptCount;
  final String? lastAnswer;
  final int updatedAt;
  final int? completedAt;
  const ListeningChallengeProgressRow({
    required this.courseId,
    required this.lessonId,
    required this.challengeId,
    required this.position,
    required this.isCompleted,
    required this.isSkipped,
    required this.attemptCount,
    this.lastAnswer,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_id'] = Variable<int>(courseId);
    map['lesson_id'] = Variable<int>(lessonId);
    map['challenge_id'] = Variable<int>(challengeId);
    map['position'] = Variable<int>(position);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['is_skipped'] = Variable<bool>(isSkipped);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastAnswer != null) {
      map['last_answer'] = Variable<String>(lastAnswer);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  ListeningChallengeProgressModelsCompanion toCompanion(bool nullToAbsent) {
    return ListeningChallengeProgressModelsCompanion(
      courseId: Value(courseId),
      lessonId: Value(lessonId),
      challengeId: Value(challengeId),
      position: Value(position),
      isCompleted: Value(isCompleted),
      isSkipped: Value(isSkipped),
      attemptCount: Value(attemptCount),
      lastAnswer: lastAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAnswer),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ListeningChallengeProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningChallengeProgressRow(
      courseId: serializer.fromJson<int>(json['courseId']),
      lessonId: serializer.fromJson<int>(json['lessonId']),
      challengeId: serializer.fromJson<int>(json['challengeId']),
      position: serializer.fromJson<int>(json['position']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      isSkipped: serializer.fromJson<bool>(json['isSkipped']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastAnswer: serializer.fromJson<String?>(json['lastAnswer']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseId': serializer.toJson<int>(courseId),
      'lessonId': serializer.toJson<int>(lessonId),
      'challengeId': serializer.toJson<int>(challengeId),
      'position': serializer.toJson<int>(position),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'isSkipped': serializer.toJson<bool>(isSkipped),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastAnswer': serializer.toJson<String?>(lastAnswer),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  ListeningChallengeProgressRow copyWith({
    int? courseId,
    int? lessonId,
    int? challengeId,
    int? position,
    bool? isCompleted,
    bool? isSkipped,
    int? attemptCount,
    Value<String?> lastAnswer = const Value.absent(),
    int? updatedAt,
    Value<int?> completedAt = const Value.absent(),
  }) => ListeningChallengeProgressRow(
    courseId: courseId ?? this.courseId,
    lessonId: lessonId ?? this.lessonId,
    challengeId: challengeId ?? this.challengeId,
    position: position ?? this.position,
    isCompleted: isCompleted ?? this.isCompleted,
    isSkipped: isSkipped ?? this.isSkipped,
    attemptCount: attemptCount ?? this.attemptCount,
    lastAnswer: lastAnswer.present ? lastAnswer.value : this.lastAnswer,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  ListeningChallengeProgressRow copyWithCompanion(
    ListeningChallengeProgressModelsCompanion data,
  ) {
    return ListeningChallengeProgressRow(
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      challengeId: data.challengeId.present
          ? data.challengeId.value
          : this.challengeId,
      position: data.position.present ? data.position.value : this.position,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      isSkipped: data.isSkipped.present ? data.isSkipped.value : this.isSkipped,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastAnswer: data.lastAnswer.present
          ? data.lastAnswer.value
          : this.lastAnswer,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningChallengeProgressRow(')
          ..write('courseId: $courseId, ')
          ..write('lessonId: $lessonId, ')
          ..write('challengeId: $challengeId, ')
          ..write('position: $position, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAnswer: $lastAnswer, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    courseId,
    lessonId,
    challengeId,
    position,
    isCompleted,
    isSkipped,
    attemptCount,
    lastAnswer,
    updatedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningChallengeProgressRow &&
          other.courseId == this.courseId &&
          other.lessonId == this.lessonId &&
          other.challengeId == this.challengeId &&
          other.position == this.position &&
          other.isCompleted == this.isCompleted &&
          other.isSkipped == this.isSkipped &&
          other.attemptCount == this.attemptCount &&
          other.lastAnswer == this.lastAnswer &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class ListeningChallengeProgressModelsCompanion
    extends UpdateCompanion<ListeningChallengeProgressRow> {
  final Value<int> courseId;
  final Value<int> lessonId;
  final Value<int> challengeId;
  final Value<int> position;
  final Value<bool> isCompleted;
  final Value<bool> isSkipped;
  final Value<int> attemptCount;
  final Value<String?> lastAnswer;
  final Value<int> updatedAt;
  final Value<int?> completedAt;
  final Value<int> rowid;
  const ListeningChallengeProgressModelsCompanion({
    this.courseId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.challengeId = const Value.absent(),
    this.position = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAnswer = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListeningChallengeProgressModelsCompanion.insert({
    required int courseId,
    required int lessonId,
    required int challengeId,
    required int position,
    this.isCompleted = const Value.absent(),
    this.isSkipped = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastAnswer = const Value.absent(),
    required int updatedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       lessonId = Value(lessonId),
       challengeId = Value(challengeId),
       position = Value(position),
       updatedAt = Value(updatedAt);
  static Insertable<ListeningChallengeProgressRow> custom({
    Expression<int>? courseId,
    Expression<int>? lessonId,
    Expression<int>? challengeId,
    Expression<int>? position,
    Expression<bool>? isCompleted,
    Expression<bool>? isSkipped,
    Expression<int>? attemptCount,
    Expression<String>? lastAnswer,
    Expression<int>? updatedAt,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseId != null) 'course_id': courseId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (challengeId != null) 'challenge_id': challengeId,
      if (position != null) 'position': position,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (isSkipped != null) 'is_skipped': isSkipped,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastAnswer != null) 'last_answer': lastAnswer,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListeningChallengeProgressModelsCompanion copyWith({
    Value<int>? courseId,
    Value<int>? lessonId,
    Value<int>? challengeId,
    Value<int>? position,
    Value<bool>? isCompleted,
    Value<bool>? isSkipped,
    Value<int>? attemptCount,
    Value<String?>? lastAnswer,
    Value<int>? updatedAt,
    Value<int?>? completedAt,
    Value<int>? rowid,
  }) {
    return ListeningChallengeProgressModelsCompanion(
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
      challengeId: challengeId ?? this.challengeId,
      position: position ?? this.position,
      isCompleted: isCompleted ?? this.isCompleted,
      isSkipped: isSkipped ?? this.isSkipped,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAnswer: lastAnswer ?? this.lastAnswer,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<int>(lessonId.value);
    }
    if (challengeId.present) {
      map['challenge_id'] = Variable<int>(challengeId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (isSkipped.present) {
      map['is_skipped'] = Variable<bool>(isSkipped.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastAnswer.present) {
      map['last_answer'] = Variable<String>(lastAnswer.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningChallengeProgressModelsCompanion(')
          ..write('courseId: $courseId, ')
          ..write('lessonId: $lessonId, ')
          ..write('challengeId: $challengeId, ')
          ..write('position: $position, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isSkipped: $isSkipped, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastAnswer: $lastAnswer, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListeningPracticeDaysTable extends ListeningPracticeDays
    with TableInfo<$ListeningPracticeDaysTable, ListeningPracticeDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningPracticeDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMillisecondsMeta =
      const VerificationMeta('activeMilliseconds');
  @override
  late final GeneratedColumn<int> activeMilliseconds = GeneratedColumn<int>(
    'active_milliseconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [date, activeMilliseconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_practice_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListeningPracticeDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('active_milliseconds')) {
      context.handle(
        _activeMillisecondsMeta,
        activeMilliseconds.isAcceptableOrUnknown(
          data['active_milliseconds']!,
          _activeMillisecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  ListeningPracticeDayRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningPracticeDayRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      activeMilliseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_milliseconds'],
      )!,
    );
  }

  @override
  $ListeningPracticeDaysTable createAlias(String alias) {
    return $ListeningPracticeDaysTable(attachedDatabase, alias);
  }
}

class ListeningPracticeDayRow extends DataClass
    implements Insertable<ListeningPracticeDayRow> {
  /// Local midnight, stored as milliseconds since epoch.
  final int date;
  final int activeMilliseconds;
  const ListeningPracticeDayRow({
    required this.date,
    required this.activeMilliseconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<int>(date);
    map['active_milliseconds'] = Variable<int>(activeMilliseconds);
    return map;
  }

  ListeningPracticeDaysCompanion toCompanion(bool nullToAbsent) {
    return ListeningPracticeDaysCompanion(
      date: Value(date),
      activeMilliseconds: Value(activeMilliseconds),
    );
  }

  factory ListeningPracticeDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningPracticeDayRow(
      date: serializer.fromJson<int>(json['date']),
      activeMilliseconds: serializer.fromJson<int>(json['activeMilliseconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<int>(date),
      'activeMilliseconds': serializer.toJson<int>(activeMilliseconds),
    };
  }

  ListeningPracticeDayRow copyWith({int? date, int? activeMilliseconds}) =>
      ListeningPracticeDayRow(
        date: date ?? this.date,
        activeMilliseconds: activeMilliseconds ?? this.activeMilliseconds,
      );
  ListeningPracticeDayRow copyWithCompanion(
    ListeningPracticeDaysCompanion data,
  ) {
    return ListeningPracticeDayRow(
      date: data.date.present ? data.date.value : this.date,
      activeMilliseconds: data.activeMilliseconds.present
          ? data.activeMilliseconds.value
          : this.activeMilliseconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningPracticeDayRow(')
          ..write('date: $date, ')
          ..write('activeMilliseconds: $activeMilliseconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, activeMilliseconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningPracticeDayRow &&
          other.date == this.date &&
          other.activeMilliseconds == this.activeMilliseconds);
}

class ListeningPracticeDaysCompanion
    extends UpdateCompanion<ListeningPracticeDayRow> {
  final Value<int> date;
  final Value<int> activeMilliseconds;
  const ListeningPracticeDaysCompanion({
    this.date = const Value.absent(),
    this.activeMilliseconds = const Value.absent(),
  });
  ListeningPracticeDaysCompanion.insert({
    this.date = const Value.absent(),
    this.activeMilliseconds = const Value.absent(),
  });
  static Insertable<ListeningPracticeDayRow> custom({
    Expression<int>? date,
    Expression<int>? activeMilliseconds,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (activeMilliseconds != null) 'active_milliseconds': activeMilliseconds,
    });
  }

  ListeningPracticeDaysCompanion copyWith({
    Value<int>? date,
    Value<int>? activeMilliseconds,
  }) {
    return ListeningPracticeDaysCompanion(
      date: date ?? this.date,
      activeMilliseconds: activeMilliseconds ?? this.activeMilliseconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (activeMilliseconds.present) {
      map['active_milliseconds'] = Variable<int>(activeMilliseconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningPracticeDaysCompanion(')
          ..write('date: $date, ')
          ..write('activeMilliseconds: $activeMilliseconds')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TopicModelsTable topicModels = $TopicModelsTable(this);
  late final $WordModelsTable wordModels = $WordModelsTable(this);
  late final $LearningProgressModelsTable learningProgressModels =
      $LearningProgressModelsTable(this);
  late final $WordSentenceProgressModelsTable wordSentenceProgressModels =
      $WordSentenceProgressModelsTable(this);
  late final $SentenceExposureModelsTable sentenceExposureModels =
      $SentenceExposureModelsTable(this);
  late final $LearningSessionsTable learningSessions = $LearningSessionsTable(
    this,
  );
  late final $SessionExercisesTable sessionExercises = $SessionExercisesTable(
    this,
  );
  late final $SimilarWordModelsTable similarWordModels =
      $SimilarWordModelsTable(this);
  late final $SttMisspellingModelsTable sttMisspellingModels =
      $SttMisspellingModelsTable(this);
  late final $LetterModelsTable letterModels = $LetterModelsTable(this);
  late final $VisitModelsTable visitModels = $VisitModelsTable(this);
  late final $OnboardingTestAnswerModelsTable onboardingTestAnswerModels =
      $OnboardingTestAnswerModelsTable(this);
  late final $ContentRevisionsTable contentRevisions = $ContentRevisionsTable(
    this,
  );
  late final $AppUsageDaysTable appUsageDays = $AppUsageDaysTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $ListeningLessonProgressModelsTable listeningLessonProgressModels =
      $ListeningLessonProgressModelsTable(this);
  late final $ListeningChallengeProgressModelsTable
  listeningChallengeProgressModels = $ListeningChallengeProgressModelsTable(
    this,
  );
  late final $ListeningPracticeDaysTable listeningPracticeDays =
      $ListeningPracticeDaysTable(this);
  late final Index topicModelEnabledOrder = Index(
    'topic_model_enabled_order',
    'CREATE INDEX topic_model_enabled_order ON TopicModel (is_enabled, "order")',
  );
  late final Index wordModelTopicEnabled = Index(
    'word_model_topic_enabled',
    'CREATE INDEX word_model_topic_enabled ON WordModel (topic_id, is_enabled)',
  );
  late final Index learningProgressRepetitionDate = Index(
    'learning_progress_repetition_date',
    'CREATE INDEX learning_progress_repetition_date ON LearningProgressModel (repetition_date)',
  );
  late final Index sentenceExposureWord = Index(
    'sentence_exposure_word',
    'CREATE INDEX sentence_exposure_word ON sentence_exposure_models (word_id)',
  );
  late final Index learningSessionStatusStartedAt = Index(
    'learning_session_status_started_at',
    'CREATE INDEX learning_session_status_started_at ON LearningSession (status, started_at)',
  );
  late final Index sessionExerciseSessionOrder = Index(
    'session_exercise_session_order',
    'CREATE UNIQUE INDEX session_exercise_session_order ON SessionExercise (session_id, order_index)',
  );
  late final Index listeningLessonProgressStatusUpdated = Index(
    'listening_lesson_progress_status_updated',
    'CREATE INDEX listening_lesson_progress_status_updated ON listening_lesson_progress_models (status, updated_at)',
  );
  late final Index listeningChallengeProgressLessonPosition = Index(
    'listening_challenge_progress_lesson_position',
    'CREATE UNIQUE INDEX listening_challenge_progress_lesson_position ON listening_challenge_progress_models (course_id, lesson_id, position)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    topicModels,
    wordModels,
    learningProgressModels,
    wordSentenceProgressModels,
    sentenceExposureModels,
    learningSessions,
    sessionExercises,
    similarWordModels,
    sttMisspellingModels,
    letterModels,
    visitModels,
    onboardingTestAnswerModels,
    contentRevisions,
    appUsageDays,
    userProfiles,
    listeningLessonProgressModels,
    listeningChallengeProgressModels,
    listeningPracticeDays,
    topicModelEnabledOrder,
    wordModelTopicEnabled,
    learningProgressRepetitionDate,
    sentenceExposureWord,
    learningSessionStatusStartedAt,
    sessionExerciseSessionOrder,
    listeningLessonProgressStatusUpdated,
    listeningChallengeProgressLessonPosition,
  ];
}

typedef $$TopicModelsTableCreateCompanionBuilder =
    TopicModelsCompanion Function({
      Value<int> id,
      Value<String?> originalName,
      Value<String?> translatedName,
      required bool isEnabled,
      required int sortOrder,
      Value<bool> isSelected,
    });
typedef $$TopicModelsTableUpdateCompanionBuilder =
    TopicModelsCompanion Function({
      Value<int> id,
      Value<String?> originalName,
      Value<String?> translatedName,
      Value<bool> isEnabled,
      Value<int> sortOrder,
      Value<bool> isSelected,
    });

class $$TopicModelsTableFilterComposer
    extends Composer<_$AppDatabase, $TopicModelsTable> {
  $$TopicModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translatedName => $composableBuilder(
    column: $table.translatedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TopicModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicModelsTable> {
  $$TopicModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translatedName => $composableBuilder(
    column: $table.translatedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TopicModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicModelsTable> {
  $$TopicModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translatedName => $composableBuilder(
    column: $table.translatedName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => column,
  );
}

class $$TopicModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TopicModelsTable,
          TopicRow,
          $$TopicModelsTableFilterComposer,
          $$TopicModelsTableOrderingComposer,
          $$TopicModelsTableAnnotationComposer,
          $$TopicModelsTableCreateCompanionBuilder,
          $$TopicModelsTableUpdateCompanionBuilder,
          (
            TopicRow,
            BaseReferences<_$AppDatabase, $TopicModelsTable, TopicRow>,
          ),
          TopicRow,
          PrefetchHooks Function()
        > {
  $$TopicModelsTableTableManager(_$AppDatabase db, $TopicModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> originalName = const Value.absent(),
                Value<String?> translatedName = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isSelected = const Value.absent(),
              }) => TopicModelsCompanion(
                id: id,
                originalName: originalName,
                translatedName: translatedName,
                isEnabled: isEnabled,
                sortOrder: sortOrder,
                isSelected: isSelected,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> originalName = const Value.absent(),
                Value<String?> translatedName = const Value.absent(),
                required bool isEnabled,
                required int sortOrder,
                Value<bool> isSelected = const Value.absent(),
              }) => TopicModelsCompanion.insert(
                id: id,
                originalName: originalName,
                translatedName: translatedName,
                isEnabled: isEnabled,
                sortOrder: sortOrder,
                isSelected: isSelected,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TopicModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TopicModelsTable,
      TopicRow,
      $$TopicModelsTableFilterComposer,
      $$TopicModelsTableOrderingComposer,
      $$TopicModelsTableAnnotationComposer,
      $$TopicModelsTableCreateCompanionBuilder,
      $$TopicModelsTableUpdateCompanionBuilder,
      (TopicRow, BaseReferences<_$AppDatabase, $TopicModelsTable, TopicRow>),
      TopicRow,
      PrefetchHooks Function()
    >;
typedef $$WordModelsTableCreateCompanionBuilder =
    WordModelsCompanion Function({
      required int id,
      required int topicId,
      required String writing,
      required String translation,
      Value<String?> transcription,
      Value<String?> transliteration,
      required bool isEnabled,
      required int priority,
      required int level,
      Value<int> showCount,
      Value<int> rowid,
    });
typedef $$WordModelsTableUpdateCompanionBuilder =
    WordModelsCompanion Function({
      Value<int> id,
      Value<int> topicId,
      Value<String> writing,
      Value<String> translation,
      Value<String?> transcription,
      Value<String?> transliteration,
      Value<bool> isEnabled,
      Value<int> priority,
      Value<int> level,
      Value<int> showCount,
      Value<int> rowid,
    });

class $$WordModelsTableFilterComposer
    extends Composer<_$AppDatabase, $WordModelsTable> {
  $$WordModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get writing => $composableBuilder(
    column: $table.writing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get showCount => $composableBuilder(
    column: $table.showCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordModelsTable> {
  $$WordModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get writing => $composableBuilder(
    column: $table.writing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get showCount => $composableBuilder(
    column: $table.showCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordModelsTable> {
  $$WordModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get writing =>
      $composableBuilder(column: $table.writing, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get showCount =>
      $composableBuilder(column: $table.showCount, builder: (column) => column);
}

class $$WordModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordModelsTable,
          WordRow,
          $$WordModelsTableFilterComposer,
          $$WordModelsTableOrderingComposer,
          $$WordModelsTableAnnotationComposer,
          $$WordModelsTableCreateCompanionBuilder,
          $$WordModelsTableUpdateCompanionBuilder,
          (WordRow, BaseReferences<_$AppDatabase, $WordModelsTable, WordRow>),
          WordRow,
          PrefetchHooks Function()
        > {
  $$WordModelsTableTableManager(_$AppDatabase db, $WordModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> topicId = const Value.absent(),
                Value<String> writing = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<String?> transcription = const Value.absent(),
                Value<String?> transliteration = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> showCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordModelsCompanion(
                id: id,
                topicId: topicId,
                writing: writing,
                translation: translation,
                transcription: transcription,
                transliteration: transliteration,
                isEnabled: isEnabled,
                priority: priority,
                level: level,
                showCount: showCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                required int topicId,
                required String writing,
                required String translation,
                Value<String?> transcription = const Value.absent(),
                Value<String?> transliteration = const Value.absent(),
                required bool isEnabled,
                required int priority,
                required int level,
                Value<int> showCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordModelsCompanion.insert(
                id: id,
                topicId: topicId,
                writing: writing,
                translation: translation,
                transcription: transcription,
                transliteration: transliteration,
                isEnabled: isEnabled,
                priority: priority,
                level: level,
                showCount: showCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordModelsTable,
      WordRow,
      $$WordModelsTableFilterComposer,
      $$WordModelsTableOrderingComposer,
      $$WordModelsTableAnnotationComposer,
      $$WordModelsTableCreateCompanionBuilder,
      $$WordModelsTableUpdateCompanionBuilder,
      (WordRow, BaseReferences<_$AppDatabase, $WordModelsTable, WordRow>),
      WordRow,
      PrefetchHooks Function()
    >;
typedef $$LearningProgressModelsTableCreateCompanionBuilder =
    LearningProgressModelsCompanion Function({
      Value<int> id,
      required int creationDate,
      Value<int> trainingProgress,
      Value<int> trainingError,
      Value<int> repetitionStep,
      Value<int?> repetitionDate,
      Value<int?> learnedDate,
      Value<bool> onFastBrain,
      Value<int> repetitionFastBrainStep,
      Value<int?> repetitionFastBrainDate,
      Value<bool> markedAsKnown,
      Value<bool> deletedByUser,
    });
typedef $$LearningProgressModelsTableUpdateCompanionBuilder =
    LearningProgressModelsCompanion Function({
      Value<int> id,
      Value<int> creationDate,
      Value<int> trainingProgress,
      Value<int> trainingError,
      Value<int> repetitionStep,
      Value<int?> repetitionDate,
      Value<int?> learnedDate,
      Value<bool> onFastBrain,
      Value<int> repetitionFastBrainStep,
      Value<int?> repetitionFastBrainDate,
      Value<bool> markedAsKnown,
      Value<bool> deletedByUser,
    });

class $$LearningProgressModelsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningProgressModelsTable> {
  $$LearningProgressModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trainingProgress => $composableBuilder(
    column: $table.trainingProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trainingError => $composableBuilder(
    column: $table.trainingError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitionStep => $composableBuilder(
    column: $table.repetitionStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitionDate => $composableBuilder(
    column: $table.repetitionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnedDate => $composableBuilder(
    column: $table.learnedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onFastBrain => $composableBuilder(
    column: $table.onFastBrain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitionFastBrainStep => $composableBuilder(
    column: $table.repetitionFastBrainStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitionFastBrainDate => $composableBuilder(
    column: $table.repetitionFastBrainDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get markedAsKnown => $composableBuilder(
    column: $table.markedAsKnown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deletedByUser => $composableBuilder(
    column: $table.deletedByUser,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningProgressModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningProgressModelsTable> {
  $$LearningProgressModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trainingProgress => $composableBuilder(
    column: $table.trainingProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trainingError => $composableBuilder(
    column: $table.trainingError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitionStep => $composableBuilder(
    column: $table.repetitionStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitionDate => $composableBuilder(
    column: $table.repetitionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnedDate => $composableBuilder(
    column: $table.learnedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onFastBrain => $composableBuilder(
    column: $table.onFastBrain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitionFastBrainStep => $composableBuilder(
    column: $table.repetitionFastBrainStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitionFastBrainDate => $composableBuilder(
    column: $table.repetitionFastBrainDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get markedAsKnown => $composableBuilder(
    column: $table.markedAsKnown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deletedByUser => $composableBuilder(
    column: $table.deletedByUser,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningProgressModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningProgressModelsTable> {
  $$LearningProgressModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trainingProgress => $composableBuilder(
    column: $table.trainingProgress,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trainingError => $composableBuilder(
    column: $table.trainingError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitionStep => $composableBuilder(
    column: $table.repetitionStep,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitionDate => $composableBuilder(
    column: $table.repetitionDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnedDate => $composableBuilder(
    column: $table.learnedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onFastBrain => $composableBuilder(
    column: $table.onFastBrain,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitionFastBrainStep => $composableBuilder(
    column: $table.repetitionFastBrainStep,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitionFastBrainDate => $composableBuilder(
    column: $table.repetitionFastBrainDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get markedAsKnown => $composableBuilder(
    column: $table.markedAsKnown,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deletedByUser => $composableBuilder(
    column: $table.deletedByUser,
    builder: (column) => column,
  );
}

class $$LearningProgressModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningProgressModelsTable,
          LearningProgressRow,
          $$LearningProgressModelsTableFilterComposer,
          $$LearningProgressModelsTableOrderingComposer,
          $$LearningProgressModelsTableAnnotationComposer,
          $$LearningProgressModelsTableCreateCompanionBuilder,
          $$LearningProgressModelsTableUpdateCompanionBuilder,
          (
            LearningProgressRow,
            BaseReferences<
              _$AppDatabase,
              $LearningProgressModelsTable,
              LearningProgressRow
            >,
          ),
          LearningProgressRow,
          PrefetchHooks Function()
        > {
  $$LearningProgressModelsTableTableManager(
    _$AppDatabase db,
    $LearningProgressModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningProgressModelsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LearningProgressModelsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LearningProgressModelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> creationDate = const Value.absent(),
                Value<int> trainingProgress = const Value.absent(),
                Value<int> trainingError = const Value.absent(),
                Value<int> repetitionStep = const Value.absent(),
                Value<int?> repetitionDate = const Value.absent(),
                Value<int?> learnedDate = const Value.absent(),
                Value<bool> onFastBrain = const Value.absent(),
                Value<int> repetitionFastBrainStep = const Value.absent(),
                Value<int?> repetitionFastBrainDate = const Value.absent(),
                Value<bool> markedAsKnown = const Value.absent(),
                Value<bool> deletedByUser = const Value.absent(),
              }) => LearningProgressModelsCompanion(
                id: id,
                creationDate: creationDate,
                trainingProgress: trainingProgress,
                trainingError: trainingError,
                repetitionStep: repetitionStep,
                repetitionDate: repetitionDate,
                learnedDate: learnedDate,
                onFastBrain: onFastBrain,
                repetitionFastBrainStep: repetitionFastBrainStep,
                repetitionFastBrainDate: repetitionFastBrainDate,
                markedAsKnown: markedAsKnown,
                deletedByUser: deletedByUser,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int creationDate,
                Value<int> trainingProgress = const Value.absent(),
                Value<int> trainingError = const Value.absent(),
                Value<int> repetitionStep = const Value.absent(),
                Value<int?> repetitionDate = const Value.absent(),
                Value<int?> learnedDate = const Value.absent(),
                Value<bool> onFastBrain = const Value.absent(),
                Value<int> repetitionFastBrainStep = const Value.absent(),
                Value<int?> repetitionFastBrainDate = const Value.absent(),
                Value<bool> markedAsKnown = const Value.absent(),
                Value<bool> deletedByUser = const Value.absent(),
              }) => LearningProgressModelsCompanion.insert(
                id: id,
                creationDate: creationDate,
                trainingProgress: trainingProgress,
                trainingError: trainingError,
                repetitionStep: repetitionStep,
                repetitionDate: repetitionDate,
                learnedDate: learnedDate,
                onFastBrain: onFastBrain,
                repetitionFastBrainStep: repetitionFastBrainStep,
                repetitionFastBrainDate: repetitionFastBrainDate,
                markedAsKnown: markedAsKnown,
                deletedByUser: deletedByUser,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningProgressModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningProgressModelsTable,
      LearningProgressRow,
      $$LearningProgressModelsTableFilterComposer,
      $$LearningProgressModelsTableOrderingComposer,
      $$LearningProgressModelsTableAnnotationComposer,
      $$LearningProgressModelsTableCreateCompanionBuilder,
      $$LearningProgressModelsTableUpdateCompanionBuilder,
      (
        LearningProgressRow,
        BaseReferences<
          _$AppDatabase,
          $LearningProgressModelsTable,
          LearningProgressRow
        >,
      ),
      LearningProgressRow,
      PrefetchHooks Function()
    >;
typedef $$WordSentenceProgressModelsTableCreateCompanionBuilder =
    WordSentenceProgressModelsCompanion Function({
      Value<int> wordId,
      Value<int> finishedCount,
    });
typedef $$WordSentenceProgressModelsTableUpdateCompanionBuilder =
    WordSentenceProgressModelsCompanion Function({
      Value<int> wordId,
      Value<int> finishedCount,
    });

class $$WordSentenceProgressModelsTableFilterComposer
    extends Composer<_$AppDatabase, $WordSentenceProgressModelsTable> {
  $$WordSentenceProgressModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedCount => $composableBuilder(
    column: $table.finishedCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordSentenceProgressModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordSentenceProgressModelsTable> {
  $$WordSentenceProgressModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedCount => $composableBuilder(
    column: $table.finishedCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordSentenceProgressModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordSentenceProgressModelsTable> {
  $$WordSentenceProgressModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get finishedCount => $composableBuilder(
    column: $table.finishedCount,
    builder: (column) => column,
  );
}

class $$WordSentenceProgressModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordSentenceProgressModelsTable,
          WordSentenceProgressRow,
          $$WordSentenceProgressModelsTableFilterComposer,
          $$WordSentenceProgressModelsTableOrderingComposer,
          $$WordSentenceProgressModelsTableAnnotationComposer,
          $$WordSentenceProgressModelsTableCreateCompanionBuilder,
          $$WordSentenceProgressModelsTableUpdateCompanionBuilder,
          (
            WordSentenceProgressRow,
            BaseReferences<
              _$AppDatabase,
              $WordSentenceProgressModelsTable,
              WordSentenceProgressRow
            >,
          ),
          WordSentenceProgressRow,
          PrefetchHooks Function()
        > {
  $$WordSentenceProgressModelsTableTableManager(
    _$AppDatabase db,
    $WordSentenceProgressModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordSentenceProgressModelsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WordSentenceProgressModelsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WordSentenceProgressModelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<int> finishedCount = const Value.absent(),
              }) => WordSentenceProgressModelsCompanion(
                wordId: wordId,
                finishedCount: finishedCount,
              ),
          createCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<int> finishedCount = const Value.absent(),
              }) => WordSentenceProgressModelsCompanion.insert(
                wordId: wordId,
                finishedCount: finishedCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordSentenceProgressModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordSentenceProgressModelsTable,
      WordSentenceProgressRow,
      $$WordSentenceProgressModelsTableFilterComposer,
      $$WordSentenceProgressModelsTableOrderingComposer,
      $$WordSentenceProgressModelsTableAnnotationComposer,
      $$WordSentenceProgressModelsTableCreateCompanionBuilder,
      $$WordSentenceProgressModelsTableUpdateCompanionBuilder,
      (
        WordSentenceProgressRow,
        BaseReferences<
          _$AppDatabase,
          $WordSentenceProgressModelsTable,
          WordSentenceProgressRow
        >,
      ),
      WordSentenceProgressRow,
      PrefetchHooks Function()
    >;
typedef $$SentenceExposureModelsTableCreateCompanionBuilder =
    SentenceExposureModelsCompanion Function({
      Value<int> sentenceId,
      required int wordId,
      Value<int> finishedCount,
      Value<int> insertWordTask,
      Value<int> constructorTask,
      Value<int> constructorAudioTask,
      Value<int> constructorInverseTask,
    });
typedef $$SentenceExposureModelsTableUpdateCompanionBuilder =
    SentenceExposureModelsCompanion Function({
      Value<int> sentenceId,
      Value<int> wordId,
      Value<int> finishedCount,
      Value<int> insertWordTask,
      Value<int> constructorTask,
      Value<int> constructorAudioTask,
      Value<int> constructorInverseTask,
    });

class $$SentenceExposureModelsTableFilterComposer
    extends Composer<_$AppDatabase, $SentenceExposureModelsTable> {
  $$SentenceExposureModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedCount => $composableBuilder(
    column: $table.finishedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get insertWordTask => $composableBuilder(
    column: $table.insertWordTask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get constructorTask => $composableBuilder(
    column: $table.constructorTask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get constructorAudioTask => $composableBuilder(
    column: $table.constructorAudioTask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get constructorInverseTask => $composableBuilder(
    column: $table.constructorInverseTask,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SentenceExposureModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $SentenceExposureModelsTable> {
  $$SentenceExposureModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedCount => $composableBuilder(
    column: $table.finishedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get insertWordTask => $composableBuilder(
    column: $table.insertWordTask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get constructorTask => $composableBuilder(
    column: $table.constructorTask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get constructorAudioTask => $composableBuilder(
    column: $table.constructorAudioTask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get constructorInverseTask => $composableBuilder(
    column: $table.constructorInverseTask,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SentenceExposureModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SentenceExposureModelsTable> {
  $$SentenceExposureModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sentenceId => $composableBuilder(
    column: $table.sentenceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get finishedCount => $composableBuilder(
    column: $table.finishedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get insertWordTask => $composableBuilder(
    column: $table.insertWordTask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get constructorTask => $composableBuilder(
    column: $table.constructorTask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get constructorAudioTask => $composableBuilder(
    column: $table.constructorAudioTask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get constructorInverseTask => $composableBuilder(
    column: $table.constructorInverseTask,
    builder: (column) => column,
  );
}

class $$SentenceExposureModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SentenceExposureModelsTable,
          SentenceExposureRow,
          $$SentenceExposureModelsTableFilterComposer,
          $$SentenceExposureModelsTableOrderingComposer,
          $$SentenceExposureModelsTableAnnotationComposer,
          $$SentenceExposureModelsTableCreateCompanionBuilder,
          $$SentenceExposureModelsTableUpdateCompanionBuilder,
          (
            SentenceExposureRow,
            BaseReferences<
              _$AppDatabase,
              $SentenceExposureModelsTable,
              SentenceExposureRow
            >,
          ),
          SentenceExposureRow,
          PrefetchHooks Function()
        > {
  $$SentenceExposureModelsTableTableManager(
    _$AppDatabase db,
    $SentenceExposureModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SentenceExposureModelsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SentenceExposureModelsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SentenceExposureModelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> sentenceId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> finishedCount = const Value.absent(),
                Value<int> insertWordTask = const Value.absent(),
                Value<int> constructorTask = const Value.absent(),
                Value<int> constructorAudioTask = const Value.absent(),
                Value<int> constructorInverseTask = const Value.absent(),
              }) => SentenceExposureModelsCompanion(
                sentenceId: sentenceId,
                wordId: wordId,
                finishedCount: finishedCount,
                insertWordTask: insertWordTask,
                constructorTask: constructorTask,
                constructorAudioTask: constructorAudioTask,
                constructorInverseTask: constructorInverseTask,
              ),
          createCompanionCallback:
              ({
                Value<int> sentenceId = const Value.absent(),
                required int wordId,
                Value<int> finishedCount = const Value.absent(),
                Value<int> insertWordTask = const Value.absent(),
                Value<int> constructorTask = const Value.absent(),
                Value<int> constructorAudioTask = const Value.absent(),
                Value<int> constructorInverseTask = const Value.absent(),
              }) => SentenceExposureModelsCompanion.insert(
                sentenceId: sentenceId,
                wordId: wordId,
                finishedCount: finishedCount,
                insertWordTask: insertWordTask,
                constructorTask: constructorTask,
                constructorAudioTask: constructorAudioTask,
                constructorInverseTask: constructorInverseTask,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SentenceExposureModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SentenceExposureModelsTable,
      SentenceExposureRow,
      $$SentenceExposureModelsTableFilterComposer,
      $$SentenceExposureModelsTableOrderingComposer,
      $$SentenceExposureModelsTableAnnotationComposer,
      $$SentenceExposureModelsTableCreateCompanionBuilder,
      $$SentenceExposureModelsTableUpdateCompanionBuilder,
      (
        SentenceExposureRow,
        BaseReferences<
          _$AppDatabase,
          $SentenceExposureModelsTable,
          SentenceExposureRow
        >,
      ),
      SentenceExposureRow,
      PrefetchHooks Function()
    >;
typedef $$LearningSessionsTableCreateCompanionBuilder =
    LearningSessionsCompanion Function({
      required String id,
      Value<int?> topicId,
      Value<int> status,
      required int requiredMask,
      required int originalExerciseCount,
      Value<int> currentIndex,
      required int startedAt,
      Value<int?> completedAt,
      Value<int?> completionAppliedAt,
      Value<int> successfulWordCount,
      Value<int> unresolvedWrongWordCount,
      Value<int> completedWordCount,
      Value<int> newlyLearnedWordCount,
      Value<int> rowid,
    });
typedef $$LearningSessionsTableUpdateCompanionBuilder =
    LearningSessionsCompanion Function({
      Value<String> id,
      Value<int?> topicId,
      Value<int> status,
      Value<int> requiredMask,
      Value<int> originalExerciseCount,
      Value<int> currentIndex,
      Value<int> startedAt,
      Value<int?> completedAt,
      Value<int?> completionAppliedAt,
      Value<int> successfulWordCount,
      Value<int> unresolvedWrongWordCount,
      Value<int> completedWordCount,
      Value<int> newlyLearnedWordCount,
      Value<int> rowid,
    });

class $$LearningSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LearningSessionsTable> {
  $$LearningSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requiredMask => $composableBuilder(
    column: $table.requiredMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalExerciseCount => $composableBuilder(
    column: $table.originalExerciseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completionAppliedAt => $composableBuilder(
    column: $table.completionAppliedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get successfulWordCount => $composableBuilder(
    column: $table.successfulWordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unresolvedWrongWordCount => $composableBuilder(
    column: $table.unresolvedWrongWordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedWordCount => $composableBuilder(
    column: $table.completedWordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newlyLearnedWordCount => $composableBuilder(
    column: $table.newlyLearnedWordCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningSessionsTable> {
  $$LearningSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requiredMask => $composableBuilder(
    column: $table.requiredMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalExerciseCount => $composableBuilder(
    column: $table.originalExerciseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completionAppliedAt => $composableBuilder(
    column: $table.completionAppliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get successfulWordCount => $composableBuilder(
    column: $table.successfulWordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unresolvedWrongWordCount => $composableBuilder(
    column: $table.unresolvedWrongWordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedWordCount => $composableBuilder(
    column: $table.completedWordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newlyLearnedWordCount => $composableBuilder(
    column: $table.newlyLearnedWordCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningSessionsTable> {
  $$LearningSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get requiredMask => $composableBuilder(
    column: $table.requiredMask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalExerciseCount => $composableBuilder(
    column: $table.originalExerciseCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completionAppliedAt => $composableBuilder(
    column: $table.completionAppliedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get successfulWordCount => $composableBuilder(
    column: $table.successfulWordCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unresolvedWrongWordCount => $composableBuilder(
    column: $table.unresolvedWrongWordCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedWordCount => $composableBuilder(
    column: $table.completedWordCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newlyLearnedWordCount => $composableBuilder(
    column: $table.newlyLearnedWordCount,
    builder: (column) => column,
  );
}

class $$LearningSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningSessionsTable,
          LearningSession,
          $$LearningSessionsTableFilterComposer,
          $$LearningSessionsTableOrderingComposer,
          $$LearningSessionsTableAnnotationComposer,
          $$LearningSessionsTableCreateCompanionBuilder,
          $$LearningSessionsTableUpdateCompanionBuilder,
          (
            LearningSession,
            BaseReferences<
              _$AppDatabase,
              $LearningSessionsTable,
              LearningSession
            >,
          ),
          LearningSession,
          PrefetchHooks Function()
        > {
  $$LearningSessionsTableTableManager(
    _$AppDatabase db,
    $LearningSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int?> topicId = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> requiredMask = const Value.absent(),
                Value<int> originalExerciseCount = const Value.absent(),
                Value<int> currentIndex = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> completionAppliedAt = const Value.absent(),
                Value<int> successfulWordCount = const Value.absent(),
                Value<int> unresolvedWrongWordCount = const Value.absent(),
                Value<int> completedWordCount = const Value.absent(),
                Value<int> newlyLearnedWordCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningSessionsCompanion(
                id: id,
                topicId: topicId,
                status: status,
                requiredMask: requiredMask,
                originalExerciseCount: originalExerciseCount,
                currentIndex: currentIndex,
                startedAt: startedAt,
                completedAt: completedAt,
                completionAppliedAt: completionAppliedAt,
                successfulWordCount: successfulWordCount,
                unresolvedWrongWordCount: unresolvedWrongWordCount,
                completedWordCount: completedWordCount,
                newlyLearnedWordCount: newlyLearnedWordCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int?> topicId = const Value.absent(),
                Value<int> status = const Value.absent(),
                required int requiredMask,
                required int originalExerciseCount,
                Value<int> currentIndex = const Value.absent(),
                required int startedAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int?> completionAppliedAt = const Value.absent(),
                Value<int> successfulWordCount = const Value.absent(),
                Value<int> unresolvedWrongWordCount = const Value.absent(),
                Value<int> completedWordCount = const Value.absent(),
                Value<int> newlyLearnedWordCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningSessionsCompanion.insert(
                id: id,
                topicId: topicId,
                status: status,
                requiredMask: requiredMask,
                originalExerciseCount: originalExerciseCount,
                currentIndex: currentIndex,
                startedAt: startedAt,
                completedAt: completedAt,
                completionAppliedAt: completionAppliedAt,
                successfulWordCount: successfulWordCount,
                unresolvedWrongWordCount: unresolvedWrongWordCount,
                completedWordCount: completedWordCount,
                newlyLearnedWordCount: newlyLearnedWordCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningSessionsTable,
      LearningSession,
      $$LearningSessionsTableFilterComposer,
      $$LearningSessionsTableOrderingComposer,
      $$LearningSessionsTableAnnotationComposer,
      $$LearningSessionsTableCreateCompanionBuilder,
      $$LearningSessionsTableUpdateCompanionBuilder,
      (
        LearningSession,
        BaseReferences<_$AppDatabase, $LearningSessionsTable, LearningSession>,
      ),
      LearningSession,
      PrefetchHooks Function()
    >;
typedef $$SessionExercisesTableCreateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<int> id,
      required String sessionId,
      required int wordId,
      required int exerciseType,
      required int orderIndex,
      Value<bool> isRetry,
      Value<int?> parentExerciseId,
      Value<int> answer,
      Value<int?> answeredAt,
    });
typedef $$SessionExercisesTableUpdateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<int> wordId,
      Value<int> exerciseType,
      Value<int> orderIndex,
      Value<bool> isRetry,
      Value<int?> parentExerciseId,
      Value<int> answer,
      Value<int?> answeredAt,
    });

class $$SessionExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRetry => $composableBuilder(
    column: $table.isRetry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parentExerciseId => $composableBuilder(
    column: $table.parentExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRetry => $composableBuilder(
    column: $table.isRetry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parentExerciseId => $composableBuilder(
    column: $table.parentExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get exerciseType => $composableBuilder(
    column: $table.exerciseType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRetry =>
      $composableBuilder(column: $table.isRetry, builder: (column) => column);

  GeneratedColumn<int> get parentExerciseId => $composableBuilder(
    column: $table.parentExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<int> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );
}

class $$SessionExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionExercisesTable,
          SessionExercise,
          $$SessionExercisesTableFilterComposer,
          $$SessionExercisesTableOrderingComposer,
          $$SessionExercisesTableAnnotationComposer,
          $$SessionExercisesTableCreateCompanionBuilder,
          $$SessionExercisesTableUpdateCompanionBuilder,
          (
            SessionExercise,
            BaseReferences<
              _$AppDatabase,
              $SessionExercisesTable,
              SessionExercise
            >,
          ),
          SessionExercise,
          PrefetchHooks Function()
        > {
  $$SessionExercisesTableTableManager(
    _$AppDatabase db,
    $SessionExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> exerciseType = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isRetry = const Value.absent(),
                Value<int?> parentExerciseId = const Value.absent(),
                Value<int> answer = const Value.absent(),
                Value<int?> answeredAt = const Value.absent(),
              }) => SessionExercisesCompanion(
                id: id,
                sessionId: sessionId,
                wordId: wordId,
                exerciseType: exerciseType,
                orderIndex: orderIndex,
                isRetry: isRetry,
                parentExerciseId: parentExerciseId,
                answer: answer,
                answeredAt: answeredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required int wordId,
                required int exerciseType,
                required int orderIndex,
                Value<bool> isRetry = const Value.absent(),
                Value<int?> parentExerciseId = const Value.absent(),
                Value<int> answer = const Value.absent(),
                Value<int?> answeredAt = const Value.absent(),
              }) => SessionExercisesCompanion.insert(
                id: id,
                sessionId: sessionId,
                wordId: wordId,
                exerciseType: exerciseType,
                orderIndex: orderIndex,
                isRetry: isRetry,
                parentExerciseId: parentExerciseId,
                answer: answer,
                answeredAt: answeredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionExercisesTable,
      SessionExercise,
      $$SessionExercisesTableFilterComposer,
      $$SessionExercisesTableOrderingComposer,
      $$SessionExercisesTableAnnotationComposer,
      $$SessionExercisesTableCreateCompanionBuilder,
      $$SessionExercisesTableUpdateCompanionBuilder,
      (
        SessionExercise,
        BaseReferences<_$AppDatabase, $SessionExercisesTable, SessionExercise>,
      ),
      SessionExercise,
      PrefetchHooks Function()
    >;
typedef $$SimilarWordModelsTableCreateCompanionBuilder =
    SimilarWordModelsCompanion Function({
      Value<int> id,
      required String options,
    });
typedef $$SimilarWordModelsTableUpdateCompanionBuilder =
    SimilarWordModelsCompanion Function({Value<int> id, Value<String> options});

class $$SimilarWordModelsTableFilterComposer
    extends Composer<_$AppDatabase, $SimilarWordModelsTable> {
  $$SimilarWordModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SimilarWordModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $SimilarWordModelsTable> {
  $$SimilarWordModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SimilarWordModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SimilarWordModelsTable> {
  $$SimilarWordModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);
}

class $$SimilarWordModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SimilarWordModelsTable,
          SimilarWordRow,
          $$SimilarWordModelsTableFilterComposer,
          $$SimilarWordModelsTableOrderingComposer,
          $$SimilarWordModelsTableAnnotationComposer,
          $$SimilarWordModelsTableCreateCompanionBuilder,
          $$SimilarWordModelsTableUpdateCompanionBuilder,
          (
            SimilarWordRow,
            BaseReferences<
              _$AppDatabase,
              $SimilarWordModelsTable,
              SimilarWordRow
            >,
          ),
          SimilarWordRow,
          PrefetchHooks Function()
        > {
  $$SimilarWordModelsTableTableManager(
    _$AppDatabase db,
    $SimilarWordModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SimilarWordModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SimilarWordModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SimilarWordModelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> options = const Value.absent(),
              }) => SimilarWordModelsCompanion(id: id, options: options),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String options,
              }) => SimilarWordModelsCompanion.insert(id: id, options: options),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SimilarWordModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SimilarWordModelsTable,
      SimilarWordRow,
      $$SimilarWordModelsTableFilterComposer,
      $$SimilarWordModelsTableOrderingComposer,
      $$SimilarWordModelsTableAnnotationComposer,
      $$SimilarWordModelsTableCreateCompanionBuilder,
      $$SimilarWordModelsTableUpdateCompanionBuilder,
      (
        SimilarWordRow,
        BaseReferences<_$AppDatabase, $SimilarWordModelsTable, SimilarWordRow>,
      ),
      SimilarWordRow,
      PrefetchHooks Function()
    >;
typedef $$SttMisspellingModelsTableCreateCompanionBuilder =
    SttMisspellingModelsCompanion Function({
      Value<int> id,
      required String misspellings,
    });
typedef $$SttMisspellingModelsTableUpdateCompanionBuilder =
    SttMisspellingModelsCompanion Function({
      Value<int> id,
      Value<String> misspellings,
    });

class $$SttMisspellingModelsTableFilterComposer
    extends Composer<_$AppDatabase, $SttMisspellingModelsTable> {
  $$SttMisspellingModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get misspellings => $composableBuilder(
    column: $table.misspellings,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SttMisspellingModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $SttMisspellingModelsTable> {
  $$SttMisspellingModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get misspellings => $composableBuilder(
    column: $table.misspellings,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SttMisspellingModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SttMisspellingModelsTable> {
  $$SttMisspellingModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get misspellings => $composableBuilder(
    column: $table.misspellings,
    builder: (column) => column,
  );
}

class $$SttMisspellingModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SttMisspellingModelsTable,
          SttMisspellingRow,
          $$SttMisspellingModelsTableFilterComposer,
          $$SttMisspellingModelsTableOrderingComposer,
          $$SttMisspellingModelsTableAnnotationComposer,
          $$SttMisspellingModelsTableCreateCompanionBuilder,
          $$SttMisspellingModelsTableUpdateCompanionBuilder,
          (
            SttMisspellingRow,
            BaseReferences<
              _$AppDatabase,
              $SttMisspellingModelsTable,
              SttMisspellingRow
            >,
          ),
          SttMisspellingRow,
          PrefetchHooks Function()
        > {
  $$SttMisspellingModelsTableTableManager(
    _$AppDatabase db,
    $SttMisspellingModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SttMisspellingModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SttMisspellingModelsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SttMisspellingModelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> misspellings = const Value.absent(),
              }) => SttMisspellingModelsCompanion(
                id: id,
                misspellings: misspellings,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String misspellings,
              }) => SttMisspellingModelsCompanion.insert(
                id: id,
                misspellings: misspellings,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SttMisspellingModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SttMisspellingModelsTable,
      SttMisspellingRow,
      $$SttMisspellingModelsTableFilterComposer,
      $$SttMisspellingModelsTableOrderingComposer,
      $$SttMisspellingModelsTableAnnotationComposer,
      $$SttMisspellingModelsTableCreateCompanionBuilder,
      $$SttMisspellingModelsTableUpdateCompanionBuilder,
      (
        SttMisspellingRow,
        BaseReferences<
          _$AppDatabase,
          $SttMisspellingModelsTable,
          SttMisspellingRow
        >,
      ),
      SttMisspellingRow,
      PrefetchHooks Function()
    >;
typedef $$LetterModelsTableCreateCompanionBuilder =
    LetterModelsCompanion Function({
      Value<int> id,
      Value<String?> writing,
      Value<String?> transcription,
      Value<int?> alphabetOrder,
      Value<int?> educationOrder,
      Value<String?> audioFilename,
      Value<String?> digitValue,
      required String type,
      required String variations,
      required String vowels,
    });
typedef $$LetterModelsTableUpdateCompanionBuilder =
    LetterModelsCompanion Function({
      Value<int> id,
      Value<String?> writing,
      Value<String?> transcription,
      Value<int?> alphabetOrder,
      Value<int?> educationOrder,
      Value<String?> audioFilename,
      Value<String?> digitValue,
      Value<String> type,
      Value<String> variations,
      Value<String> vowels,
    });

class $$LetterModelsTableFilterComposer
    extends Composer<_$AppDatabase, $LetterModelsTable> {
  $$LetterModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get writing => $composableBuilder(
    column: $table.writing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get alphabetOrder => $composableBuilder(
    column: $table.alphabetOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get educationOrder => $composableBuilder(
    column: $table.educationOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioFilename => $composableBuilder(
    column: $table.audioFilename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get digitValue => $composableBuilder(
    column: $table.digitValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variations => $composableBuilder(
    column: $table.variations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vowels => $composableBuilder(
    column: $table.vowels,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LetterModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $LetterModelsTable> {
  $$LetterModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get writing => $composableBuilder(
    column: $table.writing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get alphabetOrder => $composableBuilder(
    column: $table.alphabetOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get educationOrder => $composableBuilder(
    column: $table.educationOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioFilename => $composableBuilder(
    column: $table.audioFilename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get digitValue => $composableBuilder(
    column: $table.digitValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variations => $composableBuilder(
    column: $table.variations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vowels => $composableBuilder(
    column: $table.vowels,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LetterModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LetterModelsTable> {
  $$LetterModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get writing =>
      $composableBuilder(column: $table.writing, builder: (column) => column);

  GeneratedColumn<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => column,
  );

  GeneratedColumn<int> get alphabetOrder => $composableBuilder(
    column: $table.alphabetOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get educationOrder => $composableBuilder(
    column: $table.educationOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioFilename => $composableBuilder(
    column: $table.audioFilename,
    builder: (column) => column,
  );

  GeneratedColumn<String> get digitValue => $composableBuilder(
    column: $table.digitValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get variations => $composableBuilder(
    column: $table.variations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vowels =>
      $composableBuilder(column: $table.vowels, builder: (column) => column);
}

class $$LetterModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LetterModelsTable,
          LetterRow,
          $$LetterModelsTableFilterComposer,
          $$LetterModelsTableOrderingComposer,
          $$LetterModelsTableAnnotationComposer,
          $$LetterModelsTableCreateCompanionBuilder,
          $$LetterModelsTableUpdateCompanionBuilder,
          (
            LetterRow,
            BaseReferences<_$AppDatabase, $LetterModelsTable, LetterRow>,
          ),
          LetterRow,
          PrefetchHooks Function()
        > {
  $$LetterModelsTableTableManager(_$AppDatabase db, $LetterModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LetterModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LetterModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LetterModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> writing = const Value.absent(),
                Value<String?> transcription = const Value.absent(),
                Value<int?> alphabetOrder = const Value.absent(),
                Value<int?> educationOrder = const Value.absent(),
                Value<String?> audioFilename = const Value.absent(),
                Value<String?> digitValue = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> variations = const Value.absent(),
                Value<String> vowels = const Value.absent(),
              }) => LetterModelsCompanion(
                id: id,
                writing: writing,
                transcription: transcription,
                alphabetOrder: alphabetOrder,
                educationOrder: educationOrder,
                audioFilename: audioFilename,
                digitValue: digitValue,
                type: type,
                variations: variations,
                vowels: vowels,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> writing = const Value.absent(),
                Value<String?> transcription = const Value.absent(),
                Value<int?> alphabetOrder = const Value.absent(),
                Value<int?> educationOrder = const Value.absent(),
                Value<String?> audioFilename = const Value.absent(),
                Value<String?> digitValue = const Value.absent(),
                required String type,
                required String variations,
                required String vowels,
              }) => LetterModelsCompanion.insert(
                id: id,
                writing: writing,
                transcription: transcription,
                alphabetOrder: alphabetOrder,
                educationOrder: educationOrder,
                audioFilename: audioFilename,
                digitValue: digitValue,
                type: type,
                variations: variations,
                vowels: vowels,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LetterModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LetterModelsTable,
      LetterRow,
      $$LetterModelsTableFilterComposer,
      $$LetterModelsTableOrderingComposer,
      $$LetterModelsTableAnnotationComposer,
      $$LetterModelsTableCreateCompanionBuilder,
      $$LetterModelsTableUpdateCompanionBuilder,
      (LetterRow, BaseReferences<_$AppDatabase, $LetterModelsTable, LetterRow>),
      LetterRow,
      PrefetchHooks Function()
    >;
typedef $$VisitModelsTableCreateCompanionBuilder =
    VisitModelsCompanion Function({
      Value<int> id,
      required int date,
      Value<bool> areDailyTasksFinished,
      Value<bool> atLeastOneTaskFinished,
      Value<int> repeatWordsGoal,
      Value<int> learnWordsGoal,
      Value<int> trainWordsGoal,
      Value<int> difficultWordsGoal,
      Value<int> wordsInSentencesGoal,
      Value<int> repeatedWordsCount,
      Value<int> learnedWordsCount,
      Value<int> trainedWordsCount,
      Value<int> difficultWordsTrainedCount,
      Value<int> wordsInSentencesCount,
      Value<int> sentencesTrainedCount,
      Value<int> sentencesTrainedExtraCount,
      Value<int> problemWordsHealedCount,
      Value<int> learningsWithoutMistakes,
      Value<int> learnedWordsWithoutMistakes,
    });
typedef $$VisitModelsTableUpdateCompanionBuilder =
    VisitModelsCompanion Function({
      Value<int> id,
      Value<int> date,
      Value<bool> areDailyTasksFinished,
      Value<bool> atLeastOneTaskFinished,
      Value<int> repeatWordsGoal,
      Value<int> learnWordsGoal,
      Value<int> trainWordsGoal,
      Value<int> difficultWordsGoal,
      Value<int> wordsInSentencesGoal,
      Value<int> repeatedWordsCount,
      Value<int> learnedWordsCount,
      Value<int> trainedWordsCount,
      Value<int> difficultWordsTrainedCount,
      Value<int> wordsInSentencesCount,
      Value<int> sentencesTrainedCount,
      Value<int> sentencesTrainedExtraCount,
      Value<int> problemWordsHealedCount,
      Value<int> learningsWithoutMistakes,
      Value<int> learnedWordsWithoutMistakes,
    });

class $$VisitModelsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitModelsTable> {
  $$VisitModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get areDailyTasksFinished => $composableBuilder(
    column: $table.areDailyTasksFinished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get atLeastOneTaskFinished => $composableBuilder(
    column: $table.atLeastOneTaskFinished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatWordsGoal => $composableBuilder(
    column: $table.repeatWordsGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnWordsGoal => $composableBuilder(
    column: $table.learnWordsGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trainWordsGoal => $composableBuilder(
    column: $table.trainWordsGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficultWordsGoal => $composableBuilder(
    column: $table.difficultWordsGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordsInSentencesGoal => $composableBuilder(
    column: $table.wordsInSentencesGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatedWordsCount => $composableBuilder(
    column: $table.repeatedWordsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnedWordsCount => $composableBuilder(
    column: $table.learnedWordsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trainedWordsCount => $composableBuilder(
    column: $table.trainedWordsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficultWordsTrainedCount => $composableBuilder(
    column: $table.difficultWordsTrainedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordsInSentencesCount => $composableBuilder(
    column: $table.wordsInSentencesCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentencesTrainedCount => $composableBuilder(
    column: $table.sentencesTrainedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentencesTrainedExtraCount => $composableBuilder(
    column: $table.sentencesTrainedExtraCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get problemWordsHealedCount => $composableBuilder(
    column: $table.problemWordsHealedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learningsWithoutMistakes => $composableBuilder(
    column: $table.learningsWithoutMistakes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnedWordsWithoutMistakes => $composableBuilder(
    column: $table.learnedWordsWithoutMistakes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VisitModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitModelsTable> {
  $$VisitModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get areDailyTasksFinished => $composableBuilder(
    column: $table.areDailyTasksFinished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get atLeastOneTaskFinished => $composableBuilder(
    column: $table.atLeastOneTaskFinished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatWordsGoal => $composableBuilder(
    column: $table.repeatWordsGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnWordsGoal => $composableBuilder(
    column: $table.learnWordsGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trainWordsGoal => $composableBuilder(
    column: $table.trainWordsGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficultWordsGoal => $composableBuilder(
    column: $table.difficultWordsGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordsInSentencesGoal => $composableBuilder(
    column: $table.wordsInSentencesGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatedWordsCount => $composableBuilder(
    column: $table.repeatedWordsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnedWordsCount => $composableBuilder(
    column: $table.learnedWordsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trainedWordsCount => $composableBuilder(
    column: $table.trainedWordsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficultWordsTrainedCount => $composableBuilder(
    column: $table.difficultWordsTrainedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordsInSentencesCount => $composableBuilder(
    column: $table.wordsInSentencesCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentencesTrainedCount => $composableBuilder(
    column: $table.sentencesTrainedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentencesTrainedExtraCount => $composableBuilder(
    column: $table.sentencesTrainedExtraCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get problemWordsHealedCount => $composableBuilder(
    column: $table.problemWordsHealedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learningsWithoutMistakes => $composableBuilder(
    column: $table.learningsWithoutMistakes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnedWordsWithoutMistakes => $composableBuilder(
    column: $table.learnedWordsWithoutMistakes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VisitModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitModelsTable> {
  $$VisitModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get areDailyTasksFinished => $composableBuilder(
    column: $table.areDailyTasksFinished,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get atLeastOneTaskFinished => $composableBuilder(
    column: $table.atLeastOneTaskFinished,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repeatWordsGoal => $composableBuilder(
    column: $table.repeatWordsGoal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnWordsGoal => $composableBuilder(
    column: $table.learnWordsGoal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trainWordsGoal => $composableBuilder(
    column: $table.trainWordsGoal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get difficultWordsGoal => $composableBuilder(
    column: $table.difficultWordsGoal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordsInSentencesGoal => $composableBuilder(
    column: $table.wordsInSentencesGoal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repeatedWordsCount => $composableBuilder(
    column: $table.repeatedWordsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnedWordsCount => $composableBuilder(
    column: $table.learnedWordsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trainedWordsCount => $composableBuilder(
    column: $table.trainedWordsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get difficultWordsTrainedCount => $composableBuilder(
    column: $table.difficultWordsTrainedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordsInSentencesCount => $composableBuilder(
    column: $table.wordsInSentencesCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sentencesTrainedCount => $composableBuilder(
    column: $table.sentencesTrainedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sentencesTrainedExtraCount => $composableBuilder(
    column: $table.sentencesTrainedExtraCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get problemWordsHealedCount => $composableBuilder(
    column: $table.problemWordsHealedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learningsWithoutMistakes => $composableBuilder(
    column: $table.learningsWithoutMistakes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnedWordsWithoutMistakes => $composableBuilder(
    column: $table.learnedWordsWithoutMistakes,
    builder: (column) => column,
  );
}

class $$VisitModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitModelsTable,
          VisitRow,
          $$VisitModelsTableFilterComposer,
          $$VisitModelsTableOrderingComposer,
          $$VisitModelsTableAnnotationComposer,
          $$VisitModelsTableCreateCompanionBuilder,
          $$VisitModelsTableUpdateCompanionBuilder,
          (
            VisitRow,
            BaseReferences<_$AppDatabase, $VisitModelsTable, VisitRow>,
          ),
          VisitRow,
          PrefetchHooks Function()
        > {
  $$VisitModelsTableTableManager(_$AppDatabase db, $VisitModelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitModelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitModelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitModelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<bool> areDailyTasksFinished = const Value.absent(),
                Value<bool> atLeastOneTaskFinished = const Value.absent(),
                Value<int> repeatWordsGoal = const Value.absent(),
                Value<int> learnWordsGoal = const Value.absent(),
                Value<int> trainWordsGoal = const Value.absent(),
                Value<int> difficultWordsGoal = const Value.absent(),
                Value<int> wordsInSentencesGoal = const Value.absent(),
                Value<int> repeatedWordsCount = const Value.absent(),
                Value<int> learnedWordsCount = const Value.absent(),
                Value<int> trainedWordsCount = const Value.absent(),
                Value<int> difficultWordsTrainedCount = const Value.absent(),
                Value<int> wordsInSentencesCount = const Value.absent(),
                Value<int> sentencesTrainedCount = const Value.absent(),
                Value<int> sentencesTrainedExtraCount = const Value.absent(),
                Value<int> problemWordsHealedCount = const Value.absent(),
                Value<int> learningsWithoutMistakes = const Value.absent(),
                Value<int> learnedWordsWithoutMistakes = const Value.absent(),
              }) => VisitModelsCompanion(
                id: id,
                date: date,
                areDailyTasksFinished: areDailyTasksFinished,
                atLeastOneTaskFinished: atLeastOneTaskFinished,
                repeatWordsGoal: repeatWordsGoal,
                learnWordsGoal: learnWordsGoal,
                trainWordsGoal: trainWordsGoal,
                difficultWordsGoal: difficultWordsGoal,
                wordsInSentencesGoal: wordsInSentencesGoal,
                repeatedWordsCount: repeatedWordsCount,
                learnedWordsCount: learnedWordsCount,
                trainedWordsCount: trainedWordsCount,
                difficultWordsTrainedCount: difficultWordsTrainedCount,
                wordsInSentencesCount: wordsInSentencesCount,
                sentencesTrainedCount: sentencesTrainedCount,
                sentencesTrainedExtraCount: sentencesTrainedExtraCount,
                problemWordsHealedCount: problemWordsHealedCount,
                learningsWithoutMistakes: learningsWithoutMistakes,
                learnedWordsWithoutMistakes: learnedWordsWithoutMistakes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int date,
                Value<bool> areDailyTasksFinished = const Value.absent(),
                Value<bool> atLeastOneTaskFinished = const Value.absent(),
                Value<int> repeatWordsGoal = const Value.absent(),
                Value<int> learnWordsGoal = const Value.absent(),
                Value<int> trainWordsGoal = const Value.absent(),
                Value<int> difficultWordsGoal = const Value.absent(),
                Value<int> wordsInSentencesGoal = const Value.absent(),
                Value<int> repeatedWordsCount = const Value.absent(),
                Value<int> learnedWordsCount = const Value.absent(),
                Value<int> trainedWordsCount = const Value.absent(),
                Value<int> difficultWordsTrainedCount = const Value.absent(),
                Value<int> wordsInSentencesCount = const Value.absent(),
                Value<int> sentencesTrainedCount = const Value.absent(),
                Value<int> sentencesTrainedExtraCount = const Value.absent(),
                Value<int> problemWordsHealedCount = const Value.absent(),
                Value<int> learningsWithoutMistakes = const Value.absent(),
                Value<int> learnedWordsWithoutMistakes = const Value.absent(),
              }) => VisitModelsCompanion.insert(
                id: id,
                date: date,
                areDailyTasksFinished: areDailyTasksFinished,
                atLeastOneTaskFinished: atLeastOneTaskFinished,
                repeatWordsGoal: repeatWordsGoal,
                learnWordsGoal: learnWordsGoal,
                trainWordsGoal: trainWordsGoal,
                difficultWordsGoal: difficultWordsGoal,
                wordsInSentencesGoal: wordsInSentencesGoal,
                repeatedWordsCount: repeatedWordsCount,
                learnedWordsCount: learnedWordsCount,
                trainedWordsCount: trainedWordsCount,
                difficultWordsTrainedCount: difficultWordsTrainedCount,
                wordsInSentencesCount: wordsInSentencesCount,
                sentencesTrainedCount: sentencesTrainedCount,
                sentencesTrainedExtraCount: sentencesTrainedExtraCount,
                problemWordsHealedCount: problemWordsHealedCount,
                learningsWithoutMistakes: learningsWithoutMistakes,
                learnedWordsWithoutMistakes: learnedWordsWithoutMistakes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VisitModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitModelsTable,
      VisitRow,
      $$VisitModelsTableFilterComposer,
      $$VisitModelsTableOrderingComposer,
      $$VisitModelsTableAnnotationComposer,
      $$VisitModelsTableCreateCompanionBuilder,
      $$VisitModelsTableUpdateCompanionBuilder,
      (VisitRow, BaseReferences<_$AppDatabase, $VisitModelsTable, VisitRow>),
      VisitRow,
      PrefetchHooks Function()
    >;
typedef $$OnboardingTestAnswerModelsTableCreateCompanionBuilder =
    OnboardingTestAnswerModelsCompanion Function({
      required String questionId,
      Value<bool?> isCorrectAnswered,
      Value<String?> answerId,
      Value<int> rowid,
    });
typedef $$OnboardingTestAnswerModelsTableUpdateCompanionBuilder =
    OnboardingTestAnswerModelsCompanion Function({
      Value<String> questionId,
      Value<bool?> isCorrectAnswered,
      Value<String?> answerId,
      Value<int> rowid,
    });

class $$OnboardingTestAnswerModelsTableFilterComposer
    extends Composer<_$AppDatabase, $OnboardingTestAnswerModelsTable> {
  $$OnboardingTestAnswerModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrectAnswered => $composableBuilder(
    column: $table.isCorrectAnswered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerId => $composableBuilder(
    column: $table.answerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OnboardingTestAnswerModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $OnboardingTestAnswerModelsTable> {
  $$OnboardingTestAnswerModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrectAnswered => $composableBuilder(
    column: $table.isCorrectAnswered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerId => $composableBuilder(
    column: $table.answerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OnboardingTestAnswerModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OnboardingTestAnswerModelsTable> {
  $$OnboardingTestAnswerModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCorrectAnswered => $composableBuilder(
    column: $table.isCorrectAnswered,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerId =>
      $composableBuilder(column: $table.answerId, builder: (column) => column);
}

class $$OnboardingTestAnswerModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OnboardingTestAnswerModelsTable,
          OnboardingTestAnswerRow,
          $$OnboardingTestAnswerModelsTableFilterComposer,
          $$OnboardingTestAnswerModelsTableOrderingComposer,
          $$OnboardingTestAnswerModelsTableAnnotationComposer,
          $$OnboardingTestAnswerModelsTableCreateCompanionBuilder,
          $$OnboardingTestAnswerModelsTableUpdateCompanionBuilder,
          (
            OnboardingTestAnswerRow,
            BaseReferences<
              _$AppDatabase,
              $OnboardingTestAnswerModelsTable,
              OnboardingTestAnswerRow
            >,
          ),
          OnboardingTestAnswerRow,
          PrefetchHooks Function()
        > {
  $$OnboardingTestAnswerModelsTableTableManager(
    _$AppDatabase db,
    $OnboardingTestAnswerModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OnboardingTestAnswerModelsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OnboardingTestAnswerModelsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OnboardingTestAnswerModelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<bool?> isCorrectAnswered = const Value.absent(),
                Value<String?> answerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OnboardingTestAnswerModelsCompanion(
                questionId: questionId,
                isCorrectAnswered: isCorrectAnswered,
                answerId: answerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                Value<bool?> isCorrectAnswered = const Value.absent(),
                Value<String?> answerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OnboardingTestAnswerModelsCompanion.insert(
                questionId: questionId,
                isCorrectAnswered: isCorrectAnswered,
                answerId: answerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OnboardingTestAnswerModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OnboardingTestAnswerModelsTable,
      OnboardingTestAnswerRow,
      $$OnboardingTestAnswerModelsTableFilterComposer,
      $$OnboardingTestAnswerModelsTableOrderingComposer,
      $$OnboardingTestAnswerModelsTableAnnotationComposer,
      $$OnboardingTestAnswerModelsTableCreateCompanionBuilder,
      $$OnboardingTestAnswerModelsTableUpdateCompanionBuilder,
      (
        OnboardingTestAnswerRow,
        BaseReferences<
          _$AppDatabase,
          $OnboardingTestAnswerModelsTable,
          OnboardingTestAnswerRow
        >,
      ),
      OnboardingTestAnswerRow,
      PrefetchHooks Function()
    >;
typedef $$ContentRevisionsTableCreateCompanionBuilder =
    ContentRevisionsCompanion Function({
      required String source,
      required int revision,
      required int syncedAt,
      Value<int> rowid,
    });
typedef $$ContentRevisionsTableUpdateCompanionBuilder =
    ContentRevisionsCompanion Function({
      Value<String> source,
      Value<int> revision,
      Value<int> syncedAt,
      Value<int> rowid,
    });

class $$ContentRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentRevisionsTable> {
  $$ContentRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentRevisionsTable> {
  $$ContentRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentRevisionsTable> {
  $$ContentRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$ContentRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentRevisionsTable,
          ContentRevisionRow,
          $$ContentRevisionsTableFilterComposer,
          $$ContentRevisionsTableOrderingComposer,
          $$ContentRevisionsTableAnnotationComposer,
          $$ContentRevisionsTableCreateCompanionBuilder,
          $$ContentRevisionsTableUpdateCompanionBuilder,
          (
            ContentRevisionRow,
            BaseReferences<
              _$AppDatabase,
              $ContentRevisionsTable,
              ContentRevisionRow
            >,
          ),
          ContentRevisionRow,
          PrefetchHooks Function()
        > {
  $$ContentRevisionsTableTableManager(
    _$AppDatabase db,
    $ContentRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> source = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentRevisionsCompanion(
                source: source,
                revision: revision,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String source,
                required int revision,
                required int syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentRevisionsCompanion.insert(
                source: source,
                revision: revision,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentRevisionsTable,
      ContentRevisionRow,
      $$ContentRevisionsTableFilterComposer,
      $$ContentRevisionsTableOrderingComposer,
      $$ContentRevisionsTableAnnotationComposer,
      $$ContentRevisionsTableCreateCompanionBuilder,
      $$ContentRevisionsTableUpdateCompanionBuilder,
      (
        ContentRevisionRow,
        BaseReferences<
          _$AppDatabase,
          $ContentRevisionsTable,
          ContentRevisionRow
        >,
      ),
      ContentRevisionRow,
      PrefetchHooks Function()
    >;
typedef $$AppUsageDaysTableCreateCompanionBuilder =
    AppUsageDaysCompanion Function({
      Value<int> date,
      Value<int> foregroundMilliseconds,
    });
typedef $$AppUsageDaysTableUpdateCompanionBuilder =
    AppUsageDaysCompanion Function({
      Value<int> date,
      Value<int> foregroundMilliseconds,
    });

class $$AppUsageDaysTableFilterComposer
    extends Composer<_$AppDatabase, $AppUsageDaysTable> {
  $$AppUsageDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foregroundMilliseconds => $composableBuilder(
    column: $table.foregroundMilliseconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppUsageDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $AppUsageDaysTable> {
  $$AppUsageDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foregroundMilliseconds => $composableBuilder(
    column: $table.foregroundMilliseconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppUsageDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppUsageDaysTable> {
  $$AppUsageDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get foregroundMilliseconds => $composableBuilder(
    column: $table.foregroundMilliseconds,
    builder: (column) => column,
  );
}

class $$AppUsageDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppUsageDaysTable,
          AppUsageDayRow,
          $$AppUsageDaysTableFilterComposer,
          $$AppUsageDaysTableOrderingComposer,
          $$AppUsageDaysTableAnnotationComposer,
          $$AppUsageDaysTableCreateCompanionBuilder,
          $$AppUsageDaysTableUpdateCompanionBuilder,
          (
            AppUsageDayRow,
            BaseReferences<_$AppDatabase, $AppUsageDaysTable, AppUsageDayRow>,
          ),
          AppUsageDayRow,
          PrefetchHooks Function()
        > {
  $$AppUsageDaysTableTableManager(_$AppDatabase db, $AppUsageDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppUsageDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppUsageDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppUsageDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> date = const Value.absent(),
                Value<int> foregroundMilliseconds = const Value.absent(),
              }) => AppUsageDaysCompanion(
                date: date,
                foregroundMilliseconds: foregroundMilliseconds,
              ),
          createCompanionCallback:
              ({
                Value<int> date = const Value.absent(),
                Value<int> foregroundMilliseconds = const Value.absent(),
              }) => AppUsageDaysCompanion.insert(
                date: date,
                foregroundMilliseconds: foregroundMilliseconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppUsageDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppUsageDaysTable,
      AppUsageDayRow,
      $$AppUsageDaysTableFilterComposer,
      $$AppUsageDaysTableOrderingComposer,
      $$AppUsageDaysTableAnnotationComposer,
      $$AppUsageDaysTableCreateCompanionBuilder,
      $$AppUsageDaysTableUpdateCompanionBuilder,
      (
        AppUsageDayRow,
        BaseReferences<_$AppDatabase, $AppUsageDaysTable, AppUsageDayRow>,
      ),
      AppUsageDayRow,
      PrefetchHooks Function()
    >;
typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      required String name,
      required String email,
      Value<String?> avatarPath,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> email,
      Value<String?> avatarPath,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfileRow,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                name: name,
                email: email,
                avatarPath: avatarPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String email,
                Value<String?> avatarPath = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                name: name,
                email: email,
                avatarPath: avatarPath,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfileRow,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;
typedef $$ListeningLessonProgressModelsTableCreateCompanionBuilder =
    ListeningLessonProgressModelsCompanion Function({
      required int courseId,
      required int lessonId,
      Value<int> currentChallengePosition,
      Value<int> completedChallenges,
      required int totalChallenges,
      Value<int> status,
      required int startedAt,
      required int updatedAt,
      Value<int?> completedAt,
      Value<int> activeMilliseconds,
      Value<int> rowid,
    });
typedef $$ListeningLessonProgressModelsTableUpdateCompanionBuilder =
    ListeningLessonProgressModelsCompanion Function({
      Value<int> courseId,
      Value<int> lessonId,
      Value<int> currentChallengePosition,
      Value<int> completedChallenges,
      Value<int> totalChallenges,
      Value<int> status,
      Value<int> startedAt,
      Value<int> updatedAt,
      Value<int?> completedAt,
      Value<int> activeMilliseconds,
      Value<int> rowid,
    });

class $$ListeningLessonProgressModelsTableFilterComposer
    extends Composer<_$AppDatabase, $ListeningLessonProgressModelsTable> {
  $$ListeningLessonProgressModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentChallengePosition => $composableBuilder(
    column: $table.currentChallengePosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedChallenges => $composableBuilder(
    column: $table.completedChallenges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChallenges => $composableBuilder(
    column: $table.totalChallenges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMilliseconds => $composableBuilder(
    column: $table.activeMilliseconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListeningLessonProgressModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListeningLessonProgressModelsTable> {
  $$ListeningLessonProgressModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentChallengePosition => $composableBuilder(
    column: $table.currentChallengePosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedChallenges => $composableBuilder(
    column: $table.completedChallenges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChallenges => $composableBuilder(
    column: $table.totalChallenges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMilliseconds => $composableBuilder(
    column: $table.activeMilliseconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListeningLessonProgressModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListeningLessonProgressModelsTable> {
  $$ListeningLessonProgressModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<int> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<int> get currentChallengePosition => $composableBuilder(
    column: $table.currentChallengePosition,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedChallenges => $composableBuilder(
    column: $table.completedChallenges,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalChallenges => $composableBuilder(
    column: $table.totalChallenges,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeMilliseconds => $composableBuilder(
    column: $table.activeMilliseconds,
    builder: (column) => column,
  );
}

class $$ListeningLessonProgressModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListeningLessonProgressModelsTable,
          ListeningLessonProgressRow,
          $$ListeningLessonProgressModelsTableFilterComposer,
          $$ListeningLessonProgressModelsTableOrderingComposer,
          $$ListeningLessonProgressModelsTableAnnotationComposer,
          $$ListeningLessonProgressModelsTableCreateCompanionBuilder,
          $$ListeningLessonProgressModelsTableUpdateCompanionBuilder,
          (
            ListeningLessonProgressRow,
            BaseReferences<
              _$AppDatabase,
              $ListeningLessonProgressModelsTable,
              ListeningLessonProgressRow
            >,
          ),
          ListeningLessonProgressRow,
          PrefetchHooks Function()
        > {
  $$ListeningLessonProgressModelsTableTableManager(
    _$AppDatabase db,
    $ListeningLessonProgressModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningLessonProgressModelsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ListeningLessonProgressModelsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ListeningLessonProgressModelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> courseId = const Value.absent(),
                Value<int> lessonId = const Value.absent(),
                Value<int> currentChallengePosition = const Value.absent(),
                Value<int> completedChallenges = const Value.absent(),
                Value<int> totalChallenges = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> activeMilliseconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningLessonProgressModelsCompanion(
                courseId: courseId,
                lessonId: lessonId,
                currentChallengePosition: currentChallengePosition,
                completedChallenges: completedChallenges,
                totalChallenges: totalChallenges,
                status: status,
                startedAt: startedAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                activeMilliseconds: activeMilliseconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int courseId,
                required int lessonId,
                Value<int> currentChallengePosition = const Value.absent(),
                Value<int> completedChallenges = const Value.absent(),
                required int totalChallenges,
                Value<int> status = const Value.absent(),
                required int startedAt,
                required int updatedAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int> activeMilliseconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningLessonProgressModelsCompanion.insert(
                courseId: courseId,
                lessonId: lessonId,
                currentChallengePosition: currentChallengePosition,
                completedChallenges: completedChallenges,
                totalChallenges: totalChallenges,
                status: status,
                startedAt: startedAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                activeMilliseconds: activeMilliseconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListeningLessonProgressModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListeningLessonProgressModelsTable,
      ListeningLessonProgressRow,
      $$ListeningLessonProgressModelsTableFilterComposer,
      $$ListeningLessonProgressModelsTableOrderingComposer,
      $$ListeningLessonProgressModelsTableAnnotationComposer,
      $$ListeningLessonProgressModelsTableCreateCompanionBuilder,
      $$ListeningLessonProgressModelsTableUpdateCompanionBuilder,
      (
        ListeningLessonProgressRow,
        BaseReferences<
          _$AppDatabase,
          $ListeningLessonProgressModelsTable,
          ListeningLessonProgressRow
        >,
      ),
      ListeningLessonProgressRow,
      PrefetchHooks Function()
    >;
typedef $$ListeningChallengeProgressModelsTableCreateCompanionBuilder =
    ListeningChallengeProgressModelsCompanion Function({
      required int courseId,
      required int lessonId,
      required int challengeId,
      required int position,
      Value<bool> isCompleted,
      Value<bool> isSkipped,
      Value<int> attemptCount,
      Value<String?> lastAnswer,
      required int updatedAt,
      Value<int?> completedAt,
      Value<int> rowid,
    });
typedef $$ListeningChallengeProgressModelsTableUpdateCompanionBuilder =
    ListeningChallengeProgressModelsCompanion Function({
      Value<int> courseId,
      Value<int> lessonId,
      Value<int> challengeId,
      Value<int> position,
      Value<bool> isCompleted,
      Value<bool> isSkipped,
      Value<int> attemptCount,
      Value<String?> lastAnswer,
      Value<int> updatedAt,
      Value<int?> completedAt,
      Value<int> rowid,
    });

class $$ListeningChallengeProgressModelsTableFilterComposer
    extends Composer<_$AppDatabase, $ListeningChallengeProgressModelsTable> {
  $$ListeningChallengeProgressModelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAnswer => $composableBuilder(
    column: $table.lastAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListeningChallengeProgressModelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListeningChallengeProgressModelsTable> {
  $$ListeningChallengeProgressModelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSkipped => $composableBuilder(
    column: $table.isSkipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAnswer => $composableBuilder(
    column: $table.lastAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListeningChallengeProgressModelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListeningChallengeProgressModelsTable> {
  $$ListeningChallengeProgressModelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<int> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<int> get challengeId => $composableBuilder(
    column: $table.challengeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSkipped =>
      $composableBuilder(column: $table.isSkipped, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastAnswer => $composableBuilder(
    column: $table.lastAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$ListeningChallengeProgressModelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListeningChallengeProgressModelsTable,
          ListeningChallengeProgressRow,
          $$ListeningChallengeProgressModelsTableFilterComposer,
          $$ListeningChallengeProgressModelsTableOrderingComposer,
          $$ListeningChallengeProgressModelsTableAnnotationComposer,
          $$ListeningChallengeProgressModelsTableCreateCompanionBuilder,
          $$ListeningChallengeProgressModelsTableUpdateCompanionBuilder,
          (
            ListeningChallengeProgressRow,
            BaseReferences<
              _$AppDatabase,
              $ListeningChallengeProgressModelsTable,
              ListeningChallengeProgressRow
            >,
          ),
          ListeningChallengeProgressRow,
          PrefetchHooks Function()
        > {
  $$ListeningChallengeProgressModelsTableTableManager(
    _$AppDatabase db,
    $ListeningChallengeProgressModelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningChallengeProgressModelsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ListeningChallengeProgressModelsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ListeningChallengeProgressModelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> courseId = const Value.absent(),
                Value<int> lessonId = const Value.absent(),
                Value<int> challengeId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastAnswer = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningChallengeProgressModelsCompanion(
                courseId: courseId,
                lessonId: lessonId,
                challengeId: challengeId,
                position: position,
                isCompleted: isCompleted,
                isSkipped: isSkipped,
                attemptCount: attemptCount,
                lastAnswer: lastAnswer,
                updatedAt: updatedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int courseId,
                required int lessonId,
                required int challengeId,
                required int position,
                Value<bool> isCompleted = const Value.absent(),
                Value<bool> isSkipped = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastAnswer = const Value.absent(),
                required int updatedAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningChallengeProgressModelsCompanion.insert(
                courseId: courseId,
                lessonId: lessonId,
                challengeId: challengeId,
                position: position,
                isCompleted: isCompleted,
                isSkipped: isSkipped,
                attemptCount: attemptCount,
                lastAnswer: lastAnswer,
                updatedAt: updatedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListeningChallengeProgressModelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListeningChallengeProgressModelsTable,
      ListeningChallengeProgressRow,
      $$ListeningChallengeProgressModelsTableFilterComposer,
      $$ListeningChallengeProgressModelsTableOrderingComposer,
      $$ListeningChallengeProgressModelsTableAnnotationComposer,
      $$ListeningChallengeProgressModelsTableCreateCompanionBuilder,
      $$ListeningChallengeProgressModelsTableUpdateCompanionBuilder,
      (
        ListeningChallengeProgressRow,
        BaseReferences<
          _$AppDatabase,
          $ListeningChallengeProgressModelsTable,
          ListeningChallengeProgressRow
        >,
      ),
      ListeningChallengeProgressRow,
      PrefetchHooks Function()
    >;
typedef $$ListeningPracticeDaysTableCreateCompanionBuilder =
    ListeningPracticeDaysCompanion Function({
      Value<int> date,
      Value<int> activeMilliseconds,
    });
typedef $$ListeningPracticeDaysTableUpdateCompanionBuilder =
    ListeningPracticeDaysCompanion Function({
      Value<int> date,
      Value<int> activeMilliseconds,
    });

class $$ListeningPracticeDaysTableFilterComposer
    extends Composer<_$AppDatabase, $ListeningPracticeDaysTable> {
  $$ListeningPracticeDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMilliseconds => $composableBuilder(
    column: $table.activeMilliseconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListeningPracticeDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $ListeningPracticeDaysTable> {
  $$ListeningPracticeDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMilliseconds => $composableBuilder(
    column: $table.activeMilliseconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListeningPracticeDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListeningPracticeDaysTable> {
  $$ListeningPracticeDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get activeMilliseconds => $composableBuilder(
    column: $table.activeMilliseconds,
    builder: (column) => column,
  );
}

class $$ListeningPracticeDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListeningPracticeDaysTable,
          ListeningPracticeDayRow,
          $$ListeningPracticeDaysTableFilterComposer,
          $$ListeningPracticeDaysTableOrderingComposer,
          $$ListeningPracticeDaysTableAnnotationComposer,
          $$ListeningPracticeDaysTableCreateCompanionBuilder,
          $$ListeningPracticeDaysTableUpdateCompanionBuilder,
          (
            ListeningPracticeDayRow,
            BaseReferences<
              _$AppDatabase,
              $ListeningPracticeDaysTable,
              ListeningPracticeDayRow
            >,
          ),
          ListeningPracticeDayRow,
          PrefetchHooks Function()
        > {
  $$ListeningPracticeDaysTableTableManager(
    _$AppDatabase db,
    $ListeningPracticeDaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningPracticeDaysTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ListeningPracticeDaysTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ListeningPracticeDaysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> date = const Value.absent(),
                Value<int> activeMilliseconds = const Value.absent(),
              }) => ListeningPracticeDaysCompanion(
                date: date,
                activeMilliseconds: activeMilliseconds,
              ),
          createCompanionCallback:
              ({
                Value<int> date = const Value.absent(),
                Value<int> activeMilliseconds = const Value.absent(),
              }) => ListeningPracticeDaysCompanion.insert(
                date: date,
                activeMilliseconds: activeMilliseconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListeningPracticeDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListeningPracticeDaysTable,
      ListeningPracticeDayRow,
      $$ListeningPracticeDaysTableFilterComposer,
      $$ListeningPracticeDaysTableOrderingComposer,
      $$ListeningPracticeDaysTableAnnotationComposer,
      $$ListeningPracticeDaysTableCreateCompanionBuilder,
      $$ListeningPracticeDaysTableUpdateCompanionBuilder,
      (
        ListeningPracticeDayRow,
        BaseReferences<
          _$AppDatabase,
          $ListeningPracticeDaysTable,
          ListeningPracticeDayRow
        >,
      ),
      ListeningPracticeDayRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TopicModelsTableTableManager get topicModels =>
      $$TopicModelsTableTableManager(_db, _db.topicModels);
  $$WordModelsTableTableManager get wordModels =>
      $$WordModelsTableTableManager(_db, _db.wordModels);
  $$LearningProgressModelsTableTableManager get learningProgressModels =>
      $$LearningProgressModelsTableTableManager(
        _db,
        _db.learningProgressModels,
      );
  $$WordSentenceProgressModelsTableTableManager
  get wordSentenceProgressModels =>
      $$WordSentenceProgressModelsTableTableManager(
        _db,
        _db.wordSentenceProgressModels,
      );
  $$SentenceExposureModelsTableTableManager get sentenceExposureModels =>
      $$SentenceExposureModelsTableTableManager(
        _db,
        _db.sentenceExposureModels,
      );
  $$LearningSessionsTableTableManager get learningSessions =>
      $$LearningSessionsTableTableManager(_db, _db.learningSessions);
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(_db, _db.sessionExercises);
  $$SimilarWordModelsTableTableManager get similarWordModels =>
      $$SimilarWordModelsTableTableManager(_db, _db.similarWordModels);
  $$SttMisspellingModelsTableTableManager get sttMisspellingModels =>
      $$SttMisspellingModelsTableTableManager(_db, _db.sttMisspellingModels);
  $$LetterModelsTableTableManager get letterModels =>
      $$LetterModelsTableTableManager(_db, _db.letterModels);
  $$VisitModelsTableTableManager get visitModels =>
      $$VisitModelsTableTableManager(_db, _db.visitModels);
  $$OnboardingTestAnswerModelsTableTableManager
  get onboardingTestAnswerModels =>
      $$OnboardingTestAnswerModelsTableTableManager(
        _db,
        _db.onboardingTestAnswerModels,
      );
  $$ContentRevisionsTableTableManager get contentRevisions =>
      $$ContentRevisionsTableTableManager(_db, _db.contentRevisions);
  $$AppUsageDaysTableTableManager get appUsageDays =>
      $$AppUsageDaysTableTableManager(_db, _db.appUsageDays);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$ListeningLessonProgressModelsTableTableManager
  get listeningLessonProgressModels =>
      $$ListeningLessonProgressModelsTableTableManager(
        _db,
        _db.listeningLessonProgressModels,
      );
  $$ListeningChallengeProgressModelsTableTableManager
  get listeningChallengeProgressModels =>
      $$ListeningChallengeProgressModelsTableTableManager(
        _db,
        _db.listeningChallengeProgressModels,
      );
  $$ListeningPracticeDaysTableTableManager get listeningPracticeDays =>
      $$ListeningPracticeDaysTableTableManager(_db, _db.listeningPracticeDays);
}
