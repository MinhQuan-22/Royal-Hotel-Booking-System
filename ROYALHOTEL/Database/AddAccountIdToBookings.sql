-- Migration: Add AccountId to Bookings table
-- Date: 2026-03-10

-- Step 1: Add AccountId column (nullable)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Bookings]') AND name = 'AccountId')
BEGIN
    ALTER TABLE [dbo].[Bookings]
    ADD [AccountId] INT NULL;
END
GO

-- Step 2: Add Foreign Key constraint
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Bookings_Accounts_AccountId')
BEGIN
    ALTER TABLE [dbo].[Bookings]
    ADD CONSTRAINT [FK_Bookings_Accounts_AccountId] 
    FOREIGN KEY ([AccountId]) 
    REFERENCES [dbo].[Accounts]([Id])
    ON DELETE SET NULL;
END
GO

-- Step 3: Create index for better query performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Bookings_AccountId' AND object_id = OBJECT_ID(N'[dbo].[Bookings]'))
BEGIN
    CREATE INDEX [IX_Bookings_AccountId] ON [dbo].[Bookings]([AccountId]);
END
GO

PRINT 'Migration completed: AccountId added to Bookings table';
