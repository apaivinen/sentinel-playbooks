#r "Newtonsoft.Json"

using System;
using System.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Primitives;
using Newtonsoft.Json;
using System.Text.RegularExpressions;

public static async Task<IActionResult> Run(HttpRequest req, ILogger log)
{
    log.LogInformation("**********************************************");
    log.LogInformation("C# HTTP trigger function processed a request.");
    log.LogInformation("**********************************************");

    string url = req.Query["url"];

    string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
    dynamic data = JsonConvert.DeserializeObject(requestBody);
    url = url ?? data?.url;
    log.LogInformation("Got url: " + url);

    // Check if it's IP or domain
    bool isIpAddress = IsIpAddress(url);
    log.LogInformation("is url IP? " + isIpAddress);
    if (!isIpAddress)
    {

        log.LogInformation("Parsing url to queryable form");
        Uri uri = new Uri(url);
        string host = uri.Host;
        string[] parts = host.Split('.');
        string domain = string.Join(".", parts.Skip(Math.Max(0, parts.Length - 2)));
        List<string> subdomainParts = parts.Take(parts.Length - 2).ToList();

        // Remove 'www' from the subdomain parts
        subdomainParts.RemoveAll(part => part.ToLower() == "www");

        string subdomain = string.Join(".", subdomainParts);
        string fullDomain = subdomain.Length > 0 ? subdomain + "." + domain : domain;

        log.LogInformation("Url parsed to domain: " + fullDomain);

        // DNS Query
        log.LogInformation("Starting DNS query");
        IPHostEntry hostEntry = null;
        string errorMessage = null;
        try
        {
            hostEntry = await Dns.GetHostEntryAsync(fullDomain);
            log.LogInformation("DNS Query done");
        }
        catch (Exception ex)
        {
            errorMessage = $"DNS Query failed with message: {ex.Message} ";
            log.LogError(errorMessage);
            return new OkObjectResult(JsonConvert.SerializeObject($"{errorMessage}"));
        }

        log.LogInformation("Starting to parse DNS results");
        IPAddress[] address = hostEntry.AddressList;
        var ipArray = address.Select(ip => ip.ToString()).ToArray();

        log.LogInformation("The end. Returning array of IP addresses to caller.");
        return new OkObjectResult(JsonConvert.SerializeObject(ipArray));
    }// if ends
    else// If url contains IP address
    {
        return new OkObjectResult(ExtractIpAddress(url));
    }// else ends

}

// Check if provided value contains IP address
private static bool IsIpAddress(string input)
{
    // Regular expression pattern for IPv4 addresses
    string ipPattern = @"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}.*$";

    // Remove any "https://" or "http://" prefixes from the input
    input = Regex.Replace(input, @"^(https?://)", "");

    return IPAddress.TryParse(input, out _)
        || Regex.IsMatch(input, ipPattern);
}

// Extract IP Address from input
// Examples for input:
// 192.168.1.1
// http://192.168.1.1
// https://192.168.1.1
// https://192.168.1.1/demo
//
//Examples for return value:
//["192.168.1.1"]
public static string ExtractIpAddress(string input)
{
    // Regular expression pattern for IPv4 addresses
    string ipPattern = @"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}";
    // Remove any "https://" or "http://" prefixes from the input
    input = Regex.Replace(input, @"^(https?://)", "");
    string ip;

    // Find the IP address in the input
    Match match = Regex.Match(input, ipPattern);
    if (match.Success)
    {
        ip = "[\"" + match.Value + "\"]";
        return ip;
    }
    else
    {
        return "No valid IP address found.";
    }
}
