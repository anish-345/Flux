// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FileMetadata _$FileMetadataFromJson(Map<String, dynamic> json) {
  return _FileMetadata.fromJson(json);
}

/// @nodoc
mixin _$FileMetadata {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  String get mimeType => throw _privateConstructorUsedError;
  String get hash => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get modifiedAt => throw _privateConstructorUsedError;
  bool get isDirectory => throw _privateConstructorUsedError;
  String? get path => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this FileMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileMetadataCopyWith<FileMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileMetadataCopyWith<$Res> {
  factory $FileMetadataCopyWith(
    FileMetadata value,
    $Res Function(FileMetadata) then,
  ) = _$FileMetadataCopyWithImpl<$Res, FileMetadata>;
  @useResult
  $Res call({
    String id,
    String name,
    int size,
    String mimeType,
    String hash,
    DateTime createdAt,
    DateTime modifiedAt,
    bool isDirectory,
    String? path,
    String? description,
  });
}

/// @nodoc
class _$FileMetadataCopyWithImpl<$Res, $Val extends FileMetadata>
    implements $FileMetadataCopyWith<$Res> {
  _$FileMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? size = null,
    Object? mimeType = null,
    Object? hash = null,
    Object? createdAt = null,
    Object? modifiedAt = null,
    Object? isDirectory = null,
    Object? path = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            size: null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as int,
            mimeType: null == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String,
            hash: null == hash
                ? _value.hash
                : hash // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            modifiedAt: null == modifiedAt
                ? _value.modifiedAt
                : modifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isDirectory: null == isDirectory
                ? _value.isDirectory
                : isDirectory // ignore: cast_nullable_to_non_nullable
                      as bool,
            path: freezed == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FileMetadataImplCopyWith<$Res>
    implements $FileMetadataCopyWith<$Res> {
  factory _$$FileMetadataImplCopyWith(
    _$FileMetadataImpl value,
    $Res Function(_$FileMetadataImpl) then,
  ) = __$$FileMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int size,
    String mimeType,
    String hash,
    DateTime createdAt,
    DateTime modifiedAt,
    bool isDirectory,
    String? path,
    String? description,
  });
}

/// @nodoc
class __$$FileMetadataImplCopyWithImpl<$Res>
    extends _$FileMetadataCopyWithImpl<$Res, _$FileMetadataImpl>
    implements _$$FileMetadataImplCopyWith<$Res> {
  __$$FileMetadataImplCopyWithImpl(
    _$FileMetadataImpl _value,
    $Res Function(_$FileMetadataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? size = null,
    Object? mimeType = null,
    Object? hash = null,
    Object? createdAt = null,
    Object? modifiedAt = null,
    Object? isDirectory = null,
    Object? path = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _$FileMetadataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        size: null == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
        mimeType: null == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String,
        hash: null == hash
            ? _value.hash
            : hash // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        modifiedAt: null == modifiedAt
            ? _value.modifiedAt
            : modifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isDirectory: null == isDirectory
            ? _value.isDirectory
            : isDirectory // ignore: cast_nullable_to_non_nullable
                  as bool,
        path: freezed == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FileMetadataImpl implements _FileMetadata {
  const _$FileMetadataImpl({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.hash,
    required this.createdAt,
    required this.modifiedAt,
    this.isDirectory = false,
    this.path,
    this.description,
  });

  factory _$FileMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileMetadataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int size;
  @override
  final String mimeType;
  @override
  final String hash;
  @override
  final DateTime createdAt;
  @override
  final DateTime modifiedAt;
  @override
  @JsonKey()
  final bool isDirectory;
  @override
  final String? path;
  @override
  final String? description;

  @override
  String toString() {
    return 'FileMetadata(id: $id, name: $name, size: $size, mimeType: $mimeType, hash: $hash, createdAt: $createdAt, modifiedAt: $modifiedAt, isDirectory: $isDirectory, path: $path, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileMetadataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt) &&
            (identical(other.isDirectory, isDirectory) ||
                other.isDirectory == isDirectory) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    size,
    mimeType,
    hash,
    createdAt,
    modifiedAt,
    isDirectory,
    path,
    description,
  );

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileMetadataImplCopyWith<_$FileMetadataImpl> get copyWith =>
      __$$FileMetadataImplCopyWithImpl<_$FileMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileMetadataImplToJson(this);
  }
}

abstract class _FileMetadata implements FileMetadata {
  const factory _FileMetadata({
    required final String id,
    required final String name,
    required final int size,
    required final String mimeType,
    required final String hash,
    required final DateTime createdAt,
    required final DateTime modifiedAt,
    final bool isDirectory,
    final String? path,
    final String? description,
  }) = _$FileMetadataImpl;

  factory _FileMetadata.fromJson(Map<String, dynamic> json) =
      _$FileMetadataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get size;
  @override
  String get mimeType;
  @override
  String get hash;
  @override
  DateTime get createdAt;
  @override
  DateTime get modifiedAt;
  @override
  bool get isDirectory;
  @override
  String? get path;
  @override
  String? get description;

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileMetadataImplCopyWith<_$FileMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TransferStatus _$TransferStatusFromJson(Map<String, dynamic> json) {
  return _TransferStatus.fromJson(json);
}

/// @nodoc
mixin _$TransferStatus {
  String get fileId => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  TransferState get state => throw _privateConstructorUsedError;
  int get totalBytes => throw _privateConstructorUsedError;
  int get transferredBytes => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  double get speed => throw _privateConstructorUsedError; // bytes per second
  int get remainingSeconds => throw _privateConstructorUsedError;

  /// Serializes this TransferStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransferStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransferStatusCopyWith<TransferStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransferStatusCopyWith<$Res> {
  factory $TransferStatusCopyWith(
    TransferStatus value,
    $Res Function(TransferStatus) then,
  ) = _$TransferStatusCopyWithImpl<$Res, TransferStatus>;
  @useResult
  $Res call({
    String fileId,
    String fileName,
    TransferState state,
    int totalBytes,
    int transferredBytes,
    DateTime startedAt,
    DateTime? completedAt,
    String? error,
    double speed,
    int remainingSeconds,
  });
}

/// @nodoc
class _$TransferStatusCopyWithImpl<$Res, $Val extends TransferStatus>
    implements $TransferStatusCopyWith<$Res> {
  _$TransferStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransferStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileId = null,
    Object? fileName = null,
    Object? state = null,
    Object? totalBytes = null,
    Object? transferredBytes = null,
    Object? startedAt = null,
    Object? completedAt = freezed,
    Object? error = freezed,
    Object? speed = null,
    Object? remainingSeconds = null,
  }) {
    return _then(
      _value.copyWith(
            fileId: null == fileId
                ? _value.fileId
                : fileId // ignore: cast_nullable_to_non_nullable
                      as String,
            fileName: null == fileName
                ? _value.fileName
                : fileName // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as TransferState,
            totalBytes: null == totalBytes
                ? _value.totalBytes
                : totalBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            transferredBytes: null == transferredBytes
                ? _value.transferredBytes
                : transferredBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            startedAt: null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            speed: null == speed
                ? _value.speed
                : speed // ignore: cast_nullable_to_non_nullable
                      as double,
            remainingSeconds: null == remainingSeconds
                ? _value.remainingSeconds
                : remainingSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransferStatusImplCopyWith<$Res>
    implements $TransferStatusCopyWith<$Res> {
  factory _$$TransferStatusImplCopyWith(
    _$TransferStatusImpl value,
    $Res Function(_$TransferStatusImpl) then,
  ) = __$$TransferStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String fileId,
    String fileName,
    TransferState state,
    int totalBytes,
    int transferredBytes,
    DateTime startedAt,
    DateTime? completedAt,
    String? error,
    double speed,
    int remainingSeconds,
  });
}

/// @nodoc
class __$$TransferStatusImplCopyWithImpl<$Res>
    extends _$TransferStatusCopyWithImpl<$Res, _$TransferStatusImpl>
    implements _$$TransferStatusImplCopyWith<$Res> {
  __$$TransferStatusImplCopyWithImpl(
    _$TransferStatusImpl _value,
    $Res Function(_$TransferStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransferStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileId = null,
    Object? fileName = null,
    Object? state = null,
    Object? totalBytes = null,
    Object? transferredBytes = null,
    Object? startedAt = null,
    Object? completedAt = freezed,
    Object? error = freezed,
    Object? speed = null,
    Object? remainingSeconds = null,
  }) {
    return _then(
      _$TransferStatusImpl(
        fileId: null == fileId
            ? _value.fileId
            : fileId // ignore: cast_nullable_to_non_nullable
                  as String,
        fileName: null == fileName
            ? _value.fileName
            : fileName // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as TransferState,
        totalBytes: null == totalBytes
            ? _value.totalBytes
            : totalBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        transferredBytes: null == transferredBytes
            ? _value.transferredBytes
            : transferredBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        speed: null == speed
            ? _value.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double,
        remainingSeconds: null == remainingSeconds
            ? _value.remainingSeconds
            : remainingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransferStatusImpl implements _TransferStatus {
  const _$TransferStatusImpl({
    required this.fileId,
    required this.fileName,
    required this.state,
    required this.totalBytes,
    required this.transferredBytes,
    required this.startedAt,
    this.completedAt,
    this.error,
    this.speed = 0.0,
    this.remainingSeconds = 0,
  });

  factory _$TransferStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransferStatusImplFromJson(json);

  @override
  final String fileId;
  @override
  final String fileName;
  @override
  final TransferState state;
  @override
  final int totalBytes;
  @override
  final int transferredBytes;
  @override
  final DateTime startedAt;
  @override
  final DateTime? completedAt;
  @override
  final String? error;
  @override
  @JsonKey()
  final double speed;
  // bytes per second
  @override
  @JsonKey()
  final int remainingSeconds;

  @override
  String toString() {
    return 'TransferStatus(fileId: $fileId, fileName: $fileName, state: $state, totalBytes: $totalBytes, transferredBytes: $transferredBytes, startedAt: $startedAt, completedAt: $completedAt, error: $error, speed: $speed, remainingSeconds: $remainingSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferStatusImpl &&
            (identical(other.fileId, fileId) || other.fileId == fileId) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.transferredBytes, transferredBytes) ||
                other.transferredBytes == transferredBytes) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fileId,
    fileName,
    state,
    totalBytes,
    transferredBytes,
    startedAt,
    completedAt,
    error,
    speed,
    remainingSeconds,
  );

  /// Create a copy of TransferStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransferStatusImplCopyWith<_$TransferStatusImpl> get copyWith =>
      __$$TransferStatusImplCopyWithImpl<_$TransferStatusImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TransferStatusImplToJson(this);
  }
}

abstract class _TransferStatus implements TransferStatus {
  const factory _TransferStatus({
    required final String fileId,
    required final String fileName,
    required final TransferState state,
    required final int totalBytes,
    required final int transferredBytes,
    required final DateTime startedAt,
    final DateTime? completedAt,
    final String? error,
    final double speed,
    final int remainingSeconds,
  }) = _$TransferStatusImpl;

  factory _TransferStatus.fromJson(Map<String, dynamic> json) =
      _$TransferStatusImpl.fromJson;

  @override
  String get fileId;
  @override
  String get fileName;
  @override
  TransferState get state;
  @override
  int get totalBytes;
  @override
  int get transferredBytes;
  @override
  DateTime get startedAt;
  @override
  DateTime? get completedAt;
  @override
  String? get error;
  @override
  double get speed; // bytes per second
  @override
  int get remainingSeconds;

  /// Create a copy of TransferStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransferStatusImplCopyWith<_$TransferStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TransferHistory _$TransferHistoryFromJson(Map<String, dynamic> json) {
  return _TransferHistory.fromJson(json);
}

/// @nodoc
mixin _$TransferHistory {
  String get id => throw _privateConstructorUsedError;
  String get deviceId => throw _privateConstructorUsedError;
  String get deviceName => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  int get fileSize => throw _privateConstructorUsedError;
  TransferDirection get direction => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  bool get success => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  int get durationSeconds => throw _privateConstructorUsedError;

  /// Serializes this TransferHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransferHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransferHistoryCopyWith<TransferHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransferHistoryCopyWith<$Res> {
  factory $TransferHistoryCopyWith(
    TransferHistory value,
    $Res Function(TransferHistory) then,
  ) = _$TransferHistoryCopyWithImpl<$Res, TransferHistory>;
  @useResult
  $Res call({
    String id,
    String deviceId,
    String deviceName,
    String fileName,
    int fileSize,
    TransferDirection direction,
    DateTime timestamp,
    bool success,
    String? error,
    int durationSeconds,
  });
}

/// @nodoc
class _$TransferHistoryCopyWithImpl<$Res, $Val extends TransferHistory>
    implements $TransferHistoryCopyWith<$Res> {
  _$TransferHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransferHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? deviceName = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? direction = null,
    Object? timestamp = null,
    Object? success = null,
    Object? error = freezed,
    Object? durationSeconds = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceId: null == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceName: null == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String,
            fileName: null == fileName
                ? _value.fileName
                : fileName // ignore: cast_nullable_to_non_nullable
                      as String,
            fileSize: null == fileSize
                ? _value.fileSize
                : fileSize // ignore: cast_nullable_to_non_nullable
                      as int,
            direction: null == direction
                ? _value.direction
                : direction // ignore: cast_nullable_to_non_nullable
                      as TransferDirection,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            durationSeconds: null == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransferHistoryImplCopyWith<$Res>
    implements $TransferHistoryCopyWith<$Res> {
  factory _$$TransferHistoryImplCopyWith(
    _$TransferHistoryImpl value,
    $Res Function(_$TransferHistoryImpl) then,
  ) = __$$TransferHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String deviceId,
    String deviceName,
    String fileName,
    int fileSize,
    TransferDirection direction,
    DateTime timestamp,
    bool success,
    String? error,
    int durationSeconds,
  });
}

/// @nodoc
class __$$TransferHistoryImplCopyWithImpl<$Res>
    extends _$TransferHistoryCopyWithImpl<$Res, _$TransferHistoryImpl>
    implements _$$TransferHistoryImplCopyWith<$Res> {
  __$$TransferHistoryImplCopyWithImpl(
    _$TransferHistoryImpl _value,
    $Res Function(_$TransferHistoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransferHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? deviceName = null,
    Object? fileName = null,
    Object? fileSize = null,
    Object? direction = null,
    Object? timestamp = null,
    Object? success = null,
    Object? error = freezed,
    Object? durationSeconds = null,
  }) {
    return _then(
      _$TransferHistoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceName: null == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String,
        fileName: null == fileName
            ? _value.fileName
            : fileName // ignore: cast_nullable_to_non_nullable
                  as String,
        fileSize: null == fileSize
            ? _value.fileSize
            : fileSize // ignore: cast_nullable_to_non_nullable
                  as int,
        direction: null == direction
            ? _value.direction
            : direction // ignore: cast_nullable_to_non_nullable
                  as TransferDirection,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        durationSeconds: null == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransferHistoryImpl implements _TransferHistory {
  const _$TransferHistoryImpl({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.fileName,
    required this.fileSize,
    required this.direction,
    required this.timestamp,
    required this.success,
    this.error,
    this.durationSeconds = 0,
  });

  factory _$TransferHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransferHistoryImplFromJson(json);

  @override
  final String id;
  @override
  final String deviceId;
  @override
  final String deviceName;
  @override
  final String fileName;
  @override
  final int fileSize;
  @override
  final TransferDirection direction;
  @override
  final DateTime timestamp;
  @override
  final bool success;
  @override
  final String? error;
  @override
  @JsonKey()
  final int durationSeconds;

  @override
  String toString() {
    return 'TransferHistory(id: $id, deviceId: $deviceId, deviceName: $deviceName, fileName: $fileName, fileSize: $fileSize, direction: $direction, timestamp: $timestamp, success: $success, error: $error, durationSeconds: $durationSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferHistoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    deviceId,
    deviceName,
    fileName,
    fileSize,
    direction,
    timestamp,
    success,
    error,
    durationSeconds,
  );

  /// Create a copy of TransferHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransferHistoryImplCopyWith<_$TransferHistoryImpl> get copyWith =>
      __$$TransferHistoryImplCopyWithImpl<_$TransferHistoryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TransferHistoryImplToJson(this);
  }
}

abstract class _TransferHistory implements TransferHistory {
  const factory _TransferHistory({
    required final String id,
    required final String deviceId,
    required final String deviceName,
    required final String fileName,
    required final int fileSize,
    required final TransferDirection direction,
    required final DateTime timestamp,
    required final bool success,
    final String? error,
    final int durationSeconds,
  }) = _$TransferHistoryImpl;

  factory _TransferHistory.fromJson(Map<String, dynamic> json) =
      _$TransferHistoryImpl.fromJson;

  @override
  String get id;
  @override
  String get deviceId;
  @override
  String get deviceName;
  @override
  String get fileName;
  @override
  int get fileSize;
  @override
  TransferDirection get direction;
  @override
  DateTime get timestamp;
  @override
  bool get success;
  @override
  String? get error;
  @override
  int get durationSeconds;

  /// Create a copy of TransferHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransferHistoryImplCopyWith<_$TransferHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
