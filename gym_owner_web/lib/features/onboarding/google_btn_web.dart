import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

Widget buildGoogleSignInButton({required VoidCallback onPressed}) {
  return web_only.renderButton(
    configuration: web_only.GSIButtonConfiguration(
      text: web_only.GSIButtonText.signinWith,
      theme: web_only.GSIButtonTheme.outline,
      size: web_only.GSIButtonSize.large,
      shape: web_only.GSIButtonShape.pill,
    ),
  );
}
