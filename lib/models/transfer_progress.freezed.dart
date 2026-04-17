// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TransferProgress _$TransferProgressFromJson(Map<String, dynamic> json) {
  return _TransferProgress.fromJson(json);
}

/// @nodoc
mixin _$TransferProgress {
  String get fileId => throw _privateConstructorUsedError;
  int get totalBytes => throw _privateConstructorUsedError;
  int get transferredBytes => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  double get speed => throw _privateConstructorUsedError; // bytes per second
  int get remainingSeconds => throw _privateConstructorUsedError;
  int get chunksTransferred => throw _privateConstructorUsedError;
  int get totalChunks => throw _privateConstructorUsedError;
  double get accuracy =>
      throw _privateConstructorUsedError; // 0.0 to 1.0 - confidence in progress
  String? get lastError => throw _privateConstructorUsedError;

  /// Serializes this TransferProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransferProgressCopyWith<TransferProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransferProgressCopyWith<$Res> {
  factory $TransferProgressCopyWith(
    TransferProgress value,
    $Res Function(TransferProgress) then,
  ) = _$TransferProgressCopyWithImpl<$Res, TransferProgress>;
  @useResult
  $Res call({
    String fileId,
    int totalBytes,
    int transferredBytes,
    DateTime startedAt,
    double speed,
    int remainingSeconds,
    int chunksTransferred,
    int totalChunks,
    double accuracy,
    String? lastError,
  });
}

/// @nodoc
class _$TransferProgressCopyWithImpl<$Res, $Val extends TransferProgress>
    implements $TransferProgressCopyWith<$Res> {
  _$TransferProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileId = null,
    Object? totalBytes = null,
    Object? transferredBytes = null,
    Object? startedAt = null,
    Object? speed = null,
    Object? remainingSeconds = null,
    Object? chunksTransferred = null,
    Object? totalChunks = null,
    Object? accuracy = null,
    Object? lastError = freezed,
  }) {
    return _then(
      _value.copyWith(
            fileId: null == fileId
                ? _value.fileId
                : fileId // ignore: cast_nullable_to_non_nullable
                      as String,
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
            speed: null == speed
                ? _value.speed
                : speed // ignore: cast_nullable_to_non_nullable
                      as double,
            remainingSeconds: null == remainingSeconds
                ? _value.remainingSeconds
                : remainingSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            chunksTransferred: null == chunksTransferred
                ? _value.chunksTransferred
                : chunksTransferred // ignore: cast_nullable_to_non_nullable
                      as int,
            totalChunks: null == totalChunks
                ? _value.totalChunks
                : totalChunks // ignore: cast_nullable_to_non_nullable
                      as int,
            accuracy: null == accuracy
                ? _value.accuracy
                : accuracy // ignore: cast_nullable_to_non_nullable
                      as double,
            lastError: freezed == lastError
                ? _value.lastError
                : lastError // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransferProgressImplCopyWith<$Res>
    implements $TransferProgressCopyWith<$Res> {
  factory _$$TransferProgressImplCopyWith(
    _$TransferProgressImpl value,
    $Res Function(_$TransferProgressImpl) then,
  ) = __$$TransferProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String fileId,
    int totalBytes,
    int transferredBytes,
    DateTime startedAt,
    double speed,
    int remainingSeconds,
    int chunksTransferred,
    int totalChunks,
    double accuracy,
    String? lastError,
  });
}

/// @nodoc
class __$$TransferProgressImplCopyWithImpl<$Res>
    extends _$TransferProgressCopyWithImpl<$Res, _$TransferProgressImpl>
    implements _$$TransferProgressImplCopyWith<$Res> {
  __$$TransferProgressImplCopyWithImpl(
    _$TransferProgressImpl _value,
    $Res Function(_$TransferProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileId = null,
    Object? totalBytes = null,
    Object? transferredBytes = null,
    Object? startedAt = null,
    Object? speed = null,
    Object? remainingSeconds = null,
    Object? chunksTransferred = null,
    Object? totalChunks = null,
    Object? accuracy = null,
    Object? lastError = freezed,
  }) {
    return _then(
      _$TransferProgressImpl(
        fileId: null == fileId
            ? _value.fileId
            : fileId // ignore: cast_nullable_to_non_nullable
                  as String,
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
        speed: null == speed
            ? _value.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double,
        remainingSeconds: null == remainingSeconds
            ? _value.remainingSeconds
            : remainingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        chunksTransferred: null == chunksTransferred
            ? _value.chunksTransferred
            : chunksTransferred // ignore: cast_nullable_to_non_nullable
                  as int,
        totalChunks: null == totalChunks
            ? _value.totalChunks
            : totalChunks // ignore: cast_nullable_to_non_nullable
                  as int,
        accuracy: null == accuracy
            ? _value.accuracy
            : accuracy // ignore: cast_nullable_to_non_nullable
                  as double,
        lastError: freezed == lastError
            ? _value.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransferProgressImpl implements _TransferProgress {
  const _$TransferProgressImpl({
    required this.fileId,
    required this.totalBytes,
    required this.transferredBytes,
    required this.startedAt,
    required this.speed,
    required this.remainingSeconds,
    this.chunksTransferred = 0,
    this.totalChunks = 0,
    this.accuracy = 0.0,
    this.lastError,
  });

  factory _$TransferProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransferProgressImplFromJson(json);

  @override
  final String fileId;
  @override
  final int totalBytes;
  @override
  final int transferredBytes;
  @override
  final DateTime startedAt;
  @override
  final double speed;
  // bytes per second
  @override
  final int remainingSeconds;
  @override
  @JsonKey()
  final int chunksTransferred;
  @override
  @JsonKey()
  final int totalChunks;
  @override
  @JsonKey()
  final double accuracy;
  // 0.0 to 1.0 - confidence in progress
  @override
  final String? lastError;

  @override
  String toString() {
    return 'TransferProgress(fileId: $fileId, totalBytes: $totalBytes, transferredBytes: $transferredBytes, startedAt: $startedAt, speed: $speed, remainingSeconds: $remainingSeconds, chunksTransferred: $chunksTransferred, totalChunks: $totalChunks, accuracy: $accuracy, lastError: $lastError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferProgressImpl &&
            (identical(other.fileId, fileId) || other.fileId == fileId) &&
            (identical(other.totalBytes, totalBytes) ||
                other.totalBytes == totalBytes) &&
            (identical(other.transferredBytes, transferredBytes) ||
                other.transferredBytes == transferredBytes) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds) &&
            (identical(other.chunksTransferred, chunksTransferred) ||
                other.chunksTransferred == chunksTransferred) &&
            (identical(other.totalChunks, totalChunks) ||
                other.totalChunks == totalChunks) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fileId,
    totalBytes,
    transferredBytes,
    startedAt,
    speed,
    remainingSeconds,
    chunksTransferred,
    totalChunks,
    accuracy,
    lastError,
  );

  /// Create a copy of TransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransferProgressImplCopyWith<_$TransferProgressImpl> get copyWith =>
      __$$TransferProgressImplCopyWithImpl<_$TransferProgressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TransferProgressImplToJson(this);
  }
}

abstract class _TransferProgress implements TransferProgress {
  const factory _TransferProgress({
    required final String fileId,
    required final int totalBytes,
    required final int transferredBytes,
    required final DateTime startedAt,
    required final double speed,
    required final int remainingSeconds,
    final int chunksTransferred,
    final int totalChunks,
    final double accuracy,
    final String? lastError,
  }) = _$TransferProgressImpl;

  factory _TransferProgress.fromJson(Map<String, dynamic> json) =
      _$TransferProgressImpl.fromJson;

  @override
  String get fileId;
  @override
  int get totalBytes;
  @override
  int get transferredBytes;
  @override
  DateTime get startedAt;
  @override
  double get speed; // bytes per second
  @override
  int get remainingSeconds;
  @override
  int get chunksTransferred;
  @override
  int get totalChunks;
  @override
  double get accuracy; // 0.0 to 1.0 - confidence in progress
  @override
  String? get lastError;

  /// Create a copy of TransferProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransferProgressImplCopyWith<_$TransferProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
