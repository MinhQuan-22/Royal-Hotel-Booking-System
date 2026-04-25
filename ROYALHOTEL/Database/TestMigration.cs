using Microsoft.Data.SqlClient;
using System;
using System.IO;

namespace ROYALHOTEL.Database
{
    /// <summary>
    /// Simple test program to execute SQL migration scripts
    /// Usage: dotnet run --project ROYALHOTEL TestMigration 03_room_rate_change_log.sql
    /// </summary>
    public class TestMigration
    {
        private const string ConnectionString = "Server=localhost,1433;Database=RoyalHotelDb;User Id=sa;Password=SqlServer@123;TrustServerCertificate=True;Encrypt=False;";

        public static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Usage: TestMigration <sql-file-name>");
                Console.WriteLine("Example: TestMigration 03_room_rate_change_log.sql");
                return;
            }

            string sqlFileName = args[0];
            string sqlFilePath = Path.Combine("Database", sqlFileName);

            if (!File.Exists(sqlFilePath))
            {
                Console.WriteLine($"Error: SQL file not found: {sqlFilePath}");
                return;
            }

            try
            {
                Console.WriteLine($"Reading SQL script: {sqlFilePath}");
                string sqlScript = File.ReadAllText(sqlFilePath);

                Console.WriteLine($"Connecting to database...");
                using (var connection = new SqlConnection(ConnectionString))
                {
                    connection.Open();
                    Console.WriteLine("Connected successfully.");

                    // Split by GO statements and execute each batch
                    var batches = sqlScript.Split(new[] { "\nGO\n", "\nGO\r\n", "\r\nGO\r\n", "\r\nGO\n" }, 
                        StringSplitOptions.RemoveEmptyEntries);

                    Console.WriteLine($"Executing {batches.Length} SQL batches...");
                    Console.WriteLine(new string('=', 60));

                    foreach (var batch in batches)
                    {
                        var trimmedBatch = batch.Trim();
                        if (string.IsNullOrWhiteSpace(trimmedBatch))
                            continue;

                        using (var command = new SqlCommand(trimmedBatch, connection))
                        {
                            command.CommandTimeout = 60;
                            
                            using (var reader = command.ExecuteReader())
                            {
                                // Print any result sets (for verification queries)
                                do
                                {
                                    while (reader.Read())
                                    {
                                        for (int i = 0; i < reader.FieldCount; i++)
                                        {
                                            Console.Write($"{reader.GetName(i)}: {reader.GetValue(i)}  ");
                                        }
                                        Console.WriteLine();
                                    }
                                } while (reader.NextResult());
                            }
                        }
                    }

                    Console.WriteLine(new string('=', 60));
                    Console.WriteLine("Migration completed successfully!");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error executing migration: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                Environment.Exit(1);
            }
        }
    }
}
