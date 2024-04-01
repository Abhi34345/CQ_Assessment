/**
 * Author: Abhinash D.
 * Created Date: 20-03-2024
 * Last Modified Date: 28-03-2024
 * Description: Test class for Part_to_ProductMap_batch class.
 *              This class tests the functionality of the Part_to_ProductMap_batch class.
 **/

@isTest
private class Part_to_ProductMap_batchTest {
    
    /**
     * Description: Test data setup method.
     *              This method creates test data required for the test methods.
     **/
    @testSetup
    static void setupTestData() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User admindUser = new User(Alias = 'standt', 
                                     Email='standarduser@testorg.com', 
                                     EmailEncodingKey='UTF-8', 
                                     LastName='Testing', 
                                     LanguageLocaleKey='en_US', 
                                     LocaleSidKey='en_US', 
                                     ProfileId = standardProfile.Id, 
                                     TimeZoneSidKey='America/Los_Angeles', 
                                     UserName='testStandarduser@#org.com');
        insert admindUser;
        
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'CQ_Product_Admin'];
        insert new PermissionSetAssignment(AssigneeId = admindUser.Id, PermissionSetId = ps.Id);
        
        System.runAs(admindUser) {
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
        }
    }
	
	/**
     * Description: Test method to verify the Parts with Products method.
     *              This method tests the Products with Parts Name, Part Number and will Map the Product with the Particular Part.
     **/    
    testmethod static void testPartWithProductMapping() {
        
        User admindUser = [Select Id, Name, ProfileId, Profile.Name from User Where Profile.Name='System Administrator' LIMIT 1];
        
        System.runAs(admindUser) {
            
            SQX_Part__c part =[SELECT Id, Name, Part_Number__c, SQX_Product__c FROM SQX_Part__c WHERE Active__c = true AND Name = 'Part 1' limit 1];
            List<Product2> prodtList =[SELECT Id, Name, ProductCode FROM Product2 WHERE Name = :part.Name AND ProductCode =: part.Part_Number__c];
            
            // Execute the batch job
            Test.startTest();
            Part_to_ProductMap_batch batchJob = new Part_to_ProductMap_batch();
            //ACT: Execute the batch job
            Database.executeBatch(batchJob);
            
            //ACT: Scheduling the Part_to_ProductMap_ScheduleBatch batch class
            Part_to_ProductMap_ScheduleBatch batch = new Part_to_ProductMap_ScheduleBatch();
            string sch = '0 0 6 * * ?'; // CRON expression
            system.schedule('Schedule Batch',sch, batch);
            Test.stopTest();
            
            //ASSERT: Asserting the Part Name and Product Name
            system.assert(prodtList.size() > 0,'There is no Product realted to Part record');
            system.assertEquals(part.Name,prodtList[0].Name,'Product record should be created');
            system.assertEquals(part.Part_Number__c,prodtList[0].ProductCode,'Product record should be created');
        }
    }
    
    
    /**
     * Description: Test method to verify the Parts with out Products method.
     *              This method tests the Products with Parts Name, Part Number. 
     * 				If Product not present will create the new Product based on Part Name, Nummber and than Map that new Product with the Particular Part.
     **/
    testmethod static void testPartWithOutProductMapping() {
        
        User admindUser = [Select Id, Name, ProfileId, Profile.Name from User Where Profile.Name='System Administrator' LIMIT 1];
        
        System.runAs(admindUser) {
            
            SQX_Part__c part =[SELECT Id, Name, Part_Number__c, SQX_Product__c FROM SQX_Part__c WHERE Active__c = true AND Name = 'Part 2' limit 1];
            List<Product2> prodtList =[SELECT Id, Name, ProductCode FROM Product2 WHERE Name = :part.Name AND ProductCode =: part.Part_Number__c];
            
            // Execute the batch job
            Test.startTest();
            Part_to_ProductMap_batch batchJob = new Part_to_ProductMap_batch();
            //ACT: Execute the batch job
            Database.executeBatch(batchJob);
            
            //ACT: Scheduling the Part_to_ProductMap_ScheduleBatch batch class
            Part_to_ProductMap_ScheduleBatch batch = new Part_to_ProductMap_ScheduleBatch();
            string sch = '0 0 6 * * ?'; // CRON expression
            system.schedule('Schedule Batch',sch, batch);
            Test.stopTest();
           
            //ASSERT: Asserting the Size of Product List
            system.assert(prodtList.size() <= 0,'There is no Product realted to Part record');
        }
    }
}