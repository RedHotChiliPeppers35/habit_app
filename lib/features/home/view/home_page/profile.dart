import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Your Profile',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No user profile found.'));
          }

          final username = profile['name'] ?? 'No Name';
          final surname = profile['surname'] ?? '';
          final email = profile['email'] ?? 'No Email';
          final phone = profile['phone'] ?? 'No Phone';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 👤 User info
                  Text(
                    '$username $surname',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  const SizedBox(height: 30),

                  // 🚪 Log Out Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      final shouldSignOut = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text(
                                'Are you sure you want to sign out?',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Sign Out',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (shouldSignOut == true) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );

                        try {
                          await Supabase.instance.client.auth.signOut();

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Signed out successfully'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          Navigator.pop(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error signing out: $e')),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Delete Account'),
                              content: const Text(
                                'Are you sure you want to permanently delete your account and all data? '
                                'This action cannot be undone.',
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (confirm != true) return;

                      final supabase = Supabase.instance.client;
                      final user = supabase.auth.currentUser;
                      if (user == null) return;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      );

                      try {
                        // Call your edge function to handle deletion
                        await supabase.functions.invoke(
                          'hyper-service',
                          body: {'user_id': user.id},
                        );

                        await supabase.auth.signOut();

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your account and all data have been deleted.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting account: $e'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
