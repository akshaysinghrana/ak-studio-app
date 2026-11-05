// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, DownloadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaKind>($DownloadsTable.$converterkind);
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DownloadStatus>($DownloadsTable.$converterstatus);
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedPathMeta = const VerificationMeta(
    'savedPath',
  );
  @override
  late final GeneratedColumn<String> savedPath = GeneratedColumn<String>(
    'saved_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    source,
    sourceId,
    url,
    title,
    artist,
    kind,
    fileName,
    status,
    progress,
    totalBytes,
    error,
    savedPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('saved_path')) {
      context.handle(
        _savedPathMeta,
        savedPath.isAcceptableOrUnknown(data['saved_path']!, _savedPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      kind: $DownloadsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      status: $DownloadsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      savedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaKind, String, String> $converterkind =
      const EnumNameConverter<MediaKind>(MediaKind.values);
  static JsonTypeConverter2<DownloadStatus, String, String> $converterstatus =
      const EnumNameConverter<DownloadStatus>(DownloadStatus.values);
}

class DownloadRow extends DataClass implements Insertable<DownloadRow> {
  final String id;

  /// Current background_downloader task ID; changes when a download is
  /// retried.
  final String taskId;

  /// `audius`, `jamendo` or `url`.
  final String source;

  /// Catalogue track ID or the URL; used to detect duplicates.
  final String sourceId;
  final String url;
  final String title;
  final String? artist;
  final MediaKind kind;
  final String fileName;
  final DownloadStatus status;
  final double progress;
  final int? totalBytes;
  final String? error;

  /// Final location in shared storage once complete.
  final String? savedPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DownloadRow({
    required this.id,
    required this.taskId,
    required this.source,
    required this.sourceId,
    required this.url,
    required this.title,
    this.artist,
    required this.kind,
    required this.fileName,
    required this.status,
    required this.progress,
    this.totalBytes,
    this.error,
    this.savedPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['source'] = Variable<String>(source);
    map['source_id'] = Variable<String>(sourceId);
    map['url'] = Variable<String>(url);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    {
      map['kind'] = Variable<String>(
        $DownloadsTable.$converterkind.toSql(kind),
      );
    }
    map['file_name'] = Variable<String>(fileName);
    {
      map['status'] = Variable<String>(
        $DownloadsTable.$converterstatus.toSql(status),
      );
    }
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || savedPath != null) {
      map['saved_path'] = Variable<String>(savedPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      source: Value(source),
      sourceId: Value(sourceId),
      url: Value(url),
      title: Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      kind: Value(kind),
      fileName: Value(fileName),
      status: Value(status),
      progress: Value(progress),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      savedPath: savedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(savedPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DownloadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      kind: $DownloadsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      fileName: serializer.fromJson<String>(json['fileName']),
      status: $DownloadsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      progress: serializer.fromJson<double>(json['progress']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      error: serializer.fromJson<String?>(json['error']),
      savedPath: serializer.fromJson<String?>(json['savedPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String>(sourceId),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'kind': serializer.toJson<String>(
        $DownloadsTable.$converterkind.toJson(kind),
      ),
      'fileName': serializer.toJson<String>(fileName),
      'status': serializer.toJson<String>(
        $DownloadsTable.$converterstatus.toJson(status),
      ),
      'progress': serializer.toJson<double>(progress),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'error': serializer.toJson<String?>(error),
      'savedPath': serializer.toJson<String?>(savedPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DownloadRow copyWith({
    String? id,
    String? taskId,
    String? source,
    String? sourceId,
    String? url,
    String? title,
    Value<String?> artist = const Value.absent(),
    MediaKind? kind,
    String? fileName,
    DownloadStatus? status,
    double? progress,
    Value<int?> totalBytes = const Value.absent(),
    Value<String?> error = const Value.absent(),
    Value<String?> savedPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DownloadRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    source: source ?? this.source,
    sourceId: sourceId ?? this.sourceId,
    url: url ?? this.url,
    title: title ?? this.title,
    artist: artist.present ? artist.value : this.artist,
    kind: kind ?? this.kind,
    fileName: fileName ?? this.fileName,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
    error: error.present ? error.value : this.error,
    savedPath: savedPath.present ? savedPath.value : this.savedPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DownloadRow copyWithCompanion(DownloadsCompanion data) {
    return DownloadRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      kind: data.kind.present ? data.kind.value : this.kind,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      error: data.error.present ? data.error.value : this.error,
      savedPath: data.savedPath.present ? data.savedPath.value : this.savedPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('kind: $kind, ')
          ..write('fileName: $fileName, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('error: $error, ')
          ..write('savedPath: $savedPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    source,
    sourceId,
    url,
    title,
    artist,
    kind,
    fileName,
    status,
    progress,
    totalBytes,
    error,
    savedPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.url == this.url &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.kind == this.kind &&
          other.fileName == this.fileName &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.totalBytes == this.totalBytes &&
          other.error == this.error &&
          other.savedPath == this.savedPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DownloadsCompanion extends UpdateCompanion<DownloadRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> source;
  final Value<String> sourceId;
  final Value<String> url;
  final Value<String> title;
  final Value<String?> artist;
  final Value<MediaKind> kind;
  final Value<String> fileName;
  final Value<DownloadStatus> status;
  final Value<double> progress;
  final Value<int?> totalBytes;
  final Value<String?> error;
  final Value<String?> savedPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.kind = const Value.absent(),
    this.fileName = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.error = const Value.absent(),
    this.savedPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String id,
    required String taskId,
    required String source,
    required String sourceId,
    required String url,
    required String title,
    this.artist = const Value.absent(),
    required MediaKind kind,
    required String fileName,
    required DownloadStatus status,
    this.progress = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.error = const Value.absent(),
    this.savedPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       source = Value(source),
       sourceId = Value(sourceId),
       url = Value(url),
       title = Value(title),
       kind = Value(kind),
       fileName = Value(fileName),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DownloadRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? kind,
    Expression<String>? fileName,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? totalBytes,
    Expression<String>? error,
    Expression<String>? savedPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (kind != null) 'kind': kind,
      if (fileName != null) 'file_name': fileName,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (error != null) 'error': error,
      if (savedPath != null) 'saved_path': savedPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? source,
    Value<String>? sourceId,
    Value<String>? url,
    Value<String>? title,
    Value<String?>? artist,
    Value<MediaKind>? kind,
    Value<String>? fileName,
    Value<DownloadStatus>? status,
    Value<double>? progress,
    Value<int?>? totalBytes,
    Value<String?>? error,
    Value<String?>? savedPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      url: url ?? this.url,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      kind: kind ?? this.kind,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      error: error ?? this.error,
      savedPath: savedPath ?? this.savedPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $DownloadsTable.$converterkind.toSql(kind.value),
      );
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $DownloadsTable.$converterstatus.toSql(status.value),
      );
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (savedPath.present) {
      map['saved_path'] = Variable<String>(savedPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('kind: $kind, ')
          ..write('fileName: $fileName, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('error: $error, ')
          ..write('savedPath: $savedPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HiddenFoldersTable extends HiddenFolders
    with TableInfo<$HiddenFoldersTable, HiddenFolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HiddenFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hiddenAtMeta = const VerificationMeta(
    'hiddenAt',
  );
  @override
  late final GeneratedColumn<DateTime> hiddenAt = GeneratedColumn<DateTime>(
    'hidden_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [folder, hiddenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hidden_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<HiddenFolderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('hidden_at')) {
      context.handle(
        _hiddenAtMeta,
        hiddenAt.isAcceptableOrUnknown(data['hidden_at']!, _hiddenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_hiddenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {folder};
  @override
  HiddenFolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HiddenFolderRow(
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      )!,
      hiddenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}hidden_at'],
      )!,
    );
  }

  @override
  $HiddenFoldersTable createAlias(String alias) {
    return $HiddenFoldersTable(attachedDatabase, alias);
  }
}

class HiddenFolderRow extends DataClass implements Insertable<HiddenFolderRow> {
  /// MediaStore relative path, e.g. `DCIM/Camera/`.
  final String folder;
  final DateTime hiddenAt;
  const HiddenFolderRow({required this.folder, required this.hiddenAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['folder'] = Variable<String>(folder);
    map['hidden_at'] = Variable<DateTime>(hiddenAt);
    return map;
  }

  HiddenFoldersCompanion toCompanion(bool nullToAbsent) {
    return HiddenFoldersCompanion(
      folder: Value(folder),
      hiddenAt: Value(hiddenAt),
    );
  }

  factory HiddenFolderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HiddenFolderRow(
      folder: serializer.fromJson<String>(json['folder']),
      hiddenAt: serializer.fromJson<DateTime>(json['hiddenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'folder': serializer.toJson<String>(folder),
      'hiddenAt': serializer.toJson<DateTime>(hiddenAt),
    };
  }

  HiddenFolderRow copyWith({String? folder, DateTime? hiddenAt}) =>
      HiddenFolderRow(
        folder: folder ?? this.folder,
        hiddenAt: hiddenAt ?? this.hiddenAt,
      );
  HiddenFolderRow copyWithCompanion(HiddenFoldersCompanion data) {
    return HiddenFolderRow(
      folder: data.folder.present ? data.folder.value : this.folder,
      hiddenAt: data.hiddenAt.present ? data.hiddenAt.value : this.hiddenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HiddenFolderRow(')
          ..write('folder: $folder, ')
          ..write('hiddenAt: $hiddenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(folder, hiddenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HiddenFolderRow &&
          other.folder == this.folder &&
          other.hiddenAt == this.hiddenAt);
}

class HiddenFoldersCompanion extends UpdateCompanion<HiddenFolderRow> {
  final Value<String> folder;
  final Value<DateTime> hiddenAt;
  final Value<int> rowid;
  const HiddenFoldersCompanion({
    this.folder = const Value.absent(),
    this.hiddenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HiddenFoldersCompanion.insert({
    required String folder,
    required DateTime hiddenAt,
    this.rowid = const Value.absent(),
  }) : folder = Value(folder),
       hiddenAt = Value(hiddenAt);
  static Insertable<HiddenFolderRow> custom({
    Expression<String>? folder,
    Expression<DateTime>? hiddenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (folder != null) 'folder': folder,
      if (hiddenAt != null) 'hidden_at': hiddenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HiddenFoldersCompanion copyWith({
    Value<String>? folder,
    Value<DateTime>? hiddenAt,
    Value<int>? rowid,
  }) {
    return HiddenFoldersCompanion(
      folder: folder ?? this.folder,
      hiddenAt: hiddenAt ?? this.hiddenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (hiddenAt.present) {
      map['hidden_at'] = Variable<DateTime>(hiddenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HiddenFoldersCompanion(')
          ..write('folder: $folder, ')
          ..write('hiddenAt: $hiddenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncTombstonesTable extends SyncTombstones
    with TableInfo<$SyncTombstonesTable, SyncTombstoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncTombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, recordId, userId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncTombstoneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, recordId, userId};
  @override
  SyncTombstoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTombstoneRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $SyncTombstonesTable createAlias(String alias) {
    return $SyncTombstonesTable(attachedDatabase, alias);
  }
}

class SyncTombstoneRow extends DataClass
    implements Insertable<SyncTombstoneRow> {
  /// 'playlist' or 'favorite'.
  final String kind;

  /// Playlist ID, or the media fingerprint for favourites.
  final String recordId;
  final String userId;
  final DateTime deletedAt;
  const SyncTombstoneRow({
    required this.kind,
    required this.recordId,
    required this.userId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['record_id'] = Variable<String>(recordId);
    map['user_id'] = Variable<String>(userId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  SyncTombstonesCompanion toCompanion(bool nullToAbsent) {
    return SyncTombstonesCompanion(
      kind: Value(kind),
      recordId: Value(recordId),
      userId: Value(userId),
      deletedAt: Value(deletedAt),
    );
  }

  factory SyncTombstoneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTombstoneRow(
      kind: serializer.fromJson<String>(json['kind']),
      recordId: serializer.fromJson<String>(json['recordId']),
      userId: serializer.fromJson<String>(json['userId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'recordId': serializer.toJson<String>(recordId),
      'userId': serializer.toJson<String>(userId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  SyncTombstoneRow copyWith({
    String? kind,
    String? recordId,
    String? userId,
    DateTime? deletedAt,
  }) => SyncTombstoneRow(
    kind: kind ?? this.kind,
    recordId: recordId ?? this.recordId,
    userId: userId ?? this.userId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  SyncTombstoneRow copyWithCompanion(SyncTombstonesCompanion data) {
    return SyncTombstoneRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      userId: data.userId.present ? data.userId.value : this.userId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstoneRow(')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId, ')
          ..write('userId: $userId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, recordId, userId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTombstoneRow &&
          other.kind == this.kind &&
          other.recordId == this.recordId &&
          other.userId == this.userId &&
          other.deletedAt == this.deletedAt);
}

class SyncTombstonesCompanion extends UpdateCompanion<SyncTombstoneRow> {
  final Value<String> kind;
  final Value<String> recordId;
  final Value<String> userId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const SyncTombstonesCompanion({
    this.kind = const Value.absent(),
    this.recordId = const Value.absent(),
    this.userId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTombstonesCompanion.insert({
    required String kind,
    required String recordId,
    required String userId,
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       recordId = Value(recordId),
       userId = Value(userId),
       deletedAt = Value(deletedAt);
  static Insertable<SyncTombstoneRow> custom({
    Expression<String>? kind,
    Expression<String>? recordId,
    Expression<String>? userId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (recordId != null) 'record_id': recordId,
      if (userId != null) 'user_id': userId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTombstonesCompanion copyWith({
    Value<String>? kind,
    Value<String>? recordId,
    Value<String>? userId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return SyncTombstonesCompanion(
      kind: kind ?? this.kind,
      recordId: recordId ?? this.recordId,
      userId: userId ?? this.userId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstonesCompanion(')
          ..write('kind: $kind, ')
          ..write('recordId: $recordId, ')
          ..write('userId: $userId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTable extends SyncMetadata
    with TableInfo<$SyncMetadataTable, SyncMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, lastSyncAt, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  SyncMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncMetadataTable createAlias(String alias) {
    return $SyncMetadataTable(attachedDatabase, alias);
  }
}

class SyncMetadataRow extends DataClass implements Insertable<SyncMetadataRow> {
  final String userId;
  final DateTime? lastSyncAt;
  final String? lastError;
  const SyncMetadataRow({
    required this.userId,
    this.lastSyncAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataCompanion(
      userId: Value(userId),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataRow(
      userId: serializer.fromJson<String>(json['userId']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncMetadataRow copyWith({
    String? userId,
    Value<DateTime?> lastSyncAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncMetadataRow(
    userId: userId ?? this.userId,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncMetadataRow copyWithCompanion(SyncMetadataCompanion data) {
    return SyncMetadataRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataRow(')
          ..write('userId: $userId, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, lastSyncAt, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataRow &&
          other.userId == this.userId &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastError == this.lastError);
}

class SyncMetadataCompanion extends UpdateCompanion<SyncMetadataRow> {
  final Value<String> userId;
  final Value<DateTime?> lastSyncAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncMetadataCompanion({
    this.userId = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataCompanion.insert({
    required String userId,
    this.lastSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<SyncMetadataRow> custom({
    Expression<String>? userId,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataCompanion copyWith({
    Value<String>? userId,
    Value<DateTime?>? lastSyncAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncMetadataCompanion(
      userId: userId ?? this.userId,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataCompanion(')
          ..write('userId: $userId, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, LibraryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaKind>($MediaItemsTable.$converterkind);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locatorMeta = const VerificationMeta(
    'locator',
  );
  @override
  late final GeneratedColumn<String> locator = GeneratedColumn<String>(
    'locator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaOrigin, String> origin =
      GeneratedColumn<String>(
        'origin',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaOrigin>($MediaItemsTable.$converterorigin);
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availableMeta = const VerificationMeta(
    'available',
  );
  @override
  late final GeneratedColumn<bool> available = GeneratedColumn<bool>(
    'available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastSeenScanMeta = const VerificationMeta(
    'lastSeenScan',
  );
  @override
  late final GeneratedColumn<int> lastSeenScan = GeneratedColumn<int>(
    'last_seen_scan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    title,
    displayName,
    locator,
    origin,
    storeId,
    mimeType,
    durationMs,
    sizeBytes,
    folder,
    artist,
    album,
    width,
    height,
    modifiedAt,
    addedAt,
    available,
    lastSeenScan,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('locator')) {
      context.handle(
        _locatorMeta,
        locator.isAcceptableOrUnknown(data['locator']!, _locatorMeta),
      );
    } else if (isInserting) {
      context.missing(_locatorMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('available')) {
      context.handle(
        _availableMeta,
        available.isAcceptableOrUnknown(data['available']!, _availableMeta),
      );
    }
    if (data.containsKey('last_seen_scan')) {
      context.handle(
        _lastSeenScanMeta,
        lastSeenScan.isAcceptableOrUnknown(
          data['last_seen_scan']!,
          _lastSeenScanMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: $MediaItemsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      locator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locator'],
      )!,
      origin: $MediaItemsTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      ),
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      available: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}available'],
      )!,
      lastSeenScan: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_scan'],
      )!,
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaKind, String, String> $converterkind =
      const EnumNameConverter<MediaKind>(MediaKind.values);
  static JsonTypeConverter2<MediaOrigin, String, String> $converterorigin =
      const EnumNameConverter<MediaOrigin>(MediaOrigin.values);
}

class LibraryItem extends DataClass implements Insertable<LibraryItem> {
  final String id;
  final MediaKind kind;
  final String title;
  final String? displayName;
  final String locator;
  final MediaOrigin origin;
  final int? storeId;
  final String? mimeType;
  final int? durationMs;
  final int? sizeBytes;
  final String? folder;
  final String? artist;
  final String? album;
  final int? width;
  final int? height;
  final DateTime? modifiedAt;
  final DateTime addedAt;
  final bool available;

  /// ID of the last MediaStore scan that saw this item; used to detect
  /// deleted/moved files without deleting their history.
  final int lastSeenScan;
  const LibraryItem({
    required this.id,
    required this.kind,
    required this.title,
    this.displayName,
    required this.locator,
    required this.origin,
    this.storeId,
    this.mimeType,
    this.durationMs,
    this.sizeBytes,
    this.folder,
    this.artist,
    this.album,
    this.width,
    this.height,
    this.modifiedAt,
    required this.addedAt,
    required this.available,
    required this.lastSeenScan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['kind'] = Variable<String>(
        $MediaItemsTable.$converterkind.toSql(kind),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['locator'] = Variable<String>(locator);
    {
      map['origin'] = Variable<String>(
        $MediaItemsTable.$converterorigin.toSql(origin),
      );
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<int>(storeId);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || folder != null) {
      map['folder'] = Variable<String>(folder);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<DateTime>(modifiedAt);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    map['available'] = Variable<bool>(available);
    map['last_seen_scan'] = Variable<int>(lastSeenScan);
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      kind: Value(kind),
      title: Value(title),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      locator: Value(locator),
      origin: Value(origin),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      folder: folder == null && nullToAbsent
          ? const Value.absent()
          : Value(folder),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      addedAt: Value(addedAt),
      available: Value(available),
      lastSeenScan: Value(lastSeenScan),
    );
  }

  factory LibraryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryItem(
      id: serializer.fromJson<String>(json['id']),
      kind: $MediaItemsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      title: serializer.fromJson<String>(json['title']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      locator: serializer.fromJson<String>(json['locator']),
      origin: $MediaItemsTable.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
      storeId: serializer.fromJson<int?>(json['storeId']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      folder: serializer.fromJson<String?>(json['folder']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      available: serializer.fromJson<bool>(json['available']),
      lastSeenScan: serializer.fromJson<int>(json['lastSeenScan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(
        $MediaItemsTable.$converterkind.toJson(kind),
      ),
      'title': serializer.toJson<String>(title),
      'displayName': serializer.toJson<String?>(displayName),
      'locator': serializer.toJson<String>(locator),
      'origin': serializer.toJson<String>(
        $MediaItemsTable.$converterorigin.toJson(origin),
      ),
      'storeId': serializer.toJson<int?>(storeId),
      'mimeType': serializer.toJson<String?>(mimeType),
      'durationMs': serializer.toJson<int?>(durationMs),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'folder': serializer.toJson<String?>(folder),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'modifiedAt': serializer.toJson<DateTime?>(modifiedAt),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'available': serializer.toJson<bool>(available),
      'lastSeenScan': serializer.toJson<int>(lastSeenScan),
    };
  }

  LibraryItem copyWith({
    String? id,
    MediaKind? kind,
    String? title,
    Value<String?> displayName = const Value.absent(),
    String? locator,
    MediaOrigin? origin,
    Value<int?> storeId = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    Value<String?> folder = const Value.absent(),
    Value<String?> artist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<DateTime?> modifiedAt = const Value.absent(),
    DateTime? addedAt,
    bool? available,
    int? lastSeenScan,
  }) => LibraryItem(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    displayName: displayName.present ? displayName.value : this.displayName,
    locator: locator ?? this.locator,
    origin: origin ?? this.origin,
    storeId: storeId.present ? storeId.value : this.storeId,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    folder: folder.present ? folder.value : this.folder,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
    addedAt: addedAt ?? this.addedAt,
    available: available ?? this.available,
    lastSeenScan: lastSeenScan ?? this.lastSeenScan,
  );
  LibraryItem copyWithCompanion(MediaItemsCompanion data) {
    return LibraryItem(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      locator: data.locator.present ? data.locator.value : this.locator,
      origin: data.origin.present ? data.origin.value : this.origin,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      folder: data.folder.present ? data.folder.value : this.folder,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      available: data.available.present ? data.available.value : this.available,
      lastSeenScan: data.lastSeenScan.present
          ? data.lastSeenScan.value
          : this.lastSeenScan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryItem(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('displayName: $displayName, ')
          ..write('locator: $locator, ')
          ..write('origin: $origin, ')
          ..write('storeId: $storeId, ')
          ..write('mimeType: $mimeType, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('folder: $folder, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('available: $available, ')
          ..write('lastSeenScan: $lastSeenScan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    title,
    displayName,
    locator,
    origin,
    storeId,
    mimeType,
    durationMs,
    sizeBytes,
    folder,
    artist,
    album,
    width,
    height,
    modifiedAt,
    addedAt,
    available,
    lastSeenScan,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryItem &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.displayName == this.displayName &&
          other.locator == this.locator &&
          other.origin == this.origin &&
          other.storeId == this.storeId &&
          other.mimeType == this.mimeType &&
          other.durationMs == this.durationMs &&
          other.sizeBytes == this.sizeBytes &&
          other.folder == this.folder &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.width == this.width &&
          other.height == this.height &&
          other.modifiedAt == this.modifiedAt &&
          other.addedAt == this.addedAt &&
          other.available == this.available &&
          other.lastSeenScan == this.lastSeenScan);
}

class MediaItemsCompanion extends UpdateCompanion<LibraryItem> {
  final Value<String> id;
  final Value<MediaKind> kind;
  final Value<String> title;
  final Value<String?> displayName;
  final Value<String> locator;
  final Value<MediaOrigin> origin;
  final Value<int?> storeId;
  final Value<String?> mimeType;
  final Value<int?> durationMs;
  final Value<int?> sizeBytes;
  final Value<String?> folder;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<int?> width;
  final Value<int?> height;
  final Value<DateTime?> modifiedAt;
  final Value<DateTime> addedAt;
  final Value<bool> available;
  final Value<int> lastSeenScan;
  final Value<int> rowid;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.displayName = const Value.absent(),
    this.locator = const Value.absent(),
    this.origin = const Value.absent(),
    this.storeId = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.folder = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.available = const Value.absent(),
    this.lastSeenScan = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    required String id,
    required MediaKind kind,
    required String title,
    this.displayName = const Value.absent(),
    required String locator,
    required MediaOrigin origin,
    this.storeId = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.folder = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    required DateTime addedAt,
    this.available = const Value.absent(),
    this.lastSeenScan = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       title = Value(title),
       locator = Value(locator),
       origin = Value(origin),
       addedAt = Value(addedAt);
  static Insertable<LibraryItem> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? displayName,
    Expression<String>? locator,
    Expression<String>? origin,
    Expression<int>? storeId,
    Expression<String>? mimeType,
    Expression<int>? durationMs,
    Expression<int>? sizeBytes,
    Expression<String>? folder,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<int>? width,
    Expression<int>? height,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? addedAt,
    Expression<bool>? available,
    Expression<int>? lastSeenScan,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (displayName != null) 'display_name': displayName,
      if (locator != null) 'locator': locator,
      if (origin != null) 'origin': origin,
      if (storeId != null) 'store_id': storeId,
      if (mimeType != null) 'mime_type': mimeType,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (folder != null) 'folder': folder,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (addedAt != null) 'added_at': addedAt,
      if (available != null) 'available': available,
      if (lastSeenScan != null) 'last_seen_scan': lastSeenScan,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsCompanion copyWith({
    Value<String>? id,
    Value<MediaKind>? kind,
    Value<String>? title,
    Value<String?>? displayName,
    Value<String>? locator,
    Value<MediaOrigin>? origin,
    Value<int?>? storeId,
    Value<String?>? mimeType,
    Value<int?>? durationMs,
    Value<int?>? sizeBytes,
    Value<String?>? folder,
    Value<String?>? artist,
    Value<String?>? album,
    Value<int?>? width,
    Value<int?>? height,
    Value<DateTime?>? modifiedAt,
    Value<DateTime>? addedAt,
    Value<bool>? available,
    Value<int>? lastSeenScan,
    Value<int>? rowid,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      displayName: displayName ?? this.displayName,
      locator: locator ?? this.locator,
      origin: origin ?? this.origin,
      storeId: storeId ?? this.storeId,
      mimeType: mimeType ?? this.mimeType,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      folder: folder ?? this.folder,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      width: width ?? this.width,
      height: height ?? this.height,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      addedAt: addedAt ?? this.addedAt,
      available: available ?? this.available,
      lastSeenScan: lastSeenScan ?? this.lastSeenScan,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $MediaItemsTable.$converterkind.toSql(kind.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (locator.present) {
      map['locator'] = Variable<String>(locator.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        $MediaItemsTable.$converterorigin.toSql(origin.value),
      );
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (available.present) {
      map['available'] = Variable<bool>(available.value);
    }
    if (lastSeenScan.present) {
      map['last_seen_scan'] = Variable<int>(lastSeenScan.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('displayName: $displayName, ')
          ..write('locator: $locator, ')
          ..write('origin: $origin, ')
          ..write('storeId: $storeId, ')
          ..write('mimeType: $mimeType, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('folder: $folder, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('addedAt: $addedAt, ')
          ..write('available: $available, ')
          ..write('lastSeenScan: $lastSeenScan, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackProgressTable extends PlaybackProgress
    with TableInfo<$PlaybackProgressTable, PlaybackProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mediaId,
    positionMs,
    completed,
    lastPlayedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMsMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPlayedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  PlaybackProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackProgressRow(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaybackProgressTable createAlias(String alias) {
    return $PlaybackProgressTable(attachedDatabase, alias);
  }
}

class PlaybackProgressRow extends DataClass
    implements Insertable<PlaybackProgressRow> {
  final String mediaId;
  final int positionMs;
  final bool completed;
  final DateTime lastPlayedAt;
  final DateTime updatedAt;
  const PlaybackProgressRow({
    required this.mediaId,
    required this.positionMs,
    required this.completed,
    required this.lastPlayedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['position_ms'] = Variable<int>(positionMs);
    map['completed'] = Variable<bool>(completed);
    map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaybackProgressCompanion toCompanion(bool nullToAbsent) {
    return PlaybackProgressCompanion(
      mediaId: Value(mediaId),
      positionMs: Value(positionMs),
      completed: Value(completed),
      lastPlayedAt: Value(lastPlayedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaybackProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackProgressRow(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      completed: serializer.fromJson<bool>(json['completed']),
      lastPlayedAt: serializer.fromJson<DateTime>(json['lastPlayedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'positionMs': serializer.toJson<int>(positionMs),
      'completed': serializer.toJson<bool>(completed),
      'lastPlayedAt': serializer.toJson<DateTime>(lastPlayedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaybackProgressRow copyWith({
    String? mediaId,
    int? positionMs,
    bool? completed,
    DateTime? lastPlayedAt,
    DateTime? updatedAt,
  }) => PlaybackProgressRow(
    mediaId: mediaId ?? this.mediaId,
    positionMs: positionMs ?? this.positionMs,
    completed: completed ?? this.completed,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaybackProgressRow copyWithCompanion(PlaybackProgressCompanion data) {
    return PlaybackProgressRow(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      completed: data.completed.present ? data.completed.value : this.completed,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackProgressRow(')
          ..write('mediaId: $mediaId, ')
          ..write('positionMs: $positionMs, ')
          ..write('completed: $completed, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(mediaId, positionMs, completed, lastPlayedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackProgressRow &&
          other.mediaId == this.mediaId &&
          other.positionMs == this.positionMs &&
          other.completed == this.completed &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.updatedAt == this.updatedAt);
}

class PlaybackProgressCompanion extends UpdateCompanion<PlaybackProgressRow> {
  final Value<String> mediaId;
  final Value<int> positionMs;
  final Value<bool> completed;
  final Value<DateTime> lastPlayedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaybackProgressCompanion({
    this.mediaId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.completed = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackProgressCompanion.insert({
    required String mediaId,
    required int positionMs,
    this.completed = const Value.absent(),
    required DateTime lastPlayedAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       positionMs = Value(positionMs),
       lastPlayedAt = Value(lastPlayedAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlaybackProgressRow> custom({
    Expression<String>? mediaId,
    Expression<int>? positionMs,
    Expression<bool>? completed,
    Expression<DateTime>? lastPlayedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (positionMs != null) 'position_ms': positionMs,
      if (completed != null) 'completed': completed,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackProgressCompanion copyWith({
    Value<String>? mediaId,
    Value<int>? positionMs,
    Value<bool>? completed,
    Value<DateTime>? lastPlayedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaybackProgressCompanion(
      mediaId: mediaId ?? this.mediaId,
      positionMs: positionMs ?? this.positionMs,
      completed: completed ?? this.completed,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackProgressCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('positionMs: $positionMs, ')
          ..write('completed: $completed, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTable extends UserPreferences
    with TableInfo<$UserPreferencesTable, UserPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncEligibleMeta = const VerificationMeta(
    'syncEligible',
  );
  @override
  late final GeneratedColumn<bool> syncEligible = GeneratedColumn<bool>(
    'sync_eligible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_eligible" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt, syncEligible];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_eligible')) {
      context.handle(
        _syncEligibleMeta,
        syncEligible.isAcceptableOrUnknown(
          data['sync_eligible']!,
          _syncEligibleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncEligible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_eligible'],
      )!,
    );
  }

  @override
  $UserPreferencesTable createAlias(String alias) {
    return $UserPreferencesTable(attachedDatabase, alias);
  }
}

class UserPreference extends DataClass implements Insertable<UserPreference> {
  final String key;
  final String value;
  final DateTime updatedAt;

  /// Whether this preference may sync to the account in Phase 6.
  final bool syncEligible;
  const UserPreference({
    required this.key,
    required this.value,
    required this.updatedAt,
    required this.syncEligible,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_eligible'] = Variable<bool>(syncEligible);
    return map;
  }

  UserPreferencesCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
      syncEligible: Value(syncEligible),
    );
  }

  factory UserPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncEligible: serializer.fromJson<bool>(json['syncEligible']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncEligible': serializer.toJson<bool>(syncEligible),
    };
  }

  UserPreference copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
    bool? syncEligible,
  }) => UserPreference(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
    syncEligible: syncEligible ?? this.syncEligible,
  );
  UserPreference copyWithCompanion(UserPreferencesCompanion data) {
    return UserPreference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncEligible: data.syncEligible.present
          ? data.syncEligible.value
          : this.syncEligible,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreference(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncEligible: $syncEligible')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt, syncEligible);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreference &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt &&
          other.syncEligible == this.syncEligible);
}

class UserPreferencesCompanion extends UpdateCompanion<UserPreference> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<bool> syncEligible;
  final Value<int> rowid;
  const UserPreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncEligible = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPreferencesCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.syncEligible = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<UserPreference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<bool>? syncEligible,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncEligible != null) 'sync_eligible': syncEligible,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<bool>? syncEligible,
    Value<int>? rowid,
  }) {
    return UserPreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      syncEligible: syncEligible ?? this.syncEligible,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncEligible.present) {
      map['sync_eligible'] = Variable<bool>(syncEligible.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncEligible: $syncEligible, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueEntriesTable extends QueueEntries
    with TableInfo<$QueueEntriesTable, QueueEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
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
  @override
  List<GeneratedColumn> get $columns => [entryId, mediaId, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  QueueEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueEntryRow(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $QueueEntriesTable createAlias(String alias) {
    return $QueueEntriesTable(attachedDatabase, alias);
  }
}

class QueueEntryRow extends DataClass implements Insertable<QueueEntryRow> {
  final String entryId;
  final String mediaId;
  final int orderIndex;
  const QueueEntryRow({
    required this.entryId,
    required this.mediaId,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['media_id'] = Variable<String>(mediaId);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  QueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return QueueEntriesCompanion(
      entryId: Value(entryId),
      mediaId: Value(mediaId),
      orderIndex: Value(orderIndex),
    );
  }

  factory QueueEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueEntryRow(
      entryId: serializer.fromJson<String>(json['entryId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'mediaId': serializer.toJson<String>(mediaId),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  QueueEntryRow copyWith({String? entryId, String? mediaId, int? orderIndex}) =>
      QueueEntryRow(
        entryId: entryId ?? this.entryId,
        mediaId: mediaId ?? this.mediaId,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  QueueEntryRow copyWithCompanion(QueueEntriesCompanion data) {
    return QueueEntryRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntryRow(')
          ..write('entryId: $entryId, ')
          ..write('mediaId: $mediaId, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, mediaId, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueEntryRow &&
          other.entryId == this.entryId &&
          other.mediaId == this.mediaId &&
          other.orderIndex == this.orderIndex);
}

class QueueEntriesCompanion extends UpdateCompanion<QueueEntryRow> {
  final Value<String> entryId;
  final Value<String> mediaId;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const QueueEntriesCompanion({
    this.entryId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueueEntriesCompanion.insert({
    required String entryId,
    required String mediaId,
    required int orderIndex,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       mediaId = Value(mediaId),
       orderIndex = Value(orderIndex);
  static Insertable<QueueEntryRow> custom({
    Expression<String>? entryId,
    Expression<String>? mediaId,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (mediaId != null) 'media_id': mediaId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueueEntriesCompanion copyWith({
    Value<String>? entryId,
    Value<String>? mediaId,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return QueueEntriesCompanion(
      entryId: entryId ?? this.entryId,
      mediaId: mediaId ?? this.mediaId,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueEntriesCompanion(')
          ..write('entryId: $entryId, ')
          ..write('mediaId: $mediaId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueStateTable extends QueueState
    with TableInfo<$QueueStateTable, QueueStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentEntryIdMeta = const VerificationMeta(
    'currentEntryId',
  );
  @override
  late final GeneratedColumn<String> currentEntryId = GeneratedColumn<String>(
    'current_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatModeMeta = const VerificationMeta(
    'repeatMode',
  );
  @override
  late final GeneratedColumn<String> repeatMode = GeneratedColumn<String>(
    'repeat_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('off'),
  );
  static const VerificationMeta _unshuffledJsonMeta = const VerificationMeta(
    'unshuffledJson',
  );
  @override
  late final GeneratedColumn<String> unshuffledJson = GeneratedColumn<String>(
    'unshuffled_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentEntryId,
    repeatMode,
    unshuffledJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_entry_id')) {
      context.handle(
        _currentEntryIdMeta,
        currentEntryId.isAcceptableOrUnknown(
          data['current_entry_id']!,
          _currentEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('repeat_mode')) {
      context.handle(
        _repeatModeMeta,
        repeatMode.isAcceptableOrUnknown(data['repeat_mode']!, _repeatModeMeta),
      );
    }
    if (data.containsKey('unshuffled_json')) {
      context.handle(
        _unshuffledJsonMeta,
        unshuffledJson.isAcceptableOrUnknown(
          data['unshuffled_json']!,
          _unshuffledJsonMeta,
        ),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueueStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_entry_id'],
      ),
      repeatMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_mode'],
      )!,
      unshuffledJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unshuffled_json'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QueueStateTable createAlias(String alias) {
    return $QueueStateTable(attachedDatabase, alias);
  }
}

class QueueStateRow extends DataClass implements Insertable<QueueStateRow> {
  final int id;
  final String? currentEntryId;
  final String repeatMode;

  /// JSON list of entry IDs in pre-shuffle order; null when not shuffled.
  final String? unshuffledJson;
  final DateTime updatedAt;
  const QueueStateRow({
    required this.id,
    this.currentEntryId,
    required this.repeatMode,
    this.unshuffledJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || currentEntryId != null) {
      map['current_entry_id'] = Variable<String>(currentEntryId);
    }
    map['repeat_mode'] = Variable<String>(repeatMode);
    if (!nullToAbsent || unshuffledJson != null) {
      map['unshuffled_json'] = Variable<String>(unshuffledJson);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QueueStateCompanion toCompanion(bool nullToAbsent) {
    return QueueStateCompanion(
      id: Value(id),
      currentEntryId: currentEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentEntryId),
      repeatMode: Value(repeatMode),
      unshuffledJson: unshuffledJson == null && nullToAbsent
          ? const Value.absent()
          : Value(unshuffledJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory QueueStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueStateRow(
      id: serializer.fromJson<int>(json['id']),
      currentEntryId: serializer.fromJson<String?>(json['currentEntryId']),
      repeatMode: serializer.fromJson<String>(json['repeatMode']),
      unshuffledJson: serializer.fromJson<String?>(json['unshuffledJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentEntryId': serializer.toJson<String?>(currentEntryId),
      'repeatMode': serializer.toJson<String>(repeatMode),
      'unshuffledJson': serializer.toJson<String?>(unshuffledJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QueueStateRow copyWith({
    int? id,
    Value<String?> currentEntryId = const Value.absent(),
    String? repeatMode,
    Value<String?> unshuffledJson = const Value.absent(),
    DateTime? updatedAt,
  }) => QueueStateRow(
    id: id ?? this.id,
    currentEntryId: currentEntryId.present
        ? currentEntryId.value
        : this.currentEntryId,
    repeatMode: repeatMode ?? this.repeatMode,
    unshuffledJson: unshuffledJson.present
        ? unshuffledJson.value
        : this.unshuffledJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QueueStateRow copyWithCompanion(QueueStateCompanion data) {
    return QueueStateRow(
      id: data.id.present ? data.id.value : this.id,
      currentEntryId: data.currentEntryId.present
          ? data.currentEntryId.value
          : this.currentEntryId,
      repeatMode: data.repeatMode.present
          ? data.repeatMode.value
          : this.repeatMode,
      unshuffledJson: data.unshuffledJson.present
          ? data.unshuffledJson.value
          : this.unshuffledJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueStateRow(')
          ..write('id: $id, ')
          ..write('currentEntryId: $currentEntryId, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('unshuffledJson: $unshuffledJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, currentEntryId, repeatMode, unshuffledJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueStateRow &&
          other.id == this.id &&
          other.currentEntryId == this.currentEntryId &&
          other.repeatMode == this.repeatMode &&
          other.unshuffledJson == this.unshuffledJson &&
          other.updatedAt == this.updatedAt);
}

class QueueStateCompanion extends UpdateCompanion<QueueStateRow> {
  final Value<int> id;
  final Value<String?> currentEntryId;
  final Value<String> repeatMode;
  final Value<String?> unshuffledJson;
  final Value<DateTime> updatedAt;
  const QueueStateCompanion({
    this.id = const Value.absent(),
    this.currentEntryId = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.unshuffledJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  QueueStateCompanion.insert({
    this.id = const Value.absent(),
    this.currentEntryId = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.unshuffledJson = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<QueueStateRow> custom({
    Expression<int>? id,
    Expression<String>? currentEntryId,
    Expression<String>? repeatMode,
    Expression<String>? unshuffledJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentEntryId != null) 'current_entry_id': currentEntryId,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (unshuffledJson != null) 'unshuffled_json': unshuffledJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  QueueStateCompanion copyWith({
    Value<int>? id,
    Value<String?>? currentEntryId,
    Value<String>? repeatMode,
    Value<String?>? unshuffledJson,
    Value<DateTime>? updatedAt,
  }) {
    return QueueStateCompanion(
      id: id ?? this.id,
      currentEntryId: currentEntryId ?? this.currentEntryId,
      repeatMode: repeatMode ?? this.repeatMode,
      unshuffledJson: unshuffledJson ?? this.unshuffledJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentEntryId.present) {
      map['current_entry_id'] = Variable<String>(currentEntryId.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<String>(repeatMode.value);
    }
    if (unshuffledJson.present) {
      map['unshuffled_json'] = Variable<String>(unshuffledJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueStateCompanion(')
          ..write('id: $id, ')
          ..write('currentEntryId: $currentEntryId, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('unshuffledJson: $unshuffledJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, PlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _ownerScopeMeta = const VerificationMeta(
    'ownerScope',
  );
  @override
  late final GeneratedColumn<String> ownerScope = GeneratedColumn<String>(
    'owner_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ownerScope,
    userId,
    createdAt,
    updatedAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_scope')) {
      context.handle(
        _ownerScopeMeta,
        ownerScope.isAcceptableOrUnknown(data['owner_scope']!, _ownerScopeMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ownerScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_scope'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class PlaylistRow extends DataClass implements Insertable<PlaylistRow> {
  final String id;
  final String name;

  /// 'local' for guest data; 'user' once synced to an account (Phase 6).
  final String ownerScope;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;
  const PlaylistRow({
    required this.id,
    required this.name,
    required this.ownerScope,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['owner_scope'] = Variable<String>(ownerScope);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      ownerScope: Value(ownerScope),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory PlaylistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerScope: serializer.fromJson<String>(json['ownerScope']),
      userId: serializer.fromJson<String?>(json['userId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'ownerScope': serializer.toJson<String>(ownerScope),
      'userId': serializer.toJson<String?>(userId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PlaylistRow copyWith({
    String? id,
    String? name,
    String? ownerScope,
    Value<String?> userId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
  }) => PlaylistRow(
    id: id ?? this.id,
    name: name ?? this.name,
    ownerScope: ownerScope ?? this.ownerScope,
    userId: userId.present ? userId.value : this.userId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  PlaylistRow copyWithCompanion(PlaylistsCompanion data) {
    return PlaylistRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerScope: data.ownerScope.present
          ? data.ownerScope.value
          : this.ownerScope,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerScope: $ownerScope, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    ownerScope,
    userId,
    createdAt,
    updatedAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerScope == this.ownerScope &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sortOrder == this.sortOrder);
}

class PlaylistsCompanion extends UpdateCompanion<PlaylistRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> ownerScope;
  final Value<String?> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerScope = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String name,
    this.ownerScope = const Value.absent(),
    this.userId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlaylistRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerScope,
    Expression<String>? userId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerScope != null) 'owner_scope': ownerScope,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? ownerScope,
    Value<String?>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerScope: ownerScope ?? this.ownerScope,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ownerScope.present) {
      map['owner_scope'] = Variable<String>(ownerScope.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerScope: $ownerScope, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistEntriesTable extends PlaylistEntries
    with TableInfo<$PlaylistEntriesTable, PlaylistEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    mediaId,
    orderIndex,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $PlaylistEntriesTable createAlias(String alias) {
    return $PlaylistEntriesTable(attachedDatabase, alias);
  }
}

class PlaylistEntryRow extends DataClass
    implements Insertable<PlaylistEntryRow> {
  final String id;
  final String playlistId;
  final String mediaId;
  final int orderIndex;
  final DateTime addedAt;
  const PlaylistEntryRow({
    required this.id,
    required this.playlistId,
    required this.mediaId,
    required this.orderIndex,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['media_id'] = Variable<String>(mediaId);
    map['order_index'] = Variable<int>(orderIndex);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  PlaylistEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlaylistEntriesCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      mediaId: Value(mediaId),
      orderIndex: Value(orderIndex),
      addedAt: Value(addedAt),
    );
  }

  factory PlaylistEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistEntryRow(
      id: serializer.fromJson<String>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'playlistId': serializer.toJson<String>(playlistId),
      'mediaId': serializer.toJson<String>(mediaId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  PlaylistEntryRow copyWith({
    String? id,
    String? playlistId,
    String? mediaId,
    int? orderIndex,
    DateTime? addedAt,
  }) => PlaylistEntryRow(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    mediaId: mediaId ?? this.mediaId,
    orderIndex: orderIndex ?? this.orderIndex,
    addedAt: addedAt ?? this.addedAt,
  );
  PlaylistEntryRow copyWithCompanion(PlaylistEntriesCompanion data) {
    return PlaylistEntryRow(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntryRow(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('mediaId: $mediaId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playlistId, mediaId, orderIndex, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistEntryRow &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.mediaId == this.mediaId &&
          other.orderIndex == this.orderIndex &&
          other.addedAt == this.addedAt);
}

class PlaylistEntriesCompanion extends UpdateCompanion<PlaylistEntryRow> {
  final Value<String> id;
  final Value<String> playlistId;
  final Value<String> mediaId;
  final Value<int> orderIndex;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const PlaylistEntriesCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistEntriesCompanion.insert({
    required String id,
    required String playlistId,
    required String mediaId,
    required int orderIndex,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       playlistId = Value(playlistId),
       mediaId = Value(mediaId),
       orderIndex = Value(orderIndex),
       addedAt = Value(addedAt);
  static Insertable<PlaylistEntryRow> custom({
    Expression<String>? id,
    Expression<String>? playlistId,
    Expression<String>? mediaId,
    Expression<int>? orderIndex,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (mediaId != null) 'media_id': mediaId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? playlistId,
    Value<String>? mediaId,
    Value<int>? orderIndex,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return PlaylistEntriesCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      mediaId: mediaId ?? this.mediaId,
      orderIndex: orderIndex ?? this.orderIndex,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntriesCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('mediaId: $mediaId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [mediaId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final String mediaId;
  final DateTime createdAt;
  const FavoriteRow({required this.mediaId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      mediaId: Value(mediaId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteRow copyWith({String? mediaId, DateTime? createdAt}) => FavoriteRow(
    mediaId: mediaId ?? this.mediaId,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteRow copyWithCompanion(FavoritesCompanion data) {
    return FavoriteRow(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('mediaId: $mediaId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.mediaId == this.mediaId &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<String> mediaId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.mediaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String mediaId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       createdAt = Value(createdAt);
  static Insertable<FavoriteRow> custom({
    Expression<String>? mediaId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? mediaId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      mediaId: mediaId ?? this.mediaId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $HiddenFoldersTable hiddenFolders = $HiddenFoldersTable(this);
  late final $SyncTombstonesTable syncTombstones = $SyncTombstonesTable(this);
  late final $SyncMetadataTable syncMetadata = $SyncMetadataTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $PlaybackProgressTable playbackProgress = $PlaybackProgressTable(
    this,
  );
  late final $UserPreferencesTable userPreferences = $UserPreferencesTable(
    this,
  );
  late final $QueueEntriesTable queueEntries = $QueueEntriesTable(this);
  late final $QueueStateTable queueState = $QueueStateTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistEntriesTable playlistEntries = $PlaylistEntriesTable(
    this,
  );
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final Index downloadsSource = Index(
    'downloads_source',
    'CREATE INDEX downloads_source ON downloads (source, source_id)',
  );
  late final Index mediaItemsKindTitle = Index(
    'media_items_kind_title',
    'CREATE INDEX media_items_kind_title ON media_items (kind, title)',
  );
  late final Index mediaItemsKindAdded = Index(
    'media_items_kind_added',
    'CREATE INDEX media_items_kind_added ON media_items (kind, added_at)',
  );
  late final Index mediaItemsFolder = Index(
    'media_items_folder',
    'CREATE INDEX media_items_folder ON media_items (kind, folder)',
  );
  late final Index playbackProgressLastPlayed = Index(
    'playback_progress_last_played',
    'CREATE INDEX playback_progress_last_played ON playback_progress (last_played_at)',
  );
  late final Index playlistEntriesOrder = Index(
    'playlist_entries_order',
    'CREATE INDEX playlist_entries_order ON playlist_entries (playlist_id, order_index)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    downloads,
    hiddenFolders,
    syncTombstones,
    syncMetadata,
    mediaItems,
    playbackProgress,
    userPreferences,
    queueEntries,
    queueState,
    playlists,
    playlistEntries,
    favorites,
    downloadsSource,
    mediaItemsKindTitle,
    mediaItemsKindAdded,
    mediaItemsFolder,
    playbackProgressLastPlayed,
    playlistEntriesOrder,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_progress', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('queue_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String id,
  required String taskId,
  required String source,
  required String sourceId,
  required String url,
  required String title,
  Value<String?> artist,
  required MediaKind kind,
  required String fileName,
  required DownloadStatus status,
  Value<double> progress,
  Value<int?> totalBytes,
  Value<String?> error,
  Value<String?> savedPath,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> id,
  Value<String> taskId,
  Value<String> source,
  Value<String> sourceId,
  Value<String> url,
  Value<String> title,
  Value<String?> artist,
  Value<MediaKind> kind,
  Value<String> fileName,
  Value<DownloadStatus> status,
  Value<double> progress,
  Value<int?> totalBytes,
  Value<String?> error,
  Value<String?> savedPath,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
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

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaKind, MediaKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DownloadStatus, DownloadStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savedPath => $composableBuilder(
    column: $table.savedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
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

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedPath => $composableBuilder(
    column: $table.savedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get savedPath =>
      $composableBuilder(column: $table.savedPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTable,
          DownloadRow,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (
            DownloadRow,
            BaseReferences<_$AppDatabase, $DownloadsTable, DownloadRow>,
          ),
          DownloadRow,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<MediaKind> kind = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<DownloadStatus> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> savedPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                id: id,
                taskId: taskId,
                source: source,
                sourceId: sourceId,
                url: url,
                title: title,
                artist: artist,
                kind: kind,
                fileName: fileName,
                status: status,
                progress: progress,
                totalBytes: totalBytes,
                error: error,
                savedPath: savedPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String source,
                required String sourceId,
                required String url,
                required String title,
                Value<String?> artist = const Value.absent(),
                required MediaKind kind,
                required String fileName,
                required DownloadStatus status,
                Value<double> progress = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> savedPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                id: id,
                taskId: taskId,
                source: source,
                sourceId: sourceId,
                url: url,
                title: title,
                artist: artist,
                kind: kind,
                fileName: fileName,
                status: status,
                progress: progress,
                totalBytes: totalBytes,
                error: error,
                savedPath: savedPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadsTable, DownloadRow>(table),
                  BaseReferences<_$AppDatabase, $DownloadsTable, DownloadRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTable,
      DownloadRow,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (
        DownloadRow,
        BaseReferences<_$AppDatabase, $DownloadsTable, DownloadRow>,
      ),
      DownloadRow,
      PrefetchHooks Function()
    >;
typedef $$HiddenFoldersTableCreateCompanionBuilder =
    HiddenFoldersCompanion Function({
      required String folder,
      required DateTime hiddenAt,
      Value<int> rowid,
    });
typedef $$HiddenFoldersTableUpdateCompanionBuilder =
    HiddenFoldersCompanion Function({
      Value<String> folder,
      Value<DateTime> hiddenAt,
      Value<int> rowid,
    });

class $$HiddenFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $HiddenFoldersTable> {
  $$HiddenFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HiddenFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $HiddenFoldersTable> {
  $$HiddenFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get hiddenAt => $composableBuilder(
    column: $table.hiddenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HiddenFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $HiddenFoldersTable> {
  $$HiddenFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<DateTime> get hiddenAt =>
      $composableBuilder(column: $table.hiddenAt, builder: (column) => column);
}

class $$HiddenFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HiddenFoldersTable,
          HiddenFolderRow,
          $$HiddenFoldersTableFilterComposer,
          $$HiddenFoldersTableOrderingComposer,
          $$HiddenFoldersTableAnnotationComposer,
          $$HiddenFoldersTableCreateCompanionBuilder,
          $$HiddenFoldersTableUpdateCompanionBuilder,
          (
            HiddenFolderRow,
            BaseReferences<_$AppDatabase, $HiddenFoldersTable, HiddenFolderRow>,
          ),
          HiddenFolderRow,
          PrefetchHooks Function()
        > {
  $$HiddenFoldersTableTableManager(_$AppDatabase db, $HiddenFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HiddenFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HiddenFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HiddenFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> folder = const Value.absent(),
                Value<DateTime> hiddenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HiddenFoldersCompanion(
                folder: folder,
                hiddenAt: hiddenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String folder,
                required DateTime hiddenAt,
                Value<int> rowid = const Value.absent(),
              }) => HiddenFoldersCompanion.insert(
                folder: folder,
                hiddenAt: hiddenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HiddenFoldersTable, HiddenFolderRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HiddenFoldersTable,
                    HiddenFolderRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HiddenFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HiddenFoldersTable,
      HiddenFolderRow,
      $$HiddenFoldersTableFilterComposer,
      $$HiddenFoldersTableOrderingComposer,
      $$HiddenFoldersTableAnnotationComposer,
      $$HiddenFoldersTableCreateCompanionBuilder,
      $$HiddenFoldersTableUpdateCompanionBuilder,
      (
        HiddenFolderRow,
        BaseReferences<_$AppDatabase, $HiddenFoldersTable, HiddenFolderRow>,
      ),
      HiddenFolderRow,
      PrefetchHooks Function()
    >;
typedef $$SyncTombstonesTableCreateCompanionBuilder =
    SyncTombstonesCompanion Function({
      required String kind,
      required String recordId,
      required String userId,
      required DateTime deletedAt,
      Value<int> rowid,
    });
typedef $$SyncTombstonesTableUpdateCompanionBuilder =
    SyncTombstonesCompanion Function({
      Value<String> kind,
      Value<String> recordId,
      Value<String> userId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$SyncTombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncTombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncTombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SyncTombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncTombstonesTable,
          SyncTombstoneRow,
          $$SyncTombstonesTableFilterComposer,
          $$SyncTombstonesTableOrderingComposer,
          $$SyncTombstonesTableAnnotationComposer,
          $$SyncTombstonesTableCreateCompanionBuilder,
          $$SyncTombstonesTableUpdateCompanionBuilder,
          (
            SyncTombstoneRow,
            BaseReferences<
              _$AppDatabase,
              $SyncTombstonesTable,
              SyncTombstoneRow
            >,
          ),
          SyncTombstoneRow,
          PrefetchHooks Function()
        > {
  $$SyncTombstonesTableTableManager(
    _$AppDatabase db,
    $SyncTombstonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncTombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncTombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncTombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion(
                kind: kind,
                recordId: recordId,
                userId: userId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String recordId,
                required String userId,
                required DateTime deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion.insert(
                kind: kind,
                recordId: recordId,
                userId: userId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncTombstonesTable, SyncTombstoneRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncTombstonesTable,
                    SyncTombstoneRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncTombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncTombstonesTable,
      SyncTombstoneRow,
      $$SyncTombstonesTableFilterComposer,
      $$SyncTombstonesTableOrderingComposer,
      $$SyncTombstonesTableAnnotationComposer,
      $$SyncTombstonesTableCreateCompanionBuilder,
      $$SyncTombstonesTableUpdateCompanionBuilder,
      (
        SyncTombstoneRow,
        BaseReferences<_$AppDatabase, $SyncTombstonesTable, SyncTombstoneRow>,
      ),
      SyncTombstoneRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataTableCreateCompanionBuilder =
    SyncMetadataCompanion Function({
      required String userId,
      Value<DateTime?> lastSyncAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableUpdateCompanionBuilder =
    SyncMetadataCompanion Function({
      Value<String> userId,
      Value<DateTime?> lastSyncAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTable> {
  $$SyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTable,
          SyncMetadataRow,
          $$SyncMetadataTableFilterComposer,
          $$SyncMetadataTableOrderingComposer,
          $$SyncMetadataTableAnnotationComposer,
          $$SyncMetadataTableCreateCompanionBuilder,
          $$SyncMetadataTableUpdateCompanionBuilder,
          (
            SyncMetadataRow,
            BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataRow>,
          ),
          SyncMetadataRow,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableManager(_$AppDatabase db, $SyncMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion(
                userId: userId,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataCompanion.insert(
                userId: userId,
                lastSyncAt: lastSyncAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetadataTable, SyncMetadataRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncMetadataTable,
                    SyncMetadataRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTable,
      SyncMetadataRow,
      $$SyncMetadataTableFilterComposer,
      $$SyncMetadataTableOrderingComposer,
      $$SyncMetadataTableAnnotationComposer,
      $$SyncMetadataTableCreateCompanionBuilder,
      $$SyncMetadataTableUpdateCompanionBuilder,
      (
        SyncMetadataRow,
        BaseReferences<_$AppDatabase, $SyncMetadataTable, SyncMetadataRow>,
      ),
      SyncMetadataRow,
      PrefetchHooks Function()
    >;
typedef $$MediaItemsTableCreateCompanionBuilder = MediaItemsCompanion Function({
  required String id,
  required MediaKind kind,
  required String title,
  Value<String?> displayName,
  required String locator,
  required MediaOrigin origin,
  Value<int?> storeId,
  Value<String?> mimeType,
  Value<int?> durationMs,
  Value<int?> sizeBytes,
  Value<String?> folder,
  Value<String?> artist,
  Value<String?> album,
  Value<int?> width,
  Value<int?> height,
  Value<DateTime?> modifiedAt,
  required DateTime addedAt,
  Value<bool> available,
  Value<int> lastSeenScan,
  Value<int> rowid,
});
typedef $$MediaItemsTableUpdateCompanionBuilder = MediaItemsCompanion Function({
  Value<String> id,
  Value<MediaKind> kind,
  Value<String> title,
  Value<String?> displayName,
  Value<String> locator,
  Value<MediaOrigin> origin,
  Value<int?> storeId,
  Value<String?> mimeType,
  Value<int?> durationMs,
  Value<int?> sizeBytes,
  Value<String?> folder,
  Value<String?> artist,
  Value<String?> album,
  Value<int?> width,
  Value<int?> height,
  Value<DateTime?> modifiedAt,
  Value<DateTime> addedAt,
  Value<bool> available,
  Value<int> lastSeenScan,
  Value<int> rowid,
});

final class $$MediaItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaItemsTable, LibraryItem> {
  $$MediaItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaybackProgressTable, List<PlaybackProgressRow>>
  _playbackProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playbackProgress,
    aliasName: 'media_items__id__playback_progress__media_id',
  );

  $$PlaybackProgressTableProcessedTableManager get playbackProgressRefs {
    final manager = $$PlaybackProgressTableTableManager(
      $_db,
      $_db.playbackProgress,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QueueEntriesTable, List<QueueEntryRow>>
  _queueEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.queueEntries,
    aliasName: 'media_items__id__queue_entries__media_id',
  );

  $$QueueEntriesTableProcessedTableManager get queueEntriesRefs {
    final manager = $$QueueEntriesTableTableManager(
      $_db,
      $_db.queueEntries,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_queueEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaylistEntriesTable, List<PlaylistEntryRow>>
  _playlistEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistEntries,
    aliasName: 'media_items__id__playlist_entries__media_id',
  );

  $$PlaylistEntriesTableProcessedTableManager get playlistEntriesRefs {
    final manager = $$PlaylistEntriesTableTableManager(
      $_db,
      $_db.playlistEntries,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<FavoriteRow>>
  _favoritesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: 'media_items__id__favorites__media_id',
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<MediaKind, MediaKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaOrigin, MediaOrigin, String> get origin =>
      $composableBuilder(
        column: $table.origin,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenScan => $composableBuilder(
    column: $table.lastSeenScan,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playbackProgressRefs(
    Expression<bool> Function($$PlaybackProgressTableFilterComposer f) f,
  ) {
    final $$PlaybackProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackProgress,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackProgressTableFilterComposer(
            $db: $db,
            $table: $db.playbackProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> queueEntriesRefs(
    Expression<bool> Function($$QueueEntriesTableFilterComposer f) f,
  ) {
    final $$QueueEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queueEntries,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueEntriesTableFilterComposer(
            $db: $db,
            $table: $db.queueEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playlistEntriesRefs(
    Expression<bool> Function($$PlaylistEntriesTableFilterComposer f) f,
  ) {
    final $$PlaylistEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableFilterComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get available => $composableBuilder(
    column: $table.available,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenScan => $composableBuilder(
    column: $table.lastSeenScan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locator =>
      $composableBuilder(column: $table.locator, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<bool> get available =>
      $composableBuilder(column: $table.available, builder: (column) => column);

  GeneratedColumn<int> get lastSeenScan => $composableBuilder(
    column: $table.lastSeenScan,
    builder: (column) => column,
  );

  Expression<T> playbackProgressRefs<T extends Object>(
    Expression<T> Function($$PlaybackProgressTableAnnotationComposer a) f,
  ) {
    final $$PlaybackProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackProgress,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.playbackProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> queueEntriesRefs<T extends Object>(
    Expression<T> Function($$QueueEntriesTableAnnotationComposer a) f,
  ) {
    final $$QueueEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.queueEntries,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QueueEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.queueEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playlistEntriesRefs<T extends Object>(
    Expression<T> Function($$PlaylistEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlaylistEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTable,
          LibraryItem,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (LibraryItem, $$MediaItemsTableReferences),
          LibraryItem,
          PrefetchHooks Function({
            bool playbackProgressRefs,
            bool queueEntriesRefs,
            bool playlistEntriesRefs,
            bool favoritesRefs,
          })
        > {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<MediaKind> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String> locator = const Value.absent(),
                Value<MediaOrigin> origin = const Value.absent(),
                Value<int?> storeId = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<bool> available = const Value.absent(),
                Value<int> lastSeenScan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                kind: kind,
                title: title,
                displayName: displayName,
                locator: locator,
                origin: origin,
                storeId: storeId,
                mimeType: mimeType,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                folder: folder,
                artist: artist,
                album: album,
                width: width,
                height: height,
                modifiedAt: modifiedAt,
                addedAt: addedAt,
                available: available,
                lastSeenScan: lastSeenScan,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required MediaKind kind,
                required String title,
                Value<String?> displayName = const Value.absent(),
                required String locator,
                required MediaOrigin origin,
                Value<int?> storeId = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                required DateTime addedAt,
                Value<bool> available = const Value.absent(),
                Value<int> lastSeenScan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                kind: kind,
                title: title,
                displayName: displayName,
                locator: locator,
                origin: origin,
                storeId: storeId,
                mimeType: mimeType,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                folder: folder,
                artist: artist,
                album: album,
                width: width,
                height: height,
                modifiedAt: modifiedAt,
                addedAt: addedAt,
                available: available,
                lastSeenScan: lastSeenScan,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaItemsTable, LibraryItem>(table),
                  $$MediaItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                playbackProgressRefs = false,
                queueEntriesRefs = false,
                playlistEntriesRefs = false,
                favoritesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playbackProgressRefs) db.playbackProgress,
                    if (queueEntriesRefs) db.queueEntries,
                    if (playlistEntriesRefs) db.playlistEntries,
                    if (favoritesRefs) db.favorites,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playbackProgressRefs)
                        await $_getPrefetchedDataByColumns<
                          LibraryItem,
                          $MediaItemsTable,
                          PlaybackProgressRow,
                          $PlaybackProgressTable
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._playbackProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackProgressRefs,
                          currentColumn: 'id',
                          referencedColumn: 'media_id',
                          typedResults: items,
                        ),
                      if (queueEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          LibraryItem,
                          $MediaItemsTable,
                          QueueEntryRow,
                          $QueueEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._queueEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).queueEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'media_id',
                          typedResults: items,
                        ),
                      if (playlistEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          LibraryItem,
                          $MediaItemsTable,
                          PlaylistEntryRow,
                          $PlaylistEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._playlistEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'media_id',
                          typedResults: items,
                        ),
                      if (favoritesRefs)
                        await $_getPrefetchedDataByColumns<
                          LibraryItem,
                          $MediaItemsTable,
                          FavoriteRow,
                          $FavoritesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'media_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTable,
      LibraryItem,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (LibraryItem, $$MediaItemsTableReferences),
      LibraryItem,
      PrefetchHooks Function({
        bool playbackProgressRefs,
        bool queueEntriesRefs,
        bool playlistEntriesRefs,
        bool favoritesRefs,
      })
    >;
typedef $$PlaybackProgressTableCreateCompanionBuilder =
    PlaybackProgressCompanion Function({
      required String mediaId,
      required int positionMs,
      Value<bool> completed,
      required DateTime lastPlayedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlaybackProgressTableUpdateCompanionBuilder =
    PlaybackProgressCompanion Function({
      Value<String> mediaId,
      Value<int> positionMs,
      Value<bool> completed,
      Value<DateTime> lastPlayedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PlaybackProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaybackProgressTable,
          PlaybackProgressRow
        > {
  $$PlaybackProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MediaItemsTable _mediaIdTable(_$AppDatabase db) =>
      db.mediaItems.createAlias('playback_progress__media_id__media_items__id');

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaybackProgressTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackProgressTable> {
  $$PlaybackProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackProgressTable> {
  $$PlaybackProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackProgressTable> {
  $$PlaybackProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackProgressTable,
          PlaybackProgressRow,
          $$PlaybackProgressTableFilterComposer,
          $$PlaybackProgressTableOrderingComposer,
          $$PlaybackProgressTableAnnotationComposer,
          $$PlaybackProgressTableCreateCompanionBuilder,
          $$PlaybackProgressTableUpdateCompanionBuilder,
          (PlaybackProgressRow, $$PlaybackProgressTableReferences),
          PlaybackProgressRow,
          PrefetchHooks Function({bool mediaId})
        > {
  $$PlaybackProgressTableTableManager(
    _$AppDatabase db,
    $PlaybackProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mediaId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime> lastPlayedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackProgressCompanion(
                mediaId: mediaId,
                positionMs: positionMs,
                completed: completed,
                lastPlayedAt: lastPlayedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mediaId,
                required int positionMs,
                Value<bool> completed = const Value.absent(),
                required DateTime lastPlayedAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackProgressCompanion.insert(
                mediaId: mediaId,
                positionMs: positionMs,
                completed: completed,
                lastPlayedAt: lastPlayedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaybackProgressTable, PlaybackProgressRow>(
                    table,
                  ),
                  $$PlaybackProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mediaId,
                        referencedTable: $$PlaybackProgressTableReferences
                            ._mediaIdTable(db),
                        referencedColumn: $$PlaybackProgressTableReferences
                            ._mediaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaybackProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackProgressTable,
      PlaybackProgressRow,
      $$PlaybackProgressTableFilterComposer,
      $$PlaybackProgressTableOrderingComposer,
      $$PlaybackProgressTableAnnotationComposer,
      $$PlaybackProgressTableCreateCompanionBuilder,
      $$PlaybackProgressTableUpdateCompanionBuilder,
      (PlaybackProgressRow, $$PlaybackProgressTableReferences),
      PlaybackProgressRow,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$UserPreferencesTableCreateCompanionBuilder =
    UserPreferencesCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<bool> syncEligible,
      Value<int> rowid,
    });
typedef $$UserPreferencesTableUpdateCompanionBuilder =
    UserPreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<bool> syncEligible,
      Value<int> rowid,
    });

class $$UserPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncEligible => $composableBuilder(
    column: $table.syncEligible,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncEligible => $composableBuilder(
    column: $table.syncEligible,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTable> {
  $$UserPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get syncEligible => $composableBuilder(
    column: $table.syncEligible,
    builder: (column) => column,
  );
}

class $$UserPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTable,
          UserPreference,
          $$UserPreferencesTableFilterComposer,
          $$UserPreferencesTableOrderingComposer,
          $$UserPreferencesTableAnnotationComposer,
          $$UserPreferencesTableCreateCompanionBuilder,
          $$UserPreferencesTableUpdateCompanionBuilder,
          (
            UserPreference,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTable,
              UserPreference
            >,
          ),
          UserPreference,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> syncEligible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                syncEligible: syncEligible,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<bool> syncEligible = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPreferencesCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                syncEligible: syncEligible,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserPreferencesTable, UserPreference>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserPreferencesTable,
                    UserPreference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTable,
      UserPreference,
      $$UserPreferencesTableFilterComposer,
      $$UserPreferencesTableOrderingComposer,
      $$UserPreferencesTableAnnotationComposer,
      $$UserPreferencesTableCreateCompanionBuilder,
      $$UserPreferencesTableUpdateCompanionBuilder,
      (
        UserPreference,
        BaseReferences<_$AppDatabase, $UserPreferencesTable, UserPreference>,
      ),
      UserPreference,
      PrefetchHooks Function()
    >;
typedef $$QueueEntriesTableCreateCompanionBuilder =
    QueueEntriesCompanion Function({
      required String entryId,
      required String mediaId,
      required int orderIndex,
      Value<int> rowid,
    });
typedef $$QueueEntriesTableUpdateCompanionBuilder =
    QueueEntriesCompanion Function({
      Value<String> entryId,
      Value<String> mediaId,
      Value<int> orderIndex,
      Value<int> rowid,
    });

final class $$QueueEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $QueueEntriesTable, QueueEntryRow> {
  $$QueueEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaItemsTable _mediaIdTable(_$AppDatabase db) =>
      db.mediaItems.createAlias('queue_entries__media_id__media_items__id');

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QueueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueEntriesTable> {
  $$QueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QueueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueEntriesTable,
          QueueEntryRow,
          $$QueueEntriesTableFilterComposer,
          $$QueueEntriesTableOrderingComposer,
          $$QueueEntriesTableAnnotationComposer,
          $$QueueEntriesTableCreateCompanionBuilder,
          $$QueueEntriesTableUpdateCompanionBuilder,
          (QueueEntryRow, $$QueueEntriesTableReferences),
          QueueEntryRow,
          PrefetchHooks Function({bool mediaId})
        > {
  $$QueueEntriesTableTableManager(_$AppDatabase db, $QueueEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueEntriesCompanion(
                entryId: entryId,
                mediaId: mediaId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String mediaId,
                required int orderIndex,
                Value<int> rowid = const Value.absent(),
              }) => QueueEntriesCompanion.insert(
                entryId: entryId,
                mediaId: mediaId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueueEntriesTable, QueueEntryRow>(table),
                  $$QueueEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mediaId,
                        referencedTable: $$QueueEntriesTableReferences
                            ._mediaIdTable(db),
                        referencedColumn: $$QueueEntriesTableReferences
                            ._mediaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QueueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueEntriesTable,
      QueueEntryRow,
      $$QueueEntriesTableFilterComposer,
      $$QueueEntriesTableOrderingComposer,
      $$QueueEntriesTableAnnotationComposer,
      $$QueueEntriesTableCreateCompanionBuilder,
      $$QueueEntriesTableUpdateCompanionBuilder,
      (QueueEntryRow, $$QueueEntriesTableReferences),
      QueueEntryRow,
      PrefetchHooks Function({bool mediaId})
    >;
typedef $$QueueStateTableCreateCompanionBuilder = QueueStateCompanion Function({
  Value<int> id,
  Value<String?> currentEntryId,
  Value<String> repeatMode,
  Value<String?> unshuffledJson,
  required DateTime updatedAt,
});
typedef $$QueueStateTableUpdateCompanionBuilder = QueueStateCompanion Function({
  Value<int> id,
  Value<String?> currentEntryId,
  Value<String> repeatMode,
  Value<String?> unshuffledJson,
  Value<DateTime> updatedAt,
});

class $$QueueStateTableFilterComposer
    extends Composer<_$AppDatabase, $QueueStateTable> {
  $$QueueStateTableFilterComposer({
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

  ColumnFilters<String> get currentEntryId => $composableBuilder(
    column: $table.currentEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unshuffledJson => $composableBuilder(
    column: $table.unshuffledJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueStateTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueStateTable> {
  $$QueueStateTableOrderingComposer({
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

  ColumnOrderings<String> get currentEntryId => $composableBuilder(
    column: $table.currentEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unshuffledJson => $composableBuilder(
    column: $table.unshuffledJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueStateTable> {
  $$QueueStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currentEntryId => $composableBuilder(
    column: $table.currentEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unshuffledJson => $composableBuilder(
    column: $table.unshuffledJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QueueStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueStateTable,
          QueueStateRow,
          $$QueueStateTableFilterComposer,
          $$QueueStateTableOrderingComposer,
          $$QueueStateTableAnnotationComposer,
          $$QueueStateTableCreateCompanionBuilder,
          $$QueueStateTableUpdateCompanionBuilder,
          (
            QueueStateRow,
            BaseReferences<_$AppDatabase, $QueueStateTable, QueueStateRow>,
          ),
          QueueStateRow,
          PrefetchHooks Function()
        > {
  $$QueueStateTableTableManager(_$AppDatabase db, $QueueStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> currentEntryId = const Value.absent(),
                Value<String> repeatMode = const Value.absent(),
                Value<String?> unshuffledJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => QueueStateCompanion(
                id: id,
                currentEntryId: currentEntryId,
                repeatMode: repeatMode,
                unshuffledJson: unshuffledJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> currentEntryId = const Value.absent(),
                Value<String> repeatMode = const Value.absent(),
                Value<String?> unshuffledJson = const Value.absent(),
                required DateTime updatedAt,
              }) => QueueStateCompanion.insert(
                id: id,
                currentEntryId: currentEntryId,
                repeatMode: repeatMode,
                unshuffledJson: unshuffledJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueueStateTable, QueueStateRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $QueueStateTable,
                    QueueStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueStateTable,
      QueueStateRow,
      $$QueueStateTableFilterComposer,
      $$QueueStateTableOrderingComposer,
      $$QueueStateTableAnnotationComposer,
      $$QueueStateTableCreateCompanionBuilder,
      $$QueueStateTableUpdateCompanionBuilder,
      (
        QueueStateRow,
        BaseReferences<_$AppDatabase, $QueueStateTable, QueueStateRow>,
      ),
      QueueStateRow,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  required String id,
  required String name,
  Value<String> ownerScope,
  Value<String?> userId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> ownerScope,
  Value<String?> userId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, PlaylistRow> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistEntriesTable, List<PlaylistEntryRow>>
  _playlistEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistEntries,
    aliasName: 'playlists__id__playlist_entries__playlist_id',
  );

  $$PlaylistEntriesTableProcessedTableManager get playlistEntriesRefs {
    final manager = $$PlaylistEntriesTableTableManager(
      $_db,
      $_db.playlistEntries,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerScope => $composableBuilder(
    column: $table.ownerScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistEntriesRefs(
    Expression<bool> Function($$PlaylistEntriesTableFilterComposer f) f,
  ) {
    final $$PlaylistEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableFilterComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerScope => $composableBuilder(
    column: $table.ownerScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ownerScope => $composableBuilder(
    column: $table.ownerScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> playlistEntriesRefs<T extends Object>(
    Expression<T> Function($$PlaylistEntriesTableAnnotationComposer a) f,
  ) {
    final $$PlaylistEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistEntries,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTable,
          PlaylistRow,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (PlaylistRow, $$PlaylistsTableReferences),
          PlaylistRow,
          PrefetchHooks Function({bool playlistEntriesRefs})
        > {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ownerScope = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                ownerScope: ownerScope,
                userId: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> ownerScope = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                ownerScope: ownerScope,
                userId: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, PlaylistRow>(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistEntriesRefs) db.playlistEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      PlaylistRow,
                      $PlaylistsTable,
                      PlaylistEntryRow,
                      $PlaylistEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableReferences
                          ._playlistEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'playlist_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTable,
      PlaylistRow,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (PlaylistRow, $$PlaylistsTableReferences),
      PlaylistRow,
      PrefetchHooks Function({bool playlistEntriesRefs})
    >;
typedef $$PlaylistEntriesTableCreateCompanionBuilder =
    PlaylistEntriesCompanion Function({
      required String id,
      required String playlistId,
      required String mediaId,
      required int orderIndex,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$PlaylistEntriesTableUpdateCompanionBuilder =
    PlaylistEntriesCompanion Function({
      Value<String> id,
      Value<String> playlistId,
      Value<String> mediaId,
      Value<int> orderIndex,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$PlaylistEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $PlaylistEntriesTable, PlaylistEntryRow> {
  $$PlaylistEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('playlist_entries__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MediaItemsTable _mediaIdTable(_$AppDatabase db) =>
      db.mediaItems.createAlias('playlist_entries__media_id__media_items__id');

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableFilterComposer({
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

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistEntriesTable> {
  $$PlaylistEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistEntriesTable,
          PlaylistEntryRow,
          $$PlaylistEntriesTableFilterComposer,
          $$PlaylistEntriesTableOrderingComposer,
          $$PlaylistEntriesTableAnnotationComposer,
          $$PlaylistEntriesTableCreateCompanionBuilder,
          $$PlaylistEntriesTableUpdateCompanionBuilder,
          (PlaylistEntryRow, $$PlaylistEntriesTableReferences),
          PlaylistEntryRow,
          PrefetchHooks Function({bool playlistId, bool mediaId})
        > {
  $$PlaylistEntriesTableTableManager(
    _$AppDatabase db,
    $PlaylistEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistEntriesCompanion(
                id: id,
                playlistId: playlistId,
                mediaId: mediaId,
                orderIndex: orderIndex,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String playlistId,
                required String mediaId,
                required int orderIndex,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistEntriesCompanion.insert(
                id: id,
                playlistId: playlistId,
                mediaId: mediaId,
                orderIndex: orderIndex,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistEntriesTable, PlaylistEntryRow>(table),
                  $$PlaylistEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: $$PlaylistEntriesTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: $$PlaylistEntriesTableReferences
                            ._playlistIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (mediaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mediaId,
                        referencedTable: $$PlaylistEntriesTableReferences
                            ._mediaIdTable(db),
                        referencedColumn: $$PlaylistEntriesTableReferences
                            ._mediaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistEntriesTable,
      PlaylistEntryRow,
      $$PlaylistEntriesTableFilterComposer,
      $$PlaylistEntriesTableOrderingComposer,
      $$PlaylistEntriesTableAnnotationComposer,
      $$PlaylistEntriesTableCreateCompanionBuilder,
      $$PlaylistEntriesTableUpdateCompanionBuilder,
      (PlaylistEntryRow, $$PlaylistEntriesTableReferences),
      PlaylistEntryRow,
      PrefetchHooks Function({bool playlistId, bool mediaId})
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  required String mediaId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<String> mediaId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$FavoritesTableReferences
    extends BaseReferences<_$AppDatabase, $FavoritesTable, FavoriteRow> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaItemsTable _mediaIdTable(_$AppDatabase db) =>
      db.mediaItems.createAlias('favorites__media_id__media_items__id');

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          FavoriteRow,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (FavoriteRow, $$FavoritesTableReferences),
          FavoriteRow,
          PrefetchHooks Function({bool mediaId})
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mediaId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                mediaId: mediaId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mediaId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                mediaId: mediaId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, FavoriteRow>(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mediaId,
                        referencedTable: $$FavoritesTableReferences
                            ._mediaIdTable(db),
                        referencedColumn: $$FavoritesTableReferences
                            ._mediaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      FavoriteRow,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (FavoriteRow, $$FavoritesTableReferences),
      FavoriteRow,
      PrefetchHooks Function({bool mediaId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$HiddenFoldersTableTableManager get hiddenFolders =>
      $$HiddenFoldersTableTableManager(_db, _db.hiddenFolders);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(_db, _db.syncTombstones);
  $$SyncMetadataTableTableManager get syncMetadata =>
      $$SyncMetadataTableTableManager(_db, _db.syncMetadata);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$PlaybackProgressTableTableManager get playbackProgress =>
      $$PlaybackProgressTableTableManager(_db, _db.playbackProgress);
  $$UserPreferencesTableTableManager get userPreferences =>
      $$UserPreferencesTableTableManager(_db, _db.userPreferences);
  $$QueueEntriesTableTableManager get queueEntries =>
      $$QueueEntriesTableTableManager(_db, _db.queueEntries);
  $$QueueStateTableTableManager get queueState =>
      $$QueueStateTableTableManager(_db, _db.queueState);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistEntriesTableTableManager get playlistEntries =>
      $$PlaylistEntriesTableTableManager(_db, _db.playlistEntries);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
}
