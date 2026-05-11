# Royal Hotel Booking System

> **Full-stack hotel booking platform** built with ASP.NET Core 8, dual-database architecture (SQL Server + MongoDB), and AI-powered chatbot support.

---

## 📋 Overview

**Royal Hotel Booking System** is a comprehensive hotel management and room booking system supporting multi-branch operations. The platform provides online room booking, intelligent AI chatbot support, real-time admin chat escalation, dynamic pricing, and detailed analytics dashboards.

**Tech Stack**

| Layer | Technology |
|---|---|
| **Backend** | ASP.NET Core 8 (C#), MVC + Repository + Decorator Pattern |
| **Primary DB** | SQL Server 2022 — bookings, accounts, payments, pricing |
| **Catalog DB** | MongoDB 7 — room catalog, amenities, full-text search |
| **AI Chatbot** | OpenAI GPT-4 Turbo via OpenRouter API |
| **Frontend** | HTML5, CSS3, Bootstrap 5, JavaScript ES6+, jQuery, AJAX |
| **DevOps** | Docker, Docker Compose, Git |
| **Testing** | xUnit, Moq (31 unit tests) |

---

## ✨ Key Features

- 🏨 **Multi-branch management** — manage multiple hotel locations with centralized admin
- 📅 **Online booking flow** — search → select → checkout → payment confirmation
- 💰 **Dynamic pricing engine** — Strategy Pattern with weekend/holiday/promotion rules
- 🔒 **Pessimistic locking** — `sp_ConfirmBooking` stored procedure prevents double-booking
- 💳 **Cancellation & refund policy** — automated refund calculation (100% / 50% / 0%) based on hours before check-in
- 🤖 **AI chatbot** — GPT-4 powered with automatic admin escalation
- 💬 **Live admin chat** — real-time polling-based chat between admin and guest
- 📊 **Analytics dashboard** — revenue charts, occupancy rates, quarterly reports
- 📧 **Email notifications** — booking confirmation via SMTP
- 🗄️ **Audit trail** — SQL triggers log room rate changes > 50%

---

## 👤 My Responsibilities

This is a solo personal project. I was responsible for all parts of the system:

- **Backend Architecture** — designed MVC structure, Repository Pattern, Decorator Pattern for booking validation, Strategy Pattern for pricing engine
- **Database Design** — SQL Server schema with stored procedures, triggers, window functions; MongoDB catalog for search optimization
- **Business Logic** — booking lifecycle (Pending → Confirmed → CheckedIn → CheckedOut), cancellation/refund policy, pessimistic locking
- **AI Integration** — OpenAI GPT-4 chatbot with RAG-style context injection, admin escalation logic
- **Frontend** — Razor Views, responsive UI with Bootstrap 5, AJAX-based interactions
- **Testing** — wrote 31 unit tests covering booking rules, pricing strategies, cancellation policies, and authentication logic
- **DevOps** — Docker Compose setup for SQL Server + MongoDB local development

---

## 📸 Screenshots

### Home Page
Displays available hotels with flexible search and date selection.

### Room Detail
Full room information with amenities, gallery, and dynamic pricing.

### Booking Flow
Step-by-step: Room Selection → Guest Info → Payment → Confirmation Email

### AI Chatbot
AI assistant answers questions about rooms, prices, and policies — escalates to admin when needed.

### Admin Dashboard
Revenue analytics, booking management, occupancy tracking.

> ℹ️ *See `/ROYALHOTEL/wwwroot/` for asset references. Add screenshots by placing images in `/docs/screenshots/`.*

---

## 🗄️ Database Architecture

### SQL Server — Core Data
```
Accounts → Bookings → PaymentTransactions
Hotels → Rooms → RoomImages / RoomAmenities
PricingRules → PricingRuleHistory (audit trigger)
ChatConversations → ChatMessages
FAQs, PasswordResetOtps
```

**Key stored procedures & triggers:**
- `sp_ConfirmBooking` — pessimistic locking for payment confirmation
- `trg_RoomRateChange` — audit trigger fires when rate changes > 50%
- `Quarterly_Revenue_Analytics` — window function view for dashboard

### MongoDB — Hotel Catalog
```
HotelCatalog collection → rich amenity data, descriptions, images
Sync service keeps MongoDB updated from SQL Server changes
```

---

## 📐 Booking Flow

```
[User searches] → [MongoDB catalog filter] → [SQL availability check]
      ↓
[Select room + dates] → [CreateBookingAsync] → [Status: Pending]
      ↓
[Payment page] → [sp_ConfirmBooking] → [Status: Confirmed]
      ↓
[Confirmation email sent via SMTP]
      ↓
[Admin: CheckIn] → [Status: CheckedIn] → [CheckOut] → [Status: Completed]
```

**Cancellation & Refund Policy:**

| Time before check-in | Refund |
|---|---|
| ≥ 48 hours | **100%** |
| 24 – 48 hours | **50%** |
| < 24 hours | **0%** |

---

## 📦 Project Structure

```
website-copy/
├── docker-compose.yml          # SQL Server + MongoDB containers
├── ROYALHOTEL/
│   ├── Controllers/            # MVC Controllers (Home, Booking, Admin, Chat...)
│   ├── Models/                 # Domain models (Booking, Room, Account, PricingRule...)
│   ├── Services/
│   │   ├── Booking/            # CoreBookingService + Decorator pattern
│   │   ├── Rooms/              # RoomPricingService + Strategy pattern
│   │   ├── Chat/               # AI chatbot + admin live chat
│   │   ├── Email/              # SMTP email notifications
│   │   └── Catalog/            # MongoDB sync service
│   ├── Data/                   # EF Core DbContext (SQL Server + MongoDB)
│   ├── Views/                  # Razor pages
│   ├── Database/               # INIT_schema.sql, SEED_data.sql, SEED_mongodb.js
│   ├── Security/               # CryptoHelper (PBKDF2 password hashing)
│   ├── appsettings.example.json  # ← copy to appsettings.json, fill in your values
│   └── Program.cs
└── RoyalHotel.Tests/           # xUnit tests (31 tests)
    ├── BookingServiceTests.cs
    ├── CancellationPolicyTests.cs
    ├── PricingRuleTests.cs
    └── AuthenticationServiceTests.cs
```

---

## 🚀 Setup Instructions

### Prerequisites
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### 1. Clone Repository
```bash
git clone <repository-url>
cd <repository-folder>
```

### 2. Start Databases
```bash
docker compose up -d
```

### 3. Configure Application
```bash
cp ROYALHOTEL/appsettings.example.json ROYALHOTEL/appsettings.json
# Edit appsettings.json — fill in passwords and API keys
```

### 4. Initialize Databases

**SQL Server:**
```bash
docker cp ROYALHOTEL/Database/INIT_schema.sql sqlserver2022:/tmp/
docker cp ROYALHOTEL/Database/SEED_data.sql sqlserver2022:/tmp/
docker exec -i sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "SqlServer@123" -C -i /tmp/INIT_schema.sql
docker exec -i sqlserver2022 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "SqlServer@123" -C -i /tmp/SEED_data.sql
```

**MongoDB:**
```bash
docker cp ROYALHOTEL/Database/SEED_mongodb.js mongodb:/tmp/
docker exec mongodb mongosh --username admin --password "MongoAdmin@123" --authenticationDatabase admin --eval "load('/tmp/SEED_mongodb.js')"
```

### 5. Run Application
```bash
cd ROYALHOTEL
dotnet restore
dotnet run
```

App runs at: **http://localhost:5263**

### 6. Run Tests
```bash
cd RoyalHotel.Tests
dotnet test --verbosity normal
```

---

## 🔐 Demo Accounts

| Role | Email | Password |
|---|---|---|
| **Admin** | `chudinhminhquan1002@gmail.com` | `Admin@123` |
| **User 1** | `52300053@student.tdtu.edu.vn` | `User@1234` |
| **User 2** | `tthuuttrangg08022005@gmail.com` | `User@123` |

**Admin capabilities:** Full dashboard access, booking management (check-in/out, cancel), pricing rule management, live chat with guests, analytics reports.

---

## ⚠️ Known Limitations

- **Payment gateway**: Payment is simulated (no real bank integration). Bank transfer and card options are UI-only.
- **Email**: SMTP email requires a real Gmail App Password to send actual emails. Without it, confirmations are logged only.
- **AI Chatbot**: Requires a valid OpenAI API key (via OpenRouter). Without it, the chatbot returns a fallback message.
- **Real-time chat**: Uses polling (not WebSocket/SignalR) — minor delay on message delivery.
- **Image upload**: Room images reference external URLs; local file upload is not implemented.
- **Scope**: Academic/portfolio project — not intended for production without additional security hardening.

---

## 🧪 Unit Tests

The project includes **31 unit tests** across 4 test files:

| Test Class | Coverage |
|---|---|
| `BookingServiceTests` | Booking code format, status transition rules, data defaults |
| `CancellationPolicyTests` | Refund policy boundary conditions (48h, 24h, <24h) |
| `PricingRuleTests` | Strategy pattern: weekend rule, priority override, multi-night avg |
| `AuthenticationServiceTests` | Login/register validation, PBKDF2 hash/verify |

```bash
dotnet test RoyalHotel.Tests --verbosity normal
# Result: 31 passed, 0 failed
```

---

## 📄 License

Developed for academic and portfolio purposes. Not for commercial use.

---

## 📞 Contact

- **Email**: chudinhminhquan1002@gmail.com
- **GitHub**: [chudinhminhquan](https://github.com/chudinhminhquan)
