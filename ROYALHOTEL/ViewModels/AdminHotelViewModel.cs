using System.ComponentModel.DataAnnotations;

namespace ROYALHOTEL.ViewModels
{
    public class AdminHotelViewModel
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Tên chi nhánh không được để trống.")]
        [StringLength(200, ErrorMessage = "Tên tối đa 200 ký tự.")]
        public string Name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Địa chỉ không được để trống.")]
        [StringLength(500, ErrorMessage = "Địa chỉ tối đa 500 ký tự.")]
        public string Address { get; set; } = string.Empty;

        [Required(ErrorMessage = "Thành phố không được để trống.")]
        [StringLength(100, ErrorMessage = "Tên thành phố tối đa 100 ký tự.")]
        public string City { get; set; } = string.Empty;

        [Required(ErrorMessage = "Quốc gia không được để trống.")]
        [StringLength(100, ErrorMessage = "Tên quốc gia tối đa 100 ký tự.")]
        public string Country { get; set; } = "Vietnam";

        // Số phòng active (read-only, tính từ DB)
        public int ActiveRoomCount { get; set; }
    }
}
