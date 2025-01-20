<!DOCTYPE html>
<html>
<head>
    <title>404 - Page Not Found</title>
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
            color: var(--primary-color);
            margin: 0;
        }
    </style>
</head>
<body>
    <div class="error-page">
        <div class="error-content">
            <h1 class="error-code">404</h1>
            <h2>Page Not Found</h2>
            <p>The page you are looking for might have been removed or is temporarily unavailable.</p>
            <a href="index.php" class="btn btn-primary">Go to Homepage</a>
        </div>
    </div>
</body>
</html>
