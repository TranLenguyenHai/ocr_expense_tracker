# 📱 OCR Expense Tracker & Receipt Parser (Flutter & Dart)

> **Mini-Project 3** | Môn học: Lập trình Đa nền tảng (Cross-Platform Mobile Development)  
> **Trọng số điểm**: 10% | Thời gian: Tuần 7 - 8  
> **Nền tảng**: Flutter 3.x, Dart 3, Android & iOS

---

## 📌 1. Giới thiệu bài toán & Mục tiêu (Problem & Overview)
Sinh viên và thủ quỹ câu lạc bộ thường xuyên phải xử lý nhiều hóa đơn giấy và biên lai chi tiêu (siêu thị, nhà sách, quán cà phê, xăng xe...). Việc nhập liệu thủ công vào bảng tính (Excel/Sheets) vừa tốn thời gian vừa dễ xảy ra sai sót.

**OCR Expense Tracker** là ứng dụng di động quản lý tài chính cá nhân tích hợp **Trí tuệ nhân tạo (On-Device AI)** chạy hoàn toàn offline trên điện thoại:
1. **Camera Viewfinder & Crop Overlay**: Khung ngắm chụp hóa đơn trực tiếp với nút bật/tắt flash, chạm lấy nét.
2. **On-Device Text Recognition (Google ML Kit)**: Nhận diện chữ siêu tốc (< 100ms), 100% offline, bảo mật tuyệt đối và không phát sinh chi phí Cloud API.
3. **Regex Heuristic Parser**: Bộ luật regex thông minh tự động bóc tách số tiền tổng cộng (`Total Amount`), ngày giao dịch (`Date`), và tên cửa hàng (`Merchant Name`).
4. **Interactive Review Screen**: Màn hình xem lại, cho phép người dùng đối chiếu ảnh gốc, xem văn bản OCR thô và sửa chữa thông tin trước khi lưu.
5. **Local SQLite Database (`sqflite`)**: Lưu trữ phân loại theo 5 danh mục chuẩn (`Food`, `Study`, `Travel`, `Gear`, `Entertainment`) và lưu trữ ảnh hóa đơn thumbnail cục bộ.
6. **Custom Canvas Visualizations (`CustomPainter`)**: Vẽ biểu đồ vành khăn (Donut Chart) phân bổ chi tiêu và biểu đồ cột (Weekly Bar Chart) chi tiêu 7 ngày trong tuần có animation chuyển động mượt mà, **không phụ thuộc vào bất kỳ thư viện biểu đồ bên thứ 3 nào**.

---

## 🏗️ 2. Kiến trúc dự án (Modular Architecture)

Dự án áp dụng mô hình Feature-first kết hợp Clean Separation:

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_categories.dart         # 5 danh mục chuẩn, mã màu, icon & tên song ngữ
│   ├── database/
│   │   └── db_helper.dart              # SQLite Database Helper (CRUD, Aggregations, Seeding)
│   └── utils/
│       ├── currency_formatter.dart     # Format tiền tệ VNĐ & ngày tháng
│       └── receipt_parser.dart         # Regex Heuristic Engine bóc tách hóa đơn
├── models/
│   └── expense_transaction.dart        # Data Model giao dịch & SQLite mapping
├── providers/
│   └── expense_provider.dart           # State Management (Provider), bộ lọc, cache ảnh
├── views/
│   ├── analytics/
│   │   ├── analytics_screen.dart       # Dashboard báo cáo & thống kê
│   │   └── widgets/
│   │       ├── category_donut_chart.dart # Donut Chart vẽ bằng CustomPainter + Animation
│   │       └── weekly_bar_chart.dart     # Weekly Bar Chart vẽ bằng CustomPainter + Animation
│   ├── camera/
│   │   ├── camera_viewfinder_screen.dart # Viewfinder, flash, focus, crop overlay, ML Kit
│   │   └── review_expense_screen.dart    # Review thông tin, đối chiếu ảnh, sửa trước khi lưu
│   ├── details/
│   │   └── transaction_detail_screen.dart# Chi tiết giao dịch, xem thumbnail, sửa, xóa
│   └── home/
│       ├── home_screen.dart              # Navigation dock & Floating Action Button
│       └── transaction_list_tab.dart     # Sổ thu chi, tìm kiếm, lọc danh mục, vuốt xóa
└── main.dart                             # Điểm khởi chạy ứng dụng & Theme
```

---

## ⚡ 3. Các tính năng cốt lõi (Core Specifications)

### 📸 A. Camera Capture & Crop Overlay
* Viewfinder trực tiếp thời gian thực sử dụng plugin `camera`.
* Lớp phủ **Framing Crop Overlay** vẽ bằng `CustomPainter` với 4 góc căn chỉnh dạ quang giúp người dùng đặt hóa đơn vào đúng trung tâm.
* Nút chuyển đổi đèn flash (`Off` / `Torch` / `Auto`).
* Chạm vào màn hình để lấy nét (`Tap-to-focus`) có vòng sáng animation phản hồi.
* Tích hợp nút chọn ảnh từ thư viện (`image_picker`) và nút **Hóa đơn mẫu (Quick Test)** phục vụ chấm điểm và chạy thử trên máy ảo Android.

### 🧠 B. On-Device OCR & Regex Heuristic Parser
* Tích hợp `google_mlkit_text_recognition` cho việc quét chữ Latin/Tiếng Việt trên thiết bị.
* **Quy tắc bóc tách số tiền (Total Amount)**:
  * Quét từ khóa: `TỔNG TIỀN`, `TỔNG CỘNG`, `THANH TOÁN`, `TIỀN MẶT`, `CỘNG TIỀN HÀNG`, `TOTAL`, `GRAND TOTAL`, `AMOUNT DUE`.
  * Regex bắt các biến thể: `150,000`, `150.000`, `150 000`, `150k` kèm/không kèm ký hiệu `VND`, `VNĐ`, `đ`, `$`.
  * Thuật toán chấm điểm vị trí: Ưu tiên dòng xuất hiện sau từ khóa neo và dòng ở nửa dưới hóa đơn.
* **Quy tắc bóc tách ngày (Date)**:
  * Regex đa định dạng: `DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD`, `DD.MM.YYYY`.
* **Quy tắc bóc tách tên cửa hàng (Merchant Name)**:
  * Bộ lọc loại trừ các từ chung chung (`HÓA ĐƠN BÁN HÀNG`, `PHIẾU THANH TOÁN`, `TEL:`, `HOTLINE`).
  * Nhận diện thương hiệu theo danh sách từ khóa: `WinMart`, `Co.opmart`, `Circle K`, `GS25`, `Highlands Coffee`, `Fahasa`, `GearVN`, `CGV`...
* **Tự động gợi ý danh mục (Category Auto-tagging)**: Dựa trên từ khóa mặt hàng hoặc thương hiệu để map vào 1 trong 5 danh mục bắt buộc.
* **Màn hình Review Screen**: Cho phép sửa tay toàn bộ thông tin và xem bảng mã chữ OCR thô (`Raw OCR Blocks`).

### 💾 C. Cơ sở dữ liệu SQLite & Quản lý giao dịch
* Cơ sở dữ liệu cục bộ với bảng `transactions` được quản lý bởi `sqflite`.
* Caching thumbnail: Lưu ảnh hóa đơn vào thư mục `app documents directory` bảo đảm dữ liệu tồn tại vĩnh viễn khi đóng app.
* Đầy đủ nghiệp vụ CRUD: Thêm mới, xem chi tiết, sửa thông tin, xóa giao dịch có popup xác nhận và hỗ trợ vuốt để xóa (`Dismissible`).
* Bộ lọc thời gian thực: Tìm kiếm theo tên cửa hàng/nội dung và lọc theo từng danh mục.

### 🎨 D. Biểu đồ tự vẽ bằng `CustomPainter` (Zero 3rd-party chart library)
1. **Animated Donut Chart (Phân bổ chi tiêu)**:
   * Vẽ bằng hàm `canvas.drawArc` với nét vẽ tròn mềm mại (`StrokeCap.round`).
   * Hiệu ứng chuyển động mượt mà điều khiển bởi `AnimationController` (`Curves.easeOutCubic`).
   * Cho phép chạm vào từng danh mục trên chú thích (Legend) để làm nổi bật (highlight slice) kèm đổ bóng dạ quang.
2. **Animated Weekly Spending Bar Chart (Chi tiêu tuần)**:
   * Vẽ 7 cột đại diện cho các thứ trong tuần (T2 - CN) bằng `canvas.drawRRect`.
   * Cột hiển thị dải màu chuyển sắc gradient (Indigo/Cyan/Rose), tự động co giãn theo giá trị chi tiêu lớn nhất trong tuần.
   * Chạm vào từng cột để xem tooltip số tiền chi tiết của ngày đó.

---

## 🚀 4. Hướng dẫn cài đặt & Chạy ứng dụng

### Yêu cầu môi trường:
* Flutter SDK >= 3.x
* Dart SDK >= 3.x
* Android Studio / VS Code với Flutter extension
* Thiết bị Android thật (bật USB Debugging) hoặc Máy ảo Android (Android Emulator API >= 21)

### Các bước cài đặt:
1. **Clone repository về máy**:
   ```bash
   git clone <URL_REPO_CUA_BAN>
   cd ocr_expense_tracker
   ```

2. **Cài đặt các thư viện phụ thuộc (Dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Chạy kiểm thử Unit Tests**:
   ```bash
   flutter test
   ```

4. **Chạy ứng dụng trên thiết bị / Máy ảo**:
   ```bash
   flutter run
   ```

5. **Xuất file cài đặt Release APK nộp bài**:
   ```bash
   flutter build apk --release
   ```
   * File APK xuất xưởng sẽ nằm tại: `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 5. Kết quả kiểm thử (Test Results)

Hệ thống đã bao gồm bộ kiểm thử tự động cho Regex Parser:
```text
00:00 +0: ReceiptParser Regex Heuristic Engine Tests Correctly extracts merchant, amount, date and category from WinMart receipt
00:00 +1: ReceiptParser Regex Heuristic Engine Tests Correctly extracts Fahasa bookstore receipt as Study category
00:00 +2: ReceiptParser Regex Heuristic Engine Tests Correctly extracts Grab bike as Travel category
00:00 +3: All tests passed!
```

---

## 👥 Tác giả & Đóng góp
* **Học phần**: Lập trình Đa nền tảng (Cross-Platform Mobile Development)
* **Dự án**: Mini-Project 3 - OCR Expense Tracker & Receipt Parser
* **Framework**: Flutter & Dart
