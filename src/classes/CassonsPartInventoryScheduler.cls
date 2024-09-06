global without sharing class CassonsPartInventoryScheduler implements Schedulable{
    
    global void execute(SchedulableContext sc) {
        CassonsHerokuService.sendPartInventoryRequest();
        Integer schedulerIntervalInSeconds = (CassonsUtility.getSchedulerInterval()) * 60;
        BPUtility.abortAlreadyScheduleJobs('Cassons Part Inventory Scheduler');
        String cronExp = BPUtility.getCronExpForGivenTime(schedulerIntervalInSeconds);
        system.schedule('Cassons Part Inventory Scheduler', cronExp, new CassonsPartInventoryScheduler());
    }
}