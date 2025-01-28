using System.Collections.Concurrent;
using System.Diagnostics;

namespace NayifatAPI.Services;

public interface IMetricsService
{
    void RecordDuration(string operation, TimeSpan duration);
    void IncrementCounter(string metric);
    void RecordValue(string metric, double value);
    Dictionary<string, MetricStats> GetMetrics();
}

public class MetricStats
{
    public long Count { get; set; }
    public double Min { get; set; }
    public double Max { get; set; }
    public double Average { get; set; }
    public double P95 { get; set; }  // 95th percentile
    public DateTime LastUpdated { get; set; }
}

public class MetricsService : IMetricsService
{
    private readonly ILogger<MetricsService> _logger;
    private readonly ConcurrentDictionary<string, ConcurrentBag<double>> _metrics = new();
    private readonly ConcurrentDictionary<string, long> _counters = new();

    public MetricsService(ILogger<MetricsService> logger)
    {
        _logger = logger;
    }

    public void RecordDuration(string operation, TimeSpan duration)
    {
        var milliseconds = duration.TotalMilliseconds;
        _metrics.GetOrAdd(operation, _ => new ConcurrentBag<double>()).Add(milliseconds);
        _logger.LogInformation("{Operation} took {Duration}ms", operation, milliseconds);
    }

    public void IncrementCounter(string metric)
    {
        _counters.AddOrUpdate(metric, 1, (_, count) => count + 1);
        _logger.LogDebug("Counter {Metric} incremented", metric);
    }

    public void RecordValue(string metric, double value)
    {
        _metrics.GetOrAdd(metric, _ => new ConcurrentBag<double>()).Add(value);
        _logger.LogDebug("Metric {Metric} recorded value: {Value}", metric, value);
    }

    public Dictionary<string, MetricStats> GetMetrics()
    {
        var result = new Dictionary<string, MetricStats>();

        foreach (var (metric, values) in _metrics)
        {
            var array = values.ToArray();
            if (array.Length == 0) continue;

            Array.Sort(array);
            var p95Index = (int)Math.Ceiling(array.Length * 0.95) - 1;

            result[metric] = new MetricStats
            {
                Count = array.Length,
                Min = array[0],
                Max = array[^1],
                Average = array.Average(),
                P95 = array[p95Index],
                LastUpdated = DateTime.UtcNow
            };
        }

        foreach (var (counter, count) in _counters)
        {
            result[$"counter_{counter}"] = new MetricStats
            {
                Count = count,
                Min = count,
                Max = count,
                Average = count,
                P95 = count,
                LastUpdated = DateTime.UtcNow
            };
        }

        return result;
    }
} 