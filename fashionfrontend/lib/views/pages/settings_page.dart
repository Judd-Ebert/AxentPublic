import 'package:Axent/views/pages/profile_settings_page.dart';
import 'package:Axent/views/pages/welcome_page.dart';
import 'package:Axent/providers/theme_provider.dart';
import 'package:Axent/providers/notification_provider.dart';
import 'package:Axent/providers/usage_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const PageStorageKey('settings'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildSettingsContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSection(
            'Account',
            [
              _buildSettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                subtitle: 'Manage your profile information',
                onTap: () => _navigateToProfile(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Preferences',
            [
              _buildThemeTile(),
              _buildNotificationsTile(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Data & Privacy',
            [
              _buildSettingsTile(
                icon: Icons.analytics_outlined,
                title: 'Usage Data',
                subtitle: 'View your app usage statistics',
                onTap: () => _showDataDialog(),
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () => _launchPrivacyPolicy(),
              ),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                onTap: () => _launchTermsOfService(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Support',
            [
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & FAQ',
                subtitle: 'Get help and find answers',
                onTap: () => _showHelpDialog(),
              ),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () => _showAboutDialog(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildDangerSection(),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    size: 16,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return _buildSettingsTile(
          icon: _getThemeIcon(themeProvider.themeMode),
          title: 'Theme',
          subtitle: _getThemeSubtitle(themeProvider.themeMode),
          onTap: () => _showThemeDialog(themeProvider),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getThemeText(themeProvider.themeMode),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTile() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return _buildSettingsTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          onTap: () => _showNotificationsDialog(notificationProvider),
        );
      },
    );
  }

  Widget _buildDangerSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                onTap: () => _showSignOutDialog(),
                trailing: Icon(
                  Icons.exit_to_app_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
              ),
              Container(
                height: 1,
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              _buildSettingsTile(
                icon: Icons.delete_forever_rounded,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and all data',
                onTap: () => _showDeleteAccountDialog(),
                trailing: Icon(
                  Icons.warning_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.auto_mode_outlined;
    }
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Auto';
    }
  }

  String _getThemeSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system settings';
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileSettingsPage(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(bottomSheetContext).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Theme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(bottomSheetContext).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            ...ThemeMode.values.map((mode) => _buildThemeOption(
                  bottomSheetContext,
                  mode,
                  themeProvider.themeMode == mode,
                  () {
                    themeProvider.setTheme(mode);
                    Navigator.pop(bottomSheetContext);
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext bottomSheetContext, ThemeMode mode,
      bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(bottomSheetContext).colorScheme.primary
                    : Theme.of(bottomSheetContext)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getThemeIcon(mode),
                  color: isSelected
                      ? Theme.of(bottomSheetContext).colorScheme.primary
                      : Theme.of(bottomSheetContext).colorScheme.onSurface,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getThemeText(mode),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(bottomSheetContext).colorScheme.secondary
                              : Theme.of(bottomSheetContext)
                                  .colorScheme
                                  .secondary,
                        ),
                      ),
                      Text(
                        _getThemeSubtitle(mode),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(bottomSheetContext)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(bottomSheetContext).colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationsDialog(NotificationProvider notificationProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure when and how you\'d like to receive notifications',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    _buildNotificationSwitch(
                      'Push Notifications',
                      'Master switch for all notifications',
                      provider.pushNotifications,
                      provider.setPushNotifications,
                    ),
                    _buildNotificationSwitch(
                      'New Product Alerts',
                      'Get notified when new products match your style',
                      provider.newProductAlerts,
                      provider.setNewProductAlerts,
                      enabled: provider.pushNotifications,
                    ),
                    _buildNotificationSwitch(
                      'Price Drop Alerts',
                      'Get notified when products in your wishlist drop in price',
                      provider.priceDropAlerts,
                      provider.setPriceDropAlerts,
                      enabled: provider.pushNotifications,
                    ),
                    _buildNotificationSwitch(
                      'Wardrobe Reminders',
                      'Weekly reminders to update and organize your wardrobes',
                      provider.wardrobeReminders,
                      provider.setWardrobeReminders,
                      enabled: provider.pushNotifications,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        color: enabled
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context)
                .colorScheme
                .surfaceContainer
                .withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled ? value : false,
            onChanged: enabled ? onChanged : null,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showDataDialog() {
    final usageData = Provider.of<UsageDataProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Usage Statistics'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUsageStatCard(
                    'Total Swipes',
                    usageData.totalSwipes.toString(),
                    Icons.swipe,
                  ),
                  const SizedBox(height: 12),
                  _buildUsageStatCard(
                    'Likes',
                    '${usageData.likesCount} (${usageData.likeRatio.toStringAsFixed(1)}%)',
                    Icons.favorite,
                  ),
                  const SizedBox(height: 12),
                  _buildUsageStatCard(
                    'Dislikes',
                    usageData.dislikesCount.toString(),
                    Icons.close,
                  ),
                  const SizedBox(height: 12),
                  _buildUsageStatCard(
                    'Wardrobes Created',
                    usageData.wardrobesCreated.toString(),
                    Icons.collections_bookmark,
                  ),
                  const SizedBox(height: 12),
                  _buildUsageStatCard(
                    'Items in Wardrobes',
                    usageData.productsInWardrobes.toString(),
                    Icons.checkroom,
                  ),
                  const SizedBox(height: 12),
                  _buildUsageStatCard(
                    'Days Active',
                    usageData.daysActive.toString(),
                    Icons.calendar_today,
                  ),
                  if (usageData.firstLoginDate != null) ...[
                    const SizedBox(height: 12),
                    _buildUsageStatCard(
                      'Member Since',
                      _formatDate(usageData.firstLoginDate!),
                      Icons.person_add,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showResetUsageDialog(usageData),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showResetUsageDialog(UsageDataProvider usageData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Usage Data'),
        content: const Text(
          'Are you sure you want to reset all usage statistics? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await usageData.resetUsageData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Usage data reset successfully')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const Text(
          'Find answers to common questions and get help using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Fashion App'),
        content: const Text(
          'Fashion App v1.0.0\n\nDiscover your style with personalized fashion recommendations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _launchPrivacyPolicy() async {
    const url =
        'https://axent.notion.site/Privacy-Policy-26f97832788680fa885ee723deac2b53';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchTermsOfService() async {
    const url =
        'https://axent.notion.site/Terms-of-Service-26f97832788680a88f00e3a31be6c8f8';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final TextEditingController confirmationController =
        TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text('Delete Account'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action will permanently delete your account and cannot be undone. All your data including:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Liked products and preferences\n• Wardrobe collections\n• Usage statistics\n• All personal information',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Type "DELETE" to confirm:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmationController,
                  decoration: InputDecoration(
                    hintText: 'Type DELETE here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  (confirmationController.text.trim() == 'DELETE' && !isLoading)
                      ? () async {
                          setState(() => isLoading = true);
                          await _deleteAccount(context);
                        }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext dialogContext) async {
    try {
      // Get current user token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final token = await user.getIdToken();

      // Call backend API
      final response = await Dio().delete(
        'https://axentbackend.onrender.com/preferences/delete_account/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Success - navigate to welcome page
        if (mounted) {
          Navigator.pop(dialogContext); // Close dialog
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const WelcomePage()),
              (route) => false,
            );
          }
        }
      } else {
        throw Exception('Failed to delete account: ${response.statusMessage}');
      }
    } catch (e) {
      // Show error dialog
      if (mounted) {
        Navigator.pop(dialogContext); // Close loading dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete account: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
