import 'package:flutter/material.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/personality_card.dart';

class PersonalityScreen extends StatefulWidget {
  const PersonalityScreen({super.key});

  @override
  State<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends State<PersonalityScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _personalities = [
    {
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
      'icon': const Icon(Icons.edit, size: 48, color: AppColors.textPrimary),
      'title': 'Creative Writer',
      'description': 'Crafts stories, poems and creative content.',
      'tagline': 'Best for Writers',
    },
    {
      'icon': const Icon(Icons.menu_book, size: 48, color: AppColors.textPrimary),
      'title': 'Study Buddy',
      'description': 'Explains concepts and helps with learning.',
      'tagline': 'Best for Students',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
                      child: PersonalityCard(
                        icon: _personalities[index]['icon'] as Widget,
                        title: _personalities[index]['title'] as String,
                        description: _personalities[index]['description'] as String,
                        tagline: _personalities[index]['tagline'] as String,
                      ),
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
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/qr_connection');
                },
                borderRadius: BorderRadius.circular(12),
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
}
