@isTest
global class BillingCalloutServiceMock implements WebServiceMock {
    public static String status = 'OK';
    public static BillingServiceProxy.project lastProject;
    public static String lastEndpoint;
    public static String lastRequestName;

    public static void reset() {
        status = 'OK';
        lastProject = null;
        lastEndpoint = null;
        lastRequestName = null;
    }

    public void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseName,
        String responseNamespace,
        String responseType
    ) {
        lastEndpoint = endpoint;
        lastRequestName = requestName;

        BillingServiceProxy.billProjectRequest_element req = (BillingServiceProxy.billProjectRequest_element) request;
        lastProject = req == null ? null : req.project;

        BillingServiceProxy.billProjectResponse_element resp = new BillingServiceProxy.billProjectResponse_element();
        resp.status = status;
        response.put('response_x', resp);
    }
}