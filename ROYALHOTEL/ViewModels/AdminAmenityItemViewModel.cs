namespace ROYALHOTEL.ViewModels
{
    public class AdminAmenityItemViewModel
    {
        public int Id { get; set; }
        public string AmenityKey { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? IconClass { get; set; }
        public string? Category { get; set; }
    }
}