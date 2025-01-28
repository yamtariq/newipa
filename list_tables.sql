-- List all tables in the database
SELECT TABLE_NAME 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'icredept_nayifat_app'
ORDER BY TABLE_NAME;