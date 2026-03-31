namespace ROYALHOTEL.Commands.Common
{
    // class to represent the result of an admin command
    public class AdminCommandResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;

        public static AdminCommandResult Ok(string message = "")
        {
            return new AdminCommandResult
            {
                Success = true,
                Message = message
            };
        }

        public static AdminCommandResult Fail(string message)
        {
            return new AdminCommandResult
            {
                Success = false,
                Message = message
            };
        }
    }
}