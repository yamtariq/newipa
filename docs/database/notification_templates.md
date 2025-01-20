DESCRIBE notification_templates;



id	int(11)	NO	PRI	NULL	auto_increment	
title	varchar(255)	YES		NULL		
body	text	YES		NULL		
title_en	varchar(255)	YES		NULL		
body_en	text	YES		NULL		
title_ar	varchar(255)	YES		NULL		
body_ar	text	YES		NULL		
route	varchar(255)	YES		NULL		
additional_data	json	YES		NULL		
target_criteria	json	YES		NULL		
created_at	timestamp	NO		CURRENT_TIMESTAMP		
expiry_at	timestamp	YES		NULL		
status	enum('active','expired','deleted')	NO		'active'
