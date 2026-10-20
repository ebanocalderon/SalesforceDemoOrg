@isTest
private class BillingCalloutServiceTest {
    @isTest
    static void testCallBillingService_success() {
        BillingCalloutServiceMock.reset();
        BillingCalloutServiceMock.status = 'OK';
        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock());

        Accessibility_Project__c project = new Accessibility_Project__c(
            OwnerId = UserInfo.getUserId(),
            Amount__c = 150
        );
        insert project;

        Test.startTest();
        AccessibilityProjectBilling.callBillingService(project.Id, project.Amount__c);
        Test.stopTest();

        Accessibility_Project__c updated = [
            SELECT Status__c
            FROM Accessibility_Project__c
            WHERE Id = :project.Id
        ];
        System.assertEquals('Complete', updated.Status__c);

        System.assertNotEquals(null, BillingCalloutServiceMock.lastProject);
        System.assertEquals(project.Id, BillingCalloutServiceMock.lastProject.projectid);
        System.assertEquals(Double.valueOf(project.Amount__c), BillingCalloutServiceMock.lastProject.billAmount);
    }

    @isTest
    static void testCallBillingService_nullStatusAndAmount() {
        BillingCalloutServiceMock.reset();
        BillingCalloutServiceMock.status = null;
        Test.setMock(WebServiceMock.class, new BillingCalloutServiceMock());

        Accessibility_Project__c project = new Accessibility_Project__c(
            OwnerId = UserInfo.getUserId(),
            Amount__c = 75
        );
        insert project;

        String initialStatus = [
            SELECT Status__c
            FROM Accessibility_Project__c
            WHERE Id = :project.Id
        ].Status__c;

        Test.startTest();
        AccessibilityProjectBilling.callBillingService(project.Id, null);
        Test.stopTest();

        Accessibility_Project__c updated = [
            SELECT Status__c
            FROM Accessibility_Project__c
            WHERE Id = :project.Id
        ];
        System.assertEquals(initialStatus, updated.Status__c);
        System.assertEquals(null, BillingCalloutServiceMock.lastProject.billAmount);
    }
}