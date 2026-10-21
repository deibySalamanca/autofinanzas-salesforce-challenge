trigger OpportunityTrigger on Opportunity (before update) {

    // Delegamos la lógica en el Trigger Handler.
    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityTriggerHandler.beforeUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }
}