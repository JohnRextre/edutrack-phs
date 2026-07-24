import 'package:flutter/material.dart';

class CustodianReturnVerificationScreen extends StatelessWidget {
  const CustodianReturnVerificationScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Return Verification')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Card(
          child: ListTile(
            title: Text('Physics: Principles & Problems'),
            subtitle: Text('Maria Santos - Today, 09:45 AM - Damaged cover'),
            trailing: Text('Verify'),
          ),
        ),
        Card(
          child: ListTile(
            title: Text('Lenovo Laptop'),
            subtitle: Text('Juan Dela Cruz - Yesterday - Good condition'),
            trailing: Text('Verify'),
          ),
        ),
      ],
    ),
  );
}
