-- Script to enable CDC on SQL Server database and tables
-- Run this on the source SQL Server database

-- Step 1: Enable CDC on the database
USE [YourDatabase]
GO
EXEC sys.sp_cdc_enable_db
GO

-- Step 2: Verify CDC is enabled on the database
SELECT name, is_cdc_enabled 
FROM sys.databases 
WHERE name = 'YourDatabase'
GO

-- Step 3: Enable CDC on the specific table(s)
EXEC sys.sp_cdc_enable_table
@source_schema = 'dbo',
@source_name = 'YourTable',
@role_name = NULL,
@supports_net_changes = 1
GO

-- Step 4: Verify CDC is enabled on the table
SELECT name, is_tracked_by_cdc 
FROM sys.tables 
WHERE name = 'YourTable'
GO

-- Step 5: Create a user for Debezium with appropriate permissions
-- First create login
USE [master]
GO
CREATE LOGIN debezium WITH PASSWORD = 'StrongPassword123!'
GO

-- Then create user and assign permissions
USE [YourDatabase]
GO
CREATE USER debezium FOR LOGIN debezium
GO
EXEC sp_addrolemember 'db_owner', 'debezium'
GO

-- Step 6: Verify SQL Server Agent is running (required for CDC)
-- In SQL Server Management Studio, check if SQL Server Agent is running
-- Or use this query to check the status
EXEC xp_servicecontrol 'QueryState', 'SQLServerAGENT'
GO
