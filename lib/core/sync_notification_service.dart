import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../domain/repositories/transaction_repository.dart';

/// Service responsible for surfacing sync results to the UI.
///
/// It exposes a simple stream of SyncResult so UI layers can observe
/// detailed outcomes, and also supports showing SnackBars via an
/// externally-provided [ScaffoldMessengerState] key.
class SyncNotificationService {
  final _controller = StreamController<SyncResult>.broadcast();
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  Future<Either<dynamic, SyncResult>> Function(List<ItemSyncResult>)?
  _retryHandler;

  Stream<SyncResult> get stream => _controller.stream;

  void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  void setRetryHandler(
    Future<Either<dynamic, SyncResult>> Function(List<ItemSyncResult>) handler,
  ) {
    _retryHandler = handler;
  }

  void notify(SyncResult result) {
    _controller.add(result);

    // If a ScaffoldMessenger key is available, show a brief summary SnackBar
    try {
      final messenger = _scaffoldMessengerKey?.currentState;
      if (messenger != null) {
        final successCount = result.succeededOperationIds.length;
        final failureCount = result.failed.length;
        final message = failureCount == 0
            ? 'Sync succeeded: $successCount operations'
            : 'Sync finished: $successCount succeeded, $failureCount failed';

        // If there are failures, offer a Details action which opens a dialog
        // with per-item information and a Retry button. Otherwise, just show
        // a simple success SnackBar.
        if (failureCount == 0) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        } else {
          // Show a SnackBar with an inline Details button (in the content)
          // and a Retry action (SnackBarAction) that triggers immediate retry.
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Expanded(child: Text(message)),
                  TextButton(
                    onPressed: () => _showFailureDialog(result),
                    child: const Text(
                      'Details',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              action: _retryHandler != null
                  ? SnackBarAction(
                      label: 'Retry',
                      onPressed: () async {
                        try {
                          await _retryHandler?.call(result.failed);
                        } catch (_) {}
                      },
                    )
                  : null,
            ),
          );
        }
      }
    } catch (_) {
      // Ignore UI errors
    }
  }

  void _showFailureDialog(SyncResult result) {
    final ctx = _scaffoldMessengerKey?.currentContext;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sync Failures'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: result.failed.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = result.failed[index];
                return ListTile(
                  title: Text(
                    '${item.operationType.toUpperCase()} ${item.resourceType}',
                  ),
                  subtitle: Text(item.errorMessage),
                  isThreeLine: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (_retryHandler != null)
              TextButton(
                onPressed: () async {
                  try {
                    Navigator.of(context).pop();
                    await _retryHandler?.call(result.failed);
                  } catch (_) {}
                },
                child: const Text('Retry'),
              ),
          ],
        );
      },
    );
  }

  void dispose() {
    _controller.close();
  }
}
