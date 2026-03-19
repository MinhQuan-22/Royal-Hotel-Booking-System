using System.ComponentModel.DataAnnotations;

namespace ROYALHOTEL.ViewModels
{
    public class AdminAmenityFormViewModel
    {
        public int Id { get; set; }

        [Required]
        [StringLength(80)]
        public string AmenityKey { get; set; } = string.Empty;

        [Required]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;

        [StringLength(120)]
        public string? IconClass { get; set; }

        [StringLength(80)]
        public string? Category { get; set; }
    }
}