using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Services.Booking;
using ROYALHOTEL.Services.Email;
using ROYALHOTEL.Services.Rooms;
using ROYALHOTEL.Services.Notifications;
using ROYALHOTEL.Services.Events;
using ROYALHOTEL.Services.Analytics;
using ROYALHOTEL.Security;
using ROYALHOTEL.Commands.Common;
using ROYALHOTEL.Commands.Bookings;
using ROYALHOTEL.Services.Accounts;
using ROYALHOTEL.Services.Catalog;
using ROYALHOTEL.Middleware;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<RoyalHotelDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ==========================================================
// MongoDB HotelCatalog — Singleton context + Scoped services
// ==========================================================
builder.Services.AddSingleton<MongoDbContext>();
builder.Services.AddScoped<IHotelCatalogService, MongoHotelCatalogService>();
builder.Services.AddScoped<CatalogSyncService>();

builder.Services.AddScoped<IRoomRepository, EfRoomRepository>();
builder.Services.AddScoped<RoomQueryService>();
builder.Services.AddScoped<IRoomPageService, RoomPageService>();

// DbPricingRuleStrategy: Đọc TẤT CẢ PricingRule active từ DB (weekend/holiday/promotion).
// Admin chỉnh rule trên UI → phản ánh ngay ở request tiếp theo. Không hardcode trong code.
builder.Services.AddScoped<IRoomPricingStrategy, DbPricingRuleStrategy>();

builder.Services.AddScoped<RoomPricingService>();
builder.Services.AddScoped<IPricingRuleAdminService, PricingRuleAdminService>();

// Analytics Service: Quarterly revenue analytics and rate change audit reporting
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();

// Adapter Pattern: Register notification service
builder.Services.AddScoped<IBookingNotificationService, EmailNotificationAdapter>();

// Observer Pattern: Register event publisher and observers
builder.Services.AddScoped<IBookingEventPublisher, BookingEventPublisher>();
builder.Services.AddScoped<IBookingEventObserver, EmailBookingConfirmedObserver>();
builder.Services.AddScoped<IBookingEventObserver, AuditLogBookingObserver>();

// Decorator Pattern: Register core service and wrap with validation decorator
builder.Services.AddScoped<CoreBookingService>();
builder.Services.AddScoped<IBookingService>(sp =>
{
    var context = sp.GetRequiredService<RoyalHotelDbContext>();
    var coreService = sp.GetRequiredService<CoreBookingService>();
    return new BookingValidationDecorator(coreService, context);
});

// Command Pattern: Register command dispatcher and handlers
builder.Services.AddScoped<IAdminCommandDispatcher, AdminCommandDispatcher>();

builder.Services.AddScoped<IAdminCommandHandler<ConfirmBookingCommand>, ConfirmBookingCommandHandler>();
builder.Services.AddScoped<IAdminCommandHandler<CheckInBookingCommand>, CheckInBookingCommandHandler>();
builder.Services.AddScoped<IAdminCommandHandler<CheckOutBookingCommand>, CheckOutBookingCommandHandler>();
builder.Services.AddScoped<IAdminCommandHandler<CompleteBookingCommand>, CompleteBookingCommandHandler>();
builder.Services.AddScoped<IAdminCommandHandler<CancelBookingCommand>, CancelBookingCommandHandler>();
//

builder.Services.AddDistributedMemoryCache();

builder.Services.AddSession();
builder.Services.AddHttpContextAccessor();

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IPasswordResetService, PasswordResetService>();
builder.Services.AddScoped<IUserSessionService, UserSessionService>();

builder.Services.Configure<SmtpSettings>(builder.Configuration.GetSection("Smtp"));
builder.Services.AddSingleton<IEmailSender, SmtpEmailSender>(); // Strategy

// Chat Services: Data validation and utility services
builder.Services.AddSingleton<ROYALHOTEL.Services.Chat.ConversationCodeGenerator>();
builder.Services.AddSingleton<ROYALHOTEL.Services.Chat.DataSanitizer>();
builder.Services.AddSingleton<ROYALHOTEL.Services.Chat.LogMasker>();

// Chat Services: Core business logic and AI integration
builder.Services.AddHttpClient<ROYALHOTEL.Services.Chat.IAIService, ROYALHOTEL.Services.Chat.AIService>();
builder.Services.AddScoped<ROYALHOTEL.Services.Chat.IChatService, ROYALHOTEL.Services.Chat.ChatService>();
builder.Services.AddMemoryCache();

// Chat Services: Background service for auto-closing inactive conversations
// Task 12.3: Runs daily to close conversations inactive for >7 days
builder.Services.AddHostedService<ROYALHOTEL.Services.Chat.ConversationAutoCloseService>();

// Add services to the container.
builder.Services.AddControllersWithViews().AddRazorRuntimeCompilation();

// ==========================================================
// Health Checks
// ==========================================================
builder.Services.AddHealthChecks()
    .AddSqlServer(
        connectionString: builder.Configuration.GetConnectionString("DefaultConnection")!,
        name: "sqlserver",
        failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Degraded,
        tags: new[] { "db", "sql" })
    .AddCheck<ROYALHOTEL.HealthChecks.MongoDbHealthCheck>(
        name: "mongodb",
        failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Degraded,
        tags: new[] { "db", "nosql" });

var app = builder.Build();

// Đảm bảo MongoDB indexes tồn tại khi app khởi động
try
{
    using var scope = app.Services.CreateScope();
    var mongo = scope.ServiceProvider.GetRequiredService<MongoDbContext>();
    await mongo.EnsureIndexesAsync();
    Console.WriteLine("[MongoDB] Indexes ensured on HotelCatalog collection.");
}
catch (Exception ex)
{
    Console.WriteLine($"[MongoDB] EnsureIndexes failed (non-fatal): {ex.Message}");
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

// Rate limiting middleware - must be before routing to intercept requests early
app.UseMiddleware<RateLimiterMiddleware>();

app.UseSession();
app.UseAuthorization();

// Health check endpoint
app.MapHealthChecks("/health");

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();