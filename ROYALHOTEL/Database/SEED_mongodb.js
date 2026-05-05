// ============================================================
// ROYALHOTEL — MongoDB HotelCatalog Seed
// File: SEED_mongodb.js
//
// Run via mongosh:
//   mongosh "mongodb://admin:MongoAdmin@123@localhost:27017/RoyalHotelCatalogDb" --file SEED_mongodb.js
//
// Or automatically via Docker docker-entrypoint-initdb.d (mount this file)
// hotel_id values MUST match Hotels.Id in SQL Server RoyalHotelDb
// ============================================================

const targetDb = db.getSiblingDB("RoyalHotelCatalogDb");

// Drop and recreate for clean seed (dev only — safe because SQL Server is source of truth)
targetDb.HotelCatalog.drop();

// ── INDEXES ─────────────────────────────────────────────────
targetDb.HotelCatalog.createIndex({ hotel_id: 1 },                          { unique: true, name: "idx_hotel_id" });
targetDb.HotelCatalog.createIndex({ amenities: 1 },                         { name: "idx_amenities" });
targetDb.HotelCatalog.createIndex({ city: 1, amenities: 1 },                { name: "idx_city_amenities" });
targetDb.HotelCatalog.createIndex({ "rooms.amenities": 1 },                 { name: "idx_rooms_amenities" });
targetDb.HotelCatalog.createIndex(
  { description: "text", hotel_name: "text" },
  { name: "idx_text_search", default_language: "none" }
);

// ── HOTEL 1 — New York (SQL Hotels.Id = 1) ───────────────────
targetDb.HotelCatalog.insertOne({
  hotel_id: 1,
  hotel_name: "Royal Hotel New York",
  city: "New York",
  country: "United States",
  description: "Khách sạn 5 sao đẳng cấp quốc tế tọa lạc tại trung tâm Midtown Manhattan. Tầm nhìn toàn cảnh New York skyline, nhà hàng fine dining tầng thượng và spa thế giới.",
  amenities: ["wifi", "pool", "spa", "gym", "parking", "restaurant", "bar", "room_service", "concierge", "business_center", "laundry", "valet"],
  images: [
    "/images/hotels/newyork/lobby.jpg",
    "/images/hotels/newyork/skyline.jpg",
    "/images/hotels/newyork/restaurant.jpg",
    "/images/hotels/newyork/spa.jpg"
  ],
  rooms: [
    {
      room_id: 301,
      room_code: "NY-DLX-201",
      room_name: "New York City View Deluxe",
      room_type: "Deluxe",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "city_view", "king_bed", "marble_bathroom"],
      description: "Phòng Deluxe 50m² tầm nhìn ra Manhattan skyline. Nội thất hiện đại, bồn tắm cẩm thạch.",
      images: ["/images/rooms/ny-dlx-201-1.jpg", "/images/rooms/ny-dlx-201-2.jpg"]
    },
    {
      room_id: 302,
      room_code: "NY-STE-401",
      room_name: "New York Penthouse Suite",
      room_type: "Suite",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "city_view", "private_terrace", "bathtub", "living_room", "kitchen", "butler", "jacuzzi"],
      description: "Penthouse Suite 200m² với terrace riêng 360° nhìn toàn cảnh New York. Butler 24/7.",
      images: ["/images/rooms/ny-ste-401-1.jpg", "/images/rooms/ny-ste-401-2.jpg"]
    }
  ],
  updated_at: new Date()
});

// ── HOTEL 2 — Nha Trang (SQL Hotels.Id = 2) ─────────────────
targetDb.HotelCatalog.insertOne({
  hotel_id: 2,
  hotel_name: "Royal Luxury Nha Trang",
  city: "Nha Trang",
  country: "Vietnam",
  description: "Khu nghỉ dưỡng đẳng cấp tại Nha Trang — thiên đường biển miền Trung. Nằm trên bãi biển Trần Phú sầm uất, khách sạn có hồ bơi nước mặn, trung tâm lặn biển và nhà hàng hải sản tươi sống. Lý tưởng cho cặp đôi và gia đình.",
  amenities: ["wifi", "pool", "spa", "parking", "restaurant", "bar", "room_service", "diving_center", "kids_club", "beach_access"],
  images: [
    "/images/hotels/nhatrang/lobby.jpg",
    "/images/hotels/nhatrang/pool.jpg",
    "/images/hotels/nhatrang/beach.jpg",
    "/images/hotels/nhatrang/restaurant.jpg"
  ],
  rooms: [
    {
      room_id: 101,
      room_code: "NT-DLX-201",
      room_name: "Nha Trang Deluxe Ocean View",
      room_type: "Deluxe",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "ocean_view", "balcony", "bathtub"],
      description: "Phòng Deluxe 50m² hướng biển, ban công rộng nhìn thẳng ra vịnh Nha Trang. Bồn tắm freestanding sang trọng.",
      images: ["/images/rooms/nt-dlx-201-1.jpg", "/images/rooms/nt-dlx-201-2.jpg"]
    },
    {
      room_id: 102,
      room_code: "NT-STE-301",
      room_name: "Nha Trang Premium Suite",
      room_type: "Suite",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "ocean_view", "balcony", "bathtub", "living_room", "pool_access", "breakfast"],
      description: "Suite cao cấp 90m² với bể tắm nước nóng ngoài trời trên ban công. Bữa sáng tại phòng và quyền truy cập hồ bơi tầng thượng.",
      images: ["/images/rooms/nt-ste-301-1.jpg", "/images/rooms/nt-ste-301-2.jpg"]
    }
  ],
  updated_at: new Date()
});

// ── HOTEL 3 — Phu Quoc (SQL Hotels.Id = 3) ──────────────────
targetDb.HotelCatalog.insertOne({
  hotel_id: 3,
  hotel_name: "Royal Luxury Phu Quoc",
  city: "Phu Quoc",
  country: "Vietnam",
  description: "Resort nghỉ dưỡng biệt lập trên đảo Phú Quốc — viên ngọc xanh của Việt Nam. Sở hữu bãi biển riêng dài 500m, 3 hồ bơi infinity pool và khu spa onsen Nhật Bản. Ẩm thực fusion sáng tạo từ nguyên liệu địa phương.",
  amenities: ["wifi", "pool", "spa", "gym", "parking", "restaurant", "bar", "room_service", "private_beach", "water_sports", "kids_club", "breakfast"],
  images: [
    "/images/hotels/phuquoc/resort.jpg",
    "/images/hotels/phuquoc/pool.jpg",
    "/images/hotels/phuquoc/beach.jpg",
    "/images/hotels/phuquoc/spa.jpg",
    "/images/hotels/phuquoc/sunset.jpg"
  ],
  rooms: [
    {
      room_id: 201,
      room_code: "PQ-DLX-201",
      room_name: "Phu Quoc Garden Deluxe",
      room_type: "Deluxe",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "garden_view", "outdoor_shower", "balcony"],
      description: "Villa Deluxe 60m² giữa vườn nhiệt đới xanh mát. Vòi sen ngoài trời và bồn tắm cắm hoa. Lối đi riêng xuống bãi biển.",
      images: ["/images/rooms/pq-dlx-201-1.jpg", "/images/rooms/pq-dlx-201-2.jpg"]
    },
    {
      room_id: 202,
      room_code: "PQ-STE-401",
      room_name: "Phu Quoc Family Suite",
      room_type: "Suite",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "sea_view", "private_pool", "bathtub", "living_room", "kitchen", "breakfast", "kids_amenities"],
      description: "Suite Gia Đình 150m² với hồ bơi riêng và bếp nhỏ. Tầm nhìn hoàng hôn tuyệt đẹp ra biển Tây. Khu vui chơi trẻ em và nôi cũi miễn phí.",
      images: ["/images/rooms/pq-ste-401-1.jpg", "/images/rooms/pq-ste-401-2.jpg"]
    }
  ],
  updated_at: new Date()
});

// ── HOTEL 4 — Los Angeles (SQL Hotels.Id = 4) ──────────────────
targetDb.HotelCatalog.insertOne({
  hotel_id: 4,
  hotel_name: "Royal Hotel Los Angeles",
  city: "Los Angeles",
  country: "United States",
  description: "Khách sạn 5 sao hàng đầu Los Angeles nằm ngay đại lộ Sunset. Tọa lạc tại trung tâm thành phố, Royal Hotel Los Angeles mang đến trải nghiệm nghỉ dưỡng đẳng cấp với hồ bơi vô cực, spa cao cấp và nhà hàng fusion cuisine.",
  amenities: ["wifi", "pool", "gym", "spa", "parking", "restaurant", "bar", "room_service", "laundry", "concierge"],
  images: [
    "/images/hotels/danang/lobby.jpg",
    "/images/hotels/danang/pool.jpg",
    "/images/hotels/danang/beach.jpg",
    "/images/hotels/danang/spa.jpg"
  ],
  rooms: [
    {
      room_id: 1,
      room_code: "LA-STD-101",
      room_name: "LA Standard Ocean View",
      room_type: "Standard",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "ocean_view"],
      description: "Phòng Standard với tầm nhìn hướng biển tuyệt đẹp. Diện tích 35m², giường king size, ban công riêng.",
      images: ["/images/rooms/dn-std-101-1.jpg", "/images/rooms/dn-std-101-2.jpg"]
    },
    {
      room_id: 2,
      room_code: "LA-DLX-201",
      room_name: "LA Deluxe Sea Breeze",
      room_type: "Deluxe",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "ocean_view", "bathtub", "balcony"],
      description: "Phòng Deluxe rộng 55m² với bồn tắm đứng, tầm nhìn panorama ra biển. Đầy đủ tiện nghi 5 sao.",
      images: ["/images/rooms/dn-dlx-201-1.jpg", "/images/rooms/dn-dlx-201-2.jpg"]
    },
    {
      room_id: 3,
      room_code: "LA-STE-301",
      room_name: "LA Presidential Suite",
      room_type: "Suite",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "ocean_view", "bathtub", "balcony", "living_room", "kitchen", "butler"],
      description: "Suite Tổng thống 120m² với phòng khách riêng, bếp nhỏ và butler riêng phục vụ 24/7. Tầm nhìn 180° ra biển Thái Bình Dương.",
      images: ["/images/rooms/dn-ste-301-1.jpg", "/images/rooms/dn-ste-301-2.jpg"]
    }
  ],
  updated_at: new Date()
});

// ── HOTEL 5 — Chicago (SQL Hotels.Id = 5) ───────────────────
targetDb.HotelCatalog.insertOne({
  hotel_id: 5,
  hotel_name: "Royal Hotel Chicago",
  city: "Chicago",
  country: "United States",
  description: "Biểu tượng sang trọng tại Chicago Loop nhìn ra hồ Michigan. Kiến trúc Art Deco kết hợp tiện nghi hiện đại, rooftop bar và nhà hàng Michelin.",
  amenities: ["wifi", "pool", "spa", "gym", "parking", "restaurant", "bar", "room_service", "concierge", "business_center", "laundry", "rooftop_bar"],
  images: [
    "/images/hotels/chicago/lobby.jpg",
    "/images/hotels/chicago/lake.jpg",
    "/images/hotels/chicago/restaurant.jpg",
    "/images/hotels/chicago/rooftop.jpg"
  ],
  rooms: [
    {
      room_id: 401,
      room_code: "CHI-DLX-201",
      room_name: "Chicago Lakefront Deluxe",
      room_type: "Deluxe",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "lake_view", "king_bed", "rainfall_shower"],
      description: "Phòng Deluxe 48m² nhìn ra hồ Michigan. Thiết kế hiện đại với vòi sen rainfall và sàn gỗ.",
      images: ["/images/rooms/chi-dlx-201-1.jpg", "/images/rooms/chi-dlx-201-2.jpg"]
    },
    {
      room_id: 402,
      room_code: "CHI-STE-401",
      room_name: "Chicago Executive Suite",
      room_type: "Suite",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "panoramic_view", "bathtub", "living_room", "meeting_room", "butler", "breakfast"],
      description: "Suite Executive 180m² với phòng họp riêng. Tầm nhìn panorama ra Chicago Loop và hồ Michigan.",
      images: ["/images/rooms/chi-ste-401-1.jpg", "/images/rooms/chi-ste-401-2.jpg"]
    }
  ],
  updated_at: new Date()
});

// ── VERIFY ───────────────────────────────────────────────────
const count   = targetDb.HotelCatalog.countDocuments();
const indexes = targetDb.HotelCatalog.getIndexes();

print("\n========================================");
print(`✔ Seed complete. Total hotels: ${count}`);
print(`✔ Indexes: ${indexes.length}`);
indexes.forEach(idx => print(`  - ${idx.name}`));
print("========================================");
