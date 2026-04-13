import 'package:flutter/material.dart';

class UserDetailsWidget extends StatelessWidget {
  final String username;
  final String email;

  const UserDetailsWidget({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username: $username',
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 20, 147),
            fontFamily: 'VT323',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Email: $email',
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 20, 147),
            fontFamily: 'VT323',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
