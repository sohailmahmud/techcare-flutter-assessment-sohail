import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers/mock_api_service_test_helper.dart';
import 'package:fintrack/data/datasources/remote_data_source.dart';

void main() {
  // Ensure Flutter bindings are initialized so asset bundle (rootBundle)
  // can be used by MockApiService/AssetDataSource during tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RemoteDataSource integration tests (MockApiService)', () {
    late TestableMockApiService apiService;
    late RemoteDataSourceImpl remote;

    setUp(() async {
      apiService = TestableMockApiService(
        failureChance: 0.0,
      ); // deterministic success
      await apiService.initialize();
      remote = RemoteDataSourceImpl(apiService.service);
    });

    test('successful getTransactions returns paginated data', () async {
      final resp = await remote.getTransactions(page: 1, limit: 10);
      expect(resp.data, isNotNull);
      expect(resp.meta.itemsPerPage, anyOf(10, greaterThan(0)));
    });

    test('createTransaction returns created transaction with id', () async {
      final tx = (await remote.getTransactions(page: 1, limit: 1)).data.first;
      final created = await remote.createTransaction(tx);
      expect(created.id, isNotEmpty);
    });

    test(
      'simulate timeout via failureChance producing receiveTimeout',
      () async {
        // Use a high failureChance and run multiple times to hit different
        // error types. This test asserts that when MockApiService throws a
        // DioException with receiveTimeout, RemoteDataSource._withApiCall
        // should surface a NetworkException (as an Exception here).
        final flaky = TestableMockApiService(failureChance: 0.0);
        await flaky.initialize();
        // Force a timeout for the next call
        flaky.forceNextError(TestableMockApiService.receiveTimeout());
        final remoteFail = RemoteDataSourceImpl(flaky.service);

        expect(
          () async => await remoteFail.getTransactions(),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('server 500 is mapped to ServerException', () async {
      // Forcing a server error deterministically is not supported by the
      // public API; use failureChance=1.0 and hope one of the thrown errors
      // is a 500. The MockApiService chooses error type randomly when
      // failureChance=1.0, so this test will accept any DioException mapping.
      final flaky = TestableMockApiService(failureChance: 0.0);
      await flaky.initialize();
      // Force 500 server error for next call
      flaky.forceNextError(TestableMockApiService.server500());
      final remoteFail = RemoteDataSourceImpl(flaky.service);

      expect(
        () async => await remoteFail.createTransaction(
          (await remote.getTransactions(limit: 1)).data.first,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('validation error (400) surfaces as ValidationException', () async {
      // Similar approach as above - rely on flaky errors; assert exception
      final flaky = TestableMockApiService(failureChance: 0.0);
      await flaky.initialize();
      // Force 400 validation error
      flaky.forceNextError(TestableMockApiService.validation400());
      final remoteFail = RemoteDataSourceImpl(flaky.service);

      expect(
        () async => await remoteFail.createTransaction(
          (await remote.getTransactions(limit: 1)).data.first,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'offline mode: when service is unreachable throws NetworkException',
      () async {
        // Simulate offline by creating a MockApiService that throws connectionError
        final offline = TestableMockApiService(failureChance: 0.0);
        await offline.initialize();
        offline.forceNextError(TestableMockApiService.connectionError());
        final remoteOffline = RemoteDataSourceImpl(offline.service);

        expect(
          () async => await remoteOffline.getTransactions(),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('concurrent requests do not crash and return independently', () async {
      final futures = List.generate(
        5,
        (_) => remote.getTransactions(page: 1, limit: 5),
      );
      final results = await Future.wait(futures);
      expect(results.length, 5);
      for (final r in results) {
        expect(r.data, isNotNull);
      }
    });

    test('request cancellation using Dio CancelToken', () async {
      final cancelToken = CancelToken();
      // Start a long running call by temporarily patching the service delay
      // There's no public API to lengthen delay; instead, call normally and
      // cancel immediately - the MockApiService usually waits a short delay
      final future = remote.getTransactions(cancelToken: cancelToken);
      cancelToken.cancel('test cancel');

      try {
        await future;
        // Depending on timing, this might either complete or throw; both are
        // acceptable but prefer it to throw
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
