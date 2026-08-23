import 'package:flutter/material.dart';
import '../repositories/legal_data_repository.dart';
import 'explore_laws_screen.dart';

const arrestDetentionCategoryName = 'Arrest & Detention';

class ArrestDetentionScreen extends StatefulWidget {
  const ArrestDetentionScreen({super.key});

  @override
  State<ArrestDetentionScreen> createState() => _ArrestDetentionScreenState();
}

class _ArrestDetentionScreenState extends State<ArrestDetentionScreen> {
  late Future<int?> _categoryIdFuture;

  @override
  void initState() {
    super.initState();
    _categoryIdFuture = _resolveCategoryId();
  }

  Future<int?> _resolveCategoryId() async {
    final categories = await LegalDataRepository.loadCategories();
    final match = categories.where((c) => c.name == arrestDetentionCategoryName);
    return match.isEmpty ? null : match.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _categoryIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),
          );
        }
        return ExploreLawsScreen(
          lockedCategoryId: snapshot.data,
          title: 'Arrest & Detention',
          showCategoryFilterBar: false,
          showAppBar: true,
        );
      },
    );
  }
}
