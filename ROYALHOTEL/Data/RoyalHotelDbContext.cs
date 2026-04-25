using Microsoft.EntityFrameworkCore;
using ROYALHOTEL.Models;

namespace ROYALHOTEL.Data;

public class RoyalHotelDbContext : DbContext
{
    public RoyalHotelDbContext(DbContextOptions<RoyalHotelDbContext> options) : base(options) { }

    public DbSet<Hotel> Hotels => Set<Hotel>();
    public DbSet<Room> Rooms => Set<Room>();
    public DbSet<Amenity> Amenities => Set<Amenity>();
    public DbSet<RoomAmenity> RoomAmenities => Set<RoomAmenity>();
    public DbSet<RoomImage> RoomImages => Set<RoomImage>();
    public DbSet<Booking> Bookings => Set<Booking>();
    public DbSet<PaymentTransaction> PaymentTransactions => Set<PaymentTransaction>();

    public DbSet<PricingRule> PricingRules => Set<PricingRule>();
    public DbSet<PricingRuleHistory> PricingRuleHistories => Set<PricingRuleHistory>();

    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<PasswordResetOtp> PasswordResetOtps => Set<PasswordResetOtp>();

    public DbSet<RoomRateChangeLog> RoomRateChangeLogs => Set<RoomRateChangeLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // =========================
        // Hotel
        // =========================
        modelBuilder.Entity<Hotel>(e =>
        {
            e.ToTable("Hotels");

            e.Property(x => x.Name)
                .HasMaxLength(200)
                .IsRequired();

            e.Property(x => x.Address)
                .HasMaxLength(500)
                .IsRequired();

            e.Property(x => x.City)
                .HasMaxLength(100)
                .IsRequired();

            e.Property(x => x.Country)
                .HasMaxLength(100)
                .IsRequired();
        });

        // =========================
        // Room / Amenity / Images
        // =========================
        modelBuilder.Entity<RoomAmenity>()
            .HasKey(x => new { x.RoomId, x.AmenityId });

        modelBuilder.Entity<RoomAmenity>()
            .HasOne(x => x.Room)
            .WithMany(r => r.RoomAmenities)
            .HasForeignKey(x => x.RoomId);

        modelBuilder.Entity<RoomAmenity>()
            .HasOne(x => x.Amenity)
            .WithMany(a => a.RoomAmenities)
            .HasForeignKey(x => x.AmenityId);

        modelBuilder.Entity<RoomImage>()
            .HasOne<Room>()
            .WithMany(r => r.Images)
            .HasForeignKey(i => i.RoomId);

        modelBuilder.Entity<Room>(e =>
        {
            e.Property(x => x.BasePricePerNight)
                .HasPrecision(18, 2);

            e.Property(x => x.Rate)
                .HasPrecision(18, 2)
                .IsRequired();

            e.Property(x => x.Status)
                .HasMaxLength(20)
                .IsRequired();

            e.HasOne(x => x.Hotel)
                .WithMany(h => h.Rooms)
                .HasForeignKey(x => x.HotelId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // =========================
        // PricingRule
        // =========================
        modelBuilder.Entity<PricingRule>(e =>
        {
            e.ToTable("PricingRules");

            e.Property(x => x.Name)
                .HasMaxLength(200)
                .IsRequired();

            e.Property(x => x.RuleType)
                .HasMaxLength(20)
                .IsRequired();

            e.Property(x => x.RoomType)
                .HasMaxLength(50);

            e.Property(x => x.DayOfWeekMask)
                .HasMaxLength(50);

            e.Property(x => x.Multiplier)
                .HasPrecision(10, 4);

            e.Property(x => x.Priority)
                .HasDefaultValue(100);

            e.Property(x => x.IsActive)
                .HasDefaultValue(true);

            e.Property(x => x.Notes)
                .HasMaxLength(500);

            e.Property(x => x.CreatedBy)
                .HasMaxLength(200);

            e.Property(x => x.UpdatedBy)
                .HasMaxLength(200);

            e.HasIndex(x => new { x.IsActive, x.RuleType, x.RoomType, x.Priority });
        });

        modelBuilder.Entity<PricingRuleHistory>(e =>
        {
            e.ToTable("PricingRuleHistories");

            e.Property(x => x.ActionType)
                .HasMaxLength(20)
                .IsRequired();

            e.Property(x => x.RuleName)
                .HasMaxLength(200)
                .IsRequired();

            e.Property(x => x.RuleType)
                .HasMaxLength(20)
                .IsRequired();

            e.Property(x => x.RoomType)
                .HasMaxLength(50);

            e.Property(x => x.DayOfWeekMask)
                .HasMaxLength(50);

            e.Property(x => x.Multiplier)
                .HasPrecision(10, 4);

            e.Property(x => x.Notes)
                .HasMaxLength(500);

            e.Property(x => x.ChangedBy)
                .HasMaxLength(200);

            e.HasIndex(x => new { x.PricingRuleId, x.ChangedAt });
        });

        // =========================
        // Booking
        // =========================
        modelBuilder.Entity<Booking>(e =>
        {
            e.ToTable("Bookings");

            e.Property(x => x.BookingCode)
                .HasMaxLength(50)
                .IsRequired();

            e.Property(x => x.Status)
                .HasMaxLength(30)
                .IsRequired();

            e.Property(x => x.GuestName)
                .HasMaxLength(200);

            e.Property(x => x.GuestEmail)
                .HasMaxLength(200);

            e.Property(x => x.GuestPhone)
                .HasMaxLength(50);

            e.Property(x => x.PaymentMethod)
                .HasMaxLength(50);

            e.Property(x => x.PricePerNight)
                .HasPrecision(18, 2);

            e.Property(x => x.TotalAmount)
                .HasPrecision(18, 2);

            e.Property(x => x.RefundAmount).HasPrecision(18, 2);
            e.Property(x => x.RefundStatus).HasMaxLength(50);
            e.Property(x => x.CancelReason).HasMaxLength(255);
            e.Property(x => x.RefundPolicyApplied).HasMaxLength(255);

            e.HasOne(x => x.Room)
                .WithMany()
                .HasForeignKey(x => x.RoomId)
                .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Account)
                .WithMany(a => a.Bookings)
                .HasForeignKey(x => x.AccountId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // =========================
        // PaymentTransaction
        // =========================
        modelBuilder.Entity<PaymentTransaction>(e =>
        {
            e.ToTable("PaymentTransactions");

            e.Property(x => x.PaymentMethod)
                .HasMaxLength(50)
                .IsRequired();

            e.Property(x => x.Amount)
                .HasPrecision(18, 2);

            e.Property(x => x.Status)
                .HasMaxLength(50)
                .IsRequired();

            e.Property(x => x.TransactionCode)
                .HasMaxLength(100);

            e.Property(x => x.TransactionType).HasMaxLength(20).HasDefaultValue("Payment");
            e.Property(x => x.Note).HasMaxLength(255);

            e.HasOne(x => x.Booking)
                .WithMany(b => b.PaymentTransactions)
                .HasForeignKey(x => x.BookingId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.ParentTransaction)
                .WithMany()
                .HasForeignKey(x => x.ParentTransactionId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // =========================
        // Account
        // =========================
        modelBuilder.Entity<Account>(e =>
        {
            e.ToTable("Accounts");

            e.HasIndex(x => x.Email).IsUnique();

            e.Property(x => x.FullName)
                .HasMaxLength(200)
                .IsRequired();

            e.Property(x => x.Email)
                .HasMaxLength(200)
                .IsRequired();

            e.Property(x => x.Phone)
                .HasMaxLength(50);

            e.Property(x => x.PasswordHash)
                .HasMaxLength(500)
                .IsRequired();

            e.Property(x => x.PasswordSalt)
                .HasMaxLength(200)
                .IsRequired();

            e.Property(x => x.Role)
                .HasMaxLength(20)
                .IsRequired()
                .HasDefaultValue("user");
        });

        // =========================
        // PasswordResetOtp
        // =========================
        modelBuilder.Entity<PasswordResetOtp>(e =>
        {
            e.ToTable("PasswordResetOtps");

            e.HasKey(x => x.Id);

            e.HasOne(x => x.Account)
                .WithMany()
                .HasForeignKey(x => x.AccountId)
                .OnDelete(DeleteBehavior.Cascade);

            e.Property(x => x.OtpHash)
                .HasMaxLength(200)
                .IsRequired();

            e.Property(x => x.OtpSalt)
                .HasMaxLength(200)
                .IsRequired();

            e.Property(x => x.AttemptCount)
                .HasDefaultValue(0);
        });

        // =========================
        // RoomRateChangeLog
        // =========================
        modelBuilder.Entity<RoomRateChangeLog>(e =>
        {
            e.ToTable("RoomRateChangeLog");

            e.Property(x => x.OldRate)
                .HasPrecision(18, 2)
                .IsRequired();

            e.Property(x => x.NewRate)
                .HasPrecision(18, 2)
                .IsRequired();

            e.Property(x => x.ChangePercent)
                .HasPrecision(5, 2)
                .IsRequired();

            e.Property(x => x.ChangedBy)
                .HasMaxLength(100);

            e.HasOne(x => x.Room)
                .WithMany()
                .HasForeignKey(x => x.RoomId)
                .OnDelete(DeleteBehavior.Restrict);

            e.HasIndex(x => new { x.RoomId, x.ChangedAt })
                .HasDatabaseName("IX_RoomRateChangeLog_RoomId_ChangedAt");
        });
    }
}