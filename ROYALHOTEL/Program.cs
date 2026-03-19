using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Data;
using ROYALHOTEL.Services.Booking;
using ROYALHOTEL.Services.Email;
using ROYALHOTEL.Services.Rooms;
using ROYALHOTEL.Services.Notifications;
using ROYALHOTEL.Services.Events;
using ROYALHOTEL.Security;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<RoyalHotelDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped<IRoomRepository, EfRoomRepository>();
builder.Services.AddScoped<RoomQueryService>();

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

builder.Services.AddDistributedMemoryCache();

builder.Services.AddSession();
builder.Services.AddHttpContextAccessor();

builder.Services.Configure<SmtpSettings>(builder.Configuration.GetSection("Smtp"));
builder.Services.AddSingleton<IEmailSender, SmtpEmailSender>(); // Strategy

// Add services to the container.
builder.Services.AddControllersWithViews().AddRazorRuntimeCompilation();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseSession();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();