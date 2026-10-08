# Dependency List

## Flutter Packages

- `camera`: rear-camera initialization and preview.
- `permission_handler`: camera, microphone, and notification permission requests.
- `speech_to_text`: device speech recognition for push-to-talk queries.
- `flutter_tts`: spoken feedback and assistant responses.
- `http`: REST communication with the future FastAPI backend.
- `connectivity_plus`: future online/offline capability checks.
- `shared_preferences`: future local user preferences.
- `flutter_lints`: static analysis rules.

## Android Permissions

- `CAMERA`: visual assistance.
- `RECORD_AUDIO`: push-to-talk voice input.
- `INTERNET`: future backend communication.
- `ACCESS_NETWORK_STATE`: future offline handling.
- `POST_NOTIFICATIONS`: future expiry and important alert reminders.

## Credentials

No API keys are stored in the mobile app. Gemini keys must be configured server-side in the backend environment.

## Tooling Needed

- Flutter SDK
- Dart SDK, included with Flutter
- Android SDK
- Android device or emulator
