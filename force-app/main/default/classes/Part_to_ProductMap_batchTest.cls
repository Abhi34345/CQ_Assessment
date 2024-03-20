@isTest
private class Part_to_ProductMap_batchTest {
    
    testmethod static void testPartToProductMapping() {
        // Setup test data        
        // This code runs as the system user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User standardUser = new User(Alias = 'standt', 
                          Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', 
                          LastName='Testing', 
                          LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', 
                          ProfileId = standardProfile.Id, 
                          TimeZoneSidKey='America/Los_Angeles', 
                          UserName='testStandarduser@#org.com');
        insert standardUser;
        
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'CQ_Product_Admin'];
        insert new PermissionSetAssignment(AssigneeId = standardUser.Id, PermissionSetId = ps.Id);
        
        System.runAs(standardUser) {
            SQX_Part__c partRec = new SQX_Part__c(Name = 'Part 1', 
                                                  Part_Number__c = 'PN1', 
                                                  Active__c = true);
            
            insert partRec;
            
            SQX_Part__c partRec2 = new SQX_Part__c(Name = 'Part 2', 
                                                   Part_Number__c = 'PN2', 
                                                   Active__c = true);
            
            insert partRec2;
            
            Product2 productRec = new Product2(Name = 'Part 1', 
                                               ProductCode = 'PN1', 
                                               IsActive = true);
            
            insert productRec;
            
            SQX_Part__c part =[SELECT Id, Name, SQX_Product__c FROM SQX_Part__c WHERE Active__c = true AND Name = 'Part 1' limit 1];
            List<Product2> prodtList =[SELECT Id FROM Product2 WHERE Id = :part.SQX_Product__c];
            //ASSERT: Asserting the count of product
            system.assertEquals(0,prodtList.Size(),'No Products to create');
            
            // Execute the batch job
            Test.startTest();
            Part_to_ProductMap_batch batchJob = new Part_to_ProductMap_batch();
            //ACT: Execute the batch job
            Database.executeBatch(batchJob);
            Part_to_ProductMap_ScheduleBatch batch = new Part_to_ProductMap_ScheduleBatch();
            string sch = '0 0 6 * * ?';
            system.schedule('test',sch, batch);
            Test.stopTest();
            
            part =[SELECT Id, Name, SQX_Product__c FROM SQX_Part__c WHERE Active__c = true AND Name = 'Part 1' limit 1];
            prodtList =[SELECT Id FROM Product2 WHERE Id = :part.SQX_Product__c];
            //ASSERT: Asserting the count of product
            system.assertEquals(1,prodtList.Size(),'Product record should be created');
        }
    }
}