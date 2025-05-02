import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final List<Widget>? actions;
  final bool showInfoButton;
  final VoidCallback? onInfoPressed;
  final IconData? icon;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onLeadingPressed,
    this.actions,
    this.showInfoButton = false,
    this.onInfoPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      elevation: 0,
      leading: leadingIcon != null
          ? IconButton(
              icon: Icon(
                leadingIcon,
                color: isDark ? AppColors.darkTextSecondary : AppColors.grey600,
              ),
              onPressed: onLeadingPressed,
            )
          : null,
      title: Row(
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.withOpacity(
                  colorScheme.primary,
                  isDark ? 0.2 : 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
          if (icon != null) const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (showInfoButton)
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDark ? AppColors.darkTextSecondary : AppColors.grey600,
            ),
            onPressed: onInfoPressed,
          ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
