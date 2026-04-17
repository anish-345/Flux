# UI AsyncValue Integration Guide

**Date:** April 12, 2026  
**Purpose:** Guide for updating UI screens to handle AsyncValue states from AsyncNotifier providers

---

## 🎯 Overview

Now that `FileTransferNotifier` and `TransferHistoryNotifier` use `AsyncNotifier`, the UI must handle `AsyncValue` states properly. This guide shows the correct patterns.

---

## 📋 AsyncValue States

`AsyncValue` has three states:

```dart
AsyncValue<T>
├── data(T value)           // Success state with data
├── loading()               // Loading state
└── error(Object, Stack)    // Error state with exception
```

---

## 🎨 UI Patterns

### Pattern 1: Using `when()` for Complete Handling

**Best for:** Screens that need to show loading, error, and data states

```dart
Consumer(
  builder: (context, ref, child) {
    final transfersAsync = ref.watch(fileTransferProvider);
    
    return transfersAsync.when(
      // Loading state
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      
      // Error state
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(fileTransferProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      
      // Data state
      data: (transfers) => ListView.builder(
        itemCount: transfers.length,
        itemBuilder: (context, index) {
          final transfer = transfers[index];
          return TransferTile(transfer: transfer);
        },
      ),
    );
  },
)
```

---

### Pattern 2: Using `whenData()` for Data-Only Handling

**Best for:** Widgets that only care about data (assume loading/error handled elsewhere)

```dart
Consumer(
  builder: (context, ref, child) {
    final transfersAsync = ref.watch(fileTransferProvider);
    
    return transfersAsync.whenData((transfers) {
      if (transfers.isEmpty) {
        return const Center(
          child: Text('No transfers yet'),
        );
      }
      
      return ListView.builder(
        itemCount: transfers.length,
        itemBuilder: (context, index) {
          final transfer = transfers[index];
          return TransferTile(transfer: transfer);
        },
      );
    }).value ?? const SizedBox.shrink();
  },
)
```

---

### Pattern 3: Using `maybeWhen()` for Selective Handling

**Best for:** Widgets that only need to handle specific states

```dart
Consumer(
  builder: (context, ref, child) {
    final transfersAsync = ref.watch(fileTransferProvider);
    
    return transfersAsync.maybeWhen(
      // Only handle error state
      error: (error, stackTrace) => ErrorWidget(error: error),
      
      // Default to data state (or empty if loading)
      orElse: () => const SizedBox.shrink(),
    );
  },
)
```

---

### Pattern 4: Using `map()` for Custom Handling

**Best for:** Complex state transformations

```dart
Consumer(
  builder: (context, ref, child) {
    final transfersAsync = ref.watch(fileTransferProvider);
    
    return transfersAsync.map(
      data: (asyncData) => TransferList(transfers: asyncData.value),
      loading: (_) => const LoadingWidget(),
      error: (asyncError) => ErrorWidget(error: asyncError.error),
    );
  },
)
```

---

## 🔄 Handling State Changes

### Triggering State Updates

```dart
Consumer(
  builder: (context, ref, child) {
    final notifier = ref.read(fileTransferProvider.notifier);
    
    return ElevatedButton(
      onPressed: () async {
        final transfer = TransferStatus(...);
        await notifier.addTransfer(transfer);
        // State automatically updates via AsyncValue.guard()
      },
      child: const Text('Add Transfer'),
    );
  },
)
```

### Refreshing Data

```dart
Consumer(
  builder: (context, ref, child) {
    return ElevatedButton(
      onPressed: () {
        // Refresh the provider
        ref.refresh(fileTransferProvider);
      },
      child: const Text('Refresh'),
    );
  },
)
```

---

## 📱 Complete Screen Example

```dart
class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(fileTransferProvider);
    final notifier = ref.read(fileTransferProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(fileTransferProvider),
          ),
        ],
      ),
      body: transfersAsync.when(
        // Loading state
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // Error state
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(fileTransferProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),

        // Data state
        data: (transfers) {
          if (transfers.isEmpty) {
            return const Center(
              child: Text('No transfers yet'),
            );
          }

          return ListView.builder(
            itemCount: transfers.length,
            itemBuilder: (context, index) {
              final transfer = transfers[index];
              return TransferTile(
                transfer: transfer,
                onPause: () => notifier.pauseTransfer(transfer.fileId),
                onResume: () => notifier.resumeTransfer(transfer.fileId),
                onCancel: () => notifier.cancelTransfer(transfer.fileId),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add transfer screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## 🎯 Common UI Patterns

### Pattern: Active Transfers Only

```dart
final activeTransfersProvider = Provider<AsyncValue<List<TransferStatus>>>((ref) {
  final transfers = ref.watch(fileTransferProvider);
  return transfers.whenData(
    (list) => list.where((t) => t.state.isActive).toList(),
  );
});

// Usage in UI
Consumer(
  builder: (context, ref, child) {
    final activeAsync = ref.watch(activeTransfersProvider);
    
    return activeAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
      data: (active) => Text('${active.length} active transfers'),
    );
  },
)
```

---

### Pattern: Transfer Progress

```dart
Consumer(
  builder: (context, ref, child) {
    final progressAsync = ref.watch(totalTransferProgressProvider);
    
    return progressAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => const SizedBox.shrink(),
      data: (progress) => LinearProgressIndicator(value: progress),
    );
  },
)
```

---

### Pattern: Transfer History

```dart
Consumer(
  builder: (context, ref, child) {
    final historyAsync = ref.watch(transferHistoryProvider);
    
    return historyAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => Text('Error loading history: $e'),
      data: (history) => ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final entry = history[index];
          return HistoryTile(entry: entry);
        },
      ),
    );
  },
)
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Accessing `.value` directly

```dart
// WRONG - will crash if loading or error
final transfers = ref.watch(fileTransferProvider).value;
```

### ✅ Correct: Use `.when()` or `.whenData()`

```dart
// RIGHT
final transfersAsync = ref.watch(fileTransferProvider);
return transfersAsync.when(
  data: (transfers) => ...,
  loading: () => ...,
  error: (e, st) => ...,
);
```

---

### ❌ Mistake 2: Not handling loading state

```dart
// WRONG - no loading indicator
return transfersAsync.whenData((transfers) => TransferList(transfers));
```

### ✅ Correct: Show loading indicator

```dart
// RIGHT
return transfersAsync.when(
  loading: () => const CircularProgressIndicator(),
  data: (transfers) => TransferList(transfers),
  error: (e, st) => ErrorWidget(error: e),
);
```

---

### ❌ Mistake 3: Forgetting to handle errors

```dart
// WRONG - errors silently fail
return transfersAsync.whenData((transfers) => TransferList(transfers));
```

### ✅ Correct: Always handle errors

```dart
// RIGHT
return transfersAsync.when(
  data: (transfers) => TransferList(transfers),
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorWidget(error: e),
);
```

---

## 🧪 Testing AsyncValue UI

```dart
testWidgets('TransfersScreen shows loading state', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fileTransferProvider.overrideWith((ref) async => []),
      ],
      child: const MyApp(),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('TransfersScreen shows transfers', (tester) async {
  final transfers = [
    TransferStatus(...),
    TransferStatus(...),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fileTransferProvider.overrideWith((ref) async => transfers),
      ],
      child: const MyApp(),
    ),
  );

  expect(find.byType(TransferTile), findsNWidgets(2));
});

testWidgets('TransfersScreen shows error state', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fileTransferProvider.overrideWith(
          (ref) => AsyncValue.error(Exception('Test error'), StackTrace.current),
        ),
      ],
      child: const MyApp(),
    ),
  );

  expect(find.byType(ErrorWidget), findsOneWidget);
});
```

---

## 📚 Reference

**AsyncValue Methods:**
- `when()` - Handle all three states
- `whenData()` - Handle data state only
- `maybeWhen()` - Handle specific states
- `map()` - Transform states
- `value` - Get data (nullable)
- `isLoading` - Check if loading
- `hasError` - Check if error

**Provider Methods:**
- `ref.watch()` - Watch provider for changes
- `ref.read()` - Read provider once
- `ref.refresh()` - Refresh provider
- `ref.invalidate()` - Invalidate provider

---

## ✅ Checklist for UI Updates

- [ ] Replace all `.value` accesses with `.when()`
- [ ] Add loading indicators for all async operations
- [ ] Add error handling for all async operations
- [ ] Test loading state
- [ ] Test error state
- [ ] Test data state
- [ ] Test state transitions
- [ ] Add retry buttons for errors
- [ ] Add refresh buttons where appropriate
- [ ] Test with real data

---

**Status:** Ready for implementation  
**Confidence Level:** High (Based on official Riverpod patterns)
