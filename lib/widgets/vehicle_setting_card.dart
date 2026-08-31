import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class VehicleSettingCard extends StatelessWidget {
  final IconData icon;

  final String title;
  final String? subtitle;

  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool isActionLoading;

  final bool showOnHome;
  final ValueChanged<bool>? onShowOnHomeChanged;
  final String homeDescription;

  final Widget? content;

  const VehicleSettingCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionPressed,
    this.isActionLoading = false,
    required this.showOnHome,
    required this.onShowOnHomeChanged,
    required this.homeDescription,
    this.content,
  });

  Widget _buildIconBox() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.iconBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: AppTheme.primary,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                _buildIconBox(),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textPrimary,
                        ),
                      ),

                      if (subtitle != null &&
                          subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),

                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 15,
                            color:
                                AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (actionText != null) ...[
                  const SizedBox(width: 12),

                  OutlinedButton(
                    onPressed:
                        isActionLoading
                            ? null
                            : onActionPressed,
                    child: isActionLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            actionText!,
                          ),
                  ),
                ],
              ],
            ),

            if (content != null) ...[
              const SizedBox(height: 20),

              content!,
            ],

            const SizedBox(height: 16),

            const Divider(),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'הצג במסך הבית',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
              subtitle: Text(
                homeDescription,
                style: const TextStyle(
                  color:
                      AppTheme.textSecondary,
                ),
              ),
              value: showOnHome,
              onChanged:
                  onShowOnHomeChanged,
            ),
          ],
        ),
      ),
    );
  }
}