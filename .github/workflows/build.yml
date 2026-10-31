name: Build APK

on: [push, workflow_dispatch]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: zulu
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Create Android project files
        run: flutter create --platforms=android --project-name learn_surah_yaseen --org com.learnyaseen .

      - name: Add internet permission
        run: sed -i 's|<application|<uses-permission android:name="android.permission.INTERNET"/>\n    <application|' android/app/src/main/AndroidManifest.xml

      - name: Get packages
        run: flutter pub get

      - name: Build APK
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: Learn-Surah-Yaseen-APK
          path: build/app/outputs/flutter-apk/app-release.apk
