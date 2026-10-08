# OmniSense Dev Backend

This is a local development backend for testing the mobile app's voice-to-backend flow.

The `/query` endpoint sends the camera image and spoken question to Gemini Vision.
Set the server-side API key before starting it:

Windows Command Prompt:

```bat
set GEMINI_API_KEY=your-gemini-api-key
python backend\dev_server.py
```

The backend defaults to `gemini-3.6-flash`. To use a different Gemini model, set
`GEMINI_MODEL` before starting the server.

Start it from the project root:

```bash
python backend/dev_server.py
```

Then run the Flutter app on an Android emulator with:

```bash
flutter run --dart-define=OMNISENSE_API_BASE_URL=http://10.0.2.2:8000
```

For a physical Android phone, replace `10.0.2.2` with your computer's LAN IP address, for example:

```bash
flutter run --dart-define=OMNISENSE_API_BASE_URL=http://192.168.1.25:8000
```

Endpoints:

```text
GET  /health
POST /query
```

The dev backend only echoes a helpful test answer. Real visual AI should be added server-side here so API keys stay out of the Flutter app.
