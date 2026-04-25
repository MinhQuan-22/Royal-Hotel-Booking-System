// =============================================
// ExecuteSqlScript.cs
// Simple utility to execute SQL scripts against the database
// =============================================
// Usage: dotnet run --project ROYALHOTEL ExecuteSqlScript.cs <script-path>
// =============================================

using System;
using System.IO;
using Microsoft.Data.SqlClient;

class ExecuteSqlScript
{
    static void Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.WriteLine("Usage: dotnet run ExecuteSqlScript.cs <script-path>");
            return;
        }

        string scriptPath = args[0];
        string connectionString = "Server=localhost,1433;Database=RoyalHotelDb;User Id=sa;Password=SqlServer@123;TrustServerCertificate=True;Encrypt=False;";

        try
        {
            string sqlScript = File.ReadAllText(scriptPath);
            
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                Console.WriteLine("Connected to database successfully.");
                
                // Split by GO statements
                string[] batches = sqlScript.Split(new[] { "\nGO\n", "\nGO\r\n", "\r\nGO\r\n", "\r\nGO\n" }, 
                    StringSplitOptions.RemoveEmptyEntries);
                
                foreach (var batch in batches)
                {
                    if (string.IsNullOrWhiteSpace(batch))
                        continue;
                        
                    using (var command = new SqlCommand(batch, connection))
                    {
                        command.ExecuteNonQuery();
                    }
                }
                
                Console.WriteLine($"Script executed successfully: {scriptPath}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error executing script: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
        }
    }
}
