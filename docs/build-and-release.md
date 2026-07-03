# Build and Release

## Install Dependencies

```bash
flutter pub get
```

## Static Analysis

```bash
flutter analyze
```

## Run on Windows

```bash
flutter run -d windows
```

If your backend requires an explicit base URL or token, include Dart defines:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3000/api/v1 --dart-define=API_AUTH_TOKEN=YOUR_TOKEN
```

## Build Windows Release

```bash
flutter build windows --release
```

## Output Path

```text
build/windows/x64/runner/Release
```

## Package the Build

1. Build the Windows release.
2. Open `build/windows/x64/runner/Release`.
3. Zip the full `Release` folder contents, not only the `.exe`.
4. Share the zipped folder with the target user or deployment channel.

## Run on Another Laptop

1. Extract the shared zip to a normal local folder.
2. Keep all files from the `Release` output together.
3. Launch the generated executable from that extracted folder.
4. Make sure the target laptop can reach the backend API and any required network resources.

## Notes

- The app depends on backend APIs for real data; without backend connectivity it will show partial or empty UI states
- If Windows SmartScreen or local security policies block execution, the receiving laptop may need local approval to run the unsigned executable
- If API base URLs are environment-specific, rebuild with the correct `--dart-define` values before sharing
