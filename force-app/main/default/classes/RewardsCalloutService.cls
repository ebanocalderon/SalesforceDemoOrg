public class RewardsCalloutService{

    public static Integer submitUsersForRewardCallout(String jsonBody) {
        // Set endpoint from named credential
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:IntegrationSB__BalancedLiving/rewards');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(String.isBlank(jsonBody) ? '[]' : jsonBody);

        // Make HTTP callout
        Http http = new Http();
        HttpResponse response = http.send(request);

        // Return response status code
        return response.getStatusCode();
    }
}