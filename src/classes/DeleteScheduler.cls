/**
 * Author: Anurag Anand
 * Since: April. 26, 2016
 * Name: DeleteScheduler
 * Description: Apex class which calls methods to delete Active Blank Records.
**/
global class DeleteScheduler implements Schedulable {
   global void execute(SchedulableContext SC) {
      DeleteEmptyRecordsSchedulerCtrl.deleteVOLineItemWhenQuote();
   }
   
   global static void executeDataScheduler(Integer second, Integer minute, Integer hour, Integer day, Integer month, Integer year){}
}