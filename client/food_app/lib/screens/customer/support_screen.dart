import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
            color: theme.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 4),
                Text('How can we help you today?', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor)),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(hintText: 'Search FAQs...', hintStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)), border: InputBorder.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('RECENT ORDERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                _issueCard('Order #44', 'Main Canteen · ₹85', theme),
                const SizedBox(height: 24),

                Text('SUPPORT TOPICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                  child: Column(
                    children: [
                      _topicRow(Icons.support_agent, 'Chat with Support', theme),
                      Divider(height: 1, color: theme.dividerColor),
                      _topicRow(Icons.account_balance_wallet, 'Payment & Refunds', theme),
                      Divider(height: 1, color: theme.dividerColor),
                      _topicRow(Icons.fastfood, 'Food Quality Issues', theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _issueCard(String title, String sub, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(8)),
            child: const Text('Report Issue', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _topicRow(IconData icon, String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 14),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
    );
  }
}
