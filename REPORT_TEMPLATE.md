# BÁO CÁO MINI-PROJECT 3: OCR EXPENSE TRACKER & RECEIPT PARSER
**Học phần**: Lập trình Đa nền tảng (Cross-Platform Mobile Development)  
**Thời gian thực hiện**: Tuần 7 - 8 | **Trọng số**: 10%  
**Sinh viên thực hiện**: [Họ và tên sinh viên] - [Mã số sinh viên]  
**Lớp sinh hoạt**: [Mã lớp] | **Giảng viên hướng dẫn**: [Tên giảng viên]  
**Link GitHub Repository**: [Dán link repo GitHub của bạn vào đây]

---

## 1. TỔNG QUAN ĐỀ TÀI & BỐI CẢNH ỨNG DỤNG
* **Bối cảnh thực tế**: Sinh viên và thủ quỹ các câu lạc bộ thường xuyên chi tiêu và thu nhận nhiều hóa đơn giấy từ siêu thị, nhà sách, quán ăn, tiền phòng trọ. Việc nhập liệu thủ công bằng tay lên bảng tính rất mất thời gian và dễ nhầm lẫn.
* **Mục tiêu ứng dụng**: Phát triển ứng dụng di động hoàn chỉnh bằng Flutter & Dart, tích hợp Trí tuệ nhân tạo On-Device AI (Google ML Kit) để quét hóa đơn tự động 100% offline, bóc tách dữ liệu thông minh qua Regex, lưu trữ vào SQLite cục bộ và trực quan hóa chi tiêu bằng biểu đồ tự vẽ bằng `CustomPainter`.

---

## 2. BẢNG CHECKLIST TÍNH NĂNG (FEATURE CHECKLIST)

| STT | Phân hệ tính năng | Mô tả chi tiết kỹ thuật | Trạng thái |
| :--- | :--- | :--- | :---: |
| **1** | **Camera Viewfinder & Crop Overlay** | • Live camera stream với plugin `camera`.<br>• Khung căn chỉnh crop bán trong suốt với 4 góc highlight (`_FramingCropOverlayPainter`).<br>• Bật/tắt Flash (`Off`/`Torch`/`Auto`), chạm lấy nét (`Tap-to-focus`).<br>• Hỗ trợ chọn ảnh từ thư viện (`image_picker`) & nạp hóa đơn mẫu (Quick Demo). | **100% HOÀN THÀNH** |
| **2** | **On-Device OCR & Regex Heuristics** | • Tích hợp `google_mlkit_text_recognition` chạy offline, độ trễ < 100ms.<br>• Regex Engine bóc tách tổng tiền tệ VNĐ/USD có chấm điểm trọng số từ khóa neo.<br>• Bóc tách ngày giao dịch đa định dạng (`DD/MM/YYYY`, `YYYY-MM-DD`).<br>• Nhận diện tên cửa hàng và lọc bỏ tiêu đề chung chung.<br>• Tự động gợi ý 1 trong 5 danh mục chuẩn.<br>• Màn hình Review cho phép đối chiếu ảnh gốc và sửa chữa trước khi lưu. | **100% HOÀN THÀNH** |
| **3** | **Local Database & Lifecycle** | • Quản lý cơ sở dữ liệu SQLite cục bộ qua `sqflite`.<br>• 5 danh mục cố định: `Food`, `Study`, `Travel`, `Gear`, `Entertainment`.<br>• Caching ảnh thumbnail hóa đơn vào `app documents directory`.<br>• Đầy đủ tính năng: Thêm, sửa, xóa (kèm dialog xác nhận & vuốt xóa), tìm kiếm và lọc theo danh mục. | **100% HOÀN THÀNH** |
| **4** | **Custom Canvas Visualizations** | • **Tuyệt đối không dùng thư viện biểu đồ ngoài (fl_chart...)**.<br>• **Donut Chart**: Vẽ cung tròn vành khăn bằng `canvas.drawArc`, hiệu ứng xoay animation `Curves.easeOutCubic`, chạm vào legend để highlight lát cắt.<br>• **Weekly Bar Chart**: Vẽ 7 cột chi tiêu trong tuần bằng `canvas.drawRRect`, animation mọc từ đáy, lưới gridline mờ và tooltip số tiền. | **100% HOÀN THÀNH** |

---

## 3. KIẾN TRÚC HỆ THỐNG (SYSTEM ARCHITECTURE)

```
[ Camera / Gallery / Quick Demo ]
               │
               ▼
[ Google ML Kit Text Recognition ] ── (Offline Text Blocks)
               │
               ▼
[ Regex Heuristic Parser Engine ] ── (Total Amount, Date, Merchant, Category)
               │
               ▼
[ Interactive Review Screen ] ◄─── (Người dùng kiểm tra, chỉnh sửa tay)
               │
               ▼
[ SQLite Database (`sqflite`) ] ◄───► [ Local Thumbnail File Storage ]
               │
      ┌────────┴────────┐
      ▼                 ▼
[ Sổ Thu Chi ]   [ Dashboard Thống Kê ]
(CRUD, Search)   (CustomPainter Donut & Bar Charts)
```

---

## 4. CHI TIẾT KỸ THUẬT NỔI BẬT

### 4.1. Thuật toán Regex Heuristic bóc tách hóa đơn
* **Bóc tách số tiền**: Sử dụng regex nhận diện cấu trúc phân tách hàng nghìn:
  ```dart
  RegExp(r'(?:^|[^\d])(\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|\d{4,9})(?:\s*(?:VND|VNĐ|đ|d|\$))?')
  ```
  Hệ thống tính điểm (`score`) dựa trên:
  - Xuất hiện sau từ khóa neo (`TỔNG TIỀN`, `TOTAL`, `THANH TOÁN`, `TIỀN MẶT`): +100 điểm.
  - Đi kèm đơn vị tiền tệ (`VND`, `đ`): +30 điểm.
  - Vị trí ở nửa cuối hóa đơn: +25 điểm.
* **Bóc tách ngày**: Quét mẫu `\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b`, kiểm tra tính hợp lệ của tháng (1-12) và ngày (1-31).

### 4.2. Kỹ thuật CustomPainter vẽ biểu đồ không dùng thư viện
* **Biểu đồ Donut**:
  - Dùng `canvas.drawCircle` vẽ vòng ray nền xám nhẹ `Color(0xFFF1F5F9)`.
  - Tính toán góc quét: `sweepAngle = (amount / total) * 2 * pi * animation.value`.
  - Dùng `canvas.drawArc` với `PaintingStyle.stroke` và `StrokeCap.round`.
  - Khi người dùng chạm vào danh mục, lát cắt tăng độ dày `strokeWidth + 6` và vẽ thêm vòng sáng dạ quang (`MaskFilter.blur`).
* **Biểu đồ cột Weekly Bar**:
  - Tọa độ cột: `top = topPadding + chartHeight - (amount / maxAmount) * chartHeight * animation.value`.
  - Vẽ cột bo góc tròn mềm mại bằng `canvas.drawRRect`.
  - Sử dụng `LinearGradient` chuyển sắc từ chóp cột xuống chân cột.

---

## 5. HƯỚNG DẪN CHẠY THỬ & ĐÁNH GIÁ (DEMO WALKTHROUGH)
1. **Khởi chạy ứng dụng**:
   * Mở ứng dụng, màn hình đầu tiên hiển thị danh sách các khoản chi tiêu mẫu đã được seed sẵn vào SQLite.
2. **Quét hóa đơn**:
   * Chạm nút quét ở giữa thanh điều hướng bên dưới để mở Camera.
   * Căn hóa đơn vào khung ngắm crop overlay hoặc chọn ảnh/chọn mẫu hóa đơn (WinMart, Fahasa, Highlands Coffee, CGV).
3. **Đối chiếu & Lưu**:
   * Màn hình Review tự động điền Tên quán, Số tiền, Ngày mua và Danh mục gợi ý.
   * Bấm "Xem OCR" để kiểm tra các dòng chữ máy quét được.
   * Bấm "Xác nhận & Lưu chi tiêu".
4. **Xem thống kê**:
   * Chuyển sang tab "Thống kê" để xem Donut Chart và Bar Chart chuyển động animation mượt mà.

---

## 6. KẾT LUẬN & ĐÁNH GIÁ
* Ứng dụng đáp ứng 100% yêu cầu đề bài Mini-Project 3.
* Mã nguồn được tổ chức sạch sẽ, chuẩn kiến trúc module, không phát sinh lỗi biên dịch (`flutter analyze` 0 error/warning).
* Đã vượt qua 100% bộ kiểm thử tự động `flutter test`.
