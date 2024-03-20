/**
 * @description: To associate active parts with their product records.
 * @TestClass Part_to_ProductMap_batchTest
 */
global with sharing class Part_to_ProductMap_batch implements Database.Batchable<sObject>{
	
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id, Name, Part_Number__c, Active__c, SQX_Product__c FROM SQX_Part__c WHERE Active__c = true AND SQX_Product__c = null with SECURITY_ENFORCED';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SQX_Part__c> partsList){
        Set<String> partName = new Set<String>();// partName is set of Strings which stores the Name of SQX_Part__c
        Set<String> partNumber = new Set<String>();// partNumber is set of Strings which stores the Part_Number__c of SQX_Part__c
        Map<String,String> productName_ProductCode_Map = new Map<String,String>();
        List<SQX_Part__c> partsToUpdate = new List<SQX_Part__c>();// parts list to update
        List<Product2> newProductList = new List<Product2>();// products list to insert
        String partName_PartNumber_Key;
        
        for(SQX_Part__c partRec : partsList){
            if(partRec.Name != null && partRec.Part_Number__c != null){
                partName.add(partRec.Name);
                partNumber.add(partRec.Part_Number__c);
            }
        }
        // List of products based on product Name and productCode
        List<Product2> productList = [SELECT Id, Name, ProductCode FROM Product2 WHERE Name IN :partName AND ProductCode IN: partNumber];
        
        for(Product2 productRec : productList){
            if(productRec.Name != null && productRec.ProductCode != null){
                productName_ProductCode_Map.put(productRec.Name+'-'+productRec.ProductCode, productRec.Id);
            }
        }
        
        // Iterate through parts and update or create products
        for(SQX_Part__c partRec : partsList){
            if(partRec.Name != null && partRec.Part_Number__c != null){
                partName_PartNumber_Key = partRec.Name + '-' + partRec.Part_Number__c;
            }
            if(!productName_ProductCode_Map.containsKey(partName_PartNumber_Key)){
                // Product does not exist, create new product
                Product2 newProduct = new Product2(Name = partRec.Name, 
                                                   ProductCode = partRec.Part_Number__c, 
                                                   IsActive = true);
                newProductList.add(newProduct);
            }
        }
        
        if(newProductList.size()>0){
            insert newProductList;
            for(Product2 prod : newProductList){
                if(prod.Name != null && prod.ProductCode != null){
                    productName_ProductCode_Map.put(prod.Name+'-'+prod.ProductCode, prod.Id);
                }
            }
        }
        
        for(SQX_Part__c partRec : partsList){
            if(partRec.Name != null && partRec.Part_Number__c != null){
                partName_PartNumber_Key = partRec.Name + '-' + partRec.Part_Number__c;
            }
            if(productName_ProductCode_Map.containsKey(partName_PartNumber_Key)){
                // Product exists, update part with product reference
                partRec.SQX_Product__c = productName_ProductCode_Map.get(partName_PartNumber_Key);
                partsToUpdate.add(partRec);
            } 
        }
        
        if(partsToUpdate.size()>0){
            update partsToUpdate;
        }
       
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}