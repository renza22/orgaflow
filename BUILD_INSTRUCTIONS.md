# OrgaFlow - Build Instructions

## 📱 Build Android APK

### Cara Cepat (Menggunakan Script)
Jalankan file `build_android.bat` dengan double-click atau:
```bash
build_android.bat
```

### Cara Manual

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate App Icons**
   ```bash
   dart run flutter_launcher_icons
   ```

3. **Build APK Release**
   ```bash
   flutter build apk --release
   ```

4. **Lokasi APK**
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```

## 🎨 Update App Icon

Logo app berada di: `assets/images/logo.png`

Untuk update icon:
1. Ganti file `assets/images/logo.png` dengan logo baru
2. Jalankan: `dart run flutter_launcher_icons`
3. Build ulang app

## 📝 Update App Name

Edit file: `android\app\src\main\AndroidManifest.xml`
```xml
<application
    android:label="OrgaFlow"  <!-- Ubah nama di sini -->
    ...>
```

## 🔧 Build Variants

- **Release APK**: `flutter build apk --release`
- **Debug APK**: `flutter build apk --debug`
- **Split APKs**: `flutter build apk --split-per-abi`
- **App Bundle**: `flutter build appbundle`

## 📦 Output Files

- **APK Universal**: `build/app/outputs/flutter-apk/app-release.apk`
- **APK Split (arm64)**: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- **APK Split (armeabi)**: `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- **APK Split (x86_64)**: `build/app/outputs/flutter-apk/app-x86_64-release.apk`

## 🚀 Install ke Device

```bash
flutter install
```

Atau manual:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## ⚙️ Konfigurasi Icon (pubspec.yaml)

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo.png"
```

## 📱 Minimum Requirements

- **Android**: API 21 (Android 5.0 Lollipop) atau lebih tinggi
- **Flutter**: 3.0.0 atau lebih tinggi
- **Dart**: 3.0.0 atau lebih tinggi

## 🐛 Troubleshooting

### Build Gagal
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Icon Tidak Berubah
```bash
dart run flutter_launcher_icons
flutter clean
flutter build apk --release
```

### Gradle Error
```bash
cd android
./gradlew clean
cd ..
flutter build apk --release
```
