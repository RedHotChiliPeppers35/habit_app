import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';

class AuthLinkHandler extends StatefulWidget {
  final Widget child;
  const AuthLinkHandler({super.key, required this.child});

  @override
  State<AuthLinkHandler> createState() => _AuthLinkHandlerState();
}

class _AuthLinkHandlerState extends State<AuthLinkHandler> {
  StreamSubscription<Uri?>? _sub;
  bool _handledInitial = false;
  bool _isConsuming = false;
  bool get _supportsLinks => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  void initState() {
    super.initState();
    if (_supportsLinks) {
      _handleInitialUri();
      _sub = uriLinkStream.listen((uri) {
        if (uri != null) _consumeSupabaseLink(uri);
      }, onError: (_) {});
    }
  }

  Future<void> _handleInitialUri() async {
    if (_handledInitial) return;
    _handledInitial = true;
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) await _consumeSupabaseLink(initialUri);
    } catch (_) {}
  }

  bool _isOurAuthLink(Uri uri) =>
      uri.scheme == dotenv.env['AUTH_SCHEME'] &&
      uri.host == dotenv.env['AUTH_HOST'];

  Future<void> _consumeSupabaseLink(Uri uri) async {
    if (!_isOurAuthLink(uri) || _isConsuming) return;
    _isConsuming = true;
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (_) {
    } finally {
      _isConsuming = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
