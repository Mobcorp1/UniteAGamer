import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class AnimatedWelcomeText extends StatefulWidget {
  const AnimatedWelcomeText({super.key});

  @override
  State<AnimatedWelcomeText> createState() => _AnimatedWelcomeTextState();
}

class _AnimatedWelcomeTextState extends State<AnimatedWelcomeText> {
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _showText = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showText) {
      return const SizedBox.shrink();
    }

    return AnimatedTextKit(
      animatedTexts: [
        TyperAnimatedText(
          'Welcome to UAG Raiders Hub',
          textStyle: AppTheme.heroTextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.08,
            color: AppTheme.neonPink,
          ),
          speed: const Duration(milliseconds: 100),
        ),
      ],
      isRepeatingAnimation: false,
    );
  }
}
