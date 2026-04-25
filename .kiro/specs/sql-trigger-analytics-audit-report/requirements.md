# Requirements Document

## Introduction

This document specifies the requirements for the SQL Trigger, Analytics, Audit & Report Integration feature for the Royal Hotel Management System. The feature introduces automated audit logging for room rate changes, advanced quarterly revenue analytics, backend integration for reporting, comprehensive test data, and performance optimization for large datasets.

The system will automatically track significant room rate changes (>50%), provide quarterly revenue insights per hotel, and expose analytics data through backend services for dashboard consumption.

## Glossary

- **RoomRateChangeLog**: Audit table that records historical room rate changes
- **Rate_Audit_Trigger**: SQL trigger that automatically logs room rate changes exceeding 50%
- **Quarterly_Revenue_Analytics**: Stored procedure or view that calculates top 3 revenue-generating rooms per hotel per quarter
- **Analytics_Service**: Backend C# service that retrieves and processes analytics data
- **Admin_Reports_Controller**: ASP.NET Core MVC controller that exposes analytics endpoints
- **Seed_Data_Generator**: SQL scripts that populate test data for multiple quarters and hotels
- **Execution_Plan_Analyzer**: SQL Server tool output showing query performance metrics
- **Royal_Hotel_System**: The complete ASP.NET Core MVC + SQL Server hotel management application
- **Rooms_Table**: SQL Server table storing room information including Rate column
- **Bookings_Table**: SQL Server table storing booking records with Status and TotalAmount
- **Hotels_Table**: SQL Server table storing hotel information
- **Quarter**: Three-month period (Q1: Jan-Mar, Q2: Apr-Jun, Q3: Jul-Sep, Q4: Oct-Dec)
- **Revenue**: Total amount from completed bookings (Status = 'Completed')
- **Change_Percent**: Calculated percentage change between old and new room rates

## Requirements

### Requirement 1: Room Rate Change Audit Logging

**User Story:** As a hotel administrator, I want to automatically track significant room rate changes, so that I can audit pricing decisions and detect anomalies.

#### Acceptance Criteria

1. THE Royal_Hotel_System SHALL create a RoomRateChangeLog table with columns: Id (INT IDENTITY PRIMARY KEY), RoomId (INT NOT NULL), OldRate (DECIMAL(18,2) NOT NULL), NewRate (DECIMAL(18,2) NOT NULL), ChangePercent (DECIMAL(5,2) NOT NULL), ChangedAt (DATETIME2 NOT NULL DEFAULT GETDATE()), ChangedBy (NVARCHAR(100) NULL)

2. THE RoomRateChangeLog SHALL include a foreign key constraint on RoomId referencing Rooms_Table(Id)

3. THE Royal_Hotel_System SHALL create an index on RoomRateChangeLog(RoomId, ChangedAt DESC) for efficient audit queries

4. WHEN a room rate change is logged, THE RoomRateChangeLog SHALL store the absolute value of ChangePercent

5. FOR ALL valid RoomRateChangeLog entries, the relationship ((NewRate - OldRate) / OldRate) \* 100 SHALL equal ChangePercent within 0.01 tolerance (round-trip calculation property)

### Requirement 2: Automatic Rate Change Trigger

**User Story:** As a hotel administrator, I want the system to automatically log room rate changes exceeding 50%, so that I can monitor significant pricing adjustments without manual intervention.

#### Acceptance Criteria

1. THE Royal_Hotel_System SHALL create a Rate_Audit_Trigger on Rooms_Table that fires AFTER UPDATE

2. WHEN Rooms_Table.Rate is updated AND the absolute value of ((NEW.Rate - OLD.Rate) / OLD.Rate) \* 100 is greater than 50, THEN THE Rate_Audit_Trigger SHALL insert a record into RoomRateChangeLog

3. WHEN Rooms_Table.Rate is updated AND the absolute value of ((NEW.Rate - OLD.Rate) / OLD.Rate) \* 100 is less than or equal to 50, THEN THE Rate_Audit_Trigger SHALL NOT insert a record into RoomRateChangeLog

4. WHEN multiple rooms are updated in a single UPDATE statement, THE Rate_Audit_Trigger SHALL log each room that meets the 50% threshold independently

5. THE Rate_Audit_Trigger SHALL calculate ChangePercent as ((NEW.Rate - OLD.Rate) / OLD.Rate) \* 100 and store the signed value

6. WHEN OLD.Rate is zero or NULL, THE Rate_Audit_Trigger SHALL NOT attempt to calculate ChangePercent and SHALL NOT insert a log record

7. THE Rate_Audit_Trigger SHALL populate ChangedBy with SYSTEM_USER or SESSION_USER where available

8. FOR ALL trigger executions with valid rate changes, inserting a log record SHALL NOT fail the UPDATE operation (trigger must handle errors gracefully)

### Requirement 3: Quarterly Revenue Analytics Query

**User Story:** As a hotel manager, I want to view the top 3 revenue-generating rooms per hotel per quarter, so that I can identify high-performing assets and optimize inventory allocation.

#### Acceptance Criteria

1. THE Royal_Hotel_System SHALL create a Quarterly_Revenue_Analytics stored procedure or view that accepts optional parameters: @HotelId (INT NULL), @Year (INT NULL), @Quarter (INT NULL)

2. THE Quarterly_Revenue_Analytics SHALL calculate Quarter from Bookings_Table.CheckIn date as: Q1 (months 1-3), Q2 (months 4-6), Q3 (months 7-9), Q4 (months 10-12)

3. THE Quarterly_Revenue_Analytics SHALL calculate TotalRevenue as SUM(Bookings_Table.TotalAmount) WHERE Bookings_Table.Status = 'Completed'

4. THE Quarterly_Revenue_Analytics SHALL group results by HotelId, Quarter, Year, and RoomId

5. THE Quarterly_Revenue_Analytics SHALL return the top 3 rooms per hotel per quarter ordered by TotalRevenue DESC

6. THE Quarterly_Revenue_Analytics SHALL output columns: HotelId (INT), HotelName (NVARCHAR), Quarter (NVARCHAR), Year (INT), RoomCode (NVARCHAR), RoomName (NVARCHAR), TotalRevenue (DECIMAL(18,2)), TotalBookings (INT)

7. WHEN @HotelId is provided, THE Quarterly_Revenue_Analytics SHALL filter results to that specific hotel

8. WHEN @Year is provided, THE Quarterly_Revenue_Analytics SHALL filter results to that specific year

9. WHEN @Quarter is provided (1-4), THE Quarterly_Revenue_Analytics SHALL filter results to that specific quarter

10. WHEN no parameters are provided, THE Quarterly_Revenue_Analytics SHALL return results for all hotels, all quarters, and all years

11. THE Quarterly_Revenue_Analytics SHALL use ROW_NUMBER() OVER (PARTITION BY HotelId, Year, Quarter ORDER BY TotalRevenue DESC) to rank rooms within each hotel-quarter combination

12. FOR ALL hotel-quarter combinations with fewer than 3 rooms having completed bookings, THE Quarterly_Revenue_Analytics SHALL return only the available rooms (not pad with nulls)

### Requirement 4: Backend Analytics Integration

**User Story:** As a developer, I want a backend service to retrieve quarterly revenue analytics, so that I can display the data in admin dashboards and reports.

#### Acceptance Criteria

1. THE Royal_Hotel_System SHALL create or update Analytics_Service with a method GetQuarterlyRevenueAnalytics that accepts parameters: hotelId (int?), year (int?), quarter (int?)

2. THE Analytics_Service.GetQuarterlyRevenueAnalytics SHALL execute the Quarterly_Revenue_Analytics stored procedure with provided parameters

3. THE Analytics_Service.GetQuarterlyRevenueAnalytics SHALL return a collection of QuarterlyRevenueDto objects containing: HotelId, HotelName, Quarter, Year, RoomCode, RoomName, TotalRevenue, TotalBookings

4. THE Admin_Reports_Controller SHALL expose an action method QuarterlyRevenue that accepts query parameters: hotelId, year, quarter

5. THE Admin_Reports_Controller.QuarterlyRevenue SHALL call Analytics_Service.GetQuarterlyRevenueAnalytics with the provided parameters

6. THE Admin_Reports_Controller.QuarterlyRevenue SHALL return JSON data or a view model for rendering

7. WHEN Analytics_Service.GetQuarterlyRevenueAnalytics encounters a database error, THE Analytics_Service SHALL log the error and return an empty collection or throw a custom exception

8. THE Admin_Reports_Controller.QuarterlyRevenue SHALL require admin authentication (Role = 'admin')

### Requirement 5: Comprehensive Test Data Generation

**User Story:** As a QA engineer, I want comprehensive seed data covering multiple quarters and hotels, so that I can validate analytics accuracy and trigger behavior.

#### Acceptance Criteria

1. THE Seed_Data_Generator SHALL create at least 3 hotels in Hotels_Table with distinct cities

2. THE Seed_Data_Generator SHALL create at least 10 rooms distributed across the 3 hotels

3. THE Seed_Data_Generator SHALL create bookings spanning at least 8 quarters (Q1-Q4 for years 2025 and 2026)

4. THE Seed_Data_Generator SHALL ensure each hotel has at least 5 completed bookings per quarter for at least 4 quarters

5. THE Seed_Data_Generator SHALL create bookings with varying TotalAmount values to produce diverse revenue rankings

6. THE Seed_Data_Generator SHALL include test cases for Rate_Audit_Trigger: at least 2 rate changes exceeding +50%, at least 2 rate changes exceeding -50%, and at least 2 rate changes within ±50%

7. THE Seed_Data_Generator SHALL ensure at least one hotel-quarter combination has more than 3 rooms with completed bookings to test TOP 3 ranking

8. THE Seed_Data_Generator SHALL include bookings with Status values: 'Completed', 'Pending', 'Cancelled', 'CheckedIn' to validate status filtering

9. THE Seed_Data_Generator SHALL be idempotent (can be run multiple times without creating duplicate data or causing errors)

### Requirement 6: Query Performance Optimization

**User Story:** As a database administrator, I want optimized analytics queries with appropriate indexes, so that reports load quickly even with large datasets.

#### Acceptance Criteria

1. THE Royal_Hotel_System SHALL create an index on Bookings_Table(Status, CheckIn) INCLUDE (RoomId, TotalAmount) to support quarterly revenue queries

2. THE Royal_Hotel_System SHALL create an index on Rooms_Table(HotelId) INCLUDE (Code, Name) to support hotel-room joins

3. THE Quarterly_Revenue_Analytics SHALL use indexes effectively as verified by SQL Server Execution_Plan_Analyzer

4. THE Execution_Plan_Analyzer output for Quarterly_Revenue_Analytics SHALL show index seek operations (not table scans) for Bookings_Table and Rooms_Table when filtering by Status and HotelId

5. THE Quarterly_Revenue_Analytics SHALL execute in under 2 seconds for datasets containing up to 100,000 booking records

6. THE Royal_Hotel_System SHALL include statistics update commands in deployment scripts to ensure query optimizer has current data distribution information

7. WHEN Execution_Plan_Analyzer identifies missing indexes, THE Royal_Hotel_System SHALL document the recommendations and implement high-impact indexes (improvement > 30%)

### Requirement 7: AI Audit Documentation

**User Story:** As a project auditor, I want documentation of AI-assisted development and manual verification, so that I can assess code quality and correctness.

#### Acceptance Criteria

1. THE Royal_Hotel_System SHALL include a document AI_Audit_Report.md in the feature directory

2. THE AI_Audit_Report.md SHALL list all AI prompts used for code generation with timestamps and tool names

3. THE AI_Audit_Report.md SHALL document all manual code modifications with rationale (e.g., "Fixed race condition in trigger", "Optimized JOIN order")

4. THE AI_Audit_Report.md SHALL include evidence of correctness testing: unit test results, integration test results, manual test scenarios executed

5. THE AI_Audit_Report.md SHALL document race condition analysis for Rate_Audit_Trigger including: identified risks, mitigation strategies, test scenarios

6. THE AI_Audit_Report.md SHALL include screenshots or text output of Execution_Plan_Analyzer results

7. THE AI_Audit_Report.md SHALL document any deviations from original requirements with justification

8. THE AI_Audit_Report.md SHALL be written in Vietnamese or English based on project team preference

### Requirement 8: Rate Change Log Parser and Formatter

**User Story:** As a developer, I want to parse and format rate change logs for reporting, so that I can display audit information in a user-friendly format.

#### Acceptance Criteria

1. THE Analytics_Service SHALL include a method ParseRateChangeLog that accepts a RoomId and date range (startDate, endDate)

2. THE Analytics_Service.ParseRateChangeLog SHALL query RoomRateChangeLog and return a collection of RateChangeDto objects

3. THE Analytics_Service SHALL include a method FormatRateChangeReport that accepts a collection of RateChangeDto objects and returns a formatted string or HTML representation

4. THE Analytics_Service.FormatRateChangeReport SHALL include room details (Code, Name), old rate, new rate, change percent, and timestamp

5. FOR ALL valid RateChangeDto objects, parsing the formatted output and re-parsing SHALL produce equivalent RateChangeDto objects (round-trip property for serialization)

6. THE Analytics_Service.ParseRateChangeLog SHALL handle empty result sets gracefully by returning an empty collection

7. THE Analytics_Service.FormatRateChangeReport SHALL escape HTML special characters to prevent injection vulnerabilities

### Requirement 9: Analytics Data Validation

**User Story:** As a QA engineer, I want to validate analytics calculations against raw data, so that I can ensure report accuracy.

#### Acceptance Criteria

1. THE Royal_Hotel_System SHALL include integration tests that compare Quarterly_Revenue_Analytics output against manual SUM calculations from Bookings_Table

2. THE integration tests SHALL verify that TotalRevenue matches SUM(TotalAmount) for each hotel-quarter-room combination

3. THE integration tests SHALL verify that TotalBookings matches COUNT(\*) for each hotel-quarter-room combination

4. THE integration tests SHALL verify that only Status = 'Completed' bookings are included in revenue calculations

5. THE integration tests SHALL verify that quarter assignment is correct for boundary dates (e.g., March 31 is Q1, April 1 is Q2)

6. THE integration tests SHALL verify that TOP 3 ranking is correct by comparing against ORDER BY TotalRevenue DESC results

7. FOR ALL test scenarios, the analytics output SHALL match the expected values within 0.01 tolerance for decimal amounts (metamorphic property: analytics aggregation = manual aggregation)

### Requirement 10: Trigger Correctness and Concurrency

**User Story:** As a database administrator, I want the rate change trigger to handle concurrent updates correctly, so that audit logs remain accurate under load.

#### Acceptance Criteria

1. THE Rate_Audit_Trigger SHALL use row-level operations (inserted and deleted tables) to handle multi-row updates correctly

2. WHEN two concurrent transactions update different rooms' rates, THE Rate_Audit_Trigger SHALL log both changes independently without interference

3. WHEN a transaction updates a room rate and then rolls back, THE Rate_Audit_Trigger SHALL NOT leave orphaned log entries (trigger participates in transaction)

4. THE Royal_Hotel_System SHALL include concurrency tests that simulate simultaneous rate updates to multiple rooms

5. THE concurrency tests SHALL verify that the number of log entries matches the number of rate changes exceeding 50% threshold

6. THE Rate_Audit_Trigger SHALL NOT introduce deadlocks when multiple transactions update Rooms_Table concurrently

7. FOR ALL concurrent update scenarios, the final RoomRateChangeLog state SHALL be equivalent to sequential execution (confluence property: order of updates doesn't affect final audit log correctness)
