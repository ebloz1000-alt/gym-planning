Mobile distribution (APK and iOS OTA)

This document explains how to let web visitors install your mobile app when app stores are not available.

Android (APK side-loading)
- Build a release-signed APK or AAB. For APK side-loading, use a release-signed APK:
  - Flutter: `flutter build apk --release`
  - Sign the APK with your signing key (preferably using the Android App Bundle and Play signing for Play Store distribution).
- Host the APK on HTTPS (e.g., https://example.com/app-release.apk). Ensure the server sets:
  - `Content-Type: application/vnd.android.package-archive`
  - `Content-Disposition: attachment; filename="app-release.apk"`
- In `frontend/web/index.html` set the meta `apk-url` to the HTTPS URL.
- When users tap the install button, the site will try `market://` first and then navigate to the APK URL. Users must enable "install unknown apps" on their device and confirm installation.

Notes:
- Side-loading APKs is platform- and device-dependent. Recent Android versions show warnings and require explicit user consent.
- Prefer distributing via the Play Store when possible for security and automatic updates.

iOS (OTA installation via itms-services)
- iOS does not allow direct installation of unsigned .ipa files from a website for general users.
- Enterprise (in-house) distribution or TestFlight are the main alternatives:
  - Enterprise: sign the IPA with an enterprise certificate and create a manifest plist (.plist) describing the app and its download URL. Host both the .plist and .ipa on HTTPS.
  - TestFlight: upload builds to App Store Connect and invite testers; no web-based install flow is possible.
- OTA manifest example (plist):
  - Create a plist following Apple's spec that points to the HTTPS .ipa URL and contains bundle identifier and version.
  - Host the plist on HTTPS (e.g., https://example.com/manifest.plist).
- In `frontend/web/index.html` set the meta `ios-itms-manifest` to the HTTPS URL of the plist. The page will trigger:
  `itms-services://?action=download-manifest&url=https://example.com/manifest.plist`
  which opens Safari's install prompt for enterprise-signed apps.

Limitations and security
- Both APK side-loading and iOS enterprise OTA carry security risks. Only use them for controlled/private distributions.
- For public distribution, submit to Play Store and App Store.
- Provide clear user instructions and host files over HTTPS.

Troubleshooting
- If OTA install fails on iOS, check provisioning/profile and enterprise cert validity.
- If APK download/install fails on Android, check MIME types and signed APK integrity.

If you want, I can:
- Insert your APK URL and iOS manifest URL into `frontend/web/index.html`.
- Add a short in-app help modal explaining side-loading steps for users.
