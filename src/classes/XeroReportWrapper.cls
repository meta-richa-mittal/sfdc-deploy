public class XeroReportWrapper {
    
    public String ReportName;
    public String ReportDate;
    public List<cls_Rows> Rows;
    
    public class cls_Rows {
        public String RowType;
        public String Title;
        public List<cls_InnerRows> Rows;
    }
    
    public class cls_InnerRows {
        public String RowType;
        public List<cls_Cells> Cells;
        public List<cls_InnerRows> Rows;
    }
    
    public class cls_Cells {
        public String Value;
        public List<cls_Attributes> Attributes;
    }

    public class cls_Attributes {
        public String Value;
        public String id;
    }
}