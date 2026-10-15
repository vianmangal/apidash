import 'package:apidash/models/models.dart';
import 'package:apidash/providers/providers.dart';
import 'package:apidash/screens/home_page/editor_pane/details_card/request_pane/ws/ws_recently_sent.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'demo_common.dart';

void main() {
  testWidgets('capture real Recently Sent widget with automatic and manual messages', (tester) async {
    await setupDemo(tester);
    final container = ProviderContainer(overrides: [selectedRequestModelProvider.overrideWith((ref) => const RequestModel(id: 'demo', apiType: APIType.websocket, wsRequestModel: WebSocketRequestModel()))]);
    addTearDown(container.dispose);
    final messages = <WebSocketMessage>[];
    Future<void> stage(int i, String title, String note) async {
      container.read(selectedRequestModelProvider.notifier).state = RequestModel(id: 'demo', apiType: APIType.websocket, wsRequestModel: WebSocketRequestModel(messageHistory: List.of(messages)));
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: demoFrame('1776', 'Keep automatic heartbeats out of Recently Sent', title, note,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Production widget: WsRecentlySent', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
          WsRecentlySent(templates: const [], onReuse: (_) {}, onSaveTemplate: (_, __) {}),
          const SizedBox(height: 24),
          Text('Underlying messageHistory: ${messages.length} events retained', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...messages.map((m) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${m.isAutomatic ? "AUTOMATIC" : "USER SENT"}    ${m.payload}', style: const TextStyle(fontSize: 17)))),
        ]))));
      await capture(tester, '1776-$i');
    }
    await stage(0, '1 / 4   Start with an empty message history', 'Recently Sent should contain only messages deliberately sent by the user.');
    messages.add(const WebSocketMessage(payload: 'custom-heartbeat', isAutomatic: true, messageType: WebSocketMessageType.sent));
    messages.add(const WebSocketMessage(payload: 'tenant-42-ping', isAutomatic: true, messageType: WebSocketMessageType.sent));
    await stage(1, '2 / 4   Add custom automatic heartbeat events', 'Both automatic events remain in messageHistory. Neither appears in Recently Sent.');
    expect(find.text('No recently sent messages'), findsOneWidget);
    messages.add(const WebSocketMessage(payload: 'Hello from the user', messageType: WebSocketMessageType.sent));
    await stage(2, '3 / 4   Add a deliberately sent user message', 'The user message appears in the production Recently Sent widget. Automatic events stay excluded.');
    expect(find.text('Hello from the user'), findsOneWidget);
    messages.add(const WebSocketMessage(payload: 'Heartbeat ping', messageType: WebSocketMessageType.sent));
    await stage(3, '4 / 4   User deliberately sends "Heartbeat ping"', 'A manual message is retained even when its text equals the old hard-coded heartbeat payload.');
    expect(find.text('Heartbeat ping'), findsOneWidget);
    expect(messages.where((m) => m.isAutomatic).length, 2);
  });
}
