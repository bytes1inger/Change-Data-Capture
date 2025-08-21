-- Script to create the destination table schema
-- Run this on the destination SQL Server database

-- Create the database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'YourDestinationDatabase')
BEGIN
    CREATE DATABASE YourDestinationDatabase
END
GO

USE [YourDestinationDatabase]
GO

-- Create the destination table
-- Adjust columns as needed to match your source table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[YourDestinationTable]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[YourDestinationTable](
        [id] [int] NOT NULL,
        [name] [nvarchar](100) NULL,
        [description] [nvarchar](max) NULL,
        [created_at] [datetime2](7) NULL,
        [updated_at] [datetime2](7) NULL,
        [source_database] [nvarchar](50) NULL, -- Optional: track source database
        CONSTRAINT [PK_YourDestinationTable] PRIMARY KEY CLUSTERED 
        (
            [id] ASC
        )
    )
END
GO

-- Create a user for the sink connector
USE [master]
GO
CREATE LOGIN sink_user WITH PASSWORD = 'StrongPassword123!'
GO

USE [YourDestinationDatabase]
GO
CREATE USER sink_user FOR LOGIN sink_user
GO
EXEC sp_addrolemember 'db_owner', 'sink_user'
GO
