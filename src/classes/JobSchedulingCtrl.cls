/**
 * Author: Pooja Khandelwal
 * Since: Jul 27, 2017
 * Name: JobSchedulingCtrl
 * Description: Apex class to handle schedule event calendar related oprations of Job Schedule 
 **/
global without sharing class JobSchedulingCtrl{
    
    private static DateTime StartCalendarViewDateTime;
    private static DateTime EndCalendarViewDateTime;
    private static JobSchedulingWrapper eventJsonObj;
    public string SchedulingDateFormat { get{return Constants.localeToschedulingDateFmtMap.containsKey(UserInfo.getLocale())? Constants.localeToschedulingDateFmtMap.get(UserInfo.getLocale()): Constants.localeToschedulingDateFmtMap.get('en_US'); } private set;}
    public Decimal SchedulingStartDay { get{return GeneralConfiguration.getSchedulerStartDay(); } private set;}
    global JobSchedulingCtrl(NewHomePageCtrl controller){}
    public JobSchedulingCtrl() {} 
    
    //Depricated 
    @remoteAction
    global static String loadJobSchedulingEvents(){
        return BPUtility.getEncodedString('');
    }
     
    @remoteAction
    global static String loadSchedulingEvents(String eventJson){
        eventJson = BPUtility.getDecodedString(eventJson);
        if(!AccessControl.ifObjectFieldIsAccessible('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        try {
            eventJsonObj = (JobSchedulingWrapper)System.JSON.deserialize(eventJson, JobSchedulingWrapper.class);
            if(eventJsonObj.StartCalendarViewDate != null && eventJsonObj.StartCalendarViewDate != '') {
                if(eventJsonObj.StartCalendarViewTime != null && eventJsonObj.StartCalendarViewTime != '') {
                    StartCalendarViewDateTime = getConvertedDateTime(eventJsonObj.StartCalendarViewDate, eventJsonObj.StartCalendarViewTime);
                } else {
                    StartCalendarViewDateTime = getConvertedDateTime(eventJsonObj.StartCalendarViewDate, '12:00AM');
                }
            }
            if(eventJsonObj.EndCalendarViewDate != null && eventJsonObj.EndCalendarViewDate != '') {
                if(eventJsonObj.EndCalendarViewTime != null && eventJsonObj.EndCalendarViewTime != '') {
                    EndCalendarViewDateTime = getConvertedDateTime(eventJsonObj.EndCalendarViewDate, eventJsonObj.EndCalendarViewTime);
                } else {
                    EndCalendarViewDateTime = getConvertedDateTime(eventJsonObj.EndCalendarViewDate, '11:59PM');
                }
            }
            String JSONString;
            if(eventJsonObj.Id != null) {
                List<Event__c> eventList = getEventWithId();
                List<JobSchedulingWrapper> eventListJson = new List<JobSchedulingWrapper>();
                if(eventList.size() > 0) {
                    if(!eventList[0].Is_MultiDay__c) {
                        eventListJson.add(new JobSchedulingWrapper(eventList[0]));
                    } else {
                        eventListJson.add(new JobSchedulingWrapper(eventList[0], StartCalendarViewDateTime, EndCalendarViewDateTime));
                    }
                }
                JSONString = System.JSON.serialize(eventListJson);
            } else {
                List<JobSchedulingWrapper> eventListJson = new List<JobSchedulingWrapper>();
                List<JobSchedulingWrapper> allDayEventListJson = new List<JobSchedulingWrapper>();
                
                if(eventJsonObj.AppointmentFilter || eventJsonObj.AppointmentwithserviceFilter || eventJsonObj.ReminderFilter){
                    if(eventJsonObj.CurrentView != 'Month'){
                        List<Event__c> eventList = getEvents(false);
                        for(Event__c event: eventList) {
                            eventListJson.add(new JobSchedulingWrapper(event));
                        }
                        
                        List<Event__c> allDayEventList = getEvents(true);
                        for(Event__c allDayevent: allDayEventList) {
                            allDayEventListJson.add(new JobSchedulingWrapper(allDayevent, StartCalendarViewDateTime, EndCalendarViewDateTime));
                        }
                    }else{
                        List<Event__c> eventList = getEvents(false);
                        for(Event__c event: eventList) {
                            eventListJson.add(new JobSchedulingWrapper(event));
                        }
                        
                        List<Event__c> eventListAllday = getEvents(true);
                        Datetime startdate;
                        Datetime enddate;
                        Integer dateDiff;
                        for(Event__c eventRec : eventListAllday) {
                                    dateDiff = (eventRec.Start_DateTime__c.date()).daysBetween(eventRec.End_DateTime__c.date()) + 1 ;
                                    startdate = eventRec.Start_DateTime__c.date();
                                    for(integer i =1 ; i <= dateDiff;i++ ){
                                        startdate = startdate;
                                        enddate = startdate;
                                        Event__c  objEvent= new Event__c();
                                        objEvent = eventRec;
                                        objEvent.Start_DateTime__c = startdate;
                                        objEvent.End_DateTime__c = enddate;
                                        eventListJson.add(new JobSchedulingWrapper(objEvent));
                                        startdate = enddate.addDays(1);
                                   
                            }   
                        }
                    
                    
                    } 
                }
                List<List<JobSchedulingWrapper>>  allEventList = new List<List<JobSchedulingWrapper>>();
                allEventList.add(eventListJson);
                allEventList.add(allDayEventListJson);
                JSONString = System.JSON.serialize(allEventList);
            }
            return BPUtility.getEncodedString(JSONString);
        } catch(exception ex){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
            return BPUtility.getEncodedString('');
        } 
    }
    
    private static List<Event__c> getEvents(Boolean isAllDayEvent){
        String query;   
        query = 'SELECT '; 
        for(String fieldsName : JobSchedulingWrapper.fieldsList()){
            query += fieldsName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event__c WHERE Is_MultiDay__c =: isAllDayEvent';
        String eventId = eventJsonObj.Id;
        Integer calendarViewMonthNumber = eventJsonObj.CalendarViewMonthNumber;
       
        if(!isAllDayEvent) {
            if((eventJsonObj.CurrentView == 'Week' || eventJsonObj.CurrentView == '3 Days' || eventJsonObj.CurrentView == 'Day' ) &&
                      eventJsonObj.StartCalendarViewDate != null && eventJsonObj.EndCalendarViewDate != null){
                query += ' AND (Start_DateTime__c >=: StartCalendarViewDateTime AND End_DateTime__c <=: EndCalendarViewDateTime)';
            } else if(eventJsonObj.CurrentView == 'Month' && calendarViewMonthNumber > 0)    {
                query += ' AND (CALENDAR_MONTH(Start_DateTime__c) =: calendarViewMonthNumber OR CALENDAR_MONTH(End_DateTime__c) =: calendarViewMonthNumber)';
            }
        } else {
            if((eventJsonObj.CurrentView == 'Week' || eventJsonObj.CurrentView == '3 Days' || eventJsonObj.CurrentView == 'Day' ) &&
                      eventJsonObj.StartCalendarViewDate != null && eventJsonObj.EndCalendarViewDate != null){
                query += ' AND (Start_DateTime__c <=: EndCalendarViewDateTime AND End_DateTime__c >=: StartCalendarViewDateTime)';
            } else if(eventJsonObj.CurrentView == 'Month' && calendarViewMonthNumber > 0)    {
                 query += ' AND (Start_DateTime__c <=: EndCalendarViewDateTime AND End_DateTime__c >=: StartCalendarViewDateTime)';
            }
        }
        
        if(eventJsonObj.AppointmentFilter || eventJsonObj.AppointmentwithserviceFilter || eventJsonObj.ReminderFilter){
            query += ' AND (';
        }
        
        if(eventJsonObj.AppointmentFilter == true)  {
            query += ' (Type__c = \'Appointment\'';
            if(eventJsonObj.AppointmentwithserviceFilter == true)   {
                query += ')';
            }else {
                query += ' AND CO_Header__c = null)';
            }
            
            if(eventJsonObj.ReminderFilter == true) {
                query += 'OR Type__c = \'Reminder\'';
            }
            query += ')';
        }else if(eventJsonObj.ReminderFilter == true)   { 
            query += ' Type__c = \'Reminder\'';
            if(eventJsonObj.AppointmentwithserviceFilter == true)   {
                query += ' OR (Type__c = \'Appointment\' AND CO_Header__c != null)';
            }
            query += ')';
        }else if(eventJsonObj.AppointmentwithserviceFilter == true) {
            query += ' Type__c = \'Appointment\' AND CO_Header__c != null';
            query += ')';
        }
        
        if(eventJsonObj.Id == null){
            query += ' ORDER BY Start_DateTime__c, End_DateTime__c, Type__c';
        }
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(query);
    }
    
    private static List<Event__c> getEventWithId(){
        String query;   
        query = 'SELECT '; 
        for(String fieldName : JobSchedulingWrapper.fieldsList()){
            query += fieldName + ', ';
        }
        query = query.substring(0, query.length()-2);
        query += ' FROM Event__c';
        String eventId = eventJsonObj.Id;
       
        if(eventJsonObj.Id != null) {
            query += ' WHERE Id =: eventId';
        }
        query += ' LIMIT ' + SOQLUtil.getAvailableQueryRowsLimit();
        return Database.query(query);
    }
    
    
    @remoteAction
    global static String saveJobSchedulingEvent(String eventJson){
        eventJson = BPUtility.getDecodedString(eventJson);
        try {
            JobSchedulingWrapper eventJsonObj = (JobSchedulingWrapper)System.JSON.deserialize(eventJson, JobSchedulingWrapper.class);
            DateTime StartDateTime;
            DateTime EndDateTime;
            if(eventJsonObj.StartDate != null && eventJsonObj.StartDate != '' &&
                eventJsonObj.ActualStartTime != null && eventJsonObj.ActualStartTime != '') {
                StartDateTime = getConvertedDateTime(eventJsonObj.StartDate, eventJsonObj.ActualStartTime);
            }
            if(eventJsonObj.EndDate != null && eventJsonObj.EndDate != '' && 
                eventJsonObj.ActualEndTime != null && eventJsonObj.ActualEndTime != '') {
                EndDateTime = getConvertedDateTime(eventJsonObj.EndDate, eventJsonObj.ActualEndTime);
            }
            
            Event__c eventObj = new Event__c();
            eventObj.Name__c = eventJsonObj.Title; //'Meeting'; 
            eventObj.Type__c = eventJsonObj.Type;
            
            if(eventJsonObj.Title == null || eventJsonObj.Title == '')  {
                eventJsonObj.Title = 'no title';
            }
            eventObj.Title__c = eventJsonObj.Title;
            eventObj.Appointment_Concern__c = eventJsonObj.Notes;
                
            /*Integer notesFieldMaxLength = 255;
            if(eventJsonObj.Notes.length() > notesFieldMaxLength) {
                eventObj.Notes__c = eventJsonObj.Notes.substring(0, (notesFieldMaxLength - 1));
                eventObj.AdditionalNotes__c = eventJsonObj.Notes.substring(notesFieldMaxLength, (eventJsonObj.Notes.length() - 1));
            } else {
                eventObj.Notes__c = eventJsonObj.Notes;
            }*/
            
            eventObj.Start_DateTime__c = StartDateTime;
            eventObj.End_DateTime__c = EndDateTime;
            eventObj.Id = eventJsonObj.Id;
            if(StartDateTime != null && EndDateTime != null){
                if(!StartDateTime.isSameDay(EndDateTime)){
                    eventObj.Is_MultiDay__c = true;
                } else {
                    eventObj.Is_MultiDay__c = false;
                }
            }
            DMLUtility.upsertSobjectList('Event__c', eventObj);
            
            return loadSchedulingEvents(BPUtility.getEncodedString(eventJson));
              
        }catch(exception ex){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
        } 
    }
    
    @remoteAction
    global static String deleteJobSchedulingEvent(String eventId, String eventJson){
        eventId = BPUtility.getDecodedString(eventId);
        try{
            if(!AccessControl.ifObjectIsDeletable('Event__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_DELETABLE); }
            Event__c eventObj = new Event__c(Id = eventId);
            delete eventObj;
            return loadSchedulingEvents(eventJson);
        }catch(exception ex){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
        } 
    }
    
    @RemoteAction
    global static void addServiceJobForJobScheduling(String eventJson) {
        eventJson = BPUtility.getDecodedString(eventJson);
        try{
            JobSchedulingWrapper eventJsonObj = (JobSchedulingWrapper)System.JSON.deserialize(eventJson, JobSchedulingWrapper.class);
            if(eventJsonObj.Id != null && eventJsonObj.COHeaderId != null)  {
                
                Event__c eventObj = new Event__c(Id = eventJsonObj.Id);
                eventObj.CO_Header__c = eventJsonObj.COHeaderId;
                DMLUtility.upsertSobjectList('Event__c', eventObj);
            }
        }catch(exception ex){
            throw new BlackPurlException(BlackPurlException.getErrorMessage(ex.getMessage(), ex.getStackTraceString()));
        } 
    }
    
    @RemoteAction
    global static String getServiceJobDetailsForForJobScheduling(String coHeaderId) {
        coHeaderId = BPUtility.getDecodedString(coHeaderId);
        try{
            if(!AccessControl.ifObjectFieldIsAccessible('CO_Header__c')) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
            
            String query = 'SELECT '; 
            //fields of CO Header
            for(String fieldsName : JobSchedulingWrapper.getCOHeaderfieldsList()){
                query += fieldsName + ', ';
            }
            
            // Child Query: fields of SO Header
            query += '( SELECT ';
            for(String fieldName : JobSchedulingWrapper.getSOHeaderfieldsList()){
                query += fieldName + ', ';
            }
            
            query = query.substring(0, query.length()-2);
            query += ' FROM Service_Order_Headers__r) ';
            query += ' FROM  CO_Header__c';
            query += ' WHERE ID =: coHeaderId';
            
            List<CO_Header__c> coHeaderList = Database.query(query);
            JobSchedulingWrapper.COHeaderWrapper coHeaderRec = new JobSchedulingWrapper.COHeaderWrapper(coHeaderList[0]);
            String JSONString = System.JSON.serialize(coHeaderRec);
            return BPUtility.getEncodedString(JSONString);
        }catch(Exception e){
            return BPUtility.getEncodedString('');
        }
    }
    
    private static DateTime getConvertedDateTime(String strDate, String strTime){
        String stringDateTime = '';
        stringDateTime += strDate;
        stringDateTime += ' ' + strTime.substring(0, strTime.length()-2);
        String strTimePeriod = ' ' + strTime.substring(strTime.length()-2, strTime.length());
        stringDateTime += strTimePeriod;
        //system.assert(false, stringDateTime);
        return DateTime.parse(stringDateTime);  
    }
}