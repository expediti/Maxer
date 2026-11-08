import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      'number': '01',
      'title': 'Discover opportunities that match your profile.',
      'description':
          'Track verified government recruitment, central & state exams, PSU vacancies, admissions, scholarships and fellowships curated directly from official sources.',
    },
    {
      'number': '02',
      'title': 'Understand your eligibility before applying.',
      'description':
          'Deterministic evaluation of age cutoffs, degree streams, reservation relaxation and minimum marks prevents wasted attempts and non-refundable fees.',
    },
    {
      'number': '03',
      'title': 'Never miss a notification or deadline.',
      'description':
          'Direct updates when official corrigenda are issued, admit cards are released, exam dates change, and final results are declared.',
    },
  ];

  void _finishOnboarding() {
    ref.read(authProvider.notifier).completeOnboarding();
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space16,
          ),
          child: Column(
            children: [
              // Top Bar with Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('REXAM', style: AppTypography.brandTitle.copyWith(fontSize: 16, letterSpacing: 2)),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text('Skip', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ),
                ],
              ),
              const Spacer(),

              // Page View
              SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemCount: _pages.length,
                  itemBuilder: (context, idx) {
                    final item = _pages[idx];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['number']!,
                          style: AppTypography.codeSnippet.copyWith(
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        Text(
                          item['title']!,
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 24,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        Text(
                          item['description']!,
                          style: AppTypography.bodyMuted.copyWith(
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),

              // Page Indicator
              Row(
                children: List.generate(_pages.length, (idx) {
                  final isActive = _currentIndex == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: AppDimensions.space6),
                    width: isActive ? 24 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryGreen : AppColors.border,
                      borderRadius: AppDimensions.roundedSmall,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppDimensions.space32),

              // Bottom Actions
              Row(
                children: [
                  if (_currentIndex > 0) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finishOnboarding();
                        }
                      },
                      child: Text(_currentIndex == _pages.length - 1 ? 'Get Started' : 'Continue'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),
            ],
          ),
        ),
      ),
    );
  }
}

