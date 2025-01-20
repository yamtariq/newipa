DESCRIBE user_notifications;

national_id	varchar(20)	NO	PRI	NULL		
notifications	json	YES		NULL		
last_updated	timestamp	NO		CURRENT_TIMESTAMP	on update CURRENT_TIMESTAMP
