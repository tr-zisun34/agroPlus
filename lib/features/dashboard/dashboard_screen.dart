import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _farmerName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarmer();
  }

  Future<void> _loadFarmer() async {
    try {
      final response = await ApiClient.instance.dio.get('/farmers/me');
      setState(() {
        _farmerName = response.data['name'] as String;
        _isLoading = false;
      });
    } on DioException {
      setState(() {
        _errorMessage = 'Could not load your profile.';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Dashboard' : (_farmerName ?? 'Dashboard')),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add farm is coming in a later update.')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add farm'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    // No /farms endpoint yet in this increment — always show the empty state.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.agriculture_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              "You haven't added a farm yet",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
