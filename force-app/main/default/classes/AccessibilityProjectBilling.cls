global class AccessibilityProjectBilling{
    
     @future(callout=true)
   public static void callBillingService(String projectId, Decimal billingAmount){
         BillingServiceProxy.InvoicesPortSoap11 service = new BillingServiceProxy.InvoicesPortSoap11();
         BillingServiceProxy.project project = new BillingServiceProxy.project();
         project.projectid = projectId;
         project.billAmount = billingAmount == null ? null : Double.valueOf(billingAmount);
         project.username = '{!$Credential.BillingServiceCredential.username}';
         project.password = '{!$Credential.BillingServiceCredential.password}';

         String status = service.billProject(project);
         if (status != null && projectId != null) {
               Accessibility_Project__c updateProject = new Accessibility_Project__c(
                    Id = projectId,
                    Status__c = 'Complete'
               );
               update updateProject;
          }
            
    }
}