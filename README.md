# Royal Hotel Booking System

## Project Overview

Royal Hotel Booking System is a comprehensive hotel management and booking platform built with ASP.NET Core, featuring AI-powered live chat support, multi-hotel management, and advanced analytics.

## Backend Setup

### Prerequisites

- .NET 8.0 SDK
- SQL Server
- MongoDB

### Configuration

See [ROYALHOTEL/CONFIGURATION.md](ROYALHOTEL/CONFIGURATION.md) for detailed configuration instructions including:

- OpenAI API Key setup
- Database connection strings
- SMTP settings

### Running the Backend

```bash
cd ROYALHOTEL
dotnet restore
dotnet run
```

## Frontend Setup

Source FE nằm tại: `frontend/Hotel Booking/`

### Option 1 (Recommended): VS Code Live Server

1. Open project in VS Code
2. Install **Live Server** extension (Ritwick Dey)
3. Open file: `frontend/Hotel Booking/pages/home.html`
4. Right-click → **Open with Live Server**

### Option 2: Direct Browser Access

- Open `frontend/Hotel Booking/pages/home.html` in Chrome/Edge

> Note: Some API calls may be restricted when opening directly (due to CORS). Live Server is more stable.

## Admin Credentials

- **Email**: chudinhminhquan1002@gmail.com
- **Password**: Admin@123456
