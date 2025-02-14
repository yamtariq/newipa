# Proxy Service Documentation

## Overview
The proxy service acts as an intermediary between the client application and internal services. It provides a secure way to route requests while handling authentication and internal service communication.

## Authentication
All requests to the proxy require an API key for authentication:
```
x-api-key: 7ca7427b418bdbd0b3b23d7debf69bf7
```

## Request Format

### Endpoint
```
POST /api/Proxy/forward
```

### Request Body Structure
```json
{
    "TargetUrl": "https://172.22.226.190/api/endpoint",
    "Method": "POST",                           // Optional, defaults to POST
    "InternalHeaders": {
        // Your actual internal headers here
    },
    "Body": {
        // Your actual request body here
    }
}
```

### Fields Description
- `TargetUrl`: (Required) The internal endpoint URL to forward the request to
- `Method`: (Optional) HTTP method for the internal request (GET, POST, PUT, DELETE, etc.)
- `InternalHeaders`: (Optional) Headers to be sent to the internal service
- `Body`: (Required) The actual request payload

## Examples

### Basic POST Request
```http
POST /api/Proxy/forward
Headers:
    x-api-key: 7ca7427b418bdbd0b3b23d7debf69bf7
Body:
{
    "TargetUrl": "https://172.22.226.190/api/users",
    "Body": {
        "UserId": "123",
        "Name": "John Doe"
    }
}
```

### Request with Custom Method and Headers
```http
POST /api/Proxy/forward
Headers:
    x-api-key: 7ca7427b418bdbd0b3b23d7debf69bf7
Body:
{
    "TargetUrl": "https://172.22.226.190/api/documents",
    "Method": "PUT",
    "InternalHeaders": {
        "Internal-Auth": "token123",
        "Custom-Header": "value"
    },
    "Body": {
        "DocumentId": "doc123",
        "Status": "approved"
    }
}
```

## Response Handling
The proxy forwards the exact response from the internal service, including:
- Status code
- Headers (except 'Host')
- Response body

### Success Response Example
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
    "status": "success",
    "data": {
        "id": "123",
        "result": "processed"
    }
}
```

### Error Response Example
```http
HTTP/1.1 404 Not Found
Content-Type: application/json

{
    "error": "Resource not found",
    "code": "404"
}
```

## Security Considerations

### Allowed Hosts
The proxy only forwards requests to approved internal IP addresses:
- 172.22.226.190
- 172.22.226.203

### SSL/TLS
- The proxy handles SSL certificate validation for internal services
- Client-to-proxy communication must use HTTPS
- Proxy-to-internal service communication has SSL verification disabled for internal certificates

## Error Handling

### Common Error Scenarios
1. Invalid API Key
```json
{
    "success": false,
    "message": "Invalid API key"
}
```

2. Unauthorized Target URL
```json
{
    "success": false,
    "message": "Unauthorized target URL"
}
```

3. Internal Service Connection Error
```json
{
    "success": false,
    "message": "Unable to connect to internal service"
}
```

## Limitations
- Request timeout: 30 seconds
- Response caching: 5 minutes
- Only approved internal IPs are accessible
- Binary file transfers are supported
- Streaming responses are supported

## Best Practices
1. Always include the required API key
2. Use HTTPS for all communications
3. Include appropriate content-type headers
4. Handle timeouts appropriately in client applications
5. Implement proper error handling for all possible response codes 