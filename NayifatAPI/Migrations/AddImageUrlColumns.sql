-- 💡 Add image URL columns to notification_templates table
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[notification_templates]') 
    AND name = 'big_picture_url'
)
BEGIN
    ALTER TABLE [dbo].[notification_templates]
    ADD big_picture_url NVARCHAR(MAX) NULL;
END

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[notification_templates]') 
    AND name = 'large_icon_url'
)
BEGIN
    ALTER TABLE [dbo].[notification_templates]
    ADD large_icon_url NVARCHAR(MAX) NULL;
END

-- Update existing records to have NULL values for new columns
UPDATE [dbo].[notification_templates]
SET big_picture_url = NULL,
    large_icon_url = NULL
WHERE big_picture_url IS NULL
   OR large_icon_url IS NULL; 