import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Axent/views/pages/auth_wrapper.dart';
import 'package:Axent/utils/page_transitions.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // User preferences
  String _selectedGender = '';
  Set<String> _selectedBrands = {};
  RangeValues _budgetRange = const RangeValues(0, 500);
  Set<String> _selectedSizes = {};

  // Available options
  final List<String> _genderOptions = ['Male', 'Female', 'Unisex'];
  final List<String> _brandOptions = [
    'Nike',
    'Adidas',
    'Yeezy',
    'Jordan',
    'New Balance',
    'Converse',
    'Vans',
    'Puma',
    'Reebok',
    'Asics',
    'Under Armour',
    'Supreme'
  ];
  final List<String> _sizeOptions = [
    '6',
    '6.5',
    '7',
    '7.5',
    '8',
    '8.5',
    '9',
    '9.5',
    '10',
    '10.5',
    '11',
    '11.5',
    '12',
    '12.5',
    '13',
    '14'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selectedGender.isNotEmpty;
      case 1:
        return _selectedBrands.isNotEmpty;
      case 2:
        return _selectedSizes.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _submitOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      await Dio().post(
        'https://axentbackend.onrender.com/preferences/set_initial_preferences/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'InitialBudgetMin': _budgetRange.start,
          'InitialBudgetMax': _budgetRange.end,
          'InitialGender': _selectedGender,
          'InitialPreferredBrands': _selectedBrands.toList(),
          'InitialSizes': _selectedSizes.toList(),
        },
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageTransitions.fadeSlideTransition(
            page: const AuthWrapper(),
            duration: const Duration(milliseconds: 600),
            slideOffset: const Offset(0.0, 0.5),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? scheme.primary
                            : scheme.outline.withAlpha(51),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildGenderPage(scheme),
                  _buildBrandsPage(scheme),
                  _buildBudgetAndSizesPage(scheme),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: scheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading || !_canProceed() ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: scheme.outline.withAlpha(51),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    scheme.onPrimary),
                              ),
                            )
                          : Text(
                              _currentPage == 2 ? 'Get Started' : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderPage(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'What would you like\nto explore?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose the styles that match your interest',
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(_genderOptions.length, (index) {
            final option = _genderOptions[index];
            final isSelected = _selectedGender == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedGender = option;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary.withAlpha(26)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : scheme.outline.withAlpha(51),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option == 'Male'
                            ? Icons.male
                            : option == 'Female'
                                ? Icons.female
                                : Icons.wc,
                        color: isSelected
                            ? scheme.primary
                            : scheme.onSurface.withAlpha(153),
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: scheme.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBrandsPage(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'What brands match\nyour vibe?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select your favorite brands (choose at least one)',
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _brandOptions.map((brand) {
              final isSelected = _selectedBrands.contains(brand);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedBrands.remove(brand);
                    } else {
                      _selectedBrands.add(brand);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : scheme.outline.withAlpha(51),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    brand,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBudgetAndSizesPage(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Almost done!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Let\'s set your budget and shoe sizes',
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 40),

          // Budget Section
          Text(
            'What\'s your budget?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outline.withAlpha(51),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${_budgetRange.start.round()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      'to',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withAlpha(153),
                      ),
                    ),
                    Text(
                      '\$${_budgetRange.end.round()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  values: _budgetRange,
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  activeColor: scheme.primary,
                  inactiveColor: scheme.outline.withAlpha(51),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _budgetRange = values;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Sizes Section
          Text(
            'What sizes fit you?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sizeOptions.map((size) {
              final isSelected = _selectedSizes.contains(size);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedSizes.remove(size);
                    } else {
                      _selectedSizes.add(size);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : scheme.outline.withAlpha(51),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
