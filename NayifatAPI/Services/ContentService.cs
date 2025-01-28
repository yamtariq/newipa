using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using MySql.Data.MySqlClient;
using NayifatAPI.Models;
using Microsoft.Extensions.Logging;

namespace NayifatAPI.Services;

public interface IContentService
{
    Task<Dictionary<string, string>> FetchLastUpdatesAsync();
    Task<Dictionary<string, ContentData>> FetchAllContentAsync();
}

public class ContentService : IContentService
{
    private readonly DatabaseService _db;
    private readonly ILogger<ContentService> _logger;
    private readonly IMemoryCache _cache;
    private const string UPDATES_CACHE_KEY = "content_updates";
    private const string CONTENT_CACHE_KEY = "content_all";
    private static readonly TimeSpan CACHE_DURATION = TimeSpan.FromMinutes(5);

    public ContentService(DatabaseService db, ILogger<ContentService> logger, IMemoryCache cache)
    {
        _db = db;
        _logger = logger;
        _cache = cache;
    }

    public async Task<Dictionary<string, string>> FetchLastUpdatesAsync()
    {
        // Try to get from cache first
        if (_cache.TryGetValue<Dictionary<string, string>>(UPDATES_CACHE_KEY, out var cachedUpdates))
        {
            _logger.LogInformation("Returning cached updates");
            return cachedUpdates;
        }

        var updates = new Dictionary<string, string>();
        
        foreach (var type in ContentTypes.All)
        {
            using var cmd = _db.CreateCommand(
                "SELECT last_updated FROM master_config WHERE page = @page AND key_name = @keyName");
            cmd.Parameters.AddWithValue("@page", type.Page);
            cmd.Parameters.AddWithValue("@keyName", type.KeyName);

            try
            {
                using var reader = await cmd.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    updates[type.KeyName] = reader.GetString("last_updated");
                }
            }
            catch (MySqlException ex)
            {
                _logger.LogError(ex, "Error fetching last_updated for {Page}/{KeyName}", type.Page, type.KeyName);
                continue; // Skip this content type if there's an error, matching PHP behavior
            }
        }

        // Cache the results
        if (updates.Count > 0)
        {
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(CACHE_DURATION);
            _cache.Set(UPDATES_CACHE_KEY, updates, cacheOptions);
        }

        return updates;
    }

    public async Task<Dictionary<string, ContentData>> FetchAllContentAsync()
    {
        // Try to get from cache first
        if (_cache.TryGetValue<Dictionary<string, ContentData>>(CONTENT_CACHE_KEY, out var cachedContent))
        {
            _logger.LogInformation("Returning cached content");
            return cachedContent;
        }

        var content = new Dictionary<string, ContentData>();
        
        foreach (var type in ContentTypes.All)
        {
            using var cmd = _db.CreateCommand(
                "SELECT value, last_updated FROM master_config WHERE page = @page AND key_name = @keyName");
            cmd.Parameters.AddWithValue("@page", type.Page);
            cmd.Parameters.AddWithValue("@keyName", type.KeyName);

            try
            {
                using var reader = await cmd.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    var value = reader.GetString("value");
                    var lastUpdated = reader.GetString("last_updated");

                    // Validate JSON format
                    try
                    {
                        var jsonData = JsonSerializer.Deserialize<object>(value);
                        content[type.KeyName] = new ContentData
                        {
                            Page = type.Page,
                            KeyName = type.KeyName,
                            Data = jsonData,
                            LastUpdated = lastUpdated
                        };
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Invalid JSON format for {Page}/{KeyName}: {Value}", 
                            type.Page, type.KeyName, value);
                        continue; // Skip invalid JSON data
                    }
                }
            }
            catch (MySqlException ex)
            {
                _logger.LogError(ex, "Database error fetching content for {Page}/{KeyName}", 
                    type.Page, type.KeyName);
                continue; // Skip this content type if there's an error, matching PHP behavior
            }
        }

        // Cache the results
        if (content.Count > 0)
        {
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(CACHE_DURATION);
            _cache.Set(CONTENT_CACHE_KEY, content, cacheOptions);
        }

        return content;
    }
} 