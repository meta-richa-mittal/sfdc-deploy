<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Service_Order_Header__c</label>
    <protected>false</protected>
    <values>
        <field>Additional_Fields_To_Query__c</field>
        <value xsi:type="xsd:string">Name__c,CO_Header__r.Customer__c,SO_Concern__c,Transaction_Type__r.Type__c,(SELECT Id, Service_Order_Header__c FROM Events__r where Type__c = &apos;Appointment&apos;)</value>
    </values>
    <values>
        <field>Additional_Info_To_Display__c</field>
        <value xsi:type="xsd:string">Name__c</value>
    </values>
    <values>
        <field>Display_Field_Name__c</field>
        <value xsi:type="xsd:string">CO_Header__r.Name</value>
    </values>
    <values>
        <field>Enable_Search__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Fixed_Where_Clause__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Is_Special_Search__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Order__c</field>
        <value xsi:type="xsd:double">26.0</value>
    </values>
    <values>
        <field>Searchable_Field_Set__c</field>
        <value xsi:type="xsd:string">CO_Header__r.Name,CO_Header__r.Customer_Name__c,Customer_Owned_Unit__r.VIN_Number__c,Customer_Owned_Unit__r.Unit_Id__c,Customer_Owned_Unit__r.Formatted_Name__c,Customer_Owned_Unit__r.Unit_Make__r.Name,Customer_Owned_Unit__r.Unit_Model__r.Name__c,Transaction_Type__r.Code_Label__c</value>
    </values>
</CustomMetadata>
