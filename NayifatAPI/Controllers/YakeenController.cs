using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NayifatAPI.Data;
using NayifatAPI.Models;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;

namespace NayifatAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class YakeenController : BaseApiController
    {
        public YakeenController(ApplicationDbContext context, IConfiguration configuration)
            : base(context, configuration)
        {
        }

        public class CitizenInfoRequest
        {
            public string IqamaNumber { get; set; } = string.Empty;
            public string DateOfBirthHijri { get; set; } = string.Empty;
            public string IdExpiryDate { get; set; } = string.Empty;
        }

        public class CitizenAddressRequest
        {
            public string IqamaNumber { get; set; } = string.Empty;
            public string DateOfBirthHijri { get; set; } = string.Empty;
            public string AddressLanguage { get; set; } = string.Empty;
        }

        [HttpPost("getCitizenInfo/json")]
        public async Task<ActionResult<YakeenCitizenInfo>> GetCitizenInfo([FromBody] CitizenInfoRequest request)
        {
            if (string.IsNullOrEmpty(request.IqamaNumber) || 
                string.IsNullOrEmpty(request.DateOfBirthHijri) || 
                string.IsNullOrEmpty(request.IdExpiryDate))
            {
                return BadRequest("All fields are required");
            }

            // Look for existing record
            var citizenInfo = await _context.YakeenCitizenInfos
                .FirstOrDefaultAsync(c => c.IqamaNumber == request.IqamaNumber);

            if (citizenInfo == null)
            {
                // For testing, create a dummy record if not found
                citizenInfo = new YakeenCitizenInfo
                {
                    IqamaNumber = request.IqamaNumber,
                    DateOfBirthHijri = request.DateOfBirthHijri,
                    IdExpiryDate = request.IdExpiryDate,
                    DateOfBirth = "28-08-1395",
                    EnglishFirstName = "TARIQ",
                    EnglishLastName = "ALYAMI",
                    EnglishSecondName = "MUBARAK",
                    EnglishThirdName = "SAAD",
                    FamilyName = "اليامي",
                    FatherName = "مبارك",
                    FirstName = "طارق",
                    Gender = 0,
                    GenderFieldSpecified = true,
                    GrandFatherName = "سعد",
                    HifizaIssuePlace = "أبو عريش",
                    HifizaNumber = "41675",
                    IdIssueDate = "03-03-1441",
                    IdIssuePlace = "أحوال الرياض  4",
                    IdVersionNumber = 4,
                    LogIdField = 0,
                    NumberOfVehiclesReg = 2,
                    OccupationCode = "O",
                    SocialStatusDetailedDesc = "زوجة واحدة",
                    SubtribeName = "",
                    TotalNumberOfCurrentDependents = 3
                };

                _context.YakeenCitizenInfos.Add(citizenInfo);
                await _context.SaveChangesAsync();
            }

            return Ok(citizenInfo);
        }

        [HttpPost("getCitizenAddressInfo/json")]
        public async Task<ActionResult<YakeenCitizenAddress>> GetCitizenAddressInfo([FromBody] CitizenAddressRequest request)
        {
            if (string.IsNullOrEmpty(request.IqamaNumber) || 
                string.IsNullOrEmpty(request.DateOfBirthHijri) || 
                string.IsNullOrEmpty(request.AddressLanguage))
            {
                return BadRequest("All fields are required");
            }

            // Look for existing record
            var citizenAddress = await _context.YakeenCitizenAddresses
                .Include(c => c.CitizenAddressLists)
                .FirstOrDefaultAsync(c => c.IqamaNumber == request.IqamaNumber);

            if (citizenAddress == null)
            {
                // For testing, create a dummy record if not found
                citizenAddress = new YakeenCitizenAddress
                {
                    IqamaNumber = request.IqamaNumber,
                    DateOfBirthHijri = request.DateOfBirthHijri,
                    AddressLanguage = request.AddressLanguage,
                    LogId = 0,
                    CitizenAddressLists = new List<CitizenAddressListItem>
                    {
                        new CitizenAddressListItem
                        {
                            AdditionalNumber = 0,
                            BuildingNumber = 0,
                            City = request.AddressLanguage == "ar" ? "الرياض" : "Riyadh",
                            District = request.AddressLanguage == "ar" ? "حي النزهة" : "Al Nuzha District",
                            IsPrimaryAddress = true,
                            LocationCoordinates = "24.7136,46.6753",
                            PostCode = 12345,
                            StreetName = request.AddressLanguage == "ar" ? "شارع الملك فهد" : "King Fahd Road",
                            UnitNumber = 0
                        }
                    }
                };

                _context.YakeenCitizenAddresses.Add(citizenAddress);
                await _context.SaveChangesAsync();
            }

            return Ok(new { logId = citizenAddress.LogId, citizenaddresslists = citizenAddress.CitizenAddressLists });
        }
    }
} 