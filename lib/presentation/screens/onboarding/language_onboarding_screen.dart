import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/app_providers.dart';

class LanguageOnboardingScreen extends ConsumerStatefulWidget {
  const LanguageOnboardingScreen({super.key});

  @override
  ConsumerState<LanguageOnboardingScreen> createState() =>
      _LanguageOnboardingScreenState();
}

class _LanguageOnboardingScreenState
    extends ConsumerState<LanguageOnboardingScreen> {
  static const _languages = [
    _AppLanguage(code: 'ar', label: 'العربية'),
    _AppLanguage(code: 'es-419', label: 'Español (Latin America)'),
    _AppLanguage(code: 'es-ES', label: 'Español (Spain)'),
    _AppLanguage(code: 'ru', label: 'Русский'),
    _AppLanguage(code: 'uk', label: 'Українська'),
    _AppLanguage(code: 'vi', label: 'Tiếng Việt'),
    _AppLanguage(code: 'de', label: 'Deutsch'),
    _AppLanguage(code: 'th', label: 'ไทย'),
    _AppLanguage(code: 'ja', label: '日本語'),
    _AppLanguage(code: 'tr', label: 'Türkçe'),
    _AppLanguage(code: 'pt', label: 'Português'),
  ];

  String _selectedLanguageCode = 'vi';
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(appLanguageServiceProvider)
          .saveSelectedLanguage(_selectedLanguageCode);
      ref.read(selectedAppLanguageProvider.notifier).state =
          _selectedLanguageCode;
      if (!mounted) return;
      context.push('/onboarding/assessment-intro');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu ngôn ngữ. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF061D4C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _OnboardingBackground(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const _LanguageHeader(),
                  Expanded(
                    child: _LanguagePanel(
                      languages: _languages,
                      selectedLanguageCode: _selectedLanguageCode,
                      isSaving: _isSaving,
                      onSelected: (code) {
                        setState(() => _selectedLanguageCode = code);
                      },
                      onContinue: _continue,
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
}

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 16,
            child: Semantics(
              label: 'Quay lại',
              button: true,
              child: InkWell(
                onTap: () {
                  if (context.canPop()) context.pop();
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 82,
            right: 92,
            top: 28,
            child: Text(
              'Chọn ngôn ngữ\nmẹ đẻ của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.5,
                height: 1.06,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 45,
            child: Image.asset(
              'assets/images/leximon-owl-wave.png',
              width: 110,
              height: 110,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 72,
            right: 72,
            top: 85,
            child: Text(
              'Chúng tôi sẽ cá nhân hóa lộ trình\nhọc phù hợp với bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                height: 1.38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePanel extends StatelessWidget {
  const _LanguagePanel({
    required this.languages,
    required this.selectedLanguageCode,
    required this.isSaving,
    required this.onSelected,
    required this.onContinue,
  });

  final List<_AppLanguage> languages;
  final String selectedLanguageCode;
  final bool isSaving;
  final ValueChanged<String> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFDFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x29031A55),
            blurRadius: 28,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              itemCount: languages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final language = languages[index];
                return _LanguageTile(
                  language: language,
                  selected: language.code == selectedLanguageCode,
                  onTap: () => onSelected(language.code),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                key: const ValueKey('language-onboarding-continue'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSaving
                        ? const [Color(0xFF78A2FF), Color(0xFF8DB4FF)]
                        : const [
                            Color(0xFF063AAE),
                            Color(0xFF0C54E7),
                            Color(0xFF1676FF),
                          ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D155CFF),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: isSaving ? null : onContinue,
                    borderRadius: BorderRadius.circular(18),
                    child: Center(
                      child: isSaving
                          ? const SizedBox.square(
                              dimension: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Tiếp',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final _AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: language.label,
      child: Material(
        color: selected ? const Color(0xFFF0F5FF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? const Color(0xFFC8DAFF) : const Color(0xFFE1E9F7),
          ),
        ),
        child: InkWell(
          key: ValueKey('app-language-${language.code}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (selected) ...[
                    SvgPicture.asset(
                      'assets/svgs/onboarding/choose_checked.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                  ],
                  Expanded(
                    child: Text(
                      language.label,
                      textAlign: TextAlign.left,
                      textDirection: language.code == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        color: const Color(0xFF082657),
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/onboarding/bg_choose_language.png',
      fit: BoxFit.cover,
    );
  }
}

class _AppLanguage {
  const _AppLanguage({required this.code, required this.label});

  final String code;
  final String label;
}
