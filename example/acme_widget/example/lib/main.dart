import 'package:acme_widget/acme_widget.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool? _available;
  String? _greeting;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await AcmeWidget.isSdkAvailable();
    final greeting = await AcmeWidget.greeting('husk_sdk');
    if (!mounted) return;
    setState(() {
      _available = available;
      _greeting = greeting;
    });
  }

  @override
  Widget build(BuildContext context) {
    final available = _available;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('acme_widget example')),
        body: Center(
          child: Text(
            available == null
                ? 'Checking...'
                : available
                ? 'AcmeWidgetSDK is linked.\n$_greeting'
                : 'AcmeWidgetSDK is not linked; this build uses the stub.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
