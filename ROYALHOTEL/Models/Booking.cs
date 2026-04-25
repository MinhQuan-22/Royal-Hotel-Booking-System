namespace ROYALHOTEL.Models;

public class Booking
{
    public int Id { get; set; }

    // Mã booking hiển thị cho người dùng, ví dụ: RH-20260309-001
    public string BookingCode { get; set; } = "";

    public int RoomId { get; set; }
    public Room? Room { get; set; }

    // Link to Account (nullable - guest có thể đặt phòng không cần đăng nhập)
    public int? AccountId { get; set; }
    public Account? Account { get; set; }

    public DateTime CheckIn { get; set; }
    public DateTime CheckOut { get; set; }

    public int Guests { get; set; }

    // Pending / Confirmed / CheckedIn / CheckedOut / Completed / Cancelled
    public string Status { get; set; } = "Pending";

    public string? GuestName { get; set; }
    public string? GuestEmail { get; set; }
    public string? GuestPhone { get; set; }

    // Snapshot giá tại thời điểm đặt phòng
    public decimal? PricePerNight { get; set; }

    // Tổng tiền booking
    public decimal? TotalAmount { get; set; }

    // bank_transfer / card
    public string? PaymentMethod { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation: 1 booking có thể có nhiều transaction (nếu sau này mở rộng retry payment)
    public ICollection<PaymentTransaction> PaymentTransactions { get; set; } = new List<PaymentTransaction>();
}