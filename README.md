# API Dash PR demonstration assets

Created on 15 October 2026 from the original PR commits using Flutter 3.47.1 and Dart 3.13.1 on macOS. These are captioned sequences of real Flutter test captures, with MP4 videos and animated GIF equivalents. They are automated widget/provider demonstrations, not recordings of a full interactive application session.

## PR #1776

- Source commit: `3952bd6f9a43565245d7c4c724919a6575489ce6`
- [MP4 video](pr-1776-demo.mp4) / [animated GIF](pr-1776-demo.gif)
- Renders the production `WsRecentlySent` widget with controlled message-history inputs. Custom automatic messages remain in the underlying history and are excluded from Recently Sent; deliberate user messages, including `Heartbeat ping`, appear.
- This capture does not establish a live WebSocket connection or exercise heartbeat scheduling/environment substitution.
- Verification: 35 tests passed: the capture harness plus the original WebSocket model and Recently Sent widget tests. The complete monorepo suite was not rerun.
- Current context: upstream PR #1799 was merged on 12 September 2026 and closed issue #1751. Maintainers should determine whether any independent behavior from #1776 is still needed.

## PR #1780

- Source commit: `0735bd71af7e079d730d3e7597699f67aaad315b`
- [MP4 video](pr-1780-demo.mp4) / [animated GIF](pr-1780-demo.gif)
- Seeds real temporary Hive stores, invokes the original `CollectionStateNotifier.clearData()`, and reads actual persisted values. The request collection and in-memory selection/sequence clear while Global environment data, history and Dashbot messages remain. Closing and reopening the Hive boxes confirms the preserved values remain on disk.
- This is a provider/storage demo, not a full application restart recording. Settings/shared preferences are not exercised by this capture.
- Verification: 2 tests passed: the capture harness and the original Clear Data regression test. The complete monorepo suite was not rerun.
- Current context: the maintainer said on 26 September 2026 that Clear Data should clear everything, and a collaborator said on 2 October that work should follow storage migration PR #1695. This original PR's request-only scope differs from that direction; the demo documents its behavior without claiming current design approval.

## Reproduce captures

Check out the original PR commit in a disposable API Dash checkout and run `flutter pub get`. Copy `source/demo_common.dart` into `test/demo_common.dart`, and copy the relevant `source/pr1776_demo_capture_test.dart` or `source/pr1780_demo_capture_test.dart` into `test/pr_demo_capture_test.dart`.

Run:

```sh
flutter --no-version-check test --no-pub test/pr_demo_capture_test.dart --reporter expanded
```

The helper writes PNG captures into `demo-frames/` by default. Set `DEMO_FRAMES` to select another output directory. On macOS it loads the system Arial font. Set `DEMO_FONT` to an available TrueType font path on another platform. All persistence data is created in an isolated temporary directory.

AI assistance disclosure: Codex helped create and verify these demo materials. No application implementation changes were made for this demo task.
