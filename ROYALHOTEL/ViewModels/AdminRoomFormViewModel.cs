using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace ROYALHOTEL.ViewModels
{
    public class AdminRoomFormViewModel
    {
        public int Id { get; set; }

        [Required]
        [StringLength(50)]
        public string Code { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [StringLength(50)]
        public string RoomType { get; set; } = string.Empty;

        [Range(0, 1000000000)]
        public decimal BasePricePerNight { get; set; }

        [Range(1, 20)]
        public int MaxGuests { get; set; }

        public bool IsActive { get; set; } = true;

        public string? Description { get; set; }

        [StringLength(500)]
        public string? CoverImageUrl { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn chi nhánh.")]
        [Range(1, int.MaxValue, ErrorMessage = "Vui lòng chọn chi nhánh.")]
        public int HotelId { get; set; }

        public List<int> SelectedAmenityIds { get; set; } = new();
        public List<SelectListItem> AmenityOptions { get; set; } = new();
        public List<SelectListItem> HotelOptions { get; set; } = new();
    }
}