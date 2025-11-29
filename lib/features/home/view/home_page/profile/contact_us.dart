import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactUsSection extends ConsumerStatefulWidget {
  const ContactUsSection({super.key});

  @override
  ConsumerState<ContactUsSection> createState() => _ContactUsSectionState();
}

class _ContactUsSectionState extends ConsumerState<ContactUsSection> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    try {
      await supabase.from('support_messages').insert({
        'user_id': user?.id,
        'email': user?.email,
        'message': text,
      });

      if (!mounted) return;

      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Message sent! We'll get back to you soon."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send message: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        const Text(
          "Contact Us",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: "Tell us what you need help with…",
            filled: true,
            fillColor: AppColors.accentRed.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _sending ? null : _sendMessage,
            icon:
                _sending
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.send, color: Colors.white),
            label: Text(
              _sending ? "Sending..." : "Send Message",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
