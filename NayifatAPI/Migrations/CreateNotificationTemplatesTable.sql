-- 💡 Create notification_templates table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[notification_templates]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[notification_templates] (
        [id] INT IDENTITY(1,1) PRIMARY KEY,
        [title] NVARCHAR(200) NULL,
        [body] NVARCHAR(1000) NULL,
        [title_en] NVARCHAR(200) NULL,
        [body_en] NVARCHAR(1000) NULL,
        [title_ar] NVARCHAR(200) NULL,
        [body_ar] NVARCHAR(1000) NULL,
        [route] NVARCHAR(100) NULL,
        [additional_data] NVARCHAR(MAX) NULL,
        [target_criteria] NVARCHAR(MAX) NULL,
        [created_at] DATETIME2 DEFAULT GETDATE(),
        [expiry_at] DATETIME2 NULL,
        [big_picture_url] NVARCHAR(MAX) NULL,
        [large_icon_url] NVARCHAR(MAX) NULL
    );

    -- Create index on expiry_at for performance
    CREATE INDEX [IX_notification_templates_expiry] ON [dbo].[notification_templates] ([expiry_at]);
END
ELSE
BEGIN
    -- Add image URL columns if they don't exist
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[notification_templates]') AND name = 'big_picture_url')
    BEGIN
        ALTER TABLE [dbo].[notification_templates]
        ADD [big_picture_url] NVARCHAR(MAX) NULL;
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[notification_templates]') AND name = 'large_icon_url')
    BEGIN
        ALTER TABLE [dbo].[notification_templates]
        ADD [large_icon_url] NVARCHAR(MAX) NULL;
    END
END 