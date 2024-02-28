#r "Newtonsoft.Json"

using System.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Primitives;
using Newtonsoft.Json;

public static async Task<IActionResult> Run(HttpRequest req, ILogger log)
{
    log.LogInformation("**********************************************");
    log.LogInformation("C# HTTP trigger function processed a request.");
    log.LogInformation("**********************************************");

    string url = req.Query["url"];

    string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
    dynamic data = JsonConvert.DeserializeObject(requestBody);
    url = url ?? data?.url;
    log.LogInformation("Got url: "+url);

}