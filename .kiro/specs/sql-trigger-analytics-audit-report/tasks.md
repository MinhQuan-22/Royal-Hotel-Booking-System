# Tasks: SQL Trigger, Analytics, Audit & Report Integration

## Phase 1: Database Schema and Infrastructure

### 1.1 Create RoomRateChangeLog Table

- [x] 1.1.1 Write SQL migration script for RoomRateChangeLog table
- [x] 1.1.2 Add columns: Id, RoomId, OldRate, NewRate, ChangePercent, ChangedAt, ChangedBy
- [x] 1.1.3 Add PRIMARY KEY constraint on Id
- [x] 1.1.4 Add FOREIGN KEY constraint on RoomId referencing Rooms(Id)
- [x] 1.1.5 Set default value for ChangedAt (GETDATE())
- [x] 1.1.6 Test table creation script

### 1.2 Create Performance Indexes

- [x] 1.2.1 Create index IX_RoomRateChangeLog_RoomId_ChangedAt on RoomRateChangeLog(RoomId, ChangedAt DESC)
- [x] 1.2.2 Create index IX_Bookings_Status_CheckIn_Includes on Bookings(Status, CheckIn) INCLUDE (RoomId, TotalAmount)
- [x] 1.2.3 Create index IX_Rooms_HotelId_Includes on Rooms(HotelId) INCLUDE (Code, Name)
- [x] 1.2.4 Test index creation and verify no conflicts with existing indexes

### 1.3 Create Rate_Audit_Trigger

- [x] 1.3.1 Write SQL trigger on Rooms table AFTER UPDATE
- [x] 1.3.2 Implement logic to check if Rate column was updated
- [x] 1.3.3 Calculate ChangePercent as ((NewRate - OldRate) / OldRate) \* 100
- [x] 1.3.4 Filter for ABS(ChangePercent) > 50
- [x] 1.3.5 Handle NULL and zero OldRate values
- [x] 1.3.6 Capture SYSTEM_USER in ChangedBy column
- [x] 1.3.7 Use inserted and deleted tables for row-level operations
- [x] 1.3.8 Test trigger with single-row updates
- [x] 1.3.9 Test trigger with multi-row updates
- [x] 1.3.10 Test trigger with rate changes below 50% threshold

### 1.4 Create Quarterly_Revenue_Analytics Stored Procedure

- [x] 1.4.1 Write stored procedure with parameters @HotelId, @Year, @Quarter
- [x] 1.4.2 Implement CTE for quarterly data aggregation
- [x] 1.4.3 Calculate quarter from CheckIn date (Q1: 1-3, Q2: 4-6, Q3: 7-9, Q4: 10-12)
- [x] 1.4.4 Filter for Status = 'Completed' bookings only
- [x] 1.4.5 Calculate SUM(TotalAmount) as TotalRevenue
- [x] 1.4.6 Calculate COUNT(\*) as TotalBookings
- [x] 1.4.7 Implement ROW_NUMBER() OVER (PARTITION BY HotelId, Year, Quarter ORDER BY TotalRevenue DESC)
- [x] 1.4.8 Filter for Rank <= 3 to get top 3 rooms per hotel-quarter
- [x] 1.4.9 Join with Hotels and Rooms tables for display names
- [x] 1.4.10 Test stored procedure with various parameter combinations
- [x] 1.4.11 Test stored procedure with NULL parameters (all data)

### 1.5 Update Statistics and Optimization

- [x] 1.5.1 Create SQL script to update statistics on Bookings, Rooms, RoomRateChangeLog
- [x] 1.5.2 Add statistics update to deployment script
- [x] 1.5.3 Analyze execution plan for Quarterly_Revenue_Analytics
- [x] 1.5.4 Verify index seeks (not table scans) in execution plan

## Phase 2: C# Backend Implementation

### 2.1 Create Data Models

- [x] 2.1.1 Create RoomRateChangeLog entity class in Models folder
- [x] 2.1.2 Add properties: Id, RoomId, Room, OldRate, NewRate, ChangePercent, ChangedAt, ChangedBy
- [x] 2.1.3 Create QuarterlyRevenueDto in DTOs folder
- [x] 2.1.4 Add properties: HotelId, HotelName, Quarter, Year, RoomCode, RoomName, TotalRevenue, TotalBookings
- [x] 2.1.5 Create RateChangeDto in DTOs folder
- [x] 2.1.6 Add properties: Id, RoomId, RoomCode, RoomName, OldRate, NewRate, ChangePercent, ChangedAt, ChangedBy

### 2.2 Update DbContext

- [x] 2.2.1 Add DbSet<RoomRateChangeLog> to RoyalHotelDbContext
- [x] 2.2.2 Configure RoomRateChangeLog entity in OnModelCreating
- [x] 2.2.3 Set precision for OldRate, NewRate (18,2) and ChangePercent (5,2)
- [x] 2.2.4 Configure foreign key relationship with Room
- [x] 2.2.5 Configure index on (RoomId, ChangedAt)
- [x] 2.2.6 Test DbContext configuration

### 2.3 Create IAnalyticsService Interface

- [x] 2.3.1 Create IAnalyticsService interface in Services/Analytics folder
- [x] 2.3.2 Define GetQuarterlyRevenueAnalyticsAsync method signature
- [x] 2.3.3 Define ParseRateChangeLogAsync method signature
- [x] 2.3.4 Define FormatRateChangeReport method signature

### 2.4 Implement AnalyticsService

- [x] 2.4.1 Create AnalyticsService class implementing IAnalyticsService
- [x] 2.4.2 Inject RoyalHotelDbContext and ILogger dependencies
- [x] 2.4.3 Implement GetQuarterlyRevenueAnalyticsAsync using SqlQueryRaw
- [x] 2.4.4 Create SqlParameter objects for @HotelId, @Year, @Quarter
- [x] 2.4.5 Handle NULL parameters with DBNull.Value
- [x] 2.4.6 Add try-catch error handling and logging
- [x] 2.4.7 Return empty collection on error
- [x] 2.4.8 Implement ParseRateChangeLogAsync with LINQ query
- [x] 2.4.9 Add date range filtering (startDate, endDate)
- [x] 2.4.10 Include Room navigation property
- [x] 2.4.11 Map to RateChangeDto
- [x] 2.4.12 Implement FormatRateChangeReport with HTML table generation
- [x] 2.4.13 Use HtmlEncode for XSS prevention
- [x] 2.4.14 Format currency and percentage values
- [x] 2.4.15 Add CSS classes for positive/negative changes

### 2.5 Update AdminReportsController

- [x] 2.5.1 Inject IAnalyticsService dependency
- [x] 2.5.2 Create QuarterlyRevenue action method (GET)
- [x] 2.5.3 Add parameters: hotelId, year, quarter
- [x] 2.5.4 Add admin authentication check
- [x] 2.5.5 Call GetQuarterlyRevenueAnalyticsAsync
- [x] 2.5.6 Return View with analytics data
- [x] 2.5.7 Create QuarterlyRevenueJson action method for API
- [x] 2.5.8 Return JSON response
- [x] 2.5.9 Create RateChangeHistory action method
- [x] 2.5.10 Add parameters: roomId, startDate, endDate
- [x] 2.5.11 Call ParseRateChangeLogAsync and FormatRateChangeReport
- [x] 2.5.12 Return View with formatted report

### 2.6 Register Services in DI Container

- [x] 2.6.1 Add IAnalyticsService registration in Program.cs
- [x] 2.6.2 Use AddScoped lifetime
- [x] 2.6.3 Test service resolution

## Phase 3: Seed Data Generation

### 3.1 Create Seed Data Script

- [x] 3.1.1 Create SQL script for seed data generation
- [x] 3.1.2 Make script idempotent (check for existing data)
- [x] 3.1.3 Create at least 3 hotels in different cities
- [x] 3.1.4 Create at least 10 rooms distributed across hotels
- [x] 3.1.5 Create bookings spanning 8 quarters (Q1-Q4 2025, Q1-Q4 2026)
- [x] 3.1.6 Ensure each hotel has 5+ completed bookings per quarter for 4 quarters
- [x] 3.1.7 Create varying TotalAmount values for diverse revenue rankings
- [x] 3.1.8 Create test cases for rate changes >+50%
- [x] 3.1.9 Create test cases for rate changes >-50%
- [x] 3.1.10 Create test cases for rate changes within ±50%
- [x] 3.1.11 Create at least one hotel-quarter with >3 rooms
- [x] 3.1.12 Create bookings with various statuses (Completed, Pending, Cancelled, CheckedIn)
- [x] 3.1.13 Test seed data script execution
- [x] 3.1.14 Verify data integrity after seed

## Phase 4: Testing

### 4.1 Unit Tests for AnalyticsService

- [x] 4.1.1 Create test class for AnalyticsService
- [x] 4.1.2 Test GetQuarterlyRevenueAnalyticsAsync with all parameters
- [x] 4.1.3 Test GetQuarterlyRevenueAnalyticsAsync with NULL parameters
- [x] 4.1.4 Test GetQuarterlyRevenueAnalyticsAsync error handling
- [x] 4.1.5 Test ParseRateChangeLogAsync with date range
- [x] 4.1.6 Test ParseRateChangeLogAsync with no results
- [x] 4.1.7 Test FormatRateChangeReport HTML encoding
- [x] 4.1.8 Test FormatRateChangeReport with empty collection
- [x] 4.1.9 Test FormatRateChangeReport formatting (currency, percentage)

### 4.2 Unit Tests for AdminReportsController

- [ ] 4.2.1 Create test class for AdminReportsController
- [ ] 4.2.2 Test QuarterlyRevenue action with admin authentication
- [ ] 4.2.3 Test QuarterlyRevenue action without admin authentication
- [ ] 4.2.4 Test QuarterlyRevenueJson action returns JSON
- [ ] 4.2.5 Test RateChangeHistory action with parameters
- [ ] 4.2.6 Mock IAnalyticsService for controller tests

### 4.3 Integration Tests for Trigger

- [ ] 4.3.1 Test rate increase >50% creates audit log entry
- [ ] 4.3.2 Test rate decrease >50% creates audit log entry
- [ ] 4.3.3 Test rate change ≤50% does not create audit log entry
- [ ] 4.3.4 Test multi-row UPDATE logs all qualifying changes
- [ ] 4.3.5 Test NULL OldRate does not create audit log entry
- [ ] 4.3.6 Test zero OldRate does not create audit log entry
- [ ] 4.3.7 Test ChangePercent calculation accuracy
- [ ] 4.3.8 Test ChangedBy captures user context
- [ ] 4.3.9 Test transaction rollback removes audit log entries

### 4.4 Integration Tests for Quarterly Revenue Analytics

- [ ] 4.4.1 Create test data with known revenue values
- [ ] 4.4.2 Execute stored procedure and compare with manual SUM
- [ ] 4.4.3 Verify TotalRevenue matches SUM(TotalAmount)
- [ ] 4.4.4 Verify TotalBookings matches COUNT(\*)
- [ ] 4.4.5 Verify only Status = 'Completed' bookings included
- [ ] 4.4.6 Test quarter assignment for boundary dates (March 31, April 1)
- [ ] 4.4.7 Verify TOP 3 ranking correctness
- [ ] 4.4.8 Test with hotel-quarter having <3 rooms
- [ ] 4.4.9 Test filtering by HotelId parameter
- [ ] 4.4.10 Test filtering by Year parameter
- [ ] 4.4.11 Test filtering by Quarter parameter

### 4.5 Concurrency Tests

- [ ] 4.5.1 Create test script for concurrent rate updates
- [ ] 4.5.2 Simulate simultaneous updates to different rooms
- [ ] 4.5.3 Verify number of log entries matches qualifying changes
- [ ] 4.5.4 Verify no deadlocks occur
- [ ] 4.5.5 Verify final audit log state is correct
- [ ] 4.5.6 Test transaction isolation

### 4.6 Performance Tests

- [ ] 4.6.1 Create test dataset with 100,000 booking records
- [ ] 4.6.2 Execute Quarterly_Revenue_Analytics and measure time
- [ ] 4.6.3 Verify execution time <2 seconds
- [ ] 4.6.4 Capture and analyze execution plan
- [ ] 4.6.5 Verify index seeks (not table scans)
- [ ] 4.6.6 Test trigger performance with multi-row updates (1,000 rows)
- [ ] 4.6.7 Verify no significant performance degradation

## Phase 5: Views and UI

### 5.1 Create QuarterlyRevenue View

- [x] 5.1.1 Create Views/AdminReports/QuarterlyRevenue.cshtml
- [x] 5.1.2 Add filter form for HotelId, Year, Quarter
- [x] 5.1.3 Display analytics data in table format
- [x] 5.1.4 Add columns: Hotel, Quarter, Year, Room, Revenue, Bookings
- [x] 5.1.5 Format currency values
- [x] 5.1.6 Add sorting functionality
- [ ] 5.1.7 Add export to CSV button (optional)

### 5.2 Create RateChangeHistory View

- [x] 5.2.1 Create Views/AdminReports/RateChangeHistory.cshtml
- [x] 5.2.2 Add filter form for RoomId, StartDate, EndDate
- [x] 5.2.3 Display formatted report HTML
- [x] 5.2.4 Add styling for positive/negative changes
- [ ] 5.2.5 Add pagination for large result sets

### 5.3 Update Navigation

- [x] 5.3.1 Add links to new reports in admin navigation menu
- [x] 5.3.2 Update AdminReports/Index.cshtml with new report links
- [x] 5.3.3 Test navigation flow

## Phase 6: Documentation and Deployment

### 6.1 Create AI Audit Documentation

- [ ] 6.1.1 Create AI_Audit_Report.md in feature directory
- [ ] 6.1.2 Document all AI prompts used with timestamps
- [ ] 6.1.3 Document manual code modifications with rationale
- [ ] 6.1.4 Include unit test results
- [ ] 6.1.5 Include integration test results
- [ ] 6.1.6 Document race condition analysis for trigger
- [ ] 6.1.7 Include execution plan screenshots
- [ ] 6.1.8 Document any deviations from requirements

### 6.2 Create Deployment Scripts

- [x] 6.2.1 Create master deployment script (01_deploy_analytics_feature.sql)
- [x] 6.2.2 Include table creation
- [x] 6.2.3 Include index creation
- [x] 6.2.4 Include trigger creation
- [x] 6.2.5 Include stored procedure creation
- [x] 6.2.6 Include statistics update
- [ ] 6.2.7 Create rollback script
- [ ] 6.2.8 Test deployment script on clean database
- [ ] 6.2.9 Test rollback script

### 6.3 Create Migration

- [x] 6.3.1 Create EF Core migration for RoomRateChangeLog entity
- [ ] 6.3.2 Review generated migration code
- [ ] 6.3.3 Test migration up
- [ ] 6.3.4 Test migration down (rollback)

### 6.4 Update API Documentation

- [ ] 6.4.1 Document QuarterlyRevenue endpoint
- [ ] 6.4.2 Document QuarterlyRevenueJson endpoint
- [ ] 6.4.3 Document RateChangeHistory endpoint
- [ ] 6.4.4 Include request/response examples
- [ ] 6.4.5 Document authentication requirements

### 6.5 Deployment to Staging

- [ ] 6.5.1 Deploy database changes to staging
- [ ] 6.5.2 Run seed data generator on staging
- [ ] 6.5.3 Deploy C# code changes to staging
- [ ] 6.5.4 Restart staging application
- [ ] 6.5.5 Smoke test all analytics endpoints
- [ ] 6.5.6 Validate analytics accuracy against known data
- [ ] 6.5.7 Test trigger behavior on staging

### 6.6 Deployment to Production

- [ ] 6.6.1 Create deployment plan with rollback strategy
- [ ] 6.6.2 Schedule maintenance window
- [ ] 6.6.3 Backup production database
- [ ] 6.6.4 Deploy database changes to production
- [ ] 6.6.5 Run seed data generator on production (if applicable)
- [ ] 6.6.6 Deploy C# code changes to production
- [ ] 6.6.7 Restart production application
- [ ] 6.6.8 Smoke test all analytics endpoints
- [ ] 6.6.9 Monitor application logs for errors
- [ ] 6.6.10 Validate analytics accuracy

## Phase 7: Monitoring and Maintenance

### 7.1 Setup Monitoring

- [ ] 7.1.1 Add logging for analytics service errors
- [ ] 7.1.2 Add performance metrics for stored procedure execution
- [ ] 7.1.3 Add alerts for trigger failures
- [ ] 7.1.4 Monitor database index fragmentation
- [ ] 7.1.5 Monitor query execution times

### 7.2 Create Maintenance Scripts

- [ ] 7.2.1 Create script to rebuild indexes
- [ ] 7.2.2 Create script to update statistics
- [ ] 7.2.3 Create script to archive old audit logs (optional)
- [ ] 7.2.4 Schedule maintenance jobs

### 7.3 User Training

- [ ] 7.3.1 Create user guide for quarterly revenue report
- [ ] 7.3.2 Create user guide for rate change history report
- [ ] 7.3.3 Conduct training session for admin users
- [ ] 7.3.4 Gather user feedback

## Completion Criteria

- All database objects created and tested
- All C# code implemented and tested
- Unit test coverage >80%
- Integration tests passing
- Performance tests meeting targets (<2 seconds for 100K records)
- Concurrency tests passing
- Seed data generator working
- Views and UI functional
- Documentation complete
- Deployed to staging and validated
- Deployed to production and validated
- Monitoring in place
- User training complete
