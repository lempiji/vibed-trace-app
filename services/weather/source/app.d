import vibe.vibe;
import std.conv : to;
import std.process : environment;
import std.typecons : Nullable;
import std.format : format;

void main()
{
    logInfo("Start Application Server");

    auto host = environment.get("HOST", "0.0.0.0");
    auto port = to!ushort(environment.get("PORT", "80"));

    auto settings = new HTTPServerSettings;
    settings.port = port;
    settings.bindAddresses = [host];

    auto router = new URLRouter;
    router.get("/health", &checkHealth); // GET /health
    router.get("/weather", &getWeather); // GET /weather?city=Tokyo

    scope listener = listenHTTP(settings, router);
    scope (exit)
        listener.stopListening();

    runApplication();
}

void checkHealth(scope HTTPServerRequest, scope HTTPServerResponse res)
{
    res.writeJsonBody(["status": "healthy"], 200);
}

void getWeather(scope HTTPServerRequest req, scope HTTPServerResponse res)
{
    const city = req.query.get("city", "");
    if (city == "")
    {
        res.writeJsonBody(["message": "Bad Request"], 400);
        return;
    }

    if (environment.get("OPENWEATHER_APIKEY", "") != "")
    {
        auto resJson = fetchWeather(city, req.headers);
        res.writeJsonBody(resJson, 200);
        return;
    }

    import std.datetime;
    import std.format;
    import std.random;

    const currentDay = cast(Date) Clock.currTime();
    version (VERSION_3)
        const weather = choice(["Sunny", "Cloud", "Rain", "Snow", "Thunder"]);
    else version (VERSION_2)
        const weather = choice(["Sunny", "Cloud", "Rain", "Snow"]);
    else
        const weather = choice(["Sunny", "Cloud", "Rain"]);

    Json[string] resJson;
    resJson["city"] = city;
    resJson["datetime"] = format!"%d-%d-%d 12:00:00"(currentDay.year, currentDay.month, currentDay
            .day);
    resJson["weather"] = weather;

    res.writeJsonBody(resJson, 200);
}

/++
Fetch the weather from the Open Weather's API

See_Also: https://openweathermap.org
+/
Json fetchWeather(string city, InetHeaderMap requestHeaders)
{
    import std.format : format;

    // See https://home.openweathermap.org/api_keys
    const encodedCity = city.formEncode();
    const apiKey = environment.get("OPENWEATHER_APIKEY").formEncode();

    const url = format!"https://api.openweathermap.org/data/2.5/forecast?q=%s&appid=%s"(
            encodedCity, apiKey);

    auto settings = new HTTPClientSettings;
    settings.readTimeout = 5.seconds;

    scope response = requestHTTP(url, (scope clientReq) {
        forwardHeaders(requestHeaders, clientReq.headers);
    }, settings);

    const json = response.readJson();
    const cityName = json["city"]["name"];
    const datetime = json["list"][0]["dt_txt"];
    const weather = json["list"][0]["weather"][0]["main"];

    Json[string] resJson = [
        "city": cityName,
        "datetime": datetime,
        "weather": weather,
    ];

    return Json(resJson);
}

void forwardHeaders(scope const InetHeaderMap req, scope InetHeaderMap clientReq)
{
    // dfmt off
    enum shouldForwardHeaders = [
        // Istio
        "X-Request-ID",

        // W3C Trace Context
        "traceparent",
        "tracestate",

        // Datadog
        "X-Datadog-Trace-ID",
        "X-Datadog-Parent-ID",
        "X-Datadog-Sampling-Priority",

        // Cloud trace context
        "X-Cloud-Trace-Context",

        // b3 trace headers
        "X-B3-TraceId",
        "X-B3-SpanId",
        "X-B3-ParentSpanId",
        "X-B3-Sampled",
        "X-B3-Flags",

        // Lightstep Tracer
        "x-ot-span-context",

        // gRPC binary trace context
        "grpc-trace-bin",
    ];
    // dfmt on

    foreach (key; shouldForwardHeaders)
    {
        const value = req.get(key);
        if (value != "")
        {
            clientReq[key] = value;
        }
    }
}
