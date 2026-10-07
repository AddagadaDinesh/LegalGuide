import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legalguide_app/services/bookmark_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BookmarkService.initForUser(null);
  });

  group('Account-Specific Saved Items Tests (TEST 1 to TEST 7)', () {
    test('TEST 1: Login Account A and save 3 items -> Account A sees 3 saved items', () async {
      await BookmarkService.onUserLoggedIn('account_a_101');
      expect(await BookmarkService.getBookmarkedIds(), isEmpty);
      expect(await BookmarkService.count(), 0);

      // Save 3 items: 1, 2, 3
      await BookmarkService.toggle(1);
      await BookmarkService.toggle(2);
      await BookmarkService.toggle(3);

      final savedA = await BookmarkService.getBookmarkedIds();
      expect(savedA, {1, 2, 3});
      expect(await BookmarkService.count(), 3);
      expect(await BookmarkService.isBookmarked(1), isTrue);
      expect(await BookmarkService.isBookmarked(2), isTrue);
      expect(await BookmarkService.isBookmarked(3), isTrue);
    });

    test('TEST 2: Logout Account A -> No Account A saved items displayed while logged out', () async {
      // Login Account A and save 3 items
      await BookmarkService.onUserLoggedIn('account_a_101');
      await BookmarkService.toggle(1);
      await BookmarkService.toggle(2);
      await BookmarkService.toggle(3);
      expect(await BookmarkService.count(), 3);

      // Logout Account A
      await BookmarkService.onUserLoggedOut();

      // Logged out / guest must NOT see Account A's items
      final loggedOutItems = await BookmarkService.getBookmarkedIds();
      expect(loggedOutItems, isEmpty);
      expect(await BookmarkService.count(), 0);
      expect(await BookmarkService.isBookmarked(1), isFalse);
    });

    test('TEST 3: Login Account B -> Account B sees only Account B items (empty initially)', () async {
      // Account A has 3 saved items
      await BookmarkService.onUserLoggedIn('account_a_101');
      await BookmarkService.toggle(1);
      await BookmarkService.toggle(2);
      await BookmarkService.toggle(3);
      await BookmarkService.onUserLoggedOut();

      // Account B logs in on same phone/app
      await BookmarkService.onUserLoggedIn('account_b_102');

      // Account B has never saved anything -> strictly empty
      final savedB = await BookmarkService.getBookmarkedIds();
      expect(savedB, isEmpty);
      expect(await BookmarkService.count(), 0);
      expect(await BookmarkService.isBookmarked(1), isFalse);
      expect(await BookmarkService.isBookmarked(2), isFalse);
      expect(await BookmarkService.isBookmarked(3), isFalse);
    });

    test('TEST 4: Account B saves one item -> Account B sees 1 item', () async {
      // Account A has 3 saved items
      await BookmarkService.onUserLoggedIn('account_a_101');
      await BookmarkService.toggle(1);
      await BookmarkService.toggle(2);
      await BookmarkService.toggle(3);
      await BookmarkService.onUserLoggedOut();

      // Account B logs in and saves Law 5
      await BookmarkService.onUserLoggedIn('account_b_102');
      await BookmarkService.toggle(5);

      final savedB = await BookmarkService.getBookmarkedIds();
      expect(savedB, {5});
      expect(await BookmarkService.count(), 1);
      expect(await BookmarkService.isBookmarked(5), isTrue);
      expect(await BookmarkService.isBookmarked(1), isFalse);
    });

    test('TEST 5: Logout Account B, Login Account A -> Account A sees original 3 items', () async {
      // Account A saves 1, 2, 3
      await BookmarkService.onUserLoggedIn('account_a_101');
      await BookmarkService.toggle(1);
      await BookmarkService.toggle(2);
      await BookmarkService.toggle(3);
      await BookmarkService.onUserLoggedOut();

      // Account B saves 5
      await BookmarkService.onUserLoggedIn('account_b_102');
      await BookmarkService.toggle(5);
      await BookmarkService.onUserLoggedOut();

      // Account A logs in again
      await BookmarkService.onUserLoggedIn('account_a_101');

      final savedA = await BookmarkService.getBookmarkedIds();
      expect(savedA, {1, 2, 3});
      expect(await BookmarkService.count(), 3);
      expect(await BookmarkService.isBookmarked(5), isFalse);
    });

    test('TEST 6: Login Account B again -> Account B sees its own 1 item', () async {
      // Setup both accounts
      await BookmarkService.onUserLoggedIn('account_a_101');
      await BookmarkService.toggle(1);
      await BookmarkService.toggle(2);
      await BookmarkService.toggle(3);
      await BookmarkService.onUserLoggedOut();

      await BookmarkService.onUserLoggedIn('account_b_102');
      await BookmarkService.toggle(5);
      await BookmarkService.onUserLoggedOut();

      // Switch back and forth
      await BookmarkService.onUserLoggedIn('account_a_101');
      expect(await BookmarkService.getBookmarkedIds(), {1, 2, 3});
      await BookmarkService.onUserLoggedOut();

      // Account B logs in
      await BookmarkService.onUserLoggedIn('account_b_102');
      final savedB = await BookmarkService.getBookmarkedIds();
      expect(savedB, {5});
      expect(await BookmarkService.count(), 1);
    });

    test('TEST 7: Offline isolation and storage namespacing verification', () async {
      final prefs = await SharedPreferences.getInstance();

      await BookmarkService.onUserLoggedIn('user_alpha');
      await BookmarkService.toggle(10);
      await BookmarkService.toggle(20);

      await BookmarkService.onUserLoggedIn('user_beta');
      await BookmarkService.toggle(30);

      // Verify physical SharedPreferences keys are completely namespaced
      expect(prefs.getStringList('lg_saved_user_user_alpha_v2'), ['10', '20']);
      expect(prefs.getStringList('lg_saved_user_user_beta_v2'), ['30']);
      expect(prefs.getStringList('lg_bookmarked_section_ids_v1'), isNull); // old global key is not used
    });
  });
}
