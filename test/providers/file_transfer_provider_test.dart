import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux/models/file_metadata.dart';
import 'package:flux/providers/file_transfer_provider.dart';

void main() {
  group('FileTransferNotifier', () {
    test('initial state is empty', () async {
      final container = ProviderContainer();
      final state = await container.read(fileTransferProvider.future);
      expect(state, isEmpty);
    });

    test('addTransfer adds a transfer to the list', () async {
      final container = ProviderContainer();
      final notifier = container.read(fileTransferProvider.notifier);

      final transfer = TransferStatus(
        fileId: 'test-1',
        fileName: 'test.txt',
        state: TransferState.pending,
        totalBytes: 1024,
        transferredBytes: 0,
        startedAt: DateTime.now(),
      );

      await notifier.addTransfer(transfer);

      final state = await container.read(fileTransferProvider.future);
      expect(state, hasLength(1));
      expect(state.first.fileId, 'test-1');
    });

    test('updateTransfer modifies an existing transfer', () async {
      final container = ProviderContainer();
      final notifier = container.read(fileTransferProvider.notifier);

      final transfer = TransferStatus(
        fileId: 'test-1',
        fileName: 'test.txt',
        state: TransferState.pending,
        totalBytes: 1024,
        transferredBytes: 0,
        startedAt: DateTime.now(),
      );

      await notifier.addTransfer(transfer);

      final updated = transfer.copyWith(state: TransferState.inProgress);
      await notifier.updateTransfer('test-1', updated);

      final state = await container.read(fileTransferProvider.future);
      expect(state.first.state, TransferState.inProgress);
    });

    test('pauseTransfer changes state to paused', () async {
      final container = ProviderContainer();
      final notifier = container.read(fileTransferProvider.notifier);

      final transfer = TransferStatus(
        fileId: 'test-1',
        fileName: 'test.txt',
        state: TransferState.inProgress,
        totalBytes: 1024,
        transferredBytes: 512,
        startedAt: DateTime.now(),
      );

      await notifier.addTransfer(transfer);
      await notifier.pauseTransfer('test-1');

      final state = await container.read(fileTransferProvider.future);
      expect(state.first.state, TransferState.paused);
    });

    test('resumeTransfer changes state to inProgress', () async {
      final container = ProviderContainer();
      final notifier = container.read(fileTransferProvider.notifier);

      final transfer = TransferStatus(
        fileId: 'test-1',
        fileName: 'test.txt',
        state: TransferState.paused,
        totalBytes: 1024,
        transferredBytes: 512,
        startedAt: DateTime.now(),
      );

      await notifier.addTransfer(transfer);
      await notifier.resumeTransfer('test-1');

      final state = await container.read(fileTransferProvider.future);
      expect(state.first.state, TransferState.inProgress);
    });

    test('cancelTransfer changes state to cancelled', () async {
      final container = ProviderContainer();
      final notifier = container.read(fileTransferProvider.notifier);

      final transfer = TransferStatus(
        fileId: 'test-1',
        fileName: 'test.txt',
        state: TransferState.inProgress,
        totalBytes: 1024,
        transferredBytes: 512,
        startedAt: DateTime.now(),
      );

      await notifier.addTransfer(transfer);
      await notifier.cancelTransfer('test-1');

      final state = await container.read(fileTransferProvider.future);
      expect(state.first.state, TransferState.cancelled);
    });

    test('removeTransfer removes a transfer from the list', () async {
      final container = ProviderContainer();
      final notifier = container.read(fileTransferProvider.notifier);

      final transfer = TransferStatus(
        fileId: 'test-1',
        fileName: 'test.txt',
        state: TransferState.completed,
        totalBytes: 1024,
        transferredBytes: 1024,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      await notifier.addTransfer(transfer);
      await notifier.removeTransfer('test-1');

      final state = await container.read(fileTransferProvider.future);
      expect(state, isEmpty);
    });

    test('getActiveTransfersCount returns correct count', () async {
      final container = ProviderContainer();
      final notifier = container.read(fileTransferProvider.notifier);

      final transfer1 = TransferStatus(
        fileId: 'test-1',
        fileName: 'test1.txt',
        state: TransferState.inProgress,
        totalBytes: 1024,
        transferredBytes: 512,
        startedAt: DateTime.now(),
      );

      final transfer2 = TransferStatus(
        fileId: 'test-2',
        fileName: 'test2.txt',
        state: TransferState.completed,
        totalBytes: 1024,
        transferredBytes: 1024,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      await notifier.addTransfer(transfer1);
      await notifier.addTransfer(transfer2);

      expect(notifier.getActiveTransfersCount(), 1);
    });

    test('getTotalTransferProgress calculates correctly', () async {
      final container = ProviderContainer();
      final notifier = container.read(fileTransferProvider.notifier);

      final transfer1 = TransferStatus(
        fileId: 'test-1',
        fileName: 'test1.txt',
        state: TransferState.inProgress,
        totalBytes: 1000,
        transferredBytes: 500,
        startedAt: DateTime.now(),
      );

      final transfer2 = TransferStatus(
        fileId: 'test-2',
        fileName: 'test2.txt',
        state: TransferState.inProgress,
        totalBytes: 1000,
        transferredBytes: 750,
        startedAt: DateTime.now(),
      );

      await notifier.addTransfer(transfer1);
      await notifier.addTransfer(transfer2);

      final progress = notifier.getTotalTransferProgress();
      expect(progress, closeTo(0.625, 0.001)); // (500 + 750) / 2000
    });
  });

  group('TransferHistoryNotifier', () {
    test('initial state is empty', () async {
      final container = ProviderContainer();
      final state = await container.read(transferHistoryProvider.future);
      expect(state, isEmpty);
    });

    test('addHistoryEntry adds an entry', () async {
      final container = ProviderContainer();
      final notifier = container.read(transferHistoryProvider.notifier);

      final entry = TransferHistory(
        id: 'history-1',
        deviceId: 'device-1',
        deviceName: 'Test Device',
        fileName: 'test.txt',
        fileSize: 1024,
        direction: TransferDirection.send,
        timestamp: DateTime.now(),
        success: true,
      );

      await notifier.addHistoryEntry(entry);

      final state = await container.read(transferHistoryProvider.future);
      expect(state, hasLength(1));
      expect(state.first.id, 'history-1');
    });

    test('getSuccessfulTransfersCount returns correct count', () async {
      final container = ProviderContainer();
      final notifier = container.read(transferHistoryProvider.notifier);

      final entry1 = TransferHistory(
        id: 'history-1',
        deviceId: 'device-1',
        deviceName: 'Test Device',
        fileName: 'test1.txt',
        fileSize: 1024,
        direction: TransferDirection.send,
        timestamp: DateTime.now(),
        success: true,
      );

      final entry2 = TransferHistory(
        id: 'history-2',
        deviceId: 'device-1',
        deviceName: 'Test Device',
        fileName: 'test2.txt',
        fileSize: 1024,
        direction: TransferDirection.send,
        timestamp: DateTime.now(),
        success: false,
      );

      await notifier.addHistoryEntry(entry1);
      await notifier.addHistoryEntry(entry2);

      expect(notifier.getSuccessfulTransfersCount(), 1);
      expect(notifier.getFailedTransfersCount(), 1);
    });

    test('getTotalBytesTransferred calculates correctly', () async {
      final container = ProviderContainer();
      final notifier = container.read(transferHistoryProvider.notifier);

      final entry1 = TransferHistory(
        id: 'history-1',
        deviceId: 'device-1',
        deviceName: 'Test Device',
        fileName: 'test1.txt',
        fileSize: 1024,
        direction: TransferDirection.send,
        timestamp: DateTime.now(),
        success: true,
      );

      final entry2 = TransferHistory(
        id: 'history-2',
        deviceId: 'device-1',
        deviceName: 'Test Device',
        fileName: 'test2.txt',
        fileSize: 2048,
        direction: TransferDirection.receive,
        timestamp: DateTime.now(),
        success: true,
      );

      await notifier.addHistoryEntry(entry1);
      await notifier.addHistoryEntry(entry2);

      expect(notifier.getTotalBytesTransferred(), 3072);
    });
  });
}
