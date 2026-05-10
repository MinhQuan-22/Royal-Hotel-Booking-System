# Royal Hotel Booking System

## 📋 Giới thiệu tổng quan

**Royal Hotel Booking System** là hệ thống quản lý và đặt phòng khách sạn toàn diện, được xây dựng với công nghệ hiện đại, tích hợp trí tuệ nhân tạo (AI) để cung cấp trải nghiệm người dùng tối ưu và công cụ quản lý mạnh mẽ cho quản trị viên.

Hệ thống hỗ trợ quản lý đa chi nhánh khách sạn với các tính năng đặt phòng trực tuyến, thanh toán an toàn, chatbot AI hỗ trợ khách hàng 24/7, và bảng điều khiển phân tích dữ liệu chi tiết.

---

## ✨ Tính năng chính

### 🏨 Quản lý khách sạn
- **Quản lý đa chi nhánh**: Hỗ trợ quản lý nhiều khách sạn tại các địa điểm khác nhau.
- **Quản lý phòng**: Thêm, sửa, xóa thông tin phòng với hình ảnh, mô tả, tiện nghi.
- **Quản lý giá động**: Hệ thống pricing rules linh hoạt theo mùa, ngày trong tuần.
- **Quản lý tiện nghi**: Cấu hình tiện nghi cho từng loại phòng và khách sạn.

### 📅 Đặt phòng trực tuyến
- **Tìm kiếm thông minh**: Tìm kiếm phòng theo ngày, số khách, loại phòng, tiện nghi.
- **Lọc và sắp xếp**: Lọc theo giá, đánh giá, tiện nghi; sắp xếp theo nhiều tiêu chí.
- **Đặt phòng nhanh**: Quy trình đặt phòng đơn giản, trực quan.
- **Thanh toán an toàn**: Tích hợp nhiều phương thức thanh toán.
- **Xác nhận tức thì**: Email xác nhận và mã đặt phòng ngay lập tức.

### 🤖 AI Chatbot hỗ trợ 24/7
- **Trả lời tự động**: AI chatbot trả lời câu hỏi về khách sạn, phòng, giá cả, chính sách.
- **Phân loại thông minh**: Tự động phân loại câu hỏi và cung cấp thông tin phù hợp.
- **Escalation to Admin**: Chuyển cuộc trò chuyện sang admin khi cần hỗ trợ chuyên sâu.
- **Live chat với Admin**: Admin có thể trò chuyện trực tiếp với khách hàng.
- **Real-time updates**: Cập nhật tin nhắn và trạng thái theo thời gian thực (Polling).

### 👤 Quản lý tài khoản
- **Đăng ký/Đăng nhập**: Hệ thống xác thực an toàn với mã hóa mật khẩu PBKDF2.
- **Quản lý hồ sơ**: Cập nhật thông tin cá nhân, đổi mật khẩu.
- **Lịch sử đặt phòng**: Xem lịch sử đặt phòng, trạng thái, chi tiết.

### 📊 Bảng điều khiển Admin
- **Dashboard tổng quan**: Thống kê doanh thu, đặt phòng, tỷ lệ lấp đầy.
- **Biểu đồ phân tích**: Biểu đồ doanh thu theo tháng, quý, năm.
- **Quản lý đặt phòng**: Xem, xác nhận, hủy, check-in, check-out.
- **Báo cáo chi tiết**: Xuất báo cáo doanh thu, phòng, khách hàng.

---

## 🛠️ Công nghệ sử dụng

### Backend
- **Framework**: ASP.NET Core 8.0 (C#)
- **Architecture**: MVC Pattern, Repository Pattern, Dependency Injection.
- **Database**: SQL Server 2022 (Dữ liệu quan hệ) & MongoDB 7.0 (Hotel Catalog).

### AI & Machine Learning
- **OpenAI GPT-4 Turbo**: Chatbot AI thông minh.
- **NLP**: Phân loại câu hỏi và trích xuất thực thể.

### Frontend
- **Giao diện**: HTML5, CSS3 (Vanilla), Bootstrap 5.
- **Logic**: JavaScript (ES6+), jQuery, AJAX, SignalR.

### DevOps
- **Containerization**: Docker & Docker Compose.
- **Tools**: Git, VS Code, Postman.

---

## 📦 Cấu trúc dự án

```
ROYALHOTEL/
├── Controllers/          # Điều hướng yêu cầu (Home, Booking, Admin, Chat...)
├── Models/              # Lớp dữ liệu và Logic nghiệp vụ
├── Services/            # Các dịch vụ xử lý (AI, Email, Booking, Catalog...)
├── Data/                # Context kết nối SQL Server và MongoDB
├── Views/               # Giao diện người dùng (Razor Pages)
├── wwwroot/             # Tài nguyên tĩnh (CSS, JS, Images, Assets)
├── Database/            # Scripts khởi tạo SQL và MongoDB
├── appsettings.json     # Cấu hình hệ thống
└── Program.cs           # Cổng vào của ứng dụng
```

---

## 📸 Hình ảnh minh họa

### Trang chủ
Hiển thị danh sách khách sạn sang trọng với các lựa chọn tìm kiếm linh hoạt.

### AI Chatbot
Trợ lý ảo hỗ trợ tìm phòng và giải đáp thắc mắc khách hàng theo thời gian thực.

### Admin Dashboard
Hệ thống báo cáo và thống kê doanh thu trực quan cho nhà quản lý.

---

## 📖 Hướng dẫn sử dụng

Để biết cách cài đặt, khởi tạo database và khởi chạy ứng dụng, vui lòng xem file:
👉 **[README.txt](README.txt)**

---

## 📄 License
Dự án được phát triển cho mục đích học tập và nghiên cứu.

---

## 📞 Liên hệ
- **Email**: chudinhminhquan1002@gmail.com
- **GitHub**: [chudinhminhquan](https://github.com/chudinhminhquan)

**Happy Coding! 🚀**
