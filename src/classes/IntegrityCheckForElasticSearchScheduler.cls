global without sharing class IntegrityCheckForElasticSearchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {}
    global void executeEmailScheduler(String cronExp) {}
}