================================================================================
                    ROYAL HOTEL BOOKING SYSTEM
                   HƯỚNG DẪN CÀI ĐẶT VÀ KHỞI CHẠY
================================================================================

MỤC LỤC
--------
1. Yêu cầu hệ thống
2. Cài đặt môi trường
3. Khởi tạo cơ sở dữ liệu
4. Cấu hình hệ thống
5. Khởi chạy ứng dụng
6. Tài khoản đăng nhập
7. Xử lý lỗi thường gặp

================================================================================
1. YÊU CẦU HỆ THỐNG
================================================================================

- .NET 8.0 SDK
- Docker Desktop
- Git
- RAM tối thiểu: 8GB (Khuyến nghị 16GB)
- Hệ điều hành: Windows 10/11, macOS, hoặc Linux

================================================================================
2. CÀI ĐẶT MÔI TRƯỜNG
================================================================================

BƯỚC 2.1: Clone Repository
---------------------------
git clone <repository-url>
cd <repository-folder>

BƯỚC 2.2: Khởi động Docker Desktop
---------------------------------
Mở ứng dụng Docker Desktop trên máy tính và đảm bảo nó đang ở trạng thái "Running".

================================================================================
3. KHỞI TẠO CƠ SỞ DỮ LIỆU
================================================================================

Hệ thống sử dụng Docker để chạy SQL Server và MongoDB.

BƯỚC 3.1: Khởi động Containers
------------------------------
Chạy lệnh sau tại thư mục gốc của project:
docker compose up -d

BƯỚC 3.2: Khởi tạo SQL Server (Schema & Data)
--------------------------------------------
1. Copy scripts vào container:
docker cp ROYALHOTEL/Database/INIT_schema.sql sqlserver2022:/tmp/
docker cp ROYALHOTEL/Database/SEED_data.sql sqlserver2022:/tmp/

2. Chạy script tạo bảng:
docker exec -i sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "SqlServer@123" -C -i /tmp/INIT_schema.sql

3. Chạy script seed dữ liệu:
docker exec -i sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "SqlServer@123" -C -i /tmp/SEED_data.sql

BƯỚC 3.3: Khởi tạo MongoDB (Hotel Catalog)
------------------------------------------
1. Copy script vào container:
docker cp ROYALHOTEL/Database/SEED_mongodb.js mongodb:/tmp/

2. Chạy script seed MongoDB:
docker exec mongodb mongosh --username admin --password "MongoAdmin@123" --authenticationDatabase admin --eval "load('/tmp/SEED_mongodb.js')"

================================================================================
4. CẤU HÌNH HỆ THỐNG
================================================================================

Mở file ROYALHOTEL/appsettings.json và xác nhận các thông số sau:

1. SQL Server Connection:
"DefaultConnection": "Server=localhost,1433;Database=RoyalHotelDb;User Id=sa;Password=SqlServer@123;..."

2. MongoDB Connection:
"ConnectionString": "mongodb://admin:MongoAdmin%40123@localhost:27017/?authSource=admin"

3. OpenAI API Key (Tùy chọn cho Chatbot):
"ApiKey": "YOUR_OPENAI_API_KEY_HERE"

================================================================================
5. KHỞI CHẠY ỨNG DỤNG
================================================================================

BƯỚC 5.1: Restore & Build
-------------------------
cd ROYALHOTEL
dotnet restore
dotnet build

BƯỚC 5.2: Run
-------------
dotnet run

Ứng dụng sẽ chạy tại địa chỉ: http://localhost:5263

================================================================================
6. TÀI KHOẢN ĐĂNG NHẬP
================================================================================

Hệ thống đã được cài đặt sẵn các tài khoản sau:

ADMIN ACCOUNT
-------------
- Email: chudinhminhquan1002@gmail.com
- Password: Admin@123
- Quyền: Quản lý toàn bộ hệ thống, phản hồi Chat Support

USER ACCOUNT 1
--------------
- Email: 52300053@student.tdtu.edu.vn
- Password: User@1234
- Quyền: Đặt phòng, xem lịch sử, Chat với AI/Admin

USER ACCOUNT 2
--------------
- Email: tthuuttrangg08022005@gmail.com
- Password: User@123
- Quyền: Đặt phòng, xem lịch sử, Chat với AI/Admin

================================================================================
7. XỬ LÝ LỖI THƯỜNG GẶP
================================================================================

LỖI 1: Port 1433 hoặc 27017 đã bị sử dụng
-> Kiểm tra và tắt các phần mềm SQL Server hoặc MongoDB đang cài trực tiếp trên máy.

LỖI 2: Docker daemon không hoạt động
-> Hãy chắc chắn rằng Docker Desktop đã được mở.

LỖI 3: Không thể kết nối SQL Server trong Program.cs
-> Kiểm tra lại mật khẩu sa trong file docker-compose.yml và appsettings.json.

================================================================================
                        CHÚC BẠN SỬ DỤNG THÀNH CÔNG!
================================================================================
