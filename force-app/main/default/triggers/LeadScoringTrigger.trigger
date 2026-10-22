trigger LeadScoringTrigger on Lead (before insert) {
    LeadScoringHandler.applyInitialScores(Trigger.new);
}
