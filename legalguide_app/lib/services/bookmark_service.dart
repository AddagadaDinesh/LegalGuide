import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  static const _key = 'lg_bookmarked_section_ids_v1';

  static Future<Set<int>> getBookmarkedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map(int.parse).toSet();
  }

  static Future<bool> isBookmarked(int sectionId) async {
    return (await getBookmarkedIds()).contains(sectionId);
  }

  static Future<void> toggle(int sectionId) async {
    final ids = await getBookmarkedIds();
    if (ids.contains(sectionId)) {
      ids.remove(sectionId);
    } else {
      ids.add(sectionId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.map((id) => id.toString()).toList());
  }

  static Future<int> count() async => (await getBookmarkedIds()).length;
}
