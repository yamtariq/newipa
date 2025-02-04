# Nayifat App Production Deployment Requirements

## 1. ASP.NET Core API Requirements
- .NET 8.0 Runtime
- Microsoft SQL Server 2022 (or latest stable version)
- SSL Certificate for HTTPS
- IIS Web Server (latest version)

## 2. Database Requirements
### Database Name: NayifatApp
### Required Tables:
- Customers
- CustomerDevices
- UserNotifications
- AuthLogs
- OtpCodes
- MasterConfigs
- ApiKeys
- YakeenCitizenInfos
- YakeenCitizenAddresses
- CitizenAddressListItems
- NotificationTemplates
- LoanApplications
- CardApplications

## 3. Server Configuration
### Minimum Specifications:
- CPU: 4 cores
- RAM: 8GB minimum, 16GB recommended
- Storage: 100GB SSD minimum

### Network Requirements:
- Port 443 (HTTPS)
- Port 1433 (SQL Server)
- Static IP address
- Firewall rules to allow Flutter app connections
- Outbound connections for third-party services (Yakeen, Nafath)

## 4. Environment Configuration
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=SERVER_NAME;Database=NayifatApp;User Id=DB_USER;Password=DB_PASSWORD;TrustServerCertificate=True;MultipleActiveResultSets=true"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
```

## 5. Security Requirements
- SSL/TLS certificate for API domain
- API Key authentication system
- SQL Server account with appropriate permissions
- Regular backup schedule for database
- Web Application Firewall (WAF) recommended

## 6. Flutter App Configuration Updates
### Required Changes:
- Update `apiBaseUrl` in `constants.dart` to point to production API URL
- Update API key for production environment

### Configure Production Endpoints:
- Authentication services
- Card services
- Loan services
- Notification services
- Government integration services (Yakeen, Nafath)

## 7. Monitoring Requirements
- Application logging system
- Database monitoring
- Server resource monitoring
- API endpoint monitoring
- Error tracking system

## 8. Backup Requirements
- Daily database backups
- Transaction log backups
- Backup retention policy
- Disaster recovery plan

## 9. External Services Integration
- Yakeen service access
- Nafath service access
- SMS gateway for OTP
- Push notification service
- Email service (if applicable)

## 10. Deployment Checklist
- [ ] Database migration scripts
- [ ] Initial seed data (if any)
- [ ] SSL certificate installation
- [ ] IIS configuration
- [ ] Firewall rules setup
- [ ] API key generation
- [ ] Backup job setup
- [ ] Monitoring tools setup

## 11. Required Documentation
- API endpoints documentation
- Database schema
- Network architecture diagram
- Backup and recovery procedures
- Monitoring and alerting procedures
- Emergency contact information

## Contact Information
Please provide the following contact information for the deployment team:
- Technical Lead:
- Database Administrator:
- Network Administrator:
- Security Team Lead:
- Operations Manager:

## Notes
- All passwords and sensitive credentials should be provided through a secure channel
- A staging environment with similar configuration is recommended for testing
- Regular security audits should be scheduled
- System updates and maintenance windows should be defined
- Performance monitoring thresholds should be established
