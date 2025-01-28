-- Add compression support to AuditTrail table
ALTER TABLE AuditTrail
ADD COLUMN is_compressed BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN user_agent VARCHAR(255) NULL,
MODIFY COLUMN details MEDIUMTEXT NULL;

-- Add index for better query performance
CREATE INDEX idx_audit_compressed ON AuditTrail(is_compressed);

-- Add comment explaining the compression
ALTER TABLE AuditTrail
COMMENT = 'Audit trail with compression support. When is_compressed is true, the details column contains base64-encoded GZip compressed data.'; 