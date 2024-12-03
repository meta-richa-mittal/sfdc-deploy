@IsTest
public class TestDataFactory_V2 {

    /** Default value provider instance */
    private static DefaultValueProvider dvPrvdr = new DefaultValueProvider();
    
    /** Default value generator, used to auto-generate default values for non required fields  */
    public static final IFieldDefaultValue DEFAULT_VALUE = new AutoFieldDefaultValue();

    /** Constant that contains a dot '.' */
    private static final String DOT = '.';

    /** Map of sObject types with their corresponding map of field Tokens  */
    @TestVisible
    private static Map<Schema.SObjectType,Map<String, Schema.SObjectField>> mapOfFieldTokensMap = new Map<Schema.SObjectType,Map<String, Schema.SObjectField>>();

    /* ===========================  Properties =========================== */
    /** Default Value Provider property, used to override the default value provider instance  **/
    public static DefaultValueProvider defaultValueProvider {
        get { return dvPrvdr; }
        set {
            if(value != null){
                dvPrvdr = value;
            }
        }
    }

    /** Determine if person account is enabled in current org **/
    @TestVisible
    private static Boolean isPersonAccountEnabled{
        get{
            return Schema.SObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' );
        }
    }

    /* ===========================  Public methods =========================== */
    /**
     * @description create an sObject
     * @param sObjectName (String): name of the sObject to be created
     * @return sObject instance
     * @example 
     * Account acc = (Account)TestDataFactory_V2.createSObject('Account');
     */
    public static SObject createSObject(String sObjectName){
        return createSObject(sObjectName,new Map<String,Object>(),true);
    }

    /**
     * @description create an sObject
     * @param sObjectName (String): name of the sObject to be created
     * @param Boolean (Boolean): if true the sObject instance is inserted to the Salesforce database
     * @return sObject instance
     * @example 
     * Account acc = (Account)TestDataFactory_V2.createSObject('Account',false);
     */
    public static SObject createSObject(String sObjectName, Boolean doInsert){
        return createSObject(sObjectName,new Map<String,Object>(),doInsert);
    }

    /**
     * @description create an sObject with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @return sObject instance
     * @example 
     * Account acc = (Account)TestDataFactory_V2.createSObject('Account',new Map<String,Object>{
     *  'Description' => 'Test'
     * });
     */
    public static SObject createSObject(String sObjectName, Map<String,Object> mapOfValuesOverride){
        return createSObject(sObjectName,mapOfValuesOverride,true);
    }

    /**
     * @description create an sObject with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @param doInsert (Boolean): if true the sObject instance is inserted to the Salesforce database
     * @return sObject instance
     * @example 
     * Account acc = (Account)TestDataFactory_V2.createSObject('Account',new Map<String,Object>{
     *  'Description' => 'Test'
     * },false);
     */
    public static SObject createSObject(String sObjectName, Map<String,Object> mapOfValuesOverride, Boolean doInsert){
        return createSObjectList(sObjectName,mapOfValuesOverride,1,doInsert).get(0);
    }

    /**
     * @description create a list of sObjects
     * @param sObjectName (String): name of the sObject to be created
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @return list of sObject instances
     * @example 
     * List<Account> accList = TestDataFactory_V2.createSObjectList('Account',10);
     */
    public static List<SObject> createSObjectList(String sObjectName, Integer numberOfSObjects){
        return createSObjectList(sObjectName,new Map<String,Object>(),numberOfSObjects,true);
    }
    
    /**
     * @description create a list of sObjects
     * @param sObjectName (String): name of the sObject to be created
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
     * @return list of sObject instances
     * @example 
     * List<Account> accList = TestDataFactory_V2.createSObjectList('Account',10,false);
     */
    public static List<SObject> createSObjectList(String sObjectName, Integer numberOfSObjects, Boolean doInsert){
        return createSObjectList(sObjectName,new Map<String,Object>(),numberOfSObjects, doInsert);
    }

    /**
     * @description create a list of sObjects with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @return list of sObject instances
     * @example 
     * List<Account> accList = TestDataFactory_V2.createSObjectList('Account',new Map<String,Object>{
     *  'Description' => 'Test'
     * },10);
     */
    public static List<SObject> createSObjectList(String sObjectName, Map<String,Object> mapOfValuesOverride, Integer numberOfSObjects){
        return createSObjectList(sObjectName,mapOfValuesOverride,numberOfSObjects,true);
    }

    /**
     * @description create a list of sObjects with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
     * @return list of sObject instances
     * @example 
     * List<Account> accList = TestDataFactory_V2.createSObjectList('Account',new Map<String,Object>{
     *  'Description' => 'Test'
     * },10,false);
     */
    public static List<SObject> createSObjectList(String sObjectName, Map<String,Object> mapOfValuesOverride, Integer numberOfSObjects, Boolean doInsert){
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName); 
        SObjectFactory sObjFactory = new SObjectFactory(sObjectType);
        List<SObject> listSObjectInstance = sObjFactory.getListSObjectInstance(mapOfValuesOverride, doInsert, numberOfSObjects);
        return listSObjectInstance;
    }


    /* ======================================================================================================== */
    /* =======================================  inner classes & interfaces ==================================== */
    /* ======================================================================================================== */
    /**
    * @description interface ISObjectManager
    */
    public interface ISObjectManager{
        List<SObject> getMainSObjectList();
        void setSObject(Integer index, SObject sObj);
        SObject getSObject(Integer index);
        void setRelationship(Integer index, String relationshipName, SObject sObj);
        SObject getRelationship(Integer index, String relationshipName);
        void insertAll();
    }

    /**
    * @description class SObjectManager : manage all the sObjects instances and the insertion to the salesforce DB
    */
    public class SObjectManager implements ISObjectManager{
        
        /** Main sObject name */
        private String sObjectName = null; 
        /** List of main sObject instances */
        @TestVisible
        private List<SObject> mainSObjectList = new List<SObject>();
        /** Map of relationship names with their related list of sObject instances */
        @TestVisible
        private Map<String,List<SObject>> relatedSObjMapList = new Map<String,List<SObject>>();
        /** List of ordered relationship names by dot notation */
        @TestVisible
        private List<String> orderedRelationshipList = new List<String>();

        /* ===========================  Error Messages =========================== */
        /** Unable to insert "{0}" records: {1} */
        private final String ERR_INSERT_SOBJECT = 'Unable to insert "{0}" records: \n{1}';


        /**
        * @description constructor
        * @return sObjectName (String): main sObject name
        */
        public SObjectManager(String sObjectName){
            this.sObjectName = sObjectName;
        }

        /**
        * @description get the list of all main sObject instances
        * @return list of sObject instances
        */
        public List<SObject> getMainSObjectList(){
            return mainSObjectList;
        }

        /**
        * @description set or add an sObject to the main sObject list for a given index
        * @param index (Integer): index for which the sObject instance will be added or set
        * @param sObj (SObject): sObject instance to add or set to the main sObject list
        */
        public void setSObject(Integer index, SObject sObj){
            if(index == mainSObjectList.size()){
                mainSObjectList.add(sObj);
            }else{
                mainSObjectList.set(index,sObj);
            } 
        }

        /**
        * @description get an sObject from the main sObject list for a given index
        * @param index (Integer): index for which the sObject instance will be returned
        * @return the returnd sObject instance
        */
        public SObject getSObject(Integer index){
            return mainSObjectList.get(index);
        }

        /**
        * @description set or add a related sObject into the related sObject map list for a given index and relationship name
        * @param index (Integer): index for which the sObject instance will be added or set
        * @param fullyQualifiedRelationshipName (String): fully qualified relationship name for which the sObject instance will be added or set
        * @param sObj (SObject): sObject instance to add or set to the related sObject map list
        */
        public void setRelationship(Integer index, String fullyQualifiedRelationshipName, SObject sObj){
            String fullyQualifiedRelationshipNameLowerCase = fullyQualifiedRelationshipName.toLowerCase();
            // get related sObject list for the fully qualified relationship name
            List<SObject> relatedSObjList = relatedSObjMapList.get(fullyQualifiedRelationshipNameLowerCase);
            if(relatedSObjList == null){ 
                // instantiate the list if null
                relatedSObjList = new List<SObject>();
                // put the list into the related sObject map list 
                relatedSObjMapList.put(fullyQualifiedRelationshipNameLowerCase,relatedSObjList);
                // add the fully qualified relationship name to the list of ordered relationship names
                addRelationshipName(fullyQualifiedRelationshipNameLowerCase);
            } 

            if(index == relatedSObjList.size()){
                relatedSObjList.add(sObj);
            }
            else{
                relatedSObjList.set(index,sObj);
            } 
        }

        /**
        * @description get a related sObject from the related sObject map list for a given index and relationship name
        * @param index (Integer): index for which the sObject instance will be returned
        * @param fullyQualifiedRelationshipName (String): fully qualified relationship name for which the sObject instance will be returned
        * @return the returnd sObject instance
        */
        public SObject getRelationship(Integer index, String fullyQualifiedRelationshipName){
            try{
                List<SObject> relatedSObjList = relatedSObjMapList.get(fullyQualifiedRelationshipName.toLowerCase());
                return relatedSObjList.get(index);
            }catch(Exception e){
                return null;
            }
        }

        /**
        * @description insert all the sObjects stored in the sObject Manager into the Salesforce database  
        */
        public void insertAll(){
            // loop through the ordered relationship list
            for(Integer i = 0; i < orderedRelationshipList.size(); i++){
                String fullyQualifiedRelationshipName = orderedRelationshipList.get(i);
                List<SObject> sObjParentList = relatedSObjMapList.get(fullyQualifiedRelationshipName);

                // insert parent sObject list
                insertList(sObjParentList,DOT+fullyQualifiedRelationshipName);
                
                // last relationship name in the dot notation
                String leafRelationshipName = (DOT+fullyQualifiedRelationshipName).substringAfterLast(DOT); 

                if(!fullyQualifiedRelationshipName.contains(DOT)){ // single relationship 
                    // link child sObject list to the main sObject list
                    setChildParentRelationship(mainSObjectList,sObjParentList,fullyQualifiedRelationshipName);

                }else{ // multiple relationships

                    // fully qualified relationship name without the leaf relationship
                    String fullyQualifiedRelationshipNameWithoutLeaf = fullyQualifiedRelationshipName.substringBeforeLast(DOT);
                    // get the list of sObject of the fully qualified relationship name without the leaf relationship name
                    List<SObject> sObjChildList = relatedSObjMapList.get(fullyQualifiedRelationshipNameWithoutLeaf);
                    // link child sObject list to the parent sObject list
                    setChildParentRelationship(sObjChildList,sObjParentList,leafRelationshipName);
                }
            }

            // insert main sObject list
            insertList(mainSObjectList,'');
        }

        /* ============================================================================================= */
        /* =======================================  private methods ==================================== */
        /* ============================================================================================= */

        /**
        * @description link a list of child sObject instances to a list of parent sObject instances for a given relationship name
        * @param sObjChildList (List<SObject>): list of child sObject instances
        * @param sObjParentList (List<SObject>): list of parent sObject instances
        * @param relationshipName (String): relationship name that links the child sObject to the parent sObject
        */
        @TestVisible
        private void setChildParentRelationship(List<SObject> sObjChildList, List<SObject> sObjParentList, String relationshipName){
            Integer index = 0;
            for(SObject sObjChild: sObjChildList){
                // get the field name that links the child sObject to the parent sObject
                String relationshipFieldName = getFieldNameFromRelationshipName(relationshipName); 
                // set field related to the relationship name (on the child sObject), with the Id of the parent sObject
                sObjChild.put(relationshipFieldName,sObjParentList.get(index).get('Id'));
                index++;
            }
        }

        /**
        * @description add relationship name to the ordered relationship list, ordered by the number of dots
        * @param fullyQualifiedRelationshipName (String): fully qualified relationship name (example contact.account)
        */
        @testVisible
        private void addRelationshipName(String fullyQualifiedRelationshipName){
            Integer i=0;
            for (String rName : orderedRelationshipList) {
                if(fullyQualifiedRelationshipName == rName) return; // already exists
                if(rName.countMatches('.') < fullyQualifiedRelationshipName.countMatches('.')){
                    // insert depending of the number of dots
                    orderedRelationshipList.add(i, fullyQualifiedRelationshipName);
                    return;
                }
                i++;
            }
            // insert at the end
            orderedRelationshipList.add(fullyQualifiedRelationshipName);
        }

        /**
        * @description execute a DML insert operation on a list of sObjects
        * @param sObjList (List<SObject>): list of sObjects to be inserted
        * @param errorMessageMergeValue (String): merge value provided only for error message generation (example : .contact.account)
        */
        @testVisible
        private void insertList(List<SObject> sObjList, String errorMessageMergeValue){
            Database.SaveResult[] saveResults = Database.insert(sObjList, false);
            Integer i = 0;
            List<String> listErrors = new List<String>();
            // Iterate through the save results
            for (Database.SaveResult saveResult : saveResults) {
                if (!saveResult.isSuccess()){
                    // Iterate through the errors                
                    for(Database.Error error : saveResult.getErrors()) {
                        Set<String> fieldNames = new Set<String>{'Name','RecordTypeId'};
                        fieldNames.addAll(error.getFields());
                        String listFieldValues = '';     
                        for(String fieldName : fieldNames){
                            Object fieldValue;
                            try {
                                fieldValue = sObjList.get(i).get(fieldName);
                            }catch(Exception e){ /*  ignore errors */}
                            if(fieldValue != null){
                                listFieldValues += fieldName + '='+ fieldValue +', ';
                            }
                        }              
                        listFieldValues = listFieldValues.removeEnd(', ');
                        listErrors.add(error.getStatusCode() + ': ' + error.getMessage() + ' ' +'['+listFieldValues+']');
                    }
                    i++;
                }
            }
            if(!listErrors.isEmpty()){
                throw new TestDataFactoryException(formatErrorMessage(ERR_INSERT_SOBJECT,new List<String>{sObjectName+errorMessageMergeValue,String.join(listErrors,'\n')},''));
            }
        }
    }

    /**
    * @description interface ISObjectFactory
    */
    public interface ISObjectFactory{
        ISObjectManager getSObjectManager();
        SObject getSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert);
        List<SObject> getListSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert, Integer numberOfSObjects);
    }

    /**
    * @description class SObjectFactory : manage the creation of all the sObjects instances 
    */
    public class SObjectFactory implements ISObjectFactory{

        /** Main sObject type to instantiated */
        private Schema.SObjectType sObjectType = null;
        /** Main sObject Name to instantiated */
        private String sObjectName;
        /** Instance of SObject Manager to store all the created sObject instances */
        private SObjectManager sObjMgr;

        /* ===========================  Error Messages =========================== */
        /** Unable to find the sObject */
        private final String ERR_NOT_FOUND_SOBJECT = 'Unable to find the sObject';
        /** The field "{0}" does not exist on "{1}" or the value type provided is incorrect */
        private final String ERR_FIELD_NOT_EXIST = 'The field "{0}" does not exist on "{1}" or the value type provided is incorrect';
        /** The relationship "{0}" does not exist on "{1}" */
        private final String ERR_RELATIONSHIP_NOT_EXIST = 'The relationship "{0}" does not exist on "{1}"';
        /** Unable to get the value for the field "{0}" */
        private final String ERR_UNABLE_TO_GET_FIELD_VALUE = 'Unable to get the value for the field "{0}"';


        /**
        * @description construtor
        * @param sObjectType (Schema.SObjectType): main sObject type to be instantiated
        */
        public SObjectFactory(Schema.SObjectType sObjectType){
            if(sObjectType == null){
                throw new TestDataFactoryException(formatErrorMessage(ERR_NOT_FOUND_SOBJECT,new List<String>{},''));
            }
            this.sObjectType = sObjectType;
            this.sObjectName = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getName();
            this.sObjMgr = new SObjectManager(this.sObjectName);
        }

        /**
        * @description get the SObject Manager instance
        * @return sObject Manager instance
        */
        public SObjectManager getSObjectManager(){
            return sObjMgr;
        }

        /**
        * @description generate an sObject instance and apply the override map of values
        * @param mapOfValuesOverride (Map<String,Object>): map of values to override when instanciating the sObject
        * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
        * @return sObject instance
        */
        public SObject getSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert){
            return getListSObjectInstance(mapOfValuesOverride,doInsert,1).get(0);
        }

        /**
        * @description generate a list of sObject instances and apply the override map of values
        * @param mapOfValuesOverride (Map<String,Object>): map of values to override when instanciating the sObject
        * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
        * @param numberOfSObjects (Integer): number of sObjects to be instantiated
        * @return list of sObject instances
        */
        public List<SObject> getListSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert, Integer numberOfSObjects){
            // get the map of values formed from the union of the map of values override given by the user and the auto-generated map of values for the required fields
            Map<String,IFieldDefaultValue> mapOfValues = defaultValueProvider.getDefaultMapOfValues(sObjectType,mapOfValuesOverride);

            for(Integer i = 0; i < numberOfSObjects; i++) {
                initSObjectInstance(mapOfValues,i); // init sObject instance
            }

            if(doInsert){
                sObjMgr.insertAll(); // insert all if doInsert = true
            }

            return sObjMgr.getMainSObjectList();
        }

        /* ============================================================================================= */
        /* =======================================  private methods ==================================== */
        /* ============================================================================================= */

        /**
        * @description initiate the main sObject instance with all related sObject and apply the map of values
        * @param mapOfValues (Map<String,IFieldDefaultValue>): map of values with key as field name and value as the default value to be used when instantiating the sObject. 
        *           This map contains the default values provided as input by the user and the auto-generated default values for the required fields
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        */
        @TestVisible
        private void initSObjectInstance(Map<String,IFieldDefaultValue> mapOfValues, Integer recordIndex){
            // add the main sObject instance to the sObject Manager
            sObjMgr.setSObject(recordIndex,sObjectType.newSObject()); 

            for(String fullyQualifiedFieldName : mapOfValues.keySet()){ // loop through the map of values

                // get the field name from the fully qualified field name
                String fieldName = (DOT+fullyQualifiedFieldName).substringAfterLast(DOT);
                // get the field value from the map of values
                Object fieldValue = getFieldValueFromMapOfValues(mapOfValues,fullyQualifiedFieldName,recordIndex);
                
                if(!fullyQualifiedFieldName.contains(DOT)){ // field name
                    putField(sObjMgr.getSObject(recordIndex),fieldName,fieldValue,sObjectName);
                }else{ // relationship
                    // first relationship name in fully qualified relationship name
                    String firstRelationshipName = fullyQualifiedFieldName.substringBefore(DOT); 
                    // fully qualified relationship name without the field name 
                    String fullyQualifiedRelationshipName = fullyQualifiedFieldName.substringBeforeLast(DOT);  
                    // generate the related sObject instances for a given fullyQualifiedRelationshipName
                    SObject relatedSObj = getRelationshipInstance(fullyQualifiedRelationshipName,recordIndex); 
                    // apply the field value for the related sObject
                    putField(relatedSObj,fieldName,fieldValue,sObjectName+DOT+fullyQualifiedRelationshipName);
                    // link the related sObject to the main sObject
                    putSObject(sObjMgr.getSObject(recordIndex),firstRelationshipName,sObjMgr.getRelationship(recordIndex,firstRelationshipName),sObjectName);
                }
            }
        }

        /**
        * @description Recursive method that initiate all the related sObjects of a given fully qualified relationship name
        * @param fullyQualifiedRelationshipName (String): fully qualified relationship name (example : Case.Contact.Account)
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return main sObject instance with all related sObjects attached to it
        */
        @TestVisible
        private SObject getRelationshipInstance(String fullyQualifiedRelationshipName, Integer recordIndex){
            // get the sObject instance from the sObject Manager
            SObject sObj = sObjMgr.getRelationship(recordIndex,fullyQualifiedRelationshipName);
            // return the sObject instance if already exists in the sObject Manager
            if(sObj != null){
                return sObj; 
            } 

            // last relationship name in the dot notation
            String leafRelationshipName = (DOT+fullyQualifiedRelationshipName).substringAfterLast(DOT); 

            if(!fullyQualifiedRelationshipName.contains(DOT)){ // single relationship
                sObj = getRelatedSObjectInstance(sObjectType,leafRelationshipName,sObjectName); 
            }else{ // multiple relationships

                // fully qualified relationship name without the leaf relationship
                String fullyQualifiedRelationshipNameWithoutLeaf = fullyQualifiedRelationshipName.substringBeforeLast(DOT); 
                // generate the all the sObject instances for the fully qualified relationship name without the leaf relationship name
                SObject relatedSObj = getRelationshipInstance(fullyQualifiedRelationshipNameWithoutLeaf,recordIndex); // <= recursion
                // merge value for error message display
                String errorMessageMergeValue = sObjectName+DOT+fullyQualifiedRelationshipNameWithoutLeaf;
                // get sObject instance for the leaf relationship
                sObj = getRelatedSObjectInstance(relatedSObj.getSObjectType(),leafRelationshipName,errorMessageMergeValue); 
                // link the related instance of the leaf relationship to the related sObject of the fully qualified relationship name without the leaf relationship name
                putSObject(relatedSObj,leafRelationshipName,sObj,errorMessageMergeValue);
            } 

            // add the sObject instance to the sObject Manager
            sObjMgr.setRelationship(recordIndex,fullyQualifiedRelationshipName,sObj);
            return sObj;
        }

        /**
        * @description get related sObject instance of an sObject type for a given relationship name
        * @param sObjectType (Schema.SObjectType): sObject type to which the generate sObject is related
        * @param relationshipName (String): relationship name that links the sObject type and the sObject instance that will be generated
        * @param errorMessageMergeValue (String): merge value provided only for error message generation (example : Contact.Account)
        * @return the generated related sObject instance
        */
        @TestVisible
        private SObject getRelatedSObjectInstance(Schema.SObjectType sObjectType, String relationshipName, String errorMessageMergeValue){
            Map<String, Schema.SObjectField> fieldsMap = getFieldTokensMap(sObjectType);
            Schema.DescribeFieldResult fieldDesc;
            SObject sObj;
            try{
                // get the related field describe
                fieldDesc = fieldsMap.get(getFieldNameFromRelationshipName(relationshipName)).getDescribe(); 
                // get related sObject instance
                sObj = fieldDesc.getReferenceTo().get(0).newSObject();
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_RELATIONSHIP_NOT_EXIST,new List<String>{relationshipName,errorMessageMergeValue},e.getMessage()));
            }
            return  sObj;
        }

        /**
        * @description get the field value from the map of values for a given record index and fully qualified field name
        * @param mapOfValues (Map<String,IFieldDefaultValue>): map of values with key as field name and value as the default value to be used when instantiating the sObject. 
        * @param fullyQualifiedFieldName (String): fully qualified field name (example : Contact.Account.Name)
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return field value
        */
        @TestVisible
        private Object getFieldValueFromMapOfValues(Map<String,IFieldDefaultValue> mapOfValues, String fullyQualifiedFieldName, Integer recordIndex){
            Object fieldValue;
            try{
                // get the field value
                fieldValue = mapOfValues.get(fullyQualifiedFieldName).getValue(recordIndex); 
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_UNABLE_TO_GET_FIELD_VALUE,new List<String>{fullyQualifiedFieldName},e.getMessage()));
            }
            return fieldValue;
        }

        /**
        * @description attach an sObject into a related sObject
        * @param sObj (SObject): main sObject instance
        * @param relationshipName (String): sObject name of the related sObject
        * @param sObjectValue (SObject): related sObject instance to be attached to the main sObject instance
        * @param errorMessageMergeValue (String): merge value provided only for error message generation (example : Contact.Account)
        * @return main sObject instance
        */
        @TestVisible
        private SObject putSObject(SObject sObj, String relationshipName , SObject sObjectValue, String errorMessageMergeValue){
            try{
                sObj.putSObject(relationshipName,sObjectValue);
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_RELATIONSHIP_NOT_EXIST,new List<String>{relationshipName,errorMessageMergeValue},e.getMessage()));
            }
            return sObj;
        }       

        /**
        * @description set field value in given sObject instance
        * @param sObj (SObject): main sObject instance
        * @param fieldName (String): field name of the field to set
        * @param fieldValue (Object): value of the field to set
        * @param errorMessageMergeValue (String): merge value provided only for error message generation (example : Contact.Account)
        * @return main sObject instance
        */
        @TestVisible
        private SObject putField(SObject sObj, String fieldName, Object fieldValue, String errorMessageMergeValue){
            try{
                sObj.put(fieldName,fieldValue);
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_FIELD_NOT_EXIST,new List<String>{fieldName,errorMessageMergeValue},e.getMessage()));
            }
            return sObj;
        }

    }

    /**
    * @description interface IDefaultValueProvider
    */
    public interface IDefaultValueProvider{
        Map<String,IFieldDefaultValue> getDefaultMapOfValues(Schema.SObjectType sObjectType, Map<String,Object> mapOfValuesOverride);
    }

    /**
    * @description virtual class DefaultValueProvider : manage the creation of the defaultMap and getting field default values
    */
    public virtual class DefaultValueProvider implements IDefaultValueProvider {

        /* ===========================  Error Messages =========================== */
        /** List values is not supported for field {0} */
        private final String ERR_LIST_VALUE_NOT_SUPPORTED = 'List values is not supported for field {0}';
        /** Bad record type Id provided for Account */
        private final String ERR_BAD_RECORDTYPE_ID_FOR_ACCOUNT = 'Bad record type Id provided for Account';

        /* ===========================  Properties =========================== */
        /** Person Account record type Ids */
        @TestVisible
        private Set<Id> personAccountRecordTypes{ 
            get{
                if(personAccountRecordTypes == null){
                    if(isPersonAccountEnabled){
                        String account = 'Account';
                        personAccountRecordTypes = new Map<Id,SObject>(Database.query('select Id from RecordType where SObjectType=:account and isPersonType=true')).keySet();
                    }else {
                        personAccountRecordTypes = new Set<Id>();
                    }
                }
                return personAccountRecordTypes;
            }
            set{}
        }

        /** Account default record type Id */
        @TestVisible
        private Id accountDefaultRecordTypeId {
            get{
                if(accountDefaultRecordTypeId == null){
                    Schema.DescribeSObjectResult dsr = Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
                    for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
                        if(rti.isDefaultRecordTypeMapping()) {
                            return rti.getRecordTypeId();
                        }
                    }
                }
                return accountDefaultRecordTypeId;
            }
            set{}
        }

        /**
        * @description get the default map of values for a given sObjectType.
        *                        The default map of value contains fully qualified field name as a key and the field value wrapped in FieldDefaultValue instance
        * @param sObjectType (Schema.SObjectType): sObject Type for which the map of values will be generated
        * @param mapOfValuesOverride (Map<String,Object>): map of values that will override the the auto-generated map of values
        * @return map of values
        */
        public Map<String,IFieldDefaultValue> getDefaultMapOfValues(Schema.SObjectType sObjectType, Map<String,Object> mapOfValuesOverride){
            Map<String,IFieldDefaultValue> mapOfValues = new Map<String,IFieldDefaultValue>(convertMapValueTypes('',mapOfValuesOverride));
            generateDefaultMapOfValues(sObjectType,mapOfValues,'');
            return mapOfValues;
        }

        /* ============================================================================================= */
        /* =======================================  private methods ==================================== */
        /* ============================================================================================= */

        /**
        * @description generate the default map of values for a given sObjectType.
        *               The default value map of values will contain the map of values overrided and generated value for all required fields of the sObjectType
        * @param sObjectType (Schema.SObjectType): sObject Type for which the map of values will generated
        * @param mapOfValues (Map<String,IFieldDefaultValue>): map of values
        * @param prefix (String): prefix of the relationship (example : Contact.Account.)
        */
        @TestVisible
        private void generateDefaultMapOfValues(Schema.SObjectType sObjectType, Map<String,IFieldDefaultValue> mapOfValues, String prefix){
            Schema.DescribeSObjectResult sObjectDesc = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED);
            Map<String, Schema.SObjectField> fieldsMap = getFieldTokensMap(sObjectType); // get the field Tokens map
            Set<String> keySetOverride = mapOfValues.keySet();
            Set<String> relationshipKeySet = getRelationshipKeySet(keySetOverride,prefix);
            // get the defined required fields set
            Set<String> definedRequiredFields = getDefinedSObjectRequiredFields(sObjectType);
            // get the defined optional fields set
            Set<String> definedOptionalFields = getDefinedSObjectOptionalFields(sObjectType);
            // Manage Person Account Org enabled
            if(sObjectType == Account.sObjectType && isPersonAccountEnabled){ 
                managePersonAccountOrgEnabled(mapOfValues,prefix,definedRequiredFields);
            }
            // loop through fields map
            for(String fieldName : fieldsMap.keySet()){
                Schema.DescribeFieldResult fieldDesc = fieldsMap.get(fieldName).getDescribe(); // get field describe
                String fieldNameLowerCase = fieldName.toLowerCase();
                // construct the fully qualified name of the field
                String fullyQualifiedFieldName = prefix+fieldNameLowerCase;
                // get the field value from the mapOfValues
                Object overrideFieldValue = mapOfValues.get(fullyQualifiedFieldName);
                if(overrideFieldValue != null){ // override value provided for the field
                    if(overrideFieldValue instanceof AutoFieldDefaultValue) { // auto generate a field value
                        if(fieldDesc.getRelationshipName() == null){ // field
                            // put a fieldDefaultValue instance of the field in order to auto-generate the field default value
                            mapOfValues.put(fullyQualifiedFieldName,new FieldDefaultValue(this,sObjectDesc,fieldDesc));
                        }else { // relationship
                            // put a field relationship in the map of values
                            putRelationshipField(mapOfValues,fieldDesc,prefix); // <== recursion
                            // remove the AutoFieldDefaultValue instance from the map
                            mapOfValues.remove(fullyQualifiedFieldName);
                        } 
                    }
                }else { // no override value provided for the field
                    // field default value required and field not mentioned in definedOptionalFields or field mentioned in definedRequiredFields
                    Boolean isRequired = (isDefaultValueRequired(fieldDesc) && !definedOptionalFields.contains(fieldNameLowerCase)) || definedRequiredFields.contains(fieldNameLowerCase);
                    if(fieldDesc.getRelationshipName() == null){ // field
                        if(isRequired){
                            // put a fieldDefaultValue instance of the field in order to auto-generate the field default value
                            mapOfValues.put(fullyQualifiedFieldName,new FieldDefaultValue(this,sObjectDesc,fieldDesc));
                        }
                    }else { // relationship
                        String relationshipName = fieldDesc.getRelationshipName().toLowerCase();
                        if(isRequired || relationshipKeySet.contains(relationshipName)){ // relationship required or mentioned in the relationshipKeySet
                            // put a field relationship in the map of values
                            putRelationshipField(mapOfValues,fieldDesc,prefix); // <== recursion
                        }
                    }
                }
            }
        }

        /**
        * @description put a relationship field into a map of values
        * @param mapOfValues (Map<String,IFieldDefaultValue>): map of values in which relationship field will be put
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information information of the relationship field
        * @param prefix (String): prefix of the relationship field (example : Contact.Account.)
        */
        @TestVisible
        private void putRelationshipField(Map<String,IFieldDefaultValue> mapOfValues, Schema.DescribeFieldResult fieldDesc, String prefix){
            String relationshipName = fieldDesc.getRelationshipName().toLowerCase();
            String fullyQualifiedRelationshipName = prefix+relationshipName;
            // at least add (fullyQualifiedRelationshipName.id,null) to force the instantiation of the related sObject
            // in case the sObject has no required fields
            mapOfValues.put(fullyQualifiedRelationshipName+DOT+'id',new FieldDefaultValue(null));
            // get the related sObject instance
            SObjectType refSObjectType = fieldDesc.getReferenceTo().get(0);
            // generate a map for the related sObject
            generateDefaultMapOfValues(refSObjectType,mapOfValues,fullyQualifiedRelationshipName+DOT);
        }

        /**
        * @description manage the map of values and the defined required fields for Account if person account enabled org
        * @param mapOfValues (Map<String,IFieldDefaultValue>): map of values from which the field value id will be extracted
        * @param prefix (String): prefix of the relationship field (example : Contact.Account.)
        * @param definedRequiredFields (Set<String>): Set of defined required fields
        */
        @TestVisible
        private void managePersonAccountOrgEnabled(Map<String,IFieldDefaultValue> mapOfValues, String prefix, Set<String> definedRequiredFields){
            String fullyQualifieldRecordTypeIdFieldName = prefix+'recordtypeid';
            IFieldDefaultValue recordTypeIdDefaultValue = mapOfValues.get(fullyQualifieldRecordTypeIdFieldName);
            if(recordTypeIdDefaultValue == null){
                recordTypeIdDefaultValue = new FieldDefaultValue(null);
            }
            if(recordTypeIdDefaultValue instanceof FieldDefaultValue){ // instance of FieldDefaultValue
                Object recordTypeIdValue = recordTypeIdDefaultValue.getValue(0);
                if(recordTypeIdValue == null) {
                    recordTypeIdValue = accountDefaultRecordTypeId;
                    mapOfValues.put(fullyQualifieldRecordTypeIdFieldName, new FieldDefaultValue(accountDefaultRecordTypeId));
                }
                try{
                    Id recordTypeId = Id.valueOf((String)recordTypeIdValue);
                    if(personAccountRecordTypes.contains(recordTypeId)){ // person account 
                        definedRequiredFields.add('lastname');
                    }else { // business account
                        definedRequiredFields.add('name');
                    }
                }catch(Exception e){
                    throw new TestDataFactoryException(formatErrorMessage(ERR_BAD_RECORDTYPE_ID_FOR_ACCOUNT,new List<String>{},e.getMessage()));
                }
            }else if(recordTypeIdDefaultValue instanceof ListFieldDefaultValue){ // instance of ListFieldDefaultValue
                throw new TestDataFactoryException(formatErrorMessage(ERR_LIST_VALUE_NOT_SUPPORTED,new List<String>{fullyQualifieldRecordTypeIdFieldName},''));
            }
        }

        /**
        * @description get defined set of required fields for a given sObject type and record type id
        * @param sObjectType (Schema.SObjectType): sObject type for which the defined required fields will be returned 
        * @param recordTypeValue (Object): record type id provided for to the sObject Type
        * @return set of defined required fields
        */
        @TestVisible
        private Set<String> getDefinedSObjectRequiredFields(Schema.SObjectType sObjectType){
            Set<String> definedRequiredFields = new Set<String>();
            Set<String> definedRequiredFieldsByDeveloper = defineSObjectRequiredFields(sObjectType);
            if(definedRequiredFieldsByDeveloper != null){
                definedRequiredFields.addAll(convertSetToLowerCase(definedRequiredFieldsByDeveloper));
            }
            
            return definedRequiredFields;
        }

        /**
        * @description get defined set of optional fields for a given sObject type
        * @param sObjectType (Schema.SObjectType): sObject type for which the defined optional fields will be returned 
        * @param recordTypeValue (Object): record type id provided for to the sObject Type
        * @return set of defined optional fields
        */
        @TestVisible
        private Set<String> getDefinedSObjectOptionalFields(Schema.SObjectType sObjectType){
            Set<String> definedOptionalFields = new Set<String>();
            Set<String> definedOptionalFieldsByDeveloper = defineSObjectOptionalFields(sObjectType);
            if(definedOptionalFieldsByDeveloper != null){
                definedOptionalFields.addAll(convertSetToLowerCase(definedOptionalFieldsByDeveloper));
            }
            
            return definedOptionalFields;
        }

        /**
        * @description get relationship names keyset that starts with a given prefix
        * @param keySetOverride (Set<String>): keySet of fully qualified field names
        * @param prefix (String): prefix (example : Contact.Account.)
        * @return set of relationship names
        * @example 
        * keySetOverride = {Contact.Account.Name,Contact.FirstName}
        * Prefix : Contact.
        * Result : {Account}
        */
        @TestVisible
        private Set<String> getRelationshipKeySet(Set<String> keySetOverride, String prefix){
            Set<String> relationshipKeySet = new Set<String>();
            String prefixLowerCase = prefix.toLowerCase();
            // loop through the keySet
            for(String fullyQualifiedFieldName : keySetOverride){
                fullyQualifiedFieldName = fullyQualifiedFieldName.toLowerCase();
                if(fullyQualifiedFieldName.startsWith(prefixLowerCase)){ // starts with the prefix
                    String fullyQualifiedFieldNameAfterPrefix = fullyQualifiedFieldName.substringAfter(prefixLowerCase)+'';
                    if(fullyQualifiedFieldNameAfterPrefix.contains(DOT)){ // if there is a relationship after the prefix
                        // add the relationship name after the prefix
                        relationshipKeySet.add(fullyQualifiedFieldName.substringBetween(prefixLowerCase,DOT));
                    }
                }
            }
            return relationshipKeySet;
        }

        /**
        * @description converting a map from Map(key:String,value:Object) to Map(key:String,value:IFieldDefaultValue)
        * @param prefix (String): prefix (example : Contact.Account.)
        * @param mapOfValues (Map<String,Object>): map of values to convert
        * @return converted map
        */
        @TestVisible
        private Map<String,IFieldDefaultValue> convertMapValueTypes(String prefix, Map<String,Object> mapOfValues){ 
            Map<String,IFieldDefaultValue> convertedMap = new Map<String,IFieldDefaultValue>();
            if(mapOfValues == null){
                return convertedMap;
            } 
            for(String name : mapOfValues.keySet()){
                if(name != null){
                    Object value = mapOfValues.get(name);
                    String fullyQualifiedName = prefix + name.trim().toLowerCase();
                    if(value instanceof IFieldDefaultValue){
                        // cast the value if already of type IFieldDefaultValue
                        convertedMap.put(fullyQualifiedName,(IFieldDefaultValue)value);
                    }else if(value instanceof Map<String,Object>){
                        // convert the sub map of values and putting into the main map of values
                        convertedMap.putAll(convertMapValueTypes(fullyQualifiedName+DOT,(Map<String,Object>)value));
                    }else if(value instanceof SObject){
                        String fullyQualifiedFieldName = getFieldNameFromRelationshipName(fullyQualifiedName);
                        if(value instanceof List<SObject>){
                            // cast to list of sObject and wrap it in a ListRelationshipFieldDefaultValue instance
                            convertedMap.put(fullyQualifiedFieldName,new ListRelationshipFieldDefaultValue((List<SObject>)value));
                        }else{
                            // wrap the value in a RelationshipFieldDefaultValue instance
                            convertedMap.put(fullyQualifiedFieldName,new RelationshipFieldDefaultValue((SObject)value));
                        }
                    }else if(value instanceof List<Object>){
                        // cast to list objects and wrap it in a ListFieldDefaultValue instance
                        convertedMap.put(fullyQualifiedName,new ListFieldDefaultValue((List<Object>)value));
                    }else{
                        // wrap the value in a FieldDefaultValue instance
                        convertedMap.put(fullyQualifiedName,new FieldDefaultValue(value));
                    }
                }
            }
            return convertedMap;
        }

        /**
        * @description converting a given set of String to set of lower case string values
        * @param setOfValues (Set<String>): set of values to convert to lower case
        * @return converted set
        */
        @TestVisible
        private Set<String> convertSetToLowerCase(Set<String> setOfValues){
            Set<String> convertedSet = new Set<String>();
            if(setOfValues == null){
                return convertedSet;
            } 
            for(String value : setOfValues){
                if(value != null){
                    convertedSet.add(value.trim().toLowerCase());
                }
            }
            return convertedSet;
        }

        /**
        * @description test if a field requires a default value
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @return true if a default value is required
        */
        @TestVisible
        private Boolean isDefaultValueRequired(Schema.DescribeFieldResult fieldDesc){
            return 
                !fieldDesc.isDefaultedOnCreate() // does not have a defaut value on creation
                && !fieldDesc.isAutoNumber() // is not an auto number
                && !fieldDesc.isNillable() // is required
                && fieldDesc.isCreateable(); // value can be set on creation 
        }

        /**
        * @description generate a default value for a given field of an sObject 
        *                       depending on the field type, the corresponding get{FieldType}DefaultValue method will be invoked to retrieve the default value
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return the generated field default value
        */
        @TestVisible
        private Object getDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            if(fieldDesc != null){
                // DisplayType Enum -> https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm
                switch on fieldDesc.getType() {
                    when Base64 {
                        return getBase64DefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Boolean {
                        return getCheckboxDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Currency {
                        return getCurrencyDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Date {
                        return getDateDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Datetime {
                        return getDateTimeDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Email {
                        return getEmailDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Location {
                        return getGeolocationDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Integer, Double {
                        return getNumberDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Percent {
                        return getPercentDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Phone {
                        return getPhoneDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Picklist {
                        return getPicklistDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when MultiPicklist {
                        return getMultiPicklistDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when String {
                        return getTextDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when TextArea {
                        return getTextAreaDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when Time {
                        return getTimeDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                    when URL {
                        return getURLDefaultValue(sObjectDesc,fieldDesc,recordIndex);
                    }
                }
            }
            return null;
        }

        /**
        * @description get the Saleforce default value for given picklist
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @return The picklist default value on Salesforce
        */
        @TestVisible
        private String getSFDefaultPicklistValue(Schema.DescribeFieldResult fieldDesc){
            if(fieldDesc != null){
                List<Schema.PicklistEntry> pickVals = fieldDesc.getPicklistValues();        
                for (Schema.PicklistEntry pickVal: pickVals) {
                    if (pickVal.isDefaultValue()) {
                        return pickVal.getValue(); // default value
                    }    
                }
                // if no default value is set, return the first value
                return pickVals.get(0).getValue();
            }
            return null;
        }

        /* ============================================================================================= */
        /* =======================================  virtual methods ==================================== */
        /* ============================================================================================= */
        /**
        * @description define a set of required fields for a given sObject
        * @param sObjectType (Schema.SObjectType): sObject Type for which the required fields will be defined
        * @return set of defined required fields
        */
        public virtual Set<String> defineSObjectRequiredFields(Schema.SObjectType sObjectType){
            return null;
        }
        /**
        * @description define a set of optional fields for a given sObject
        * @param sObjectType (Schema.SObjectType): sObject Type for which the optional fields will be defined
        * @return set of defined optional fields
        */
        public virtual Set<String> defineSObjectOptionalFields(Schema.SObjectType sObjectType){
            return null;
        }
        /**
        * @description get the default value for Base64 field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return base64 default value
        */
        public virtual Blob getBase64DefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return Blob.valueOf(recordIndex.format());
        }   
        /**
        * @description get the default value for checkbox field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return checkbox default value
        */
        public virtual Boolean getCheckboxDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return false;
        }
        /**
        * @description get the default value for Currency field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return currency default value
        */
        public virtual Decimal getCurrencyDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return recordIndex;
        }
        /**
        * @description get the default value for Date field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return date default value
        */
        public virtual Date getDateDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return Date.today();
        }
        /**
        * @description get the default value for Datetime field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return datetime default value
        */
        public virtual Datetime getDateTimeDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return Datetime.now();
        }
        /**
        * @description get the default value for Email field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return email default value
        */
        public virtual String getEmailDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return 'test'+recordIndex.format()+'@email.com';
        }
        /**
        * @description get the default value for Geolocation field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return geolocation default value
        */
        public virtual Location getGeolocationDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return Location.newInstance(0,0);
        }       
        /**
        * @description get the default value for Number field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return number default value
        */
        public virtual Decimal getNumberDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return recordIndex;
        }
        /**
        * @description get the default value for Percent field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return percent default value
        */
        public virtual Decimal getPercentDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return recordIndex;
        }
        /**
        * @description get the default value for Phone field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return phone default value
        */
        public virtual String getPhoneDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return '01 23 45 67 89';
        }
        /**
        * @description get the default value for Picklist field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return picklist default value
        */
        public virtual String getPicklistDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return getSFDefaultPicklistValue(fieldDesc);
        }
        /**
        * @description get the default value for Multipicklist field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return multipicklist default value
        */
        public virtual String getMultiPicklistDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return getSFDefaultPicklistValue(fieldDesc);
        }
        /**
        * @description get the default value for Text field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return text default value
        */
        public virtual String getTextDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return 'test'+recordIndex.format();
        }
        /**
        * @description get the default value for TextArea field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return text area default value
        */
        public virtual String getTextAreaDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return 'test'+recordIndex.format();
        }
        /**
        * @description get the default value for Time field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return time default value
        */
        public virtual Time getTimeDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return Time.newInstance(12, 0, 0, 0);
        }
        /**
        * @description get the default value for URL field type
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return URL default value
        */
        public virtual String getURLDefaultValue(Schema.DescribeSObjectResult sObjectDesc, Schema.DescribeFieldResult fieldDesc, Integer recordIndex){
            return 'http://test' + recordIndex + '.com';
        }

    }

    /**
    * @description common interface fo the field default value classes
    */
    public interface IFieldDefaultValue{
        /**
        * @description get the value wrapped for a given record index
        */
        Object getValue(Integer recordIndex);
    }

    /**
    * @description wrapper for default value that will be auto generated 
    */
    public class AutoFieldDefaultValue implements IFieldDefaultValue{
        /**
        * @description get the value wrapped for a given record index
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return field default value
        */
        public Object getValue(Integer recordIndex){
            return null;
        }
    }

    /**
    * @description wrapper for a field default value
    */
    @TestVisible
    private class FieldDefaultValue implements IFieldDefaultValue{
        /** Instance of the container class */
        private DefaultValueProvider dvPrvdr = null;
        /** Field value */
        private Object value = null;
        /** SObject describe information */
        private Schema.DescribeSObjectResult sObjectDesc = null;
        /** Field describe information */
        private Schema.DescribeFieldResult fieldDesc = null;

        /**
        * @description construtor to wrap a griven field value
        * @param value (Object): the value that will be wrapped
        */
        public FieldDefaultValue(Object value){
            this.value = value;
        }   

        /**
        * @description construtor to wrap a field value that will be generated based on the given sObject & Field describe informations
        * @param dvPrvdr (DefaultValueProvider): default value provider instance of the containing class DefaultValueProvider
        * @param sObjectDesc (Schema.DescribeSObjectResult): sObject describe information
        * @param fieldDesc (Schema.DescribeFieldResult): field describe information
        */  
        public FieldDefaultValue(DefaultValueProvider dvPrvdr,Schema.DescribeSObjectResult sObjectDesc,Schema.DescribeFieldResult fieldDesc){
            this.dvPrvdr = dvPrvdr;
            this.sObjectDesc = sObjectDesc;
            this.fieldDesc = fieldDesc;
        }

        /**
        * @description get the wrapped value for a given record index
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return field default value
        */
        public Object getValue(Integer recordIndex){
            if(dvPrvdr != null){ // if default value provider is set
                // generate the value from the sObject & field describe informations
                return dvPrvdr.getDefaultValue(sObjectDesc,fieldDesc,recordIndex);
            }else {
                if(value instanceof String) // if value is of type string merge the index value
                    return mergeValue((String)value,'index',recordIndex.format());
                else return value;
            }
        }
    }

    /**
    * @description wrapper for a relationship field default value
    */
    @TestVisible
    private class RelationshipFieldDefaultValue implements IFieldDefaultValue{
        /** Field value */
        private SObject sObjectValue = null;

        /**
        * @description construtor to wrap a griven field sObject value
        * @param sObjectValue (Object): the sObject value that will be wrapped
        */
        public RelationshipFieldDefaultValue(SObject sObjectValue){
            this.sObjectValue = sObjectValue;
        }   

        /**
        * @description get the wrapped sObject value for a given record index
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return Id of the sObject field default value
        */
        public Object getValue(Integer recordIndex){
            return sObjectValue.Id;
        }
    }

    /**
    * @description wrapper for a list of field default values
    */
    @TestVisible
    private class ListFieldDefaultValue implements IFieldDefaultValue{
        /** Field list values */
        private List<Object> listValues = null;

        /**
        * @description construtor to wrap a griven field list of values
        * @param listValues (List<Object>): the list of values that will be wrapped
        */
        public ListFieldDefaultValue(List<Object> listValues){
            this.listValues = listValues;
        }   

        /**
        * @description get the wrapped value for a given record index
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return value at recordIndex position of list field default values
        */
        public Object getValue(Integer recordIndex){
            return listValues.get(Math.mod(recordIndex,listValues.size()));
        }

        /**
        * @description return the size of the wrapped list of values
        */
        public Integer size(){
            return listValues.size();
        }
    }

    /**
    * @description wrapper for a list of relationship field default values
    */
    @TestVisible
    private class ListRelationshipFieldDefaultValue implements IFieldDefaultValue{
        /** Field list sObject values */
        private List<SObject> listSObjectValues = null;

        /**
        * @description construtor to wrap a griven field list of sObject values
        * @param listSObjectValues (List<SObject>): the list of values that will be wrapped
        */
        public ListRelationshipFieldDefaultValue(List<SObject> listSObjectValues){
            this.listSObjectValues = listSObjectValues;
        }   

        /**
        * @description get the wrapped list sObject values for a given record index
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return id of the sObject at recordIndex position of list relationship field default values
        */
        public Object getValue(Integer recordIndex){
                return listSObjectValues.get(recordIndex).Id;
        }

        /**
        * @description return the size of the wrapped list of the sObject values
        */
        public Integer size(){
            return listSObjectValues.size();
        }
    }

    /* ===========================  Utility methods  =========================== */

    /**
     * @description get the field tokens map of an sObject type with caching
     * @param sObjectType (Schema.SObjectType): sObject type for which the map of field tokens will be returned
     * @return field tokens map
     */
     @TestVisible
    private static Map<String, Schema.SObjectField> getFieldTokensMap(Schema.SObjectType sObjectType){
        if(mapOfFieldTokensMap.containsKey(sObjectType)){
            return mapOfFieldTokensMap.get(sObjectType);
        }else {
            Map<String, Schema.SObjectField> fieldTokensMap = sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
            mapOfFieldTokensMap.put(sObjectType,fieldTokensMap);
            return fieldTokensMap;
        }
    }

    /**
    * @description get field name from a relationship name
    * @param relationshipName (String): relationship name
    * @return field name 
    */
    @TestVisible
    private static String getFieldNameFromRelationshipName(String relationshipName){
        String relationshipNameLowerCase = relationshipName.toLowerCase();
        if(relationshipNameLowerCase.contains('__r')) // custom relationship 
            return relationshipNameLowerCase.replace('__r', '__c');
        return relationshipNameLowerCase+'id'; // standard relationship
    }

    /**
    * @description merge given value in a string
    * @param text (String): text with a merge value
    * @param name (String): name of the merge value
    * @param value (String): value to be merged
    * @return text with merged value
    */
    @TestVisible
    private static String mergeValue(String text, String name, String value){
        if(text == null) return null;
        String pattern = '(?i)\\{!'+name+'\\}';
        return text.replaceAll(pattern,value);
    }

    /**
    * @description format an error message
    * @param message (String): error message
    * @param mergeValues (List<String>): values to be merge in the error message
    * @param originalMessage (String): original error message
    * @return error message
    */
    @TestVisible
    private static String formatErrorMessage(String message, List<String> mergeValues, String originalMessage){
        String errorMessage = String.format(message,mergeValues);
        // if originalMessage is passed as param it will be include in the errorMessage
        if(!String.isBlank(originalMessage)) errorMessage +='\n'+'Original error message : '+originalMessage;
        return errorMessage;
    }
    
    /**
    * @description this is a dummy test method needed in order to create a managed package for TestDataFactory_V2
    */
    @IsTest
    private static void dummyTest(){}

    /**
    * @description Test Data Factory Exception
    */
    public class TestDataFactoryException extends Exception {}

    public static List<Account_Type__c> createTestDataForAccountType(Boolean doInsert) {
        List<Account_Type__c> accountTypeList = createTestDataForAccountType(doInsert, 'Retail Customer', 'Customers');
        return accountTypeList;
    }

    public static List<Account_Type__c> createTestDataForAccountType(Boolean doInsert, String name, String appliesTo) {
        Account_Type__c accountType = (Account_Type__c)createSObject(Constants.NAMESPACE+'Account_Type__c', new Map<String,Object> {
            'Name' => name,
            Constants.NAMESPACE+'Default__c' => true,
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Applies_To__c' => appliesTo
        }, doInsert);
        List<Account_Type__c> accountTypeList = new List<Account_Type__c>();
        accountTypeList.add(accountType);
        return accountTypeList;
    }

    public static List<Category__c> createTestDataForCategory(Boolean doInsert) {
        List<Category__c> categoryList = (List<Category__c>)createSObjectList(Constants.NAMESPACE+'Category__c', new Map<String,Object> {
            'Name' => 'Test Category',
            Constants.NAMESPACE+'Default__c' => true,
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Type__c' => new List<String>{'Labour','Adjustment','Fee','Internal Expense','Miscellaneous','Part','Sublet','Tax','Unit','Trade-in','Stamp Duty','Deductible','Stocked Trade','Lien Payout'},
            Constants.NAMESPACE+'Description__c' => 'Test Category Description'
        }, 14, doInsert);
        return categoryList;
    }

    public static List<Price_Level__c> createTestDataForPriceLevel(Boolean doInsert) {
        Price_Level__c priceLevel = (Price_Level__c)createSObject(Constants.NAMESPACE+'Price_Level__c', new Map<String,Object> {
            Constants.NAMESPACE+'Name__c' => 'Default Price Level',
            Constants.NAMESPACE+'Default__c' => true,
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Discount_Markup__c' => 10,
            Constants.NAMESPACE+'Labour_Rate__c' => 10,
            Constants.NAMESPACE+'Part_Price_Base__c' => 'Price'
        }, doInsert);
        List<Price_Level__c> priceLevelList = new List<Price_Level__c>();
        priceLevelList.add(priceLevel);
        return priceLevelList;
    }

    public static List<Account> createTestDataForCustomer(List<Account_Type__c> accountTypeList, List<Price_Level__c> priceLevelList, Boolean doInsert) {
        Account acc = (Account)createSObject(Constants.NAMESPACE+'Account', new Map<String,Object> {
            Constants.NAMESPACE+'Is_Customer__c' => true,
            Constants.NAMESPACE+'Type__c' => 'Individual',
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Account_Type__c' => accountTypeList[0].Id,
            Constants.NAMESPACE+'Price_Level__c' => priceLevelList[0].Id
        }, doInsert);
        List<Account> accountList = new List<Account>();
        accountList.add(acc);
        return accountList;
    }

    public static List<Sales_Tax_Item__c> createTestDataForSalesTaxItem(List<Category__c> categoryList, Boolean doInsert) { 
        List<Sales_Tax_Item__c> salesTaxItemList = createTestDataForSalesTaxItem('Sell', categoryList, doInsert);
        return salesTaxItemList;
    }

    public static List<Sales_Tax_Item__c> createTestDataForSalesTaxItem(String taxType, List<Category__c> categoryList, Boolean doInsert) { 
        Category__c categoryRec = new Category__c();
        for(Category__c category : categoryList) {
            if(category.Type__c == 'Tax') {
                categoryRec = category;
                break;
            }
        }
        Sales_Tax_Item__c salesTaxItem1 = (Sales_Tax_Item__c)createSObject(Constants.NAMESPACE+'Sales_Tax_Item__c', new Map<String,Object> {
            Constants.NAMESPACE+'Forms_Label__c' => 'State Collected',
            Constants.NAMESPACE+'Name__c' => 'State Collected',
            Constants.NAMESPACE+'Rate__c' => 10,
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Category__c' => categoryRec.Id,
            Constants.NAMESPACE+'Tax_Misc__c' => true,
            Constants.NAMESPACE+'Tax_Parts__c' => true,
            Constants.NAMESPACE+'Tax_Labour__c' => true,
            Constants.NAMESPACE+'Tax_Units__c' => true,
            Constants.NAMESPACE+'Tax_Type__c' => taxType,
            Constants.NAMESPACE+'Rate_Type__c' => 'Fixed rate'
        }, doInsert);

        Sales_Tax_Item__c salesTaxItem2 = (Sales_Tax_Item__c)createSObject(Constants.NAMESPACE+'Sales_Tax_Item__c', new Map<String,Object> {
            Constants.NAMESPACE+'Forms_Label__c' => 'State Escalating',
            Constants.NAMESPACE+'Name__c' => 'State Escalating',
            Constants.NAMESPACE+'Rate__c' => 0,
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Category__c' => categoryList[0].Id,
            Constants.NAMESPACE+'Tax_Misc__c' => true,
            Constants.NAMESPACE+'Tax_Parts__c' => true,
            Constants.NAMESPACE+'Tax_Labour__c' => true,
            Constants.NAMESPACE+'Tax_Units__c' => true,
            Constants.NAMESPACE+'Tax_Type__c' => taxType,
            Constants.NAMESPACE+'Rate_Type__c' => 'Escalating rate',
            Constants.NAMESPACE+'Maximum_Tax_Amount__c' => 150,
            Constants.NAMESPACE+'Max_Taxable_Amount_Tier_1__c' => 2000,
            Constants.NAMESPACE+'Max_Taxable_Amount_Tier_2__c' => 5000,
            Constants.NAMESPACE+'Minimum_Tax_Amount__c' => 0,
            Constants.NAMESPACE+'Tax_Rate_Tier_1__c' => 3,
            Constants.NAMESPACE+'Tax_Rate_Tier_2__c' =>  4,
            Constants.NAMESPACE+'Tax_Rate_Tier_3__c' => 5 
        }, doInsert);

        Sales_Tax_Item__c salesTaxItem3 = (Sales_Tax_Item__c)createSObject(Constants.NAMESPACE+'Sales_Tax_Item__c', new Map<String,Object> {
            Constants.NAMESPACE+'Forms_Label__c' => 'State Tiered',
            Constants.NAMESPACE+'Name__c' => 'State Tiered',
            Constants.NAMESPACE+'Rate__c' => 0,
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Category__c' => categoryList[0].Id,
            Constants.NAMESPACE+'Tax_Misc__c' => true,
            Constants.NAMESPACE+'Tax_Parts__c' => true,
            Constants.NAMESPACE+'Tax_Labour__c' => true,
            Constants.NAMESPACE+'Tax_Units__c' => true,
            Constants.NAMESPACE+'Tax_Type__c' => taxType,
            Constants.NAMESPACE+'Rate_Type__c' => 'Tiered rate',
            Constants.NAMESPACE+'Maximum_Tax_Amount__c' => 9999999,
            Constants.NAMESPACE+'Max_Taxable_Amount_Tier_1__c' => 2000,
            Constants.NAMESPACE+'Max_Taxable_Amount_Tier_2__c' => 5000,
            Constants.NAMESPACE+'Minimum_Tax_Amount__c' => 50,
            Constants.NAMESPACE+'Tax_Rate_Tier_1__c' => 2.5,
            Constants.NAMESPACE+'Tax_Rate_Tier_2__c' =>  3.5,
            Constants.NAMESPACE+'Tax_Rate_Tier_3__c' => 4.5
        }, doInsert);
        List<Sales_Tax_Item__c> salesTaxItemList = new List<Sales_Tax_Item__c> {
            salesTaxItem1,
            salesTaxItem2,
            salesTaxItem3
        };  
        return salesTaxItemList;
    }

    public static List<Tax_Exemption__c> createTestDataForTaxExemption(List<Account_Type__c> accountTypeList, List<Sales_Tax_Item__c> salesTaxItemList, Boolean doInsert) {
        Tax_Exemption__c taxExemption = (Tax_Exemption__c)createSObject(Constants.NAMESPACE+'Tax_Exemption__c', new Map<String,Object> {
            Constants.NAMESPACE+'Account_Type__c' => accountTypeList[0].Id,
            Constants.NAMESPACE+'Sales_Tax_Item__c' => salesTaxItemList[0].Id
        }, doInsert);
        List<Tax_Exemption__c> taxExemptionList = new List<Tax_Exemption__c>();
        taxExemptionList.add(taxExemption);
        return taxExemptionList;
    }

    public static List<Sales_Tax__c> createTestDataForSalesTax(Boolean doInsert) {
        List<Sales_Tax__c> salesTaxList = createTestDataForSalesTax(doInsert, 'Sell');
        return salesTaxList;
    }

    public static List<Sales_Tax__c> createTestDataForSalesTax(Boolean doInsert, String taxType) {
        Sales_Tax__c salesTax = (Sales_Tax__c)createSObject(Constants.NAMESPACE+'Sales_Tax__c', new Map<String,Object> {
            Constants.NAMESPACE+'Forms_Label__c' => 'Sales Tax',
            Constants.NAMESPACE+'Name__c' => 'Country Collected',
            Constants.NAMESPACE+'Rate__c' => 10,
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Forms_List_Taxes__c' => true,
            Constants.NAMESPACE+'Default__c' => true,
            Constants.NAMESPACE+'Labour_Tax__c' => 10,
            Constants.NAMESPACE+'Tax_Type__c' => taxType
        }, doInsert);
        List<Sales_Tax__c> salesTaxList = new List<Sales_Tax__c>();
        salesTaxList.add(salesTax);
        return salesTaxList;
    }

    public static List<Applicable_Taxes__c> createTestDataForApplicableTax(List<Sales_Tax__c> salesTaxList, List<Sales_Tax_Item__c> salesTaxItemList, Boolean doInsert) {
        Applicable_Taxes__c applicableTax1 = (Applicable_Taxes__c)createSObject(Constants.NAMESPACE+'Applicable_Taxes__c', new Map<String,Object> {
            Constants.NAMESPACE+'Sales_Tax__c' => salesTaxList[0].Id,
            Constants.NAMESPACE+'Sales_Tax_Item__c' => salesTaxItemList[0].Id
        }, doInsert);
        
        Applicable_Taxes__c applicableTax2 = (Applicable_Taxes__c)createSObject(Constants.NAMESPACE+'Applicable_Taxes__c', new Map<String,Object> {
            Constants.NAMESPACE+'Sales_Tax__c' => salesTaxList[0].Id,
            Constants.NAMESPACE+'Sales_Tax_Item__c' => salesTaxItemList[1].Id
        }, doInsert);

        Applicable_Taxes__c applicableTax3 = (Applicable_Taxes__c)createSObject(Constants.NAMESPACE+'Applicable_Taxes__c', new Map<String,Object> {
            Constants.NAMESPACE+'Sales_Tax__c' => salesTaxList[0].Id,
            Constants.NAMESPACE+'Sales_Tax_Item__c' => salesTaxItemList[2].Id
        }, doInsert);
        
        List<Applicable_Taxes__c> applicableTaxList = new List<Applicable_Taxes__c> {
            applicableTax1, applicableTax2, applicableTax3
        };
        return applicableTaxList;
    }

    public static List<Fee__c> createTestDataForFee(List<Sales_Tax__c> salesTaxList, List<Category__c> categoryList, Boolean doInsert) {
        Category__c categoryRec = new Category__c();
        for(Category__c category : categoryList) {
            if(category.Type__c == 'Fee') {
                categoryRec = category;
                break;
            }
        }
        Fee__c fee = (Fee__c)createSObject(Constants.NAMESPACE+'Fee__c', new Map<String,Object> {
            Constants.NAMESPACE+'Cost_Rate__c' => 0,
            Constants.NAMESPACE+'Is_Include_In_Profit_Calculation__c' => true,
            Constants.NAMESPACE+'Price__c' => 100,
            Constants.NAMESPACE+'Taxable__c' => true,
            Constants.NAMESPACE+'Type__c' => 'Selling',
            Constants.NAMESPACE+'Cost_Method__c' => 'Fixed Cost',
            Constants.NAMESPACE+'Applicable_Tax__c' => salesTaxList[0].Id,
            Constants.NAMESPACE+'Code__c' => 'feecode',
            Constants.NAMESPACE+'Category__c' => categoryRec.Id,
            Constants.NAMESPACE+'Active__c' => true
        }, doInsert);
        List<Fee__c> feeList = new List<Fee__c>();
        feeList.add(fee);
        return feeList;
    }

    public static List<Linked_Fee__c> createTestDataForLinkedFee(List<Fee__c> feeList, Boolean doInsert) {
        Linked_Fee__c linkedFee = (Linked_Fee__c)createSObject(Constants.NAMESPACE+'Linked_Fee__c', new Map<String,Object> {
            Constants.NAMESPACE+'Description__c' => 'edoceef',
            Constants.NAMESPACE+'Fee__c' => feeList[0].Id,
            Constants.NAMESPACE+'Price__c' => 1,
            Constants.NAMESPACE+'Related_To__c' => 'Merchandise'
        }, doInsert);
        List<Linked_Fee__c> linkedFeeList = new List<Linked_Fee__c>();
        linkedFeeList.add(linkedFee);
        return linkedFeeList;
    }

    public static List<CO_Header__c> createTestDataForCOHeader(Boolean doInsert) {
        CO_Header__c coHeader = (CO_Header__c)createSObject(Constants.NAMESPACE+'CO_Header__c', doInsert); 
        List<CO_Header__c> coHeaderList = new List<CO_Header__c>();
        coHeaderList.add(coHeader);
        return coHeaderList;
    }

    public static List<CO_Invoice_Header__c> createTestDataForCOInvoiceHeader(List<CO_Header__c> coHeaderList, Boolean doInsert) {
        CO_Invoice_Header__c coInvoiceHeader = (CO_Invoice_Header__c)createSObject(Constants.NAMESPACE+'CO_Invoice_Header__c', new Map<String,Object> {
            Constants.NAMESPACE+'CO_Header__c' => coHeaderList[0].Id,
            Constants.NAMESPACE+'Invoice_Status__c' => 'Closed'
        }, doInsert);
        List<CO_Invoice_Header__c> coInvoiceHeaderList = new List<CO_Invoice_Header__c>();
        coInvoiceHeaderList.add(coInvoiceHeader);
        return coInvoiceHeaderList;
    }

    public static List<CO_Invoice_Payment__c> createTestDataForCOInvoicePayment(List<CO_Invoice_Header__c> coInvoiceHeaderList, Boolean doInsert) {
        CO_Invoice_Payment__c coInvoicePayment = (CO_Invoice_Payment__c)createSObject(Constants.NAMESPACE+'CO_Invoice_Payment__c', new Map<String,Object> {
            Constants.NAMESPACE+'CO_Invoice_Header__c' => coInvoiceHeaderList[0].Id,
            Constants.NAMESPACE+'Amount__c' => 1000,
            Constants.NAMESPACE+'Payment_Method__c' => 'AR Credit'
        }, doInsert);
        List<CO_Invoice_Payment__c> coInvoicePaymentList = new List<CO_Invoice_Payment__c>();
        coInvoicePaymentList.add(coInvoicePayment);
        return coInvoicePaymentList;
    }

    public static List<CO_Deposit__c> createTestDataForCODeposit(List<CO_Header__c> coHeaderList, Boolean doInsert) {
        CO_Deposit__c coDeposit = (CO_Deposit__c)createSObject(Constants.NAMESPACE+'CO_Deposit__c', new Map<String,Object> {
            Constants.NAMESPACE+'CO_Header__c' => coHeaderList[0].Id,
            Constants.NAMESPACE+'Amount__c' => 1000,
            Constants.NAMESPACE+'Payment_Method__c' => 'Store Credit'
        }, doInsert);
        List<CO_Deposit__c> coDepositList = new List<CO_Deposit__c>();
        coDepositList.add(coDeposit);
        return coDepositList;
    }

    public static List<Deal__c> createTestDataForDeal(List<CO_Header__c> coHeaderList, Boolean doInsert) {
        Deal__c deal = (Deal__c)createSObject(Constants.NAMESPACE+'Deal__c', new Map<String,Object> {
            Constants.NAMESPACE+'CO_Header__c' => coHeaderList[0].Id
        }, doInsert);
        List<Deal__c> dealList = new List<Deal__c>();
        dealList.add(deal);
        return dealList;
    }

    public static List<Deal_Item__c> createTestDataForDealItem(List<Deal__c> dealList, Boolean doInsert) {
        Deal_Item__c dealItem = (Deal_Item__c)createSObject(Constants.NAMESPACE+'Deal_Item__c', new Map<String,Object> {
            Constants.NAMESPACE+'Deal__c' => dealList[0].Id,
            Constants.NAMESPACE+'Type__c' => 'Trade In',
            Constants.NAMESPACE+'Is_Stocked_In__c' => true
        }, doInsert);
        List<Deal_Item__c> dealItemList = new List<Deal_Item__c>();
        dealItemList.add(dealItem);
        return dealItemList;
    }

    public static List<Service_Order_Header__c> createTestDataForServiceOrderHeader(List<CO_Header__c> coHeaderList, Boolean doInsert) {
        Service_Order_Header__c soHeader = (Service_Order_Header__c)createSObject(Constants.NAMESPACE+'Service_Order_Header__c', new Map<String,Object> {
            Constants.NAMESPACE+'CO_Header__c' => coHeaderList[0].Id,
            Constants.NAMESPACE+'Work_Status__c' => 'Closed'
        }, doInsert);
        List<Service_Order_Header__c> soHeaderList = new List<Service_Order_Header__c>();
        soHeaderList.add(soHeader);
        return soHeaderList;
    }

    
    public static List<Account> createTestDataForVendor(Boolean doInsert) {
        List<Account> vendorList = createTestDataForVendor(doInsert, new List<Account_Type__c>(), new List<Sales_Tax__c>());
        return vendorList;
    }

    public static List<Account> createTestDataForVendor(Boolean doInsert, List<Account_Type__c> accountTypeList, List<Sales_Tax__c> purchaseTaxList) {
        Account vendor = (Account)createSObject(Constants.NAMESPACE+'Account', new Map<String,Object> {
            'Name' => TestDataFactory_V2.DEFAULT_VALUE,
            'Phone' => TestDataFactory_V2.DEFAULT_VALUE,
            'BillingCity' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Email__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Is_Vendor__c' => true,
            Constants.NAMESPACE+'Sublet_Purchases__c' => true,
            Constants.NAMESPACE+'Purchase_Tax__c' => purchaseTaxList.size() > 0 ? purchaseTaxList[0].Id : null,
            Constants.NAMESPACE+'Account_Type__c' => accountTypeList.size() > 0 ? accountTypeList[0].Id : null
        }, doInsert);
        List<Account> vendorList = new List<Account>();
        vendorList.add(vendor);
        return vendorList;
    }

    public static List<Part__c> createTestDataForPart(List<Category__c> categoryList, List<Account> vendorList, List<Sales_Tax__c> salesTaxList, Boolean doInsert) {
        Category__c categoryRec = new Category__c();
        for(Category__c category : categoryList) {
            if(category.Type__c == 'Part') {
                categoryRec = category;
                break;
            }
        }
        Part__c part = (Part__c)createSObject(Constants.NAMESPACE+'Part__c', new Map<String,Object> {
            Constants.NAMESPACE+'Part_Number__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Description__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Category__c' => categoryRec.Id,
            Constants.NAMESPACE+'Vendor__c' => vendorList[0].Id,
            Constants.NAMESPACE+'Applicable_Tax__c' => salesTaxList[0].Id,
            Constants.NAMESPACE+'Order_Lots__c' => 1,
            Constants.NAMESPACE+'Average_Cost__c' => 100,
            Constants.NAMESPACE+'Last_Cost__c' => 100,
            Constants.NAMESPACE+'MSRP__c' => 100,
            Constants.NAMESPACE+'Retail_Price__c' => 100,
            Constants.NAMESPACE+'Qty_In_Stock__c' => 5
        }, doInsert);
        List<Part__c> partList = new List<Part__c>();
        partList.add(part);
        return partList;
    }

    public static List<Kit_Header__c> createTestDataForKit(Boolean doInsert) {
        Kit_Header__c kitHeader = (Kit_Header__c)createSObject(Constants.NAMESPACE+'Kit_Header__c', new Map<String,Object> {
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Can_Split__c' => true,
            Constants.NAMESPACE+'Service_Kit__c' => false,
            Constants.NAMESPACE+'Description__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Code__c' => TestDataFactory_V2.DEFAULT_VALUE
        }, doInsert);
        List<Kit_Header__c> kitHeaderList = new List<Kit_Header__c>();
        kitHeaderList.add(kitHeader);
        return kitHeaderList;
    }

    public static List<Kit_Header_Line_Item__c> createTestDataForKitLineItem(List<Part__c> partList, List<Fee__c> feeList, List<Kit_Header__c> kitHeaderList, Boolean doInsert) {
        Kit_Header_Line_Item__c kitHeaderLineItem = (Kit_Header_Line_Item__c)createSObject(Constants.NAMESPACE+'Kit_Header_Line_Item__c', new Map<String,Object> {
            Constants.NAMESPACE+'Part__c' => partList[0].Id,
            Constants.NAMESPACE+'Qty_Needed__c' => 1,
            Constants.NAMESPACE+'Retail__c' => 110,
            Constants.NAMESPACE+'Kit_Price__c' => 110,
            Constants.NAMESPACE+'Item_Description__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Item_Code__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Kit_Header__c' => kitHeaderList[0].Id
        }, doInsert);

        Kit_Header_Line_Item__c kitHeaderLineItem1 = (Kit_Header_Line_Item__c)createSObject(Constants.NAMESPACE+'Kit_Header_Line_Item__c', new Map<String,Object> {
            Constants.NAMESPACE+'Fee__c' => feeList[0].Id,
            Constants.NAMESPACE+'Qty_Needed__c' => 1,
            Constants.NAMESPACE+'Retail__c' => 10,
            Constants.NAMESPACE+'Kit_Price__c' => 10,
            Constants.NAMESPACE+'Item_Description__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Item_Code__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Kit_Header__c' => kitHeaderList[0].Id
        }, doInsert);
        
        List<Kit_Header_Line_Item__c> kitHeaderLineItemList = new List<Kit_Header_Line_Item__c> {
            kitHeaderLineItem,
            kitHeaderLineItem1
        };
        return kitHeaderLineItemList;
    }

    public static List<Customer_Owned_Unit__c> createTestDataForUnit(List<Account> accountList, List<Sales_Tax__c> salesTaxList, String unitType, String status, Boolean doInsert) {
        Customer_Owned_Unit__c unit = (Customer_Owned_Unit__c)createSObject(Constants.NAMESPACE+'Customer_Owned_Unit__c', new Map<String,Object> {
            Constants.NAMESPACE+'VIN_Number__c' => '1234567890',
            Constants.NAMESPACE+'Unit_Type__c' => unitType,
            Constants.NAMESPACE+'Status__c' => status,
            Constants.NAMESPACE+'Account__c' => accountList.size() > 0 ? accountList[0].Id : null,
            Constants.NAMESPACE+'Unit_Make__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Unit_Model__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Sub_Model__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Taxable__c' => true,
            Constants.NAMESPACE+'Applicable_Tax__c' => salesTaxList[0].Id
        }, doInsert);
        List<Customer_Owned_Unit__c> unitList = new List<Customer_Owned_Unit__c> {
            unit
        };
        return unitList;
    }

    public static List<Labour_Code__c> createTestDataForLabour(List<Category__c> categoryList, List<Sales_Tax__c> salesTaxList, Boolean doInsert) {
        Category__c categoryRec = new Category__c();
        for(Category__c category : categoryList) {
            if(category.Type__c == 'Labour') {
                categoryRec = category;
                break;
            }
        }
        Labour_Code__c labour = (Labour_Code__c)createSObject(Constants.NAMESPACE+'Labour_Code__c', new Map<String,Object> {
            Constants.NAMESPACE+'Code__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Description__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Hours__c' => 1,
            Constants.NAMESPACE+'Fixed_Rate__c' => false,
            Constants.NAMESPACE+'Rate__c' => 100,
            Constants.NAMESPACE+'Category__c' => categoryRec.Id,
            Constants.NAMESPACE+'Taxable__c' => true,
            Constants.NAMESPACE+'Applicable_Tax__c' => salesTaxList[0].Id
        }, doInsert);
        List<Labour_Code__c> labourList = new List<Labour_Code__c> {
            labour
        };
        return labourList;
    }

    public static List<Product__c> createTestDataForSublet(List<Account> accountList, List<Category__c> categoryList, List<Sales_Tax__c> salesTaxList, Boolean doInsert) {
        Category__c categoryRec = new Category__c();
        for(Category__c category : categoryList) {
            if(category.Type__c == 'Sublet') {
                categoryRec = category;
                break;
            }
        }
        Product__c labour = (Product__c)createSObject(Constants.NAMESPACE+'Product__c', new Map<String,Object> {
            Constants.NAMESPACE+'Vendor__c' => accountList.size() > 0 ? accountList[0].Id : null,
            Constants.NAMESPACE+'Category__c' => categoryRec.Id,
            Constants.NAMESPACE+'Price__c' => 100,
            Constants.NAMESPACE+'Type__c' => 'Sublet',
            Constants.NAMESPACE+'Cost_Method__c' => 'Fixed Cost',
            Constants.NAMESPACE+'Description__c' => TestDataFactory_V2.DEFAULT_VALUE,
            Constants.NAMESPACE+'Cost__c' => 100,
            Constants.NAMESPACE+'Taxable__c' => true,
            Constants.NAMESPACE+'Applicable_Tax__c' => salesTaxList[0].Id
        }, doInsert);
        List<Product__c> subletList = new List<Product__c> {
            labour
        };
        return subletList;
    }

    public static List<Transaction_Type__c> createTestDataForTransactionType(List<Category__c> categoryList, Boolean doInsert) {
        Category__c categoryRec = new Category__c();
        for(Category__c category : categoryList) {
            if(category.Type__c == 'Labour') {
                categoryRec = category;
                break;
            }
        }
        Transaction_Type__c transactionType = (Transaction_Type__c)createSObject(Constants.NAMESPACE+'Transaction_Type__c', new Map<String,Object> {
            Constants.NAMESPACE+'Type__c' => 'Customer',
            Constants.NAMESPACE+'Labour_Category__c' => categoryRec.Id,
            Constants.NAMESPACE+'Default__c' => true,
            Constants.NAMESPACE+'Code_Label__c' => TestDataFactory_V2.DEFAULT_VALUE,    
            Constants.NAMESPACE+'Active__c' => true
        }, doInsert);
        List<Transaction_Type__c> transactionTypeList = new List<Transaction_Type__c> {
            transactionType
        };
        return transactionTypeList;
    }

    public static List<PO_Type__c> createTestDataForPOType(String vendorId, Boolean doInsert) {
        PO_Type__c poType = (PO_Type__c)createSObject(Constants.NAMESPACE+'PO_Type__c', new Map<String,Object> {
            Constants.NAMESPACE+'Code__c' => 'STANDARD',
            Constants.NAMESPACE+'Vendor__c' => vendorId,
            Constants.NAMESPACE+'IsDefault__c' => true
        }, doInsert);
        List<PO_Type__c> poTypeList = new List<PO_Type__c> {
            poType
        };
        return poTypeList;
    }

    public static List<Shop_Settings__c> createTestDataForShopSetting(Boolean doInsert, String name, String day, Boolean isWorking) {
        Shop_Settings__c shopSetting = (Shop_Settings__c)createSObject(Constants.NAMESPACE+'Shop_Settings__c', new Map<String,Object> {
            'Name' => name,
            Constants.NAMESPACE+'Day__c' => day,
            Constants.NAMESPACE+'Is_Working__c' => isWorking,
            Constants.NAMESPACE+'From_Time__c' => '8:00AM',
            Constants.NAMESPACE+'To_Time__c' => '5:00PM'
        }, doInsert);
        List<Shop_Settings__c> shopSettingList = new List<Shop_Settings__c> {
            shopSetting
        };
        return shopSettingList;
    }

    public static List<Technician__c> createTestDataForTechnician(Boolean doInsert, String technicianName) {
        Technician__c technician = (Technician__c)createSObject(Constants.NAMESPACE+'Technician__c', new Map<String,Object> {
            Constants.NAMESPACE+'Technician_Name__c' => technicianName,
            Constants.NAMESPACE+'Type__c' => 'Technician',
            Constants.NAMESPACE+'First_Name__c' => 'FirstName',
            Constants.NAMESPACE+'Last_Name__c' => 'LastName',
            Constants.NAMESPACE+'Active__c' => true,
            Constants.NAMESPACE+'Working_Days__c' => 'Monday; Tuesday; Wednesday; Thursday; Friday'
        }, doInsert);
        List<Technician__c> technicianList = new List<Technician__c> {
            technician
        };
        return technicianList;
    }
    
    public static List<Payroll_Time__c> createTestDataForPayrollClockingTime(Boolean doInsert, String employeeId, DateTime clockInTime, DateTime clockOutTime) {
        Payroll_Time__c payrollClockingTime = (Payroll_Time__c)createSObject(Constants.NAMESPACE+'Payroll_Time__c', new Map<String,Object> {
            Constants.NAMESPACE+'Technician__c' => employeeId,
            Constants.NAMESPACE+'Start_Date__c' => clockInTime,
            Constants.NAMESPACE+'End_Date__c' => clockOutTime
        }, doInsert);
        List<Payroll_Time__c> payrollClockingTimeList = new List<Payroll_Time__c> {
            payrollClockingTime
        };
        return payrollClockingTimeList;
    }

    public static List<Hours_Logged__c> createTestDataForHoursLogged(Boolean doInsert, String technicianId) {
        Hours_Logged__c hoursLogged = (Hours_Logged__c)createSObject(Constants.NAMESPACE+'Hours_Logged__c', new Map<String,Object> {
            Constants.NAMESPACE+'Technician__c' => technicianId,
            Constants.NAMESPACE+'Start_Date_Time__c' => System.today()
        }, doInsert);
        List<Hours_Logged__c> hoursLoggedList = new List<Hours_Logged__c> {
            hoursLogged
        };
        return hoursLoggedList;
    }

    public static List<Cash_Drawer__c> createTestDataForCashDrawer(Boolean doInsert, String name) {
        Cash_Drawer__c cashDrawer = (Cash_Drawer__c)createSObject(Constants.NAMESPACE+'Cash_Drawer__c', new Map<String,Object> {
            'Name' => name,
            Constants.NAMESPACE+'Active__c' => true
        }, doInsert);
        List<Cash_Drawer__c> cashDrawerList = new List<Cash_Drawer__c> {
            cashDrawer
        };
        return cashDrawerList;
    }

    public static List<SO_Status__c> createTestDataForServiceJobStatus() {
        List<SO_Status__c> soStatusRecInsertList = new List<SO_Status__c>();
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.Estimate, Short_Name__c = 'est', Order_No__c = 1, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-warm-grey-font', Background_Color__c = 'bp-white-ice'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.NEW_JOB, Short_Name__c = 'new', Order_No__c = 2, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-purpureus', Background_Color__c = 'bp-purple-light'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.TRIAGE_REQUIRED, Short_Name__c = 'triage', Order_No__c = 3, Is_Active__c = true, Text_Color__c = 'bp-red-font', Background_Color__c = 'bp-light-moss-green'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.TRIAGE_DONE, Short_Name__c = 'triage', Order_No__c = 4, Is_Active__c = true, Text_Color__c = 'bp-purpureus', Background_Color__c = 'bp-light-moss-green'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.CUSTOMER_TO_OK, Short_Name__c = 'cust', Order_No__c = 5, Is_Active__c = true, Text_Color__c = 'bp-red-font', Background_Color__c = 'bp-light-steel-blue'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.CUSTOMER_APPROVED, Short_Name__c = 'cust', Order_No__c = 6, Is_Active__c = true, Text_Color__c = 'bp-charcoal', Background_Color__c = 'bp-light-steel-blue'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.READY_TO_START, Short_Name__c = 'ready', Order_No__c = 7, Is_Active__c = true, Text_Color__c = 'bp-light-sea-green', Background_Color__c = 'bp-cyan-light'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.IN_PROGRESS, Short_Name__c = 'prog', Order_No__c = 8, Is_Active__c = true, Text_Color__c = 'bp-orange-dark-font', Background_Color__c = 'bp-orange-light'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.WAIT_FOR_PARTS, Short_Name__c = 'wait', Order_No__c = 9, Is_Active__c = true, Text_Color__c = 'bp-black ', Background_Color__c = 'bp-vivid-tangerine'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.PART_MGR_REVIEW, Short_Name__c = 'review', Order_No__c = 10, Is_Active__c = true, Text_Color__c = 'bp-black ', Background_Color__c = 'bp-crayola'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.SERV_MGR_REVIEW, Short_Name__c = 'review', Order_No__c = 11, Is_Active__c = true, Text_Color__c = 'bp-black ', Background_Color__c = 'bp-crayola'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = 'Other', Short_Name__c = 'other', Order_No__c = 12, Text_Color__c = 'bp-black ', Background_Color__c = 'bp-crayola'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.JOB_COMPLETE, Short_Name__c = 'comp', Order_No__c = 13, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-red-font', Background_Color__c = 'bp-middle-yellow'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.READY_TO_INVOICE, Short_Name__c = 'toinv', Order_No__c = 14, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-red-font', Background_Color__c = 'bp-middle-yellow'));
        soStatusRecInsertList.add(new SO_Status__c(Name__c = ServiceJobUtil.INVOICED, Short_Name__c = 'inv', Order_No__c = 15, Is_Active__c = true, Is_Required__c = true, Text_Color__c = 'bp-green-dark-font', Background_Color__c = 'bp-green-light'));
        DMLUtility.insertSobjectList('SO_Status__c', soStatusRecInsertList);
        return soStatusRecInsertList;
    }

    public static void resetAllStaticVariables() {
        // ApplicableTaxTriggerHelper
            ApplicableTaxTriggerHelper.applicableTaxNewList = new List<Applicable_Taxes__c>();
            ApplicableTaxTriggerHelper.applicableTaxOldList = new List<Applicable_Taxes__c>();
            ApplicableTaxTriggerHelper.applicableTaxNewMap = new Map<Id, Applicable_Taxes__c>();
            ApplicableTaxTriggerHelper.applicableTaxOldMap = new Map<Id, Applicable_Taxes__c>();

        // ARPaymentTriggerHelper
            ARPaymentTriggerHelper.isForceStopTrigger = false;
            // private static BaseIntegrationService integrationRec;
        
        // BusinessProfileTriggerHelper
            BusinessProfileTriggerHelper.isForceStopTrigger = false;

        // CategoryTriggerHelper
            CategoryTriggerHelper.categoryNewList = new List<Category__c>();
            CategoryTriggerHelper.categoryOldList = new List<Category__c>();
            CategoryTriggerHelper.categoryNewMap = new Map<Id, Category__c>();
            CategoryTriggerHelper.categoryOldMap = new Map<Id, Category__c>();
            CategoryTriggerHelper.runDefaultCheckBoxUpdate = true;
            // private static BaseIntegrationService integrationRec;

        // ClaimLineItemTriggerHelper
            ClaimLineItemTriggerHelper.isUpdateSOLI = true;
            ClaimLineItemTriggerHelper.claimLineItemNewList = new List<Claim_Line_Item__c>();
            ClaimLineItemTriggerHelper.claimLineItemOldList = new List<Claim_Line_Item__c>();
            ClaimLineItemTriggerHelper.claimLineItemNewMap = new Map<Id, Claim_Line_Item__c>();
            ClaimLineItemTriggerHelper.claimLineItemOldMap = new Map<Id, Claim_Line_Item__c>();
        
        // CODepositTriggerHelper
            CODepositTriggerHelper.CODepositNewList = new List<CO_Deposit__c>();
            CODepositTriggerHelper.CODepositOldList = new List<CO_Deposit__c>();
            CODepositTriggerHelper.CODepositNewMap = new Map<Id, CO_Deposit__c>();
            CODepositTriggerHelper.CODepositOldMap = new Map<Id, CO_Deposit__c>();
            CODepositTriggerHelper.isTriggerRun = false;
            CODepositTriggerHelper.preventOnAccountingSync = false;
            // private static BaseIntegrationService integrationRec;

        // COInvoicePaymentTriggerHelper
            COInvoicePaymentTriggerHelper.COInvoicePaymentNewList = new List<CO_Invoice_Payment__c>();
            COInvoicePaymentTriggerHelper.COInvoicePaymentOldList = new List<CO_Invoice_Payment__c>();
            COInvoicePaymentTriggerHelper.COInvoicePaymentNewMap = new Map<Id, CO_Invoice_Payment__c>();
            COInvoicePaymentTriggerHelper.COInvoicePaymentOldMap = new Map<Id, CO_Invoice_Payment__c>();
            COInvoicePaymentTriggerHelper.isTriggerRun = false;
            COInvoicePaymentTriggerHelper.preventOnAccountingSync = false;
            // private static BaseIntegrationService integrationRec;

        // COInvoiceTriggerHelper
            COInvoiceTriggerHelper.isForceStopTrigger = false;
            COInvoiceTriggerHelper.invoiceNewList = new List<CO_Invoice_Header__c>();
            COInvoiceTriggerHelper.invoiceOldList = new List<CO_Invoice_Header__c>();
            COInvoiceTriggerHelper.invoiceNewMap = new Map<Id, CO_Invoice_Header__c>();
            COInvoiceTriggerHelper.invoiceOldMap = new Map<Id, CO_Invoice_Header__c>();
            COInvoiceTriggerHelper.preventOnAccountingSync = false;
            // COInvoiceTriggerHelper.integrationRec;
            
        // COKitHeaderTriggerHelper
            COKitHeaderTriggerHelper.cokhNewList = new List<CO_Kit_Header__c>();
            COKitHeaderTriggerHelper.cokhOldList = new List<CO_Kit_Header__c>();
            COKitHeaderTriggerHelper.cokhNewMap = new Map<Id, CO_Kit_Header__c>();
            COKitHeaderTriggerHelper.cokhOldMap = new Map<Id, CO_Kit_Header__c>();
            COKitHeaderTriggerHelper.isTriggerExecuted = false;

        // COLineItemTriggerHelper
            COLineItemTriggerHelper.isForceStopTrigger = false;
            COLineItemTriggerHelper.COLineItemNewList = new List<CO_Line_Item__c>();
            COLineItemTriggerHelper.COLineItemOldList = new List<CO_Line_Item__c>();
            COLineItemTriggerHelper.COLineItemNewMap = new Map<Id, CO_Line_Item__c>();
            COLineItemTriggerHelper.COLineItemOldMap = new Map<Id, CO_Line_Item__c>();
            COLineItemTriggerHelper.coHeaderIdToSalesTaxItemIdsMap = new Map<Id, Set<Id>>();
            COLineItemTriggerHelper.soHeaderIdToSalesTaxItemIdsMap = new Map<Id, Set<Id>>();
            COLineItemTriggerHelper.partIdToPartRecordMap = new Map<Id, Part__c>();
            COLineItemTriggerHelper.feeIdToFeeRecordMap = new Map<Id, Fee__c>();
            COLineItemTriggerHelper.soliMap = new Map<Id, Service_Order_Line_Item__c>();
            COLineItemTriggerHelper.coHeaderIdToCoHeaderRecMap = new Map<Id, CO_Header__c>();
            COLineItemTriggerHelper.partIdToNonInventoryFlagMap = new Map<Id, Boolean>();
            COLineItemTriggerHelper.isTriggerExecute = false;
            COLineItemTriggerHelper.isVOLIRecToInsert = false;
            COLineItemTriggerHelper.isCalculateSalesTax = true;
            COLineItemTriggerHelper.isVOLIRecToChange = true;
            COLineItemTriggerHelper.isVOLIInsertFromVRPage = true;
            COLineItemTriggerHelper.isTotalCalculated = false;
            COLineItemTriggerHelper.isActivateQuoteCO = false;
            COLineItemTriggerHelper.isMoveLineItem = false;
            COLineItemTriggerHelper.isCalculatePriceLevel = true;
            COLineItemTriggerHelper.defaultSalesTax = new List<Sales_Tax__c>();

        // COTriggerHelper
            COTriggerHelper.isForceStopTrigger = false;
            COTriggerHelper.COHeaderNewList = new List<CO_Header__c>();
            COTriggerHelper.COHeaderOldList = new List<CO_Header__c>();
            COTriggerHelper.COHeaderNewMap = new Map<Id, CO_Header__c>();
            COTriggerHelper.COHeaderOldMap = new Map<Id, CO_Header__c>();
            COTriggerHelper.isTriggerExecute = false;
            COTriggerHelper.defaultSalesTax = new List<Sales_Tax__c>();
            COTriggerHelper.defaultPriceLevel = new List<Price_Level__c>();
            COTriggerHelper.isCOInvoiceHeaderUpdated = false;
            COTriggerHelper.isCalculatePLandTax = false;
            COTriggerHelper.isRecalculateCOPLAndTax = false;
            COTriggerHelper.isResetPricing = true;
            COTriggerHelper.isRecalculateTaxes = true;
            // COTriggerHelper.isRetainItemPrices = false;

        // CountryTriggerHelper
            CountryTriggerHelper.countryNewList = new List<Country__c>();
            CountryTriggerHelper.countryOldList = new List<Country__c>();
            CountryTriggerHelper.countryNewMap = new Map<Id, Country__c>();
            CountryTriggerHelper.countryOldMap = new Map<Id, Country__c>();
            CountryTriggerHelper.runDefaultCheckBoxUpdate = true;

        // CountSessionLineItemTriggerHelper
            CountSessionLineItemTriggerHelper.isForceStopTrigger = false;

        // CountSessionTriggerHelper
            CountSessionTriggerHelper.isForceStopTrigger = false;
            // private static BaseIntegrationService integrationRec;

        // CustomerOwnedUnitTriggerHelper
            CustomerOwnedUnitTriggerHelper.isForceStopTrigger = false;
            CustomerOwnedUnitTriggerHelper.forcefullyRunPopulateUnitIdLogic = false;
            CustomerOwnedUnitTriggerHelper.customerOwnerUnitNewList = new List<Customer_Owned_Unit__c>();
            CustomerOwnedUnitTriggerHelper.customerOwnerUnitOldList = new List<Customer_Owned_Unit__c>();
            CustomerOwnedUnitTriggerHelper.customerOwnerUnitNewMap = new Map<Id, Customer_Owned_Unit__c>();
            CustomerOwnedUnitTriggerHelper.customerOwnerUnitOldMap = new Map<Id, Customer_Owned_Unit__c>();
            CustomerOwnedUnitTriggerHelper.preventOnAccountingSync = false;
            // private static BaseIntegrationService integrationRec;

        // CustomerTriggerHelper
            CustomerTriggerHelper.isForceStopTrigger = false;
            CustomerTriggerHelper.accountNewList = new List<Account>();
            CustomerTriggerHelper.accountOldList = new List<Account>();
            CustomerTriggerHelper.accountNewMap = new Map<Id, Account>();
            CustomerTriggerHelper.accountOldMap = new Map<Id, Account>();
            CustomerTriggerHelper.isTriggerRun = false;
            CustomerTriggerHelper.preventOnAccountingSync = false;
            // private static BaseIntegrationService integrationRec;

        // DealItemTriggerHelper
            DealItemTriggerHelper.isForceStopTrigger = false;
            DealItemTriggerHelper.dealItemNewList = new List<Deal_Item__c>();
            DealItemTriggerHelper.dealItemOldList = new List<Deal_Item__c>();
            DealItemTriggerHelper.dealItemNewMap = new Map<Id, Deal_Item__c>();
            DealItemTriggerHelper.dealItemOldMap = new Map<Id, Deal_Item__c>();
            DealItemTriggerHelper.dealIdSet = new Set<String>();
            DealItemTriggerHelper.preventOnAccountingSync = false;
            DealItemTriggerHelper.isTriggerExecute = true;
            DealItemTriggerHelper.isCustomerPLUpdate = false;
            DealItemTriggerHelper.isRecaclTaxesOnFeesAndNonSubletProducts = false;
            // private static BaseIntegrationService integrationRec;

        // DealTriggerHelper
            DealTriggerHelper.isForceStopTrigger = false;
            // private static BaseIntegrationService integrationRec;

        // DealUnitPriceAndCostTriggerHelper
            DealUnitPriceAndCostTriggerHelper.DealUnitPriceAndCostNewList = new List<Deal_Unit_Price_Cost__c>();
            DealUnitPriceAndCostTriggerHelper.DealUnitPriceAndCostOldList = new List<Deal_Unit_Price_Cost__c>();
            DealUnitPriceAndCostTriggerHelper.DealUnitPriceAndCostNewMap = new Map<Id, Deal_Unit_Price_Cost__c>();
            DealUnitPriceAndCostTriggerHelper.DealUnitPriceAndCostOldMap = new Map<Id, Deal_Unit_Price_Cost__c>();
            DealUnitPriceAndCostTriggerHelper.isCustomerPLUpdate = false;
            DealUnitPriceAndCostTriggerHelper.isTriggerExecute = true;
            DealUnitPriceAndCostTriggerHelper.isForceStopTrigger = false;

        // DealUnresolvedFulfillmentTriggerHelper
            DealUnresolvedFulfillmentTriggerHelper.isForceStopTrigger = false;
            DealUnresolvedFulfillmentTriggerHelper.dealURFOldList = new List<Deal_Unresolved_Fulfillment__c>();
        
        // EventSchedulingTriggerHelper
            EventSchedulingTriggerHelper.isForceStopTrigger = false;

        // EventTriggerHelper
            EventTriggerHelper.isForceStopTrigger = false;

        // FactoryOptionTriggerHelper
            FactoryOptionTriggerHelper.isForceStopTrigger = false;

        // FilterTriggerHelper
            FilterTriggerHelper.FilterNewList = new List<Filter__c>();
            FilterTriggerHelper.FilterOldList = new List<Filter__c>();
            FilterTriggerHelper.FilterNewMap = new Map<Id, Filter__c>();
            FilterTriggerHelper.FilterOldMap = new Map<Id, Filter__c>();
            FilterTriggerHelper.runTrigger = true;

        // FIProductTriggerHelper
            FIProductTriggerHelper.isForceStopTrigger = false;
            FIProductTriggerHelper.FIProductNewList = new List<F_I_Product__c>();
            FIProductTriggerHelper.FIProductOldList = new List<F_I_Product__c>();
            FIProductTriggerHelper.FIProductNewMap = new Map<Id, F_I_Product__c>();
            FIProductTriggerHelper.FIProductOldMap = new Map<Id, F_I_Product__c>();
            FIProductTriggerHelper.dealIdSet = new Set<String>();
            FIProductTriggerHelper.isTriggerExecute = false;
            FIProductTriggerHelper.isCustomerPLUpdate = false;

        // HoursLoggedTriggerHelper
            HoursLoggedTriggerHelper.isForceStopTrigger = false;    
            HoursLoggedTriggerHelper.preventOnAccountingSync = false;
            // private static BaseIntegrationService integrationRec;

        // KitHeaderTriggerHelper
            KitHeaderTriggerHelper.KHNewList = new List<Kit_Header__c>();
            KitHeaderTriggerHelper.KHOldList = new List<Kit_Header__c>();
            KitHeaderTriggerHelper.KHNewMap = new Map<Id, Kit_Header__c>();
            KitHeaderTriggerHelper.KHOldMap = new Map<Id, Kit_Header__c>();
            KitHeaderTriggerHelper.PermitRun_BeforeUpdate = true;
            KitHeaderTriggerHelper.IsForceKitDistributionCalculation = false;

        // KitLineItemtriggerHelper
            KitLineItemtriggerHelper.newList = new List<Kit_Header_Line_Item__c>();
            KitLineItemtriggerHelper.oldList = new List<Kit_Header_Line_Item__c>();
            KitLineItemtriggerHelper.newMap = new Map<Id, Kit_Header_Line_Item__c>();
            KitLineItemtriggerHelper.oldMap = new Map<Id, Kit_Header_Line_Item__c>();
            KitLineItemtriggerHelper.PermitRun_BeforeInsert = true;
            KitLineItemtriggerHelper.PermitRun_BeforeUpdate = true;
            KitLineItemtriggerHelper.PermitRun_BeforeDelete = true;

        // LabourCodeTriggerHelper
            LabourCodeTriggerHelper.LabourNewList = new List<Labour_Code__c>();
            LabourCodeTriggerHelper.LabourOldList = new List<Labour_Code__c>();
            LabourCodeTriggerHelper.LabourNewMap = new Map<Id, Labour_Code__c>();
            LabourCodeTriggerHelper.LabourOldMap = new Map<Id, Labour_Code__c>();
        
        // OptionAndFeeTriggerHelper
            OptionAndFeeTriggerHelper.isForceStopTrigger = false;
            OptionAndFeeTriggerHelper.isRunningScript = false;
            OptionAndFeeTriggerHelper.OptionAndFeeNewList = new List<Option_Fee__c>();
            OptionAndFeeTriggerHelper.OptionAndFeeOldList = new List<Option_Fee__c>();
            OptionAndFeeTriggerHelper.OptionAndFeeNewMap = new Map<Id, Option_Fee__c>();
            OptionAndFeeTriggerHelper.OptionAndFeeOldMap = new Map<Id, Option_Fee__c>();
            OptionAndFeeTriggerHelper.isTriggerExecute = false;
            OptionAndFeeTriggerHelper.isCalculatePriceLevel = true;
            OptionAndFeeTriggerHelper.isCalculateTotalOnDeal = true;
            OptionAndFeeTriggerHelper.isCustomerPLUpdate = false;

        // OtherChargesTriggerHelper
            OtherChargesTriggerHelper.otherChargesNewList = new List<Other_Charges__c>();
            OtherChargesTriggerHelper.otherChargesOldList = new List<Other_Charges__c>();
            OtherChargesTriggerHelper.otherChargesNewMap = new Map<Id, Other_Charges__c>();
            OtherChargesTriggerHelper.otherChargesOldMap = new Map<Id, Other_Charges__c>();
            
        // PartAlternateTriggerHelper
            PartAlternateTriggerHelper.PartAlternateNewList = new List<Part_Alternates__c>();
            PartAlternateTriggerHelper.PartAlternateOldList = new List<Part_Alternates__c>();
            PartAlternateTriggerHelper.PartAlternateNewMap = new Map<Id, Part_Alternates__c>();
            PartAlternateTriggerHelper.PartAlternateOldMap = new Map<Id, Part_Alternates__c>();
            
        // FIFOBucketActivityLineItemTriggerHelper
            FIFOBucketActivityLineItemTriggerHelper.partFIFIBucketActivityLINewList = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
            FIFOBucketActivityLineItemTriggerHelper.partFIFIBucketActivityLIOldList = new List<Part_FIFO_Bucket_Activity_Line_Item__c>();
            FIFOBucketActivityLineItemTriggerHelper.partFIFIBucketActivityLINewMap = new Map<Id, Part_FIFO_Bucket_Activity_Line_Item__c>();
            FIFOBucketActivityLineItemTriggerHelper.partFIFIBucketActivityLIOldMap = new Map<Id, Part_FIFO_Bucket_Activity_Line_Item__c>();
            FIFOBucketActivityLineItemTriggerHelper.isTriggerRun = false;
            // private static BaseIntegrationService integrationRec;

        // PartFIFOBucketTriggerHelper
            PartFIFOBucketTriggerHelper.partFIFOBucketNewList = new List<Part_FIFO_Bucket__c>();
            PartFIFOBucketTriggerHelper.partFIFOBucketOldList = new List<Part_FIFO_Bucket__c>();
            PartFIFOBucketTriggerHelper.partFIFOBucketNewMap = new Map<Id, Part_FIFO_Bucket__c>();
            PartFIFOBucketTriggerHelper.partFIFOBucketOldMap = new Map<Id, Part_FIFO_Bucket__c>();
            PartFIFOBucketTriggerHelper.preventOnAccountingSync = false;
            // private static BaseIntegrationService integrationRec;
            // private static Set<Id> partIdSet = new Set<Id>();

        // PartTriggerHelper
            PartTriggerHelper.isForceStopTrigger = false;
            PartTriggerHelper.PartNewList = new List<Part__c>();
            PartTriggerHelper.PartOldList = new List<Part__c>();
            PartTriggerHelper.PartNewMap = new Map<Id, Part__c>();
            PartTriggerHelper.PartOldMap = new Map<Id, Part__c>();
            PartTriggerHelper.isTriggerExecuted = false;
            PartTriggerHelper.isPartFromImport = true;
            PartTriggerHelper.isCoToQuoteAction = false;
            PartTriggerHelper.preventOnAccountingSync = false;
            PartTriggerHelper.isDisableTriggerForSetQtyAndAvgCostOnFIFOBktAndLIBatch = false;
            PartTriggerHelper.isPreventOnDataLoad = false;
            PartTriggerHelper.isRunningFromFinalizeCountSessionAction = false;
            PartTriggerHelper.defaultPriceLevel = new List<Price_Level__c>();
            PartTriggerHelper.isBulkPartProcess = false;

            // PaymentOnAccountTriggerHelper
            PaymentOnAccountTriggerHelper.isForceStopTrigger = false;
            // private static BaseIntegrationService integrationRec;

        // PriceLevelTriggerHelper
            PriceLevelTriggerHelper.priceLevelNewList = new List<Price_Level__c>();
            PriceLevelTriggerHelper.priceLevelOldList = new List<Price_Level__c>();
            PriceLevelTriggerHelper.priceLevelNewMap = new Map<Id, Price_Level__c>();
            PriceLevelTriggerHelper.priceLevelOldMap = new Map<Id, Price_Level__c>();
            PriceLevelTriggerHelper.runDefaultCheckBoxUpdate = true;
        
        // ReturnVOLITriggerHelper
            ReturnVOLITriggerHelper.returnVOLINewList = new List<Return_VO_Line_Item__c>();
            ReturnVOLITriggerHelper.returnVOLIOldList = new List<Return_VO_Line_Item__c>();
            ReturnVOLITriggerHelper.returnVOLINewMap = new Map<Id, Return_VO_Line_Item__c>();
            ReturnVOLITriggerHelper.returnVOLIOldMap = new Map<Id, Return_VO_Line_Item__c>();
        
        // SalesTaxItemTriggerHelper
            SalesTaxItemTriggerHelper.oldMap = new Map<Id,Sales_Tax_Item__c>();
            SalesTaxItemTriggerHelper.newMap = new Map<Id,Sales_Tax_Item__c>();
            SalesTaxItemTriggerHelper.oldList = new List<Sales_Tax_Item__c>();
            SalesTaxItemTriggerHelper.newList = new List<Sales_Tax_Item__c>();

        // SalesTaxTriggerHelper
            SalesTaxTriggerHelper.salesTaxNewList = new List<Sales_Tax__c>();
            SalesTaxTriggerHelper.salesTaxOldList = new List<Sales_Tax__c>();
            SalesTaxTriggerHelper.salesTaxNewMap = new Map<Id, Sales_Tax__c>();
            SalesTaxTriggerHelper.salesTaxOldMap = new Map<Id, Sales_Tax__c>();
            SalesTaxTriggerHelper.runDefaultCheckBoxUpdate = true;

        // ServiceOrderLineItemTriggerHelper
            ServiceOrderLineItemTriggerHelper.soliNewList = new List<Service_Order_Line_Item__c>();
            ServiceOrderLineItemTriggerHelper.soliOldList = new List<Service_Order_Line_Item__c>();
            ServiceOrderLineItemTriggerHelper.soliNewMap = new Map<Id, Service_Order_Line_Item__c>();
            ServiceOrderLineItemTriggerHelper.soliOldMap = new Map<Id, Service_Order_Line_Item__c>();
            ServiceOrderLineItemTriggerHelper.isTriggerExecuted = false;
            ServiceOrderLineItemTriggerHelper.isUpdateClaimLI = true;
            ServiceOrderLineItemTriggerHelper.isVOLIRecToChange = true;
            ServiceOrderLineItemTriggerHelper.isActivateQuoteCO = false;
            ServiceOrderLineItemTriggerHelper.isVOLIInsertFromVRPage = true;
            ServiceOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
            ServiceOrderLineItemTriggerHelper.isMoveLineItem = false;
            ServiceOrderLineItemTriggerHelper.isCalculateSalesTax = true;
            ServiceOrderLineItemTriggerHelper.coHeaderId = null;

        // SOKitHeaderTriggerHelper
            SOKitHeaderTriggerHelper.isForceStopTrigger = false;
            SOKitHeaderTriggerHelper.soKitHeaderNewList = new List<Service_Order_Kit_Header__c>();
            SOKitHeaderTriggerHelper.soKitHeaderOldList = new List<Service_Order_Kit_Header__c>();
            SOKitHeaderTriggerHelper.soKitHeaderNewMap = new Map<Id, Service_Order_Kit_Header__c>();
            SOKitHeaderTriggerHelper.soKitHeaderOldMap = new Map<Id, Service_Order_Kit_Header__c>();
        
        // SOPaymentRoleTriggerHelper
            SOPaymentRoleTriggerHelper.soPaymentRoleNewList = new List<SO_Payment_Role__c>();
            SOPaymentRoleTriggerHelper.soPaymentRoleOldList = new List<SO_Payment_Role__c>();
            SOPaymentRoleTriggerHelper.soPaymentRoleNewMap = new Map<Id, SO_Payment_Role__c>();
            SOPaymentRoleTriggerHelper.soPaymentRoleOldMap = new Map<Id, SO_Payment_Role__c>();
            SOPaymentRoleTriggerHelper.isTriggerRun = false;

        // SOTriggerHelper
            SOTriggerHelper.isForceStopTrigger = false;
            SOTriggerHelper.soHeaderNewList = new List<Service_Order_Header__c>();
            SOTriggerHelper.soHeaderOldList = new List<Service_Order_Header__c>();
            SOTriggerHelper.soHeaderNewMap = new Map<Id, Service_Order_Header__c>();
            SOTriggerHelper.soHeaderOldMap = new Map<Id, Service_Order_Header__c>();
            SOTriggerHelper.isTriggerRun = false;
            SOTriggerHelper.refreshTaxExemptions = false;
            SOTriggerHelper.defaultPriceLevel = new List<Price_Level__c>();
            SOTriggerHelper.CLAIM_UNSUBMITTED_STATUS = 'Unsubmitted';

        // StateTriggerHelper
            StateTriggerHelper.stateNewList = new List<State__c>();
            StateTriggerHelper.stateOldList = new List<State__c>();
            StateTriggerHelper.stateNewMap = new Map<Id, State__c>();
            StateTriggerHelper.stateOldMap = new Map<Id, State__c>();
            StateTriggerHelper.runDefaultCheckBoxUpdate = true;

        // StoreCreditTriggerHelper
            StoreCreditTriggerHelper.storeCreditNewList = new List<Store_Credit__c>();
            StoreCreditTriggerHelper.storeCreditOldList = new List<Store_Credit__c>();
            StoreCreditTriggerHelper.storeCreditNewMap = new Map<Id, Store_Credit__c>();
            StoreCreditTriggerHelper.storeCreditOldMap = new Map<Id, Store_Credit__c>();
            StoreCreditTriggerHelper.preventOnAccountingSync = false;
            // private static BaseIntegrationService integrationRec;

        // UnitModelTriggerHelper
            UnitModelTriggerHelper.unitModelNewList = new List<Unit_Model__c>();
            UnitModelTriggerHelper.unitModelOldList = new List<Unit_Model__c>();
            UnitModelTriggerHelper.unitModelNewMap = new Map<Id, Unit_Model__c>();
            UnitModelTriggerHelper.unitModelOldMap = new Map<Id, Unit_Model__c>();

        // UnitPriceAndCostTriggerHelper
            UnitPriceAndCostTriggerHelper.unitPriceAndCostNewList = new List<Unit_Price_Cost__c>();
            UnitPriceAndCostTriggerHelper.unitPriceAndCostOldList = new List<Unit_Price_Cost__c>();
            UnitPriceAndCostTriggerHelper.unitPriceAndCostNewMap = new Map<Id, Unit_Price_Cost__c>();
            UnitPriceAndCostTriggerHelper.unitPriceAndCostOldMap = new Map<Id, Unit_Price_Cost__c>();
            // private static Set<Id> unitIdSet = new Set<Id>();

        // UnitSubModelTriggerHelper
            UnitSubModelTriggerHelper.unitSubModelNewList = new List<Unit_Sub_Model__c>();
            UnitSubModelTriggerHelper.unitSubModelOldList = new List<Unit_Sub_Model__c>();
            UnitSubModelTriggerHelper.unitSubModelNewMap = new Map<Id, Unit_Sub_Model__c>();
            UnitSubModelTriggerHelper.unitSubModelOldMap = new Map<Id, Unit_Sub_Model__c>();

        // UserTriggerHelper
            UserTriggerHelper.userNewList = new List<User>();
            UserTriggerHelper.userOldList = new List<User>();
            UserTriggerHelper.userNewMap = new Map<Id, User>();
            UserTriggerHelper.userOldMap = new Map<Id, User>();
            UserTriggerHelper.isRunTrigger = true; 

        // VendorInvoicingHeaderTriggerHelper
            VendorInvoicingHeaderTriggerHelper.invoiceNewList = new List<Vendor_Invoicing_Header__c>();
            VendorInvoicingHeaderTriggerHelper.invoiceOldList = new List<Vendor_Invoicing_Header__c>();
            VendorInvoicingHeaderTriggerHelper.invoiceNewMap = new Map<Id, Vendor_Invoicing_Header__c>();
            VendorInvoicingHeaderTriggerHelper.invoiceOldMap = new Map<Id, Vendor_Invoicing_Header__c>();
            VendorInvoicingHeaderTriggerHelper.preventOnAccountingSync = false;

        // VendorOrderHeaderTriggerHelper
            VendorOrderHeaderTriggerHelper.newList = new List<Vendor_Order_Header__c>();
            VendorOrderHeaderTriggerHelper.oldList = new List<Vendor_Order_Header__c>();
            VendorOrderHeaderTriggerHelper.newMap = new Map<Id, Vendor_Order_Header__c>();
            VendorOrderHeaderTriggerHelper.oldMap = new Map<Id, Vendor_Order_Header__c>();
            VendorOrderHeaderTriggerHelper.isToExecuteRemoveFromReceiving = true;

        // VendorOrderLineItemGroupTriggerHelper
            VendorOrderLineItemGroupTriggerHelper.newList = new List<Vendor_Order_Line_Item_Group__c>();
            VendorOrderLineItemGroupTriggerHelper.oldList = new List<Vendor_Order_Line_Item_Group__c>();
            VendorOrderLineItemGroupTriggerHelper.newMap = new Map<Id, Vendor_Order_Line_Item_Group__c>();
            VendorOrderLineItemGroupTriggerHelper.oldMap = new Map<Id, Vendor_Order_Line_Item_Group__c>();
            
        // VendorOrderLineItemTriggerHelper
            VendorOrderLineItemTriggerHelper.voliNewList = new List<Vendor_Order_Line_Item__c>();
            VendorOrderLineItemTriggerHelper.voliOldList = new List<Vendor_Order_Line_Item__c>();
            VendorOrderLineItemTriggerHelper.voliNewMap = new Map<Id, Vendor_Order_Line_Item__c>();
            VendorOrderLineItemTriggerHelper.voliOldMap = new Map<Id, Vendor_Order_Line_Item__c>();
            VendorOrderLineItemTriggerHelper.isTriggerExecute = true;
            VendorOrderLineItemTriggerHelper.shouldTriggerRunStop = false;
            VendorOrderLineItemTriggerHelper.isCommitReceivingAction = false;
            VendorOrderLineItemTriggerHelper.dealerName = null;

        // VendorProductTriggerHelper
            VendorProductTriggerHelper.vendorProductNewList = new List<Product__c>();
            VendorProductTriggerHelper.vendorProductOldList = new List<Product__c>();
            VendorProductTriggerHelper.vendorProductNewMap = new Map<Id, Product__c>();
            VendorProductTriggerHelper.vendorProductOldMap = new Map<Id, Product__c>();

        // VendorReceivingGroupTriggerHelper
            VendorReceivingGroupTriggerHelper.isForceStopTrigger = false;
            VendorReceivingGroupTriggerHelper.newList = new List<Vendor_Receiving_Group__c>();
            VendorReceivingGroupTriggerHelper.oldList = new List<Vendor_Receiving_Group__c>();
            VendorReceivingGroupTriggerHelper.newMap = new Map<Id, Vendor_Receiving_Group__c>();
            VendorReceivingGroupTriggerHelper.oldMap = new Map<Id, Vendor_Receiving_Group__c>();
            VendorReceivingGroupTriggerHelper.isProcessed = false;

        // VendorReceivingHeaderTriggerHelper
            VendorReceivingHeaderTriggerHelper.receivingNewList = new List<Vendor_Receiving_Header__c>();
            VendorReceivingHeaderTriggerHelper.receivingOldList = new List<Vendor_Receiving_Header__c>();
            VendorReceivingHeaderTriggerHelper.receivingNewMap = new Map<Id, Vendor_Receiving_Header__c>();
            VendorReceivingHeaderTriggerHelper.receivingOldMap = new Map<Id, Vendor_Receiving_Header__c>();
            VendorReceivingHeaderTriggerHelper.isTriggerRun = false;
            VendorReceivingHeaderTriggerHelper.preventOnAccountingSync = false;
            // private static BaseIntegrationService integrationRec;

        // WebsiteProductTriggerHelper
            WebsiteProductTriggerHelper.isForceStopTrigger = false;
    }
}