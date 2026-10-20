@isTest
private class RewardsCalloutServiceTestCopy {
    private static Date getStartDate() {
        Date today = Date.today();
        Integer currentYear = today.year();
        Integer currentMonth = today.month();
        Integer previousQuarterStartMonth = ((currentMonth - 1) / 3) * 3 + 1 - 3;

        if (previousQuarterStartMonth <= 0) {
            previousQuarterStartMonth += 12;
            currentYear--;
        }

        return Date.newInstance(currentYear, previousQuarterStartMonth, 1);
    }

    private static Date getEndDate() {
        Date previousQuarterStartDate = getStartDate();
        return previousQuarterStartDate.addMonths(3).addDays(-1);
    }

    private static List<Wellness_Journey__c> buildJourneys(Integer count, Id ownerId) {
        Date startDate = getStartDate();
        Date endDate = getEndDate();
        List<Wellness_Journey__c> journeys = new List<Wellness_Journey__c>();

        for (Integer i = 0; i < count; i++) {
            Date completionDate = startDate.addDays(i);
            if (completionDate > endDate) {
                completionDate = endDate;
            }

            Wellness_Journey__c journey = new Wellness_Journey__c();
            if (Schema.sObjectType.Wellness_Journey__c.fields.Name.isCreateable()) {
                journey.Name = 'Journey ' + i;
            }
            journey.OwnerId = ownerId;
            journey.Status__c = 'Complete';
            journey.Completion_Date__c = completionDate;
            journeys.add(journey);
        }

        return journeys;
    }

    private static User createTestUser() {
        String unique = String.valueOf(Datetime.now().getTime());
        String shortUnique = unique.substring(unique.length() - 6);
        String alias = 't' + shortUnique;
        String nickname = 'nick' + shortUnique;
        String email = 'test.user.' + unique + '@example.com';

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = email,
            Username = email,
            Alias = alias,
            CommunityNickname = nickname,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = UserInfo.getProfileId()
        );
        insert u;
        return u;
    }

    @isTest
    static void testSubmitUsersForRewardCallout_success() {
        RewardsCalloutServiceMock.reset();
        RewardsCalloutServiceMock.statusCode = 201;
        RewardsCalloutServiceMock.responseBody = '{"result":"ok"}';

        Test.setMock(HttpCalloutMock.class, new RewardsCalloutServiceMock());

        Integer statusCode = RewardsCalloutService.submitUsersForRewardCallout('[{"userId":"005000000000000","fullName":"Test User","email":"test@example.com","username":"test.user"}]');

        System.assertEquals(201, statusCode);
        System.assertNotEquals(null, RewardsCalloutServiceMock.lastRequest);
        System.assertEquals('POST', RewardsCalloutServiceMock.lastRequest.getMethod());
        System.assert(RewardsCalloutServiceMock.lastRequest.getEndpoint().contains('callout:IntegrationSB__BalancedLiving/rewards'));
    }

    @isTest
    static void testSubmitUsersForRewardCallout_error() {
        RewardsCalloutServiceMock.reset();
        RewardsCalloutServiceMock.statusCode = 503;
        RewardsCalloutServiceMock.responseBody = '{"error":"unavailable"}';

        Test.setMock(HttpCalloutMock.class, new RewardsCalloutServiceMock());

        Integer statusCode = RewardsCalloutService.submitUsersForRewardCallout('');
        System.assertEquals(503, statusCode);
        System.assertEquals('[]', RewardsCalloutServiceMock.lastRequest.getBody());
    }

    @isTest
    static void testBatchSerializesEligibleUsers() {
        Date startDateCopy = getStartDate();
        Date endDateCopy = getEndDate();
        System.debug('startDateCopy=' + startDateCopy + ', endDateCopy=' + endDateCopy);

        User testUser = createTestUser();
        String expectedFullName = testUser.FirstName + ' ' + testUser.LastName;
        List<Wellness_Journey__c> journeys = buildJourneys(12, testUser.Id);
        insert journeys;

        RewardsCalloutServiceMock.reset();
        Test.setMock(HttpCalloutMock.class, new RewardsCalloutServiceMock());

        Test.startTest();
        Database.executeBatch(new WellnessJourneyRewardsBatch(), 200);
        Test.stopTest();

        System.assertNotEquals(null, RewardsCalloutServiceMock.lastRequest);

        List<Object> payload = (List<Object>) JSON.deserializeUntyped(RewardsCalloutServiceMock.lastRequest.getBody());
        System.assertEquals(1, payload.size());

        Map<String, Object> userObj = (Map<String, Object>) payload[0];
        System.assertEquals(String.valueOf(testUser.Id), (String) userObj.get('userId'));
        System.assertEquals(expectedFullName, (String) userObj.get('fullName'));
        System.assertEquals(testUser.Email, (String) userObj.get('email'));
        System.assertEquals(testUser.Username, (String) userObj.get('username'));
    }
}