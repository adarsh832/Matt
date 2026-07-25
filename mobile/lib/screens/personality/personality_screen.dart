import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/personality_card.dart';
import 'package:mobile/providers/app_providers.dart';

class PersonalityScreen extends ConsumerStatefulWidget {
  const PersonalityScreen({super.key});

  @override
  ConsumerState<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends ConsumerState<PersonalityScreen> {
  late final PageController _pageController;
  final TextEditingController _customPersonalityController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _personalities = [
    {
      'id': 'coding_partner',
      'icon': const Text(
        '</>', 
        style: TextStyle(
          fontSize: 48, 
          fontWeight: FontWeight.bold, 
          color: AppColors.textPrimary
        )
      ),
      'title': 'Coding Partner',
      'description': 'Writes, debugs and explains code.',
      'tagline': 'Best for Developers',
    },
    {
      'id': 'creative_writer',
      'icon': const Icon(Icons.edit, size: 48, color: AppColors.textPrimary),
      'title': 'Creative Writer',
      'description': 'Crafts stories, poems and creative content.',
      'tagline': 'Best for Writers',
    },
    {
      'id': 'study_buddy',
      'icon': const Icon(Icons.menu_book, size: 48, color: AppColors.textPrimary),
      'title': 'Study Buddy',
      'description': 'Explains concepts and helps with learning.',
      'tagline': 'Best for Students',
    },
    {
      'id': 'custom',
      'icon': const Icon(Icons.tune, size: 48, color: AppColors.textPrimary),
      'title': 'Custom',
      'description': 'Define your own personality.',
      'tagline': 'Make it yours',
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customPersonalityController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'AI Personality',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _personalities.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                      } else {
                        value = (index == _currentPage) ? 1.0 : 0.85;
                      }
                      
                      return Center(
                        child: SizedBox(
                          height: Curves.easeOut.transform(value) * 420,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                      child: _buildCard(index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _personalities.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.textPrimary
                        : AppColors.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                onPressed: () {
                  String selectedPersonality = _personalities[_currentPage]['id'] as String;
                  
                  if (selectedPersonality == 'custom') {
                    final customText = _customPersonalityController.text.trim();
                    final customName = _customNameController.text.trim();
                    if (customText.isNotEmpty) {
                      final nameToUse = customName.isNotEmpty ? customName : 'Custom AI';
                      selectedPersonality = 'custom:$nameToUse|$customText';
                    } else {
                      selectedPersonality = 'coding_partner'; // fallback
                    }
                  }

                  ref.read(personalityProvider.notifier).setPersonality(selectedPersonality);
                  
                  if (ref.read(connectionStateProvider)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamed(context, '/qr_connection');
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    if (_personalities[index]['id'] == 'custom') {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _personalities[index]['icon'] as Widget,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customNameController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Custom Name',
                hintStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customPersonalityController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. You are a pirate who speaks only in riddles...',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _personalities[index]['tagline'] as String,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return PersonalityCard(
      icon: _personalities[index]['icon'] as Widget,
      title: _personalities[index]['title'] as String,
      description: _personalities[index]['description'] as String,
      tagline: _personalities[index]['tagline'] as String,
    );
  }
}
