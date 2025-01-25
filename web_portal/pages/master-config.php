<?php
session_start();
if (!isset($_SESSION['user_id'])) {
    header("Location: ../login.php");
    exit();
}

require_once '../db_connect.php';
?>
<!DOCTYPE html>
<html>
<head>
    <title>Master Config - Nayifat Admin Dashboard</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link rel="stylesheet" href="../assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@11.7.32/dist/sweetalert2.min.css">
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11.7.32/dist/sweetalert2.all.min.js"></script>
    <style>
        :root {
            --primary-color: #0A71A3;
            --secondary-color: #0986c3;
            --accent-color: #40a7d9;
            --hover-bg: #e6f3f8;
            --text-color: #1e293b;
            --sidebar-width: 280px;
            --sidebar-width-collapsed: 80px;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Inter', 'Segoe UI', sans-serif;
        }

        body {
            display: flex;
            min-height: 100vh;
            background-color: #f8f9fa;
        }

        .sidebar {
            width: var(--sidebar-width);
            background: white;
            color: #64748b;
            padding: 1.5rem 1rem;
            transition: all 0.3s ease;
            height: 100vh;
            position: fixed;
            left: 0;
            top: 0;
            z-index: 1000;
            box-shadow: 4px 0 10px rgba(0, 0, 0, 0.05);
            overflow-y: auto;
        }

        .sidebar.collapsed {
            width: var(--sidebar-width-collapsed);
        }

        .logo-container {
            text-align: center;
            padding: 1rem 0;
            margin-bottom: 2rem;
            border-bottom: 1px solid #e2e8f0;
            white-space: nowrap;
            overflow: hidden;
        }

        .logo-container h2 {
            color: var(--primary-color);
            font-size: 1.5rem;
            font-weight: 700;
            transition: all 0.3s ease;
            margin-bottom: 0.5rem;
        }

        .logo-container h2 .full-name {
            transition: opacity 0.3s ease;
        }

        .sidebar.collapsed .logo-container h2 .full-name {
            display: none;
        }

        .logo-container h2 .letter {
            display: inline-block;
        }

        .sidebar.collapsed .logo-container {
            padding: 1rem 0;
        }

        .sidebar.collapsed .logo-container h2 {
            opacity: 1;
            width: auto;
            margin: 0;
            font-size: 1.75rem;
        }

        .user-info {
            font-size: 0.875rem;
            color: #64748b;
            transition: opacity 0.3s ease;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .user-name {
            font-weight: 600;
            color: var(--text-color);
            margin-bottom: 0.25rem;
        }

        .user-role {
            font-size: 0.75rem;
            color: #64748b;
        }

        .sidebar.collapsed .user-info {
            opacity: 0;
            height: 0;
            margin: 0;
        }

        .nav-link {
            display: flex;
            align-items: center;
            color: #64748b;
            text-decoration: none;
            padding: 0.875rem 1rem;
            margin-bottom: 0.5rem;
            border-radius: 0.5rem;
            transition: all 0.2s ease;
            white-space: nowrap;
            overflow: hidden;
        }

        .nav-link i {
            min-width: 1.5rem;
            margin-right: 1rem;
            font-size: 1.25rem;
            text-align: center;
            transition: margin 0.3s ease;
        }

        .nav-link span {
            opacity: 1;
            transition: opacity 0.3s ease;
        }

        .sidebar.collapsed .nav-link span {
            opacity: 0;
            width: 0;
            display: none;
        }

        .nav-link:hover, .nav-link.active {
            color: var(--primary-color);
            background: var(--hover-bg);
        }

        .toggle-sidebar {
            position: fixed;
            bottom: 2rem;
            left: 1.25rem;
            background: var(--primary-color);
            color: white;
            width: 2.5rem;
            height: 2.5rem;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            border: none;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            transition: all 0.2s ease;
            z-index: 1001;
        }

        .toggle-sidebar:hover {
            background: var(--secondary-color);
            transform: scale(1.05);
        }

        .main-content {
            margin-left: var(--sidebar-width);
            padding: 2rem;
            width: calc(100% - var(--sidebar-width));
            transition: all 0.3s ease;
        }

        .sidebar.collapsed ~ .main-content {
            margin-left: var(--sidebar-width-collapsed);
            width: calc(100% - var(--sidebar-width-collapsed));
        }

        .page-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding: 20px;
        }

        .page-title {
            color: var(--primary-color);
            font-size: 24px;
            font-weight: 600;
        }

        .logout-btn {
            background: white;
            color: #dc3545;
            border: 2px solid #dc3545;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
            text-decoration: none;
        }

        .logout-btn:hover {
            background: #fde8ea;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }

        .logout-btn i {
            font-size: 16px;
            color: #dc3545;
        }

        .section-header {
            color: var(--primary-color);
            font-size: 18px;
            font-weight: 600;
            padding: 1rem 0;
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }

        .section-header i {
            margin-left: 8px;
            transition: transform 0.3s ease;
        }

        .section-header:hover {
            color: #085785;
        }

        .section-content {
            padding: 1rem 0;
            border-radius: 8px;
            margin-bottom: 1.5rem;
        }

        .section-content.collapsed {
            display: none;
        }

        .slide-container {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            position: relative;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .slide {
            position: relative;
            padding: 20px;
            padding-top: 35px;
            background: #f8f9fa;
            border-radius: 8px;
            margin-bottom: 15px;
        }

        .slide-number {
            position: absolute;
            top: 10px;
            left: 10px;
            background: var(--primary-color);
            color: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 14px;
            font-weight: 500;
        }

        .delete-slide {
            position: absolute;
            top: 10px;
            right: 10px;
            padding: 2px 8px;
            background-color: #dc3545;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background-color 0.3s;
        }

        .delete-slide:hover {
            background-color: #c82333;
        }

        .form-group {
            margin-top: 35px;
            margin-bottom: 15px;
        }

        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 500;
            color: var(--text-color);
        }

        .form-group input {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }

        .form-group input:focus {
            border-color: var(--primary-color);
            outline: none;
            box-shadow: 0 0 0 2px rgba(10, 113, 163, 0.1);
        }

        h4 {
            color: #2c3e50;
            margin-bottom: 20px;
            font-size: 18px;
        }

        .swal2-popup {
            width: 600px;
            padding: 2em;
        }

        .swal2-popup .form-group {
            margin-bottom: 1.5em;
            text-align: left;
        }

        .swal2-popup .form-group label {
            display: block;
            margin-bottom: 0.5em;
            color: #1a4f7a;
            font-weight: 500;
        }

        .swal2-popup .swal2-input {
            width: 100%;
            height: 40px;
            margin: 0;
            padding: 0.5em 1em;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }

        .swal2-popup .swal2-input:focus {
            border-color: #1a4f7a;
            box-shadow: 0 0 0 2px rgba(26, 79, 122, 0.2);
        }

        .swal2-popup .swal2-actions {
            margin-top: 2em;
        }

        .swal2-popup .swal2-confirm {
            background: #1a4f7a !important;
        }

        .swal2-popup .swal2-cancel {
            background: #6c757d !important;
        }

        .top-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px 30px;
            background: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            border-radius: 12px;
            margin-bottom: 30px;
        }

        .header-buttons {
            display: flex;
            gap: 1rem;
            align-items: center;
        }

        .btn-danger {
            background: white;
            color: #dc3545;
            border: 2px solid #dc3545;
            padding: 10px 20px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
            text-decoration: none;
        }

        .btn-danger:hover {
            background: #fde8ea;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }

        .btn-danger i {
            font-size: 16px;
            color: #dc3545;
        }

        .slideshow-container {
            display: flex;
            gap: 20px;
            margin-bottom: 30px;
        }

        .slideshow-column {
            flex: 1;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .slideshow-column h3 {
            margin-top: 0;
            margin-bottom: 20px;
            color: var(--primary-color);
            font-size: 18px;
            font-weight: 600;
        }

        .slide-pair {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }

        .slide-pair .form-group {
            flex: 1;
        }

        .combined-save-btn {
            display: block;
            width: 200px;
            margin: 20px auto;
            padding: 12px 24px;
            background: var(--primary-color);
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 500;
            transition: background 0.3s ease;
        }

        .combined-save-btn:hover {
            background: var(--secondary-color);
        }

        .add-slide {
            background-color: #28a745;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin-bottom: 20px;
            transition: background-color 0.3s;
        }

        .add-slide:hover {
            background-color: #218838;
        }

        .save-changes {
            background-color: #007bff;
            color: white;
            padding: 10px 25px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            transition: background-color 0.3s;
            font-size: 16px;
        }

        .save-changes:hover {
            background-color: #0056b3;
        }

        .image-upload-container {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 10px;
        }
        .upload-btn {
            padding: 5px 10px;
            background-color: var(--primary-color);
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
        }
        .upload-btn:hover {
            background-color: var(--secondary-color);
        }
        .upload-status {
            font-size: 12px;
            margin-left: 10px;
        }
        .upload-progress {
            display: none;
            margin-left: 10px;
        }
    </style>
</head>
<body>
    <div class="sidebar" id="sidebar">
        <div class="logo-container">
            <h2><span class="letter">N</span><span class="full-name">ayifat</span></h2>
            <div class="user-info">
                <div class="user-name"><?php echo $_SESSION['name']; ?></div>
                <div class="user-role"><?php echo ucfirst($_SESSION['role']); ?></div>
            </div>
        </div>
        <nav>
            <a href="../index.php" class="nav-link">
                <i class="fas fa-home"></i>
                <span>Dashboard</span>
            </a>
            <a href="loan-applications.php" class="nav-link">
                <i class="fas fa-file-alt"></i>
                <span>Loan Applications</span>
            </a>
            <a href="card-applications.php" class="nav-link">
                <i class="fas fa-credit-card"></i>
                <span>Card Applications</span>
            </a>
            <a href="users.php" class="nav-link">
                <i class="fas fa-users"></i>
                <span>Users</span>
            </a>
            <a href="master-config.php" class="nav-link active">
                <i class="fas fa-cogs"></i>
                <span>Master Config</span>
            </a>
            <a href="push-notification.php" class="nav-link">
                <i class="fas fa-bell"></i>
                <span>Push Notifications</span>
            </a>
        </nav>
    </div>

    <button class="toggle-sidebar" id="toggleSidebar">
        <i class="fas fa-bars"></i>
    </button>

    <div class="main-content">
        <div class="top-bar">
            <h1 class="page-title">Master Configuration</h1>
            <div class="header-buttons">
                <a href="../logout.php" class="btn-danger">
                    <i class="fas fa-sign-out-alt"></i>
                    Logout
                </a>
            </div>
        </div>

        <div style="padding: 0 20px;">
            <h3 class="section-header" onclick="toggleSection('slideshow')">
                Home Page Slideshow Configuration
                <i class="fas fa-chevron-down"></i>
            </h3>

            <div id="slideshow-section" class="section-content collapsed">
                <div class="slideshow-container">
                    <div class="slideshow-column">
                        <h3>Home Page Slideshow Configuration (English)</h3>
                        <div id="slides-container">
                            <?php
                            try {
                                $sql = "SELECT * FROM master_config WHERE page = 'home' AND key_name = 'slideshow_content'";
                                $result = $conn->query($sql);
                                
                                if ($result->num_rows > 0) {
                                    $row = $result->fetch_assoc();
                                    $configData = $row['value'];
                                    $configData = str_replace('\\"', '"', $configData);
                                    $configData = str_replace('\n', '', $configData);
                                    $slides = json_decode($configData, true);
                                    
                                    if (json_last_error() === JSON_ERROR_NONE) {
                                        foreach ($slides as $index => $slide) {
                                            echo '<div class="slide" id="slide-' . $index . '">';
                                            echo '<div class="slide-number">Slide ' . ($index + 1) . '</div>';
                                            echo '<div class="form-group">';
                                            echo '<label>Image URL:</label>';
                                            echo '<input type="text" id="image_url_' . $index . '" name="image_url[]" value="' . htmlspecialchars($slide['image_url']) . '" required>';
                                            echo '</div>';
                                            echo '<div class="form-group">';
                                            echo '<label>Link:</label>';
                                            echo '<input type="text" name="link[]" value="' . htmlspecialchars($slide['link']) . '" required>';
                                            echo '</div>';
                                            echo '<div class="form-group">';
                                            echo '<label>Left Title:</label>';
                                            echo '<input type="text" name="leftTitle[]" value="' . htmlspecialchars($slide['leftTitle']) . '" required>';
                                            echo '</div>';
                                            echo '<div class="form-group">';
                                            echo '<label>Right Title:</label>';
                                            echo '<input type="text" name="rightTitle[]" value="' . htmlspecialchars($slide['rightTitle']) . '" required>';
                                            echo '</div>';
                                            echo '<button type="button" class="delete-slide" onclick="deleteSlide(' . $index . ')">';
                                            echo '<i class="fas fa-trash"></i> Delete Slide';
                                            echo '</button>';
                                            echo '</div>';
                                        }
                                    }
                                }
                            } catch (Exception $e) {
                                echo "Error: " . $e->getMessage();
                            }
                            ?>
                        </div>
                        <button type="button" class="add-slide" onclick="addNewSlide()">
                            <i class="fas fa-plus"></i> Add New Slide
                        </button>
                    </div>

                    <div class="slideshow-column">
                        <h3>Home Page Slideshow Configuration (Arabic)</h3>
                        <div id="slides-container-ar">
                            <?php
                            try {
                                $sql = "SELECT * FROM master_config WHERE page = 'home' AND key_name = 'slideshow_content_ar'";
                                $result = $conn->query($sql);
                                
                                if ($result->num_rows > 0) {
                                    $row = $result->fetch_assoc();
                                    $configData = $row['value'];
                                    $configData = str_replace('\\"', '"', $configData);
                                    $configData = str_replace('\n', '', $configData);
                                    $slides = json_decode($configData, true);
                                    
                                    if (json_last_error() === JSON_ERROR_NONE) {
                                        foreach ($slides as $index => $slide) {
                                            echo '<div class="slide" id="slide-ar-' . $index . '">';
                                            echo '<div class="slide-number">Slide ' . ($index + 1) . '</div>';
                                            echo '<div class="form-group">';
                                            echo '<label>Image URL:</label>';
                                            echo '<input type="text" id="image_url_ar_' . $index . '" name="image_url_ar[]" value="' . htmlspecialchars($slide['image_url']) . '" required>';
                                            echo '</div>';
                                            echo '<div class="form-group">';
                                            echo '<label>Link:</label>';
                                            echo '<input type="text" name="link_ar[]" value="' . htmlspecialchars($slide['link']) . '" required>';
                                            echo '</div>';
                                            echo '<div class="form-group">';
                                            echo '<label>Left Title:</label>';
                                            echo '<input type="text" name="leftTitle_ar[]" value="' . htmlspecialchars($slide['leftTitle']) . '" required>';
                                            echo '</div>';
                                            echo '<div class="form-group">';
                                            echo '<label>Right Title:</label>';
                                            echo '<input type="text" name="rightTitle_ar[]" value="' . htmlspecialchars($slide['rightTitle']) . '" required>';
                                            echo '</div>';
                                            echo '<button type="button" class="delete-slide" onclick="deleteSlideAr(' . $index . ')">';
                                            echo '<i class="fas fa-trash"></i> Delete Slide';
                                            echo '</button>';
                                            echo '</div>';
                                        }
                                    }
                                }
                            } catch (Exception $e) {
                                echo "Error: " . $e->getMessage();
                            }
                            ?>
                        </div>
                        <button type="button" class="add-slide" onclick="addNewSlideAr()">
                            <i class="fas fa-plus"></i> Add New Slide
                        </button>
                    </div>
                </div>

                <button type="button" class="combined-save-btn" onclick="saveBothConfigs()">
                    <i class="fas fa-save"></i> Save All Changes
                </button>

                <script>
                    let slideCount = 0;
                    let slideCountAr = 0;

                    function addNewSlide() {
                        Swal.fire({
                            title: 'Add New Slide',
                            html: `
                                <div class="form-group">
                                    <label>Image URL:</label>
                                    <input type="text" id="new_image_url" class="swal2-input" placeholder="Enter image URL">
                                    <div class="image-upload-container">
                                        <input type="file" id="new_image_file" accept="image/*" style="display: none;">
                                        <button type="button" class="upload-btn" onclick="document.getElementById('new_image_file').click()">
                                            <i class="fas fa-upload"></i> Upload
                                        </button>
                                        <span class="upload-status"></span>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label>Link:</label>
                                    <input type="text" id="new_link" class="swal2-input" placeholder="Enter link">
                                </div>
                                <div class="form-group">
                                    <label>Left Title:</label>
                                    <input type="text" id="new_left_title" class="swal2-input" placeholder="Enter left title">
                                </div>
                                <div class="form-group">
                                    <label>Right Title:</label>
                                    <input type="text" id="new_right_title" class="swal2-input" placeholder="Enter right title">
                                </div>
                            `,
                            focusConfirm: false,
                            didOpen: () => {
                                const fileInput = document.getElementById('new_image_file');
                                const urlInput = document.getElementById('new_image_url');
                                const statusSpan = document.querySelector('.upload-status');
                                const uploadBtn = document.querySelector('.upload-btn');

                                fileInput.addEventListener('change', async (e) => {
                                    if (!e.target.files.length) return;
                                    
                                    const file = e.target.files[0];
                                    const formData = new FormData();
                                    formData.append('image', file);
                                    
                                    statusSpan.textContent = 'Uploading...';
                                    uploadBtn.disabled = true;
                                    
                                    try {
                                        const response = await fetch('../upload_handler.php', {
                                            method: 'POST',
                                            body: formData
                                        });
                                        
                                        const result = await response.json();
                                        
                                        if (result.success) {
                                            urlInput.value = result.url;
                                            statusSpan.textContent = 'Upload successful!';
                                            statusSpan.style.color = 'green';
                                        } else {
                                            throw new Error(result.message);
                                        }
                                    } catch (error) {
                                        statusSpan.textContent = `Error: ${error.message}`;
                                        statusSpan.style.color = 'red';
                                        console.error('Upload error:', error);
                                    } finally {
                                        uploadBtn.disabled = false;
                                        fileInput.value = '';
                                    }
                                });
                            },
                            preConfirm: () => {
                                return {
                                    image_url: document.getElementById('new_image_url').value,
                                    link: document.getElementById('new_link').value,
                                    leftTitle: document.getElementById('new_left_title').value,
                                    rightTitle: document.getElementById('new_right_title').value
                                }
                            }
                        }).then((result) => {
                            if (result.isConfirmed) {
                                const newSlideIndex = slideCount++;
                                const newSlide = document.createElement('div');
                                newSlide.className = 'slide';
                                newSlide.id = `slide-${newSlideIndex}`;
                                newSlide.innerHTML = `
                                    <div class="slide-number">Slide ${newSlideIndex + 1}</div>
                                    <button type="button" class="delete-slide" onclick="deleteSlide(${newSlideIndex})">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                    <div class="form-group">
                                        <label>Image URL:</label>
                                        <input type="text" id="image_url_${newSlideIndex}" name="image_url[]" value="${result.value.image_url}" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Link:</label>
                                        <input type="text" name="link[]" value="${result.value.link}" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Left Title:</label>
                                        <input type="text" name="leftTitle[]" value="${result.value.leftTitle}" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Right Title:</label>
                                        <input type="text" name="rightTitle[]" value="${result.value.rightTitle}" required>
                                    </div>
                                `;
                                document.getElementById('slides-container').appendChild(newSlide);
                                createImageUploader(`image_url_${newSlideIndex}`);
                            }
                        });
                    }

                    function addNewSlideAr() {
                        Swal.fire({
                            title: 'Add New Slide (Arabic)',
                            html: `
                                <div class="form-group">
                                    <label>Image URL:</label>
                                    <input type="text" id="new_image_url_ar" class="swal2-input" placeholder="Enter image URL">
                                    <div class="image-upload-container">
                                        <input type="file" id="new_image_file_ar" accept="image/*" style="display: none;">
                                        <button type="button" class="upload-btn" onclick="document.getElementById('new_image_file_ar').click()">
                                            <i class="fas fa-upload"></i> Upload
                                        </button>
                                        <span class="upload-status"></span>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label>Link:</label>
                                    <input type="text" id="new_link_ar" class="swal2-input" placeholder="Enter link">
                                </div>
                                <div class="form-group">
                                    <label>Left Title:</label>
                                    <input type="text" id="new_left_title_ar" class="swal2-input" placeholder="Enter left title">
                                </div>
                                <div class="form-group">
                                    <label>Right Title:</label>
                                    <input type="text" id="new_right_title_ar" class="swal2-input" placeholder="Enter right title">
                                </div>
                            `,
                            focusConfirm: false,
                            didOpen: () => {
                                const fileInput = document.getElementById('new_image_file_ar');
                                const urlInput = document.getElementById('new_image_url_ar');
                                const statusSpan = document.querySelector('.upload-status');
                                const uploadBtn = document.querySelector('.upload-btn');

                                fileInput.addEventListener('change', async (e) => {
                                    if (!e.target.files.length) return;
                                    
                                    const file = e.target.files[0];
                                    const formData = new FormData();
                                    formData.append('image', file);
                                    
                                    statusSpan.textContent = 'Uploading...';
                                    uploadBtn.disabled = true;
                                    
                                    try {
                                        const response = await fetch('../upload_handler.php', {
                                            method: 'POST',
                                            body: formData
                                        });
                                        
                                        const result = await response.json();
                                        
                                        if (result.success) {
                                            urlInput.value = result.url;
                                            statusSpan.textContent = 'Upload successful!';
                                            statusSpan.style.color = 'green';
                                        } else {
                                            throw new Error(result.message);
                                        }
                                    } catch (error) {
                                        statusSpan.textContent = `Error: ${error.message}`;
                                        statusSpan.style.color = 'red';
                                        console.error('Upload error:', error);
                                    } finally {
                                        uploadBtn.disabled = false;
                                        fileInput.value = '';
                                    }
                                });
                            },
                            preConfirm: () => {
                                return {
                                    image_url: document.getElementById('new_image_url_ar').value,
                                    link: document.getElementById('new_link_ar').value,
                                    leftTitle: document.getElementById('new_left_title_ar').value,
                                    rightTitle: document.getElementById('new_right_title_ar').value
                                }
                            }
                        }).then((result) => {
                            if (result.isConfirmed) {
                                const newSlideIndex = slideCountAr++;
                                const newSlide = document.createElement('div');
                                newSlide.className = 'slide';
                                newSlide.id = `slide-ar-${newSlideIndex}`;
                                newSlide.innerHTML = `
                                    <div class="slide-number">Slide ${newSlideIndex + 1}</div>
                                    <button type="button" class="delete-slide" onclick="deleteSlideAr(${newSlideIndex})">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                    <div class="form-group">
                                        <label>Image URL:</label>
                                        <input type="text" id="image_url_ar_${newSlideIndex}" name="image_url_ar[]" value="${result.value.image_url}" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Link:</label>
                                        <input type="text" name="link_ar[]" value="${result.value.link}" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Left Title:</label>
                                        <input type="text" name="leftTitle_ar[]" value="${result.value.leftTitle}" required>
                                    </div>
                                    <div class="form-group">
                                        <label>Right Title:</label>
                                        <input type="text" name="rightTitle_ar[]" value="${result.value.rightTitle}" required>
                                    </div>
                                `;
                                document.getElementById('slides-container-ar').appendChild(newSlide);
                                createImageUploader(`image_url_ar_${newSlideIndex}`);
                            }
                        });
                    }

                    function deleteSlide(index) {
                        const slide = document.getElementById(`slide-${index}`);
                        if (slide) {
                            Swal.fire({
                                title: 'Are you sure?',
                                text: "You won't be able to revert this!",
                                icon: 'warning',
                                showCancelButton: true,
                                confirmButtonColor: '#3085d6',
                                cancelButtonColor: '#d33',
                                confirmButtonText: 'Yes, delete it!'
                            }).then((result) => {
                                if (result.isConfirmed) {
                                    slide.remove();
                                }
                            });
                        }
                    }

                    function deleteSlideAr(index) {
                        const slide = document.getElementById(`slide-ar-${index}`);
                        if (slide) {
                            Swal.fire({
                                title: 'Are you sure?',
                                text: "You won't be able to revert this!",
                                icon: 'warning',
                                showCancelButton: true,
                                confirmButtonColor: '#3085d6',
                                cancelButtonColor: '#d33',
                                confirmButtonText: 'Yes, delete it!'
                            }).then((result) => {
                                if (result.isConfirmed) {
                                    slide.remove();
                                }
                            });
                        }
                    }

                    function saveBothConfigs() {
                        // Collect English slides data
                        const englishSlides = [];
                        document.querySelectorAll('#slides-container .slide').forEach((slide, index) => {
                            englishSlides.push({
                                slide_id: index + 1,
                                image_url: slide.querySelector('input[name="image_url[]"]').value,
                                link: slide.querySelector('input[name="link[]"]').value,
                                leftTitle: slide.querySelector('input[name="leftTitle[]"]').value,
                                rightTitle: slide.querySelector('input[name="rightTitle[]"]').value
                            });
                        });

                        // Collect Arabic slides data
                        const arabicSlides = [];
                        document.querySelectorAll('#slides-container-ar .slide').forEach((slide, index) => {
                            arabicSlides.push({
                                slide_id: index + 1,
                                image_url: slide.querySelector('input[name="image_url_ar[]"]').value,
                                link: slide.querySelector('input[name="link_ar[]"]').value,
                                leftTitle: slide.querySelector('input[name="leftTitle_ar[]"]').value,
                                rightTitle: slide.querySelector('input[name="rightTitle_ar[]"]').value
                            });
                        });

                        // Show loading state
                        Swal.fire({
                            title: 'Saving changes...',
                            allowOutsideClick: false,
                            didOpen: () => {
                                Swal.showLoading();
                            }
                        });

                        // Save both configurations
                        Promise.all([
                            fetch('../api/update_master_config.php', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                },
                                body: JSON.stringify({
                                    page: 'home',
                                    key_name: 'slideshow_content',
                                    value: englishSlides
                                })
                            }),
                            fetch('../api/update_master_config.php', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': 'application/json',
                                },
                                body: JSON.stringify({
                                    page: 'home',
                                    key_name: 'slideshow_content_ar',
                                    value: arabicSlides
                                })
                            })
                        ])
                        .then(responses => Promise.all(responses.map(r => r.json())))
                        .then(results => {
                            if (results.every(r => r.success)) {
                                Swal.fire({
                                    icon: 'success',
                                    title: 'Success!',
                                    text: 'Both configurations have been saved successfully.',
                                });
                            } else {
                                throw new Error('Failed to save one or both configurations');
                            }
                        })
                        .catch(error => {
                            console.error('Save error:', error);
                            Swal.fire({
                                icon: 'error',
                                title: 'Error!',
                                text: 'There was an error saving the configurations.',
                            });
                        });
                    }

                    // Initialize slide counts
                    document.addEventListener('DOMContentLoaded', function() {
                        slideCount = document.querySelectorAll('#slides-container .slide').length;
                        slideCountAr = document.querySelectorAll('#slides-container-ar .slide').length;
                    });
                </script>
            </div>

            <h3 class="section-header" onclick="toggleSection('loan-ads')" style="margin-top: 30px;">
                Loan Advertisement Configuration
                <i class="fas fa-chevron-down"></i>
            </h3>

            <div id="loan-ads-section" class="section-content collapsed">
                <?php
                try {
                    $sql = "SELECT * FROM master_config WHERE page = 'loans' AND key_name = 'loan_ad'";
                    $result = $conn->query($sql);
                    
                    if ($result->num_rows > 0) {
                        $row = $result->fetch_assoc();
                        $configData = $row['value'];
                        $configData = str_replace('\\"', '"', $configData);
                        $configData = str_replace('\n', '', $configData);
                        $adData = json_decode($configData, true);
                        
                        if (json_last_error() === JSON_ERROR_NONE) {
                            ?>
                            <form id="loanAdForm">
                                <div class="form-group">
                                    <label>Image URL:</label>
                                    <input type="text" name="image_url" value="<?php echo htmlspecialchars($adData['image_url']); ?>" required>
                                </div>
                                <button type="submit" class="save-changes">
                                    <i class="fas fa-save"></i> Save Changes
                                </button>
                            </form>

                            <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                const loanAdForm = document.getElementById('loanAdForm');
                                if (loanAdForm) {
                                    loanAdForm.addEventListener('submit', function(e) {
                                        e.preventDefault();
                                        
                                        const data = {
                                            page: 'loans',
                                            key_name: 'loan_ad',
                                            value: {
                                                image_url: this.querySelector('[name="image_url"]').value
                                            }
                                        };

                                        console.log('Sending loan ad data:', data);
                                        
                                        fetch('../api/update_master_config.php', {
                                            method: 'POST',
                                            headers: {
                                                'Content-Type': 'application/json',
                                            },
                                            body: JSON.stringify(data)
                                        })
                                        .then(response => {
                                            if (!response.ok) {
                                                throw new Error('Network response was not ok');
                                            }
                                            return response.json();
                                        })
                                        .then(data => {
                                            if (data.success) {
                                                Swal.fire({
                                                    icon: 'success',
                                                    title: 'Success!',
                                                    text: 'Loan advertisement updated successfully',
                                                    icon: 'success',
                                                    confirmButtonText: 'OK'
                                                });
                                            } else {
                                                throw new Error(data.message || 'Failed to update loan advertisement');
                                            }
                                        })
                                        .catch(error => {
                                            console.error('Error:', error);
                                            Swal.fire({
                                                icon: 'error',
                                                title: 'Error!',
                                                text: error.message || 'An error occurred while updating the loan advertisement',
                                                icon: 'error',
                                                confirmButtonText: 'OK'
                                            });
                                        });
                                    });
                                }
                            });
                            </script>
                            <?php
                        } else {
                            echo "<p>Error decoding JSON: " . json_last_error_msg() . "</p>";
                        }
                    } else {
                        echo "<p>No loan advertisement configuration found in the database.</p>";
                    }
                } catch (Exception $e) {
                    echo "Error: " . $e->getMessage();
                }
                ?>
            </div>

            <h3 class="section-header" onclick="toggleSection('card-ads')" style="margin-top: 30px;">
                Card Advertisement Configuration
                <i class="fas fa-chevron-down"></i>
            </h3>

            <div id="card-ads-section" class="section-content collapsed">
                <?php
                try {
                    $sql = "SELECT * FROM master_config WHERE page = 'cards' AND key_name = 'card_ad'";
                    $result = $conn->query($sql);
                    
                    if ($result->num_rows > 0) {
                        $row = $result->fetch_assoc();
                        $configData = $row['value'];
                        $configData = str_replace('\\"', '"', $configData);
                        $configData = str_replace('\n', '', $configData);
                        $adData = json_decode($configData, true);
                        
                        if (json_last_error() === JSON_ERROR_NONE) {
                            ?>
                            <form id="cardAdForm">
                                <div class="form-group">
                                    <label>Image URL:</label>
                                    <input type="text" name="image_url" value="<?php echo htmlspecialchars($adData['image_url']); ?>" required>
                                </div>
                                <button type="submit" class="save-changes">
                                    <i class="fas fa-save"></i> Save Changes
                                </button>
                            </form>

                            <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                const cardAdForm = document.getElementById('cardAdForm');
                                if (cardAdForm) {
                                    cardAdForm.addEventListener('submit', function(e) {
                                        e.preventDefault();
                                        
                                        const data = {
                                            page: 'cards',
                                            key_name: 'card_ad',
                                            value: {
                                                image_url: this.querySelector('[name="image_url"]').value
                                            }
                                        };

                                        console.log('Sending card ad data:', data);
                                        
                                        fetch('../api/update_master_config.php', {
                                            method: 'POST',
                                            headers: {
                                                'Content-Type': 'application/json',
                                            },
                                            body: JSON.stringify(data)
                                        })
                                        .then(response => {
                                            if (!response.ok) {
                                                throw new Error('Network response was not ok');
                                            }
                                            return response.json();
                                        })
                                        .then(data => {
                                            if (data.success) {
                                                Swal.fire({
                                                    icon: 'success',
                                                    title: 'Success!',
                                                    text: 'Card advertisement updated successfully',
                                                    icon: 'success',
                                                    confirmButtonText: 'OK'
                                                });
                                            } else {
                                                throw new Error(data.message || 'Failed to update card advertisement');
                                            }
                                        })
                                        .catch(error => {
                                            console.error('Error:', error);
                                            Swal.fire({
                                                icon: 'error',
                                                title: 'Error!',
                                                text: error.message || 'An error occurred while updating the card advertisement',
                                                icon: 'error',
                                                confirmButtonText: 'OK'
                                            });
                                        });
                                    });
                                }
                            });
                            </script>
                            <?php
                        } else {
                            echo "<p>Error decoding JSON: " . json_last_error_msg() . "</p>";
                        }
                    } else {
                        echo "<p>No card advertisement configuration found in the database.</p>";
                    }
                } catch (Exception $e) {
                    echo "Error: " . $e->getMessage();
                }
                ?>
            </div>

            <h3 class="section-header" onclick="toggleSection('contact')" style="margin-top: 30px;">
                Contact Details Configuration
                <i class="fas fa-chevron-down"></i>
            </h3>

            <div id="contact-section" class="section-content collapsed">
                <?php
                try {
                    $sql = "SELECT * FROM master_config WHERE page = 'home' AND key_name = 'contact_details'";
                    $result = $conn->query($sql);
                    
                    if ($result->num_rows > 0) {
                        $row = $result->fetch_assoc();
                        $configData = $row['value'];
                        $configData = stripslashes($configData);  // Remove slashes
                        $contactDetails = json_decode($configData, true);
                        
                        if (json_last_error() === JSON_ERROR_NONE) {
                            ?>
                            <form id="contactForm" class="config-form">
                                <div class="form-group">
                                    <label for="email">Email:</label>
                                    <input type="email" id="email" name="email" value="<?php echo htmlspecialchars($contactDetails['email'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="phone">Phone:</label>
                                    <input type="text" id="phone" name="phone" value="<?php echo htmlspecialchars($contactDetails['phone'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="work_hours">Work Hours:</label>
                                    <input type="text" id="work_hours" name="work_hours" value="<?php echo htmlspecialchars($contactDetails['work_hours'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="linkedin">LinkedIn URL:</label>
                                    <input type="url" id="linkedin" name="linkedin" value="<?php echo htmlspecialchars($contactDetails['social_links']['linkedin'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="instagram">Instagram URL:</label>
                                    <input type="url" id="instagram" name="instagram" value="<?php echo htmlspecialchars($contactDetails['social_links']['instagram'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="twitter">Twitter URL:</label>
                                    <input type="url" id="twitter" name="twitter" value="<?php echo htmlspecialchars($contactDetails['social_links']['twitter'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="facebook">Facebook URL:</label>
                                    <input type="url" id="facebook" name="facebook" value="<?php echo htmlspecialchars($contactDetails['social_links']['facebook'] ?? ''); ?>" required>
                                </div>
                                
                                <button type="submit" class="save-changes">
                                    <i class="fas fa-save"></i> Save Changes
                                </button>
                            </form>

                            <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                const contactForm = document.getElementById('contactForm');
                                if (contactForm) {
                                    contactForm.addEventListener('submit', function(e) {
                                        e.preventDefault();
                                        
                                        try {
                                            const contactData = {
                                                email: document.getElementById('email')?.value?.trim() || '',
                                                phone: document.getElementById('phone')?.value?.trim() || '',
                                                work_hours: document.getElementById('work_hours')?.value?.trim() || '',
                                                social_links: {
                                                    linkedin: document.getElementById('linkedin')?.value?.trim() || '',
                                                    instagram: document.getElementById('instagram')?.value?.trim() || '',
                                                    twitter: document.getElementById('twitter')?.value?.trim() || '',
                                                    facebook: document.getElementById('facebook')?.value?.trim() || ''
                                                }
                                            };

                                            // Validate required fields
                                            if (!contactData.email || !contactData.phone) {
                                                Swal.fire({
                                                    icon: 'error',
                                                    title: 'Validation Error',
                                                    text: 'Email and Phone are required fields.',
                                                    confirmButtonColor: '#0A71A3'
                                                });
                                                return;
                                            }

                                            // Show loading state
                                            Swal.fire({
                                                title: 'Saving changes...',
                                                allowOutsideClick: false,
                                                didOpen: () => {
                                                    Swal.showLoading();
                                                }
                                            });

                                            fetch('../api/update_master_config.php', {
                                                method: 'POST',
                                                headers: {
                                                    'Content-Type': 'application/json'
                                                },
                                                body: JSON.stringify({
                                                    page: 'home',
                                                    key_name: 'contact_details',
                                                    value: contactData
                                                })
                                            })
                                            .then(response => response.json())
                                            .then(data => {
                                                if (data.success) {
                                                    Swal.fire({
                                                        icon: 'success',
                                                        title: 'Success!',
                                                        text: 'Contact details have been updated.',
                                                        confirmButtonColor: '#0A71A3'
                                                    });
                                                } else {
                                                    throw new Error(data.message || 'Failed to update contact details');
                                                }
                                            })
                                            .catch(error => {
                                                console.error('Error:', error);
                                                Swal.fire({
                                                    icon: 'error',
                                                    title: 'Error!',
                                                    text: error.message || 'An error occurred while saving changes.',
                                                    confirmButtonColor: '#0A71A3'
                                                });
                                            });
                                        } catch (error) {
                                            console.error('Form submission error:', error);
                                            Swal.fire({
                                                icon: 'error',
                                                title: 'Error!',
                                                text: 'An error occurred while processing the form.',
                                                confirmButtonColor: '#0A71A3'
                                            });
                                        }
                                    });
                                }

                                const contactFormAr = document.getElementById('contactFormAr');
                                if (contactFormAr) {
                                    contactFormAr.addEventListener('submit', function(e) {
                                        e.preventDefault();
                                        
                                        try {
                                            const contactData = {
                                                email: document.getElementById('email_ar')?.value?.trim() || '',
                                                phone: document.getElementById('phone_ar')?.value?.trim() || '',
                                                work_hours: document.getElementById('work_hours_ar')?.value?.trim() || '',
                                                social_links: {
                                                    linkedin: document.getElementById('linkedin_ar')?.value?.trim() || '',
                                                    instagram: document.getElementById('instagram_ar')?.value?.trim() || '',
                                                    twitter: document.getElementById('twitter_ar')?.value?.trim() || '',
                                                    facebook: document.getElementById('facebook_ar')?.value?.trim() || ''
                                                }
                                            };

                                            // Validate required fields
                                            if (!contactData.email || !contactData.phone) {
                                                Swal.fire({
                                                    icon: 'error',
                                                    title: 'Validation Error',
                                                    text: 'Email and Phone are required fields.',
                                                    confirmButtonColor: '#0A71A3'
                                                });
                                                return;
                                            }

                                            // Show loading state
                                            Swal.fire({
                                                title: 'Saving changes...',
                                                allowOutsideClick: false,
                                                didOpen: () => {
                                                    Swal.showLoading();
                                                }
                                            });

                                            fetch('../api/update_master_config.php', {
                                                method: 'POST',
                                                headers: {
                                                    'Content-Type': 'application/json'
                                                },
                                                body: JSON.stringify({
                                                    page: 'home',
                                                    key_name: 'contact_details_ar',
                                                    value: contactData
                                                })
                                            })
                                            .then(response => response.json())
                                            .then(data => {
                                                if (data.success) {
                                                    Swal.fire({
                                                        icon: 'success',
                                                        title: 'Success!',
                                                        text: 'Contact details have been updated.',
                                                        confirmButtonColor: '#0A71A3'
                                                    });
                                                } else {
                                                    throw new Error(data.message || 'Failed to update contact details');
                                                }
                                            })
                                            .catch(error => {
                                                console.error('Error:', error);
                                                Swal.fire({
                                                    icon: 'error',
                                                    title: 'Error!',
                                                    text: error.message || 'An error occurred while saving changes.',
                                                    confirmButtonColor: '#0A71A3'
                                                });
                                            });
                                        } catch (error) {
                                            console.error('Form submission error:', error);
                                            Swal.fire({
                                                icon: 'error',
                                                title: 'Error!',
                                                text: 'An error occurred while processing the form.',
                                                confirmButtonColor: '#0A71A3'
                                            });
                                        }
                                    });
                                }
                            });
                            </script>
                            <?php
                        } else {
                            echo "<p>Error decoding JSON: " . json_last_error_msg() . "</p>";
                        }
                    } else {
                        echo "<p>No contact details found in the database.</p>";
                    }
                } catch (Exception $e) {
                    echo "Error: " . $e->getMessage();
                }
                ?>
            </div>

            <h3 class="section-header" onclick="toggleSection('contact-ar')" style="margin-top: 30px;">
                Contact Details Configuration (Arabic)
                <i class="fas fa-chevron-down"></i>
            </h3>

            <div id="contact-ar-section" class="section-content collapsed">
                <?php
                try {
                    $sql = "SELECT * FROM master_config WHERE page = 'home' AND key_name = 'contact_details_ar'";
                    $result = $conn->query($sql);
                    
                    if ($result->num_rows > 0) {
                        $row = $result->fetch_assoc();
                        $configData = $row['value'];
                        $configData = stripslashes($configData);
                        $contactDetails = json_decode($configData, true);
                        
                        if (json_last_error() === JSON_ERROR_NONE) {
                            ?>
                            <form id="contactFormAr" class="config-form">
                                <div class="form-group">
                                    <label for="email_ar">Email:</label>
                                    <input type="email" id="email_ar" name="email" value="<?php echo htmlspecialchars($contactDetails['email'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="phone_ar">Phone:</label>
                                    <input type="text" id="phone_ar" name="phone" value="<?php echo htmlspecialchars($contactDetails['phone'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="work_hours_ar">Work Hours:</label>
                                    <input type="text" id="work_hours_ar" name="work_hours" value="<?php echo htmlspecialchars($contactDetails['work_hours'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="linkedin_ar">LinkedIn URL:</label>
                                    <input type="url" id="linkedin_ar" name="linkedin" value="<?php echo htmlspecialchars($contactDetails['social_links']['linkedin'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="instagram_ar">Instagram URL:</label>
                                    <input type="url" id="instagram_ar" name="instagram" value="<?php echo htmlspecialchars($contactDetails['social_links']['instagram'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="twitter_ar">Twitter URL:</label>
                                    <input type="url" id="twitter_ar" name="twitter" value="<?php echo htmlspecialchars($contactDetails['social_links']['twitter'] ?? ''); ?>" required>
                                </div>
                                
                                <div class="form-group">
                                    <label for="facebook_ar">Facebook URL:</label>
                                    <input type="url" id="facebook_ar" name="facebook" value="<?php echo htmlspecialchars($contactDetails['social_links']['facebook'] ?? ''); ?>" required>
                                </div>
                                
                                <button type="submit" class="save-changes">
                                    <i class="fas fa-save"></i> Save Changes
                                </button>
                            </form>

                            <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                const contactFormAr = document.getElementById('contactFormAr');
                                if (contactFormAr) {
                                    contactFormAr.addEventListener('submit', function(e) {
                                        e.preventDefault();
                                        
                                        try {
                                            const contactData = {
                                                email: document.getElementById('email_ar')?.value?.trim() || '',
                                                phone: document.getElementById('phone_ar')?.value?.trim() || '',
                                                work_hours: document.getElementById('work_hours_ar')?.value?.trim() || '',
                                                social_links: {
                                                    linkedin: document.getElementById('linkedin_ar')?.value?.trim() || '',
                                                    instagram: document.getElementById('instagram_ar')?.value?.trim() || '',
                                                    twitter: document.getElementById('twitter_ar')?.value?.trim() || '',
                                                    facebook: document.getElementById('facebook_ar')?.value?.trim() || ''
                                                }
                                            };

                                            // Validate required fields
                                            if (!contactData.email || !contactData.phone) {
                                                Swal.fire({
                                                    icon: 'error',
                                                    title: 'Validation Error',
                                                    text: 'Email and Phone are required fields.',
                                                    confirmButtonColor: '#0A71A3'
                                                });
                                                return;
                                            }

                                            // Show loading state
                                            Swal.fire({
                                                title: 'Saving changes...',
                                                allowOutsideClick: false,
                                                didOpen: () => {
                                                    Swal.showLoading();
                                                }
                                            });

                                            fetch('../api/update_master_config.php', {
                                                method: 'POST',
                                                headers: {
                                                    'Content-Type': 'application/json'
                                                },
                                                body: JSON.stringify({
                                                    page: 'home',
                                                    key_name: 'contact_details_ar',
                                                    value: contactData
                                                })
                                            })
                                            .then(response => response.json())
                                            .then(data => {
                                                if (data.success) {
                                                    Swal.fire({
                                                        icon: 'success',
                                                        title: 'Success!',
                                                        text: 'Contact details have been updated.',
                                                        confirmButtonColor: '#0A71A3'
                                                    });
                                                } else {
                                                    throw new Error(data.message || 'Failed to update contact details');
                                                }
                                            })
                                            .catch(error => {
                                                console.error('Error:', error);
                                                Swal.fire({
                                                    icon: 'error',
                                                    title: 'Error!',
                                                    text: error.message || 'An error occurred while saving changes.',
                                                    confirmButtonColor: '#0A71A3'
                                                });
                                            });
                                        } catch (error) {
                                            console.error('Form submission error:', error);
                                            Swal.fire({
                                                icon: 'error',
                                                title: 'Error!',
                                                text: 'An error occurred while processing the form.',
                                                confirmButtonColor: '#0A71A3'
                                            });
                                        }
                                    });
                                }
                            });
                            </script>
                            <?php
                        } else {
                            echo "<p>Error decoding JSON: " . json_last_error_msg() . "</p>";
                        }
                    } else {
                        echo "<p>No contact details found in the database.</p>";
                    }
                } catch (Exception $e) {
                    echo "Error: " . $e->getMessage();
                }
                ?>
            </div>
        </div>
    </div>

    <script>
        const sidebar = document.getElementById('sidebar');
        const toggleButton = document.getElementById('toggleSidebar');

        toggleButton.addEventListener('click', () => {
            sidebar.classList.toggle('collapsed');
        });

        // Handle responsive behavior
        if (window.innerWidth <= 768) {
            sidebar.classList.add('collapsed');
        }

        window.addEventListener('resize', () => {
            if (window.innerWidth <= 768) {
                sidebar.classList.add('collapsed');
            }
        });

        function toggleSection(sectionId) {
            const section = document.getElementById(`${sectionId}-section`);
            section.classList.toggle('collapsed');
            
            const icon = event.currentTarget.querySelector('i');
            icon.classList.toggle('fa-chevron-down');
            icon.classList.toggle('fa-chevron-up');
        }
    </script>

    <script>
        function createImageUploader(inputId) {
            const input = document.getElementById(inputId);
            if (!input) return;
            
            // Check if uploader already exists
            const existingUploader = input.nextElementSibling;
            if (existingUploader && existingUploader.className === 'image-upload-container') {
                return; // Uploader already exists, don't create another one
            }
            
            // Create upload button and container
            const uploadContainer = document.createElement('div');
            uploadContainer.className = 'image-upload-container';
            
            const fileInput = document.createElement('input');
            fileInput.type = 'file';
            fileInput.accept = 'image/*';
            fileInput.style.display = 'none';
            
            const uploadBtn = document.createElement('button');
            uploadBtn.type = 'button';
            uploadBtn.className = 'upload-btn';
            uploadBtn.innerHTML = '<i class="fas fa-upload"></i> Upload';
            
            const statusSpan = document.createElement('span');
            statusSpan.className = 'upload-status';
            
            uploadContainer.appendChild(fileInput);
            uploadContainer.appendChild(uploadBtn);
            uploadContainer.appendChild(statusSpan);
            
            // Insert the upload container after the input
            input.parentNode.insertBefore(uploadContainer, input.nextSibling);
            
            // Handle click on upload button
            uploadBtn.addEventListener('click', () => {
                fileInput.click();
            });
            
            // Handle file selection
            fileInput.addEventListener('change', async (e) => {
                if (!e.target.files.length) return;
                
                const file = e.target.files[0];
                const formData = new FormData();
                formData.append('image', file);
                
                statusSpan.textContent = 'Uploading...';
                uploadBtn.disabled = true;
                
                try {
                    const response = await fetch('../upload_handler.php', {
                        method: 'POST',
                        body: formData
                    });
                    
                    const result = await response.json();
                    
                    if (result.success) {
                        input.value = result.url;
                        statusSpan.textContent = 'Upload successful!';
                        statusSpan.style.color = 'green';
                    } else {
                        throw new Error(result.message);
                    }
                } catch (error) {
                    statusSpan.textContent = `Error: ${error.message}`;
                    statusSpan.style.color = 'red';
                    console.error('Upload error:', error);
                } finally {
                    uploadBtn.disabled = false;
                    fileInput.value = '';
                }
            });
        }

        // Initialize image uploaders for all image URL fields
        document.addEventListener('DOMContentLoaded', function() {
            // For English slides
            document.querySelectorAll('[id^="image_url_"]').forEach(input => {
                createImageUploader(input.id);
            });
            
            // For Arabic slides
            document.querySelectorAll('[id^="image_url_ar_"]').forEach(input => {
                createImageUploader(input.id);
            });
        });
    </script>
</body>
</html>
