import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/localization/app_strings.dart';
import 'package:legalguide_app/models/chat_message.dart';
import 'package:legalguide_app/screens/assistant_chat_screen.dart';
import 'package:legalguide_app/services/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'lg_language_v1': 'en'});
    await LocaleService.init();
    await LocaleService.setLanguage('en');
  });

  group('AI Assistant User Question Copy Feature Tests', () {
    testWidgets('English user question shows copy button and copies exact text to clipboard', (tester) async {
      final List<Map<String, dynamic>> clipboardLog = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLog.add(Map<String, dynamic>.from(methodCall.arguments as Map));
          }
          return null;
        },
      );

      const englishQuestion = 'What should I do if a police officer stops me? (Section 47)';
      final testMessage = ChatMessage(
        conversationId: 'test_c1',
        text: englishQuestion,
        isUser: true,
        timestamp: DateTime(2026, 10, 7, 10, 0),
        language: 'en',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantPanel(initialMessages: [testMessage]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify user question bubble is rendered
      expect(find.text(englishQuestion), findsOneWidget);

      // Verify copy button is rendered
      final copyButtonFinder = find.byKey(const ValueKey('copy_user_question_inkwell'));
      expect(copyButtonFinder, findsOneWidget);

      // Tap the copy button
      await tester.tap(copyButtonFinder);
      await tester.pump();

      // Verify SnackBar toast "Question copied" appears
      expect(find.text('Question copied'), findsOneWidget);

      // Verify exact clipboard content matches original text exactly (preserving punctuation, spaces, case)
      expect(clipboardLog, isNotEmpty);
      expect(clipboardLog.last['text'], englishQuestion);
    });

    testWidgets('Telugu user question copies exact Telugu text without modification', (tester) async {
      final List<Map<String, dynamic>> clipboardLog = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLog.add(Map<String, dynamic>.from(methodCall.arguments as Map));
          }
          return null;
        },
      );

      await LocaleService.setLanguage('te');
      const teluguQuestion = 'పోలీసులు నన్ను అదుపులోకి తీసుకుంటే నా ప్రాథమిక హక్కులు ఏమిటి?';
      final testMessage = ChatMessage(
        conversationId: 'test_c2',
        text: teluguQuestion,
        isUser: true,
        timestamp: DateTime(2026, 10, 7, 10, 0),
        language: 'te',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantPanel(initialMessages: [testMessage]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(teluguQuestion), findsOneWidget);

      final copyButtonFinder = find.byKey(const ValueKey('copy_user_question_inkwell'));
      expect(copyButtonFinder, findsOneWidget);

      await tester.tap(copyButtonFinder);
      await tester.pump();

      // Check localized Telugu snackbar
      expect(find.text(tr('Question copied')), findsOneWidget);

      expect(clipboardLog, isNotEmpty);
      expect(clipboardLog.last['text'], teluguQuestion);
    });

    testWidgets('Hindi user question copies exact Hindi text without modification', (tester) async {
      final List<Map<String, dynamic>> clipboardLog = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLog.add(Map<String, dynamic>.from(methodCall.arguments as Map));
          }
          return null;
        },
      );

      await LocaleService.setLanguage('hi');
      const hindiQuestion = 'यदि कोई पुलिस अधिकारी मुझे हिरासत में लेता है तो मेरे अधिकार क्या हैं?';
      final testMessage = ChatMessage(
        conversationId: 'test_c3',
        text: hindiQuestion,
        isUser: true,
        timestamp: DateTime(2026, 10, 7, 10, 0),
        language: 'hi',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantPanel(initialMessages: [testMessage]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(hindiQuestion), findsOneWidget);

      final copyButtonFinder = find.byKey(const ValueKey('copy_user_question_inkwell'));
      expect(copyButtonFinder, findsOneWidget);

      await tester.tap(copyButtonFinder);
      await tester.pump();

      // Check localized Hindi snackbar
      expect(find.text(tr('Question copied')), findsOneWidget);

      expect(clipboardLog, isNotEmpty);
      expect(clipboardLog.last['text'], hindiQuestion);
    });

    testWidgets('Very long question wraps cleanly on narrow screens without overflow', (tester) async {
      // Set narrow phone dimensions (320 x 640)
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const veryLongQuestion =
          'What are the full procedural requirements when a police officer stops a citizen during a traffic checkpoint late at night in Hyderabad, demands vehicle registration papers, asks for a breath analyser test, refuses to state their name and police station, and threatens vehicle seizure under Section 185 and BNSS Section 47?';

      final testMessage = ChatMessage(
        conversationId: 'test_c4',
        text: veryLongQuestion,
        isUser: true,
        timestamp: DateTime(2026, 10, 7, 10, 0),
        language: 'en',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantPanel(initialMessages: [testMessage]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(veryLongQuestion), findsOneWidget);
      expect(find.byKey(const ValueKey('copy_user_question_inkwell')), findsOneWidget);

      // Verify no RenderFlex overflow error was triggered
      expect(tester.takeException(), isNull);
    });

    testWidgets('User question Copy and AI answer Copy operate independently', (tester) async {
      final List<String> copiedTexts = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedTexts.add((methodCall.arguments as Map)['text'] as String);
          }
          return null;
        },
      );

      const question = 'Is bail a matter of right for bailable offences?';
      const aiReply =
        '### ⚡ Key Points\n'
        '• Yes, under Section 479 of the Bharatiya Nagarik Suraksha Sanhita, 2023 (BNSS), bail is a statutory right for bailable offences.\n\n'
        '### 📋 What You Should Do\n'
        '1. Request the station bail application.\n'
        '2. Furnish suitable sureties.';

      final userMsg = ChatMessage(
        conversationId: 'test_c5',
        text: question,
        isUser: true,
        timestamp: DateTime(2026, 10, 7, 10, 0),
        language: 'en',
      );
      final aiMsg = ChatMessage(
        conversationId: 'test_c5',
        text: aiReply,
        isUser: false,
        timestamp: DateTime(2026, 10, 7, 10, 1),
        language: 'en',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantPanel(initialMessages: [userMsg, aiMsg]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Copy user question
      final userCopyFinder = find.byKey(const ValueKey('copy_user_question_inkwell'));
      expect(userCopyFinder, findsOneWidget);
      await tester.tap(userCopyFinder);
      await tester.pump();

      expect(copiedTexts.last, question);

      // 2. Look for AI response Card and its copy button
      final aiCopyFinder = find.widgetWithText(InkWell, tr('Copy'));
      expect(aiCopyFinder, findsOneWidget);
      await tester.tap(aiCopyFinder);
      await tester.pump();

      expect(copiedTexts.length, 2);
      // AI answer text is different from original question
      expect(copiedTexts.last, isNot(equals(question)));
      expect(copiedTexts.last, contains('Bharatiya Nagarik Suraksha Sanhita'));
    });

    testWidgets('Live sending via TextField also attaches Copy button to newly sent question', (tester) async {
      final List<Map<String, dynamic>> clipboardLog = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLog.add(Map<String, dynamic>.from(methodCall.arguments as Map));
          }
          return null;
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.tekartik.sqflite'),
        (call) async {
          if (call.method == 'getDatabasesPath') return '/mock/path';
          if (call.method == 'openDatabase') return 1;
          if (call.method == 'query') return [];
          if (call.method == 'rawQuery') return [];
          if (call.method == 'insert') return 1;
          return null;
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async => null,
      );

      const liveQuestion = 'How to register a cyber crime complaint?';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantPanel(initialMessages: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), liveQuestion);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send_message_button')));
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text(liveQuestion), findsAtLeastNWidgets(1));
      final copyButton = find.byKey(const ValueKey('copy_user_question_inkwell'));
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pump();

      expect(find.text('Question copied'), findsOneWidget);
      expect(clipboardLog.last['text'], liveQuestion);

      // Drain AnalyticsService debounce timer and SnackBar timer
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
