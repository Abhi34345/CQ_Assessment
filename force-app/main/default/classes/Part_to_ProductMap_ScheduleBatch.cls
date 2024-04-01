/**
* Author: Abhinash D.
* Created Date: 20-03-2024
* Last Modified Date: 28-03-2024
* @description: To schedule the Part_to_ProductMap_batch apex based on current loggedin User whose Profile is System Administrator and has a CQ_Product_Admin PermissionSet.
* @TestClass: Part_to_ProductMap_batchTest
*/
global class Part_to_ProductMap_ScheduleBatch implements Schedulable {
    global static string CQ_PRODUCT_ADMIN = 'CQ_Product_Admin';
    global static string PERMISSION_SET_NAME;
    global void execute(SchedulableContext SC) {
        // fetching current loggedin user Id
        String UserId = UserInfo.getUserId();
        
        // Get the permissionset
        List<PermissionSet> CqProductAdminPermission = [SELECT Id,
                                                        Name 
                                                        FROM PermissionSet 
                                                        Where Name = :CQ_PRODUCT_ADMIN];
        if(!CqProductAdminPermission.isEmpty()){
            PERMISSION_SET_NAME = CqProductAdminPermission[0].Name;
        }
        
        // list of permission set assignments for the current logged in user
        List<PermissionSetAssignment> userperm = [SELECT Id, 
                                                  PermissionSetId, 
                                                  PermissionSet.Name, 
                                                  PermissionSet.ProfileId, 
                                                  PermissionSet.Profile.Name, 
                                                  AssigneeId, Assignee.Name 
                                                  FROM PermissionSetAssignment 
                                                  WHERE AssigneeId =: userId  
                                                  AND PermissionSet.Name =: PERMISSION_SET_NAME];
        
        Set<String> ExistingPermSet = new Set<String>();
        for(PermissionSetAssignment PS :userperm ){
            ExistingPermSet.add(PS.PermissionSet.Name);
        }
        if(ExistingPermSet.contains(PERMISSION_SET_NAME)){
            Part_to_ProductMap_batch scheduleBatch = new Part_to_ProductMap_batch();
            Database.executeBatch(scheduleBatch, 200);
        }
    }
}