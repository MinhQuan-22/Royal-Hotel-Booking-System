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

// ── HOTEL 1 — Da Nang (SQL Hotels.Id = 1) ───────────────────
targetDb.HotelCatalog.insertOne({
  hotel_id: 1,
  hotel_name: "Royal Luxury Da Nang",
  city: "Da Nang",
  country: "Vietnam",
  description: "Khách sạn 5 sao hàng đầu Đà Nẵng nằm ngay bờ biển Mỹ Khê. Tọa lạc tại trung tâm thành phố, Royal Luxury Da Nang mang đến trải nghiệm nghỉ dưỡng đẳng cấp với hồ bơi vô cực, spa cao cấp và nhà hàng fusion cuisine. Tầm nhìn trực diện biển từ mọi phòng nghỉ.",
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
      room_code: "DN-STD-101",
      room_name: "Da Nang Standard Ocean View",
      room_type: "Standard",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "ocean_view"],
      description: "Phòng Standard với tầm nhìn hướng biển tuyệt đẹp. Diện tích 35m², giường king size, ban công riêng.",
      images: ["/images/rooms/dn-std-101-1.jpg", "/images/rooms/dn-std-101-2.jpg"]
    },
    {
      room_id: 2,
      room_code: "DN-DLX-201",
      room_name: "Da Nang Deluxe Sea Breeze",
      room_type: "Deluxe",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "ocean_view", "bathtub", "balcony"],
      description: "Phòng Deluxe rộng 55m² với bồn tắm đứng, tầm nhìn panorama ra biển. Đầy đủ tiện nghi 5 sao.",
      images: ["/images/rooms/dn-dlx-201-1.jpg", "/images/rooms/dn-dlx-201-2.jpg"]
    },
    {
      room_id: 3,
      room_code: "DN-STE-301",
      room_name: "Da Nang Presidential Suite",
      room_type: "Suite",
      amenities: ["wifi", "air_conditioning", "tv", "minibar", "safe", "ocean_view", "bathtub", "balcony", "living_room", "kitchen", "butler"],
      description: "Suite Tổng thống 120m² với phòng khách riêng, bếp nhỏ và butler riêng phục vụ 24/7. Tầm nhìn 180° ra vịnh Đà Nẵng.",
      images: ["/images/rooms/dn-ste-301-1.jpg", "/images/rooms/dn-ste-301-2.jpg"]
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

// ── VERIFY ───────────────────────────────────────────────────
const count   = targetDb.HotelCatalog.countDocuments();
const indexes = targetDb.HotelCatalog.getIndexes();

print("\n========================================");
print(`✔ Seed complete. Total hotels: ${count}`);
print(`✔ Indexes: ${indexes.length}`);
indexes.forEach(idx => print(`  - ${idx.name}`));
print("========================================");
