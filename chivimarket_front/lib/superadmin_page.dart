import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart'; // Para AnimatedGradientBackground y GlassContainer
import 'subscription_plans_page.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({Key? key}) : super(key: key);

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/admin/users');
      if (response.statusCode == 200) {
        if (mounted) setState(() => _users = jsonDecode(response.body));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.statusCode}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de red: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePlan(int userId, String userName, String currentPlan) async {
    final String? newPlan = await showDialog<String>(
      context: context,
      builder: (context) => _ChangePlanDialog(userName: userName, currentPlan: currentPlan),
    );

    if (newPlan != null && newPlan.toLowerCase() != currentPlan.toLowerCase()) {
      setState(() => _isLoading = true);
      try {
        final response = await ApiService.patch('/admin/users/$userId/subscription', {'type': newPlan});
        if (response.statusCode == 200) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan de $userName actualizado a ${newPlan.toUpperCase()}'), backgroundColor: Colors.green));
          _fetchUsers();
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar plan'), backgroundColor: Colors.red));
          setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Súper Administración', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest, color: Colors.orangeAccent),
            tooltip: 'Configurar Alcances',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionPlansPage()));
            },
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchUsers)
        ],
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: _isLoading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final subscriptionStr = user['subscription'] != null ? user['subscription']['type'].toString().toUpperCase() : 'FREE';
                    final businessesCount = user['businesses_count'] ?? 0;
                    final isAdmin = user['id'] == 1; // Asunción básica de proteccion visual

                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                          child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.white),
                        ),
                        title: Text(user['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(user['email'], style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildBadge(subscriptionStr, subscriptionStr == 'FREE' ? Colors.grey : Colors.amber),
                                const SizedBox(width: 8),
                                _buildBadge('$businessesCount Locales', Colors.blueAccent),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isAdmin ? null : () => _changePlan(user['id'], user['name'], subscriptionStr),
                          child: const Text('Cambiar Plan'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _ChangePlanDialog extends StatelessWidget {
  final String userName;
  final String currentPlan;

  const _ChangePlanDialog({required this.userName, required this.currentPlan});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text('Cambiar Plan: $userName', style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['free', 'basic', 'premium', 'enterprise'].map((plan) {
          final isCurrent = currentPlan.toLowerCase() == plan;
          return ListTile(
            title: Text(plan.toUpperCase(), style: TextStyle(color: isCurrent ? Colors.orangeAccent : Colors.white)),
            trailing: isCurrent ? const Icon(Icons.check, color: Colors.orangeAccent) : null,
            onTap: () => Navigator.pop(context, plan),
          );
        }).toList(),
      ),
    );
  }
}
