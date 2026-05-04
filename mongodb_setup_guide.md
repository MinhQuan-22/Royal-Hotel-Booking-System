# Hướng dẫn Khởi tạo & Chạy MongoDB cho ROYALHOTEL

> **Dành cho thành viên mới** — Làm theo từng bước theo thứ tự, không bỏ qua bước nào.

---

## Tổng quan

Project ROYALHOTEL dùng **hai cơ sở dữ liệu song song**:

| Database | Công nghệ | Dùng cho |
|----------|-----------|----------|
| `RoyalHotelDb` | **SQL Server** (port 1433) | Tài khoản, phòng, đặt phòng, chat, FAQ |
| `RoyalHotelCatalogDb` | **MongoDB** (port 27017) | HotelCatalog — ảnh, mô tả, tiện nghi khách sạn |

MongoDB được chạy hoàn toàn qua **Docker** — không cần cài MongoDB thủ công.

---

## Bước 1 — Cài Docker Desktop (nếu chưa có)

**Kiểm tra đã có chưa:**
```bash
docker --version
docker compose version
```

Nếu trả về phiên bản → bỏ qua bước này.

**Nếu chưa có:**

### Trên macOS
1. Truy cập [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
2. Chọn **"Download for Mac"** — chọn đúng chip:
   - **Apple Silicon (M1/M2/M3/M4)** → chọn Mac Apple Silicon
   - **Intel** → chọn Mac Intel
3. Mở file `.dmg` vừa tải, kéo Docker vào thư mục Applications
4. Mở Docker Desktop từ Launchpad
5. Chấp nhận License Agreement, đợi Docker khởi động (icon cá voi ở thanh menu chuyển sang trạng thái Running)

### Trên Windows
1. Truy cập [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
2. Chọn **"Download for Windows"**
3. Chạy file `.exe` vừa tải, chọn **"Install required Windows components for WSL 2"**
4. Khởi động lại máy nếu được yêu cầu
5. Mở Docker Desktop sau khi khởi động lại

**Xác nhận cài đặt thành công:**
```bash
docker --version
# Docker version 27.x.x, build ...

docker compose version
# Docker Compose version v2.x.x
```

---

## Bước 2 — Tạo file `docker-compose.yml`

Trong project **chưa có** file `docker-compose.yml` — cần tạo tại thư mục gốc của repository (`website-copy/`).

```bash
# Di chuyển đến thư mục gốc của repository
cd /đường/dẫn/đến/website-copy
```

Tạo file `docker-compose.yml` với nội dung sau:

```yaml
version: "3.9"

services:
  mongodb:
    image: mongo:7.0
    container_name: royalhotel_mongodb
    restart: unless-stopped
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: "MongoAdmin@123"
      MONGO_INITDB_DATABASE: RoyalHotelCatalogDb
    volumes:
      - mongodb_data:/data/db
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  mongodb_data:
    driver: local
```

> **Lưu ý quan trọng:**
> - Username: `admin`
> - Password: `MongoAdmin@123`
> - Database: `RoyalHotelCatalogDb`
> - Những giá trị này phải khớp với `appsettings.Development.json` của project

---

## Bước 3 — Khởi chạy MongoDB

```bash
# Đứng tại thư mục chứa docker-compose.yml (website-copy/)
docker compose up -d
```

Lệnh này sẽ:
- Tự động tải image MongoDB 7.0 về (lần đầu mất 1-3 phút tùy internet)
- Tạo container `royalhotel_mongodb`
- Chạy MongoDB ở nền (detached mode `-d`)

**Kiểm tra container đang chạy:**
```bash
docker ps
```

Kết quả mong đợi:
```
CONTAINER ID   IMAGE       COMMAND                  STATUS          PORTS
xxxxxxxxxxxx   mongo:7.0   "docker-entrypoint.s…"   Up 30 seconds   0.0.0.0:27017->27017/tcp
```

---

## Bước 4 — Seed dữ liệu HotelCatalog vào MongoDB

> **Bước này bắt buộc** — nếu không seed, tính năng tìm kiếm khách sạn và chatbot AI sẽ không có dữ liệu.

```bash
# Di chuyển vào thư mục Database
cd website-copy/ROYALHOTEL/Database

# Chạy lệnh seed MongoDB
docker exec -i royalhotel_mongodb mongosh \
  "mongodb://admin:MongoAdmin%40123@localhost:27017/RoyalHotelCatalogDb?authSource=admin" \
  --file /dev/stdin < SEED_mongodb.js
```

**Hoặc** copy file vào container rồi chạy:
```bash
docker cp SEED_mongodb.js royalhotel_mongodb:/tmp/SEED_mongodb.js

docker exec royalhotel_mongodb mongosh \
  --username admin \
  --password "MongoAdmin@123" \
  --authenticationDatabase admin \
  --eval "load('/tmp/SEED_mongodb.js')"
```

**Kết quả mong đợi:**
```
✔ Seed complete. Total hotels: 3
✔ Indexes: 6
  - _id_
  - idx_hotel_id
  - idx_amenities
  - idx_city_amenities
  - idx_rooms_amenities
  - idx_text_search
```

---

## Bước 5 — Xác nhận dữ liệu đã được seed

```bash
docker exec -it royalhotel_mongodb mongosh \
  --username admin \
  --password "MongoAdmin@123" \
  --authenticationDatabase admin \
  --eval "
    db = db.getSiblingDB('RoyalHotelCatalogDb');
    print('Total hotels: ' + db.HotelCatalog.countDocuments());
    db.HotelCatalog.find({}, {hotel_id:1, hotel_name:1, city:1}).forEach(printjson);
  "
```

Kết quả mong đợi:
```
Total hotels: 3
{ hotel_id: 1, hotel_name: 'Royal Luxury Da Nang',  city: 'Da Nang'  }
{ hotel_id: 2, hotel_name: 'Royal Luxury Nha Trang', city: 'Nha Trang' }
{ hotel_id: 3, hotel_name: 'Royal Luxury Phu Quoc',  city: 'Phu Quoc'  }
```

---

## Bước 6 — Chạy project ROYALHOTEL

Sau khi MongoDB đang chạy, khởi động .NET server:

```bash
cd website-copy/ROYALHOTEL

# Tắt server đang chạy ngầm (nếu có)
lsof -ti:5263 | xargs kill -9 2>/dev/null

# Khởi chạy
dotnet run
```

Truy cập [http://localhost:5263](http://localhost:5263)

---

## Các lệnh quản lý thường dùng

```bash
# Xem trạng thái container
docker ps

# Dừng MongoDB (dữ liệu vẫn được giữ)
docker compose stop

# Khởi động lại MongoDB
docker compose start

# Dừng và xóa hoàn toàn (mất dữ liệu)
docker compose down -v

# Xem log MongoDB
docker logs royalhotel_mongodb

# Mở MongoDB shell để query thủ công
docker exec -it royalhotel_mongodb mongosh \
  --username admin \
  --password "MongoAdmin@123" \
  --authenticationDatabase admin
```

---

## Xử lý lỗi thường gặp

### ❌ `port is already allocated` — port 27017 đang bị chiếm
```bash
# Tìm và kill process đang dùng port 27017
lsof -ti:27017 | xargs kill -9    # macOS/Linux
netstat -ano | findstr :27017      # Windows (tìm PID rồi Task Manager > End Task)

# Sau đó chạy lại
docker compose up -d
```

### ❌ `Authentication failed` — sai mật khẩu
- Kiểm tra `appsettings.Development.json` — `MongoDb:ConnectionString` phải là:
  ```
  mongodb://admin:MongoAdmin@123@localhost:27017
  ```
- **Chú ý:** Trong URL khi dùng `mongosh` thì ký tự `@` trong mật khẩu phải encode thành `%40`:
  ```
  mongodb://admin:MongoAdmin%40123@localhost:27017
  ```

### ❌ Docker Desktop chưa khởi động
```bash
# Kiểm tra Docker daemon
docker info
# Nếu lỗi "Cannot connect to the Docker daemon" → mở Docker Desktop trước
```

### ❌ `[MongoDB] EnsureIndexes failed` trong log .NET
- Lỗi này không ảnh hưởng hoạt động (non-fatal)
- Nguyên nhân: index text search đã tồn tại với cấu hình khác
- Xử lý nếu muốn sạch:
  ```bash
  docker compose down -v    # xóa data volume
  docker compose up -d      # tạo lại
  # Chạy lại SEED_mongodb.js
  ```

---

## Tóm tắt quy trình khởi tạo lần đầu

```
Cài Docker Desktop
      ↓
Tạo docker-compose.yml tại website-copy/
      ↓
docker compose up -d          (khởi chạy MongoDB)
      ↓
Chạy SEED_mongodb.js          (seed 3 khách sạn)
      ↓
Chạy INIT_schema.sql          (tạo bảng SQL Server)
      ↓
Chạy SEED_data.sql            (seed dữ liệu SQL Server)
      ↓
dotnet run                    (khởi chạy .NET server)
      ↓
http://localhost:5263 ✅
```

---

> **Từ lần chạy thứ 2 trở đi**, chỉ cần:
> ```bash
> docker compose start   # bật MongoDB
> dotnet run             # bật .NET server
> ```
