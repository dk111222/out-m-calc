import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class ParentIdentity {
  const ParentIdentity({
    required this.provider,
    required this.subject,
    this.email,
    this.name,
  });

  final String provider;
  final String subject;
  final String? email;
  final String? name;
}

/// Android opens Google. iOS opens Apple. A cancel returns null.
Future<ParentIdentity?> signInOnThisPhone() async {
  if (Platform.isAndroid) return _google();
  if (Platform.isIOS) return _apple();
  return null;
}

Future<void> endProviderSession(String? provider, {bool revoke = false}) async {
  if (provider != 'google') return;
  final google = GoogleSignIn(scopes: const ['email']);
  try {
    if (revoke) {
      await google.disconnect();
    } else {
      await google.signOut();
    }
  } catch (_) {
    // The Google session may already be gone. Local deletion still proceeds.
  }
}

Future<ParentIdentity?> _google() async {
  final account = await GoogleSignIn(scopes: const ['email']).signIn();
  if (account == null || account.id.isEmpty) return null;
  return ParentIdentity(
    provider: 'google',
    subject: account.id,
    email: account.email,
    name: account.displayName,
  );
}

Future<ParentIdentity?> _apple() async {
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final subject = credential.userIdentifier;
    if (subject == null || subject.isEmpty) return null;
    final name = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return ParentIdentity(
      provider: 'apple',
      subject: subject,
      email: credential.email,
      name: name.isEmpty ? null : name,
    );
  } on SignInWithAppleAuthorizationException catch (error) {
    if (error.code == AuthorizationErrorCode.canceled) return null;
    rethrow;
  }
}
