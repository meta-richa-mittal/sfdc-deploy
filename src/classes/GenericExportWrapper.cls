public without sharing class GenericExportWrapper {
    public String Id;
    public String FileName;
    public String FileType;
    public String DelimiterTextValue;
    public String Delimiter;
    public Boolean IncludeColumnHeader;
    public String VendorId;
    public String ObjectAPIName;
    public String OrderByClause;
    public String ExportType;
    public String FilterId;
    public String GroupByFieldAPIName;
    public String WhereClause;
    public List<ColumnDetailWrapper> ColumnDetailList;

    public GenericExportWrapper() {}

    public GenericExportWrapper(GE_File_Config__c fileConfigRec) {
        this.Id = fileConfigRec.Id;
        this.FileName = fileConfigRec.File_Name__c;
        this.FileType = fileConfigRec.File_Content_Type__c;
        this.DelimiterTextValue = fileConfigRec.File_Separator__c;
        this.Delimiter = fileConfigRec.Delimiter__c;
        this.IncludeColumnHeader = fileConfigRec.Include_Column_Header__c;
        this.VendorId = fileConfigRec.Vendor__c;
        this.FilterId = fileConfigRec.Filter__c;
        this.GroupByFieldAPIName = fileConfigRec.Group_By_Field_API_Name__c;
        this.WhereClause = fileConfigRec.Where_Clause__c;
        this.ColumnDetailList = new List<ColumnDetailWrapper>();
        for(GE_File_Detail__c fileDetailRec: fileConfigRec.GE_File_Details__r) {
            this.ColumnDetailList.add(new ColumnDetailWrapper(fileDetailRec));
        }
    }

    public class ColumnDetailWrapper {
        public String Id;
        public String ColumnName;
        public String ColumnLabel;
        public Integer OrderNumber;
        public String ColumnDefaultValue;
        public Boolean isDelete;
        public String FieldAPIName;

        public ColumnDetailWrapper() {}

        public ColumnDetailWrapper(GE_File_Detail__c fileDetailRec) {
            this.Id = fileDetailRec.Id;
            this.ColumnName = fileDetailRec.File_Column_Name__c;
            this.ColumnLabel = fileDetailRec.File_Column_Label__c;
            this.OrderNumber = Integer.valueOf(fileDetailRec.Order_Number__c);
            this.ColumnDefaultValue = fileDetailRec.Default_Value__c;
            this.FieldAPIName = fileDetailRec.Field_API_Name__c;
        }
    }

    public class BPExportFormatWrapper {
        public String Id;
        public String Name;
        public Integer OrderNumber;

        public BPExportFormatWrapper(GE_File_Config__c fileConfigRec) {
            this.Id = fileConfigRec.Id;
            this.Name = fileConfigRec.File_Name__c;
            this.OrderNumber = Integer.valueOf(fileConfigRec.Blackpurl_Format_Order_Number__c);
        }
    }

    public static List<String> fileConfigFields = new List<String>{ 'Id', 'File_Name__c', 'File_Content_Type__c', 'File_Separator__c', 'Include_Column_Header__c', 'Vendor__c', 
                                                                    'Blackpurl_Format_Order_Number__c', 'Delimiter__c', 'Object_API_Name__c', 'Where_Clause__c', 
                                                                    'Order_By_Clause__c', 'Use_Public_Image__c', 'Filter__c', 'Group_By_Field_API_Name__c', 'Include_Image_URLs_In_One_Column__c'};
    public static List<String> fileDetailFields = new List<String>{ 'Id', 'File_Column_Name__c', 'File_Column_Label__c', 'Order_Number__c', 'Default_Value__c', 
                                                                    'Data_Type__c', 'Field_API_Name__c', 'Other_Object_API_Name__c'};
}