# Decorator Pattern Refactor - Booking Validation

## Overview
Applied the Decorator Pattern to separate validation logic from core booking business logic in the ROYALHOTEL project.

## Pattern Implementation

### Problem
The original `BookingService` mixed validation logic with core business logic in `CreateBookingAsync()`:
- Room existence and active status check
- Date validation (CheckOut > CheckIn)
- Guest count validation
- Booking overlap detection

This violated the Single Responsibility Principle and made the service harder to test and maintain.

### Solution
Split the service into two components using the Decorator Pattern:

1. **CoreBookingService** - Handles core business logic only:
   - Calculate price (nights × price per night)
   - Create booking record
   - Generate booking code
   - Save to database

2. **BookingValidationDecorator** - Wraps CoreBookingService and adds validation:
   - Room exists and is active
   - CheckOutDate > CheckInDate
   - Guests > 0 and <= MaxGuests
   - No overlap with Confirmed/CheckedIn bookings

## Files Changed

### Created Files
- `Services/Booking/CoreBookingService.cs` - Core booking logic without validation
- `Services/Booking/BookingValidationDecorator.cs` - Validation wrapper

### Modified Files
- `Program.cs` - Updated DI registration to use decorator pattern

### Deleted Files
- `Services/Booking/BookingService.cs` - Replaced by CoreBookingService + Decorator

## Dependency Injection Configuration

```csharp
// Register core service
builder.Services.AddScoped<CoreBookingService>();

// Register IBookingService as factory returning decorated instance
builder.Services.AddScoped<IBookingService>(sp =>
{
    var context = sp.GetRequiredService<RoyalHotelDbContext>();
    var coreService = sp.GetRequiredService<CoreBookingService>();
    return new BookingValidationDecorator(coreService, context);
});
```

## Benefits

1. **Separation of Concerns**: Validation logic is isolated from business logic
2. **Single Responsibility**: Each class has one clear purpose
3. **Testability**: Can test core logic and validation independently
4. **Extensibility**: Easy to add more decorators (e.g., logging, caching)
5. **Maintainability**: Changes to validation don't affect core logic

## How It Works

When `IBookingService.CreateBookingAsync()` is called:

1. Request enters `BookingValidationDecorator.CreateBookingAsync()`
2. Decorator performs all validations
3. If validation fails, throws exception immediately
4. If validation passes, calls `_inner.CreateBookingAsync()` (CoreBookingService)
5. CoreBookingService executes core business logic
6. Result returns through decorator to caller

All other methods (`GetBookingById`, `ConfirmPayment`, `Cancel`, etc.) are forwarded directly to the inner service without modification.

## Testing Strategy

- Test `CoreBookingService` with valid inputs to verify business logic
- Test `BookingValidationDecorator` with invalid inputs to verify validation rules
- Integration tests verify the decorated service works end-to-end

## Pattern Comparison

This project now uses multiple design patterns:

- **Factory Method**: Payment processing (`PaymentProcessorFactory`)
- **Decorator**: Booking validation (`BookingValidationDecorator`)
- **Strategy**: Email sending (`IEmailSender` implementations)
- **Repository**: Data access (`IRoomRepository`)

Each pattern solves a specific problem and improves code quality.
