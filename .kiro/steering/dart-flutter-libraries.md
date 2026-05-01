---
inclusion: manual
---

# Dart & Flutter Essential Libraries Guide

**Quick Navigation:** [HTTP & Networking](#-http--networking) | [JSON Serialization](#-json-serialization) | [State Management](#-state-management) | [Testing](#-testing) | [Storage](#-local-storage) | [Library Matrix](#-library-selection-matrix)

**Last Updated:** April 12, 2026  
**Status:** ✅ Active Knowledge Base  
**Confidence Level:** High (Official Documentation)  
**Use Case:** Reference for selecting proper libraries in Dart/Flutter projects

---

## 📋 Document Summary

This guide provides expert recommendations for Dart/Flutter libraries across all major categories:
- **HTTP & Networking:** http, Dio, and networking solutions
- **JSON Serialization:** json_serializable, freezed, and data models
- **State Management:** Provider, Riverpod, Bloc/Cubit comparison
- **Dependency Injection:** get_it and Riverpod patterns
- **Testing:** Unit, widget, and integration testing frameworks
- **Local Storage:** shared_preferences, Hive, sqflite options
- **Library Selection Matrix:** Comparison table for decision-making

**When to use:** When selecting libraries for Dart/Flutter projects or understanding library trade-offs.

---

## 📦 HTTP & Networking

### package:http - Standard HTTP Client
```yaml
dependencies:
  http: ^1.1.0
```

**When to use:** Simple HTTP requests, REST APIs
**Pros:** Built-in, lightweight, no external dependencies
**Cons:** No interceptors, limited features

```dart
import 'package:http/http.dart' as http;

Future<String> fetchData() async {
  final response = await http.get(Uri.parse('https://api.example.com'));
  if (response.statusCode == 200) {
    return response.body;
  }
  throw Exception('Failed to load data');
}
```

### Dio - Advanced HTTP Client
```yaml
dependencies:
  dio: ^5.4.0
```

**When to use:** Complex APIs, interceptors, file uploads
**Pros:** Interceptors, request/response transformation, timeout handling
**Cons:** Heavier than http

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 5),
));

dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options) => options,
  onError: (error) => error,
));

final response = await dio.get('/users');
```

---

## 📄 JSON Serialization

### dart:convert - Built-in
```dart
import 'dart:convert';

final json = jsonEncode({'key': 'value'});
final data = jsonDecode(json) as Map<String, dynamic>;
```

**When to use:** Simple JSON, one-off parsing
**Pros:** No dependencies, built-in
**Cons:** No type safety, manual parsing

### json_serializable - Code Generation
```yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

**When to use:** Complex models, type safety
**Pros:** Type-safe, automatic generation, null safety
**Cons:** Requires build_runner

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String name;
  final int age;
  
  User({required this.name, required this.age});
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// Generate: dart run build_runner build
```

### freezed - Immutable Models
```yaml
dependencies:
  freezed_annotation: ^2.4.1

dev_dependencies:
  build_runner: ^2.4.7
  freezed: ^2.4.5
```

**When to use:** Immutable data classes with JSON
**Pros:** Immutability, copyWith, equality, JSON support
**Cons:** Requires build_runner

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String name,
    required int age,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

---

## 🎯 State Management

### Provider - Lightweight & Simple
```yaml
dependencies:
  provider: ^6.1.1
```

**When to use:** Simple to medium complexity apps
**Pros:** Lightweight, easy to learn, good documentation
**Cons:** Less type-safe than Riverpod

```dart
class Counter with ChangeNotifier {
  int _count = 0;
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

// Usage
Consumer<Counter>(
  builder: (context, counter, child) => Text('${counter.count}'),
)
```

### Riverpod - Type-Safe
```yaml
dependencies:
  flutter_riverpod: ^2.4.9
```

**When to use:** Type-safe state management
**Pros:** Type-safe, testable, no BuildContext needed
**Cons:** Steeper learning curve

```dart
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  void increment() => state++;
}

// Usage
Consumer(
  builder: (context, ref, child) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  },
)
```

### Bloc/Cubit - Event-Driven
```yaml
dependencies:
  bloc: ^8.1.2
  flutter_bloc: ^8.1.3
```

**When to use:** Complex event-driven logic
**Pros:** Testable, scalable, clear separation
**Cons:** More boilerplate

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

// Usage
BlocBuilder<CounterCubit, int>(
  builder: (context, count) => Text('$count'),
)
```

---

## 💉 Dependency Injection

### get_it - Service Locator
```yaml
dependencies:
  get_it: ^7.6.4
```

**When to use:** Service location, singleton management
**Pros:** Simple, lightweight, no reflection
**Cons:** Manual registration

```dart
final getIt = GetIt.instance;

// Register
getIt.registerSingleton<ApiService>(ApiService());
getIt.registerLazySingleton<Database>(() => Database());

// Use
final api = getIt<ApiService>();
```

### Riverpod - Type-Safe DI
- Also provides state management
- Type-safe dependency injection
- No manual registration needed

---

## 🧪 Testing

### package:test - Unit Testing
```yaml
dev_dependencies:
  test: ^1.25.0
  mockito: ^5.4.4
```

```dart
import 'package:test/test.dart';

void main() {
  test('addition test', () {
    expect(2 + 2, 4);
  });
  
  test('throws exception', () {
    expect(() => throw Exception(), throwsException);
  });
}
```

### flutter_test - Widget Testing
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('counter increments', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });
}
```

### integration_test - Integration Testing
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

---

## 💾 Local Storage

### shared_preferences - Key-Value
```yaml
dependencies:
  shared_preferences: ^2.2.2
```

**When to use:** Simple settings, user preferences
**Pros:** Simple, built-in, no setup
**Cons:** Limited to simple types

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('username', 'john');
final username = prefs.getString('username');
```

### Hive - Fast Database
```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

**When to use:** Complex data, fast access
**Pros:** Fast, type-safe, no SQL
**Cons:** Requires setup

```dart
await Hive.initFlutter();
final box = await Hive.openBox('users');
await box.put('user1', User(name: 'John'));
```

### sqflite - SQLite
```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.9.0
```

**When to use:** Complex queries, relational data
**Pros:** SQL support, powerful queries
**Cons:** More complex setup

---

## 🔄 Async Patterns

### Prefer async/await over raw Futures
```dart
// Good
Future<int> countUsers() async {
  try {
    final users = await fetchUsers();
    return users.length;
  } catch (e) {
    return 0;
  }
}

// Avoid
Future<int> countUsers() {
  return fetchUsers()
    .then((users) => users.length)
    .catchError((_) => 0);
}
```

---

## 📊 Library Selection Matrix

| Feature | Provider | Riverpod | Bloc | GetIt |
|---------|----------|----------|------|-------|
| Type-safe | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐ |
| Learning curve | Easy | Medium | Hard | Easy |
| Testability | Good | Excellent | Excellent | Good |
| Boilerplate | Low | Low | High | Low |
| Community | Large | Growing | Large | Large |

---

## 🎯 Recommended Stack

**Minimal App:**
- State: Provider
- HTTP: http
- JSON: json_serializable
- Storage: shared_preferences
- Testing: flutter_test

**Medium App:**
- State: Riverpod
- HTTP: Dio
- JSON: freezed
- Storage: Hive
- DI: get_it
- Testing: flutter_test + mockito

**Large App:**
- State: Riverpod + Bloc
- HTTP: Dio
- JSON: freezed
- Storage: Hive + sqflite
- DI: Riverpod
- Testing: flutter_test + mockito + integration_test

---

**Last Updated:** April 12, 2026  
**Status:** ✅ Active Knowledge Base  
**Confidence Level:** High (Official Documentation)  
**Use Case:** Reference for selecting proper libraries in Dart/Flutter projects

---