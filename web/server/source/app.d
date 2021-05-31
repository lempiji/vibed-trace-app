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
	registerWebInterface(router, new AppServer);
	router.get("*", serveStaticFiles("public"));

    scope listener = listenHTTP(settings, router);
    scope (exit)
        listener.stopListening();

    runApplication();
}

void checkHealth(scope HTTPServerRequest, scope HTTPServerResponse res)
{
    res.writeJsonBody(["status": "healthy"], 200);
}

class AppServer
{
	void index(scope HTTPServerRequest req, scope HTTPServerResponse res)
	{
		res.redirect("/index.html");
	}

    @method(HTTPMethod.GET)
    @path("/api/weather")
    void getWeather(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const city = req.query.get("city", "");
        if (city == "")
        {
            res.writeJsonBody(["message": "Bad Request"], 400);
            return;
        }

        import std.format : format;

        const service = environment.get("WEATHER_SERVICE", "http://weather-service");
        const url = format!"%s/weather?city=%s"(service, formEncode(city));
        scope response = requestHTTP(url, (scope HTTPClientRequest clientReq) {
            forwardHeaders(req.headers, clientReq.headers);
        });

        if (response.statusCode == 200) {
            const json = response.readJson();
            res.writeJsonBody(json, 200);
            return;
        }

        res.writeJsonBody(["message": "Internal Server Error"], 500);
    }
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
