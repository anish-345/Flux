// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TransferHistory _$TransferHistoryFromJson(Map<String, dynamic> json) {
  return _TransferHistory.fromJson(json);
}

/// @nodoc
mixin _$TransferHistory {
  String get id => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  int get fileSize => throw _privateConstructorUsedError;
  TransferDirection get direction => throw _privateConstructorUsedError;
  TransferStatus get status => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get peerDeviceName => throw _privateConstructorUsedError;
  String? get peerIpAddress => throw _privateConstructorUsedError;
  double? get progress => throw _privateConstructorUsedError;
  double? get speed => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

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
    String fileName,
    int fileSize,
    TransferDirection direction,
    TransferStatus status,
    DateTime timestamp,
    String? peerDeviceName,
    String? peerIpAddress,
    double? progress,
    double? speed,
    String? errorMessage,
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
    Object? fileName = null,
    Object? fileSize = null,
    Object? direction = null,
    Object? status = null,
    Object? timestamp = null,
    Object? peerDeviceName = freezed,
    Object? peerIpAddress = freezed,
    Object? progress = freezed,
    Object? speed = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
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
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as TransferStatus,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            peerDeviceName: freezed == peerDeviceName
                ? _value.peerDeviceName
                : peerDeviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            peerIpAddress: freezed == peerIpAddress
                ? _value.peerIpAddress
                : peerIpAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            progress: freezed == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as double?,
            speed: freezed == speed
                ? _value.speed
                : speed // ignore: cast_nullable_to_non_nullable
                      as double?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
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
    String fileName,
    int fileSize,
    TransferDirection direction,
    TransferStatus status,
    DateTime timestamp,
    String? peerDeviceName,
    String? peerIpAddress,
    double? progress,
    double? speed,
    String? errorMessage,
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
    Object? fileName = null,
    Object? fileSize = null,
    Object? direction = null,
    Object? status = null,
    Object? timestamp = null,
    Object? peerDeviceName = freezed,
    Object? peerIpAddress = freezed,
    Object? progress = freezed,
    Object? speed = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$TransferHistoryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
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
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as TransferStatus,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        peerDeviceName: freezed == peerDeviceName
            ? _value.peerDeviceName
            : peerDeviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        peerIpAddress: freezed == peerIpAddress
            ? _value.peerIpAddress
            : peerIpAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        progress: freezed == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as double?,
        speed: freezed == speed
            ? _value.speed
            : speed // ignore: cast_nullable_to_non_nullable
                  as double?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransferHistoryImpl implements _TransferHistory {
  const _$TransferHistoryImpl({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.direction,
    required this.status,
    required this.timestamp,
    this.peerDeviceName,
    this.peerIpAddress,
    this.progress,
    this.speed,
    this.errorMessage,
  });

  factory _$TransferHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransferHistoryImplFromJson(json);

  @override
  final String id;
  @override
  final String fileName;
  @override
  final int fileSize;
  @override
  final TransferDirection direction;
  @override
  final TransferStatus status;
  @override
  final DateTime timestamp;
  @override
  final String? peerDeviceName;
  @override
  final String? peerIpAddress;
  @override
  final double? progress;
  @override
  final double? speed;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'TransferHistory(id: $id, fileName: $fileName, fileSize: $fileSize, direction: $direction, status: $status, timestamp: $timestamp, peerDeviceName: $peerDeviceName, peerIpAddress: $peerIpAddress, progress: $progress, speed: $speed, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferHistoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.peerDeviceName, peerDeviceName) ||
                other.peerDeviceName == peerDeviceName) &&
            (identical(other.peerIpAddress, peerIpAddress) ||
                other.peerIpAddress == peerIpAddress) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.speed, speed) || other.speed == speed) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fileName,
    fileSize,
    direction,
    status,
    timestamp,
    peerDeviceName,
    peerIpAddress,
    progress,
    speed,
    errorMessage,
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
    required final String fileName,
    required final int fileSize,
    required final TransferDirection direction,
    required final TransferStatus status,
    required final DateTime timestamp,
    final String? peerDeviceName,
    final String? peerIpAddress,
    final double? progress,
    final double? speed,
    final String? errorMessage,
  }) = _$TransferHistoryImpl;

  factory _TransferHistory.fromJson(Map<String, dynamic> json) =
      _$TransferHistoryImpl.fromJson;

  @override
  String get id;
  @override
  String get fileName;
  @override
  int get fileSize;
  @override
  TransferDirection get direction;
  @override
  TransferStatus get status;
  @override
  DateTime get timestamp;
  @override
  String? get peerDeviceName;
  @override
  String? get peerIpAddress;
  @override
  double? get progress;
  @override
  double? get speed;
  @override
  String? get errorMessage;

  /// Create a copy of TransferHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransferHistoryImplCopyWith<_$TransferHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
