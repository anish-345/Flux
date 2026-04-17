// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Device _$DeviceFromJson(Map<String, dynamic> json) {
  return _Device.fromJson(json);
}

/// @nodoc
mixin _$Device {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get ipAddress => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  DeviceType get type => throw _privateConstructorUsedError;
  ConnectionType get connectionType => throw _privateConstructorUsedError;
  DateTime get discoveredAt => throw _privateConstructorUsedError;
  bool get isConnected => throw _privateConstructorUsedError;
  bool get isTrusted => throw _privateConstructorUsedError;
  String? get publicKey => throw _privateConstructorUsedError;
  String? get deviceModel => throw _privateConstructorUsedError;
  String? get osVersion => throw _privateConstructorUsedError;

  /// Serializes this Device to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceCopyWith<Device> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceCopyWith<$Res> {
  factory $DeviceCopyWith(Device value, $Res Function(Device) then) =
      _$DeviceCopyWithImpl<$Res, Device>;
  @useResult
  $Res call({
    String id,
    String name,
    String ipAddress,
    int port,
    DeviceType type,
    ConnectionType connectionType,
    DateTime discoveredAt,
    bool isConnected,
    bool isTrusted,
    String? publicKey,
    String? deviceModel,
    String? osVersion,
  });
}

/// @nodoc
class _$DeviceCopyWithImpl<$Res, $Val extends Device>
    implements $DeviceCopyWith<$Res> {
  _$DeviceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ipAddress = null,
    Object? port = null,
    Object? type = null,
    Object? connectionType = null,
    Object? discoveredAt = null,
    Object? isConnected = null,
    Object? isTrusted = null,
    Object? publicKey = freezed,
    Object? deviceModel = freezed,
    Object? osVersion = freezed,
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
            ipAddress: null == ipAddress
                ? _value.ipAddress
                : ipAddress // ignore: cast_nullable_to_non_nullable
                      as String,
            port: null == port
                ? _value.port
                : port // ignore: cast_nullable_to_non_nullable
                      as int,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as DeviceType,
            connectionType: null == connectionType
                ? _value.connectionType
                : connectionType // ignore: cast_nullable_to_non_nullable
                      as ConnectionType,
            discoveredAt: null == discoveredAt
                ? _value.discoveredAt
                : discoveredAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isConnected: null == isConnected
                ? _value.isConnected
                : isConnected // ignore: cast_nullable_to_non_nullable
                      as bool,
            isTrusted: null == isTrusted
                ? _value.isTrusted
                : isTrusted // ignore: cast_nullable_to_non_nullable
                      as bool,
            publicKey: freezed == publicKey
                ? _value.publicKey
                : publicKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceModel: freezed == deviceModel
                ? _value.deviceModel
                : deviceModel // ignore: cast_nullable_to_non_nullable
                      as String?,
            osVersion: freezed == osVersion
                ? _value.osVersion
                : osVersion // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DeviceImplCopyWith<$Res> implements $DeviceCopyWith<$Res> {
  factory _$$DeviceImplCopyWith(
    _$DeviceImpl value,
    $Res Function(_$DeviceImpl) then,
  ) = __$$DeviceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String ipAddress,
    int port,
    DeviceType type,
    ConnectionType connectionType,
    DateTime discoveredAt,
    bool isConnected,
    bool isTrusted,
    String? publicKey,
    String? deviceModel,
    String? osVersion,
  });
}

/// @nodoc
class __$$DeviceImplCopyWithImpl<$Res>
    extends _$DeviceCopyWithImpl<$Res, _$DeviceImpl>
    implements _$$DeviceImplCopyWith<$Res> {
  __$$DeviceImplCopyWithImpl(
    _$DeviceImpl _value,
    $Res Function(_$DeviceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? ipAddress = null,
    Object? port = null,
    Object? type = null,
    Object? connectionType = null,
    Object? discoveredAt = null,
    Object? isConnected = null,
    Object? isTrusted = null,
    Object? publicKey = freezed,
    Object? deviceModel = freezed,
    Object? osVersion = freezed,
  }) {
    return _then(
      _$DeviceImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        ipAddress: null == ipAddress
            ? _value.ipAddress
            : ipAddress // ignore: cast_nullable_to_non_nullable
                  as String,
        port: null == port
            ? _value.port
            : port // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as DeviceType,
        connectionType: null == connectionType
            ? _value.connectionType
            : connectionType // ignore: cast_nullable_to_non_nullable
                  as ConnectionType,
        discoveredAt: null == discoveredAt
            ? _value.discoveredAt
            : discoveredAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isConnected: null == isConnected
            ? _value.isConnected
            : isConnected // ignore: cast_nullable_to_non_nullable
                  as bool,
        isTrusted: null == isTrusted
            ? _value.isTrusted
            : isTrusted // ignore: cast_nullable_to_non_nullable
                  as bool,
        publicKey: freezed == publicKey
            ? _value.publicKey
            : publicKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceModel: freezed == deviceModel
            ? _value.deviceModel
            : deviceModel // ignore: cast_nullable_to_non_nullable
                  as String?,
        osVersion: freezed == osVersion
            ? _value.osVersion
            : osVersion // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceImpl implements _Device {
  const _$DeviceImpl({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.type,
    required this.connectionType,
    required this.discoveredAt,
    this.isConnected = false,
    this.isTrusted = false,
    this.publicKey,
    this.deviceModel,
    this.osVersion,
  });

  factory _$DeviceImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String ipAddress;
  @override
  final int port;
  @override
  final DeviceType type;
  @override
  final ConnectionType connectionType;
  @override
  final DateTime discoveredAt;
  @override
  @JsonKey()
  final bool isConnected;
  @override
  @JsonKey()
  final bool isTrusted;
  @override
  final String? publicKey;
  @override
  final String? deviceModel;
  @override
  final String? osVersion;

  @override
  String toString() {
    return 'Device(id: $id, name: $name, ipAddress: $ipAddress, port: $port, type: $type, connectionType: $connectionType, discoveredAt: $discoveredAt, isConnected: $isConnected, isTrusted: $isTrusted, publicKey: $publicKey, deviceModel: $deviceModel, osVersion: $osVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ipAddress, ipAddress) ||
                other.ipAddress == ipAddress) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.connectionType, connectionType) ||
                other.connectionType == connectionType) &&
            (identical(other.discoveredAt, discoveredAt) ||
                other.discoveredAt == discoveredAt) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.isTrusted, isTrusted) ||
                other.isTrusted == isTrusted) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.deviceModel, deviceModel) ||
                other.deviceModel == deviceModel) &&
            (identical(other.osVersion, osVersion) ||
                other.osVersion == osVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    ipAddress,
    port,
    type,
    connectionType,
    discoveredAt,
    isConnected,
    isTrusted,
    publicKey,
    deviceModel,
    osVersion,
  );

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceImplCopyWith<_$DeviceImpl> get copyWith =>
      __$$DeviceImplCopyWithImpl<_$DeviceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceImplToJson(this);
  }
}

abstract class _Device implements Device {
  const factory _Device({
    required final String id,
    required final String name,
    required final String ipAddress,
    required final int port,
    required final DeviceType type,
    required final ConnectionType connectionType,
    required final DateTime discoveredAt,
    final bool isConnected,
    final bool isTrusted,
    final String? publicKey,
    final String? deviceModel,
    final String? osVersion,
  }) = _$DeviceImpl;

  factory _Device.fromJson(Map<String, dynamic> json) = _$DeviceImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get ipAddress;
  @override
  int get port;
  @override
  DeviceType get type;
  @override
  ConnectionType get connectionType;
  @override
  DateTime get discoveredAt;
  @override
  bool get isConnected;
  @override
  bool get isTrusted;
  @override
  String? get publicKey;
  @override
  String? get deviceModel;
  @override
  String? get osVersion;

  /// Create a copy of Device
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceImplCopyWith<_$DeviceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
