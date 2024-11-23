#r "Newtonsoft.Json"

using System;
using System.Net;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System.Text.RegularExpressions;

public static async Task<IActionResult> Run(HttpRequest req, ILogger log)
{
    string url = req.Query["url"];
    if (string.IsNullOrEmpty(url))
    {
        string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
        dynamic data = JsonConvert.DeserializeObject(requestBody);
        url = data?.url;
    }

    log.LogInformation($"Processing URL: {url}");

    if (IsIpAddress(url))
    {
        return new OkObjectResult(ExtractIpAddress(url));
    }
    else
    {
        return new OkObjectResult(await GetIpAddressesFromDomain(url, log));
    }
}

private static bool IsIpAddress(string input)
{
    string ipPattern = @"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}.*$";
    input = Regex.Replace(input, @"^(https?://)", "");
    return IPAddress.TryParse(input, out _) || Regex.IsMatch(input, ipPattern);
}

public static string ExtractIpAddress(string input)
{
    string ipPattern = @"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}";
    input = Regex.Replace(input, @"^(https?://)", "");
    Match match = Regex.Match(input, ipPattern);
    return match.Success ? $"[\"{match.Value}\"]" : "No valid IP address found.";
}

private static async Task<string> GetIpAddressesFromDomain(string url, ILogger log)
{
    Uri uri = new Uri(url);
    string domain = uri.Host;

    try
    {
        IPHostEntry hostEntry = await Dns.GetHostEntryAsync(domain);
        string[] ipArray = hostEntry.AddressList.Select(ip => ip.ToString()).ToArray();
        return JsonConvert.SerializeObject(ipArray);
    }
    catch (Exception ex)
    {
        log.LogError($"DNS Query failed with message: {ex.Message}");
        return JsonConvert.SerializeObject($"DNS Query failed with message: {ex.Message}");
    }
}