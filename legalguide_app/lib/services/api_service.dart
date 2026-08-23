import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_section.dart';
import '../models/legal_matter.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<List<Category>> fetchCategories() async {
    final response = await http
        .get(Uri.parse('$baseUrl/categories/'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw ApiException('Failed to load categories (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Category.fromJson(json)).toList();
  }

  static Future<List<Law>> fetchLaws({int? categoryId}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/laws/'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw ApiException('Failed to load laws (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    List<Law> laws = data.map((json) => Law.fromJson(json)).toList();
    if (categoryId != null) {
      laws = laws.where((law) => law.categoryId == categoryId).toList();
    }
    return laws;
  }

  static Future<List<LegalSection>> fetchSections({int? lawId}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/sections/'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw ApiException('Failed to load sections (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    List<LegalSection> sections =
        data.map((json) => LegalSection.fromJson(json)).toList();
    if (lawId != null) {
      sections = sections.where((sec) => sec.lawId == lawId).toList();
    }
    return sections;
  }

  static Future<List<LegalMatter>> fetchMatters({int? categoryId}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/matters/'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw ApiException('Failed to load matters (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body);
    List<LegalMatter> matters =
        data.map((json) => LegalMatter.fromJson(json)).toList();
    if (categoryId != null) {
      matters = matters.where((m) => m.categoryId == categoryId).toList();
    }
    return matters;
  }
}
