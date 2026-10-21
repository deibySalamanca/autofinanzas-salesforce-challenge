public without sharing class OpportunitySelector {

    public static List<Opportunity> selectByIds(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return new List<Opportunity>();
        }

        return [
            SELECT Id, AccountId, Amount, StageName,
                   Description, Vehicle_Count__c,
                   Discount__c, Credit_Score__c,
                   Credit_Status__c,
                   Account.Customer_Segment__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];
    }

    
    public static Map<Id, Account> selectAccountsByIds(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new Map<Id, Account>();
        }

        return new Map<Id, Account>([
            SELECT Id, Customer_Segment__c
            FROM Account
            WHERE Id IN :accountIds
        ]);
    }
}