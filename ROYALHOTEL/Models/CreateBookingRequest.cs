using System.ComponentModel.DataAnnotations;

namespace ROYALHOTEL.ViewModels.Booking;

public class CreateBookingRequest
{
    [Required]
    public int RoomId { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn ngày nhận phòng.")]
    [DataType(DataType.Date)]
    public DateTime CheckInDate { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn ngày trả phòng.")]
    [DataType(DataType.Date)]
    public DateTime CheckOutDate { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn số khách.")]
    [Range(1, 20, ErrorMessage = "Số khách phải lớn hơn 0.")]
    public int Guests { get; set; }

    [Required(ErrorMessage = "Vui lòng nhập họ và tên.")]
    [StringLength(200)]
    public string GuestName { get; set; } = "";

    [Required(ErrorMessage = "Vui lòng nhập email.")]
    [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
    [StringLength(200)]
    public string GuestEmail { get; set; } = "";

    [Required(ErrorMessage = "Vui lòng nhập số điện thoại.")]
    [Phone(ErrorMessage = "Số điện thoại không hợp lệ.")]
    [StringLength(50)]
    public string GuestPhone { get; set; } = "";
}