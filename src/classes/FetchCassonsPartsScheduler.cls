global without sharing class FetchCassonsPartsScheduler implements Schedulable {
    public Integer startIndex = 1;
    public FetchCassonsPartsScheduler(Integer startIndex){
        this.startIndex = startIndex;
    }
    global void execute(SchedulableContext sc) {
        CassonsHerokuService.fetchPartsFromHeroku(this.startIndex);
    }
}