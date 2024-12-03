/**
 * Author: Tarun Khandelwal
 * Since: Feb 15, 2016
 * Name: HomeSearchUtil
 * Description: Class used to hold utility methods, variables and mapping used in Home Search screen
 * 
**/
public without sharing class HomeSearchUtil {
    public static List<PaginationSorting.SortAttrs> sortMapping;
    public static String nonTaxablePurchases = 'Non taxable purchases';
    public static String nonTaxableSales = 'Non taxable sales';

    /**
     * Name: getGenericObjectNameBySelectedObject 
     * Description: To get Generic object name by Selected object set
     * @param: 1. Set<String> objectNamesSet - selected object set
     * @return: String
     */ 
    public static String getGenericObjectNameBySelectedObject(Set<String> objectNamesSet) {
        List<String> objectNames = new List<String>(objectNamesSet);
        if(objectNamesSet.size() == 0) {
            return Label.Generic_Object_Label;
        }
        
        if(objectNames.size() == 1) {
            return objectNames[0];
        } 
        
        for(String groupName : groupNameToGroupObjectsMap.keySet()) {
            Set<String> mapObjects = new Set<String>(groupNameToGroupObjectsMap.get(groupName));
            
            boolean isAGroup = true;
            for(String objNameSelected : objectNamesSet) {
                if( mapObjects.contains(objNameSelected) == false ) {
                    isAGroup = false;
                    break;
                }
            }
            if(isAGroup){
                return groupName;
            }
        }
        
        return Label.Generic_Object_Label;
    }
    
    /**
     * Name: getPickValues 
     * Description: To get picklist values by describe call
     * @param:  1. String objectName - object name
     *          2. String fieldName - Picklist field API Name
     * @return: List<String> - Picklist options
     */
    public static List<String> getPickValues(String objectName, String fieldName) {
        List<String> lstPickvals = new List<String>();
        
        if(Schema.getGlobalDescribe().containsKey(objectName)) {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);
            Sobject Object_name = targetType.newSObject();
            Schema.sObjectType sobject_type = Object_name.getSObjectType();
            
            Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
            Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
            if(field_map.containsKey(fieldName)) {
                List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName).getDescribe().getPickListValues();
                
                for (Schema.PicklistEntry a : pick_list_values) {
                    lstPickvals.add(a.getValue());
                }
            }
        }
        return lstPickvals;
    }
    
    /**
     * Name: getUserPermissions
     * Description: to get permissions
     * @param:  
     * @return: Map<String, Map<String, Boolean>> - permission map
     */
    public static Map<String, Map<String, Boolean>> permissionsMap;
    public static Map<String, Map<String, Boolean>> getUserPermissions() {
        if(permissionsMap == null) {
        String permissionsJson = NewHomePageCtrl.getUserPermissions(UserInfo.getUserId());
        UserGroupWrapper groupDetails = (UserGroupWrapper)System.JSON.deserialize(permissionsJson, UserGroupWrapper.class);
            permissionsMap = groupDetails.GroupOnlyPermissions;
        }
        return permissionsMap;
    }
    
    /**
     * Name: filterListBasedOnPermissions 
     * Description: To remove values from list which are restricted for current user (user permissions)
     * @param:  1. List<String> listToFilter - list to filter
     *          2. List<String> Map<String, String> - map to get permissions based of key
     * @return: List<String> - filtered list
     */
    public static List<String> filterListBasedOnPermissions(List<String> listToFilter, Map<String, String> keyToPermissionsMap) {
        Map<String, Map<String, Boolean>> permissionsMap = getUserPermissions();
        
        String PrimaryLabel = '';
        String SecondaryLabel = '';
        for(String filterName: keyToPermissionsMap.keySet()) {
            List<String> permissionNames = keyToPermissionsMap.get(filterName).split(',');
            Boolean permissionValue = false;
            for(String name: permissionNames) {
                PrimaryLabel = Constants.permissionTypeToLabelListMap.get(name)[0];
                SecondaryLabel = Constants.permissionTypeToLabelListMap.get(name)[1];
                permissionValue = permissionValue || permissionsMap.get(name).get(PrimaryLabel);
            }
            
            if(!permissionValue) {
                for(Integer i=0; i<listToFilter.size(); i++) {
                    if(listToFilter[i] == filterName) {
                        listToFilter.remove(i);
                    }
                }
            }
        }
        return listToFilter;
    }

    public static List<Filter__c> getSharedFiltersForUser(String userId) {
		if(AccessControl.ifObjectFieldIsAccessible('Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
		if(AccessControl.ifObjectFieldIsAccessible('Shared_Filter__c') == false) { throw new BlackPurlException(Constants.OBJIECT_NOT_ACCESSIBLE); }
        String query = 'SELECT Id, ' + String.join(HomeSearchCtrl.filterObjFieldsList, ',');
		query += ' FROM Filter__c WHERE Id IN (SELECT Filter__c FROM Shared_Filter__c WHERE User__c = :userId)';
		return Database.query(query);
	}

    public static void shareFilterWithUsers(String filterId, Set<String> userIdSet) {
		List<Shared_Filter__c> sharedFiltersListToInsert = new List<Shared_Filter__c>();
		List<Shared_Filter__c> sharedFiltersListToDelete = new List<Shared_Filter__c>();
		for(Shared_Filter__c rec: [SELECT User__c FROM Shared_Filter__c WHERE Filter__c = :filterId]) {
			if(!userIdSet.contains(rec.User__c)) {
				sharedFiltersListToDelete.add(rec);
			} else {
				userIdSet.remove(rec.User__c);
			}
		}
		for(String userId: userIdSet) {
			sharedFiltersListToInsert.add(new Shared_Filter__c(User__c = userId, Filter__c = filterId));
		}
		DMLUtility.insertSobjectList('Shared_Filter__c', sharedFiltersListToInsert);
		DMLUtility.deleteSobjectList('Shared_Filter__c', sharedFiltersListToDelete);
	}

    public static void deleteSharedReport(String filterId, String userId) {
		DMLUtility.deleteSobjectList('Shared_Filter__c', [SELECT Id FROM Shared_Filter__c WHERE Filter__c = :filterId AND User__c = :userId]);
	}
    
    //Modified by Nidhi - #1152 - 19-10-2016   
    // Map of object name to owner field API Name
    public static Map<String, String> objectToOwnerObjectFieldName = new Map<String,String>{'Part__c'   =>  'Vendor__r',
                                                                                            'CO_Invoice_Header__c'  =>  'CO_Header__r.Owner__c',
                                                                                            'CO_Invoice_Payment__c' =>  'CO_Invoice_Header__r.CO_Header__r.Owner__c',
                                                                                            'CO_Deposit__c' =>  'CO_Header__r.Owner__c',
                                                                                            'Service_Order_Header__c' => 'CO_Header__r.Owner__c',
                                                                                            'Product__c'    =>  'Vendor__r',
                                                                                            'Payment_on_Account__c' => 'Customer__r'
                                                                                        };
    
    // Map of object name to related grid columns name and field API name(Used in sorting attributes for records)
    public static Map<String, Map<String, String>> obejctNameToMapOfSortLabelToAPIName = new Map<String, Map<String, String>>{
                                                                                            'Account' => new Map<String, String>{'Id'       =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name',
                                                                                                                                 'Drivers License' => 'Drivers_License__c'
                                                                                                                            },
                                                                                            CONSTANTS.NAMESPACE+'Part__c' => new Map<String, String>{'Id'       =>  'Id',
                                                                                                                                 'Key'      =>  'Part_Number__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Vendor__r.Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Labour_Code__c' => new Map<String, String>{'Id'=>  'Id',
                                                                                                                                 'Key'      =>  'Code__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'CO_Header__c' => new Map<String, String>{'Id'=>    'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner__r.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            'User' => new Map<String, String>{   'Id'       =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'CreatedBy.Name',
                                                                                                                                 'Name'     =>  'Title',
                                                                                                                                 'Status' => 'IsActive'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Kit_Header__c' => new Map<String, String>{'Id' =>  'Id',
                                                                                                                                 'Key'      =>  'Code__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Fee__c' => new Map<String, String>{ 'Id'       =>  'Id',
                                                                                                                                 'Key'      =>  'Code__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            
                                                                                            CONSTANTS.NAMESPACE+'CO_Invoice_Header__c' => new Map<String, String>{ 'Id' =>  'Id',
                                                                                                                                 'Key'      =>  'Invoice_Number__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'CO_Header__r.Owner__r.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Invoice_Number__c'
                                                                                                                                },
                                                                                                                                
                                                                                            CONSTANTS.NAMESPACE+'CO_Invoice_Payment__c' => new Map<String, String>{ 'Id'    =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'CO_Invoice_Header__r.CO_Header__r.Owner__r.Name',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                                                                
                                                                                            CONSTANTS.NAMESPACE+'CO_Deposit__c' => new Map<String, String>{ 'Id'    =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'CO_Header__r.Owner__r.Name',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Payment_on_Account__c' => new Map<String, String>{ 'Id'    =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Customer__r.Owner.Name',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                                                                                                    
                                                                                            CONSTANTS.NAMESPACE+'Vendor_Order_Header__c' => new Map<String, String>{ 'Id'   =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner__r.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                             CONSTANTS.NAMESPACE+'Return_VO_Header__c' => new Map<String, String>{ 'Id'   =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Return_CR_Header__c' => new Map<String, String>{ 'Id'   =>  'Id',
                                                                                                                                'Key'      =>  'Name',
                                                                                                                                'LastModifiedDate' =>  'LastModifiedDate',
                                                                                                                                'Created'  =>  'CreatedDate',
                                                                                                                                'Owner'    =>  'Owner.Name',
                                                                                                                                'Status'   =>  'Status__c',
                                                                                                                                'Name'     =>  'Name'
                                                                                                                                },                                
                                                                                            CONSTANTS.NAMESPACE+'Vendor_Receiving_Header__c' => new Map<String, String>{ 'Id'   =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner__r.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Vendor_Invoicing_Header__c' => new Map<String, String>{ 'Id'   =>  'Id',
                                                                                                                                 'Key'      =>  'Vendor_Invoice_Number__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner__r.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Category__c' => new Map<String, String>{ 'Id'  =>  'Id',
                                                                                                                                 'Key'      =>  'Unique_Category__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Price_Level__c' => new Map<String, String>{'Id'=>  'Id',
                                                                                                                                 'Key'      =>  'Name__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                             CONSTANTS.NAMESPACE+'CO_Line_Item__c' => new Map<String, String>{'Id'=>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'Owner'    =>  'CO_Header__r.Owner__r.Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'InvoiceDate'	=>	'Invoice_Number__r.Invoice_Date__c'
                                                                                                                                },
                                                                                             CONSTANTS.NAMESPACE+'Service_Order_Line_Item__c' => new Map<String, String>{'Id'=>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'Owner'    =>  'Service_Order_Header__r.CO_Header__r.Owner__r.Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'InvoiceDate'	=>	'Service_Order_Header__r.Invoice_Number__r.Invoice_Date__c'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Option_Fee__c' => new Map<String, String>{'Id'=>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'Owner'    =>  'Deal__r.CO_Header__r.Owner__r.Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'InvoiceDate'	=>	'Deal__r.Invoice_Number__r.Invoice_Date__c'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Sales_Tax__c' => new Map<String, String>{'Id'=>    'Id',
                                                                                                                                 'Key'      =>  'Name__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                                                                
                                                                                            CONSTANTS.NAMESPACE+'Product__c' => new Map<String, String>{'Id'=>  'Id',
                                                                                                                                 'Key'      =>  'Code__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Vendor__r.Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            CONSTANTS.NAMESPACE+'Service_Order_Header__c' => new Map<String, String>{ 'Id'    =>  'Id',
                                                                                                                                 'Key'      =>  'Name',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'CO_Header__r.Owner__r.Name',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                            //Added by Nidhi - #1152 - 19-10-2016   
                                                                                            CONSTANTS.NAMESPACE+'Customer_Owned_Unit__c' => new Map<String, String>{ 'Id'    =>  'Id',
                                                                                                                                 'Key'      =>  'Stock_Id__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name',
                                                                                                                                 'Compliance Date' => 'Compliance_Date__c',
                                                                                                                                 'Year of 1st Rego' => 'Year_Of_1st_Rego__c',
                                                                                                                                 'Registration Serial#' => 'Registration_Serial__c',
                                                                                                                                 'Manufactured Date' => 'Manufactured_Date__c'
                                                                                                                                },
                                                                                                                                
                                                                                           CONSTANTS.NAMESPACE+'Vendor_Order_Line_Item__c' => new Map<String, String>{ 'Id'    =>  'Id',
                                                                                                                                 'Key'      =>  'Needed_For__c',
                                                                                                                                 'Owner'    =>  'Owner.Name'
                                                                                                                                },
                                                                                          CONSTANTS.NAMESPACE+'Deal__c' => new Map<String, String>{'Id'=>  'Id',
                                                                                                                                 'Key'      =>  'Type__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Status__c',
                                                                                                                                 'Name'     =>  'Name'
                                                                                                                                },
                                                                                         CONSTANTS.NAMESPACE+'Deal_Item__c' => new Map<String, String>{'Id'=>  'Id',
                                                                                                                                 'Key'      =>  'Type__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Status'   =>  'Customer_Owned_Unit__r.Status__c',
                                                                                                                                 'Name'     =>  'Name',
                                                                                                                                 'Compliance Date'   =>  'Customer_Owned_Unit__r.Compliance_Date__c',
                                                                                                                                 'Year of 1st Rego'   =>  'Customer_Owned_Unit__r.Year_Of_1st_Rego__c',
                                                                                                                                 'Registration Serial#'   =>  'Customer_Owned_Unit__r.Registration_Serial__c',
                                                                                                                                 'Manufactured Date'   =>  'Customer_Owned_Unit__r.Manufactured_Date__c',
                                                                                                                                 'InvoiceDate'	=>	'Deal__r.Invoice_Number__r.Invoice_Date__c'
                                                                                                                                },
                                                                                        CONSTANTS.NAMESPACE+'Deal_Unit_Price_Cost__c'	=>	new map<String, String>{
										                                                                                         'InvoiceDate'	=>	'Deal_Item__r.Deal__r.Invoice_Number__r.Invoice_Date__c'
										                                                                                        },
                                                                                        CONSTANTS.NAMESPACE+'F_I_Product__c'	=>	new map<String, String>{
										                                                                                         'InvoiceDate'	=>	'Deal_Finance__r.Deal__r.Invoice_Number__r.Invoice_Date__c'
										                                                                                        },
                                                                                        CONSTANTS.NAMESPACE+'Hours_Logged__c'	=>	new map<String, String>{
										                                                                                         'Id'    =>  'Id',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Name'     =>  'Name'
										                                                                                        },
                                                                                         CONSTANTS.NAMESPACE+'Technician__c'	=>	new map<String, String>{
										                                                                                         'Id'    =>  'Id',
                                                                                                                                 'Key'      =>  'Technician_Name__c',
                                                                                                                                 'LastModifiedDate' =>  'Last_Modified_Date__c',
                                                                                                                                 'Created'  =>  'CreatedDate',
                                                                                                                                 'Owner'    =>  'Owner.Name',
                                                                                                                                 'Name'     =>  'Technician_Name__c'
										                                                                                        }                                       
                                                                                    };
    //Modified by Nidhi - #1152 - 19-10-2016   
    public static Map<String, String> searchableObjectToUniqueValueFieldMap = new Map<String, String>{
        'Account'                   => 'Name',
        'Part__c'                   => 'Name',
        'Labour_Code__c'            => 'Name',
        'Kit_Header__c'             => 'Name',
        'Fee__c'                    => 'Name',
        'CO_Header__c'              => 'Name',
        'CO_Invoice_Header__c'      => 'Invoice_Number__c',
        'CO_Invoice_Payment__c'     => 'Name',
        'CO_Deposit__c'             => 'Name', 
        'Payment_on_Account__c'             => 'Name', 
        'Vendor_Order_Header__c'    => 'Name',
        'Return_VO_Header__c'    => 'Name',
        'Return_CR_Header__c'    => 'Name',
        'Vendor_Receiving_Header__c'=> 'Name',
        'Vendor_Invoicing_Header__c'=> 'Name',
        'Category__c'               => 'Unique_Category__c',
        'Price_Level__c'            => 'Name',
        'Sales_Tax__c'              => 'Name',
        'Product__c'                => 'Name',
        'User'                      => 'UserName',
        'Service_Order_Header__c'   => 'Name',
        'Customer_Owned_Unit__c'    => 'Name',
        'Vendor_Order_Line_Item__c' => 'Name',
        'CO_Line_Item__c'           => 'Name',
        'Service_Order_Line_Item__c'=> 'Name',
        'Option_Fee__c'         => 'Name',
        'Hours_Logged__c'           => 'Name',
        'Technician__c' => 'Name',
        'Payroll_Time__c'           => 'Name',
        'Part_FIFO_Bucket__c' => 'Name',
        'Part_FIFO_Bucket_Activity_Line_Item__c' => 'Name',
        'Vendor_Invoicing_Header__c' => 'Vendor_Invoice_Number__c',
        'Deal__c' => 'Name',
        'Deal_Item__c' => 'Name',
        'CO_Section_Detail__c' => 'Name',
        'CO_Line_Item__c'	=>	'Name',
        'Deal_Unit_Price_Cost__c'	=> 'Name',
        'Unit_Price_Cost__c' => 'Name',
        'F_I_Product__c'	=>	'Name',
        'Deal_Finance__c'   =>  'Name'
    }; 
    
    public static Map<String, Set<String>> searchableSpecialObjectToFieldsMap = new Map<String, Set<String>>{
            'CO_Invoice_Header__c'              => new Set<String> {
                                                    'Id', 
                                                    'CO_Header__c',
                                                    'Invoice_Date__c',
                                                    'CO_Header__r.Customer_Name__c', 
                                                    'Invoice_Number__c',
                                                    'Total__c',
                                                    'SalesTax_Total__c',
                                                    'Invoice_Date__c',
                                                    'Sub_Total__c',
                                                    'Taxable_Total__c',
                                                    'Non_Taxable_Total__c',
                                                    'CO_Header__r.Account_Type__r.Name',
                                                    'Checkout_Type__c',
                                                    'Salesperson__c'
                                                    },
            'Vendor_Invoicing_Header__c'        => new Set<String> {
                                                    'Id', 
                                                    'Invoice_Date__c',
                                                    'Vendor_Invoice_Number__c',
                                                    'Vendor__r.Name',
                                                    'Total_With_Tax__c',
                                                    'Sub_Total__c',
                                                    'Tax_Total__c',
                                                    'Vendor__r.Purchase_Tax__c',
                                                    'Status__c',
                                                    'Taxable_Total__c',
                                                    'Non_Taxable_Total__c',
                                                    'Applicable_Purchase_Tax_Name__c',
                                                    'Vendor__r.Vendor_Account_Type__r.Name',
                                                    '(SELECT Tax_Rate__c, Sales_Tax_Item__r.Name__c FROM Individual_Taxes__r)'
                                                    },
            'Unit_Price_Cost__c'        => new Set<String> {
                                                    'Id', 
                                                    'Name',
                                                    'Customer_Owned_Unit__c',
                                                    'Customer__r.Name',
                                                    'Vendor__r.Name',
                                                    'Customer_Reference_Number__c',
                                                    'Vendor_Reference_Number__c',
                                                    'Adjustment_Date__c',
                                                    'Total_Cost__c',
                                                    'Applicable_Tax__c',
                                                    'Applicable_Tax__r.Tax_Type__c',
                                                    'Customer__c',
                                                    'Vendor__c'
                                                    },
            'Return_VO_Header__c'        => new Set<String> {
                                                    'Id', 
                                                    'Name', 
                                                    'Vendor__r.Name',
                                                    'Vendor__r.Purchase_Tax__c',
                                                    'SubTotal__c',
                                                    'Credit_Memo__c',
                                                    'Credited_Date__c'
                                                    },
            'Customer_Owned_Unit__c'        => new Set<String> {
                                                    'Id',
                                                    'Name',
                                                    'Date_Stocked_In__c',
                                                    'Referenced_Unit__r.Vendor__r.Name',
                                                    'Referenced_Unit__r.Invoice_Number__c',
                                                    'Referenced_Unit__r.Unit_Purchase_Tax__c',
                                                    'Referenced_Unit__r.Total_Cost__c',
                                                    'Referenced_Unit__r.Taxable_Cost__c'
                                                    }                            
    };
    // A Map of Objects to associated fields on which search to be performed -> Used to make JSON + Result Wrapper
    public static Map<String, Set<String>> searchableObjectToFieldsMap = new Map<String, Set<String>>{
            'Account'       => new Set<String>{ 'Id', 
                                                'Is_Customer__c', 
                                                'Is_Vendor__c', 
                                                'AccountNumber',
                                                'Customer_Number__c',
                                                'Active__c', 
                                                'Name', 
                                                'Description', 
                                                'Phone', 
                                                'Email__c', 
                                                'Email_Address__c',
                                                'Work_Email__c',
                                                'BillingStreet', 
                                                'BillingCity', 
                                                'BillingState', 
                                                'BillingCountry', 
                                                'BillingPostalCode',
                                                'Sales_Tax__r.Name__c', 
                                                'Price_Level__r.Name__c', 
                                                'Preferred_Email__c',
                                                'Preferred_Phone__c',
                                                'Vendor_Code__c',
                                                'Owner.Name', 
                                                'OwnerId',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Status__c',
                                                'FirstName__c',
                                                'LastName__c',
                                                'Nickname__c',
                                                'Birth_Date__c',
                                                'VIP__c',
                                                'Job_Title__c',
                                                'ShippingStreet',
                                                'ShippingCity',
                                                'ShippingState',
                                                'ShippingPostalCode',
                                                'Mobile__c',
                                                'Other_Email__c',
                                                'Home_Number__c',
                                                'Work_Email__c',
                                                'Work_Number__c',
                                                'Facebook__c',
                                                'LinkedIn__c',
                                                'Twitter__c',
                                                'Website',
                                                'Sales_Tax__c',
                                                'Sales_Tax__r.Name__c',
                                                'Price_Level__c',
                                                'Price_Level__r.Name__c',
                                                'Open_Orders__c',
                                                'Orders_Lifetime__c',
                                                'Average_Spend_per_Order__c',
                                                'Last_Visit_Order__c',
                                                'Purchase_Tax__c',
                                                'Purchase_Tax__r.Name__c',
                                                'Part_Category_Default__c',
                                                'Part_Category_Default__r.Name',
                                                'Unit_Category_Default__c',
                                                'Unit_Category_Default__r.Name',
                                                'Claims_for_Service_Work__c',
                                                'Flooring_Company__c',
                                                'Unit_Purchases__c',
                                                'Part_Purchases__c',
                                                'Sublet_Purchases__c',
                                                'Warranty_Plan_Sales_on_Unit_Deals__c',
                                                'Id_Number__c',
                                                'Formatted_Home_number__c',
                                                'Formatted_Mobile_Number__c',
                                                'Formatted_Work_Number__c',
                                                'Formatted_Preferred_Phone__c',
                                                'Type__c',
                                                'Account_Type__r.Name',
                                                'Vendor_Account_Type__r.Name',
                                                'Drivers_License__c',
                                                'Total_Store_Credit__c',
                                                '(Select MailingStreet, MailingCity, MailingState, MailingPostalCode FROM Contacts WHERE Is_Shipping_Address__c = true Order By CreatedDate LIMIT 1)'
                                            },
                                            
            'Part__c'       => new Set<String>{ 'Id', 
                                                'Part_Number__c', 
                                                'Active__c', 
                                                'Description__c', 
                                                'AvailableParts__c', 
                                                'Vendor__c',
                                                'Vendor__r.Vendor_Code__c',
                                                'Qty_In_Stock__c',
                                                'Qty_Committed__c',
                                                'Qty_On_Order__c',
                                                'Retail_Price__c',
                                                'Location__c',
                                                'Category__r.Name',
                                                'Category__c',
                                                'Status__c',
                                                'Name',
                                                'Last_Cost__c',
                                                'LastModifiedDate', 
                                                'Last_Modified_Date__c',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Vendor__r.OwnerId',
                                                'Vendor__r.Name',
                                                'Vendor__r.Owner.Name',
                                                'Status__c',
                                                'Status__c',
                                                'MSRP__c',
                                                'Enviro_Fee__c',
                                                'Average_Cost__c',
                                                'Package_Cost__c',
                                                'Package_Qty__c',
                                                'Package_Unit__c',
                                                'Last_Counted__c',
                                                'Last_Sold__c',
                                                'Last_Stocked__c',
                                                'Auto_reorder_Min__c',
                                                'Auto_reorder_Max__c',
                                                'Order_Lots__c',
                                                'Superseded_By__c',
                                                'Superseded_By__r.Part_Number__c',
                                                'Oversold_Qty__c',
                                                'Oversold_Cost__c',
                                                'Inventory_Qty__c',
                                                'Total_Cost__c',
                                                'Mfg_Part__c', // Added by richa 28/11/2016
                                                'SKU_Number__c', // Added by richa 28/11/2016
                                                'Non_Inventory_Part__c', // Added by richa 28/11/2016
                                                'Assigned_Tag_1__c',
                                                'Assigned_Tag_2__c',
                                                'Part_Aging_Detail__r.PRD1Qty__c',
                                                'Part_Aging_Detail__r.PRD1Cost__c',
                                                'Part_Aging_Detail__r.PRD2Qty__c',
                                                'Part_Aging_Detail__r.PRD2Cost__c',
                                                'Part_Aging_Detail__r.PRD3Qty__c',
                                                'Part_Aging_Detail__r.PRD3Cost__c',
                                                'Part_Aging_Detail__r.PRD4Qty__c',
                                                'Part_Aging_Detail__r.PRD4Cost__c',
                                                'Part_Type__c',
                                                'Assigned_Location_1__c',
                                                'Assigned_Location_2__c',
                                                'Sale_Price__c',
                                                'Assigned_Locations__c',
                                                'Publish_In_Feeds__c',
                                                'Superseded_To__c',
                                                'Superseded_To__r.Part_Number__c', 
                                                'Part_Aging_Detail__c',
                                                'Last_Edited__c',
                                                'Last_Price_Update__c',
                                                'Last_Edited_By__r.Name',
                                                'BP_Inventory_valuation__c',
                                                'Committed_Cost__c',
                                                'Available_Cost__c'
                                            },
             
            'Hours_Logged__c'       => new Set<String>{ 'Id',
            									'Total_Cost__c',
                                                'Owner.Name',
                                                'CreatedDate',
                                                'Name',
                                                'Technician__r.Technician_Name__c',
                                                'Start_Date_Time__c',
                                                'End_Date_Time__c',
                                                'Service_Order_Header__r.CO_Header__r.Name',
                                                'Task__r.Name__c',
                                                'Service_Order_Header__r.Name__c',
                                                'Notes__c',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'Calculated_Hours__c',
                                                'Work_Performed_Date__c',
                                                'Time_Spent__c',
                                                'Billed_Hours__c',
                                                'WIP_Invoice_Hours__c',
                                                'Service_Order_Header__r.SO_Type__c',
                                                'Service_Order_Header__r.SO_Status__c',
                                                'Service_Order_Header__r.CO_Header__r.Customer_name__c',
                                                'Efficiency__c',
                                                'Service_Order_Header__r.Transaction_Type__c',
                                                'Service_Order_Header__r.Transaction_Type__r.Code_Label__c',
                                                'Total_Hours__c',
                                                'Paused_Hours__c'
                                            },
            'Technician__c'         => new Set<String>{ 'Id',
                                                        'Name',
                                                        'Type__c',
                                                        'Owner.Name',
                                                        'CreatedDate',
                                                        'LastModifiedDate',
                                                        'Last_Modified_Date__c',
                                                        'Technician_Name__c',
														'(Select Id, Service_Order_Header__c, Service_Order_Header__r.SO_Status__c, Task__c, Calculated_Hours__c,'+ 
                                                                'Total_Cost__c, Is_Removed__c, Billed_Hours__c, WIP_Invoice_Hours__c, Paused_Hours__c from Hours_Logged__r)', 
                                                        '(Select Id, Total_Time__c from Payroll_Times__r)'
                                            },
                                            
            'Payroll_Time__c'       => new Set<String>{ 'Id',
                                                        'Name',
                                                        'Technician__c',
                                                        'CreatedDate',
                                                        'Technician__r.Technician_Name__c',
                                                        'Start_Date__c',
                                                        'End_Date__c',
                                                        'Formatted_Total_time__c',
                                                        'Total_time__c',
                                                        'Payroll_Date__c',
                                                        'In_Time__c'
                                            },                           
                                           
            'Labour_Code__c'=> new Set<String>{ 'Id', 
                                                'Name', 
                                                'Name__c',
                                                'Active__c', 
                                                'Description__c', 
                                                'Code__c', 
                                                'Category__r.Name',
                                                'Category__c',
                                                'Rate__c',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c', 
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Owner.Name',
                                                'OwnerId',
                                                'Status__c',
                                                'Code__c',
                                                'Assigned_Tag_1__c',
                                                'Assigned_Tag_2__c',
                                                'Hours__c'
                                            },
            
            'Kit_Header__c' => new Set<String>{ 'Id', 
                                                'Name', 
                                                'Active__c', 
                                                'Description__c', 
                                                'Code__c', 
                                                'Fixed_Price__c',
                                                'OwnerId',
                                                'Owner.Name', 
                                                'LastModifiedDate', 
                                                'Last_Modified_Date__c',
                                                'CreatedDate', 
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Code__c',
                                                'Kit_Unique_Name__c',
                                                'Status__c',
                                                'Service_Kit__c'
                                            },
                                            
            'Fee__c'        => new Set<String>{ 'Id', 
                                                'Name', 
                                                'Active__c', 
                                                'Description__c', 
                                                'Code__c', 
                                                'Category__c',
                                                'Category__r.Name',
                                                'Price__c',
                                                'Owner.Name', 
                                                'OwnerId',
                                                'LastModifiedDate', 
                                                'Last_Modified_Date__c',
                                                'CreatedDate', 
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Fee_Unique_Name__c',
                                                'Status__c',
                                                'Assigned_Tag_1__c',
                                                'Assigned_Tag_2__c',
                                                'Code__c',
                                                'Type__c'
                                            },
            
            'CO_Header__c'=> new Set<String>{   'Id', 
                                                'Name',
                                                'Salesperson_Names__c',
                                                'CO_Salesperson_Names__c',
                                                'Customer__c',
                                                'Customer__r.Name',
                                                'CO_Type__c',
                                                'Order_status__c', 
                                                'Total_Order_Value__c', 
                                                'Total_COLI__c',
                                                'Deal_Total__c',
                                                'Total_SO_Tax_Amount__c',
                                                'Total_SO__c',
                                                'Owner__r.Name', 
                                                'Owner__c',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'LastModifiedDate__c', 
                                                'CreatedDate',
                                                'CreatedDate__c',
                                                'Total_Balance_Due__c',
                                                'Status__c',
                                                'Total_Payment__c',
                                                'Total__c',
                                                'Total_Deposit__c',
                                                'Customer_Name__c',
                                                'TotalNumberOfSOHeader__c ', // Added by richa 20/01/2017 for global search changes for CO
                                                'Selling_Group__c', // Added by richa 20/01/2017 for global search changes for CO
                                                'TotalNumberOfCOLI__c', // Added by richa 20/01/2017 for global search changes for CO
                                                'NumberOfDeals__c', // Added by richa 20/01/2017 for global search changes for CO
                                                'Total_COLI_Clearfix__c', // Added by richa 20/01/2017 for global search changes for CO
                                                'Order_Total__c',
                                                'Total_Deposit_And_Payment__c',
                                                'Invoiced_Amount__c',
                                                'Uninvoiced_Amount__c',
                                                'Deal_Header_Total__c',
                                                'Service_Order_Subtotal__c',
                                                'Merchandise_Total__c',
                                                'Hide_Merchandise_Section__c',
                                                'Last_Comment__c',
                                                'Account_Type__r.Name',
                                                'Merchandise_Pre_Tax_Part_Total__c',
                                                'Merchandise_Pre_Tax_Fee_Total__c',
                                                'Parts_And_Accessories_Tax_Amount__c',
                                                'Merchandise_Profit__c',
                                                'Merchandise_Status__c',
                                                'Parts_And_Accessories_Total__c',
                                                'Merchandise_Transaction_Type__c',
                                                'Parts_And_Accessories_Invoiced_Total__c',
                                                'Merchandise_Sale_Type__c',
                                                '(Select Special_Order_Status__c from CO_Section_Details__r where Section_Type__c = \'Merchandise\')',
                                                'Customer__r.FirstName__c',
												'Customer__r.LastName__c',
												'Customer__r.BillingStreet',
												'Customer__r.BillingCity',
												'Customer__r.BillingState',
												'Customer__r.BillingPostalCode',
												'Customer__r.Type__c',
												'Customer__r.Home_Number__c',
												'Customer__r.Work_Number__c',
												'Customer__r.Formatted_Home_Number__c',
                                                'Customer__r.Formatted_Work_Number__c',
												'Customer__r.Preferred_Phone__c',
												'Customer__r.Mobile__c',
												'Customer__r.Formatted_Mobile_Number__c',
												'Customer__r.Email__c',
                                                'Customer__r.Work_Email__c',
                                                'Customer__r.Other_Email__c',
                                                'Transaction_Type__c',
                                                'Transaction_Type__r.Code_Label__c'
                                            },
           
            'CO_Invoice_Header__c'=> new Set<String>{'Id', 
                                                    'Name', 
                                                    'Invoice_Number__c',   
                                                    'CO_Header__r.Customer__c',
                                                    'CO_Header__r.Customer__r.Name',
                                                    'CO_Header__r.Customer_Name__c',
                                                    'CO_Header__r.CO_Type__c',
                                                    'Invoice_Status__c', 
                                                    'Total_Payment__c',
                                                    'Total__c',
                                                    'CO_Header__r.Owner__r.Name',
                                                    'CO_Header__r.Owner__c',
                                                    'LastModifiedDate', 
                                                    'Last_Modified_Date__c',
                                                    'CreatedDate',
                                                    'LastModifiedDate__c',
                                                    'CreatedDate__c',
                                                    'CO_Header__c',
                                                    'CO_Header__r.Name',
                                                    'CO_Header__r.Owner__c',
                                                    'CO_Header__r.Owner__r.Name',
                                                    'CO_Header__r.Total_Balance_Due__c',
                                                    'Status__c',
                                                    'Part_Total__c',
                                                    'Fee_Total__c',
                                                    'Total_Fee_With_Shop_Supplies__c',
                                                    'Labour_Total__c',
                                                    'Sublet_Total__c',
                                                    'Unit_Total__c',
                                                    'SalesTax_Total__c',
                                                    'Invoice_Date__c',
                                                    'Invoice_Date_Formula__c',
                                                    'CO_Header__r.Customer_Name__c',
                                                    'Warranty_Product_Total__c',
                                                    'Other_Product_Total__c',
                                                    'Product_Total__c',
                                                    'Trade_In_Total__c',
                                                    'Deal_Profitability__c',
                                                    'Invoice_Profitability__c',
                                                    'Stamp_Duty_Total__c',
                                                    'Total_Amount_Except_Charge_Account__c',
                                                    'Taxable_Total__c',
                                                    'Non_Taxable_Total__c',
                                                    'Pre_Tax_Part_Total__c',
                                                    'Pre_Tax_Labour_Total__c',
                                                    'Pre_Tax_Sublet_Total__c',
                                                    'Pre_Tax_Unit_Total__c',
                                                    'Pre_Tax_Trade_In_Total__c',
                                                    'Pre_Tax_Warranty_Product_Total__c',
                                                    'Pre_Tax_Other_Product_Total__c',
                                                    'Deal_Commission__c',
                                                    'Salesperson__c',
                                                    'CO_Header__r.Account_Type__r.Name',
                                                    'Lien_Payout_Total__c',
                                                    'Closed_Invoice_Date__c',
                                                    'Total_Finance_Commission__c',
                                                    'Calculated_AR_Balance__c',
                                                    'Is_Deal_Invoiced__c'
                                            },
            
            'CO_Invoice_Payment__c'=> new Set<String>{'Id', 
                                                    'Name', 
                                                    'CO_Invoice_Header__r.CO_Header__c',
                                                    'CO_Invoice_Header__r.CO_Header__r.Name',
                                                    'CO_Invoice_Header__r.CO_Header__r.Customer__c',
                                                    'CO_Invoice_Header__r.CO_Header__r.Customer__r.Name',
                                                    'CO_Invoice_Header__r.CO_Header__r.CO_Type__c',
                                                    'Amount__c',
                                                    'CO_Invoice_Header__r.CO_Header__r.Customer_Name__c',
                                                    'CO_Invoice_Header__r.CO_Header__r.Owner__r.Name',
                                                    'CO_Invoice_Header__r.CO_Header__r.Owner__c',
                                                    'CO_Invoice_Header__r.Status__c',
                                                    'CO_Invoice_Header__r.Invoice_Number__c',
                                                    'LastModifiedDate', 
                                                    'Last_Modified_Date__c',
                                                    'CreatedDate',
                                                    'LastModifiedDate__c',
                                                    'CreatedDate__c',
                                                    'Payment_Method__c',
                                                    'Reverse_Payment_From__c',
                                                    'Reverse_Payment_From__r.Name',
                                                    'CO_Invoice_Header__r.CO_Header__r.Customer_Name__c',
                                                    'CO_Invoice_Header__r.CO_Header__r.Account_Type__r.Name',
                                                    'Cash_Drawer__r.Name',
                                                    'Payment_Date__c',
                                                    'Customer_Name__c',
                                                    'Customer_Name__r.Name',
                                                    'Reference__c'
                                            },       
                                            
            'CO_Deposit__c'         => new Set<String>{'Id', 
                                                    'Name', 
                                                    'CO_Invoice_Header__r.CO_Header__c',
                                                    'CO_Header__r.Name',
                                                    'CO_Header__r.Customer__c',
                                                    'CO_Header__r.Customer__r.Name',
                                                    'CO_Header__r.Customer_Name__c',
                                                    'CO_Header__r.CO_Type__c',
                                                    'Amount__c',
                                                    'CO_Header__r.Owner__r.Name',
                                                    'CO_Header__r.Owner__c',
                                                    'CO_Invoice_Header__r.Status__c',
                                                    'LastModifiedDate', 
                                                    'Last_Modified_Date__c',
                                                    'CreatedDate',
                                                    'LastModifiedDate__c',
                                                    'CreatedDate__c',
                                                    'Payment_Method__c',
                                                    'CO_Header__r.Customer_Name__c',
                                                    'CO_Header__r.Account_Type__r.Name',
                                                    'Cash_Drawer__r.Name',
                                                    'Payment_Date__c',
                                                    'Customer_Name__c',
                                                    'Customer_Name__r.Name',
                                                    'Reference__c'
                                            },                                                                          
            
           	'CO_Section_Detail__c'=> new Set<String>{'Id', 
           										'Name',
           										'SO_Status_Priority_Number__c',
                                                'CO_Header__c', 
                                                'Section_Type__c',
                                                'CreatedDate',
                                                'Special_Order_Status__c',
                                                'CO_Header__r.Name',
                                                'CO_Header__r.CO_Type__c', 
                                                'CO_Header__r.Customer__r.Name', 
                                                'CO_Header__r.CreatedDate',
                                                'CO_Header__r.LastModifiedDate',
                                                'CO_Header__r.Last_Modified_Date__c',
                                                'CO_Header__r.Last_Comment__c'
           									},
                                                                                                                    
            'Payment_on_Account__c'         => new Set<String>{'Id', 
                                                    'Name', 
                                                    'Customer__c',
                                                    'Customer__r.Name',
                                                    'Total_Amount__c',
                                                    'Customer__r.Owner.Name',
                                                    'LastModifiedDate', 
                                                    'Last_Modified_Date__c',
                                                    'CreatedDate',
                                                    'Cash_Drawer__c',
                                                    'Cash_Drawer__r.Name',
                                                    'Customer__r.Account_Type__r.Name',
                                                    'Payment_Date__c',
                                                    'Payment_Method__c',
                                                    'Reference__c'
                                            },                                                                          
            
            'Vendor_Order_Header__c'=> new Set<String>{ 'Id', 
                                                        'Name', 
                                                        'Vendor__c',
                                                        'Vendor__r.Name',
                                                        'Status__c',
                                                        'CreatedBy.Name',
                                                        'Last_Modified_By__r.Name',
                                                        'LastModifiedDate', 
                                                        'Last_Modified_Date__c',
                                                        'CreatedDate',
                                                        'LastModifiedDate__c',
                                                        'CreatedDate__c',
                                                        'Total__c',
                                                        'Total_Recieved__c',
                                                        'Status__c',
                                                        'Purchase_Order_Type__c',
                                                        'Purchase_Order_Type__r.Code__c',
                                                        'Vendor__r.Vendor_Account_Type__r.Name',
                                                        'Expected_Date_Formula__c',
                                                        'Ordered_Date__c',
                                                        'Notes__c'                           
                                            },  
                                            
            'Return_VO_Header__c'=> new Set<String>{ 'Id', 
                                                        'Name', 
                                                        'Vendor__c',
                                                        'Vendor__r.Name',
                                                        'Status__c',
                                                        'OwnerId',
                                                        'Owner.Name',
                                                        'LastModifiedDate', 
                                                        'Last_Modified_Date__c',
                                                        'CreatedDate',
                                                        'LastModifiedDate__c',
                                                        'CreatedDate__c',
                                                        'Total__c',
                                                        'Vendor__r.Vendor_Account_Type__r.Name',
                                                        'Last_Modified_Date__c',
                                                        'Submitted_Date__c',
                                                        'Approved_Date__c', 
                                                        'Returned_Date__c', 
                                                        'SubTotal_Reporting__c',
                                                        'Tax_Reporting__c',
                                                        'Credits_Pending_Reporting__c',
                                                        'RMA__c', 
                                                        'Tracking_Number__c',
                                                        'Reason__c',
                                                        'Notes__c'
                                            },
                                                                           
            'Vendor_Receiving_Header__c'=> new Set<String>{ 'Id', 
                                                            'Name', 
                                                            'Vendor__c',
                                                            'Vendor__r.Name',
                                                            'Status__c', 
                                                            'Owner__r.Name', 
                                                            'Owner__c',
                                                            'Packing_Slip_Number__c',
                                                            'LastModifiedDate', 
                                                            'Last_Modified_Date__c',
                                                            'CreatedDate',
                                                            'LastModifiedDate__c',
                                                            'CreatedDate__c',
                                                            'Status__c',
                                                            'Receiving_Total__c',
                                                            'Receipt_Number__c',
                                                            'Vendor__r.Vendor_Account_Type__r.Name'
                                            },
                                            
            'Vendor_Invoicing_Header__c'=> new Set<String>{ 'Id', 
                                                            'Name', 
                                                            'Vendor_Invoice_Number__c',
                                                            'Vendor__c',
                                                            'Vendor__r.Name',
                                                            'Status__c', 
                                                            'Owner__r.Name', 
                                                            'Owner__c',
                                                            'Invoice_Number__c',
                                                            'LastModifiedDate', 
                                                            'Last_Modified_Date__c',
                                                            'CreatedDate',
                                                            'LastModifiedDate__c',
                                                            'CreatedDate__c',
                                                            'Status__c',
                                                            'Total__c',
                                                            'Total_With_Tax__c',
                                                            'Vendor__r.Vendor_Account_Type__r.Name'
                                            },
            'Category__c'=> new Set<String>{    'Id', 
                                                'Name', 
                                                'Description__c',
                                                'Status__c', 
                                                'Owner.Name', 
                                                'OwnerId',
                                                'LastModifiedDate', 
                                                'Last_Modified_Date__c',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Unique_Category__c',
                                                'Type__c',
                                                'Active__c'
                                },
            'Price_Level__c'=> new Set<String>{ 'Id', 
                                                'Name__c', 
                                                'Description__c',
                                                'Status__c', 
                                                'Owner.Name', 
                                                'OwnerId',
                                                'LastModifiedDate', 
                                                'Last_Modified_Date__c',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Name',
                                                'Discount_Markup__c',
                                                'Active__c'
                                },
            'Sales_Tax__c'=> new Set<String>{   'Id', 
                                                'Name__c', 
                                                'Forms_Label__c',
                                                'Status__c', 
                                                'Tax_Type__c',
                                                '(Select Id, Sales_Tax_Item__r.Name__c, Sales_Tax_Item__r.Rate_Type__c, Sales_Tax_Item__r.Rate__c from Applicable_Taxes__r)',
                                                'Owner.Name', 
                                                'OwnerId',
                                                'LastModifiedDate', 
                                                'Last_Modified_Date__c',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Name',
                                                'Rate__c',
                                                'Active__c'
                                },
                                
            'Product__c' => new Set<String>{    'Id',
                                                'Description__c',
                                                'Category__r.Name',
                                                'Name',
                                                'Price__c',
                                                'Status__c', 
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'Vendor__r.Vendor_Code__c',
                                                'Cost__c',
                                                'Code__c',
                                                'Vendor__r.Owner.Name',
                                                'Vendor__r.Name',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Product_Unique_Name__c',
                                                'Type__c',
                                                'Vendor__c',
                                                'Vendor__r.Vendor_Account_Type__r.Name',
                                                'Cost_Method__c'
                                },
                                
            'User'      => new Set<String>  {   'Id',
                                                'Name',
                                                'UserName',
                                                'Email',
                                                'LastModifiedDate',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'CreatedBy.Name',
                                                'IsActive',
                                                'Phone'
                                },
                                
            'Service_Order_Header__c' => new Set<String>    {   'Id',
                                                'Name',
                                                'Name__c',
                                                'Salesperson_Names__c',
                                                'CO_Header__c',
                                                'CO_Header__r.CO_Type__c',
                                                'CO_Header__r.Name',
                                                'CO_Header__r.Customer__c',
                                                'CO_Header__r.CreatedDate',
                                                'CO_Header__r.LastModifiedDate',
                                                'CO_Header__r.Last_Modified_Date__c',
                                                'CO_Header__r.Last_Comment__c',
                                                'Special_Order_Status__c',
												'SO_Status_Priority_Number__c',
                                                'CO_Header__r.Customer__r.Name',
                                                'CO_Header__r.Owner__c',
                                                'CO_Header__r.Order_Status__c',
                                                'SO_Status__c',
                                                'Total__c',
                                                'Tax_Amount__c',
                                                'SO_Type__c',
                                                'Technician_Name__c',
                                                'Hrs_Billed__c',
                                                'Total_Hours_Billed__c',
                                                'Hrs_Logged__c',
                                                'Total_Parts__c',
                                                'Total_Labor__c',
                                                'SO_Type__c',
                                                'Total_Sublet__c',
                                                'Total_Fees__c',
                                                'Total_Fee_With_Shop_Supplies__c',
                                                'Total_Tax__c',
                                                'Total_With_Tax__c',
                                                'Customer_Owned_Unit__c',
                                                'Customer_Owned_Unit__r.Unit_Id__c',
                                                'Customer_Owned_Unit__r.Stock_Id__c',
                                                'Customer_Owned_Unit__r.Unit_Type__c',
                                                'Customer_Owned_Unit__r.Unit_Number__c',
                                                'Customer_Owned_Unit__r.VIN_Number__c',
                                                'Customer_Owned_Unit__r.Plate__c',
                                                'Customer_Owned_Unit__r.Unit_Make__r.Name',
                                                'Customer_Owned_Unit__r.Unit_Model__r.Name__c',
                                                'Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c',
                                                'SO_Concern__c',
                                                'Transaction_Type__c',
                                                'Transaction_Type__r.Code_Label__c',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'CreatedBy.Name',
                                                'Deal__c',
                                                'CO_Header__r.Customer_Name__c',
                                                'Scheduled_Date__c',
                                                'Invoice_Number__c',
                                                'Customer_Owned_Unit__r.Formatted_Name__c', 
												'CreatedDate',
												'Customer_Owned_Unit__r.Engine_Serial_No__c',
												'Odometer_on_Arrival__c',
												'Odometer_on_Departure__c',
												'Transaction_Type__r.Type__c',
												'Provider__r.Name',
												'Claim_Status__c',
												'Invoice_Number__r.Invoice_Date__c',
												'Invoice_Number__r.Invoice_Number__c',
                                                'CO_Header__r.Customer__r.FirstName__c',
                                                'CO_Header__r.Customer__r.LastName__c',
                                                'CO_Header__r.Customer__r.BillingStreet',
                                                'CO_Header__r.Customer__r.BillingCity',
                                                'CO_Header__r.Customer__r.BillingState',
                                                'CO_Header__r.Customer__r.BillingPostalCode',
                                                'CO_Header__r.Customer__r.Type__c',
                                                'CO_Header__r.Customer__r.Home_Number__c',
                                                'CO_Header__r.Customer__r.Work_Number__c',
                                                'CO_Header__r.Customer__r.Formatted_Home_Number__c',
                                                'CO_Header__r.Customer__r.Formatted_Work_Number__c',
                                                'CO_Header__r.Customer__r.Preferred_Phone__c',
                                                'CO_Header__r.Customer__r.Mobile__c',
                                                'CO_Header__r.Customer__r.Formatted_Mobile_Number__c',
                                                'CO_Header__r.Customer__r.Email__c',
                                                'CO_Header__r.Customer__r.Work_Email__c',
                                                'CO_Header__r.Customer__r.Other_Email__c',
                                                'Customer_Owned_Unit__r.Unit_Data_01__c',
                                                'Customer_Owned_Unit__r.Unit_Data_02__c',
                                                'Customer_Owned_Unit__r.Unit_Data_03__c',
                                                'Customer_Owned_Unit__r.Unit_Data_04__c',
                                                'Customer_Owned_Unit__r.Unit_Data_05__c',
                                                'Customer_Owned_Unit__r.Unit_Data_06__c',
                                                'Customer_Owned_Unit__r.Unit_Data_07__c',
                                                'Customer_Owned_Unit__r.Unit_Data_08__c',
                                                'Customer_Owned_Unit__r.Unit_Data_09__c',
                                                'Customer_Owned_Unit__r.Unit_Data_10__c',
                                                'Customer_Owned_Unit__r.Unit_Data_11__c',
                                                'Customer_Owned_Unit__r.Unit_Data_12__c',
                                                'Customer_Owned_Unit__r.Unit_Data_13__c',
                                                'Customer_Owned_Unit__r.Unit_Data_14__c',
                                                'Customer_Owned_Unit__r.Unit_Data_15__c',
                                                'Due_In_DateTime__c',
                                                'Promised_By_DateTime__c',
                                                'Unit_Arrived__c',
                                                'Deductible_SO_Payment__c',
                                                'Deductible_SO_Payment__r.Total_With_Tax__c',
                                                'Claim__c',
                                                'Claimed_Total__c',
                                                'Claim__r.Provider_Claim_Number__c',
                                                'Claim_Invoice_Number__c',
                                                'Claim__r.Total_Variance__c',
                                                'Deductible_Invoice_Number__c',
                                                'Claim_Clearing__c',
                                                'Pre_Tax_Parts_Total__c',
                                                'Pre_Tax_Labor_Total__c',
                                                'Pre_Tax_Sublet_Total__c',
                                                'Pre_Tax_Total_Fee_With_Shop_Supplies__c',
                                                'Special_Order_Status_Formula__c'
                                },

            //Added by Nidhi - #1152 - 19-10-2016   
            'Customer_Owned_Unit__c' => new Set<String> {   'Id',
                                                'Name',
                                                'Stock_Id__c',
                                                'Year__c',
                                                'Unit_Make__r.Name',
                                                'Unit_Model__r.Name__c',
                                                'Unit_Model__r.Sub_Model__c',
                                                'Sub_Model__r.Sub_Model_Name__c',
                                                'Sub_Model__c',
                                                'Colour__c',
                                                'Status__c',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'VIN_Number__c',
                                                'VIN_Number_Formula__c',
                                                'New_Unit__c',
                                                'Total_Base_Unit_Price__c',
                                                'Total_Base_Units_Cost__c', 
                                                'Total_Dealer_Options_Cost__c', 
                                                'Total_Dealer_Options_Price__c', 
                                                'Total_Factory_Options_Cost__c',
                                                'Total_Factory_Options_Price__c',
                                                'Deal_Options_WIP__c',
                                                'Total_Cost__c', 
                                                'Total_Price__c',
                                                'Location__c',
                                                'Category__r.Name',
                                                'Date_Stocked_In__c',
                                                'Age__c',
                                                'Key_No__c',
                                                'Engine_Serial_No__c',
                                                'Other_Serial_No__c',
                                                'Interior_Colour__c',
                                                'Owner.Name',
                                                'CreatedDate',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'Unit_Number__c',
                                                'Unit_Type__c', //Added by Pooja 8 Dec 2016
                                                'Date_Stocked_Out__c',
                                                'Taxable__c',
                                                'Applicable_Tax__c',
                                                'Applicable_Tax__r.Name__c',
                                                'Cylinders__c',
                                                'Automatic__c',
                                                'Manufactured_Date__c',
                                                'Mileage__c',
                                                'Mileage_Value__c',
                                                'Plate__c',
                                                'Reg_Expiry_Date__c',
                                                'Make_Name__c',
                                                'Model_Name__c',
                                                'Account__r.Name',
                                                'Account__r.Preferred_Phone__c',
                                                'Account__r.Home_Number__c',
                                                'Account__r.Mobile__c',
                                                'Account__r.Formatted_Home_number__c',
                                                'Account__r.Formatted_Mobile_Number__c',
                                                'Account__r.Formatted_Work_Number__c',
                                                'Account__r.Formatted_Preferred_Phone__c',
                                                'Assigned_Tag_1__c',
                                                'Assigned_Tag_2__c',
                                                'Unit_Type__c',
                                                'Account__r.Account_Type__r.Name',
                                                'Mileage_Type__c',
                                                'Compliance_Date__c',
                                                'Year_Of_1st_Rego__c',
                                                'Registration_Serial__c',
                                                'Manufactured_Date__c',
                                                'Unit_Data_01__c',
                                                'Unit_Data_02__c',
                                                'Unit_Data_03__c',
                                                'Unit_Data_04__c',
                                                'Unit_Data_05__c',
                                                'Unit_Data_06__c',
                                                'Unit_Data_07__c',
                                                'Unit_Data_08__c',
                                                'Unit_Data_09__c',
                                                'Unit_Data_10__c',
                                                'Unit_Data_11__c',
                                                'Unit_Data_12__c',
                                                'Unit_Data_13__c',
                                                'Unit_Data_14__c',
                                                'Unit_Data_15__c',
                                                'Date_Ordered__c',
                                                'Date_Expected__c',
                                                'Factory_Order_No__c',
                                                'Is_Ordered_Unit_Added_To_Deal__c',
                                                'Tax_Amount__c',
                                                'Vendor__r.Name',
                                                'Total_Cost_With_Tax__c',
                                                'NITC_Withheld__c',
                                                'Agreed_Payout__c',
                                                'Suggested_Price__c',
                                                'Unit_Id__c',
                                                'Consignment__c',
                                                'How_Acquired__c',
                                                'Reference_Number__c',
                                                'Acquired_From__c', 
                                                'Sale_Number__c',
                                                'Sold_To__c',
                                                'Acquired_From__r.BillingStreet',
                                                'Acquired_From__r.BillingCity',
                                                'Acquired_From__r.Billing_County_Parish__c', 
                                                'Acquired_From__r.BillingState',
                                                'Acquired_From__r.BillingPostalCode',
                                                'Acquired_From__r.Name',
                                                'Sold_To__r.BillingStreet',
                                                'Sold_To__r.BillingCity',
                                                'Sold_To__r.Billing_County_Parish__c', 
                                                'Sold_To__r.BillingState',
                                                'Sold_To__r.BillingPostalCode',
                                                'Sold_To__r.Name',
                                                'Acquisition_Cost__c',
                                                'Additional_Costs__c', 
                                                'Sold_Price__c',
                                                'Profit__c',
                                                'Formatted_Name__c',
                                                'Deal_Item__c'
                                },
                                
            'CO_Line_Item__c' => new Set<String>  {   
                                                'Id',
                                                'Name',
                                                'Qty__c',
                                                'Part__c',
                                                'Fee__c',
                                                'Part__r.Vendor__r.Name',
                                                'Part__r.Part_Type__c',
                                                'Part__r.Category__r.Name',
                                                'Fee__r.Code__c',
                                                'Part__r.Part_Number__c',
                                                'Fee__r.Category__r.Name',
                                                'CO_Header__r.Customer_Name__c',
                                                'Invoice_Number__r.Invoice_Date__c',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'CO_Header__r.Owner__r.Name',
                                                'Price__c',
                                                'Revenue__c',
                                                'Price_When_Tax_Included__c',
                                                'Part__r.Description__c',
                                                'Fee__r.Description__c',
                                                'Item_Code__c',
                                                'Item_Description__c',
                                                'Per_Item_Profit__c',
                                                'Invoice_Number__r.Invoice_Number__c',
                                                'Invoice_Number__r.Salesperson__c',
                                                'Item_Type__c',
                                                'Invoice_Number__r.Invoice_Date_Formula__c',
                                                'Deal__c',
                                                'Sub_Total_With_Tax__c',
                                                'Total_Cost__c',
                                                'Total_Profit__c',
                                                'Pre_Tax_Part_Sales__c',
                                                'Pre_Tax_Fee_Sales__c',
                                                'CO_Header__c',
                                                'CO_Header__r.Name',
                                                'Part__r.Assigned_Location_1__c',
                                                'Part__r.Assigned_Location_2__c',
                                                'Qty_Pulled_Formula__c',
                                                'Qty_To_Pull__c',
                                                'Service_Order_Line_Item__c',
                                                'Qty_Committed__c',
                                                'Parts_To_Pull_Sale_Type__c',
                                                'CreatedDate'
                                },
                                
            'Deal__c' => new Set<String>  {
                                                'Id',
                                                'Name',
                                                'CO_Header__r.Name',
                                                'CO_Header__r.Customer_Name__c',
                                                'CO_header__r.Customer__r.Name',
                                                'Type__c',
                                                'CO_Header__r.Deal_Total__c ',
                                                'Status__c',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'CreatedDate',
                                                'Delivery_Date__c',
                                                'Unit_Price_And_Cost_Total__c',
                                                'Trade_In_Total__c',
                                                'Product_Total__c',
                                                'Fee_Total__c',
                                                'Sales_Tax_Total__c',
                                                'Part_Total__c',
                                                'Labour_Total__c',
                                                'Stamp_Duty_Total__c',
                                                'Lien_Payout_Total__c',
                                                'F_I_Total__c',
                                                'CO_Header__r.Owner__r.Name',
                                                'Owner.Name',
                                                'Pre_Tax_Fee_Total__c',
                                                'Pre_Tax_Other_Product_Total__c',
                                                'Pre_Tax_Part_And_Labor_Total__c',
                                                'Pre_Tax_Trade_In_Total__c',
                                                'Pre_Tax_Unit_Price_And_Cost_Total__c',
                                                'CO_Header__r.Customer__r.FirstName__c',
                                                'CO_Header__r.Customer__r.LastName__c',
                                                'CO_Header__r.Customer__r.BillingStreet',
                                                'CO_Header__r.Customer__r.BillingCity',
                                                'CO_Header__r.Customer__r.BillingState',
                                                'CO_Header__r.Customer__r.BillingPostalCode',
                                                'CO_Header__r.Customer__r.Type__c',
                                                'CO_Header__r.Customer__r.Home_Number__c',
                                                'CO_Header__r.Customer__r.Work_Number__c',
                                                'CO_Header__r.Customer__r.Formatted_Home_Number__c',
                                                'CO_Header__r.Customer__r.Formatted_Work_Number__c',
                                                'CO_Header__r.Customer__r.Preferred_Phone__c',
                                                'CO_Header__r.Customer__r.Mobile__c',
                                                'CO_Header__r.Customer__r.Formatted_Mobile_Number__c',
                                                'CO_Header__r.Customer__r.Email__c',
                                                'CO_Header__r.Customer__r.Work_Email__c',
                                                'CO_Header__r.Customer__r.Other_Email__c',
                                                'CO_Header__r.Owner__r.Name',
                                                'Salesperson_Name__c', 
                                                'Invoice_Number__r.Salesperson__c',
                                                'Total_Finance_Commission__c',
                                                'Deal_Commission__c',
                                                'Option_Clearing__c',
                                                'Stocked_Trades__c',
                                                'Invoice_Number__r.Invoice_Number__c',
                                                'Invoice_Number__r.Invoice_Date__c',
                                                'CO_Header__r.Customer_Name__c',
                                                '(SELECT Customer_Owned_Unit__c, Customer_Owned_Unit__r.Formatted_Name__c FROM Deal_Items__r where Customer_Owned_Unit__c != null AND Type__c = \'Unit\' Order by Name Asc limit 2)'
                                },
             'Deal_Item__c' => new Set<String>  {
                                                'Id',
                                                'Name',
                                                'Customer_Owned_Unit__r.Id',
                                                'Customer_Owned_Unit__r.Name',
                                                'Customer_Owned_Unit__r.Make_Name__c',
                                                'Customer_Owned_Unit__r.Model_Name__c',
                                                'Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c',
                                                'Customer_Owned_Unit__r.Year__c',
                                                'Customer_Owned_Unit__r.Status__c',
                                                'Customer_Owned_Unit__r.VIN_Number_Formula__c',
                                                'Customer_Owned_Unit__r.New_Unit__c',
                                                'Customer_Owned_Unit__r.Category__r.Name',
                                                'Customer_Owned_Unit__r.Date_Stocked_In__c',
                                                'Customer_Owned_Unit__r.Age__c',
                                                'Deal__r.Confirmed_Sale_Date__c',
                                                'Unit_Type__c',
                                                'Customer_Owned_Unit__r.Mileage_Value__c',
                                                'Customer_Owned_Unit__r.Mileage_Type__c',
                                                'Customer_Owned_Unit__r.Colour__c',
                                                'Customer_Owned_Unit__r.Interior_Colour__c',
                                                'Customer_Owned_Unit__r.Stock_Id__c',
                                                'Customer_Owned_Unit__r.Unit_Number__c',
                                                'Customer_Owned_Unit__r.Assigned_Tag_2__c',
                                                'Customer_Owned_Unit__r.Assigned_Tag_1__c',
                                                'Customer_Owned_Unit__r.Formatted_Name__c',
                                                'Deal__r.CO_Header__c',
                                                'Deal__r.CO_Header__r.Name',
                                                'Deal__r.CO_Header__r.Customer_Name__c',
                                                'Deal__r.Type__c',
                                                'Deal__r.Status__c',
                                                'Other_Product_Total__c',
                                                'Labour_Total__c',
                                                'Base_Price__c',
                                                'Dealer_Option_Total__c',
                                                'Factory_Option_Total__c',
                                                'Fee_Total__c',
                                                'Part_Total__c',
                                                'Sublet_Total__c',
                                                'Warranty_Product_Total__c',
                                                'Stamp_Duty_Total__c',
                                                'Total_Price__c',
                                                'Total_Cost__c',
                                                'Total_Profit__c',
                                                'Unit_Price__c',
                                                'Unit_Cost__c',
                                                'Unit_Profit__c',
                                                'Unit_Option_Price__c',
                                                'Unit_Option_Cost__c',
                                                'Unit_Option_Profit__c',
                                                'Date_Sold__c',
                                                'Type__c',
                                                'Owner.Name',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'CreatedDate',
                                                'Customer_Owned_Unit__r.Compliance_Date__c',
                                                'Customer_Owned_Unit__r.Year_Of_1st_Rego__c',
                                                'Customer_Owned_Unit__r.Registration_Serial__c',
                                                'Customer_Owned_Unit__r.Manufactured_Date__c',
                                                'Deal__r.CO_Header__r.Customer__r.FirstName__c',
                                                'Deal__r.CO_Header__r.Customer__r.LastName__c',
                                                'Deal__r.CO_Header__r.Customer__r.BillingStreet',
                                                'Deal__r.CO_Header__r.Customer__r.BillingCity',
                                                'Deal__r.CO_Header__r.Customer__r.BillingState',
                                                'Deal__r.CO_Header__r.Customer__r.BillingPostalCode',
                                                'Deal__r.CO_Header__r.Customer__r.Type__c',
                                                'Deal__r.CO_Header__r.Customer__r.Home_Number__c',
                                                'Deal__r.CO_Header__r.Customer__r.Work_Number__c',
                                                'Deal__r.CO_Header__r.Customer__r.Formatted_Home_Number__c',
                                                'Deal__r.CO_Header__r.Customer__r.Formatted_Work_Number__c',
                                                'Deal__r.CO_Header__r.Customer__r.Preferred_Phone__c',
                                                'Deal__r.CO_Header__r.Customer__r.Mobile__c',
                                                'Deal__r.CO_Header__r.Customer__r.Formatted_Mobile_Number__c',
                                                'Deal__r.CO_Header__r.Customer__r.Email__c',
                                                'Deal__r.CO_Header__r.Customer__r.Work_Email__c',
                                                'Deal__r.CO_Header__r.Customer__r.Other_Email__c',
                                                'Deal__r.CO_Header__r.Owner__r.Name',
                                                'Deal__r.Salesperson_Name__c',
                                                'Deal__r.Invoice_Number__r.Salesperson__c',
                                                'Deal__r.Invoice_Number__r.Invoice_Number__c',
                                                'Deal__r.Invoice_Number__r.Invoice_Date__c',
                                                'Total_Price_With_Tax__c',
                                                'Actual_Cash_Value__c',
                                                'Total_Profit__c',
                                                'Pre_Tax_Agreed_Value__c',
                                                'Pre_Tax_Agreed_Value_ACV_Variance__c',
                                                'Total_Cost__c',
                                                'Customer_Owned_Unit__r.Unit_Data_01__c',
                                                'Customer_Owned_Unit__r.Unit_Data_02__c',
                                                'Customer_Owned_Unit__r.Unit_Data_03__c',
                                                'Customer_Owned_Unit__r.Unit_Data_04__c',
                                                'Customer_Owned_Unit__r.Unit_Data_05__c',
                                                'Customer_Owned_Unit__r.Unit_Data_06__c',
                                                'Customer_Owned_Unit__r.Unit_Data_07__c',
                                                'Customer_Owned_Unit__r.Unit_Data_08__c',
                                                'Customer_Owned_Unit__r.Unit_Data_09__c',
                                                'Customer_Owned_Unit__r.Unit_Data_10__c',
                                                'Customer_Owned_Unit__r.Unit_Data_11__c',
                                                'Customer_Owned_Unit__r.Unit_Data_12__c',
                                                'Customer_Owned_Unit__r.Unit_Data_13__c',
                                                'Customer_Owned_Unit__r.Unit_Data_14__c',
                                                'Customer_Owned_Unit__r.Unit_Data_15__c',
                                                'Deal__r.Confirmed_Sale_Date__c',
                                                'Unit_Type__c',
                                                'Unit_Status__c',
                                                'Unit_Make__r.Name',
                                                'Unit_Model__r.Name__c',
                                                'Sub_Model__r.Sub_Model_Name__c',
                                                'Year__c',
                                                'Colour__c',
                                                'Lien_Payout__c'
            					},
            'Service_Order_Line_Item__c' => new Set<String>  {   
                                                'Id',
                                                'Name',
                                                'Part__r.Vendor__r.Name',
                                                'Sublet__r.Vendor__r.Name',
                                                'Part__r.Part_Number__c',
                                                'Part__r.Part_Type__c',
                                                'Labour_Code__r.Code__c',
                                                'Fee__r.Code__c',
                                                'Qty_Needed__c',
                                                'Kit_Price__c',
                                                'Revenue__c',
                                                'Per_Item_Profit__c',
                                                'Price_When_Tax_Included__c',
                                                'Part__r.Description__c',
                                                'Fee__r.Description__c',
                                                'Labour_Code__r.Description__c',
                                                'Sublet__r.Code__c',
                                                'Sublet__r.Description__c',
                                                'Item_Code__c',
                                                'Item_Description__c',
                                                'Part__r.Category__r.Name',
                                                'Fee__r.Category__r.Name',
                                                'Labour_Code__r.Category__r.Name',
                                                'Sublet__r.Category__r.Name',
                                                'Service_Order_Header__r.CO_Header__r.Customer_Name__c',
                                                'Service_Order_Header__r.CO_Header__r.Owner__r.Name',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'Service_Order_Header__r.Invoice_Number__r.Invoice_Number__c',
                                                'Service_Order_Header__r.Invoice_Number__r.Invoice_Date__c',
                                                'Sublet__r.Type__c',
                                                'Service_Order_Header__r.Invoice_Number__r.Salesperson__c',
                                                'Service_Order_Header__r.Transaction_Type__r.Type__c',
                                                'Part__c',
                                                'Labour_Code__c',
                                                'Sublet__c',
                                                'Fee__c',
                                                'Type__c',
                                                'Item_Desc__c',
                                                'Total_Price_With_Tax__c',
                                                'Total_Cost__c',
                                                'Total_Profit__c',
                                                'Pre_Tax_Part_Sales__c',
                                                'Pre_Tax_Fee_Sales__c',
                                                'Pre_Tax_Labor_Sales__c',
                                                'Pre_Tax_Sublet_Sales__c',
                                                'Pre_Tax_Supplies_Sales__c',
                                                'Service_Order_Header__r.CO_Header__c',
                                                'Fee__r.Is_Include_In_Profit_Calculation__c'

                                },
            'Option_Fee__c' => new Set<String>  {   
                                                'Id',
                                                'Name',
                                                'Product__c',
                                                'Part__c',
                                                'Fee__c',
                                                'Labour_Code__c',
                                                'Revenue__c',
                                                'Per_Item_Profit__c',
                                                
                                                'Product__r.Description__c',
                                                'Part__r.Description__c',
                                                'Fee__r.Description__c',
                                                'Labour_Code__r.Description__c',
                                                'Item_Code__c',
                                                'Item_Description__c',
                                                'Part__r.Part_Type__c',
                                                'Part__r.Vendor__r.Name',
                                                'Product__r.Vendor__r.Name',
                                                
                                                'Part__r.Part_Number__c',
                                                'Labour_Code__r.Code__c',
                                                'Fee__r.Code__c',
                                                'Product__r.Code__c',
                                                'Product__r.Type__c',
                                                
                                                'Part__r.Category__r.Name',
                                                'Fee__r.Category__r.Name',
                                                'Labour_Code__r.Category__r.Name',
                                                'Product__r.Category__r.Name',
                                                
                                                'Deal__r.CO_Header__r.Customer_Name__c',
                                                'Deal__r.CO_Header__r.Owner__r.Name',
                                                
                                                'Deal__r.Invoice_Number__r.Invoice_Number__c',
                                                'Deal__r.Invoice_Number__r.Invoice_Date__c',
                                                'Qty__c',
                                                'Price__c',
                                                'Price_When_Tax_Included__c',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'Total_Price_With_Tax__c',
                                                'Total_Cost__c',
                                                'Total_Profit__c',
                                                'Pre_Tax_Option_Part_Sales__c',
                                                'Pre_Tax_Option_Labor_Sales__c',
                                                'Pre_Tax_Option_Sublet_Sales__c',
                                                'Pre_Tax_Option_Fee_Sales__c',
                                                'Pre_Tax_Option_Warranty_Sales__c',
                                                'Pre_Tax_Option_Other_Product_Sales__c',
                                                'Deal__r.Invoice_Number__r.Salesperson__c',
                                                'Deal__r.CO_Header__c',
												'Fee__r.Is_Include_In_Profit_Calculation__c'
                                },                  
            'Vendor_Order_Line_Item__c' => new Set<String>  {   
                                                'Id',
                                                'Name',
                                                'Part__r.Vendor__r.Name',
                                                'Sublet__r.Vendor__r.Name',
                                                'Service_Order_Line_Item__r.Item_Code__c',
                                                'Service_Order_Line_Item__r.Item_Description__c',
                                                'Part__r.Description__c', 
                                                'Part__r.Item_Description__c',
                                                'CO_Header__r.Name',
                                                'CO_Header__c',
                                                'Cost__c',
                                                'Qty_Needed__c',
                                                'Part__r.Status__c',
                                                'Part__r.Part_Type__c',
                                                'Part__r.Part_Number__c',
                                                'Part__r.Last_Cost__c',
                                                'Is_required_For_Customer__c',
                                                'Is_Service__c',
                                                'CO_Header__r.Customer__r.Name',
                                                'LastModifiedDate',
                                                'Last_Modified_Date__c',
                                                'Status__c',
                                                'Dealer_Name__c',
                                                'Total_Cost__c',
                                                'Owner.Name',
                                                'LastModifiedDate__c',
                                                'CreatedDate__c',
                                                'CreatedDate',
                                                'Needed_For__c',
                                                'Customer__c',
                                                'Part__r.AvailableParts__c',
                                                'Part__r.Qty_On_Order__c',
                                                'Vendor_Order_Header__c',
                                                'Vendor_Order_Header__r.Vendor__c',
                                                'Vendor_Order_Header__r.Vendor__r.Name',
                                                'Item_Description__c',
                                                'Vendor_Order_Header__r.Name',
                                                'Vendor_Order_Header__r.Ordered_Date__c',
                                                'Vendor_Order_Header__r.Expected_Date_Formula__c',
                                                'Vendor_Order_Header__r.LastModifiedDate__c', 
                                                'Vendor_Order_Header__r.Last_Modified_Date__c',
                                                'Service_Order_Line_Item__r.CO_Header_Id__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__r.Name__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__r.SO_Status__c',
                                                'Service_Order_Line_Item__r.Service_Order_Header__r.Job_Type__c',
                                                'Service_Order_Line_Item__r.Status__c',
                                                'Service_Order_Line_Item__r.Total_Price_With_Tax__c',
                                                'Service_Order_Line_Item__r.Item_Desc__c',
                                                'Vendor_Receiving_Group__r.Vendor_Receiving_Header__r.Name',
                                                'Sublet__c',
                                                'Sublet_Calculated_Total_Cost__c',
                                                'Sublet_Accrual__c',
                                                'Receiving_Status__c'
                                },
            'Part_FIFO_Bucket__c' => new Set<String>  {   
                                                'Name',
                                                'CreatedDate',
                                                'Qty_In__c',
                                                'Cost__c',
                                                'Source_Name__c',
                                                'Part__c',
                                                'Qty_In_Stock_When_Created__c',
                                                'Average_Cost_When_Created__c',
                                                '(SELECT CO_Line_Item__r.Price__c, CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Price__c from Coli_Fifo_Line_Items_Junction__r WHERE CO_Line_Item__c != null AND (CO_Line_Item__r.Price__c != null OR CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Price__c != null))'
                                },
             'Part_FIFO_Bucket_Activity_Line_Item__c' => new Set<String>  {   
                                                'Name',
                                                'CreatedDate',
                                                'Qty_Out__c',
                                                'Cost__c',
                                                'CO_Invoice_Header__c',
                                                'Reference__c',
                                                'Part_FIFO_Bucket__r.Cost__c',
                                                'Part_FIFO_Bucket__r.Part__c',
                                                'Qty_In_Stock_When_Created__c',
                                                'Average_Cost_When_Created__c',
                                                '(SELECT CO_Line_Item__r.Price__c, CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Price__c from Coli_Fifo_Line_Items_Junction__r WHERE CO_Line_Item__c != null AND (CO_Line_Item__r.Price__c != null OR CO_Line_Item__r.Service_Order_Line_Item__r.Kit_Price__c != null))'
                                },
             'Deal_Unit_Price_Cost__c'	=>	new Set<String>{
								             	'Item_Description__c',
										        'Price__c',
										        'Price_When_Tax_Included__c',
										        'Deal_Item__r.Deal__r.Invoice_Number__r.Invoice_Number__c',
		                                        'Deal_Item__r.Deal__r.Invoice_Number__r.Invoice_Date__c',
                                                'Deal_Item__r.Deal__r.Invoice_Number__r.Salesperson__c',
                                                'Qty__c',
                                                'Total_Price_With_Tax__c',
                                                'Total_Pre_Tax_Price__c',
                                                'Total_Cost__c',
                                                'Total_Profit__c',
                                                'Pre_Tax_Base_Sales__c',
                                                'Pre_Tax_Dealer_Sales__c',
                                                'Pre_Tax_Factory_Sales__c',
                                                'Deal_Item__r.Deal__r.CO_Header__r.Customer_Name__c',
                                                'Type__c',
                                                'Deal_Item__r.Deal__r.CO_Header__c',
                                                'Name'
								},
			 'F_I_Product__c'	=>	new Set<String>{
								        'Item_Description__c',
								        'Price__c',
								        'Price_When_Tax_Included__c',
								        'Deal_Finance__r.Deal__r.Invoice_Number__r.Invoice_Number__c',
                                        'Deal_Finance__r.Deal__r.Invoice_Number__r.Invoice_Date__c',
                                        'Deal_Finance__r.Deal__r.Invoice_Number__r.Salesperson__c',
                                        'Total_Cost__c',
                                        'Total_Profit__c',
                                        'Deal_Finance__r.Deal__r.CO_Header__r.Customer_Name__c',
                                        'Deal_Finance__r.Deal__r.CO_Header__c',
                                        'Name'
                    
								},
            'Deal_Finance__c'	=>	new Set<String>{
                                        'Deal__r.CO_Header__c',
                                        'Deal__r.Invoice_Number__r.Invoice_Number__c',
                                        'Deal__r.Invoice_Number__r.Invoice_Date__c',
                                        'Deal__r.CO_Header__r.Customer_Name__c',
                                        'Deal__r.Invoice_Number__r.Salesperson__c',
                                        'Finance_Commission__c',
                                        'Buy_Rate_Commission__c',
                                        'Name'
                                },
            'Return_CR_Header__c'	=>	new Set<String>{
                                        'Name',
                                        'Vendor__r.Name',
                                        'Vendor__r.Purchase_Tax__c',
                                        'Owner.Name',
                                        'Status__c',
                                        'Total_With_Tax__c',
                                        'CreatedDate',
                                        'LastModifiedDate',
                                        'Credit_Memo__c',
                                        'Credited_Date__c',
                                        'Item_Total__c',
                                        'Other_Charges_Total__c',
                                        'Vendor__r.Vendor_Account_Type__r.Name',
                                        '(Select Id, Is_Taxable__c, Cost__c FROM Other_Charges__r WHERE Is_Taxable__c = false)'
                                }
          };
    
    //Modified by Nidhi - #1152 - 19-10-2016   
    // A map to define group with object names
    public static Map<String, List<String>> groupNameToGroupObjectsMap = new Map<String, List<String>>{ 'People'            => new List<String>{'Customers', 'Vendors'},
                                                                                                        'Products'          => new List<String>{'Parts', 'Kits', 'Fees', 'Labor Codes', 'Sublets', 'Vendor Product', 'Inventory Unit'},
                                                                                                        'Customer Sales'    => new List<String>{'Customer Orders', 'Customer Invoices', 'Customer Payments', 'Service Jobs', 'Claim Jobs', 'Unit Deals', 'Parts Order'},
                                                                                                        'Vendor Ordering'   => new List<String>{'Vendor Orders', 'Vendor Receivings', 'Vendor Invoices'},
                                                                                                        'Setting'           => new List<String>{'Item Categories', 'Sales Taxes', 'Price Levels'}
                                                                                                    };
    
    //Modified by Nidhi - #1152 - 19-10-2016   
    // A map to define group/display object name to object API name
    public static Map<String, String> displayObjectNameToObjectAPINameMap = new Map<String, String>{'People'            => 'Account',
                                                                                                    'Customers'         => 'Account',
                                                                                                    'Vendors'           => 'Account',
                                                                                                    'Parts'             => 'Part__c',
                                                                                                    'Kits'              => 'Kit_Header__c',
                                                                                                    'Fees'              => 'Fee__c',
                                                                                                    'Labor Codes'       => 'Labour_Code__c',
                                                                                                    'Sublets'           => 'Product__c',
                                                                                                    'Vendor Product'   => 'Product__c',
                                                                                                    'Financing Product' => 'Product__c',
                                                                                                    'Deal Product'      => 'Product__c',
                                                                                                    'Warranty Plan'     => 'Product__c',
                                                                                                    'Other Product'     => 'Product__c',
                                                                                                    'Users'             => 'User',
                                                                                                    'Customer Orders'   => 'CO_Header__c',
                                                                                                    'Customer Invoices' => 'CO_Invoice_Header__c',
                                                                                                    'Customer Payments' => 'CO_Invoice_Payment__c',
                                                                                                    'Customer Deposits' => 'CO_Deposit__c',
                                                                                                    'AR Payments'		=> 'Payment_on_Account__c',
                                                                                                    'Vendor Orders'     => 'Vendor_Order_Header__c',
                                                                                                    'Vendor Returns' => 'Return_VO_Header__c',
                                                                                                    'Vendor Credit' => 'Return_CR_Header__c',
                                                                                                    'Vendor Receivings' => 'Vendor_Receiving_Header__c',
                                                                                                    'Vendor Invoices'   => 'Vendor_Invoicing_Header__c',
                                                                                                    'Item Categories'   => 'Category__c',
                                                                                                    'Price Levels'      => 'Price_Level__c',
                                                                                                    'Sales Taxes'       => 'Sales_Tax__c',
                                                                                                    'Service Jobs'      => 'Service_Order_Header__c',
                                                                                                    //Dinesh Kumar 10/10/2016
                                                                                                    'Parts Needed'      => 'Vendor_Order_Line_Item__c',
                                                                                                    'Inventory Unit'        => 'Customer_Owned_Unit__c',
                                                                                                    'Part Inventory Valuation'      => 'Part__c',
                                                                                                    'Customer Unit'        => 'Customer_Owned_Unit__c',
                                                                                                    'Invoiced Items'       => 'CO_Line_Item__c',
                                                                                                    'SOLI'                 => 'Service_Order_Line_Item__c',
                                                                                                    'Option and Fee'       => 'Option_Fee__c',
                                                                                                    'Technician Hours'     => 'Hours_Logged__c',
                                                                                                    'Payroll Hours'        => 'Payroll_Time__c',
                                                                                                    'Technician Performance'=> 'Technician__c',
                                                                                                    'Parts to Pull'        => 'CO_Line_Item__c',
                                                                                                    'Unit Deals' => 'Deal__c',
                                                                                                    'Part FIFO' => 'Part_FIFO_Bucket__c',
                                                                                                    'Part FIFO Line Item' => 'Part_FIFO_Bucket_Activity_Line_Item__c',
                                                                                                    'Tax Detail Customer Invoices' => 'CO_Invoice_Header__c',
                                                                                                    'Tax Detail Vendor Invoices' => 'Vendor_Invoicing_Header__c',
                                                                                                    'Deal Units' => 'Deal_Item__c',
                                                                                                    'Parts Order' => 'CO_Header__c',
                                                                                                    'Special Order' => 'CO_Section_Detail__c',
                                                                                                    'SO Special Order' => 'Service_Order_Header__c',
                                                                                                    'Customer Invoice Details COLI'       => 'CO_Line_Item__c',
                                                                                                    'Customer Invoice Details SOLI'	=> 'Service_Order_Line_Item__c',
                                                                                                    'Customer Invoice Details Option and Fee'	=> 'Option_Fee__c',
                                                                                                    'Customer Invoice Details Deal UPC'	=> 'Deal_Unit_Price_Cost__c',
                                                                                                    'Customer Invoice Details Trade in'	=> 'Deal_Item__c',
                                                                                                    'Customer Invoice Details FI Product'	=> 'F_I_Product__c',
                                                                                                    'Customer Invoice Details Deal Finance'	=> 'Deal_Finance__c',
                                                                                                    'Customer Invoice Details Deal'	=> 'Deal__c',
                                                                                                    'Customer Invoice Details Lien'	=> 'Deal_Item__c',
                                                                                                    'Order Unit'	=>	'Customer_Owned_Unit__c',
                                                                                                    'VO Items' => 'Vendor_Order_Line_Item__c',
                                                                                                    'VO Items Parts' => 'Vendor_Order_Line_Item__c',
                                                                                                    'VO Items Sublets' => 'Vendor_Order_Line_Item__c',
                                                                                                    'Sublet Items' => 'Vendor_Order_Line_Item__c',
                                                                                                    'Claim Jobs'      => 'Service_Order_Header__c',
                                                                                                    'Unit Register'      => 'Customer_Owned_Unit__c'
                                                                                                };
    // Special Searching filters - which is having multiple objects to search but only display in one name LIKE - Tax Detail
    public static Map<String, String> displayObjectNameToObjectAPINameSpecialSearchMap = new Map<String, String> {
                                                                                                    'Tax Detail Customer Invoices'  => 'CO_Invoice_Header__c',
                                                                                                    'Tax Detail Vendor Invoices'    => 'Vendor_Invoicing_Header__c',
                                                                                                    'Tax Detail Unit Invoices'    => 'Customer_Owned_Unit__c',
                                                                                                    'Tax Detail Vendor Returns'    => 'Return_CR_Header__c',
                                                                                                    'Tax Detail Unit Adjustments'    => 'Unit_Price_Cost__c',
                                                                                                    'Customer Invoice Details COLI'    => 'CO_Line_Item__c',
                                                                                                    'Customer Invoice Details SOLI' => 'Service_Order_Line_Item__c',
                                                                                                    'Customer Invoice Details Option and Fee'   => 'Option_Fee__c',
                                                                                                    'Customer Invoice Details Deal UPC' => 'Deal_Unit_Price_Cost__c',
                                                                                                    'Customer Invoice Details Trade in' => 'Deal_Item__c',
                                                                                                    'Customer Invoice Details FI Product'   => 'F_I_Product__c',
                                                                                                    'Customer Invoice Details Deal Finance'	=> 'Deal_Finance__c',
                                                                                                    'Customer Invoice Details Deal'	=> 'Deal__c'
                                                                                                };
    
    //Modified by Nidhi - #1152 - 19-10-2016                                                                                                
    // A map to define group/display object name to object API name
    public static Map<String, String> displayObjectAPINameToObjectNameMap = new Map<String, String>{'Account'                       => 'Customer',
                                                                                                    CONSTANTS.NAMESPACE+'Part__c'                       => 'Part',
                                                                                                    CONSTANTS.NAMESPACE+'Kit_Header__c'                 => 'Kit',
                                                                                                    CONSTANTS.NAMESPACE+'Fee__c'                        => 'Fee',
                                                                                                    CONSTANTS.NAMESPACE+'Labour_Code__c'                => 'Labor Code',
                                                                                                    CONSTANTS.NAMESPACE+'Product__c'                    => 'Sublet',
                                                                                                    'User'                          => 'User',
                                                                                                    CONSTANTS.NAMESPACE+'CO_Header__c'                  => 'Customer Order',
                                                                                                    CONSTANTS.NAMESPACE+'CO_Invoice_Header__c'          => 'Customer Invoice',
                                                                                                    CONSTANTS.NAMESPACE+'CO_Invoice_Payment__c'         => 'Customer Payment',
                                                                                                    CONSTANTS.NAMESPACE+'CO_Deposit__c'                 => 'Customer Payment',
                                                                                                    CONSTANTS.NAMESPACE+'Payment_on_Account__c'                 => 'Customer Payment',
                                                                                                    CONSTANTS.NAMESPACE+'Vendor_Order_Header__c'        => 'Vendor Order',
                                                                                                    CONSTANTS.NAMESPACE+'Vendor_Receiving_Header__c'    => 'Vendor Receiving',
                                                                                                    CONSTANTS.NAMESPACE+'Vendor_Invoicing_Header__c'    => 'Vendor Invoice',
                                                                                                    CONSTANTS.NAMESPACE+'Category__c'                   => 'Item Categorie',
                                                                                                    CONSTANTS.NAMESPACE+'Price_Level__c'                => 'Price Level',
                                                                                                    CONSTANTS.NAMESPACE+'Sales_Tax__c'                  => 'Sales Tax',
                                                                                                    CONSTANTS.NAMESPACE+'Service_Order_Header__c'       => 'Service Job',
                                                                                                    CONSTANTS.NAMESPACE+'Vendor_Order_Line_Item__c'     => 'Parts Needed',
                                                                                                    CONSTANTS.NAMESPACE+'Customer_Owned_Unit__c'        => 'Customer Unit',
                                                                                                    CONSTANTS.NAMESPACE+'CO_Line_Item__c'               => 'Invoiced Items',
                                                                                                    CONSTANTS.NAMESPACE+'Service_Order_Line_Item__c'    => 'SOLI',
                                                                                                    CONSTANTS.NAMESPACE+'Option_Fee__c'                 => 'Option and Fee',
                                                                                                    CONSTANTS.NAMESPACE+'Hours_Logged__c'               => 'Technician Hours',
                                                                                                    CONSTANTS.NAMESPACE+'Payroll_Time__c'               => 'Payroll Hours',
                                                                                                    CONSTANTS.NAMESPACE+'Technician__c'                 => 'Technician Performance',
                                                                                                    CONSTANTS.NAMESPACE+'Part_FIFO_Bucket__c'           => 'Part FIFO',
                                                                                                    CONSTANTS.NAMESPACE+'Deal__c'          				=> 'Unit Deals',
                                                                                                    CONSTANTS.NAMESPACE+'Deal_Item__c'          		=> 'Deal Units',
                                                                                                    CONSTANTS.NAMESPACE+'CO_Section_Detail__c'          => 'Special Order'
                                                                                                };
    
    //Modified by Nidhi - #1152 - 19-10-2016                                                                                                
    // A map to define group/display object name to object API name
    public static Map<String, Integer> displayObjectNameToTypeNumber = new Map<String, Integer>{'Customers'         => 1,
                                                                                                'Vendors'           => 2,
                                                                                                'Parts'             => 3,
                                                                                                'Kits'              => 4,
                                                                                                'Fees'              => 5,
                                                                                                'Labor Codes'       => 6,
                                                                                                'Users'             => 7,
                                                                                                'Customer Orders'   => 8,
                                                                                                'Customer Invoices' => 9,
                                                                                                'Vendor Orders'     => 10,
                                                                                                'Vendor Receivings' => 11,
                                                                                                'Vendor Invoices'   => 12,
                                                                                                'Item Categories'   => 13,
                                                                                                'Price Levels'      => 14,
                                                                                                'Sales Taxes'       => 15,
                                                                                                'Sublets'           => 16,
                                                                                                'Customer Payments' => 17,
                                                                                                'Service Jobs'      => 18,
                                                                                                'Inventory Unit'    => 19,
                                                                                                'Parts Needed'      => 20,
                                                                                                'Part Inventory Valuation'  => 21,
                                                                                                'Customer Unit'  => 22,
                                                                                                'Financing Product' => 23,
                                                                                                'Deal Product'      => 24,
                                                                                                'Warranty Plan'     => 25,
                                                                                                'Vendor Returns'     => 26,
                                                                                                'Other Product'     => 27,
                                                                                                'Technician Hours'  => 28,
                                                                                                'Payroll Hours'     => 29,
                                                                                                'Technician Performance' => 30,
                                                                                                'Unit Deals' => 31,
                                                                                                'Deal Units' => 32,
                                                                                                'Parts Order' => 33,
                                                                                                'AR Payments' => 34,
                                                                                                'Special Order' => 35,
                                                                                                'Parts to Pull' => 36,
                                                                                                'Order Unit' => 37,
                                                                                                'VO Items Parts' => 38,
                                                                                                'VO Items Sublets' => 39,
                                                                                                'Sublet Items' => 40,
                                                                                                'Vendor Credit' => 41, 
                                                                                                'Claim Jobs' => 42, 
                                                                                                'Unit Register' => 43
                                                                                            };

    //Modified by Nidhi - #1152 - 19-10-2016                                                                                    
    public static Map<String, Integer> filterGroupToOrderMap = new Map<String, Integer>{'Reporting' => 1,
                                                                                        'Customer Sales'    => 2,
                                                                                        'Vendor Orders' => 3,
                                                                                        'Product'   => 4,
                                                                                        'People'    => 5,
                                                                                        'Setting'   => 6,
                                                                                        'Settings'  => 6,
                                                                                        
                                                                                        'Customer Payments' => 6,
                                                                                        'Invoice Summary' => 7,
                                                                                        'Invoice Detail' =>8,
                                                                                        'Tax Detail' => 9,
                                                                                        'Payroll Hours' => 10,
                                                                                        'Technician Hours' => 11,
                                                                                        'Technician Performance' => 12,
                                                                                        'Part Inventory Valuation' => 13,
                                                                                        'Part Inventory Aging' => 14,
                                                                                        'Part Movement' => 15,
                                                                                        'Active Part Sales' => 16,
                                                                                        'Open Service Jobs'   => 17,
                                                                                        'Claim Service Jobs' => 18,
                                                                                        'Active Unit Deals' => 19,
                                                                                        'Unit Sales Tracker' => 20,
                                                                                        'Deal Units' => 21,
                                                                                        'My Customer Orders'    => 22,
                                                                                        'All Customer Orders'   => 23,
                                                                                        'Recent Customer Invoices'  => 24,
                                                                                        'Units on order'  => 24,
                                                                                        'My Vendor Orders'  => 24,
                                                                                        'All Vendor Orders' => 25,
                                                                                        'Active Receivings' => 26,
                                                                                        'Recent Vendor Invoices'    => 26,
                                                                                        'Active Returns' => 27,
                                                                                        'Recent Parts'  => 27,
                                                                                        'Parts Needed'  =>28,
                                                                                        'Parts to Pull'  => 29,
                                                                                        'Special Order Summary'  =>30,
                                                                                        'Stock Units'               => 28,
                                                                                        'Kits'                      => 31,
                                                                                        'Sublets'                   => 32,
                                                                                        'Labor'                     => 33,
                                                                                        'Labour'                    => 32,
                                                                                        'Fees'                      => 34,
                                                                                        'Customers'                 => 35,
                                                                                        'Customer'                  => 35,
                                                                                        'Customer Units'            => 36,
                                                                                        'Vendors'                   => 37,
                                                                                        'Vendor'                    => 38,
                                                                                        'Category'                  => 38,
                                                                                        'Price Level'               => 39,
                                                                                        'Sales Tax'                 => 40,
                                                                                        'Product History Detail'    => 41,
                                                                                        'Product History Summary'   => 42,
                                                                                        'Unit Register'             => 43,
                                                                                        'Stock Unit Valuation'      => 44

                                                                                    };
    
    // Map to define label to UI map Key
    public static Map<String, Map<String, String>> objectNameToLabelToJSONKeyMap = new Map<String, Map<String, String>> {
            'Customers' => new Map<String, String>{ 'Id' => 'People_Id',
                                                    'Name' => 'People_Name',
                                                    'Phone' => 'People_Phone',
                                                    'Email' => 'People_Email',
                                                    'Address' => 'People_BillingAddress',
                                                    'City' => 'People_BillingCity',
                                                    'State' => 'People_StateProv',
                                                    'Country' => 'People_Country',
                                                    'Sales Tax' => 'People_SalesTax',
                                                    'Price Level' => 'People_PriceLevel',
                                                    'Account Type' => 'Customer_AccountType',
                                                    'Drivers License' => 'Customers_Drivers_License',
                                                    'Store Credits' => 'Customers_Store_Credits'
                            
                            },
            'Invoiced Items' => new Map<String, String>{ 'Type' => 'InvoicedItem_Type',
                                                    'Item' => 'InvoicedItem_Item',
                                                    'Customer' => 'InvoicedItem_Customer',
                                                    'Invoice date' => 'InvoicedItem_InvoiceDate',
                                                    'Category' => 'InvoicedItem_Category',
                                                    'Invoiced By' => 'InvoicedItem_InvoicedBy',
                                                    'Vendor' => 'InvoicedItem_Vendor',
                                                    'Qty' => 'InvoicedItem_Quantity',
                                                    'Revenue' => 'InvoicedItem_Revenue',
                                                    'Invoice Type' => 'InvoicedItem_Invoice_Type'
                            
                            },
                            
            'Technician Hours' => new Map<String, String>{ 'Type' => 'TechinicianHours_ItemType',
                                                    'Technician' => 'TechinicianHours_Technician',
                                                    'Date' => 'TechinicianHours_Date',
                                                    'Job Type' => 'TechinicianHours_JobType',
                                                    'Customer' => 'InvoicedItem_Customer'
                            },
             'Technician Performance' => new Map<String, String>{ 'Technician' => 'TechinicianPerformance_Technician',
                                                    'Date' => 'TechinicianPerformance_Date'
             },
                            
             'Payroll Hours' => new Map<String, String>{ 'Employee' => 'Payroll_Employee',
                                                    'Date' => 'Payroll_Date'
                            },
                            
            'Vendors' =>  new Map<String, String> { 'Id' => 'People_Id',
                                                    'Name' => 'People_Name',
                                                    'Phone' => 'People_Phone',
                                                    'Email' => 'People_Email',
                                                    'Address' => 'People_BillingAddress',
                                                    'City' => 'People_BillingCity',
                                                    'State' => 'People_StateProv',
                                                    'Country' => 'People_Country',
                                                    'Sales Tax' => 'People_SalesTax',
                                                    'Price Level' => 'People_PriceLevel',
                                                    'Purchase Sales Tax' => 'Vendor_PurchaseSalesTax',
                                                    'Account Type' => 'Vendor_AccountType'
                            },  
            'People' => new Map<String, String> {   'Id' => 'People_Id',
                                                    'Name' => 'People_Name',
                                                    'Phone' => 'People_Phone',
                                                    'Email' => 'People_Email',
                                                    'Address' => 'People_BillingAddress',
                                                    'City' => 'People_BillingCity',
                                                    'State' => 'People_StateProv',
                                                    'Country' => 'People_Country',
                                                    'Sales Tax' => 'People_SalesTax',
                                                    'Price Level' => 'People_PriceLevel'
                                },
                                            
            'Products' => new Map<String, String> { 'Item'              => 'Product_Item',
                                                    'Description'       => 'Product_Description',
                                                    'Category'          => 'Product_Category' ,
                                                    'Price'             => 'Product_Price'
                                                    //'Qty Available'     => 'Product_QtyAvailable'
                                                },      
                                                                        
            'Kits' => new Map<String, String> {     'Item'              => 'Product_Item',
                                                    'Description'       => 'Product_Description',
                                                    'Category'          => 'Product_Category',
                                                    'Price'             => 'Product_Price',
                                                    //'Qty Available'     => 'Product_QtyAvailable',
                                                    'Kit Price'         => 'Kit_KitPrice',
                                                    'Fixed Price'       => 'Kit_FixedPrice' ,
                                                    'Service Kit'       =>'Kit_ServiceKit' 
                                                },  
                                                
            'Fees' => new Map<String, String> {     'Item'              => 'Product_Item',
                                                    'Description'       => 'Product_Description',
                                                    'Category'          => 'Product_Category' ,
                                                    'Price'             => 'Product_Price',
                                                    'Forms Tags'        => 'AssignedTags',
                                                    'Fee Type'          => 'Fee_FeeType'
                                                },  
                                                
            'Service_Jobs' => new Map<String, String> { 'Customer'          => 'Service_Job_Customer',
                                                        'Job Type'          => 'Service_Job_Job_Type',
                                                		'SO Status'         => 'Service_Jobs_SO_Status',
                                                        'Job'               => 'Service_Job_Job',
                                                        'Unit Description'  => 'Service_Job_Unit_Description',
                                                        'Technician'        => 'Service_Job_Technician',
                                                        'VIN'               => 'Service_Job_VIN',
                                                        'Plate Number'      => 'Service_Job_Plate_Number',
                                                        'Engine Number'     => 'Service_Job_Engine_Number',
                                                        'Unit Number'       => 'Service_Job_Unit_Number',
                                                        'Scheduled'         => 'Service_Job_Scheduled',
                                                        'Invoice Date'      => 'Service_Job_Invoice_Date',
                                                        'Invoice Number'    => 'Service_Job_Invoice_Number',
                                                        'Hrs Billed'        => 'Service_Job_Hrs_Billed',
                                                        'Hrs Logged'        => 'Service_Job_Hrs_Logged',
                                                        'Parts Total'       => 'Service_Job_Parts_Total',
                                                        'Labor Total'       => 'Service_Job_Labor_Total',
                                                        'Sublet Total'      => 'Service_Job_Sublet_Total',
                                                        'Fees Total'        => 'Service_Job_Fees_Total',
                                                        'Tax Total'         => 'Service_Job_Tax_Total',
                                                        'Total'             => 'Service_Job_Total',
                                                        'Odometer In'       => 'Service_Job_Odometer_In',
                                                        'Odometer Out'      => 'Service_Job_Odometer_Out',
                                                        'SO Type'           => 'Service_Job_SO_Type',
                                                        'Provider'          => 'Service_Job_Provider',
                                                        'Claim Status'      => 'Service_Job_Claim_Status',
                                                        'Make'              => 'Service_Job_Make',
                                                        'Model'             => 'Service_Job_Model',
                                                        'SubModel'          => 'Service_Job_SubModel',
                                                        'Salesperson'		=> 'Service_Job_Salesperson',
                                                        'Date Due In'       => 'Service_Job_Date_Due_In',
                                                        'Date Promised'     => 'Service_Job_Date_Promised',
                                                        'Unit Arrived'      => 'Service_Job_Unit_Arrived'
                                                },                                                  
                                                
            'Inventory_Unit' => new Map<String, String> { 'VIN'             => 'Inventory_Unit_VIN',
                                                        'Stock Number'      => 'Inventory_Unit_Stock_Number',
                                                        'Make'              => 'Inventory_Unit_Make',
                                                        'Model'             => 'Inventory_Unit_Model',
                                                        'SubModel'          => 'Inventory_Unit_SubModel', 
                                                        'Year'              => 'Inventory_Unit_Year',
                                                        'Ext Colour'        => 'Inventory_Unit_Ext_Colour',
                                                        'New Unit'          => 'Inventory_Unit_New_Unit',
                                                        'Base Unit Price'   => 'Inventory_Unit_Base_Unit_Price',
                                                        'Factory Options'   => 'Inventory_Unit_Factory_Options',
                                                        'Dealer Options'    => 'Inventory_Unit_Dealer_Options',
                                                        'Total Price'       => 'Inventory_Unit_Total_Price',
                                                        'Base Unit Cost'    => 'Inventory_Unit_Base_Unit_Cost',
                                                        'Factory Option Cost'=> 'Inventory_Unit_Factory_Option_Cost',
                                                        'Dealer Option Cost'=> 'Inventory_Unit_Dealer_Option_Cost', 
                                                        'Deal Options WIP'  => 'Inventory_Unit_Deal_Options_WIP',
                                                        'Total Cost'        => 'Inventory_Unit_Total_Cost',
                                                        'Location'          => 'Inventory_Unit_Location', 
                                                        'Category'          => 'Inventory_Unit_Category',
                                                        'Stocked'           => 'Inventory_Unit_Stocked_In',
                                                        'Age'               => 'Inventory_Unit_Age',
                                                        'Key Number'        => 'Inventory_Unit_Key_Number',
                                                        'Engine Number'     => 'Inventory_Unit_Engine_Number',
                                                        'Other Number'      => 'Inventory_Unit_Other_Number',
                                                        'Int Colour'        => 'Inventory_Unit_Int_Colour',
                                                        'Stocked Out'       => 'Inventory_Unit_Stocked_Out',
                                                        'Taxable'           => 'Inventory_Unit_Taxable',
                                                        'Applicable Tax'    => 'Inventory_Unit_Applicable_Tax',
                                                        'Cylinders'         => 'Inventory_Unit_Cylinders' ,
                                                        'Automatic'         => 'Inventory_Unit_Automatic',
                                                        'Manufactured Date' => 'Inventory_Unit_Manufactured_Date',
                                                        'Mileage'           => 'Inventory_Unit_Mileage',
                                                        'Plate Number'      => 'Inventory_Unit_Plate_Number',
                                                        'Reg Expiry'        => 'Inventory_Unit_Reg_Expiry',
                                                        'Tags'              => 'AssignedTags' ,
                                                        'Unit Type'         => 'Inventory_Unit_Unit_Type',
                                                        'Compliance Date'         => 'Inventory_Unit_Compliance_Date',
                                                        'Year of 1st Rego'         => 'Inventory_Unit_Year_Of_1st_Rego',
                                                        'Registration Serial#'         => 'Inventory_Unit_Registration_Serial',
                                                        'NITC Withheld'		=> 'Inventory_Unit_NITC_Withheld',
                                                        'Include Consignment'		=> 'IncludeConsignments',
                                                        'In Stock As Of'    => 'Inventory_Unit_In_Stock_As_Of',
                                                        'Vendor'    => 'Inventory_Unit_Vendor'
                                                },  
                                                
            'Customer_Unit' => new Map<String, String> {'Unit ID'           => 'Customer_Unit_Unit_ID',
                                                        'Customer'          => 'Customer_Unit_Customer' ,
                                                        'Year'              => 'Customer_Unit_Year',
                                                        'Make'              => 'Customer_Unit_Make',
                                                        'Model'             => 'Customer_Unit_Model',
                                                        'SubModel'          => 'Customer_Unit_SubModel',
                                                        'Mileage'           => 'Customer_Unit_Mileage',  
                
                                                        'VIN'               => 'Customer_Unit_VIN',
                                                        'Plate Number'      => 'Customer_Unit_Plate_Number',
                                                        'Reg Expiry'        => 'Customer_Unit_Reg_Expiry' ,
                                                        'Key Number'        => 'Customer_Unit_Key_Number',
                                                        'Engine Number'     => 'Customer_Unit_Engine_Number',
                                                        'Other Number'      => 'Customer_Unit_Other_Number',
                                                        'Ext Colour'        => 'Customer_Unit_Ext_Colour',
                                                        'Int Colour'        => 'Customer_Unit_Int_Colour',
                                                        'Tags'              => 'AssignedTags',
                                                        'Account Type' => 'Customer_AccountType',
                                                        'Compliance Date' => 'Customer_Unit_Compliance_Date',
                                                        'Year of 1st Rego' => 'Customer_Unit_Year_Of_1st_Rego',
                                                        'Registration Serial#' => 'Customer_Unit_Registration_Serial',
                                                        'Manufactured Date' => 'Customer_Unit_Manufactured_Date'
                                                },
            'Order_Unit' => new Map<String, String> {
                                                        'Make'              => 'Order_Unit_Make',
                                                        'Model'             => 'Order_Unit_Model',
                                                        'SubModel'          => 'Order_Unit_SubModel', 
                                                        'Year'              => 'Order_Unit_Year',
                                                        'Unit ID'           => 'Order_Unit_Unit_ID',
                                                        'Category'          => 'Order_Unit_Category',
                                                        'Ordered'          	=> 'Order_Unit_Ordered',
                                                        'Expected'          => 'Order_Unit_Expected',
                                                        'Days Out'          => 'Order_Unit_Days_Out',
                                                        'FO Number'         => 'Order_Unit_FO_Number',
                                                        'Committed'         => 'Order_Unit_Committed',
                                                        'Unit Cost'        	=> 'Order_Unit_Unit_Cost',
                                                        'Tax'        		=> 'Order_Unit_Tax',
                                                        'Total Cost'        => 'Order_Unit_Total_Cost',
                                                        'Retail Price'      => 'Order_Unit_Retail_Price',
                                                        'Vendor'          	=> 'Order_Unit_Vendor' ,
                                                        'VIN'             	=> 'Order_Unit_VIN',
                                                        'Stock Number'      => 'Order_Unit_Stock_Number',
                                                        'Ext Color'        	=> 'Order_Unit_Ext_Color',
                                                        'Int Color'        	=> 'Order_Unit_Int_Color'
                                                },
            'Labor_Codes' => new Map<String, String> {  'Item'          => 'Product_Item',
                                                        'Description'   => 'Product_Description',
                                                        'Category'      => 'Product_Category' ,
                                                        'Forms Tags'   	=> 'AssignedTags',
                                                        'Price'         => 'Product_Price'
                                                        //'Qty Available' => 'Product_QtyAvailable'
                                                },
            'Product__c' => new Map<String, String> {   'Category'  =>  'Category__r.Name',
                                                        'Code'      => 'Code__c',
                                                        'Cost'      => 'Cost__c',
                                                        'Description'=> 'Description__c',
                                                        'Modified'  =>  'Last_Modified_Date__c',
                                                        'Price'     =>  'Price__c',
                                                        'Status'    =>  'Status__c',
                                                        'Vendor Code'=> 'Vendor_Code__c'
                                                },                              
                                                
            'Parts' => new Map<String, String> {        'Item'          => 'Product_Item',
                                                        'Description'   => 'Product_Description',
                                                        'Category'      => 'Product_Category' ,
                                                        'Price'         => 'Product_Price',
                                                        'Qty Available' => 'Product_QtyAvailable',
                                                        'Vendor'        => 'Part_Vendor',
                                                        'Cost'          => 'Part_Cost',
                                                        'Avg Cost'      => 'Part_AverageCost',
                                                        'Location'      => 'Part_Location', 
                                                        'In Stock'      => 'Part_InStock',
                                                        'Committed'     => 'Part_Committed',
                                                        'On Order'      => 'Part_OnOrder',
                                                        'Packaged Part' => 'Part_PackagedPart',
                                                        'LastCounted'   => 'Part_LastCounted',
                                                        'Last Sold'     => 'Part_LastSold',
                                                        'Last Stocked'  => 'Part_LastStocked',
                                                        'Reorder At'    => 'Part_ReorderAt', 
                                                        'Reorder To'    => 'Part_ReorderTo',
                                                        'Status'        =>  'Part_Status',
                                                        'Non Inventory' =>  'Part_NonInventory', //Added by richa 28/11/2016
                                                        'SKU'           =>  'Part_SKUNumber', //Added by richa 28/11/2016
                                                        'Mfg Part'      =>  'Part_MfgPart', //Added by richa 28/11/2016
                                                        'Oversold Qty'  =>  'Part_OversoldQty',
                                                        'Oversold Cost' =>  'Part_OversoldCost',
                                                        'PRD1 Qty'      => 'Part_PRD1Qty',
                                                        'PRD1 Cost'     => 'Part_PRD1Cost',
                                                        'PRD2 Qty'      => 'Part_PRD2Qty',
                                                        'PRD2 Cost'     => 'Part_PRD2Cost',
                                                        'PRD3 Qty'      => 'Part_PRD3Qty',
                                                        'PRD3 Cost'     => 'Part_PRD3Cost',
                                                        'PRD4 Qty'      => 'Part_PRD4Qty',
                                                        'PRD4 Cost'     => 'Part_PRD4Cost',
                                                        'Tags'          =>  'AssignedTags',
                                                        'Part Type'     =>  'Part_Type',
                                                        'Sale Price'      => 'Part_SalePrice',
                                                        'Publish In Feeds'      => 'Part_PublishInFeeds',
                                                        'Inventory Qty'  =>  'Part_InventoryQty',
                                                        'Last Price Update'   => 'Part_LastPriceUpdate',
                                                        'Last Edited'   => 'Part_LastEdited'
                                           },
                                           
            'Invoiced Items' => new Map<String, String> {'Item Type' => 'InvoicedItem_Type',
                                                        'Item'   => 'InvoicedItem_Item',
                                                        'Customer'      => 'InvoicedItem_Customer' ,
                                                        'Invoice date'         => 'InvoicedItem_InvoiceDate',
                                                        'Category' => 'InvoicedItem_Category',
                                                        'Invoiced By'        => 'InvoicedItem_InvoicedBy',
                                                        'Vendor'          => 'InvoicedItem_Vendor',
                                                        'Quantity'      => 'InvoicedItem_Quantity',
                                                        'Revenue'      => 'InvoicedItem_Revenue',
                                                        'Invoice Type' => 'InvoicedItem_Invoice_Type'
                                           },
                                           
            'Customer_Sales' => new Map<String, String> {   'Id'            => 'Customer_Sales_Id',
                                                            'Customer'      => 'Customer_Sales_Customer',
                                                            'Total'         => 'Customer_Sales_Total',
                                                            'Balance Due'   => 'Customer_Sales_Balance_Due'
                                            },
                                            
            'Customer_Orders' => new Map<String, String> {  'Id'            => 'Customer_Sales_Id',
                                                            'Customer'      => 'Customer_Sales_Customer',
                                                            'Total'         => 'Customer_Sales_Total',
                                                            'Balance Due'   => 'Customer_Sales_Balance_Due',
                                                            'Deposits'      => 'Customer_Order_Deposits',
                                                            'Invoiced'      => 'Customer_Order_Payments',
                                                            'Status'        => 'Customer_Order_Status',
                                                            'Deal Total'    => 'Customer_Order_Deal_Total',
                                                            'Notes'         => 'Customer_Order_Notes',
                                                            'Account Type' => 'Customer_AccountType',
                                                            'Salesperson'	=> 'Customer_Order_Salesperson'
                                                },
                                                
            'Customer_Invoices' => new Map<String, String> {'Id'            => 'Customer_Sales_Id',
                                                            'Customer'      => 'Customer_Sales_Customer',
                                                            'Total'         => 'Customer_Sales_Total',
                                                            'Balance Due'   => 'Customer_Sales_Balance_Due',
                                                            'Deposits'      => 'Customer_Order_Deposits',
                                                            'Payments'      => 'Customer_Order_Payments',
                                                            'Customer Order'=> 'CO_Invoice_Header_Customer_Order',
                                                            'Status'        => 'CO_Invoice_Header_Status',
                                                            'Part Total'    => 'CO_Invoice_Header_Part_Total',
                                                            'Fee Total'     => 'CO_Invoice_Header_Fee_Total',
                                                            'Labour Total'  => 'CO_Invoice_Header_Labour_Total',
                                                            'Unit Total'    => 'CO_Invoice_Header_Unit_Total',
                                                            'Sublet Total'  => 'CO_Invoice_Header_Sublet_Total',
                                                            'SalesTax Total'=> 'CO_Invoice_Header_SalesTax_Total',
                                                            'Commission'    => 'CO_Invoice_Header_Commission',
                                                            'Salesperson'   => 'CO_Invoice_Header_Salesperson',
                                                            'Account Type' => 'Customer_AccountType',
                                                            'Invoice Date' => 'COInvoice_InvoiceDate',
                                                            'Lien Payout' => 'CO_Invoice_Header_LienPayout_Total',
                                                            'AR Balance' => 'CO_Invoice_Header_AR_Balance'                                                              
                                                    },
                                                    
            'Customer_Payments' => new Map<String, String> {'Id'            => 'Customer_Sales_Id',
                                                            'Customer'      => 'Customer_Sales_Customer',
                                                            'Total'         => 'Customer_Sales_Total',
                                                            'Customer Order'=> 'CO_Payment_Customer_Order',
                                                            'Payment Method'=> 'CO_Payment_Payment_Method',
                                                            'Account Type' => 'Customer_AccountType',
                                                            'Cash Drawer'	=> 'CO_Payment_Cash_Drawer'
                                                    },
            
                                                    
            'Vendor_Ordering' => new Map<String, String>{   'Id'            => 'Vendor_Ordering_Id',
                                                            'Vendor'        => 'Vendor_Ordering_Vendor',
                                                            'Total'         => 'Vendor_Ordering_Total'
                                                    },
                                                    
            'Vendor_Orders' => new Map<String, String>{     'Id'            => 'Vendor_Ordering_Id',
                                                            'Vendor'        => 'Vendor_Ordering_Vendor',
                                                            'Total'         => 'Vendor_Ordering_Total',
                                                            'Purchase Order'=> 'Vendor_Order_Purchase_Order',
                                                            'Total Recieved'=> 'Vendor_Order_Total_Recieved' ,
                                                            'Status'        => 'Vendor_Order_Status',
                                                            'Account Type'  =>  'Vendor_AccountType'
                                                    },
                                                    
            'Vendor_Receivings' => new Map<String, String>{ 'Id'            => 'Vendor_Ordering_Id',
                                                            'Vendor'        => 'Vendor_Ordering_Vendor',
                                                            'Total'         => 'Vendor_Ordering_Total',
                                                            'Status'        => 'Vendor_Invoicing_Header_Status',
                                                            'Account Type'  => 'Vendor_AccountType'
                                                    },
                                                    
            'Vendor_Invoices' => new Map<String, String>{   'Id'            => 'Vendor_Ordering_Id',
                                                            'Vendor'        => 'Vendor_Ordering_Vendor',
                                                            'Total'         => 'Vendor_Ordering_Total',
                                                            'Status'        => 'Vendor_Invoicing_Header_Status',
                                                            'Account Type'  => 'Vendor_AccountType'
                                                    },                      
            'Vendor_Returns' => new Map<String, String>{    'Credits Pending'   => 'Vendor_Return_Credits_Pending',
                                                            'Status'            => 'Vendor_Invoicing_Header_Status',
                                                            'Total'             => 'Vendor_Ordering_Total',
                                                            'Vendor'            => 'Vendor_Ordering_Vendor',
                                                            'RMA#'               => 'Vendor_Return_RMA',
                                                            'Tracking#'          => 'Vendor_Return_Tracking'
                                                    },
            'Category__c' => new Map<String, String>{       'Id'            => 'Category_Id',
                                                            'Status'        => 'Category_Status'
                                                    },
                                                    
            'Price_Level__c' => new Map<String, String>{        'Id'        => 'Price_Level_Id',
                                                            'Status'        => 'Price_Level_Status'
                                                    },
                                                    
            'Sales_Tax__c' => new Map<String, String>{      'Id'            => 'Sales_Tax_Id',
                                                            'Status'        => 'Sales_Tax_Status'
                                                },
            'Parts_Needed' => new Map<String, String>{'Part Type'     =>  'Part_Type'},
                                            
            'Sublets' => new Map<String, String> { 'Item'              => 'Product_Item',
                                                    'Description'       => 'Product_Description',
                                                    'Category'          => 'Product_Category' ,
                                                    'Price'             => 'Product_Price',
                                                    'Product Type'      => 'Product_Type',
                                                    'Account Type'      => 'Vendor_AccountType'
                                                },
                                                
            'Invoiced_Items' => new Map<String, String> { 'Item'             => 'InvoicedItem_Item',
                                                        'Customer'          => 'InvoicedItem_Customer',
                                                        'InvoiceDate'       => 'InvoicedItem_InvoiceDate' ,
                                                        'Category'          => 'InvoicedItem_Category',
                                                        'Invoiced By'       => 'InvoicedItem_InvoicedBy',
                                                        'Vendor'            => 'InvoicedItem_Vendor',
                                                        'Quantity'          => 'InvoicedItem_Quantity',
                                                        'Revenue'           => 'InvoicedItem_Revenue',
                                                        'Part Type'         => 'Part_Type'
                                                },
            'Tax_Detail' => new Map<String, String>{'Account Type'		=> 'Customer_AccountType'},
            
            'Unit_Deals' => new Map<String, String>{'Delivery'          		=> 'Unit_Deals_Delivery',
            										'Units'						=> 'Unit_Deals_Units',
            										'Trade Ins'					=> 'Unit_Deals_Trade_Ins',
            										'Lien Payout'				=> 'Unit_Deals_Lien_payout',
            										'Parts And Labour'			=> 'Unit_Deals_Parts_And_Labour',
            										'Deal Products'				=> 'Unit_Deals_Other_Products',
            										'Fees'						=> 'Unit_Deals_Fees',
            										'Stamp Duty'				=> 'Unit_Deals_Stamp_Duty',
            										'Financing Products'		=> 'Unit_Deals_Financing_Products',
            										'Sales Tax'					=> 'Unit_Deals_Sales_Tax',
            										'Order Number'				=> 'Unit_Deals_Order_Number',
            										'Customer'					=> 'Unit_Deals_Customer',
            										'Deal Type'					=> 'Unit_Deals_Deal_Type',
            										'Total'						=> 'Unit_Deals_Total',
                                                    'Salesperson'				=> 'Unit_Deals_Salesperson',
                                                    'Option Clearing'			=> 'Unit_Deals_Option_Clearing',
                                                    'Stocked Trades'			=> 'Unit_Deals_Stocked_Trades'
            										}, 
         'Deal_Units' => new Map<String, String>{	'Order Number' => 'Deal_Units_Order_Number',
													'Stock Number' => 'Deal_Units_Stock_Number',
            										'Status' => 'Deal_Units_Status',
													'Date Sold' => 'Deal_Units_Date_Sold',
													'Invoice Number' => 'Deal_Units_Invoice_Number',
            										'Make' => 'Deal_Units_Make',
													'Model' => 'Deal_Units_Model',
													'Submodel' => 'Deal_Units_Submodel',
													'Year' => 'Deal_Units_Year',
													'Customer' => 'Deal_Units_Deal_Customer',
													'Deal Type' => 'Deal_Units_Deal_Type',
													'Salesperson'		=> 'Deal_Units_Salesperson',
                                                    'Total Price' => 'Deal_Units_Total_Price',
													'Total Cost' => 'Deal_Units_Total_Cost',
													'Total Profit' => 'Deal_Units_Total_Profit',
													'Total Unit Price' => 'Deal_Units_Total_Unit_Price',
													'Total Unit Cost' => 'Deal_Units_Total_Unit_Cost',
													'Total Unit Profit' => 'Deal_Units_Total_Unit_Profit',
													'Total Unit Option Price' => 'Deal_Units_Total_Unit_Option_Price',
													'Total Unit Option Cost' => 'Deal_Units_Total_Unit_Option_Cost',
													'Total Unit Option Profit' => 'Deal_Units_Total_Unit_Option_Profit',
													'Base Price' => 'Deal_Units_Base_Price',
													'Factory Options' => 'Deal_Units_Factory_Options',
													'Dealer Installed' => 'Deal_Units_Dealer_Installed',
													'Part Options' => 'Deal_Units_Part_Options',
													'Labor Options' => 'Deal_Units_Labor_Options',
													'Sublet Options' => 'Deal_Units_Sublet_Options',
													'Fee Options' => 'Deal_Units_Fee_Options',
													'Warranty Options' => 'Deal_Units_Warranty_Options',
													'Other Products' => 'Deal_Units_Other_Products',
													'Stamp Duty' => 'Deal_Units_Stamp_Duty',
													'VIN' => 'Deal_Units_VIN',
													'New Unit' => 'Deal_Units_New_Unit',
													'Category' => 'Deal_Units_Category',
													'Stocked In' => 'Deal_Units_Stocked_In',
													'Age' => 'Deal_Units_Age',
                                                    'Confirmed Sale' => 'Deal_Units_Confirmed_Sale',
                                                    'Unit Type' => 'Deal_Units_Unit_Type',
													'Tags' => 'AssignedTags',
													'Mileage' => 'Deal_Units_Mileage',
													'Mileage Type' => 'Deal_Units_Mileage_Type',
													'Ext Color' => 'Deal_Units_Ext_Color',
													'Int Color' => 'Deal_Units_Int_Color',
													'Compliance Date' => 'Deal_Units_Compliance_Date',
                                                    'Year of 1st Rego' => 'Deal_Units_Year_Of_1st_Rego',
                                                    'Registration Serial#' => 'Deal_Units_Registration_Serial',
                                                    'Manufactured Date' => 'Deal_Units_Manufactured_Date',
                                                    'First Name'    => 'Deal_Units_First_Name',
                                                    'Last Name'    => 'Deal_Units_Last_Name',
                                                    'Address'    => 'Deal_Units_Address',
                                                    'City'    => 'Deal_Units_City',
                                                    'State/Prov'    => 'Deal_Units_State',
                                                    'Postal'    => 'Deal_Units_Postal',
                                                    'Phone'    => 'Deal_Units_Phone',
                                                    'Mobile'    => 'Deal_Units_Mobile',
                                                    'Email'    => 'Deal_Units_Email',
                                                    'Other Email'    => 'Deal_Units_Other_Email'
            										},
           'Parts_Order'  => new Map<String, String>{'Order Number' => 'Parts_Order_Order_Number',
           											 'Customer'	=> 'Parts_Order_Customer',
           											 'Sale Type' => 'Parts_Order_Sale_Type',
           											 'Total' => 'Parts_Order_Total',
           											 'Status' => 'Parts_Order_Status',
           											 'SO Status' => 'Parts_Order_SO_Status',
           											 'Deposits' => 'Parts_Order_Deposits',
           											 'Invoiced' => 'Parts_Order_Invoiced',
           											 'Modified' => 'Parts_Order_Modified',
           											 'Parts' => 'Parts_Order_Parts',
           											 'Fees' => 'Parts_Order_Fees',
           											 'Sales Tax' => 'Parts_Order_Sales_Tax',
                                                     'Salesperson' => 'Parts_Order_Salesperson'
            										},
           'Special_Order'  => new Map<String, String>{'Order Number' => 'Parts_Order_Order_Number',
           											 'Customer'	=> 'Parts_Order_Customer',
           											 'Sale Type' => 'Special_Order_Sale_Type',
           											 'Notes' => 'Customer_Order_Notes'
            										},
           'Part_FIFO'  => new Map<String, String>{'Sales Qty' => 'Part_FIFO_Sales_Qty',
           											 'Purchase Qty'	=> 'Part_FIFO_Purchase_Qty',
           											 'Adjusted Qty' => 'Part_FIFO_Adjusted_Qty',
                                                     'Part Number' => 'Part_FIFO_Part_Number'
        										},
            'VO_Items'  => new Map<String, String>{'Vendor' => 'VO_Items_Vendor',
                                                    'Item Description'	=> 'VO_Items_Item_Description',
                                                    'VO Number' => 'VO_Items_VO_Number',
                                                    'Quantity' => 'VO_Items_Quantity',
                                                    'Total Cost'	=> 'VO_Items_Total_Cost',
                                                    'Ordered' => 'VO_Items_Ordered',
                                                    'Expected' => 'VO_Items_Expected',
                                                    'Needed For'	=> 'VO_Items_Needed_For',
                                                    'Customer' => 'VO_Items_Customer'
                                                },
            'Sublet_Items'  => new Map<String, String>{'Order Number' => 'Sublet_Items_Order_Number',
                                                    'Customer'	=> 'Sublet_Items_Customer',
                                                    'Job Status' => 'Sublet_Items_Job_Status',
                                                    'Job Type' => 'Sublet_Items_Job_Type',
                                                    'Total Price'	=> 'Sublet_Items_Total_Price',
                                                    'Total Cost' => 'Sublet_Items_Total_Cost',
                                                    'Expected' => 'Sublet_Items_Expected',
                                                    'Vendor'	=> 'Sublet_Items_Vendor',
                                                    'VO Number' => 'Sublet_Items_VO_Number',
                                                    'VR Number' => 'Sublet_Items_VR_Number',
                                                    'VI Number' => 'Sublet_Items_VI_Number'
                                                },
            'Claim_Jobs'  => new Map<String, String>{'Provider' => 'Claim_Jobs_Provider',
                                                    'Claim Status'	=> 'Claim_Jobs_Claim_Status',
                                                    'Variance' => 'Claim_Jobs_Variance'
                                                },
            'Unit_Register'  => new Map<String, String>{'Stocked In' => 'Unit_Register_Stocked_In',
                                                    'Make'	=> 'Unit_Register_Make',
                                                    'Model' => 'Unit_Register_Model',
                                                    'Submodel' => 'Unit_Register_Submodel',
                                                    'Year' => 'Unit_Register_Year',
                                                    'New Unit' => 'Unit_Register_New_Unit',
                                                    'How Acquired' => 'Unit_Register_How_Acquired'
                                                }		 	  										
            										
            										           
    };
    
    
    // Map of object name to owner field API Name
    public static Map<String, List<String>> objectToCommonNumericFieldAPIName = 
                        new Map<String, List<String>>{'Parts'               =>  new List<String>{'Retail_Price__c', 'Last_Cost__c'},
                                                        'Kits'              =>  new List<String>{'Fixed_Price__c'},
                                                        'Labor Codes'       =>  new List<String>{'Rate__c'},
                                                        'Fees'              =>  new List<String>{'Price__c'},
                                                        'Sublets'           =>  new List<String>{'Price__c'},
                                                        'Vendor Product'    => new List<String>{'Price__c'},
                                                        'Sales Taxes'       =>  new List<String>(),
                                                        'Price Levels'      =>  new List<String>(),
                                                        'Item Categories'   =>  new List<String>(),
                                                        'Customers'         =>  new List<String>(),
                                                        'Vendors'           =>  new List<String>(),
                                                        'Customer Orders'   =>  new List<String>{'Order_Total__c', 'Total_Balance_Due__c', 'Invoiced_Amount__c', 'Total_Deposit_And_Payment__c', 'Uninvoiced_Amount__c'},
                                                        'Customer Invoices' =>  new List<String>{'Total_Payment__c', 'CO_Header__r.Total_Balance_Due__c'},
                                                        'Service Jobs'  =>  new List<String>{'Total_With_Tax__c'},
                                                        'Customer Payments' =>  new List<String>{'Amount__c'},
                                                        'Customer Deposits' =>  new List<String>{'Amount__c'},
                                                        'AR Payments'		=> 	new List<String>{'Total_Amount__c'}, 
                                                        'Vendor Orders'     =>  new List<String>{'Total__c'},
                                                        'Vendor Returns' =>  new List<String>{'SubTotal_Reporting__c', 'Tax_Reporting__c', 'Total__c', 'Credits_Pending_Reporting__c'},
                                                        'Vendor Credit' =>  new List<String>{'Total_With_Tax__c'},
                                                        'Vendor Receivings' =>  new List<String>{'Receiving_Total__c'},
                                                        'Vendor Invoices'   =>  new List<String>(),
                                                        'People'            =>  new List<String>(),
                                                        'Inventory Unit'    =>  new List<String>{'Total_Price__c', 'Total_Cost__c', 'Total_Base_Unit_Price__c', 'Total_Factory_Options_Price__c', 'Total_Dealer_Options_Price__c', 'Total_Base_Units_Cost__c', 'Total_Factory_Options_Cost__c', 'Total_Dealer_Options_Cost__c'},
                                                        'Tax Detail Customer Invoices'  =>  new List<String>{},
                                                        'Tax Detail Vendor Invoices'    =>  new List<String>{},
                                                        'Unit Deals' =>  new List<String>{'CO_Header__r.Deal_Total__c'},
                                                        'Deal Units' =>  new List<String>{'Total_Price__c'},
                                                        'Parts Order'   =>  new List<String>(),
                                                        'Customer Invoice Details COLI' => new List<String>{'Qty__c', 'Sub_Total_With_Tax__c', 'Total_Cost__c', 'Total_Profit__c', 'Pre_Tax_Part_Sales__c', '', '', 'Pre_Tax_Fee_Sales__c', '', '', '', '', '', '', '', '', '', '', '', '', ''},
                                                        'Customer Invoice Details SOLI' => new List<String>{'Qty_Needed__c', 'Total_Price_With_Tax__c', 'Total_Cost__c', 'Total_Profit__c', 'Pre_Tax_Part_Sales__c', 'Pre_Tax_Labor_Sales__c', 'Pre_Tax_Sublet_Sales__c', 'Pre_Tax_Fee_Sales__c', 'Pre_Tax_Supplies_Sales__c', '', '', '', '', '', '', '', '', '', '', '', ''},
                                                        'Customer Invoice Details Option and Fee' => new List<String>{'Qty__c', 'Total_Price_With_Tax__c', 'Total_Cost__c', 'Total_Profit__c', '', '', '', '', '', '', '', '', 'Pre_Tax_Option_Part_Sales__c', 'Pre_Tax_Option_Labor_Sales__c', 'Pre_Tax_Option_Sublet_Sales__c', 'Pre_Tax_Option_Fee_Sales__c', 'Pre_Tax_Option_Warranty_Sales__c', 'Pre_Tax_Option_Other_Product_Sales__c', '', '', ''},
                                                        'Customer Invoice Details Deal UPC' => new List<String>{'Qty__c', 'Total_Price_With_Tax__c', 'Total_Cost__c', 'Total_Profit__c', '', '', '', '', '', 'Pre_Tax_Base_Sales__c', 'Pre_Tax_Factory_Sales__c', 'Pre_Tax_Dealer_Sales__c', '', '', '', '', '', '', '', '', ''},
                                                        'Customer Invoice Details Trade in' => new List<String>{'Qty__c', 'Total_Price_With_Tax__c', 'Total_Cost__c', 'Total_Profit__c', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'Total_Price__c', '', ''},
                                                        'Customer Invoice Details FI Product' => new List<String>{'Id', 'Price_When_Tax_Included__c', 'Total_Cost__c', 'Total_Profit__c', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'Price__c'},
                                                        'Customer Invoice Details Deal Finance' => new List<String>{'', 'Total_Commission__c', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''},
                                                        'Customer Invoice Details Deal' => new List<String>{'', '', 'Deal_Commission__c', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''},
                                                        'Customer Invoice Details Lien' => new List<String>{'', 'Lien_Payout__c', 'Lien_Payout__c_1', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'Lien_Payout__c_2', ''}
                                                    };
    
    // Map of object name to owner field API Name
    public static Map<String, List<String>> objectToCommonNumericFieldLabelName = 
                        new Map<String, List<String>>{'Parts'               =>  new List<String>{'Price', 'Cost'},
                                                        'Kits'              =>  new List<String>{'Price'},
                                                        'Labor Codes'       =>  new List<String>{'Price'},
                                                        'Fees'              =>  new List<String>{'Price'},
                                                        'Sublets'           =>  new List<String>{'Price'},
                                                        'Vendor Product'    =>  new List<String>{'Price'},
                                                        'Sales Taxes'       =>  new List<String>(),
                                                        'Price Levels'      =>  new List<String>(),
                                                        'Item Categories'   =>  new List<String>(),
                                                        'Customers'         =>  new List<String>(),
                                                        'Vendors'           =>  new List<String>(),
                                                        'Customer Orders'   =>  new List<String>{'Total', 'Balance_Due', 'Invoiced', 'Deposits', 'Uninvoiced'},
                                                        'Service Jobs'  =>  new List<String>{'Total'},
                                                        'Customer Invoices' =>  new List<String>{'Total', 'Balance_Due'},
                                                        'Customer Payments' =>  new List<String>{'Total'},
                                                        'Customer Deposits' =>  new List<String>{'Total'},
                                                        'AR Payments'		=> 	new List<String>{'Total'},
                                                        'Vendor Orders'     =>  new List<String>{'Total'},
                                                        'Vendor Returns' =>  new List<String>{'Sub_Total', 'Taxes', 'Total', 'Credits_Pending'},
                                                        'Vendor Credit' =>  new List<String>{'Total'},
                                                        'Vendor Receivings' =>  new List<String>{'Total'},
                                                        'Vendor Invoices'   =>  new List<String>(),
                                                        'People'            =>  new List<String>(),
                                                        //Added by Nidhi - #1152 - 19-10-2016
                                                        'Inventory Unit'    =>  new List<String>{'Price', 'Cost', 'Base_Unit_Price', 'Factory_Options', 'Dealer_Options', 'Base_Unit_Cost', 'Factory_Option_Cost', 'Dealer_Option_Cost'},
                                                        'Tax Detail Customer Invoices'  =>  new List<String>{},
                                                        'Tax Detail Vendor Invoices'    =>  new List<String>{},
                                                        'Unit Deals' =>  new List<String>{'Total'},
                                                        'Deal Units'  =>  new List<String>{'Total_Price'},
                                                        'Parts Order'   =>  new List<String>(),
                                                        'Customer Invoice Details COLI' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'},
                                                        'Customer Invoice Details SOLI' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'},
                                                        'Customer Invoice Details Option and Fee' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'},
                                                        'Customer Invoice Details Deal UPC' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'},
                                                        'Customer Invoice Details Trade in' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'},
                                                        'Customer Invoice Details FI Product' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'},
                                                        'Customer Invoice Details Deal Finance' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'},
                                                        'Customer Invoice Details Deal' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'},
                                                        'Customer Invoice Details Lien' => new List<String>{'QTY', 'Total_Price', 'Total_Cost', 'Total_Profit', 'Part_Sales', 'Labor_Sales', 'Sublet_Sales', 'Fee_Sales', 'Supplies_Sales', 'Unit_Base_Sales', 'Unit_Factory_Sales', 'Unit_Dealer_Sales', 'Option_Part_Sales', 'Option_Labor_Sales', 'Option_Sublet_Sales', 'Option_Fee_Sales', 'Option_Warranty_Sales', 'Option_Product_Sales', 'Trade_ins', 'Lien_Payouts', 'Finance_Product_Sales'}
                                                    };
                                                    
    // Map of object name to owner field API Name
    public static Map<String, List<String>> objectToCommonNumericFieldTypeMap = 
                        new Map<String, List<String>>{  'Parts'             =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Kits'              =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Labor Codes'       =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Fees'              =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Sublets'           =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Vendor Product'    =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Sales Taxes'       =>  new List<String>(),
                                                        'Price Levels'      =>  new List<String>(),
                                                        'Item Categories'   =>  new List<String>(),
                                                        'Customers'         =>  new List<String>(),
                                                        'Vendors'           =>  new List<String>(),
                                                        'Customer Orders'   =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Service Jobs'      =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Customer Invoices' =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Customer Payments' =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Customer Deposits' =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'AR Payments'		=> 	new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Vendor Orders'     =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Vendor Returns'     =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Vendor Credit'     =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Vendor Receivings' =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Vendor Invoices'   =>  new List<String>(),
                                                        //Added by Nidhi - #1152 - 19-10-2016
                                                        'Inventory Unit'    => new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2, HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Tax Detail Customer Invoices'  =>  new List<String>{},
                                                        'Tax Detail Vendor Invoices'    =>  new List<String>{},
                                                        'Unit Deals' =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Deal Units' =>  new List<String>{HomeSearchReportUtil.NUMERIC_TYPE_2},
                                                        'Parts Order'   =>  new List<String>()
                                                        
                                                    };

    //START : Added by nidhi - 10-11-2016
    //Map of object name to Map of field name to field value                                                
    public static Map<String, Map<String, String>> objectNameToMapOfFieldNameToFieldValueMap = 
                        new Map<String, Map<String, String>>{'Customer_Owned_Unit__c'   =>  new Map<String, String>{'Unit_Type__c' => '\'Stock\''},
                                                            'CO_Invoice_Header__c'      =>  new Map<String, String>{'Status__c' => '\'Closed\''} 
                                                    };          
                                                    
                                                    
    public static Map<String, Map<String, String>> groupFieldNameToObjAPINameToFieldAPINameMap =                                                                                                                                    
                        new Map<String, Map<String, String>> {'Products_Price' => new Map<String, String>{'Part__c' => 'Retail_Price__c',
                                                                                                        'Labour_Code__c' => 'Rate__c',
                                                                                                        'Fee__c' => 'Price__c',
                                                                                                        'Product__c' => 'Price__c',
                                                                                                        'Kit_Header__c' => 'Fixed_Price__c',
                                                                                                        'Customer_Owned_Unit__c' => 'Total_Price__c'},
                                                                                                        
                                                                'Products_Description' => new Map<String, String>{'Part__c' => 'Part_Number__c',
                                                                                                        'Labour_Code__c' => 'Description__c',
                                                                                                        'Fee__c' => 'Fee_Unique_Name__c',
                                                                                                        'Product__c' => 'Description__c',
                                                                                                        'Kit_Header__c' => 'Kit_Unique_Name__c'},
                                                                                                        
                                                                'Products_Code' => new Map<String, String>{'Part__c' => 'Part_Number__c',
                                                                                                        'Labour_Code__c' => 'Description__c',
                                                                                                        'Fee__c' => 'Fee_Unique_Name__c',
                                                                                                        'Product__c' => 'Description__c',
                                                                                                        'Kit_Header__c' => 'Kit_Unique_Name__c',
                                                                                                        'Customer_Owned_Unit__c' => 'Stock_Id__c'},                                     
                                                                
                                                                'Products_Cost' => new Map<String, String>{'Part__c' => 'Last_Cost__c',
                                                                                                        'Product__c' => 'Cost__c',
                                                                                                        'Customer_Owned_Unit__c' => 'Total_Cost__c'},
                                                                                                        
                                                                                                        
                                                                'Customer_Sales_Id_Number' => new Map<String, String>{'CO_Header__c' => 'Name',
                                                                                                        'CO_Invoice_Header__c' => 'Invoice_Number__c',
                                                                                                        'CO_Invoice_Payment__c' => 'Name',
                                                                                                        'CO_Deposit__c' => 'Name',
                                                                                                        'Payment_on_Account__c' => 'Name',
                                                                                                        'Service_Order_Header__c' => 'CO_Header__r.Name'},
                                                                                                        
                                                                'Customer_Sales_Name' => new Map<String, String>{'CO_Header__c' => 'Customer_Name__c',
                                                                                                        'CO_Invoice_Header__c' => 'CO_Header__r.Customer_Name__c',
                                                                                                        'CO_Invoice_Payment__c' => 'CO_Invoice_Header__r.CO_Header__r.Customer_Name__c',
                                                                                                        'CO_Deposit__c' => 'CO_Header__r.Customer_Name__c',
                                                                                                        'Payment_on_Account__c' => 'Customer__r.Name',
                                                                                                        'Service_Order_Header__c' => 'CO_Header__r.Customer_Name__c'},
                                                                                                        
                                                                'Customer_Sales_Status' => new Map<String, String>{'CO_Header__c' => 'Status__c',
                                                                                                        'CO_Invoice_Header__c' => 'Status__c',
                                                                                                        'Service_Order_Header__c' => 'SO_Status__c'},
                                                                                                        
                                                                'Customer_Sales_Balance_Due' => new Map<String, String>{'CO_Header__c' => 'Total_Balance_Due__c',
                                                                                                        'CO_Invoice_Header__c' => 'CO_Header__r.Total_Balance_Due__c'},
                                                                                                        
                                                                                                                                                
                                                                'Customer_Sales_Total' => new Map<String, String>{'CO_Header__c' => 'Order_Total__c',
                                                                                                        'CO_Invoice_Header__c' => 'Total_Payment__c',
                                                                                                        'CO_Invoice_Payment__c' => 'Amount__c',
                                                                                                        'CO_Deposit__c' => 'Amount__c',
                                                                                                        'Payment_on_Account__c' => 'Amount_Paid__c',
                                                                                                        'Service_Order_Header__c' => 'Total__c'},
                                                                                                        
                                                                'Customer_Sales_Order_Number' => new Map<String, String>{
                                                                                                        'CO_Invoice_Header__c' => 'CO_Header__r.Name',
                                                                                                        'CO_Invoice_Payment__c' => 'CO_Invoice_Header__r.CO_Header__r.Name',
                                                                                                        'CO_Deposit__c' => 'CO_Header__r.Name'} ,
                                                                
                                                                'Customer_Payments_Customer_Name' => new Map<String, String>{
                                                                                                        'CO_Invoice_Payment__c' => 'Customer_Name__r.Name',
                                                                                                        'CO_Deposit__c' => 'Customer_Name__r.Name',
                                                                                                        'Payment_on_Account__c' => 'Customer__r.Name'} ,   
                                                                
                                                                'Customer_Payments_Order_Number' => new Map<String, String>{
                                                                                                        'CO_Invoice_Payment__c' => 'CO_Invoice_Header__r.CO_Header__r.Name',
                                                                                                        'CO_Deposit__c' => 'CO_Header__r.Name'
                                                                                                        } ,
                                                                
                                                                'Customer_Payments_Owner' => new Map<String, String>{
                                                                                                        'CO_Invoice_Payment__c' => 'CO_Invoice_Header__r.CO_Header__r.Owner__r.Name',
                                                                                                        'CO_Deposit__c' => 'CO_Header__r.Owner__r.Name', 
                                                                                                        'Payment_on_Account__c' => 'Customer__r.Owner.Name'} , 
                                                                                                        
                                                                 'Customer_Payments_Account_Type' => new Map<String, String>{
                                                                                                        'CO_Invoice_Payment__c' => 'CO_Invoice_Header__r.CO_Header__r.Account_Type__r.Name',
                                                                                                        'CO_Deposit__c' => 'CO_Header__r.Account_Type__r.Name',
                                                                                                        'Payment_on_Account__c' => 'Customer__r.Account_Type__r.Name'} ,
                                                                                                                                               
                                                                'Vendor_Ordering_ID_Number' => new Map<String, String>{
                                                                                                        'Vendor_Order_Header__c' => 'Name',
                                                                                                        'Return_VO_Header__c' => 'Name',
                                                                                                        'Return_CR_Header__c' => 'Name',
                                                                                                        'Vendor_Receiving_Header__c' => 'Receipt_Number__c',
                                                                                                        'Vendor_Invoicing_Header__c' => 'Invoice_Number__c'},
                                                                
                                                                'Vendor_Ordering_Total' => new Map<String, String>{
                                                                                                        'Vendor_Order_Header__c' => 'Total__c',
                                                                                                        'Return_VO_Header__c' => 'Total__c',
                                                                                                        'Return_CR_Header__c' => 'Total_With_Tax__c'},
                                                                                                        
                                                                
                                                                'Vendor_Ordering_Account_Type' => new Map<String, String>{
                                                                                                        'Vendor_Order_Header__c' => 'Vendor__r.Vendor_Account_Type__r.Name',
                                                                                                        'Return_VO_Header__c' => 'Vendor__r.Vendor_Account_Type__r.Name',
                                                                                                        'Return_CR_Header__c' => 'Vendor__r.Vendor_Account_Type__r.Name'}, 
                                                                                                        
                                                                'Tax_Detail_Account_Type' => new Map<String, String>{
                                                                                                        'CO_Invoice_Header__c' => 'CO_Header__r.Account_Type__r.Name',
                                                                                                        'Vendor_Invoicing_Header__c' => 'Vendor__r.Vendor_Account_Type__r.Name '},                                                                                                         
                                                                                                        
                                                                'Setting_Key' => new Map<String, String>{
                                                                                                        'Category__c' => 'Unique_Category__c',
                                                                                                        'Price_Level__c' => 'Name__c',
                                                                                                        'Sales_Tax__c' => 'Name__c'}, 
                                                                                                        
                                                                'Setting_Summary' => new Map<String, String>{
                                                                                                        'Category__c' => 'Description__c',
                                                                                                        'Price_Level__c' => 'Description__c',
                                                                                                        'Sales_Tax__c' => 'Forms_Label__c'}                                                                                                                                                                                                                                                                                                                                                                                                                                                 
                        
                                                            };          
    
    public static Map<String, String> filterLabelToPermissionNameMap = new Map<String, String> {    'Price Levels' => 'Price Levels',
                                                                                    'Sales Taxes' => 'Sales Taxes',
                                                                                    'Service Jobs' => 'Service job',
                                                                                    'Users' => 'System Settings',
                                                                                    'Vendor Invoices' => 'Vendor invoicing',
                                                                                    'Vendor Orders' => 'Vendor order',
                                                                                    'Vendor Receivings' => 'Vendor receiving',
                                                                                    'Customer Orders' => 'Merchandise,Service job,Deal',
                                                                                    'Technician Hours' => 'Manage job clocking',
                                                                                    'Payroll Hours' => 'Manage payroll clocking',
                                                                                    'Part FIFO' => 'Costs',
                                                                                    'Tax Detail' => 'Sales Taxes',
                                                                                    'Customer Invoice Details Deal Finance' => 'Deal commissions',
                                                                                    'Customer Invoice Details Deal' => 'Deal commissions'
                                                                                };
                                                                                
     public static Map<String, String> entityTypeToPermissionNameMap = new Map<String, String> {
                                                                                    'Part Inventory Valuation' => 'Part costs',
                                                                                    'Parts Needed' => 'Vendor order',
                                                                                    'Open Service Jobs' => 'Service job',
                                                                                    'Units on order' => 'Vendor order',
                                                                                    'My Vendor Orders' => 'Vendor order',
                                                                                    'All Vendor Orders' => 'Vendor order',
                                                                                    'Active Receivings' => 'Vendor receiving',
                                                                                    'Recent Vendor Invoices' => 'Vendor invoicing',
                                                                                    'Technician Hours' => 'Manage job clocking',
                                                                                    'Payroll Hours' => 'Manage payroll clocking',
                                                                                    'Part Movement' => 'Costs',
                                                                                    'Tax Detail' => 'Sales Taxes'
                                                                                };
    
    public static Map<String, String> objectAPILabelToPermissionNameMap = new Map<String, String> { 'Price_Level__c' => 'Price Levels',
                                                                                    'Sales_Tax__c' => 'Sales Taxes',
                                                                                    'Service_Order_Header__c' => 'Service job',
                                                                                    'User' => 'System Settings',
                                                                                    'Vendor_Invoicing_Header__c' => 'Vendor invoicing',
                                                                                    'Vendor_Order_Header__c' => 'Vendor order',
                                                                                    'Vendor_Receiving_Header__c' => 'Vendor receiving',
                                                                                    'CO_Header__c' => 'Merchandise,Service job,Deal',
                                                                                    'Payment_on_Account__c' => 'Payment on account'
                                                                                };
    
    public static Map<String, Set<String>> entityTypeToCostColumnsMap = new Map<String, Set<String>> {  'Invoice Summary' => new Set<String>{'Invoice Profit', 'Deal Profit', 'Commission'},
                                                                                    'Recent Customer Invoices' => new Set<String>{'Invoice Profit', 'Deal Profit', 'Commission'},
                                                                                    'Stock Units' => new Set<String>{'Base Unit Cost', 'Factory Option Cost', 'Dealer Option Cost', 'Total Cost'},
                                                                                    'Recent Parts' => new Set<String>{'Cost', 'Average Cost', 'Package Cost', 'Oversold Cost', 'Total Cost'},
                                                                                    'Parts Needed' => new Set<String>{'Total Cost'},
                                                                                    'Sublets' => new Set<String>{'Cost'},
                                                                                    'Part Inventory Valuation' => new Set<String>{'Cost', 'Average Cost', 'Package Cost', 'Oversold Cost', 'In Stock Cost', 'Inventory Valuation'},
                                                                                    'Product History Detail' => new Set<String>{'Profit', 'Average Profit', 'Total Profit'},
                                                                                    'Product History Summary' => new Set<String>{'Profit', 'Average Profit', 'Total Profit'},
                                                                                    'Stock Unit Valuation' => new Set<String>{'Base Unit Cost', 'Factory Option Cost', 'Dealer Option Cost', 'Deal Options WIP', 'Total Cost'},
                                                                                    'Open Service Jobs' => new Set<String>{'WIP Part Cost', 'WIP Labor Cost'},
                                                                                    'Technician Hours' => new Set<String>{'Cost'},
                                                                                    'Technician Performance' => new Set<String>{'Invoiced Cost', 'Uninvoiced Cost'},
                                                                                    'Invoice Detail' => new Set<String>{'Total Cost', 'Total Profit', 'Total Gross Pct'},
                                                                                    'Active Unit Deals' => new Set<String>{'Commission'}
                                                                                 };
    
    public static Map<String, Map<String, String>> entityTypeToModifyCostColumnsMap = new Map<String, Map<String, String>> {'Invoice Summary' => new Map<String, String>{'Commission' => 'CO_Invoice_Header_Commission'},
                                                                                                        'Recent Customer Invoices' => new Map<String, String>{'Commission' => 'CO_Invoice_Header_Commission'}
                                                                                 };
    
   public static Map<String, Set<String>> entityTypeToPartCostColumnsMap = new Map<String, Set<String>> {
                                                                                    'Parts Needed' => new Set<String>{'Total Cost'},
                                                                                    'Part Inventory Valuation' => new Set<String>{'Cost', 'Average Cost', 'Package Cost', 'Oversold Cost', 'In Stock Cost', 'Inventory Valuation'}
                                                                                 };
                                                                                 
   public static Map<String, Set<String>> entityTypeToUnitCostColumnsMap = new Map<String, Set<String>> {
                                                                                    'Stock Units' => new Set<String>{'Base Unit Cost', 'Factory Option Cost', 'Dealer Option Cost', 'Total Cost'},
                                                                                    'Deal Units' => new Set<String>{'Total Cost','Total Profit','Total Unit Cost','Total Unit Profit','Total Unit Option Cost','Total Unit Option Profit'}
                                                                                 };
                                                                       
    public static Map<String, Set<String>> entityTypeToCommissionColumnsMap = new Map<String, Set<String>> {
                                                                                    'Customer Invoices' => new Set<String>{'Finance Commission', 'Sales Commission'},
                                                                                    'Unit Deals' => new Set<String>{'Finance Commission', 'Sales Commission'},
                                                                                    'Customer Invoice Details' => new Set<String>{'Finance Commission', 'Sales Commission'}
                                                                                };

    public static Map<String, String> objectNameToPermissionNameMap = new Map<String, String> { 'Price Levels' => 'Price Levels',
                                                                                    'Sales Taxes' => 'Sales Taxes',
                                                                                    'Customer Orders' => 'Merchandise,Service job,Deal',
                                                                                    'Users' => 'System Settings',
                                                                                    'Vendor Invoices' => 'Vendor invoicing',
                                                                                    'Vendor Orders' => 'Vendor order',
                                                                                    'Vendor Receivings' => 'Vendor receiving'
                                                                                };
    
    public static Map<String, Set<String>> filterNameToHiddenFieldMap = new Map<String, Set<String>> {'Invoice Summary' => new Set<String>{'Stamp Duty Total'},
                                                                                    'Recent Customer Invoices' => new Set<String>{'Stamp Duty Total'}
                                                                                };
    
    public static Map<String, List<String>> objectNameToNumericFieldApiNameMap = new Map<String, List<String>> {
                                                                                'Vendor Return' => new List<String>{'Total__c'},
                                                                                'Vendor Credit' => new List<String>{'Total_With_Tax__c'},
                                                                                'Invoiced Item' => new List<String>{'Qty__c'},
                                                                                'SOLI' => new List<String>{'Qty_Needed__c', 'Revenue__c', 'Per_Item_Profit__c'},
                                                                                'SOLI Without Permission' => new List<String>{'Qty_Needed__c', 'Revenue__c'},
                                                                                'Option and Fee' => new List<String>{'Qty__c', 'Revenue__c', 'Per_Item_Profit__c'}
                                                                                }; 
                                                                                
    // Used when there are sorting on multiple objects and Field API names are different - Added by TK
    public static Map<String, Map<String, String>> objectNameToCommonApiToAPINameMap = 
                new Map<String, Map<String, String>> {
                    'Service_Order_Line_Item__c' => new Map<String, String>{'CO_Header__r.Customer_Name__c' => 'Service_Order_Header__r.CO_Header__r.Customer_Name__c',
                                                                            'Invoice_Number__r.Invoice_Number__c' => 'Service_Order_Header__r.Invoice_Number__r.Invoice_Number__c',
                                                                            'Price__c' => 'Kit_Price__c',
                                                                            'Qty__c' => 'Qty_Needed__c'},
                    'Option_Fee__c'              => new Map<String, String>{'CO_Header__r.Customer_Name__c' => 'Deal__r.CO_Header__r.Customer_Name__c',
                                                                            'Invoice_Number__r.Invoice_Number__c' => 'Deal__r.Invoice_Number__r.Invoice_Number__c'}
                };  
    
    public static Map<String, Map<String, String>> searchNameToChildQueryObjNameToFieldToFilterNameMap = new Map<String, Map<String, String>> {
                                                                                'Technician Performance' => new Map<String, String>{'Hours_Logged__r'=> 'Start_Date__c',
                                                                                                                                    'Payroll_Times__r'=> 'Start_Date__c'},
                                                                                 'Part FIFO' => new Map<String,String>{'Part_FIFO_Bucket_Activity_Line_Items__r'=> 'CreatedDate'}
                                                                                };
    
    // If there is any report which requires child query then include its name here for report scheduling
    public static Set<String> reportNameSetToQueryChildObj = new Set<String> {'Technician Performance'};
    
    public static Set<String> ObjectToExcludeFromRecentSearchSet = new Set<String> {'Technician Performance','Technician Hours','Payroll Hours'};
                                                                                
    public static Map<String, Set<String>> searchNameToFieldToFilterNameMap = new Map<String, Set<String>> {
                                                                                'Technician Performance' => new Set<String>{'Start_Date__c'},
                                                                                'Inventory Unit' => new Set<String>{'((Adjustment_Date__c'}
                                                                                };                                                                            
    public static Map<String, Map<String, String>> childObjNameToFilterFieldNameToAPIName = new Map<String, Map<String, String>> {
                                                                                'Hours_Logged__r' => new Map<String, String>{'Start_Date__c'=> 'Start_Date_Time__c'}
                                                                                };  
    public static Set<String> APINamesUsedInORTypeQueryFilters = new Set<String>{ 
                                                                                'Unit_Type__c',
                                                                                'Consignment__c',
                                                                                'Status__c',
                                                                                'Date_Stocked_Out__c',
                                                                                'Adjustment_Date__c',
                                                                                '(Type__c',
                                                                                'CreatedDate',
                                                                                'Salesperson_Names__c'
                                                                                };    
    // Not include this filter in summary report child query,
    public static Map<String, Set<String>> searchObjNameToFieldFilterNameMap = new Map<String, Set<String>> {
        'Inventory Unit' => new Set<String>{'((Date_Stocked_Out__c'}
    };   

    public static Set<String> objectWithNoPaginationSet = 
            new Set<String>{'Technician__c', 'Part_FIFO_Bucket__c', 'Part_FIFO_Bucket_Activity_Line_Item__c', 'CO_Line_Item__c', 'Service_Order_Line_Item__c', 'Option_Fee__c'};
                                                                                    
    public static String implementNameSpace(String objName){
        String objNameWithNameSpace;
        if(objName.indexOf(Constants.NAMESPACE) == -1 && objName.indexOf('__c') != -1) {
            objName = Constants.NAMESPACE + objName;
        }
        return objName;
    }    
    
    public static Map<String, Map<String, String>> saleTypeToSearchTypeToWhereClauseStrMap = new Map<String, Map<String, String>>{
    														'Parts - Customer'	=>	new Map<String, String> {
    																						'Customer Invoice Details COLI'	=>	'Is_In_Merch_Section__c = true'
    																					},
    														'Parts - Deal'	=>	new Map<String, String> {
    																						'Customer Invoice Details COLI'	=>	'Deal__c != null'
    																					},
    														'Service - Customer'	=>	new Map<String, String> {
    																						'Customer Invoice Details SOLI'	=>	'Service_Order_Header__r.Transaction_Type__r.Type__c = \'Customer\''
    																					},
    														'Service - Third-Party'	=>	new Map<String, String> {
    																						'Customer Invoice Details SOLI'	=>	'Service_Order_Header__r.Transaction_Type__r.Type__c = \'Third-Party\''
    																					},
    														'Service - Internal'	=>	new Map<String, String> {
    																						'Customer Invoice Details SOLI'	=>	'Service_Order_Header__r.Transaction_Type__r.Type__c = \'Internal\''
    																					},
    														'Service - Deal Option'	=>	new Map<String, String> {
    																						'Customer Invoice Details SOLI'	=>	'Service_Order_Header__r.Transaction_Type__r.Type__c = \'Deal Service\''
    																					},
    														'Service - Stock Unit'	=>	new Map<String, String> {
    																						'Customer Invoice Details SOLI'	=>	'Service_Order_Header__r.Transaction_Type__r.Type__c = \'Stock Unit\''
    																					},
    														'Deal'	=>	new Map<String, String> {
    																						'Customer Invoice Details Option and Fee'	=>	'',
    																						'Customer Invoice Details Deal UPC'	=>	'',
    																						'Customer Invoice Details Trade in'	=>	'',
    																						'Customer Invoice Details FI Product'	=>	'',
    																						'Customer Invoice Details Deal Finance' => '',
                                                                                            'Customer Invoice Details Deal' => '(Deal_Commission__c != null AND Deal_Commission__c != 0)',
                                                                                            'Customer Invoice Details Lien' => '(Lien_Payout__c != null AND Lien_Payout__c != 0)'
    																					}
    													};
    
    public static Map<String, Map<String, String>> itemTypeToSearchTypeToWhereClauseStrMap = new Map<String, Map<String, String>>{
													    	'Part'	=>	new Map<String, String> {
    																						'Customer Invoice Details COLI'	=>	'Part__c != null',
    																						'Customer Invoice Details SOLI'	=>	'Part__c != null'
    																					},
    														'Labor'	=>	new Map<String, String> {
    																						'Customer Invoice Details SOLI'	=>	'Labour_Code__c != null'
    																					},
    														'Sublet'	=>	new Map<String, String> {
    																						'Customer Invoice Details SOLI'	=>	'Sublet__c != null'
    																					},
    														'Fee'	=>	new Map<String, String> {
    																						'Customer Invoice Details COLI'	=>	'Fee__c != null',
    																						'Customer Invoice Details SOLI'	=>	'(Fee__c != null AND Type__c = null)'
    																					},
    														'Supplies'	=>	new Map<String, String> {
    																						'Customer Invoice Details SOLI'	=>	'(Fee__c != null AND Type__c = \'Shop Supply\')'
    																					},
    														'Unit-Base'	=>	new Map<String, String> {
    																						'Customer Invoice Details Deal UPC'	=>	'Type__c = \'Base\''
    																					},
    														'Unit-Factory'	=>	new Map<String, String> {
    																						'Customer Invoice Details Deal UPC'	=>	'Type__c = \'Factory\''
    																					},
    														'Unit-Dealer'	=>	new Map<String, String> {
    																						'Customer Invoice Details Deal UPC'	=>	'Type__c = \'Dealer\''
    																					},
    														'Option-Part'	=>	new Map<String, String> {
    																						'Customer Invoice Details Option and Fee'	=>	'Part__c != null'
    																					},
    														'Option-Labor'	=>	new Map<String, String> {
    																						'Customer Invoice Details Option and Fee'	=>	'Labour_Code__c != null'
    																					},
    														'Option-Sublet'	=>	new Map<String, String> {
    																						'Customer Invoice Details Option and Fee'	=>	'(Product__c != null AND Product__r.Type__c = \'Sublet\')'
    																					},
    														'Option-Fee'	=>	new Map<String, String> {
    																						'Customer Invoice Details Option and Fee'	=>	'Fee__c != null'
    																					},
    														'Option-Warranty'	=>	new Map<String, String> {
    																						'Customer Invoice Details Option and Fee'	=>	'(Product__c != null AND Product__r.Type__c = \'Warranty Plan\')'
    																					},
    														'Option-Product'	=>	new Map<String, String> {
    																						'Customer Invoice Details Option and Fee'	=>	'(Product__c != null AND Product__r.Type__c != \'Sublet\' AND Product__r.Type__c != \'Warranty Plan\')'
    																					},
    														'Trade-in'	=>	new Map<String, String> {
    																						'Customer Invoice Details Trade in'	=>	''
    																					},
    														'Finance Product'	=>	new Map<String, String> {
    																						'Customer Invoice Details FI Product'	=>	''
    																					},
                                                            'Finance Commission' => new Map<String, String>{
                                                                                            'Customer Invoice Details Deal Finance' =>  ''
                                                                                        },
                                                            'Sales Commission' => new Map<String, String>{
                                                                                            'Customer Invoice Details Deal' =>  '(Deal_Commission__c != null AND Deal_Commission__c != 0)'
                                                                                        }
													    };
    
    public static Set<String> objectsToSearchForCustomerInvoiceDetailsSearch = new Set<String>{
							    		'Customer Invoice Details COLI',
							    		'Customer Invoice Details SOLI',
							    		'Customer Invoice Details Option and Fee',
							    		'Customer Invoice Details Deal UPC',
							    		'Customer Invoice Details Trade in',
							    		'Customer Invoice Details FI Product',
                                        'Customer Invoice Details Deal Finance',
                                        'Customer Invoice Details Deal'
							    	};
    
    // Map used in Inventory Aging Home Search for Parts records
    public static Map<String, String> agingPeriodsToPeriodValueMap = new Map<String, String> 
                                               {'PRD1' => Part_Aging_Period__c.getOrgDefaults().Period_1__c + 'day-',
                                               'PRD2' => Part_Aging_Period__c.getOrgDefaults().Period_2__c + 'day-',
                                               'PRD3' => Part_Aging_Period__c.getOrgDefaults().Period_3__c + 'day-',
                                               'PRD4' => '>' + Part_Aging_Period__c.getOrgDefaults().Period_3__c + 'day-'
                                               };                                                                                                                                                                               
}