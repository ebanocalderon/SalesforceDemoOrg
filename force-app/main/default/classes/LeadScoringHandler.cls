public with sharing class LeadScoringHandler {
    private static final Integer BASE_SCORE = 10;
    private static final Integer SCORE_BOOST = 25;
    private static final Integer MAX_SCORE = 100;

    public static void applyInitialScores(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        for (Lead leadRecord : leads) {
            Integer score = BASE_SCORE;
            if (leadRecord.LeadSource == 'Web') {
                score += SCORE_BOOST;
            }
            if (leadRecord.Industry == 'Technology' || leadRecord.Industry == 'Finance') {
                score += SCORE_BOOST;
            }
            if (leadRecord.NumberOfEmployees != null && leadRecord.NumberOfEmployees >= 100) {
                score += SCORE_BOOST;
            }
            if (leadRecord.Rating == 'Hot') {
                score += SCORE_BOOST;
            }
            leadRecord.Initial_Score__c = score > MAX_SCORE ? MAX_SCORE : score;
        }
    }
}
