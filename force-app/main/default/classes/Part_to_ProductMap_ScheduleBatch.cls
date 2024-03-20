/**
 * @description: To schedule the Part_to_ProductMap_batch apex.
 * @TestClass Part_to_ProductMap_batchTest
 */
global class Part_to_ProductMap_ScheduleBatch implements Schedulable {
    global void execute(SchedulableContext SC) {
        Part_to_ProductMap_batch scheduleBatch = new Part_to_ProductMap_batch();
        Database.executeBatch(scheduleBatch, 200);
    }
}