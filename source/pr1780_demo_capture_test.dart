import 'dart:io';
import 'package:apidash/consts.dart';
import 'package:apidash/models/models.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/services/services.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'demo_common.dart';

void main() {
  testWidgets('capture actual clearData persistence before and after', (tester) async {
    await setupDemo(tester);
    late Directory dir;
    late ProviderContainer container;
    late CollectionStateNotifier notifier;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('apidash-pr1780-demo-');
      expect(await initHiveBoxes(true, dir.path), true);
      await hiveHandler.setIds(['request-id']);
      await hiveHandler.setRequestModel('request-id', const RequestModel(id: 'request-id', httpRequestModel: HttpRequestModel()).toJson());
      await hiveHandler.setEnvironmentIds([kGlobalEnvironmentId]);
      await hiveHandler.setEnvironment(kGlobalEnvironmentId, const EnvironmentModel(id: kGlobalEnvironmentId, name: 'Global', values: [EnvironmentVariableModel(key: 'baseUrl', value: 'https://example.com', enabled: true)]).toJson());
      await hiveHandler.setHistoryIds(['history-id']);
      await hiveHandler.setHistoryMeta('history-id', {'id': 'history-id'});
      await hiveHandler.setHistoryRequest('history-id', {'id': 'history-id'});
      await hiveHandler.saveDashbotMessages('saved messages');
      container = ProviderContainer();
      notifier = container.read(collectionStateNotifierProvider.notifier);
      container.read(environmentsStateNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
    });
    Future<void> stage(int i, HiveHandler handler, String title, String note) async {
      late List<List<String>> rows;
      await tester.runAsync(() async {
        rows = [
          ['Request collection on disk', handler.getRequestModel('request-id') == null ? 'EMPTY' : '1 saved request'],
          ['Global environment', handler.getEnvironment(kGlobalEnvironmentId) == null ? 'MISSING' : 'baseUrl = https://example.com'],
          ['History metadata', handler.getHistoryMeta('history-id') == null ? 'MISSING' : 'history-id retained'],
          ['History request', await handler.getHistoryRequest('history-id') == null ? 'MISSING' : 'history-id retained'],
          ['Dashbot messages', '${await handler.getDashbotMessages()}'],
        ];
      });
      await tester.pumpWidget(demoFrame('1780', 'Clear requests while preserving other stores', title, note,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Actual Hive store values (temporary workspace)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [SizedBox(width: 325, child: Text(r[0], style: const TextStyle(fontSize: 18))), Text(r[1], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff4355a8)))]))),
          const Divider(),
          Text(i == 0 ? 'In memory: 1 request selected' : i == 1 ? 'In memory: 0 requests; selection null; Global variable still available' : 'Hive boxes closed and reopened; values read from disk again', style: const TextStyle(fontSize: 16)),
        ])));
      await capture(tester, '1780-$i');
    }
    await stage(0, hiveHandler, '1 / 3   Seed requests, Global environment, history and Dashbot', 'This demonstrates the original PR scope: clear requests only. The provider uses real Hive stores.');
    await tester.runAsync(() async { await notifier.clearData(); });
    expect(container.read(collectionStateNotifierProvider), isEmpty);
    expect(container.read(selectedIdStateProvider), isNull);
    expect(container.read(requestSequenceProvider), isEmpty);
    expect(container.read(availableEnvironmentVariablesStateProvider)[kGlobalEnvironmentId]!.single.key, 'baseUrl');
    await stage(1, hiveHandler, '2 / 3   Execute and await CollectionStateNotifier.clearData()', 'Requests and selection are cleared. Global variables, history and Dashbot data remain intact.');
    late HiveHandler reopened;
    await tester.runAsync(() async {
      container.dispose();
      await Hive.close();
      expect(await openHiveBoxes(), true);
      reopened = HiveHandler();
      expect(reopened.getRequestModel('request-id'), isNull);
      expect(reopened.getEnvironment(kGlobalEnvironmentId), isNotNull);
      expect(reopened.getHistoryMeta('history-id'), isNotNull);
      expect(await reopened.getHistoryRequest('history-id'), isNotNull);
      expect(await reopened.getDashbotMessages(), 'saved messages');
    });
    await stage(2, reopened, '3 / 3   Close and reopen the Hive boxes', 'Preservation survives reopening disk storage. This is a provider demo, not a full app restart recording.');
    await tester.runAsync(() async { await Hive.close(); await dir.delete(recursive: true); });
  });
}
