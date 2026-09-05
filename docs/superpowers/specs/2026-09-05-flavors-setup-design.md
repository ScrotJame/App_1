# Thiết Kế Hệ Thống Flavors (Dev & Production) Cho Dự Án Flutter

- **Ngày tạo:** 2026-09-05
- **Trạng thái:** Approved by User

## 1. Mục Tiêu & Yêu Cầu
- Tách biệt hai môi trường hoạt động: `dev` (phục vụ phát triển, kiểm thử, log chi tiết) và `prod` (sản phẩm chính thức).
- Nền tảng trọng tâm: Android.
- Quản lý Application ID: Giữ chung Application ID (`com.example.test_abc`) cho cả Dev và Prod nhằm bảo toàn tính toàn vẹn của Firebase và Google Sign-In hiện tại mà không làm gãy cấu hình `google-services.json`.
- Tên hiển thị ứng dụng: Phân biệt trực quan trên thiết bị (`Dungeonary Dev` và `Dungeonary`).
- Cung cấp cấu hình VS Code (`.vscode/launch.json`) để nhà phát triển có thể bấm F5 chạy trực tiếp từng Flavor.

## 2. Kiến Trúc & Luồng Dữ Liệu

### 2.1. Cấu hình Môi trường trong Dart (`AppConfig`)
Tạo class Singleton `AppConfig` lưu giữ ngữ cảnh môi trường đang chạy:
- `AppFlavor`: enum `{ dev, prod }`
- `appName`: Tên ứng dụng tương ứng
- `envFileName`: Tên file env tương ứng (`.env.dev` hoặc `.env.prod`)
- Getter tiện ích: `isDev`, `isProd`

### 2.2. Tách Entry Points
- `lib/main_common.dart`: Nhận đối tượng `AppConfig`, khởi tạo bindings, nạp file env qua `flutter_dotenv`, khởi tạo Firebase, Google Sign-In, Permissions, Pronunciation Dictionary, và gọi `runApp(MyApp())`.
- `lib/main_dev.dart`: Entry point cho flavor Dev, khởi tạo `AppConfig.dev` rồi gọi `mainCommon(...)`.
- `lib/main_prod.dart`: Entry point cho flavor Prod, khởi tạo `AppConfig.prod` rồi gọi `mainCommon(...)`.
- `lib/main.dart`: Giữ lại làm wrapper mặc định chuyển hướng sang `main_dev.dart` để không làm gián đoạn các tooling cũ nếu chạy trực tiếp `flutter run`.

### 2.3. File Biến Môi Trường
- `.env.dev`: Chứa biến môi trường cho Dev (`BACKUP_SECRET_KEY`, `APP_ENV=dev`, `ENABLE_LOG=true`).
- `.env.prod`: Chứa biến môi trường cho Prod (`BACKUP_SECRET_KEY`, `APP_ENV=prod`, `ENABLE_LOG=false`).
- Khai báo `.env.dev` và `.env.prod` vào khối `assets` của `pubspec.yaml`.

### 2.4. Cấu hình Native Android (Gradle build.gradle.kts & Manifest)
- Trong `android/app/build.gradle.kts`:
  - Thiết lập `flavorDimensions += "default"`.
  - Thiết lập `productFlavors`:
    - `dev`: `resValue("string", "app_name", "Dungeonary Dev")`
    - `prod`: `resValue("string", "app_name", "Dungeonary")`
- Trong `android/app/src/main/AndroidManifest.xml`:
  - Đổi `android:label="Dungeonary"` sang `android:label="@string/app_name"`.

### 2.5. Tooling Cấu hình VS Code
- File `.vscode/launch.json`:
  - `Dungeonary (Dev - Debug)`: `-t lib/main_dev.dart --flavor dev`
  - `Dungeonary (Prod - Debug)`: `-t lib/main_prod.dart --flavor prod`
  - `Dungeonary (Dev - Release)` & `Dungeonary (Prod - Release)`

## 3. Kế Hoạch Kiểm Thử (Verification)
1. **Kiểm tra cú pháp code Dart:** Chạy `flutter analyze` để xác nhận không có compile error hoặc warning mới.
2. **Kiểm tra Unit Test:** Chạy `flutter test` đảm bảo các test case hiện có tiếp tục pass 100%.
3. **Kiểm tra Native Build:** Chạy lệnh build hoặc assemble dry-run cho flavor `dev` và `prod` qua Gradle/Flutter CLI để kiểm tra tính toàn vẹn của file manifest và resource generation.
