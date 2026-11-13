import 'package:flutter/material.dart';

import 'monetisation_screen.dart';

/// Legacy route retained only for backwards compatibility.
/// The commercial storefront now has one source of truth: [MonetisationScreen].
class UagPlansScreen extends StatelessWidget {
  static const routeName = '/monetisation/plans';

  const UagPlansScreen({super.key});

  @override
  Widget build(BuildContext context) => const MonetisationScreen();
}
