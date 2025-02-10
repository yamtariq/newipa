using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using NayifatAPI.Data;
using NayifatAPI.Models;
using System.IO;

namespace NayifatAPI.Controllers
{
    [ApiController]
    [Route("api/documents")]
    public class DocumentsController : ApiBaseController
    {
        private readonly ILogger<DocumentsController> _logger;
        private readonly string _uploadPath;

        public DocumentsController(
            ApplicationDbContext context,
            ILogger<DocumentsController> logger,
            IConfiguration configuration) : base(context, configuration)
        {
            _logger = logger;
            // 💡 Get upload path from configuration or use default
            _uploadPath = configuration.GetValue<string>("DocumentUploadPath") ?? Path.Combine(Directory.GetCurrentDirectory(), "Uploads");
            
            // Ensure upload directory exists
            if (!Directory.Exists(_uploadPath))
            {
                Directory.CreateDirectory(_uploadPath);
            }
        }

        [HttpPost("upload")]
        public async Task<IActionResult> UploadDocument([FromForm] IFormFile file, [FromForm] string nationalId, [FromForm] string documentType)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                if (file == null || file.Length == 0)
                {
                    return Error("No file uploaded", 400);
                }

                // Validate file type
                var allowedTypes = new[] { ".pdf", ".jpg", ".jpeg", ".png" };
                var fileExtension = Path.GetExtension(file.FileName).ToLowerInvariant();
                if (!allowedTypes.Contains(fileExtension))
                {
                    return Error("Invalid file type. Allowed types: PDF, JPG, JPEG, PNG", 400);
                }

                // Validate file size (max 10MB)
                if (file.Length > 10 * 1024 * 1024)
                {
                    return Error("File size must be less than 10MB", 400);
                }

                // 💡 Parse product type and actual document type
                var parts = documentType.Split('/');
                if (parts.Length != 2)
                {
                    return Error("Invalid document type format. Expected format: 'product/document_type'", 400);
                }

                var productType = parts[0];
                var actualDocumentType = parts[1];

                // Create product-specific directory
                var productPath = Path.Combine(_uploadPath, productType);
                if (!Directory.Exists(productPath))
                {
                    Directory.CreateDirectory(productPath);
                }

                // Create customer-specific directory inside product directory
                var customerPath = Path.Combine(productPath, nationalId);
                if (!Directory.Exists(customerPath))
                {
                    Directory.CreateDirectory(customerPath);
                }

                // Generate unique filename
                var fileName = $"{actualDocumentType}_{DateTime.UtcNow:yyyyMMddHHmmss}{fileExtension}";
                var filePath = Path.Combine(customerPath, fileName);

                // Save file
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // Save document record in database
                var document = new CustomerDocument
                {
                    NationalId = nationalId,
                    DocumentType = documentType,
                    FileName = fileName,
                    FilePath = filePath,
                    UploadDate = DateTime.UtcNow,
                    Status = "UPLOADED",
                    FileSize = file.Length,
                    FileType = fileExtension
                };

                _context.CustomerDocuments.Add(document);
                await _context.SaveChangesAsync();

                return Success(new { 
                    file_name = fileName,
                    document_type = documentType,
                    upload_date = document.UploadDate,
                    status = document.Status
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading document for National ID: {NationalId}", nationalId);
                return Error("Internal server error", 500);
            }
        }

        [HttpGet("status/{nationalId}/{documentType}")]
        public async Task<IActionResult> GetDocumentStatus(string nationalId, string documentType)
        {
            if (!ValidateApiKey())
            {
                return Error("Invalid API key", 401);
            }

            try
            {
                var document = await _context.CustomerDocuments
                    .Where(d => d.NationalId == nationalId && d.DocumentType == documentType)
                    .OrderByDescending(d => d.UploadDate)
                    .FirstOrDefaultAsync();

                if (document == null)
                {
                    return Error("Document not found", 404);
                }

                return Success(new
                {
                    status = document.Status,
                    upload_date = document.UploadDate,
                    file_name = document.FileName
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting document status for National ID: {NationalId}, Document Type: {DocumentType}", 
                    nationalId, documentType);
                return Error("Internal server error", 500);
            }
        }
    }
} 