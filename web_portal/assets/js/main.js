// Handle form submissions with AJAX
document.addEventListener('DOMContentLoaded', function() {
    // Generic form submission handler
    const handleFormSubmit = async (form, url) => {
        const formData = new FormData(form);
        try {
            const response = await fetch(url, {
                method: 'POST',
                body: formData
            });
            const data = await response.json();
            return data;
        } catch (error) {
            console.error('Error:', error);
            return { success: false, message: 'An error occurred' };
        }
    };

    // Handle status updates
    window.handleStatusUpdate = async (id, status, type) => {
        try {
            const response = await fetch(`../api/update-${type}-status.php`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ id, status })
            });
            const data = await response.json();
            if (data.success) {
                location.reload();
            }
        } catch (error) {
            console.error('Error:', error);
        }
    };

    // Search functionality
    const searchInput = document.getElementById('search');
    const statusFilter = document.getElementById('statusFilter');
    
    if (searchInput) {
        searchInput.addEventListener('input', debounce(filterTable, 300));
    }
    
    if (statusFilter) {
        statusFilter.addEventListener('change', filterTable);
    }

    function filterTable() {
        const searchTerm = searchInput ? searchInput.value.toLowerCase() : '';
        const statusTerm = statusFilter ? statusFilter.value.toLowerCase() : '';
        const table = document.querySelector('table');
        const rows = table.getElementsByTagName('tr');

        for (let i = 1; i < rows.length; i++) {
            const row = rows[i];
            const nationalId = row.cells[1].textContent.toLowerCase();
            const status = row.cells[row.cells.length - 3].textContent.toLowerCase();
            
            const matchesSearch = !searchTerm || nationalId.includes(searchTerm);
            const matchesStatus = !statusTerm || status === statusTerm;
            
            row.style.display = matchesSearch && matchesStatus ? '' : 'none';
        }
    }
});

// Modal handling
window.showModal = (modalId) => {
    document.getElementById(modalId).style.display = 'block';
};

window.closeModal = () => {
    const modals = document.getElementsByClassName('modal');
    for (let modal of modals) {
        modal.style.display = 'none';
    }
};

// Close modal when clicking outside
window.onclick = (event) => {
    if (event.target.classList.contains('modal')) {
        event.target.style.display = 'none';
    }
};

// Utility function for debouncing
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Add modal functionality for viewing application details
window.viewDetails = (id, type) => {
    fetch(`../api/get-${type}-details.php?id=${id}`)
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                const detailsHtml = generateDetailsHtml(data.details, type);
                document.getElementById('detailsModalContent').innerHTML = detailsHtml;
                showModal('detailsModal');
            }
        })
        .catch(error => console.error('Error:', error));
};

function generateDetailsHtml(details, type) {
    let html = `<h3>${type.charAt(0).toUpperCase() + type.slice(1)} Application Details</h3>`;
    for (let key in details) {
        if (details.hasOwnProperty(key)) {
            html += `<p><strong>${key.replace('_', ' ').toUpperCase()}:</strong> ${details[key]}</p>`;
        }
    }
    return html;
}
