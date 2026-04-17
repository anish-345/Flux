// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppConnectionState _$AppConnectionStateFromJson(Map<String, dynamic> json) {
  return _AppConnectionState.fromJson(json);
}

/// @nodoc
mixin _$AppConnectionState {
  bool get isInternetConnected => throw _privateConstructorUsedError;
  bool get isBluetoothEnabled => throw _privateConstructorUsedError;
  bool get isWiFiEnabled => throw _privateConstructorUsedError;
  bool get isHotspotEnabled => throw _privateConstructorUsedError;
  String? get currentWiFiSSID => throw _privateConstructorUsedError;
  String? get deviceIPAddress => throw _privateConstructorUsedError;
  List<String> get availableNetworks => throw _privateConstructorUsedError;
  bool get isDiscovering => throw _privateConstructorUsedError;
  int get discoveredDevicesCount => throw _privateConstructorUsedError;

  /// Serializes this AppConnectionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppConnectionStateCopyWith<AppConnectionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppConnectionStateCopyWith<$Res> {
  factory $AppConnectionStateCopyWith(
    AppConnectionState value,
    $Res Function(AppConnectionState) then,
  ) = _$AppConnectionStateCopyWithImpl<$Res, AppConnectionState>;
  @useResult
  $Res call({
    bool isInternetConnected,
    bool isBluetoothEnabled,
    bool isWiFiEnabled,
    bool isHotspotEnabled,
    String? currentWiFiSSID,
    String? deviceIPAddress,
    List<String> availableNetworks,
    bool isDiscovering,
    int discoveredDevicesCount,
  });
}

/// @nodoc
class _$AppConnectionStateCopyWithImpl<$Res, $Val extends AppConnectionState>
    implements $AppConnectionStateCopyWith<$Res> {
  _$AppConnectionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInternetConnected = null,
    Object? isBluetoothEnabled = null,
    Object? isWiFiEnabled = null,
    Object? isHotspotEnabled = null,
    Object? currentWiFiSSID = freezed,
    Object? deviceIPAddress = freezed,
    Object? availableNetworks = null,
    Object? isDiscovering = null,
    Object? discoveredDevicesCount = null,
  }) {
    return _then(
      _value.copyWith(
            isInternetConnected: null == isInternetConnected
                ? _value.isInternetConnected
                : isInternetConnected // ignore: cast_nullable_to_non_nullable
                      as bool,
            isBluetoothEnabled: null == isBluetoothEnabled
                ? _value.isBluetoothEnabled
                : isBluetoothEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isWiFiEnabled: null == isWiFiEnabled
                ? _value.isWiFiEnabled
                : isWiFiEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            isHotspotEnabled: null == isHotspotEnabled
                ? _value.isHotspotEnabled
                : isHotspotEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentWiFiSSID: freezed == currentWiFiSSID
                ? _value.currentWiFiSSID
                : currentWiFiSSID // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceIPAddress: freezed == deviceIPAddress
                ? _value.deviceIPAddress
                : deviceIPAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            availableNetworks: null == availableNetworks
                ? _value.availableNetworks
                : availableNetworks // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isDiscovering: null == isDiscovering
                ? _value.isDiscovering
                : isDiscovering // ignore: cast_nullable_to_non_nullable
                      as bool,
            discoveredDevicesCount: null == discoveredDevicesCount
                ? _value.discoveredDevicesCount
                : discoveredDevicesCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppConnectionStateImplCopyWith<$Res>
    implements $AppConnectionStateCopyWith<$Res> {
  factory _$$AppConnectionStateImplCopyWith(
    _$AppConnectionStateImpl value,
    $Res Function(_$AppConnectionStateImpl) then,
  ) = __$$AppConnectionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isInternetConnected,
    bool isBluetoothEnabled,
    bool isWiFiEnabled,
    bool isHotspotEnabled,
    String? currentWiFiSSID,
    String? deviceIPAddress,
    List<String> availableNetworks,
    bool isDiscovering,
    int discoveredDevicesCount,
  });
}

/// @nodoc
class __$$AppConnectionStateImplCopyWithImpl<$Res>
    extends _$AppConnectionStateCopyWithImpl<$Res, _$AppConnectionStateImpl>
    implements _$$AppConnectionStateImplCopyWith<$Res> {
  __$$AppConnectionStateImplCopyWithImpl(
    _$AppConnectionStateImpl _value,
    $Res Function(_$AppConnectionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInternetConnected = null,
    Object? isBluetoothEnabled = null,
    Object? isWiFiEnabled = null,
    Object? isHotspotEnabled = null,
    Object? currentWiFiSSID = freezed,
    Object? deviceIPAddress = freezed,
    Object? availableNetworks = null,
    Object? isDiscovering = null,
    Object? discoveredDevicesCount = null,
  }) {
    return _then(
      _$AppConnectionStateImpl(
        isInternetConnected: null == isInternetConnected
            ? _value.isInternetConnected
            : isInternetConnected // ignore: cast_nullable_to_non_nullable
                  as bool,
        isBluetoothEnabled: null == isBluetoothEnabled
            ? _value.isBluetoothEnabled
            : isBluetoothEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isWiFiEnabled: null == isWiFiEnabled
            ? _value.isWiFiEnabled
            : isWiFiEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        isHotspotEnabled: null == isHotspotEnabled
            ? _value.isHotspotEnabled
            : isHotspotEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentWiFiSSID: freezed == currentWiFiSSID
            ? _value.currentWiFiSSID
            : currentWiFiSSID // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceIPAddress: freezed == deviceIPAddress
            ? _value.deviceIPAddress
            : deviceIPAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        availableNetworks: null == availableNetworks
            ? _value._availableNetworks
            : availableNetworks // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isDiscovering: null == isDiscovering
            ? _value.isDiscovering
            : isDiscovering // ignore: cast_nullable_to_non_nullable
                  as bool,
        discoveredDevicesCount: null == discoveredDevicesCount
            ? _value.discoveredDevicesCount
            : discoveredDevicesCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppConnectionStateImpl implements _AppConnectionState {
  const _$AppConnectionStateImpl({
    required this.isInternetConnected,
    required this.isBluetoothEnabled,
    required this.isWiFiEnabled,
    required this.isHotspotEnabled,
    required this.currentWiFiSSID,
    required this.deviceIPAddress,
    final List<String> availableNetworks = const [],
    this.isDiscovering = false,
    this.discoveredDevicesCount = 0,
  }) : _availableNetworks = availableNetworks;

  factory _$AppConnectionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppConnectionStateImplFromJson(json);

  @override
  final bool isInternetConnected;
  @override
  final bool isBluetoothEnabled;
  @override
  final bool isWiFiEnabled;
  @override
  final bool isHotspotEnabled;
  @override
  final String? currentWiFiSSID;
  @override
  final String? deviceIPAddress;
  final List<String> _availableNetworks;
  @override
  @JsonKey()
  List<String> get availableNetworks {
    if (_availableNetworks is EqualUnmodifiableListView)
      return _availableNetworks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableNetworks);
  }

  @override
  @JsonKey()
  final bool isDiscovering;
  @override
  @JsonKey()
  final int discoveredDevicesCount;

  @override
  String toString() {
    return 'AppConnectionState(isInternetConnected: $isInternetConnected, isBluetoothEnabled: $isBluetoothEnabled, isWiFiEnabled: $isWiFiEnabled, isHotspotEnabled: $isHotspotEnabled, currentWiFiSSID: $currentWiFiSSID, deviceIPAddress: $deviceIPAddress, availableNetworks: $availableNetworks, isDiscovering: $isDiscovering, discoveredDevicesCount: $discoveredDevicesCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppConnectionStateImpl &&
            (identical(other.isInternetConnected, isInternetConnected) ||
                other.isInternetConnected == isInternetConnected) &&
            (identical(other.isBluetoothEnabled, isBluetoothEnabled) ||
                other.isBluetoothEnabled == isBluetoothEnabled) &&
            (identical(other.isWiFiEnabled, isWiFiEnabled) ||
                other.isWiFiEnabled == isWiFiEnabled) &&
            (identical(other.isHotspotEnabled, isHotspotEnabled) ||
                other.isHotspotEnabled == isHotspotEnabled) &&
            (identical(other.currentWiFiSSID, currentWiFiSSID) ||
                other.currentWiFiSSID == currentWiFiSSID) &&
            (identical(other.deviceIPAddress, deviceIPAddress) ||
                other.deviceIPAddress == deviceIPAddress) &&
            const DeepCollectionEquality().equals(
              other._availableNetworks,
              _availableNetworks,
            ) &&
            (identical(other.isDiscovering, isDiscovering) ||
                other.isDiscovering == isDiscovering) &&
            (identical(other.discoveredDevicesCount, discoveredDevicesCount) ||
                other.discoveredDevicesCount == discoveredDevicesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isInternetConnected,
    isBluetoothEnabled,
    isWiFiEnabled,
    isHotspotEnabled,
    currentWiFiSSID,
    deviceIPAddress,
    const DeepCollectionEquality().hash(_availableNetworks),
    isDiscovering,
    discoveredDevicesCount,
  );

  /// Create a copy of AppConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppConnectionStateImplCopyWith<_$AppConnectionStateImpl> get copyWith =>
      __$$AppConnectionStateImplCopyWithImpl<_$AppConnectionStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppConnectionStateImplToJson(this);
  }
}

abstract class _AppConnectionState implements AppConnectionState {
  const factory _AppConnectionState({
    required final bool isInternetConnected,
    required final bool isBluetoothEnabled,
    required final bool isWiFiEnabled,
    required final bool isHotspotEnabled,
    required final String? currentWiFiSSID,
    required final String? deviceIPAddress,
    final List<String> availableNetworks,
    final bool isDiscovering,
    final int discoveredDevicesCount,
  }) = _$AppConnectionStateImpl;

  factory _AppConnectionState.fromJson(Map<String, dynamic> json) =
      _$AppConnectionStateImpl.fromJson;

  @override
  bool get isInternetConnected;
  @override
  bool get isBluetoothEnabled;
  @override
  bool get isWiFiEnabled;
  @override
  bool get isHotspotEnabled;
  @override
  String? get currentWiFiSSID;
  @override
  String? get deviceIPAddress;
  @override
  List<String> get availableNetworks;
  @override
  bool get isDiscovering;
  @override
  int get discoveredDevicesCount;

  /// Create a copy of AppConnectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppConnectionStateImplCopyWith<_$AppConnectionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConnectionInfo _$ConnectionInfoFromJson(Map<String, dynamic> json) {
  return _ConnectionInfo.fromJson(json);
}

/// @nodoc
mixin _$ConnectionInfo {
  String get deviceId => throw _privateConstructorUsedError;
  String get deviceName => throw _privateConstructorUsedError;
  ConnectionStatus get status => throw _privateConstructorUsedError;
  DateTime get connectedAt => throw _privateConstructorUsedError;
  DateTime? get disconnectedAt => throw _privateConstructorUsedError;
  int get bytesTransferred => throw _privateConstructorUsedError;
  int get filesTransferred => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this ConnectionInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionInfoCopyWith<ConnectionInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionInfoCopyWith<$Res> {
  factory $ConnectionInfoCopyWith(
    ConnectionInfo value,
    $Res Function(ConnectionInfo) then,
  ) = _$ConnectionInfoCopyWithImpl<$Res, ConnectionInfo>;
  @useResult
  $Res call({
    String deviceId,
    String deviceName,
    ConnectionStatus status,
    DateTime connectedAt,
    DateTime? disconnectedAt,
    int bytesTransferred,
    int filesTransferred,
    String? error,
  });
}

/// @nodoc
class _$ConnectionInfoCopyWithImpl<$Res, $Val extends ConnectionInfo>
    implements $ConnectionInfoCopyWith<$Res> {
  _$ConnectionInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? deviceName = null,
    Object? status = null,
    Object? connectedAt = null,
    Object? disconnectedAt = freezed,
    Object? bytesTransferred = null,
    Object? filesTransferred = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            deviceId: null == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String,
            deviceName: null == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ConnectionStatus,
            connectedAt: null == connectedAt
                ? _value.connectedAt
                : connectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            disconnectedAt: freezed == disconnectedAt
                ? _value.disconnectedAt
                : disconnectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            bytesTransferred: null == bytesTransferred
                ? _value.bytesTransferred
                : bytesTransferred // ignore: cast_nullable_to_non_nullable
                      as int,
            filesTransferred: null == filesTransferred
                ? _value.filesTransferred
                : filesTransferred // ignore: cast_nullable_to_non_nullable
                      as int,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConnectionInfoImplCopyWith<$Res>
    implements $ConnectionInfoCopyWith<$Res> {
  factory _$$ConnectionInfoImplCopyWith(
    _$ConnectionInfoImpl value,
    $Res Function(_$ConnectionInfoImpl) then,
  ) = __$$ConnectionInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String deviceId,
    String deviceName,
    ConnectionStatus status,
    DateTime connectedAt,
    DateTime? disconnectedAt,
    int bytesTransferred,
    int filesTransferred,
    String? error,
  });
}

/// @nodoc
class __$$ConnectionInfoImplCopyWithImpl<$Res>
    extends _$ConnectionInfoCopyWithImpl<$Res, _$ConnectionInfoImpl>
    implements _$$ConnectionInfoImplCopyWith<$Res> {
  __$$ConnectionInfoImplCopyWithImpl(
    _$ConnectionInfoImpl _value,
    $Res Function(_$ConnectionInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? deviceName = null,
    Object? status = null,
    Object? connectedAt = null,
    Object? disconnectedAt = freezed,
    Object? bytesTransferred = null,
    Object? filesTransferred = null,
    Object? error = freezed,
  }) {
    return _then(
      _$ConnectionInfoImpl(
        deviceId: null == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceName: null == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ConnectionStatus,
        connectedAt: null == connectedAt
            ? _value.connectedAt
            : connectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        disconnectedAt: freezed == disconnectedAt
            ? _value.disconnectedAt
            : disconnectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        bytesTransferred: null == bytesTransferred
            ? _value.bytesTransferred
            : bytesTransferred // ignore: cast_nullable_to_non_nullable
                  as int,
        filesTransferred: null == filesTransferred
            ? _value.filesTransferred
            : filesTransferred // ignore: cast_nullable_to_non_nullable
                  as int,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConnectionInfoImpl implements _ConnectionInfo {
  const _$ConnectionInfoImpl({
    required this.deviceId,
    required this.deviceName,
    required this.status,
    required this.connectedAt,
    this.disconnectedAt,
    this.bytesTransferred = 0,
    this.filesTransferred = 0,
    this.error,
  });

  factory _$ConnectionInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionInfoImplFromJson(json);

  @override
  final String deviceId;
  @override
  final String deviceName;
  @override
  final ConnectionStatus status;
  @override
  final DateTime connectedAt;
  @override
  final DateTime? disconnectedAt;
  @override
  @JsonKey()
  final int bytesTransferred;
  @override
  @JsonKey()
  final int filesTransferred;
  @override
  final String? error;

  @override
  String toString() {
    return 'ConnectionInfo(deviceId: $deviceId, deviceName: $deviceName, status: $status, connectedAt: $connectedAt, disconnectedAt: $disconnectedAt, bytesTransferred: $bytesTransferred, filesTransferred: $filesTransferred, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionInfoImpl &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.connectedAt, connectedAt) ||
                other.connectedAt == connectedAt) &&
            (identical(other.disconnectedAt, disconnectedAt) ||
                other.disconnectedAt == disconnectedAt) &&
            (identical(other.bytesTransferred, bytesTransferred) ||
                other.bytesTransferred == bytesTransferred) &&
            (identical(other.filesTransferred, filesTransferred) ||
                other.filesTransferred == filesTransferred) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    deviceId,
    deviceName,
    status,
    connectedAt,
    disconnectedAt,
    bytesTransferred,
    filesTransferred,
    error,
  );

  /// Create a copy of ConnectionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionInfoImplCopyWith<_$ConnectionInfoImpl> get copyWith =>
      __$$ConnectionInfoImplCopyWithImpl<_$ConnectionInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionInfoImplToJson(this);
  }
}

abstract class _ConnectionInfo implements ConnectionInfo {
  const factory _ConnectionInfo({
    required final String deviceId,
    required final String deviceName,
    required final ConnectionStatus status,
    required final DateTime connectedAt,
    final DateTime? disconnectedAt,
    final int bytesTransferred,
    final int filesTransferred,
    final String? error,
  }) = _$ConnectionInfoImpl;

  factory _ConnectionInfo.fromJson(Map<String, dynamic> json) =
      _$ConnectionInfoImpl.fromJson;

  @override
  String get deviceId;
  @override
  String get deviceName;
  @override
  ConnectionStatus get status;
  @override
  DateTime get connectedAt;
  @override
  DateTime? get disconnectedAt;
  @override
  int get bytesTransferred;
  @override
  int get filesTransferred;
  @override
  String? get error;

  /// Create a copy of ConnectionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionInfoImplCopyWith<_$ConnectionInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
