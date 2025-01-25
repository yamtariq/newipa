<?php
require_once '../db_connect.php';
?>

<!DOCTYPE html>
<html>
<head>
    <title>Nayifat - API Tester</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        :root {
            --primary-color: #87CEEB;
            --secondary-color: #4a4a4a;
            --background-color: #F0F8FF;
            --border-color: #B0E0E6;
        }
        
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: var(--background-color);
            height: 100vh;
            overflow: hidden;
        }
        
        .container {
            max-width: 1400px;
            margin: 10px auto;
            padding: 0 10px;
            height: 95vh;
        }
        
        .card {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin: 0;
            height: 95vh;
        }
        
        .card-header {
            padding: 15px 20px;
            border-bottom: 1px solid var(--border-color);
            background-color: var(--primary-color);
            color: white;
            border-radius: 8px 8px 0 0;
        }
        
        .card-title {
            margin: 0;
            font-size: 1.2em;
        }
        
        .card-body {
            padding: 15px;
            display: flex;
            flex-direction: column;
            height: calc(100% - 60px);
        }
        
        .form-group {
            margin-bottom: 10px;
        }
        
        label {
            display: block;
            margin-bottom: 5px;
            color: var(--secondary-color);
            font-weight: bold;
        }
        
        .form-control {
            width: 100%;
            padding: 6px 10px;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            box-sizing: border-box;
            margin-bottom: 8px;
            font-size: 13px;
        }
        
        textarea.form-control {
            min-height: 120px;
            font-family: monospace;
        }
        
        .btn {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 13px;
            transition: all 0.2s ease;
        }
        
        .btn-primary {
            background-color: var(--primary-color);
            color: white;
        }
        
        .btn-primary:hover {
            background-color: #6bb8d6;
        }
        
        .btn-outline-secondary {
            background-color: white;
            border: 1px solid var(--secondary-color);
            color: var(--secondary-color);
        }
        
        .btn-outline-secondary:hover {
            background-color: var(--secondary-color);
            color: white;
        }
        
        .badge {
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: normal;
        }
        
        .bg-secondary { background-color: var(--secondary-color); color: white; }
        .bg-success { background-color: var(--primary-color); color: white; }
        .bg-danger { background-color: #dc3545; color: white; }
        .bg-warning { background-color: #ffc107; color: black; }
        
        #response {
            font-family: monospace;
            white-space: pre;
            background-color: #f8f9fa;
            height: calc(100% - 40px);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            padding: 8px;
        }
        
        .response-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .row {
            display: flex;
            height: 100%;
            margin: 0;
            gap: 20px;
        }
        
        .col-md-6 {
            width: 50%;
            height: 100%;
            display: flex;
            flex-direction: column;
        }
        
        .form-section {
            flex: 1;
            display: flex;
            flex-direction: column;
        }
        
        .form-section > .form-group:last-child {
            margin-bottom: 0;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 10px;
            }
            .row {
                flex-direction: column;
                gap: 10px;
            }
            .col-md-6 {
                width: 100%;
                height: auto;
            }
            #response {
                height: 300px;
            }
        }
        
        .form-check-inline {
            display: inline-flex;
            align-items: center;
            padding: 0;
            margin-right: 1rem;
            margin-bottom: 0;
        }
        
        .form-check-inline .form-check-input {
            margin-right: 0.5rem;
        }
        
        .form-check-inline .form-check-label {
            margin-bottom: 0;
        }
        
        .options-row {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 10px;
        }
        
        .options-row label:first-child {
            margin-right: 10px;
            margin-bottom: 0;
        }
        
        .form-check-input:checked {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
        }
        
        .form-row {
            display: flex;
            gap: 10px;
            margin-bottom: 10px;
        }
        
        .form-row .form-group {
            margin-bottom: 0;
            flex: 1;
        }
        
        .form-row .form-group.method-group {
            flex: 0 0 120px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="row">
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">API Tester</h4>
                    </div>
                    <div class="card-body">
                        <div class="form-section">
                            <div class="form-row">
                                <div class="form-group method-group">
                                    <label>Method</label>
                                    <select id="method" class="form-control">
                                        <option value="GET">GET</option>
                                        <option value="POST">POST</option>
                                        <option value="PUT">PUT</option>
                                        <option value="DELETE">DELETE</option>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label>Request URL</label>
                                    <input type="text" id="apiUrl" class="form-control" placeholder="Enter API URL">
                                </div>
                            </div>
                            <div class="form-group">
                                <div class="options-row">
                                    <label>Headers</label>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" name="headersType" id="headersTypeFields" value="fields" checked>
                                        <label class="form-check-label" for="headersTypeFields">Fields</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" name="headersType" id="headersTypeJson" value="json">
                                        <label class="form-check-label" for="headersTypeJson">JSON</label>
                                    </div>
                                </div>
                                <div id="headersFields">
                                    <div class="header-field-row">
                                        <div class="row mb-2">
                                            <div class="col">
                                                <input type="text" class="form-control header-key" placeholder="Key">
                                            </div>
                                            <div class="col">
                                                <input type="text" class="form-control header-value" placeholder="Value">
                                            </div>
                                            <div class="col-auto">
                                                <button type="button" class="btn btn-outline-danger" onclick="removeHeaderField(this)">
                                                    <i class="fas fa-times"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                    <button type="button" class="btn btn-outline-secondary btn-sm" onclick="addHeaderField()">
                                        <i class="fas fa-plus"></i> Add Header
                                    </button>
                                </div>
                                <div id="headersJson" style="display: none;">
                                    <textarea id="headers" class="form-control" placeholder='{"Content-Type": "application/json"}'></textarea>
                                </div>
                            </div>
                            <div class="form-group">
                                <div class="options-row">
                                    <label>Request Body</label>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" name="bodyType" id="bodyTypeForm" value="form" checked>
                                        <label class="form-check-label" for="bodyTypeForm">Form</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" name="bodyType" id="bodyTypeFields" value="fields">
                                        <label class="form-check-label" for="bodyTypeFields">Fields</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" name="bodyType" id="bodyTypeJson" value="json">
                                        <label class="form-check-label" for="bodyTypeJson">JSON</label>
                                    </div>
                                </div>
                                <div id="bodyForm">
                                    <div class="body-form-row">
                                        <div class="row mb-2">
                                            <div class="col">
                                                <input type="text" class="form-control body-key" placeholder="Key">
                                            </div>
                                            <div class="col">
                                                <input type="text" class="form-control body-value" placeholder="Value">
                                            </div>
                                            <div class="col-auto">
                                                <button type="button" class="btn btn-outline-danger" onclick="removeBodyFormField(this)">
                                                    <i class="fas fa-times"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                    <button type="button" class="btn btn-outline-secondary btn-sm" onclick="addBodyFormField()">
                                        <i class="fas fa-plus"></i> Add Field
                                    </button>
                                </div>
                                <div id="bodyFields" style="display: none;">
                                    <div class="body-field-row">
                                        <div class="row mb-2">
                                            <div class="col">
                                                <input type="text" class="form-control body-key" placeholder="Key">
                                            </div>
                                            <div class="col">
                                                <input type="text" class="form-control body-value" placeholder="Value">
                                            </div>
                                            <div class="col-auto">
                                                <button type="button" class="btn btn-outline-danger" onclick="removeBodyField(this)">
                                                    <i class="fas fa-times"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                    <button type="button" class="btn btn-outline-secondary btn-sm" onclick="addBodyField()">
                                        <i class="fas fa-plus"></i> Add Field
                                    </button>
                                </div>
                                <div id="bodyJson" style="display: none;">
                                    <textarea id="requestBody" class="form-control" placeholder='{"key": "value"}'></textarea>
                                </div>
                            </div>
                            <button class="btn btn-primary" onclick="sendRequest()">
                                <i class="fas fa-paper-plane"></i> Send Request
                            </button>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">Response</h4>
                    </div>
                    <div class="card-body">
                        <div class="form-section">
                            <div class="form-group">
                                <div class="response-header">
                                    <span id="statusCode" class="badge bg-secondary">Status: --</span>
                                    <button class="btn btn-outline-secondary" onclick="copyResponse()">
                                        <i class="fas fa-copy"></i> Copy
                                    </button>
                                </div>
                                <textarea id="response" class="form-control" readonly></textarea>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
    // Toggle between fields and JSON for headers
    document.querySelectorAll('input[name="headersType"]').forEach(radio => {
        radio.addEventListener('change', function() {
            document.getElementById('headersFields').style.display = this.value === 'fields' ? 'block' : 'none';
            document.getElementById('headersJson').style.display = this.value === 'json' ? 'block' : 'none';
        });
    });

    // Toggle between form, fields and JSON for body
    document.querySelectorAll('input[name="bodyType"]').forEach(radio => {
        radio.addEventListener('change', function() {
            document.getElementById('bodyForm').style.display = this.value === 'form' ? 'block' : 'none';
            document.getElementById('bodyFields').style.display = this.value === 'fields' ? 'block' : 'none';
            document.getElementById('bodyJson').style.display = this.value === 'json' ? 'block' : 'none';
        });
    });

    function addHeaderField() {
        const container = document.querySelector('#headersFields');
        const template = `
            <div class="header-field-row">
                <div class="row mb-2">
                    <div class="col">
                        <input type="text" class="form-control header-key" placeholder="Key">
                    </div>
                    <div class="col">
                        <input type="text" class="form-control header-value" placeholder="Value">
                    </div>
                    <div class="col-auto">
                        <button type="button" class="btn btn-outline-danger" onclick="removeHeaderField(this)">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
        // Insert the new field before the "Add Field" button
        const addButton = container.querySelector('button');
        addButton.insertAdjacentHTML('beforebegin', template);
    }

    function addBodyField() {
        const container = document.querySelector('#bodyFields');
        const template = `
            <div class="body-field-row">
                <div class="row mb-2">
                    <div class="col">
                        <input type="text" class="form-control body-key" placeholder="Key">
                    </div>
                    <div class="col">
                        <input type="text" class="form-control body-value" placeholder="Value">
                    </div>
                    <div class="col-auto">
                        <button type="button" class="btn btn-outline-danger" onclick="removeBodyField(this)">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
        // Insert the new field before the "Add Field" button
        const addButton = container.querySelector('button');
        addButton.insertAdjacentHTML('beforebegin', template);
    }

    function addBodyFormField() {
        const container = document.querySelector('#bodyForm');
        const template = `
            <div class="body-form-row">
                <div class="row mb-2">
                    <div class="col">
                        <input type="text" class="form-control body-key" placeholder="Key">
                    </div>
                    <div class="col">
                        <input type="text" class="form-control body-value" placeholder="Value">
                    </div>
                    <div class="col-auto">
                        <button type="button" class="btn btn-outline-danger" onclick="removeBodyFormField(this)">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
        // Insert the new field before the "Add Field" button
        const addButton = container.querySelector('button');
        addButton.insertAdjacentHTML('beforebegin', template);
    }

    function removeHeaderField(button) {
        const row = button.closest('.header-field-row');
        const container = document.querySelector('#headersFields');
        const totalFields = container.querySelectorAll('.header-field-row').length;
        
        // Only remove if there's more than one field
        if (totalFields > 1) {
            row.remove();
        }
    }

    function removeBodyField(button) {
        const row = button.closest('.body-field-row');
        const container = document.querySelector('#bodyFields');
        const totalFields = container.querySelectorAll('.body-field-row').length;
        
        // Only remove if there's more than one field
        if (totalFields > 1) {
            row.remove();
        }
    }

    function removeBodyFormField(button) {
        const row = button.closest('.body-form-row');
        const container = document.querySelector('#bodyForm');
        const totalFields = container.querySelectorAll('.body-form-row').length;
        
        // Only remove if there's more than one field
        if (totalFields > 1) {
            row.remove();
        }
    }

    function getHeadersFromFields() {
        const headers = {};
        document.querySelectorAll('.header-field-row').forEach(row => {
            const key = row.querySelector('.header-key').value.trim();
            const value = row.querySelector('.header-value').value.trim();
            if (key) headers[key] = value;
        });
        return headers;
    }

    function getBodyFromFields() {
        const body = {};
        document.querySelectorAll('.body-field-row').forEach(row => {
            const key = row.querySelector('.body-key').value.trim();
            const value = row.querySelector('.body-value').value.trim();
            if (key) body[key] = value;
        });
        return body;
    }

    function getFormDataFromFields() {
        const formData = new FormData();
        document.querySelectorAll('.body-form-row').forEach(row => {
            const key = row.querySelector('.body-key').value.trim();
            const value = row.querySelector('.body-value').value.trim();
            if (key) formData.append(key, value);
        });
        return formData;
    }

    function getUrlEncodedFromFields() {
        const params = new URLSearchParams();
        document.querySelectorAll('.body-form-row').forEach(row => {
            const key = row.querySelector('.body-key').value.trim();
            const value = row.querySelector('.body-value').value.trim();
            if (key) params.append(key, value);
        });
        return params;
    }

    function sendRequest() {
        const url = document.getElementById('apiUrl').value;
        const method = document.getElementById('method').value;
        let headers = {};
        let body = undefined;

        // Get headers based on selected type
        const headersType = document.querySelector('input[name="headersType"]:checked').value;
        if (headersType === 'json') {
            const headersText = document.getElementById('headers').value.trim();
            if (headersText) {
                try {
                    headers = JSON.parse(headersText);
                } catch (e) {
                    alert('Invalid headers JSON format');
                    return;
                }
            }
        } else {
            headers = getHeadersFromFields();
        }

        // Get body based on selected type
        if (method !== 'GET') {
            const bodyType = document.querySelector('input[name="bodyType"]:checked').value;
            if (bodyType === 'json') {
                const bodyText = document.getElementById('requestBody').value.trim();
                if (bodyText) {
                    try {
                        body = bodyText;
                        if (!headers['Content-Type']) {
                            headers['Content-Type'] = 'application/json';
                        }
                    } catch (e) {
                        alert('Invalid body JSON format');
                        return;
                    }
                }
            } else if (bodyType === 'form') {
                if (!headers['Content-Type']) {
                    headers['Content-Type'] = 'application/x-www-form-urlencoded';
                }
                body = getUrlEncodedFromFields().toString();
            } else {
                body = JSON.stringify(getBodyFromFields());
                if (!headers['Content-Type']) {
                    headers['Content-Type'] = 'application/json';
                }
            }
        }

        const statusElement = document.getElementById('statusCode');
        const responseElement = document.getElementById('response');
        
        statusElement.textContent = 'Status: Loading...';
        statusElement.className = 'badge bg-warning';
        responseElement.value = 'Loading...';
        
        fetch(url, {
            method: method,
            headers: headers,
            body: body
        })
        .then(async response => {
            const responseText = await response.text();
            let formattedResponse;
            
            try {
                const jsonResponse = JSON.parse(responseText);
                formattedResponse = JSON.stringify(jsonResponse, null, 2);
            } catch {
                formattedResponse = responseText;
            }
            
            statusElement.textContent = `Status: ${response.status} ${response.statusText}`;
            statusElement.className = 'badge bg-' + (response.ok ? 'success' : 'danger');
            responseElement.value = formattedResponse;
        })
        .catch(error => {
            statusElement.textContent = 'Status: Error';
            statusElement.className = 'badge bg-danger';
            responseElement.value = error.message;
        });
    }

    function copyResponse() {
        navigator.clipboard.writeText(document.getElementById('response').value);
        alert('Response copied to clipboard');
    }
    </script>
</body>
</html>
