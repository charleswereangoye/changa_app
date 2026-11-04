import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/household_preview.dart';
import 'package:changa_app/features/household/domain/usecases/create_household.dart';
import 'package:changa_app/features/household/domain/usecases/join_household.dart';
import 'package:changa_app/features/household/domain/usecases/preview_household_by_pin.dart';
import 'package:changa_app/features/household/presentation/cubit/create_household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/join_household_cubit.dart';
import 'package:changa_app/features/household/presentation/pages/create_household_page.dart';
import 'package:changa_app/features/household/presentation/pages/household_created_page.dart';
import 'package:changa_app/features/household/presentation/pages/join_household_page.dart';

class MockCreateHousehold extends Mock implements CreateHousehold {}

class MockPreviewHouseholdByPin extends Mock implements PreviewHouseholdByPin {}

class MockJoinHousehold extends Mock implements JoinHousehold {}

void main() {
  final testHousehold = Household(
    id: 'house_123',
    name: 'Kigali Nest',
    type: HouseholdType.apartment,
    expectedMembers: 4,
    pin: '482916',
    adminUid: 'uid_1',
    createdAt: DateTime(2026, 10, 24),
  );

  Widget wrapWithTheme(Widget child, {Size size = const Size(390, 844)}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
  }

  group('HouseholdCreatedPage widget tests', () {
    testWidgets(
      'disables Copy PIN and share buttons when no household is available',
      (tester) async {
        String? sharedText;
        await tester.pumpWidget(
          wrapWithTheme(
            HouseholdCreatedPage(
              household: null,
              onShare: (text) async => sharedText = text,
            ),
          ),
        );

        // No fallback PIN 482 916 is shown
        expect(find.textContaining('4 8 2'), findsNothing);
        expect(find.text('— — —   — — —'), findsOneWidget);

        await tester.tap(find.text('WhatsApp'));
        await tester.pump();
        expect(sharedText, isNull);
      },
    );

    testWidgets(
      'displays formatted PIN and shares invite message when household is loaded',
      (tester) async {
        String? sharedText;
        await tester.pumpWidget(
          wrapWithTheme(
            HouseholdCreatedPage(
              household: testHousehold,
              onShare: (text) async => sharedText = text,
            ),
          ),
        );

        expect(find.text('4 8 2   9 1 6'), findsOneWidget);
        await tester.tap(find.text('WhatsApp'));
        await tester.pump();
        expect(sharedText, 'Join my household on Changa with PIN 482 916');
      },
    );
  });

  group('JoinHouseholdPage widget tests', () {
    testWidgets(
      'shows preview when 6 digits entered and invalidates when digit deleted',
      (tester) async {
        final mockPreview = MockPreviewHouseholdByPin();
        final mockJoin = MockJoinHousehold();

        when(() => mockPreview('482916')).thenAnswer(
          (_) async => Result.success(
            const HouseholdPreview(name: 'Kigali Nest', memberCount: 4),
          ),
        );

        final cubit = JoinHouseholdCubit(
          previewHouseholdByPin: mockPreview,
          joinHousehold: mockJoin,
        );

        await tester.pumpWidget(wrapWithTheme(JoinHouseholdPage(cubit: cubit)));

        final fields = find.byType(TextField);
        expect(fields, findsNWidgets(6));

        // Paste 6-digit PIN into first box
        await tester.enterText(fields.first, '482916');
        await tester.pumpAndSettle();

        expect(find.text('Kigali Nest'), findsOneWidget);
        expect(find.text('4 members'), findsOneWidget);

        // Delete last digit -> preview disappears
        await tester.enterText(fields.at(5), '');
        await tester.pumpAndSettle();

        expect(find.text('Kigali Nest'), findsNothing);
        await cubit.close();
      },
    );
  });

  group('Responsive 320px and Landscape layout regression tests', () {
    for (final size in const [Size(320, 568), Size(640, 320)]) {
      testWidgets(
        'renders Create, Created, and Join pages at $size without overflow',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final createCubit = CreateHouseholdCubit(
            createHousehold: MockCreateHousehold(),
          );
          final joinCubit = JoinHouseholdCubit(
            previewHouseholdByPin: MockPreviewHouseholdByPin(),
            joinHousehold: MockJoinHousehold(),
          );

          await tester.pumpWidget(
            wrapWithTheme(CreateHouseholdPage(cubit: createCubit), size: size),
          );
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            wrapWithTheme(
              HouseholdCreatedPage(household: testHousehold),
              size: size,
            ),
          );
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            wrapWithTheme(JoinHouseholdPage(cubit: joinCubit), size: size),
          );
          expect(tester.takeException(), isNull);

          await createCubit.close();
          await joinCubit.close();
        },
      );
    }
  });
}
