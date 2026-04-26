using System;
using Microsoft.Data.SqlClient;

string connectionString = "Server=localhost,1433;Database=RoyalHotelDb;User Id=sa;Password=SqlServer@123;TrustServerCertificate=True;Encrypt=False;";

Console.WriteLine("==========================================");
Console.WriteLine("Schema Verification for Chat Tables");
Console.WriteLine("==========================================");
Console.WriteLine();

try
{
    using (var connection = new SqlConnection(connectionString))
    {
        connection.Open();
        Console.WriteLine("✓ Connected to database");
        Console.WriteLine();
        
        // Verify ChatConversations table
        Console.WriteLine("1. ChatConversations Table Structure:");
        Console.WriteLine(new string('-', 60));
        using (var command = new SqlCommand(@"
            SELECT 
                c.name AS ColumnName,
                t.name AS DataType,
                c.max_length AS MaxLength,
                c.is_nullable AS IsNullable,
                ISNULL(dc.definition, '') AS DefaultValue
            FROM sys.columns c
            INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
            LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
            WHERE c.object_id = OBJECT_ID('ChatConversations')
            ORDER BY c.column_id", connection))
        {
            using (var reader = command.ExecuteReader())
            {
                while (reader.Read())
                {
                    Console.WriteLine($"  {reader["ColumnName"],-20} {reader["DataType"],-15} " +
                                    $"Nullable: {reader["IsNullable"],-5} Default: {reader["DefaultValue"]}");
                }
            }
        }
        Console.WriteLine();
        
        // Verify ChatMessages table
        Console.WriteLine("2. ChatMessages Table Structure:");
        Console.WriteLine(new string('-', 60));
        using (var command = new SqlCommand(@"
            SELECT 
                c.name AS ColumnName,
                t.name AS DataType,
                c.max_length AS MaxLength,
                c.is_nullable AS IsNullable,
                ISNULL(dc.definition, '') AS DefaultValue
            FROM sys.columns c
            INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
            LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
            WHERE c.object_id = OBJECT_ID('ChatMessages')
            ORDER BY c.column_id", connection))
        {
            using (var reader = command.ExecuteReader())
            {
                while (reader.Read())
                {
                    Console.WriteLine($"  {reader["ColumnName"],-25} {reader["DataType"],-15} " +
                                    $"Nullable: {reader["IsNullable"],-5} Default: {reader["DefaultValue"]}");
                }
            }
        }
        Console.WriteLine();
        
        // Verify Foreign Keys
        Console.WriteLine("3. Foreign Key Constraints:");
        Console.WriteLine(new string('-', 60));
        using (var command = new SqlCommand(@"
            SELECT 
                fk.name AS ConstraintName,
                OBJECT_NAME(fk.parent_object_id) AS TableName,
                COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
                OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
                COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
                fk.delete_referential_action_desc AS DeleteAction
            FROM sys.foreign_keys fk
            INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
            WHERE OBJECT_NAME(fk.parent_object_id) IN ('ChatConversations', 'ChatMessages')
            ORDER BY TableName", connection))
        {
            using (var reader = command.ExecuteReader())
            {
                while (reader.Read())
                {
                    Console.WriteLine($"  {reader["ConstraintName"]}");
                    Console.WriteLine($"    {reader["TableName"]}.{reader["ColumnName"]} -> " +
                                    $"{reader["ReferencedTable"]}.{reader["ReferencedColumn"]}");
                    Console.WriteLine($"    ON DELETE {reader["DeleteAction"]}");
                    Console.WriteLine();
                }
            }
        }
        
        // Verify Check Constraints
        Console.WriteLine("4. Check Constraints:");
        Console.WriteLine(new string('-', 60));
        using (var command = new SqlCommand(@"
            SELECT 
                OBJECT_NAME(cc.parent_object_id) AS TableName,
                cc.name AS ConstraintName,
                cc.definition AS Definition
            FROM sys.check_constraints cc
            WHERE OBJECT_NAME(cc.parent_object_id) IN ('ChatConversations', 'ChatMessages')
            ORDER BY TableName, ConstraintName", connection))
        {
            using (var reader = command.ExecuteReader())
            {
                while (reader.Read())
                {
                    Console.WriteLine($"  {reader["TableName"]}.{reader["ConstraintName"]}");
                    Console.WriteLine($"    {reader["Definition"]}");
                    Console.WriteLine();
                }
            }
        }
        
        // Verify Indexes
        Console.WriteLine("5. Indexes:");
        Console.WriteLine(new string('-', 60));
        using (var command = new SqlCommand(@"
            SELECT 
                OBJECT_NAME(i.object_id) AS TableName,
                i.name AS IndexName,
                i.type_desc AS IndexType,
                STRING_AGG(COL_NAME(ic.object_id, ic.column_id), ', ') AS Columns
            FROM sys.indexes i
            INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
            WHERE OBJECT_NAME(i.object_id) IN ('ChatConversations', 'ChatMessages')
            AND i.name IS NOT NULL
            GROUP BY OBJECT_NAME(i.object_id), i.name, i.type_desc
            ORDER BY TableName, IndexName", connection))
        {
            using (var reader = command.ExecuteReader())
            {
                while (reader.Read())
                {
                    Console.WriteLine($"  {reader["TableName"]}.{reader["IndexName"]}");
                    Console.WriteLine($"    Type: {reader["IndexType"]}");
                    Console.WriteLine($"    Columns: {reader["Columns"]}");
                    Console.WriteLine();
                }
            }
        }
        
        Console.WriteLine("==========================================");
        Console.WriteLine("✓ Schema verification completed!");
        Console.WriteLine("==========================================");
    }
}
catch (Exception ex)
{
    Console.WriteLine();
    Console.WriteLine("✗ Error during verification:");
    Console.WriteLine($"  {ex.Message}");
    Environment.Exit(1);
}
