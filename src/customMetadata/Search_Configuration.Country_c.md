<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Country__c</label>
    <protected>false</protected>
    <values>
        <field>Additional_Fields_To_Query__c</field>
        <value xsi:type="xsd:string">Active__c,Conversion_Rate__c,Flag_Encoded__c,Currency_Symbol__c,Backward_Conversion_Rate__c</value>
    </values>
    <values>
        <field>Additional_Info_To_Display__c</field>
        <value xsi:nil="true"/>
    </values>
    <values>
        <field>Display_Field_Name__c</field>
        <value xsi:type="xsd:string">Name__c</value>
    </values>
    <values>
        <field>Enable_Search__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Fixed_Where_Clause__c</field>
        <value xsi:type="xsd:string">Active__c != TRUE AND Currency_Code__c != null</value>
    </values>
    <values>
        <field>Is_Special_Search__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Order__c</field>
        <value xsi:type="xsd:double">25.0</value>
    </values>
    <values>
        <field>Searchable_Field_Set__c</field>
        <value xsi:type="xsd:string">Name__c,Currency_Name__c,Currency_Code__c</value>
    </values>
</CustomMetadata>
