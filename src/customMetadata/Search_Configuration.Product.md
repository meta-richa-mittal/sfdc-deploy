<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Product__c</label>
    <protected>false</protected>
    <values>
        <field>Additional_Fields_To_Query__c</field>
        <value xsi:type="xsd:string">Product_Unique_Name__c,Vendor__r.Id,Vendor__r.Name,Price__c</value>
    </values>
    <values>
        <field>Additional_Info_To_Display__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Display_Field_Name__c</field>
        <value xsi:type="xsd:string">Product_Unique_Name__c</value>
    </values>
    <values>
        <field>Enable_Search__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Fixed_Where_Clause__c</field>
        <value xsi:type="xsd:string">Status__c = &apos;Active&apos;</value>
    </values>
    <values>
        <field>Is_Special_Search__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Order__c</field>
        <value xsi:type="xsd:double">8.0</value>
    </values>
    <values>
        <field>Searchable_Field_Set__c</field>
        <value xsi:type="xsd:string">Code__c,Description__c,Type__c,Category__r.Name</value>
    </values>
</CustomMetadata>