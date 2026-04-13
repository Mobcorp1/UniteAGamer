
import 'package:flutter/material.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: ListView(
        children: const [
          ListTile(title: Text('Terms of Use')),
          ListTile(title: Text('Privacy Policy')),
          ListTile(title: Text('Community Rules')),
          ListTile(title: Text('Refund Policy')),
          ListTile(title: Text('Affiliate Terms')),
        ],
      ),
    );
  }
}
