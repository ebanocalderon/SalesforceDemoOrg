@isTest
global class RewardsCalloutServiceMock implements HttpCalloutMock {
    public static Integer statusCode = 200;
    public static String responseBody = '{"status":"ok"}';
    public static HttpRequest lastRequest;

    public HTTPResponse respond(HTTPRequest req) {
        lastRequest = req;
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(responseBody);
        return res;
    }

    public static void reset() {
        statusCode = 200;
        responseBody = '{"status":"ok"}';
        lastRequest = null;
    }
}