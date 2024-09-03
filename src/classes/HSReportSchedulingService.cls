public without sharing class HSReportSchedulingService {

    public final static String SCHEDULER_POSTFIX = ' Scheduler';

    public static Boolean isReportSchedulable(Filter__c filterRec) {
        String fieldFilterJson = ((filterRec.Field_Filter_Json__c != null ? filterRec.Field_Filter_Json__c : '' ) + (filterRec.Field_Filter_Json_2__c  != null ? filterRec.Field_Filter_Json_2__c : ''));
        if(String.isBlank(fieldFilterJson)) return false;
        HomeSearchFilterWrapper filterWrapperObj = new HomeSearchFilterWrapper();
        try {
            filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(fieldFilterJson, HomeSearchFilterWrapper.class);
        } catch(Exception e) {
            return false;
        }
        return validateReportToSchedule(filterWrapperObj);
    }
    
    public static String scheduleReport(String scheduleReportJson) {
        ScheduleReportWrapper scheduleReportObj = (ScheduleReportWrapper) System.JSON.deserialize(scheduleReportJson, ScheduleReportWrapper.class);
        validateEmailList(scheduleReportObj.EmailListStr);
        Filter__c filterRec = updateReportSchedulingData(scheduleReportObj);
        GE_File_Config__c geFileConfig = createGEFileConfigData(scheduleReportObj);
        scheduleExport(filterRec, geFileConfig);
        return 'Success';
    }

    public static String deleteScheduledReport(String filterId) {
        // reset filter fields related to report scheduling
        Filter__c filterRecToUpdate = new Filter__c(Id = filterId);
        resetScheduleRelatedFilterFields(filterRecToUpdate);
        DMLUtility.updateSobjectList('Filter__c', filterRecToUpdate);

        List<GE_File_Config__c> fileConfigList = [SELECT Id, File_Name__c FROM GE_File_Config__c WHERE Filter__c = :filterId];
        if(!fileConfigList.isEmpty()) {
            deleteScheduleRelatedConfig(fileConfigList);
        }
        return 'Success';
    }

    public static void resetScheduleRelatedFilterFields(Filter__c filterRecToUpdate) {
        // reset filter fields related to report scheduling
        filterRecToUpdate.Report_Format__c = filterRecToUpdate.Email_Addresses__c = filterRecToUpdate.Report_Frequency__c = 
        filterRecToUpdate.Schedule_On__c = filterRecToUpdate.Schedule_At__c = null;
    }

    public static void deleteScheduleRelatedConfig(List<GE_File_Config__c> fileConfigList) {
        List<String> schedledJobNameList = new List<String>();
        for(GE_File_Config__c fileConfigRec: fileConfigList) {
            schedledJobNameList.add(fileConfigRec.File_Name__c + SCHEDULER_POSTFIX);
        }

        // abort related scheduled job
        List<CronTrigger> alreadyScheduledJobs = [Select Id from CronTrigger where CronJobDetail.Name IN :schedledJobNameList];
        for(CronTrigger scheduledJobRec: alreadyScheduledJobs) {
            system.abortJob(scheduledJobRec.Id);
        }
            
        // delete related GE file config and GE file detail records (GE file detail records will be deleted automatically with GE file config)
        DMLUtility.deleteSobjectList('GE_File_Config__c', fileConfigList);
    }

    private static void validateEmailList(String emailListStr) {
        if(String.isBlank(emailListStr)) {
            throw new BlackPurlException('Email can not be blank.');
        }

        List<String> licensedUserEmailList = GenericExportService.getLicensedUserEmailList();
        Set<String> invalidEmailSet = new Set<String>();
        for(String emailStr: emailListStr.split(',')) {
            if(!licensedUserEmailList.contains(emailStr)) {
                invalidEmailSet.add(emailStr);
            }
        }
        if(!invalidEmailSet.isEmpty()) {
            throw new BlackPurlException('Email - ' + String.join(new List<String>(invalidEmailSet), ', ') + 
                                            (invalidEmailSet.size() == 1 ? ' is ' : ' are ') + 
                                            'not associated with a licensed user.');
        }
    }

    private static void scheduleExport(Filter__c filterRec, GE_File_Config__c geFileConfig) {
        String fileName = geFileConfig.File_Name__c;
        AccountingUtil.abortScheduleJobs(fileName);
        String scheduleStr = getCRONStrForSchedule(filterRec);
        System.schedule(fileName + SCHEDULER_POSTFIX, scheduleStr , new GenericExportBatch(fileName));
    }

    private static String getCRONStrForSchedule(Filter__c filterRec) {
        Time scheduleTime = DateTimeUtility.getTimeFromString2(filterRec.Schedule_At__c);
        Integer second = scheduleTime.second();
        Integer minute = scheduleTime.minute();
        Integer hour = scheduleTime.hour();
        String dayOfMonth = '';
        String month = '*';
        String dayOfWeek = ''; 
        String year = '*';

        if(filterRec.Report_Frequency__c == 'Daily') {
            dayOfMonth = '*';
            dayOfWeek = '?';
        } else if(filterRec.Report_Frequency__c == 'Weekly') {
            dayOfMonth = '?';
            dayOfWeek = dayNameToNumberMap.get(filterRec.Schedule_On__c);
        } else if(filterRec.Report_Frequency__c == 'Monthly') {
            dayOfMonth = dayNameToNumberMap.get(filterRec.Schedule_On__c);
            dayOfWeek = '?';
        }
        return (second + ' ' + minute + ' ' + hour + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek + ' ' + year);
    }

    private static Filter__c updateReportSchedulingData(ScheduleReportWrapper scheduleReportObj) {
        Filter__c filterToScheduleRec = new Filter__c(Id = scheduleReportObj.FilterId);
        filterToScheduleRec.Report_Format__c = scheduleReportObj.ReportFormat;
        filterToScheduleRec.Email_Addresses__c = scheduleReportObj.EmailListStr;
        filterToScheduleRec.Report_Frequency__c = scheduleReportObj.Frequency;
        filterToScheduleRec.Schedule_On__c = scheduleReportObj.ScheduleOn;
        filterToScheduleRec.Schedule_At__c = scheduleReportObj.ScheduleAt;
        DMLUtility.updateSobjectList('Filter__c', filterToScheduleRec);
        return filterToScheduleRec;
    }

    private static GE_File_Config__c createGEFileConfigData(ScheduleReportWrapper scheduleReportObj) {
        Filter__c filterRec = [SELECT Field_Filter_Json__c, Field_Filter_Json_2__c, Export_GroupBy_Field__c, Sort_Json__c, Display_Hidden_Column__c, 
                                Filter_User__c, (SELECT Id FROM GE_File_Configs__r LIMIT 1) FROM Filter__c WHERE Id =: scheduleReportObj.FilterId];
        
        String fieldFilterJson = ((filterRec.Field_Filter_Json__c != null ? filterRec.Field_Filter_Json__c : '' ) + (filterRec.Field_Filter_Json_2__c  != null ? filterRec.Field_Filter_Json_2__c : ''));
        HomeSearchFilterWrapper filterWrapperObj = (HomeSearchFilterWrapper) System.JSON.deserialize(fieldFilterJson, HomeSearchFilterWrapper.class);
        PaginationSorting sortingObj = (PaginationSorting) System.JSON.deserialize(filterRec.Sort_Json__c, PaginationSorting.class);
        
        String objectNameLabel;
        if(!filterWrapperObj.Type.Objects.isEmpty()) {
            objectNameLabel = new List<String>(filterWrapperObj.Type.Objects)[0];
        } else {
            throw new BlackPurlException('Some issue occurred while creating scheduling configuration - object is not defined.');
        }
        
        GenericExportWrapper genericExportObj = new GenericExportWrapper();
        if(filterRec.GE_File_Configs__r.size() > 0) {
            genericExportObj.Id = filterRec.GE_File_Configs__r[0].Id;
        }

        genericExportObj.FileName = scheduleReportObj.ReportName + '_' + filterRec.Filter_User__c;
        genericExportObj.FileType = scheduleReportObj.ReportFormat.toLowerCase();
        genericExportObj.DelimiterTextValue = scheduleReportObj.ReportFormat.equalsIgnoreCase('pdf') ? 'tab' : 'comma';
        genericExportObj.Delimiter = GenericExportUtil.fileSeparatorToFileSeparatorSymbolMap.get(genericExportObj.DelimiterTextValue);
        genericExportObj.IncludeColumnHeader = true;
        genericExportObj.ObjectAPIName = HomeSearchUtil.displayObjectNameToObjectAPINameMap.get(objectNameLabel);
        genericExportObj.FilterId = scheduleReportObj.FilterId;
        genericExportObj.GroupByFieldAPIName = getGroupByFieldAPIName(filterRec.Export_GroupBy_Field__c, objectNameLabel);
        genericExportObj.OrderByClause = getOrderByClause(sortingObj, genericExportObj.ObjectAPIName);
        genericExportObj.WhereClause = getWhereClause(filterWrapperObj, objectNameLabel);
        genericExportObj.ColumnDetailList = createDataForGEFileDetails(filterRec.Display_Hidden_Column__c, objectNameLabel, filterWrapperObj.IncludeInactiveRecords);
        
        if(genericExportObj.Id != null) {
            DMLUtility.deleteSobjectList('GE_File_Detail__c', [SELECT Id FROM GE_File_Detail__c WHERE GE_File_Config__c = :genericExportObj.Id]);
        }
        return GenericExportService.upsertGenericExportFormat(genericExportObj);
    }

    public static Boolean validateReportToSchedule(HomeSearchFilterWrapper filterWrapperObj) {
        if(!filterWrapperObj.Type.Objects.isEmpty()) {
            if(filterWrapperObj.Type.Objects.size() > 1) {
                return false;
            } else {
                filterWrapperObj.Tax_Detail_Invoice_Type = String.isNotBlank(filterWrapperObj.Tax_Detail_Invoice_Type) ? filterWrapperObj.Tax_Detail_Invoice_Type : '0'; // defaulted to 0 as this is not coming from FE
                Set<String> objectsSet = HomeSearchReportUtil.getObjectNamesSet(filterWrapperObj);
                if(objectsSet.contains('Part FIFO')) {
                    objectsSet.add('Part FIFO Line Item');
                }

                String objectLabel = (new List<String>(filterWrapperObj.Type.Objects))[0];
                if(objectsSet.size() > 1 || HomeSearchUtil.reportNameSetToQueryChildObj.contains(objectLabel)) {
                    return false;
                }
            }
        } else {
            return false;
        }
        return true;
	}

    private static String getGroupByFieldAPIName(String exportGroupByFieldName, String displayObjectName) {
        List<HomeSearch_Grid_Column__mdt> gridColsRecList = [SELECT Field_API_Name__c FROM HomeSearch_Grid_Column__mdt WHERE MasterLabel =: exportGroupByFieldName AND Display_Object_Name__c =: displayObjectName];
        if(!gridColsRecList.isEmpty()) {
            return gridColsRecList[0].Field_API_Name__c;
        }
        return null;
    }

    private static String getOrderByClause(PaginationSorting sortingObj, String objectAPIName) {
        String orderByStr = '';
        HomeSearchReportUtil.updateSortJson(sortingObj, objectAPIName);
        for(PaginationSorting.SortAttrs sortAttrObj: sortingObj.Sorting) {
            orderByStr += sortAttrObj.FieldName + ' ' + sortAttrObj.SortDirection + ', ';
        }
        orderByStr = orderByStr.substring(0, orderByStr.length()-2);
        return orderByStr;
    }

    private static String getWhereClause(HomeSearchFilterWrapper filterWrapperObj, String objectNameLabel) {
        String whereClauseStr = '';

        Map<String, List<HomeSearchFilterInterface.FieldFilter>> objNameToFilterListMap = HomeSearchFilterInterface.getFilterList(filterWrapperObj);
        if(!objNameToFilterListMap.containsKey(objectNameLabel)) {
            throw new BlackPurlException('Filters can not be found for ' + objectNameLabel + '.');
        }
        for(HomeSearchFilterInterface.FieldFilter fieldFilterObj: objNameToFilterListMap.get(objectNameLabel)) {
            whereClauseStr += fieldFilterObj.FieldName + ' ' + fieldFilterObj.Operator + ' ' + fieldFilterObj.FieldValue + ' AND ';
        }
        whereClauseStr = whereClauseStr.subString(0, whereClauseStr.length() - 5);
        return whereClauseStr;
    }

    private static List<GenericExportWrapper.ColumnDetailWrapper> createDataForGEFileDetails(String displayHiddenColJson, String displayObjectName, Boolean includeInactiveRecords) {
        List<String> colsToInculdeList = new List<String>();
        HomeSearchCtrl.DisplayHiddenColumnWrapper columnObj = (HomeSearchCtrl.DisplayHiddenColumnWrapper) System.JSON.deserialize(displayHiddenColJson, HomeSearchCtrl.DisplayHiddenColumnWrapper.class);
        List<GenericExportWrapper.ColumnDetailWrapper> columnList = new List<GenericExportWrapper.ColumnDetailWrapper>();
        for(HomeSearchCtrl.DisplayedColumnsWrapper colObj: columnObj.DisplayedColumns) {
            if(colObj.Label != 'Active' || (includeInactiveRecords != null && includeInactiveRecords)) {
                colsToInculdeList.add(colObj.Label);
            }
        }
        List<HomeSearch_Grid_Column__mdt> gridColsRecList = [SELECT MasterLabel, Field_API_Name__c, Order_Number__c FROM HomeSearch_Grid_Column__mdt WHERE MasterLabel IN :colsToInculdeList AND Display_Object_Name__c =: displayObjectName];
        for(HomeSearch_Grid_Column__mdt colRec: gridColsRecList) {
            if(colRec.MasterLabel == 'Type') {
                continue;
            }
            GenericExportWrapper.ColumnDetailWrapper colDetailObj = new GenericExportWrapper.ColumnDetailWrapper();
            colDetailObj.ColumnLabel = colRec.MasterLabel;
            colDetailObj.OrderNumber = Integer.valueOf(colRec.Order_Number__c);
            colDetailObj.FieldAPIName = colRec.Field_API_Name__c;
            columnList.add(colDetailObj);
        }
        return columnList;
    }

    private static Map<String, String> dayNameToNumberMap = new Map<String, String>{
                                                                                        'Sunday' => '1',
                                                                                        'Monday' => '2',
                                                                                        'Tuesday' => '3',
                                                                                        'Wednesday' => '4',
                                                                                        'Thursday' => '5',
                                                                                        'Friday' => '6',
                                                                                        'Saturday' => '7',
                                                                                        '1st day' => '1',
                                                                                        'Last day' => 'L',
                                                                                        '15th day' => '15'
                                                                                    };
}