<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Total Payment-Last 7 Days</label>
    <protected>false</protected>
    <values>
        <field>Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>Block_Name__c</field>
        <value xsi:type="xsd:string">Payments</value>
    </values>
    <values>
        <field>Data_Type__c</field>
        <value xsi:type="xsd:string">Currency</value>
    </values>
    <values>
        <field>Filter_Order_Number__c</field>
        <value xsi:type="xsd:double">2.0</value>
    </values>
    <values>
        <field>Filter_Value__c</field>
        <value xsi:type="xsd:string">Last 7 Days</value>
    </values>
    <values>
        <field>Home_Search_Additional_Field_Json__c</field>
        <value xsi:type="xsd:string">[{&quot;UIFieldKey&quot;:&quot;CO_Payment_Payment_Method&quot;,&quot;Label&quot;:&quot;Payment Method&quot;,&quot;IsDisplayed&quot;:true}]</value>
    </values>
    <values>
        <field>Home_Search_Filter_Json__c</field>
        <value xsi:type="xsd:string">{&quot;Type&quot;:{&quot;Objects&quot;:[&quot;Customer Payments&quot;]},&quot;CreatedDate&quot;:{&quot;SelectedOption&quot;:3}, &quot;CO_Payment_Payment_Method&quot;:{&quot;SelectedOption&quot;:10}}</value>
    </values>
    <values>
        <field>Order_Number__c</field>
        <value xsi:type="xsd:double">2.0</value>
    </values>
    <values>
        <field>Query__c</field>
        <value xsi:type="xsd:string">SELECT SUM(Amount__c) FROM CO_Deposit__c WHERE CreatedDate = LAST_N_DAYS:7 AND (Payment_Method__c IN (&apos;Cash&apos;,&apos;Debit&apos;,&apos;Cheque&apos;,&apos;Visa&apos;,&apos;Mastercard&apos;,&apos;Amex&apos;,&apos;Preferred Payments&apos;,&apos;Afterpay&apos;,&apos;Discover&apos;,&apos;EFTPOS&apos;,&apos;PayPal&apos;,&apos;PIN Payment&apos;,&apos;Webstore&apos;));SELECT SUM(Amount__c) FROM CO_Invoice_Payment__c WHERE CreatedDate = LAST_N_DAYS:7 AND (Payment_Method__c IN (&apos;Cash&apos;,&apos;Debit&apos;,&apos;Cheque&apos;,&apos;Visa&apos;,&apos;Mastercard&apos;,&apos;Amex&apos;,&apos;Preferred Payments&apos;,&apos;Afterpay&apos;,&apos;Discover&apos;,&apos;EFTPOS&apos;,&apos;PayPal&apos;,&apos;PIN Payment&apos;,&apos;Webstore&apos;));SELECT SUM(Total_Payment__c) FROM Payment_on_Account__c WHERE CreatedDate = LAST_N_DAYS:7 AND (Payment_Method__c IN (&apos;Cash&apos;,&apos;Debit&apos;,&apos;Cheque&apos;,&apos;Visa&apos;,&apos;Mastercard&apos;,&apos;Amex&apos;,&apos;Preferred Payments&apos;,&apos;Afterpay&apos;,&apos;Discover&apos;,&apos;EFTPOS&apos;,&apos;PayPal&apos;,&apos;PIN Payment&apos;,&apos;Webstore&apos;))</value>
    </values>
    <values>
        <field>Summary_Card__c</field>
        <value xsi:type="xsd:string">Store_Summary</value>
    </values>
</CustomMetadata>
