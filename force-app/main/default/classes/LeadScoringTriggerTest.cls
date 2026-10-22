@isTest
private class LeadScoringTriggerTest {
    @isTest
    static void baseScoreIsTen() {
        Lead leadRecord = new Lead(FirstName = 'Test', LastName = 'Base', Company = 'Base Co');

        Test.startTest();
        insert leadRecord;
        Test.stopTest();

        Lead inserted = [SELECT Initial_Score__c FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals(10, inserted.Initial_Score__c.intValue(), 'Base score should be 10');
    }

    @isTest
    static void webTechnologyAndEmployeesScoreEightyFive() {
        Lead leadRecord = new Lead(
            FirstName = 'Test',
            LastName = 'Combo',
            Company = 'Combo Co',
            LeadSource = 'Web',
            Industry = 'Technology',
            NumberOfEmployees = 150
        );

        Test.startTest();
        insert leadRecord;
        Test.stopTest();

        Lead inserted = [SELECT Initial_Score__c FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals(
            85,
            inserted.Initial_Score__c.intValue(),
            'Web + Technology + 150 employees should score 85'
        );
    }

    @isTest
    static void scoreIsCappedAtOneHundred() {
        Lead leadRecord = new Lead(
            FirstName = 'Test',
            LastName = 'Max',
            Company = 'Max Co',
            LeadSource = 'Web',
            Industry = 'Finance',
            NumberOfEmployees = 500,
            Rating = 'Hot'
        );

        Test.startTest();
        insert leadRecord;
        Test.stopTest();

        Lead inserted = [SELECT Initial_Score__c FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals(
            100,
            inserted.Initial_Score__c.intValue(),
            'Score should be capped at 100'
        );
    }

    @isTest
    static void bulkInsertAssignsScores() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(
                new Lead(
                    FirstName = 'Bulk',
                    LastName = 'Lead ' + i,
                    Company = 'Bulk Co ' + i,
                    LeadSource = 'Web'
                )
            );
        }

        Test.startTest();
        insert leads;
        Test.stopTest();

        Set<Id> leadIds = new Map<Id, Lead>(leads).keySet();
        List<Lead> inserted = [SELECT Initial_Score__c FROM Lead WHERE Id IN :leadIds];
        System.assertEquals(200, inserted.size(), 'All 200 leads should be inserted');
        for (Lead leadRecord : inserted) {
            System.assertEquals(35, leadRecord.Initial_Score__c.intValue(), 'Web leads should score 35');
        }
    }

    @isTest
    static void updateDoesNotRecalculateScore() {
        Lead leadRecord = new Lead(FirstName = 'Test', LastName = 'Update', Company = 'Update Co');
        insert leadRecord;

        leadRecord = [SELECT Id, Initial_Score__c FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals(10, leadRecord.Initial_Score__c.intValue(), 'Insert should score 10');

        leadRecord.Initial_Score__c = 5;

        Test.startTest();
        update leadRecord;
        Test.stopTest();

        Lead updated = [SELECT Initial_Score__c FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals(5, updated.Initial_Score__c.intValue(), 'Trigger should not run on update');
    }
}
