<?php
session_start();
require_once '../db_connect.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../login.php");
    exit();
}

$query = "SELECT * FROM master_config ORDER BY page, key_name";
$result = $conn->query($query);

// Group configs by page
$configs = [];
while ($row = $result->fetch_assoc()) {
    if (!isset($configs[$row['page']])) {
        $configs[$row['page']] = [];
    }
    $configs[$row['page']][] = $row;
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>System Configuration</title>
    <link rel="stylesheet" href="../assets/css/style.css">
</head>
<body>
    <div class="dashboard">
        <?php include '../includes/sidebar.php'; ?>
        <div class="main-content">
            <h2>System Configuration</h2>
            <button class="btn btn-primary" onclick="showAddConfigModal()">Add New Config</button>

            <?php foreach ($configs as $page => $pageConfigs): ?>
            <div class="config-section">
                <h3><?php echo ucfirst($page); ?></h3>
                <table class="table">
                    <thead>
                        <tr>
                            <th>Key</th>
                            <th>Value</th>
                            <th>Last Updated</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($pageConfigs as $config): ?>
                        <tr>
                            <td><?php echo $config['key_name']; ?></td>
                            <td><?php echo $config['value']; ?></td>
                            <td><?php echo $config['last_updated']; ?></td>
                            <td>
                                <button class="btn btn-primary" onclick="editConfig(<?php echo $config['config_id']; ?>)">Edit</button>
                                <button class="btn btn-danger" onclick="deleteConfig(<?php echo $config['config_id']; ?>)">Delete</button>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <?php endforeach; ?>
        </div>
    </div>

    <!-- Add Config Modal -->
    <div id="configModal" class="modal">
        <div class="modal-content">
            <h3>Add New Configuration</h3>
            <form id="configForm">
                <div class="form-group">
                    <input type="text" name="page" placeholder="Page Name" required>
                </div>
                <div class="form-group">
                    <input type="text" name="key_name" placeholder="Key Name" required>
                </div>
                <div class="form-group">
                    <input type="text" name="value" placeholder="Value" required>
                </div>
                <button type="submit" class="btn btn-primary">Save</button>
                <button type="button" class="btn btn-danger" onclick="closeModal()">Cancel</button>
            </form>
        </div>
    </div>

    <script src="../assets/js/main.js"></script>
    <script>
        function showAddConfigModal() {
            document.getElementById('configModal').style.display = 'block';
        }

        function closeModal() {
            document.getElementById('configModal').style.display = 'none';
        }

        function editConfig(configId) {
            // Implement edit config functionality
        }

        function deleteConfig(configId) {
            if (confirm('Are you sure you want to delete this configuration?')) {
                fetch('../api/delete-config.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ configId })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        location.reload();
                    }
                });
            }
        }

        document.getElementById('configForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const formData = new FormData(this);
            
            fetch('../api/add-config.php', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    location.reload();
                }
            });
        });
    </script>
</body>
</html>
