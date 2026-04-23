# Requirements Document

## Introduction

This feature displays a "🔥 Được đặt nhiều" (Hot/Popular) badge on room cards for the top 3 most-booked room types in the ROYALHOTEL customer interface. The calculation logic must be implemented in SQL Server using a stored procedure to meet Database Advanced course requirements. Only bookings with confirmed statuses are counted, and the badge only appears for room types with at least one valid booking.

## Glossary

- **System**: The ROYALHOTEL booking application (ASP.NET Core MVC)
- **Stored_Procedure**: SQL Server stored procedure `sp_GetTopBookedRoomTypes`
- **Backend_Service**: C# service layer that calls the stored procedure and maps results
- **Room_Card**: Visual component displaying room information in the customer interface
- **RoomType**: The type classification of a room (e.g., "Standard", "Deluxe", "Suite")
- **Valid_Booking_Status**: Booking status values: Confirmed, CheckedIn, CheckedOut, Completed
- **Invalid_Booking_Status**: Booking status values: Pending, Cancelled
- **Top_Booked_RoomType**: A RoomType that ranks in the top 3 by booking count
- **Badge**: Visual indicator "🔥 Được đặt nhiều" displayed on room cards

## Requirements

### Requirement 1: Calculate Top 3 Room Types Using SQL Server

**User Story:** As a database administrator, I want the top 3 most-booked room types calculated in SQL Server, so that the core business logic resides in the database layer as required by the Database Advanced course.

#### Acceptance Criteria

1. THE Stored_Procedure SHALL be named `sp_GetTopBookedRoomTypes`
2. THE Stored_Procedure SHALL join the Bookings table with the Rooms table on RoomId
3. THE Stored_Procedure SHALL filter bookings to include only Valid_Booking_Status values
4. THE Stored_Procedure SHALL exclude bookings with Invalid_Booking_Status values
5. THE Stored_Procedure SHALL exclude rooms where RoomType is NULL or empty string
6. THE Stored_Procedure SHALL group results by RoomType
7. THE Stored_Procedure SHALL count the number of bookings for each RoomType
8. THE Stored_Procedure SHALL return only RoomTypes with booking count greater than zero
9. THE Stored_Procedure SHALL return the top 3 RoomTypes ordered by booking count descending, then by RoomType ascending
10. THE Stored_Procedure SHALL return two columns: RoomType (string) and BookingCount (integer)

### Requirement 2: Backend Integration with Stored Procedure

**User Story:** As a backend developer, I want to call the stored procedure from the service layer, so that I can retrieve top-booked room types without implementing calculation logic in C#.

#### Acceptance Criteria

1. THE Backend_Service SHALL call the Stored_Procedure to retrieve top-booked room types
2. THE Backend_Service SHALL NOT replicate the calculation logic using EF Core or LINQ
3. THE Backend_Service SHALL use ADO.NET, FromSqlRaw, or equivalent method to execute the stored procedure
4. THE Backend_Service SHALL map the stored procedure results to a C# data structure
5. WHEN the stored procedure returns results, THE Backend_Service SHALL extract RoomType values into a collection
6. WHEN the stored procedure execution fails, THE Backend_Service SHALL handle the error gracefully and return an empty collection

### Requirement 3: Display Badge on Room Cards

**User Story:** As a customer, I want to see a "🔥 Được đặt nhiều" badge on popular room types, so that I can identify which rooms are most frequently booked.

#### Acceptance Criteria

1. WHEN a Room_Card is rendered, THE System SHALL check if the room's RoomType is a Top_Booked_RoomType
2. WHERE the room's RoomType is a Top_Booked_RoomType, THE System SHALL display the Badge on the Room_Card
3. WHERE the room's RoomType is NOT a Top_Booked_RoomType, THE System SHALL NOT display the Badge
4. THE Badge SHALL display the text "🔥 Được đặt nhiều"
5. THE Badge SHALL be visually distinct and not break the existing room card layout
6. THE Badge SHALL appear on room cards in the Rooms/Index view

### Requirement 4: Page Data Integration

**User Story:** As a frontend developer, I want top-booked room types available in the page model, so that I can conditionally render badges in the view.

#### Acceptance Criteria

1. THE System SHALL add top-booked room types data to the RoomIndexPageData model
2. THE System SHALL provide the top-booked room types as a collection (List or HashSet) of RoomType strings
3. WHEN the Rooms/Index page is requested, THE System SHALL populate the top-booked room types collection
4. THE System SHALL make the top-booked room types collection accessible to the Rooms/Index view

### Requirement 5: Preserve Existing Functionality

**User Story:** As a system maintainer, I want existing room filtering and sorting to remain unchanged, so that the new feature does not introduce regressions.

#### Acceptance Criteria

1. THE System SHALL NOT modify existing room search logic
2. THE System SHALL NOT modify existing room filtering logic
3. THE System SHALL NOT modify existing room sorting logic
4. THE System SHALL NOT modify MongoDB, catalog, or search functionality
5. WHERE room sorting is applied, THE System SHALL maintain the current sort order
6. WHERE room filtering is applied, THE System SHALL apply filters before badge display logic

### Requirement 6: Optional Room Prioritization

**User Story:** As a product manager, I want rooms with top-booked room types optionally displayed first, so that popular rooms are more visible to customers.

#### Acceptance Criteria

1. WHERE room prioritization is implemented, THE System SHALL move rooms with Top_Booked_RoomType to the front of the list
2. WHERE room prioritization is implemented, THE System SHALL preserve existing filter results
3. WHERE room prioritization is implemented, THE System SHALL preserve existing search results
4. WHERE room prioritization conflicts with user-selected sorting, THE System SHALL respect user-selected sorting

### Requirement 7: Handle Insufficient Data Gracefully

**User Story:** As a system administrator, I want the system to handle cases where fewer than 3 room types have bookings, so that the feature works correctly with limited data.

#### Acceptance Criteria

1. WHEN fewer than 3 RoomTypes have valid bookings, THE System SHALL display badges only for RoomTypes with bookings
2. WHEN no RoomTypes have valid bookings, THE System SHALL NOT display any badges
3. WHEN exactly 1 RoomType has valid bookings, THE System SHALL display the badge only for that RoomType
4. THE System SHALL NOT display badges for RoomTypes with zero bookings

### Requirement 8: Database Migration and Deployment

**User Story:** As a database administrator, I want the stored procedure deployed via a SQL script file, so that it can be version-controlled and applied to different environments.

#### Acceptance Criteria

1. THE System SHALL provide a SQL script file containing the stored procedure definition
2. THE SQL script file SHALL use CREATE OR ALTER syntax for idempotent deployment
3. THE SQL script file SHALL be located in the ROYALHOTEL/Database directory
4. THE SQL script file SHALL include comments explaining the procedure's purpose and logic
