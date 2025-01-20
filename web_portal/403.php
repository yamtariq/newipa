<!DOCTYPE html>
<html>
<head>
    <title>403 - Forbidden</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        .error-page {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            text-align: center;
        }
        .error-content {
            padding: 2rem;
            background: white;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .error-code {
            font-size: 6rem;
            color: var(--danger-color);
            margin: 0;
        }
    </style>
</head>
<body>
    <div class="error-page">
        <div class="error-content">
            <h1 class="error-code">403</h1>
            <h2>Access Forbidden</h2>
            <p>You don't have permission to access this resource.</p>
            <a href="index.php" class="btn btn-primary">Go to Homepage</a>
        </div>
    </div>
</body>
</html>
