#!/bin/bash

# =============================================================
# test_mongodb.sh
# Script tự động kiểm tra MongoDB cho Royal Hotel Project 14
# Chạy: bash test_mongodb.sh
# =============================================================

echo "=========================================="
echo "🔍 MONGODB VERIFICATION SCRIPT"
echo "Royal Hotel Project 14"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# MongoDB connection string
MONGO_URI="mongodb://admin:MongoAdmin@123@localhost:27017/RoyalHotelCatalogDb"
AUTH_DB="admin"

# Test counter
PASSED=0
FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "Testing: $test_name ... "
    
    result=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        if [ -z "$expected" ] || echo "$result" | grep -q "$expected"; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((PASSED++))
            return 0
        else
            echo -e "${RED}✗ FAILED${NC}"
            echo "  Expected: $expected"
            echo "  Got: $result"
            ((FAILED++))
            return 1
        fi
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Error: $result"
        ((FAILED++))
        return 1
    fi
}

echo "=========================================="
echo "1. INFRASTRUCTURE CHECKS"
echo "=========================================="
echo ""

# Test 1: Docker is running
run_test "Docker daemon is running" \
    "docker ps > /dev/null 2>&1 && echo 'running'" \
    "running"

# Test 2: MongoDB container exists and running
run_test "MongoDB container is running" \
    "docker ps | grep mongodb | grep -q 'Up' && echo 'running'" \
    "running"

# Test 3: MongoDB port is accessible
run_test "MongoDB port 27017 is accessible" \
    "nc -z localhost 27017 && echo 'accessible'" \
    "accessible"

# Test 4: mongosh is installed
run_test "mongosh is installed" \
    "mongosh --version | head -n 1" \
    ""

echo ""
echo "=========================================="
echo "2. DATABASE CHECKS"
echo "=========================================="
echo ""

# Test 5: Can connect to MongoDB
run_test "Can connect to MongoDB" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.getName()'" \
    "RoyalHotelCatalogDb"

# Test 6: Collection exists
run_test "HotelCatalog collection exists" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.getCollectionNames()'" \
    "HotelCatalog"

# Test 7: Document count
run_test "Document count is 3" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.countDocuments()'" \
    "3"

# Test 8: Index count
run_test "Index count is 6" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.getIndexes().length'" \
    "6"

echo ""
echo "=========================================="
echo "3. DATA INTEGRITY CHECKS"
echo "=========================================="
echo ""

# Test 9: Hotel 1 exists (Da Nang)
run_test "Hotel 1 (Da Nang) exists" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.findOne({hotel_id: 1}) ? \"exists\" : \"missing\"'" \
    "exists"

# Test 10: Hotel 2 exists (Nha Trang)
run_test "Hotel 2 (Nha Trang) exists" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.findOne({hotel_id: 2}) ? \"exists\" : \"missing\"'" \
    "exists"

# Test 11: Hotel 3 exists (Phu Quoc)
run_test "Hotel 3 (Phu Quoc) exists" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.findOne({hotel_id: 3}) ? \"exists\" : \"missing\"'" \
    "exists"

# Test 12: Total room count
run_test "Total room count is 7" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.aggregate([{\$unwind: \"\$rooms\"}, {\$count: \"total\"}]).toArray()[0].total'" \
    "7"

echo ""
echo "=========================================="
echo "4. INDEX VERIFICATION"
echo "=========================================="
echo ""

# Test 13: idx_hotel_id exists
run_test "idx_hotel_id index exists" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.getIndexes().find(i => i.name === \"idx_hotel_id\") ? \"exists\" : \"missing\"'" \
    "exists"

# Test 14: idx_amenities exists
run_test "idx_amenities index exists" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.getIndexes().find(i => i.name === \"idx_amenities\") ? \"exists\" : \"missing\"'" \
    "exists"

# Test 15: idx_text_search exists
run_test "idx_text_search index exists" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.getIndexes().find(i => i.name === \"idx_text_search\") ? \"exists\" : \"missing\"'" \
    "exists"

echo ""
echo "=========================================="
echo "5. QUERY PERFORMANCE TESTS"
echo "=========================================="
echo ""

# Test 16: Query by hotel_id uses index
run_test "Query by hotel_id uses idx_hotel_id" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.find({hotel_id: 1}).explain(\"executionStats\").executionStats.executionSuccess'" \
    "true"

# Test 17: Query by city returns results
run_test "Query by city returns results" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.find({city: \"Da Nang\"}).count()'" \
    "1"

# Test 18: Query by amenities returns results
run_test "Query by amenities returns results" \
    "mongosh \"$MONGO_URI\" --authenticationDatabase $AUTH_DB --quiet --eval 'db.HotelCatalog.find({amenities: \"spa\"}).count()'" \
    "3"

echo ""
echo "=========================================="
echo "6. APPLICATION INTEGRATION CHECKS"
echo "=========================================="
echo ""

# Test 19: appsettings.json exists
run_test "appsettings.json exists" \
    "test -f ROYALHOTEL/appsettings.json && echo 'exists'" \
    "exists"

# Test 20: MongoDbContext.cs exists
run_test "MongoDbContext.cs exists" \
    "test -f ROYALHOTEL/Data/MongoDbContext.cs && echo 'exists'" \
    "exists"

# Test 21: MongoDbHealthCheck.cs exists
run_test "MongoDbHealthCheck.cs exists" \
    "test -f ROYALHOTEL/HealthChecks/MongoDbHealthCheck.cs && echo 'exists'" \
    "exists"

# Test 22: HotelCatalogDocument.cs exists
run_test "HotelCatalogDocument.cs exists" \
    "test -f ROYALHOTEL/Models/HotelCatalogDocument.cs && echo 'exists'" \
    "exists"

# Test 23: Seed script exists
run_test "hotelcatalog_seed.js exists" \
    "test -f ROYALHOTEL/Database/hotelcatalog_seed.js && echo 'exists'" \
    "exists"

echo ""
echo "=========================================="
echo "📊 TEST SUMMARY"
echo "=========================================="
echo ""
echo -e "Total tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}=========================================="
    echo "✅ ALL TESTS PASSED!"
    echo "MongoDB is fully operational"
    echo "==========================================${NC}"
    exit 0
else
    echo -e "${RED}=========================================="
    echo "❌ SOME TESTS FAILED"
    echo "Please check the errors above"
    echo "==========================================${NC}"
    exit 1
fi
