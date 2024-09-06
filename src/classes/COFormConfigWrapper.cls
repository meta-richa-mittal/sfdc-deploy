/**
 * Author: Nidhi Sharma
 * Since: Oct 29, 2020
 * Name: COFormConfigWrapper
 * Description: Used to provide form mapping values
**/
public class COFormConfigWrapper {
	
	public String CustomerOrderNumber;
    public String CODate;
    public String CODateDay;
    public String CODateMonth;
    public String CODateYear;
    public String CONumber;
	
    //Customer
    public String CustomerType;
    public String CustomerFirstName;
    public String CustomerLastName;
    public String CustomerName;
    public String CustomerStreetAddress1;
    public String CustomerStreetAddress2;
    public String CustomerStreetAddress1and2;
    public String CustomerCity;
    public String CustomerState;
    public String CustomerZIPCode;
    public String CustomerBillingCityStateZipCode;
    public String CustomerPhoneNumber;
    public String CustomerOtherPhone;
    public String CustomerEmail;
    public String CustomerDriverLicenseNumber;
    public String CustomerDOB;
    public String IndividualCustomerDOB;
    public String CustomerAddress;
    public String CustomerShippingStreetAddress1;
    public String CustomerShippingStreetAddress2;
    public String CustomerShippingStreetAddress1and2;
    public String CustomerShippingCity;
    public String CustomerShippingState;
    public String CustomerShippingZIPCode;
    public String CustomerShippingCountry;
    public String CustomerBillingCityState;
    public String CustomershippingCityStateZipCode;
    public String CustomerShippingAddress;
    public String CustomerStreetCombinedAddressLine;
    public String CustomerNumber;
    public String CustomerTwoLineAddress;
    public String CustomerTwoLineShippingAddress;
    public String VendorAccountNumber;
    public String CustomerDOBDay;
    public String CustomerDOBMonth;
    public String CustomerDOBYear;
    public String CustomerJobTitle;
    public String CustomerNickname;
    public String CustomerShippingStreetAddress1and2AndCity;
    public String CustomerStreetAddress1and2AndCity;
    public String CustomerDLExpiryDate;
    public String CustomerAgOtherID;
    public String CustomerCompanyName;
    public String CustomerMiddleName;
    public String CustomerTaxID;
    public String CustomerBillingCountyParish;
    public String CustomerShippingCountyParish;
    public String BusinessCustomerTaxId;
    public String ShippingMailingStreet = '';
    public String ShippingMailingCity = '';
    public String ShippingMailingState = '';
    public String ShippingMailingZIPCode = '';

    
    //Individual Customer
    public String IndividualCustomerName;
    public String IndividualCustomerAddress1and2;
    public String IndividualCustomerCity;
    public String IndividualCustomerState;
    public String IndividualCustomerZipcode;
    public String IndividualCustomerPhoneNumber;
    public String IndividualCustomerEmail;

    //Business Customer
    public String BusinessCustomerName;
    public String BusinessCustomerAddress1and2;
    public String BusinessCustomerCity;
    public String BusinessCustomerState;
    public String BusinessCustomerZipcode;
    public String BusinessCustomerPhoneNumber;
    public String BusinessCustomerEmail;
    
    //Business
    public String BusinessPhoneNumber;
    public String BusinessEmail;
    public String BusinessName;
    public String BusinessCity;
    public String BusinessState;
    public String BusinessZipcode;
    public String BusinessAddressLine1;
    public String BusinessAddressLine2;
    public String BusinessAddress1and2;
    public String BusinessAddress;
    public String BusinessCityStateZipCode;
    public String BusinessCityState;
    public String BusinessTaxId;
    public String BusinessDealerNumber;
    
    //Deal
    public String DealInvoicedDate;
    public String DateInvoicedDay;
    public String DateInvoicedMonth;
    public String DateInvoicedMonthName;
    public String DateInvoicedYear;
    public String DealDeliveryDate;
    public String DealTotalAmountPaid;
    public String DealTotalBalanceDue;
    public String DealInvoiceNumber;
    public String DealTotal;
    public String DealAmountFinanced;
    public String DateToday;
    public String DealSalesperson;
    public String DealTotalSalesTaxes;
    public String DealTotalUnitAmount;
    public String DealTotalDuePayble;
    public String NetPurchasePrice;
    public String DealSalespersonFirstName;
    public String DealSalespersonLastName;
    public String DealStatus;
    public String DateInvoicedDay01;
    public String DateInvoicedDay02;
    public String DateInvoicedMonth01;
    public String DateInvoicedMonth02;
    public String DateInvoicedYear01;
    public String DateInvoicedYear02;
    public String DateInvoicedYear03;
    public String DateInvoicedYear04;
    public String DealFirstDepositDate;
    public String DealDeposit;
    public String AllUnitsDOCTagUnitFee;
    public String SecondNetPurchasePrice;
    public String SumOfFirstandSecondTradeInUnitTotal;
    public String SumOfFirstandSecondUnitTotal;
    public String TotalNetPurchasePrice;
    public String DateTodayMonth;
    public String DateTodayMonthName;
    public String DateTodayDay;
    public String DateTodayYear;
    public String InsurancePolicyNumber;
    public String InsurancePolicyCompany;
    public String DealDeliveryDateDay;
    public String DealDeliveryDateMonth;
    public String DealDeliveryDateYear;
    public String SevenPercOfNetPurchasePrice;
    public String DealDepositType;
    public String AllUnitsLOCREGTagUnitFee;
    public String AllUnitsTEXREGTagUnitFee;
    public String AllUnitsBTAGTagUnitFee;
    public String AllUnitsINSPTagUnitFee;
    public String AllUnitsPROCTagUnitFee;
    public String AllUnitsTITLETagUnitFee;
    public String AllUnitsFRTOUTCodeUnitFee;
    public String NetBasePurchasePrice;
    public String SevenPercOfNetBasePurchasePrice;

    //Deal Finance
    public String FinanceCompany;
    public String FinanceCompanyBillingAddress1;
    public String FinanceCompanyBillingAddress2;
    public String FinanceCompanyBillingAddress1and2;
    public String FinanceCompanyBillingCity;
    public String FinanceCompanyBillingState;
    public String FinanceCompanyBillingZipCode;
    public String DealFinanceEstimatedPayment;
    public String DealFinanceLoanPayments;
    public String DealFinanceDownPayment;
    public String DealFinanceInterestRate;
    public String DealFinanceLoanTerm;
    public String DealFinanceDealTotal;
    public String DealFinancePaymentFrequency;
    public String FinanceCompanyBillingAddressCityStateZipCode;
    public String FinanceCompanyBillingCityStateZipCode;
    public String ProductDealFinanceEstimatedPaymentAndLoanTerm;
    public String DiffOfProdDealFinanceEstimatedPaymentAndLoanTermAndDealAmountFinanced;
    public String SumOfProdDealFinanceEstimatedPaymentAndLoanTermAndDealFinanceDownPayment;
    public String FinanceCompanyVendorTaxID;
    public String SumOfProductDealFinanceEstimatedPaymentAndLoanTermAndDealDeposit;
    public String DealFinanceCommission;
    public String DealAmountFinancedMinusCommission;
  
    //Co Buyer
    public String CoBuyerName = '';
    public String CoBuyerLicenseNumber = '';
    public String CoBuyerFirstName = '';
    public String CoBuyerLastName = '';
    public String CoBuyerAddress = '';
    public String CoBuyerAddress1 = '';
    public String CoBuyerAddress2 = '';
    public String CoBuyerStreetAddress1and2 = '';
    public String CoBuyerCity = '';
    public String CoBuyerState = '';
    public String CoBuyerZIPCode = '';
    public String CoBuyerBillingCityState = '';
    public String CoBuyerBillingCityStateZIPCode = '';
    public String CoBuyerDOB = '';
    public String CoBuyerEmail = '';
    public String CoBuyerMobile = '';
    public String CoBuyerPhoneNumber = '';
    public String CoBuyerDOBDay = '';
    public String CoBuyerDOBMonth = '';
    public String CoBuyerDOBYear = '';
    public String CoBuyerDLExpiryDate = '';
    public String CoBuyerAgOtherID;
    public String CoBuyerCompanyName;
    public String CoBuyerMiddleName;
    public String CoBuyerTaxID;
    public String CoBuyerBillingCountyParish;
    public String CoBuyerShippingCountyParish;
    public String CoBuyerDOBLCDetails = '';

    //Deal Unit
    public String TotalStampduty;
    public String UnitTotalBasePrice;
    public String UnitTotalFactoryOptions;
    public String UnitTotalDealerInstalledOptions;
    public String UnitTotalPriceWithNonFeeOptions;
    public String UnitTotalSalesTax;
    public String UnitTotalPrice;
    public String UnitTotalPriceWithPartLabour;
    public String UnitTotalOptionsParts;
    public String UnitTotalOptionsLabor;
    public String UnitAllOptionLaborCodeName;
    public String UnitTotalOptionsPartsAndLabor;
    public String UnitTotalOptionsPartsLaborAndSublet;
    public String UnitTotalOptionsAndFees;
    public String UnitTotalPriceLaborRegInsTagFee;
	public String DealTotalFee;
    public String DealTotalOptionsParts;
	public String DealTotalOptionsLabor;
    public String UnitInvoiceDate;
    public String DealTotalPartsAndLaborAmount;
	public String DealTotalPartLaborAndFee;
	public String DealPartAndFee;
    public String UnitTotalPriceWithAllOptions;
    public String DifferenceOfTradeInTotalAndUnitTotal;
    public String UnitTotalOptionsPartsAndSublet;
    public String WarrantyAndNoTagFeeUnitTotal;
    public String DealRideAwayPrice;
    public String DifferenceOfUnitTotalPriceWithAllOptionsAndTradeInTotal ;
    public String DifferenceOfUnitTotalPriceWithNonFeeOptionsAndTradeInTotal;
    public String DifferenceOfTotalUnitPriceCodeAndNoTagFeeAndTradeInTotal;
    public String SumOfBasePriceSalesTaxAndDOCFee;
    public String SumOfBasePricePartsPriceAndFRTOUTFee;
    public String SumOfBasePricePartsPriceFRTOUTFeeAndDOCFee;
    public String SumOfUnitTotalPriceAndSalesTax;
    public String SumOfTradeInTotalAndDealTotalAmountPaid;
    public String DiffOfUnitTotalPriceWithSalesTaxAndTradeInTotalWithDealTotalAmountPaid;
    public String AmountFinancedTrakPowersports;
    public String DifferenceOfTotalUnitPriceCodeAndNoTagPartAndTradeInTotal;
    public String TotalSalesTaxAndDifferenceOfTotalUnitPriceCodeAndNoTagPartAndTradeInTotal;
    public String DifferOfUnitTotalBasePriceAndDISCCodeUnitFee;
    public String DifferenceOfNetPurchasePriceAndRebateFee;
    public String SumOfRegtTitleTranFeeAndSalesTax;
    public String SumOfTradeInTotalAndTaxesAmount;
    public String SumOfTradeInTotalAndSecondTradeInUnitAllowance;
    public String DiffOfUnitTotalPriceAndSumOfTradeInTotalAndTradeInUnitLienPayoute;
    public String ReidsSumOfFeesAndOtherPrices;
    public String DiffOfReidsSumOfFeesAndOtherPricesAndDealTotalAmountPaid;
    public String SumOfNetPurchasePriceUnitTotalSalesTaxUnitFeeTITLETagUnitFee;
    public String SumOfNetPurchasePriceTITLETagLICTagTotalSalesTax;
    public String DifferenceOfUnitTotalPriceAndTradeInTotal;
    public String UnitTotalPriceWithSalesTax;
    public String SumOfUnitFeeTITLEUnitFeeREGTotalSalesTax;
    public String SumOfTotalBasePriceTotalSalesTaxAndTradeInTotal;
    public String SumOfTITLETagUnitFeeTotalSalesTax;
    public String NewWorldRVAmountOfTaxCollected;

    public String DealPartAndFeeFarnleysYamaha;
    public String TotalDeliverPriceOfVehicle;

    public String UnitTotalPriceAnd5OptionsPartFee;
    public String TotalUnitPriceFeeOfCodeAndNoTagFee;
    public String TotalSalesTaxAndDifferenceOfUnitPriceWithCodeAndNoTagFeeAndTradeInTotal;
    public String TotalUnitPriceOfCodeAndNoTagPart;
    public String SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceAndDOCTagUnitFee;
    public String SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceDOCTagUnitFeeLICTagUnitFeeAndTotalSalesTax;
    public String SumOfNetPurchasePrice_DealTotalSalesTaxes_TradeInUnitLienPayout;
    public String SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceDOCTagREGTagTITLETagUnitFee;
    public String SumOfNetPurchasePriceDOCTagREGTagTITLETagUnitFee;
    public String SumOfFeeTITLETagFeeLICTagFee;
    public String SumOfFeeTITLETagFeeLICTagDealTotalSalesTaxes;
    public String SumOfUnitTotalPriceWithAllOptionsAndDealTotalFees;
    public String SumOfPlateTranTitleFeesAndDealTotalSalesTaxes;
    public String SumOfPlateTranTitleFeesDealTotalSalesTaxesUnitTotalPriceWithAllOptionsAndDealTotalFees;
    
	public String DealPartAndFeeName1;
	public String DealPartAndFeePrice1;
	public String DealPartAndFeeName2;
	public String DealPartAndFeePrice2;
	public String DealPartAndFeeName3;
	public String DealPartAndFeePrice3;
	public String DealPartAndFeeName4;
	public String DealPartAndFeePrice4;
	public String DealPartAndFeeName5;
	public String DealPartAndFeePrice5;
    public String DealPartAndFeeName6;
    public String DealPartAndFeePrice6;
    public String DealPartDescriptionList;
    public String DealPartPriceList;
    public String TotalDealPartPrice;
    public String SumOfDealDepositAndDealFinanceDownPayment;
    public String DealPartAndFeePrice1To3Total;
    public String SumOfDealPartAndFeePrice1To3TotalAndUnitTotalPriceAndSalesTax;
    public String DealPartAndFeePrice1To5Total;
    public String SumOfDealPartAndFeePrice1To5TotalAndUnitTotalPriceAndSalesTax;
    public String SumOfUnitTotalOptionsAndFeesAndUnitTotalPriceAndSalesTax;
    public String SumOfTITLETagTRANTagREGTagLIENTagUnitFee;
    public String SumOfUnitTotalSalesTaxTITLETagTRANTagREGTagLIENTagUnitFee;
    public String DiffOfUnitTotalPriceDealerInstalledOptionsAndTradeInTotal;
    public String TotalSalePriceFRVBuyersOrder;
    public String SumOfUnitTotalDealerInstalledOptionsAndDealTotalFee;
    public String DifferenceOfUnitOtherData02WithUnitOtherData01;
    public String SumOfUnitData01AndUnitData02;
    public String SumOfUnitTotalOptionsAndFeesAndUnitTotalPriceWithSalesTax;
    public String SumOFDOCTagUnitFeeAndPartsAddedToDeal;

    //Unit
    public String UnitMake;
    public String UnitModel;
    public String UnitModelWithThirtyLetters;
    public String UnitSubModel;
    public String UnitYear;
    public String UnitStockNumber;
    public String UnitExteriorColour;
    public String UnitDateStockedin;
    public String UnitInteriorColour;
    public String UnitComplianceDate;
    public String UnitNotes;
    public String UnitNotesGleeson;
    public String UnitCylinders;
    public String UnitDisplacement;
    public String UnitTaxForReids;
    public String UnitModelDescription;
    public String UnitSubModelDescription;
    public String PurchaseOrderNumber;
    public String UnitConsignorName;
    public String UnitConsignorEmailAddress;
    public String UnitConsignorBillingStreet;
    public String UnitConsignorBillingCity;
    public String UnitConsignorBillingState;
    public String UnitConsignorPostalCode;
    public String UnitConsignorPhoneNumber;
    public String UnitConsignorOtherPhone;
    public String MultiLineUnitMake;
    public String MultiLineUnitModel;
    public String MultiLineUnitSubModel;
    public String UnitManufacturedDate;
    public String UnitManufacturedDateMonth;
    public String UnitManufacturedDateYear;
    public String MultiLineUnitOtherData01;
    public String MultiLineUnitOtherData02;
    public String MultiLineUnitOtherData03;
    public String MultiLineUnitOtherData04;
    public String MultiLineUnitOtherData05;
    public String MultiLineUnitOtherData06;
    public String MultiLineUnitOtherData07;
    public String MultiLineUnitOtherData08;
    public String MultiLineUnitOtherData09;
    public String MultiLineUnitOtherData10;
    public String MultiLineUnitOtherData11;
    public String MultiLineUnitOtherData12;
    public String MultiLineUnitOtherData13;
    public String MultiLineUnitOtherData14;
    public String MultiLineUnitOtherData15;
    
    public String UnitOdometer;
    public String UnitOdometer1;
    public String UnitOdometer2;
    public String UnitOdometer3;
    public String UnitOdometer4;
    public String UnitOdometer5;
    public String UnitOdometer6;
    
    public String UnitVIN;
    public String UnitVIN01;
    public String UnitVIN02;
    public String UnitVIN03;
    public String UnitVIN04;
    public String UnitVIN05;
    public String UnitVIN06;
    public String UnitVIN07;
    public String UnitVIN08;
    public String UnitVIN09;
    public String UnitVIN10;
    public String UnitVIN11;
    public String UnitVIN12;
    public String UnitVIN13;
    public String UnitVIN14;
    public String UnitVIN15;
    public String UnitVIN16;
    public String UnitVIN17;
    public String UnitVIN18;
    public String UnitVIN19;
    public String UnitVINLast6Digits;
    
    public String UnitComplianceDateMonth01;
    public String UnitComplianceDateMonth02;
    public String UnitComplianceDateYear01;
    public String UnitComplianceDateYear02;
    public String UnitComplianceDateYear03;
    public String UnitComplianceDateYear04;
    public String UnitRegistrationExpiryMonth;
    public String UnitRegistrationExpiryDay;
    public String UnitRegistrationExpiryYear;

    public String UnitOtherData01;
    public String UnitOtherData02;
    public String UnitOtherData03;
    public String UnitOtherData04;
    public String UnitOtherData05;
    public String UnitOtherData06;
    public String UnitOtherData07;
    public String UnitOtherData08;
    public String UnitOtherData11;
    public String UnitOtherData09;
    public String UnitOtherData10;
    public String UnitOtherData12;
    public String UnitOtherData13;
    public String UnitOtherData14;
    public String UnitOtherData15;
    public String UnitRegistrationSerialNumber;
    public Boolean NewUnit;
    public Boolean OldUnit;
    
	public String SecondUnitMake;
	public String SecondUnitModel;
	public String SecondUnitYear;
	public String SecondUnitExteriorColour;
	public String SecondUnitOtherData01;
	public String SecondUnitVIN;
	public String SecondUnitRegistrationNumber;
	public String SecondUnitEngineNumber;
    public String SecondUnitSubModel;
    public String GSTOnlyUnitSale;
    public String PSTOnlyUnitSale;
    public String SumOfAllDealUnitTotalPrices;
    public String SecondUnitOdometer;
    public String FETTaxAmount;
    public String SecondUnitYearFirstREGO;
    public String SecondUnitComplianceDate;
    public String SecondUnitRegistrationExpirydate;
    public String SecondUnitTotalStampDuty;
    public String SecondTradeInUnitInteriorColour;
    public String SecondTradeInTotal;
    
    public String SecondUnitOtherData02;
    public String SecondUnitOtherData03;
    public String SecondUnitOtherData04;
    public String SecondUnitOtherData05;
    public String SecondUnitOtherData06;
    public String SecondUnitOtherData07;
    public String SecondUnitOtherData08;
    public String SecondUnitOtherData09;
    public String SecondUnitOtherData10;
    public String SecondUnitOtherData11;
    public String SecondUnitOtherData12;
    public String SecondUnitOtherData13;
    public String SecondUnitOtherData14;
    public String SecondUnitOtherData15;
    public String SecondUnitStockNumber;
    public String SecondUnitTotalPrice;
    public String MultiLineSecondUnitMake;
    public String MultiLineSecondUnitModel;
    public String MultiLineSecondUnitSubModel;
    public String ThirdUnitVIN;
    public String ThirdUnitMake;
    public String ThirdUnitModel;
    public String ThirdUnitSubModel;
    public String ThirdUnitYear;
    public String ThirdUnitStockNumber;
    public String ThirdUnitTotalPrice;
    public String MultiLineThirdUnitMake;
    public String MultiLineThirdUnitModel;
    public String MultiLineThirdUnitSubModel;
    public String FourthUnitVIN;
    public String FourthUnitMake;
    public String FourthUnitModel;
    public String FourthUnitSubModel;
    public String FourthUnitYear;
    public String FourthUnitStockNumber;
    public String FourthUnitTotalPrice;
    public String MultiLineFourthUnitMake;
    public String MultiLineFourthUnitModel;
    public String MultiLineFourthUnitSubModel;
    public String FifthUnitVIN;
    public String FifthUnitMake;
    public String FifthUnitModel;
    public String FifthUnitSubModel;
    public String FifthUnitYear;
    public String FifthUnitStockNumber;
    public String FifthUnitTotalPrice;
    public String MultiLineFifthUnitMake;
    public String MultiLineFifthUnitModel;
    public String MultiLineFifthUnitSubModel;
    public String ThirdUnitOtherData01;
    public String ThirdUnitOtherData02;
    public String ThirdUnitOtherData03;
    public String ThirdUnitOtherData04;
    public String ThirdUnitOtherData05;
    public String ThirdUnitOtherData06;
    public String ThirdUnitOtherData07;
    public String ThirdUnitOtherData08;
    public String ThirdUnitOtherData09;
    public String ThirdUnitOtherData10;
    public String ThirdUnitOtherData11;
    public String ThirdUnitOtherData12;
    public String ThirdUnitOtherData13;
    public String ThirdUnitOtherData14;
    public String ThirdUnitOtherData15;
    public String FourthUnitOtherData01;
    public String FourthUnitOtherData02;
    public String FourthUnitOtherData03;
    public String FourthUnitOtherData04;
    public String FourthUnitOtherData05;
    public String FourthUnitOtherData06;
    public String FourthUnitOtherData07;
    public String FourthUnitOtherData08;
    public String FourthUnitOtherData09;
    public String FourthUnitOtherData10;
    public String FourthUnitOtherData11;
    public String FourthUnitOtherData12;
    public String FourthUnitOtherData13;
    public String FourthUnitOtherData14;
    public String FourthUnitOtherData15;
    public String FifthUnitOtherData01;
    public String FifthUnitOtherData02;
    public String FifthUnitOtherData03;
    public String FifthUnitOtherData04;
    public String FifthUnitOtherData05;
    public String FifthUnitOtherData06;
    public String FifthUnitOtherData07;
    public String FifthUnitOtherData08;
    public String FifthUnitOtherData09;
    public String FifthUnitOtherData10;
    public String FifthUnitOtherData11;
    public String FifthUnitOtherData12;
    public String FifthUnitOtherData13;
    public String FifthUnitOtherData14;
    public String FifthUnitOtherData15;

    //Trade In
    public String TradeInUnitMake;
    public String TradeInUnitModel;
    public String TradeInUnitSubModel;
    public String TradeInUnitYear;
    public String TradeInUnitExteriorColour;
    public String TradeInUnitDescription;
    public String TradeInUnitEngineSize;
    public String TradeInUnitYearFirstREGO;
    public String TradeInUnitOtherNumber;
	public String TradeInUnitOtherData01;
    public String TradeInUnitRegistriationNumber;
    public String TradeInUnitRegistrationExpirydate;
    public String TradeInUnitEngineNumber;
	public String TradeInUnitStockNumber;
    public String TradeInUnitOtherData03;
    public String TradeInUnitRegistrationExpiryDay;
    public String TradeInUnitRegistrationExpiryMonth;
    public String TradeInUnitRegistrationExpiryYear;
    public String TradeInRegistrationSerialNumber;
    
    public String TradeInTotal;
    public String TradeInUnitLienPayout;
    public String TradeInUnitNetAllowance;
    public String TaxableAmount;
    public String TaxableAmountAfterTax;
    public String DealTotalTradeInsAmount;

    public String TradeInSalesTaxesAmount;
    public String SecondTradeInUnitVIN;
    public String SecondTradeInUnitOdometer;
    public String SecondTradeInUnitLienPayout;
    public String SecondTradeInUnitAllowance;
    public String SecondTradeInUnitYear;
    public String SecondTradeInUnitMake;
    public String SecondTradeInUnitModel;
    public String SecondTradeInUnitTotal;

    public String SecondTradeInUnitSubModel;
    public String SecondTradeInUnitExteriorColour;
    public String SecondTradeInUnitEngineSize;
    public String SecondTradeInUnitYearFirstREGO;
    public String SecondTradeInUnitOtherNumber;
    public String SecondTradeInUnitRegistriationNumber;
    public String SecondTradeInUnitRegistrationExpirydate;
    public String SecondTradeInUnitEngineNumber;
    public String SecondTradeInUnitStockNumber;
    public String SecondTradeInLienFinanceCompanyName;
    public String SecondTradeInLienFinanceCompanyAddress1;
    public String SecondTradeInLienFinanceCompanyAddress2;
    public String SecondTradeInLienFinanceCompanyAddress1and2;
    public String SecondTradeInLienFinanceCompanyCity;
    public String SecondTradeInLienFinanceCompanyState;
    public String SecondTradeInLienFinanceCompanyZipCode;
    public String SecondTradeInLienFinanceCompanyCityStateZipCode;
    public String MultiLineSecondTradeInUnitMake;
    public String MultiLineSecondTradeInUnitModel;
    public String MultiLineSecondTradeInUnitSubModel;
    public String DiffOFUnitTotalBasePriceTotalOptionsAndFeesAndTradeInTotal;
    public String TotalBalanceDueExpertAuto;
    public String BalanceOnDeliveryExpertAuto;
    public String SumOfDealTotalTradeInsAndGSTAmount;
    public String TotalSattlementRRVSaleContract;
	
    public String MultiLineTradeInUnitMake;
    public String MultiLineTradeInUnitModel;
    public String MultiLineTradeInUnitSubModel;

	//Lien Payout    
    public String VendorTaxID;
    public String LienFinanceCompanyName;
    public String LienFinanceCompanyAddress1;
    public String LienFinanceCompanyAddress2;
    public String LienFinanceCompanyAddress1and2;
    public String LienFinanceCompanyCity;
    public String LienFinanceCompanyState;
    public String LienFinanceCompanyZipCode;
    public String LienFinanceCompanyCityStateZipCode;
    public String LienFinanceCompanyAddress1CityStateZipCode;
    public String DealTotalLienPayoutAmount;
    public String SumOfUnitTotalPriceTRANUnitFeeREGTagUnitFeeGSTOnlyUnitSale;
    public String DiffOfUnitTotalPriceWithSalesTaxAndDealTotalAmountPaid;
    public String UnitTotalPricePartLaborPartNDealTotalFeeStampduty;
    public String TotalPurchaseAmountForBusStop;
    public String SumOfDealTotalAndGSTOnlyUnitSale;
    public String SumOfDealTotalFeeAndStampduty;    
    
    public String TradeInUnitOdometer;
    public String TradeInUnitOdometer1;
    public String TradeInUnitOdometer2;
    public String TradeInUnitOdometer3;
    public String TradeInUnitOdometer4;
    public String TradeInUnitOdometer5;
    public String TradeInUnitOdometer6;
    
    public String TradeInUnitVIN;
    public String TradeInUnitVIN01;
    public String TradeInUnitVIN02;
    public String TradeInUnitVIN03;
    public String TradeInUnitVIN04;
    public String TradeInUnitVIN05;
    public String TradeInUnitVIN06;
    public String TradeInUnitVIN07;
    public String TradeInUnitVIN08;
    public String TradeInUnitVIN09;
    public String TradeInUnitVIN10;
    public String TradeInUnitVIN11;
    public String TradeInUnitVIN12;
    public String TradeInUnitVIN13;
    public String TradeInUnitVIN14;
    public String TradeInUnitVIN15;
    public String TradeInUnitVIN16;
    public String TradeInUnitVIN17;
    public String TradeInUnitVIN18;
    public String TradeInUnitVIN19;
    public String TradeInUnitYear01;
    public String TradeInUnitYear02;
    public String TradeInUnitYear03;
    public String TradeInUnitYear04;
    
	//Tagged Fee
	public String UnitFee1NoTagName; 
	public String UnitFee1NoTagPrice;
	public String UnitFee2NoTagName; 
	public String UnitFee2NoTagPrice;
	public String UnitFee3NoTagName; 
	public String UnitFee3NoTagPrice;
	public String UnitFee4NoTagName; 
	public String UnitFee4NoTagPrice;
	public String UnitFee5NoTagName; 
	public String UnitFee5NoTagPrice;
	public String UnitFee6NoTagName; 
	public String UnitFee6NoTagPrice;
	
    public String DealerDeliveryUnitFee;
    public String UCCFilingTagUnitFee;
	public String UnitFeeGasTagUnitFee; 
	public String UnitFeeLicTagUnitFee;
	public String UnitFeeWARRUnitFee;	//UnitFeeWarrantyProduct
    public String UnitFeeDOCTagUnitFee;
	public String UnitFeeREGTagUnitFee;
	public String UnitFeeINSTagUnitFee;
    public String UnitMakeModel;
    public String UnitRegistrationExpirydate;
    public String UnitYearFirstREGO;
    public String UnitRegistrationNumber;
    public String UnitEngineSize;
    public String UnitTotalPricePlusOptionsTax;
    public String UnitDescription;
    public String UnitOtherNumber;
    public String UnitEngineNumber;
    public String UnitOptionListing;
    public String ADMINTagUnitFee;
    public String UnitFeeTITLETagUnitFee;
	public String DOCCodeUnitFee;
	public String TEFCodeUnitFee;
	public String WARRCodeUnitFee;
	public String FRTCodeUnitFee;
	public String PDICodeUnitFee;
  	public String StateCodeUnitFee;
    public String FRTOUTCodeUnitFee;
    public String GAPCodeUnitFee;
    public String Title_FeeCodeUnitFee;
    public String ESCCodeUnitFee;
    public String NintyDay_WarrantyFeeCodeUnitFee;
    public String Prepaid_MaintenanceFeeCodeUnitFee;
    public String RegistrationFeeCodeUnitFee;
    public String PlateTransferFeeCodeUnitFee;
    public String VINInspectionFeeCodeUnitFee;
    public String VINTradeFeeCodeUnitFee;
    public String SumOfRegistrationPlateTransferVINInspectionAndVINTrade;
    public String SumOfFeesTrakPowersports;
    public String DOCCodeFeeName;
    public String ESCCodeFeeName;
    public String NintyDayWarrantyCodeFeeName;
    public String PrepaidMaintenanceCodeFeeName;
    public String DISCCodeUnitFee;
    public String GAPCodeUnitFeeDescription;
    public String GAPVendorProductTerm;
    public String GAPDescriptionPrice;
    public String License1CodeUnitFee;
    public String SumOfTop9PartsPriceAndDifferOfUnitTotalBasePriceAndDISCCodeUnitFee;
    public String SumOfUnitTotalSalesTaxTop9PartsPriceAndDifferOfUnitTotalBasePriceAndDISCCodeFee;
    public String TotalPurchasePriceForFTruck;
    public String PayableDeliveryUnitFee;
    public String RebateCodeFeePrice;
    public String UnitFeeTRANTagUnitFee;
    public String UnitFeeLIENTagUnitFee;
    public String SumOfTITLETagREGTagAndTRANTagUnitFee;
    public String SumOfTITLETagTRANTagUnitFeeAndUnitTotalSalesTax;
    public String SumOfNetPurchasePriceTotalSalesTaxREGTagADMINTagUnitFee;
    public String SumOfUnitTotalBasePriceUnitTotalSalesTaxTITLETagTRANTagREGTagDOCTagUnitFee;
    public String SumOfDealTotalTradeInsAmountAndDealDeposit;
    public String DifferenceofTotalDownpaymentAndTotalCashPrice;
    public String SumOfNetPriceUnitTotalSalesTaxTITLETagTRANTagLICTagUnitFee;
    public String SumOfFeeTITLETagFeeLICTagFeeDOCTagFee;
    public String SumOfFeeTITLETagFeeLICTagFeeDOCTagFeeUnitTotalPriceAndSalesTax;
    public String SumOfPlateTransferVINInspectionAndVINTrade;
    public String SumOfTitleRegPlateTransferVINInspectionAndVINTrade;
    public String SumOfESCNintyDayWarrantyPrepaid_MaintenanceFeeCode;
    public String SumOfTotalBasePriceTotalSaletaxAndVeriousFeeForMPLaw;
    public String UnpaidBalanceOfCashSalesPrice;
    public String DiffOfTradeInTotalAndTotalLienPayout;
    public String DiffOfTradeInTotalAndTotalLienPayoutAndDealTotalAmountPaid;
    public String TotalBalanceDueForAMPR;
    public String SumOfADMINTagPLATETagTITLETagTRANUnitFeeAndTotalSalesTax;
    public String PLATETagUnitFee;
    public String NetTradeAllowanceAndDealTotalAmountPaid;
    public String DiffOfBasePricePlusUnitTotalOptionsAndFeesAndTradeInTotal;
    public String SubtotalForProMarine;
    public String SumOfNetPurchasePriceAndDOCTagUnitFee;
    public String SumOfNetPurchasePriceDOCTagUnitFeeLICTagUnitFeeAndUnitTotalSalesTax;
    public String HighwayTaxForIDealCarsTrailers;
    public String SumOfUnitTotalPriceAndHighwayTax;
    public String SumOfDealDepositAndTradeInTotal;
    public String DiffOfUnitTotalPriceHighwayTaxAndDealDepositTradeInTotal;
    public String SumOfLICTagFeeREGTagFee;
    public String SumOfTITLETagLICTagAndREGagUnitFee;
    public String InsuranceDealProduct;
    public String ConsumerCreditInsurance;
    public String SubTotalRRVSalesContract;
    public String PurchasePriceInclusiveOfGST;
    public String TotalPurchasePriceForRRVSalesContract;
    public String SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions;
    public String DiffOfSumOfUnitTotalPriceAndUnitTotalDealerInstalledOptionsAndTradeInTotal;
    public String ProcessingCodeUnitFee;
    public String MPSportsAmountDue;
    public String SumOfTITLETagTranTagLICTagAndREGagUnitFee;
    public String IWSEWCodeUnitFee;
    public String IWSEWOptionCodeUnitFee;
    public String SumOfTITLETagLICTagAndREGTagUnitFee;
    public String SumOfDealTotalTITLETagLICTagAndREGTagUnitFee;
    public String SumOfBasePricePartsPriceFRTOUTFeeAndFETTax;
    public String SumOfLicTagREGTagAndTRANTagUnitFee;
    public String SumOfUnitTotalPriceTotalInstalledOptionsStampdutyREGTagTRANUnitFee;
    public String UnitTotalWithFactoryDealerInstalledAndPartOptions;
    public String SumOftotalUnitFeeWithNoTagAndStampDuty;
    public String SumOfUnitTotalWithFactoryDealerInstalledPartOptionsStampDutyAndNoTagFee;
    public String SumOfRegtTitleFeeAndSalesTax;
    public String SumOfUnitTotalWithFactoryDealerInstalledPartOptionsStampDutyNoTagFeeRegtTitleFeeAndSalesTax;
    public String SumOfDealTotalStampdutyRegTagUnitFee;
    public String SumOfUnitTotalWithFactoryDealerInstalledPartLaborOptionsStampDutyNoTagFeeRegtTitleFeeAndSalesTax;
    public String TREGTagUnitFee;
    public String LOCREGTagUnitFee;
    public String TEXREGTagUnitFee;
    public String BTAGTagUnitFee;
    public String INSPTagUnitFee;
    public String PROCTagUnitFee;
    public String HUTTagUnitFee;
    public String ORIGTagUnitFee;
    public String SumOfDOCAndORIGTagUnitFee;
    public String SumOfUnitTotalWithFactoryDealerInstalledPartLaborOptionsAndDOCTagUnitFeeRegtTitleFeeAndSalesTax;
    public String SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptionsWithoutStampDuty;
    public String SumOfUnitTotalWithFactoryDealerInstalledPartOptionsAndDOCTagUnitFee;
    public String SumOfUnitTotalWithFactoryDealerInstalledPartLaborOptionsAndDOCTagUnitFeeRegtTitleFeeAndSalesTaxMinusDealDeposit;
    public String SumOfTREGTagUnitFeeAndTITLETagUnitFee;
    public String VehicleBillofSaleSubTotal;
    public String SixPointTwoFivePercOfNetPurchasePrice;

    //Tagged Part
    public String UnitPart1NoTagName;
    public String UnitPart2NoTagName;
    public String UnitPart3NoTagName;
    public String UnitPart4NoTagName;
    public String UnitPart5NoTagName;
    public String UnitPart6NoTagName;
    public String UnitPart7NoTagName;
    public String UnitPart8NoTagName;
    public String UnitPart9NoTagName;
    public String UnitPart10NoTagName;
    public String UnitPart11NoTagName;
    public String UnitPart12NoTagName;
    public String UnitPart13NoTagName;
    public String UnitPart14NoTagName;
    public String UnitPart15NoTagName;
    public String UnitPart16NoTagName;
    public String UnitPart17NoTagName;
    public String UnitPart18NoTagName;
    public String UnitPart19NoTagName;
    public String UnitPart20NoTagName;
    public String UnitPart1NoTagPrice;
    public String UnitPart2NoTagPrice;
    public String UnitPart3NoTagPrice;
    public String UnitPart4NoTagPrice;
    public String UnitPart5NoTagPrice;
    public String UnitPart6NoTagPrice;
    public String UnitPart7NoTagPrice;
    public String UnitPart8NoTagPrice;
    public String UnitPart9NoTagPrice;
    public String UnitPart10NoTagPrice;
    public String UnitPart11NoTagPrice;
    public String UnitPart12NoTagPrice;
    public String UnitPart13NoTagPrice;
    public String UnitPart14NoTagPrice;
    public String UnitPart15NoTagPrice;
    public String UnitPart16NoTagPrice;
    public String UnitPart17NoTagPrice;
    public String UnitPart18NoTagPrice;
    public String UnitPart19NoTagPrice;
    public String UnitPart20NoTagPrice;


    //Previous owner fields
    public String UnitPrevOwnerName;  
    public String UnitPrevOwnerStreetAddress1;
    public String UnitPrevOwnerStreetAddress2;
    public String UnitPrevOwnerStreetAddress1and2;
    public String UnitPrevOwnerCity;
    public String UnitPrevOwnerState;
    public String UnitPrevOwnerZIPCode;
    public String UnitPrevOwnerAddress;

    //Service Order fields
    public String ServiceConcern;
    public String ServiceCause;
    public String ServiceCorrection;
    public String ServiceNotesforCustomer;
    public String ServiceNotesforCustomerCamroseMotorsports;
    public String ServiceJobItems;
    public String QtyServiceJobItems;
    public String ServiceJobInvoice;
    public String ServiceJobUnitMake;
    public String ServiceJobUnitModel;
    public String ServiceJobUnitSubModel;
    public String ServiceJobUnitYear;
    public String ServiceJobUnitVIN;
    public String ServiceJobUnitOdometer;
    public String ServiceJobOdometerOnArrival;
    public String ServiceJobOdometerOnDeparture;
    public String ServiceConcernCamrose;
	public String ServiceCauseCamrose;
	public String ServiceCorrectionCamrose;
    public String ServiceJobUnitStockNumber;
    public String ServiceJobUnitNumber;

    //kit header
    public String KitCodeAndDiscription;
	
	//Others
    public String DealerGDN = 'P153991X';
    public String PolicyNumber ='';
    public String Trailer = 'Trailer';
    public String DriversLicense = 'Driver\'s License';
    
	public void setCOFields(CO_Header__c coRec) {
		this.CustomerOrderNumber = coRec.Name;
        this.CODate = BPUtility.getFormatedDateTime(coRec.CreatedDate__c);
        this.PurchaseOrderNumber = coRec.Customer_PO_Number__c != null ? coRec.Customer_PO_Number__c: '-';
        this.CODateDay = coRec.CreatedDate__c != null ? String.valueOf(coRec.CreatedDate__c.day()) : '';
        this.CODateMonth = coRec.CreatedDate__c != null ? String.valueOf(coRec.CreatedDate__c.month()) : '';
        this.CODateYear = coRec.CreatedDate__c != null ? String.valueOf(coRec.CreatedDate__c.year()) : '';
        this.CONumber = String.isNotBlank(this.CustomerOrderNumber) ? this.CustomerOrderNumber.subString(3,this.CustomerOrderNumber.length()) : '';

        setShippingAddressFields(coRec);
	}
	
    public void setBusinessFields(Business_Profile__c bpRec) {
    	this.BusinessPhoneNumber = bpRec.Formatted_Business_Number__c != null ? bpRec.Formatted_Business_Number__c : '' ;
        this.BusinessEmail = bpRec.Business_Email__c != null ? bpRec.Business_Email__c : '';
        this.BusinessName = bpRec.Business_Name__c != null ? bpRec.Business_Name__c : '';
        this.BusinessCity = bpRec.Business_City__c != null ? bpRec.Business_City__c : '';
        this.BusinessState = bpRec.Business_State__r.Name__c != null ? bpRec.Business_State__r.Name__c : '';
        this.BusinessAddressLine1 = String.isNotBlank(bpRec.Business_Street_Address1__c) ? bpRec.Business_Street_Address1__c : '';
        this.BusinessAddressLine2 = String.isNotBlank(bpRec.Business_Street_Address2__c) ? bpRec.Business_Street_Address2__c : '';
        this.BusinessAddress1and2 = this.BusinessAddressLine1 + ' ' + this.BusinessAddressLine2;
        this.BusinessZipcode = bpRec.Business_Postal_Code__c != null ? bpRec.Business_Postal_Code__c : '';
        this.BusinessAddress = this.BusinessAddress1and2 + ' ' + this.BusinessCity+ ' ' + this.BusinessState+ ' ' + this.BusinessZipcode;
        this.BusinessCityStateZipCode = this.BusinessCity+ ' ' + this.BusinessState+ ' ' + this.BusinessZipcode;
        this.BusinessCityState = this.BusinessCity+ ' ' + this.BusinessState;
        this.BusinessTaxId = Configurations__c.getOrgDefaults().Tax_Id__c;
        this.BusinessDealerNumber = Configurations__c.getOrgDefaults().Dealer_Number__c;
    }
    
    public void setCustomerFields(Account customerRec) {
        this.CustomerName = String.isNotBlank(customerRec.Name) ? customerRec.Name : '';
        this.CustomerNumber = String.isNotBlank(customerRec.Customer_Number__c) ? customerRec.Customer_Number__c : '';
        
        String billingStreet = (customerRec.BillingStreet == null ) ? '' : customerRec.BillingStreet;
        List<String> bsList = billingStreet.contains('\r\n') ? billingStreet.split('\r\n') : billingStreet.split('\n');
        this.CustomerStreetAddress1 = (bsList.size() > 0) ? bsList[0].replaceAll('\r\n', ' ') : '';
        this.CustomerStreetAddress2 = (bsList.size() > 1) ? bsList[1].replaceAll('\r\n', ' ') : '';
        this.CustomerStreetAddress1and2 = this.CustomerStreetAddress1 + ' ' + this.CustomerStreetAddress2;
                
        this.CustomerCity = String.isNotBlank(customerRec.BillingCity) ? customerRec.BillingCity : '';
        this.CustomerState = String.isNotBlank(customerRec.BillingState) ? customerRec.BillingState : '';
        this.CustomerZIPCode = String.isNotBlank(customerRec.BillingPostalCode) ? customerRec.BillingPostalCode : '';
        this.CustomerBillingCityStateZipCode = this.CustomerCity + ' ' + this.CustomerState + ' ' + this.CustomerZIPCode;
        this.CustomerBillingCityState = this.CustomerCity + ' ' + this.CustomerState;
        this.CustomerStreetAddress1and2AndCity = ((String.isNotBlank(this.CustomerStreetAddress1and2) ? this.CustomerStreetAddress1and2+' ' : '') + (String.isNotBlank(this.CustomerCity) ? this.CustomerCity : '')).trim();

        this.CustomerPhoneNumber = '';
        if(customerRec.Type__c == 'Individual') {
            this.CustomerFirstName = (customerRec.FirstName__c != null) ? customerRec.FirstName__c : '';
            this.CustomerLastName = (customerRec.LastName__c != null) ? customerRec.LastName__c : '';
            this.CustomerPhoneNumber = String.isNotBlank(customerRec.Formatted_Home_number__c) ? customerRec.Formatted_Home_number__c : '';
            this.CustomerEmail = (customerRec.Email__c != null) ? customerRec.Email__c : '';
            this.CustomerType = 'Individual';
        } else if(customerRec.Type__c == 'Business')  {
            this.CustomerFirstName = '';
            this.CustomerLastName = (customerRec.Name != null)? customerRec.Name : '';
            this.CustomerPhoneNumber = String.isNotBlank(customerRec.Formatted_Work_Number__c) ? customerRec.Formatted_Work_Number__c : '';
            this.CustomerEmail = (customerRec.Work_Email__c != null) ? customerRec.Work_Email__c : '';
            this.CustomerType = 'Business';
        }
        this.CustomerOtherPhone = String.isNotBlank(customerRec.Formatted_Mobile_Number__c) ? customerRec.Formatted_Mobile_Number__c : '';
        this.CustomerDriverLicenseNumber = (customerRec.Drivers_License__c != null) ? customerRec.Drivers_License__c : '';
        this.CustomerDOB = (customerRec.Birth_Date__c != null ? BPUtility.getFormatedDateTime(Datetime.newInstance(customerRec.Birth_Date__c.year(), 
        						customerRec.Birth_Date__c.month(), customerRec.Birth_Date__c.day())) : '');
       	this.CustomerAddress = this.CustomerStreetAddress1and2 + ' ' + this.CustomerCity + ' ' + this.CustomerState + ' ' + this.CustomerZIPCode;
        this.CustomerTwoLineAddress = this.CustomerAddress;
        this.CustomerAddress = this.CustomerAddress.replace('\r\n',' ');
        this.CustomerAddress = this.CustomerAddress.replace('\n',' ');
        this.CustomerAddress = this.CustomerAddress.replace('\r',' ');
        this.CustomerStreetCombinedAddressLine = String.isNotBlank(this.CustomerStreetAddress1and2) ? this.CustomerStreetAddress1and2 : '';
        this.CustomerStreetCombinedAddressLine = this.CustomerStreetCombinedAddressLine.replace('\r\n',' ').replace('\n',' ').replace('\r',' ');
        this.CustomerDOBDay = customerRec.Birth_Date__c != null ? String.valueOf(customerRec.Birth_Date__c.day()) : '';
        this.CustomerDOBMonth = customerRec.Birth_Date__c != null ? String.valueOf(customerRec.Birth_Date__c.month()) : '';
        this.CustomerDOBYear = customerRec.Birth_Date__c != null ? String.valueOf(customerRec.Birth_Date__c.year()) : '';
        this.CustomerJobTitle = customerRec.Job_Title__c != null ? String.valueOf(customerRec.Job_Title__c) : '';
        this.CustomerNickname = customerRec.Nickname__c != null ? String.valueOf(customerRec.Nickname__c) : '';
        this.CustomerDLExpiryDate = (customerRec.Drivers_License_Expiry_Date__c != null ? BPUtility.getFormatedDateTime(Datetime.newInstance(customerRec.Drivers_License_Expiry_Date__c.year(), 
        						customerRec.Drivers_License_Expiry_Date__c.month(), customerRec.Drivers_License_Expiry_Date__c.day())) : '');
        this.CustomerAgOtherID = customerRec.Ag_Other_ID__c != null ? String.valueOf(customerRec.Ag_Other_ID__c) : '';
        this.CustomerCompanyName = customerRec.Company_Name__c != null ? String.valueOf(customerRec.Company_Name__c) : '';
        this.CustomerMiddleName = customerRec.Middle_Name__c != null ? String.valueOf(customerRec.Middle_Name__c) : '';
        this.CustomerTaxID = customerRec.Tax_ID__c != null ? String.valueOf(customerRec.Tax_ID__c) : '';
        this.CustomerBillingCountyParish = customerRec.Billing_County_Parish__c != null ? String.valueOf(customerRec.Billing_County_Parish__c) : '';
        this.setIndividualOrBusinessCustomerDetails(this.customerType);
    }
    
    public void setIndividualOrBusinessCustomerDetails(String customerType){
        if(customerType == 'Individual'){
            this.IndividualCustomerName = this.CustomerName;
            this.IndividualCustomerAddress1and2 = this.CustomerStreetAddress1and2;
            this.IndividualCustomerCity = this.CustomerCity;
            this.IndividualCustomerState = this.CustomerState;
            this.IndividualCustomerZipcode = this.CustomerZipcode;
            this.IndividualCustomerPhoneNumber = this.CustomerPhoneNumber;
            this.IndividualCustomerEmail = this.CustomerEmail;
            this.IndividualCustomerDOB = this.CustomerDOB;

        }else if(customerType == 'Business'){
            this.BusinessCustomerName = this.CustomerName;
            this.BusinessCustomerAddress1and2 = this.CustomerStreetAddress1and2;
            this.BusinessCustomerCity = this.CustomerCity;
            this.BusinessCustomerState = this.CustomerState;
            this.BusinessCustomerZipcode = this.CustomerZipcode;
            this.BusinessCustomerPhoneNumber = this.CustomerPhoneNumber;
            this.BusinessCustomerEmail = this.CustomerEmail;
            this.BusinessCustomerTaxId = this.CustomerTaxID;
        }
    }
    
    public void setDealFields(Deal__c dealRec) {
        DateTime invoicedDateTime =  (dealRec.Invoice_Number__r.Invoice_Date__c != null ? dealRec.Invoice_Number__r.Invoice_Date__c : system.now());
        this.DealInvoicedDate =  BPUtility.getFormatedDateTime(invoicedDateTime);
        this.DateInvoicedDay = invoicedDateTime.format('dd');
        this.DateInvoicedMonth =  invoicedDateTime.format('MM');
        this.DateInvoicedMonthName = invoicedDateTime.format('MMMMM');
        this.DateInvoicedYear = String.valueOf(invoicedDateTime.year());
        this.DealDeliveryDate =  (dealRec.Delivery_Date__c != null ? BPUtility.getFormatedDateTime(Datetime.newInstance(dealRec.Delivery_Date__c.year(), 
        						dealRec.Delivery_Date__c.month(), dealRec.Delivery_Date__c.day())) : '');
        this.DealInvoiceNumber = dealRec.Invoice_Number__r.Invoice_Number__c;
        this.DateToday = BPUtility.getFormatedDateTime(Date.today());
        this.DealSalesperson = String.isNotBlank(dealRec.Salesperson_Name__c) ? dealRec.Salesperson_Name__c: '';						
        this.DealFinanceDealTotal = formatToDecimal((dealRec.Deal_Total__c != null) ? dealRec.Deal_Total__c : 0);
        this.DealTotalSalesTaxes = formatToDecimal(dealRec.Sales_Tax_Total__c != null ? dealRec.Sales_Tax_Total__c.setScale(2, RoundingMode.HALF_UP) : 0);
        this.DealSalespersonFirstName = this.DealSalesperson.split(' ').size() > 0 ? this.DealSalesperson.split(' ')[0] : '';
        this.DealSalespersonLastName = this.DealSalesperson.split(' ').size() > 1 ? this.DealSalesperson.split(' ')[this.DealSalesperson.split(' ').size() - 1] : '';
        this.DealStatus = String.isNotBlank(dealRec.Status__c) ? dealRec.Status__c: '';
        this.DateInvoicedDay01 = this.DateInvoicedDay.length() > 0 ? this.DateInvoicedDay.subString(0, 1) : '';
        this.DateInvoicedDay02 = this.DateInvoicedDay.length() > 1 ? this.DateInvoicedDay.subString(1, 2) : '';
        this.DateInvoicedMonth01 = this.DateInvoicedMonth.length() > 0 ? this.DateInvoicedMonth.subString(0, 1) : '';
        this.DateInvoicedMonth02 = this.DateInvoicedMonth.length() > 1 ? this.DateInvoicedMonth.subString(1, 2) : '';
        this.DateInvoicedYear01 = this.DateInvoicedYear.length() > 0 ? this.DateInvoicedYear.subString(0, 1) : '';
        this.DateInvoicedYear02 = this.DateInvoicedYear.length() > 1 ? this.DateInvoicedYear.subString(1, 2) : '';
        this.DateInvoicedYear03 = this.DateInvoicedYear.length() > 2 ? this.DateInvoicedYear.subString(2, 3) : '';
        this.DateInvoicedYear04 = this.DateInvoicedYear.length() > 3 ? this.DateInvoicedYear.subString(3, 4) : '';
        this.DateTodayDay = String.valueOf(Date.today().day());
        this.DateTodayMonth = String.valueOf(Date.today().month());
        this.DateTodayMonthName = system.now().format('MMMMM');
        this.DateTodayYear = String.valueOf(Date.today().year());
        this.InsurancePolicyNumber = String.isNotBlank(dealRec.Insurance_Policy__c) ? dealRec.Insurance_Policy__c : '';
        this.InsurancePolicyCompany = String.isNotBlank(dealRec.Insurance_Provider__c) ? dealRec.Insurance_Provider__c : '';
        this.DealDeliveryDateDay = dealRec.Delivery_Date__c !=null ? String.valueOf(dealRec.Delivery_Date__c.day()) : '';
        this.DealDeliveryDateMonth = dealRec.Delivery_Date__c !=null ? String.valueOf(dealRec.Delivery_Date__c.month()) : '';
        this.DealDeliveryDateYear = dealRec.Delivery_Date__c !=null ? String.valueOf(dealRec.Delivery_Date__c.year()) : '';
        if(dealRec.Co_Buyer__c != null) {
            setCOBuyerFields(dealRec.Co_Buyer__r);
        }
    }

    public void setServiceFields(Service_Order_Header__c serviceOrderRecord) {
        this.ServiceConcern = serviceOrderRecord.SO_Concern__c;
        this.ServiceCause = serviceOrderRecord.SO_Cause__c;
        this.ServiceCorrection = serviceOrderRecord.SO_Correction__c;
        this.ServiceNotesforCustomer = serviceOrderRecord.SO_Notes_For_Customer__c;
        this.ServiceJobInvoice = serviceOrderRecord.Invoice_Number__r.Invoice_Number__c;
        this.ServiceJobUnitMake = (serviceOrderRecord.Customer_Owned_Unit__r.Unit_Make__c != null) ? serviceOrderRecord.Customer_Owned_Unit__r.Unit_Make__r.Name : '';
        this.ServiceJobUnitModel = (serviceOrderRecord.Customer_Owned_Unit__r.Unit_Model__c != null) ? serviceOrderRecord.Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
        this.ServiceJobUnitSubModel = (serviceOrderRecord.Customer_Owned_Unit__r.Sub_Model__c != null) ? serviceOrderRecord.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
        this.ServiceJobUnitYear = (serviceOrderRecord.Customer_Owned_Unit__r.Year__c != null) ? String.valueOf(serviceOrderRecord.Customer_Owned_Unit__r.Year__c) : '';
		this.ServiceJobUnitVIN = (serviceOrderRecord.Customer_Owned_Unit__r.VIN_Number__c != null) ? serviceOrderRecord.Customer_Owned_Unit__r.VIN_Number__c : '';
        this.ServiceJobUnitOdometer = (serviceOrderRecord.Customer_Owned_Unit__r.Mileage_Value__c != null) ? String.valueOf(serviceOrderRecord.Customer_Owned_Unit__r.Mileage_Value__c) : '';
        this.ServiceJobOdometerOnArrival = (serviceOrderRecord.Odometer_on_Arrival__c != null) ? String.valueOf(serviceOrderRecord.Odometer_on_Arrival__c) : '';
        this.ServiceJobOdometerOnDeparture = (serviceOrderRecord.Odometer_on_Departure__c != null) ? String.valueOf(serviceOrderRecord.Odometer_on_Departure__c) : '';
        this.ServiceJobUnitStockNumber = (serviceOrderRecord.Customer_Owned_Unit__r.Stock_ID__c != null) ? serviceOrderRecord.Customer_Owned_Unit__r.Stock_ID__c : '';
        this.ServiceJobUnitNumber = (serviceOrderRecord.Customer_Owned_Unit__r.Unit_Id__c != null) ? serviceOrderRecord.Customer_Owned_Unit__r.Unit_Id__c : '';
        integer index = 0;
        ServiceNotesforCustomerCamroseMotorsports = '';
        if(String.isNotBlank(ServiceNotesforCustomer)) {
          while (index < ServiceNotesforCustomer.length()) {
            ServiceNotesforCustomerCamroseMotorsports  += ServiceNotesforCustomer.substring(index, Math.min(index + 90,ServiceNotesforCustomer.length())) + '\n';
            index += 90;
          }
        }  
        if(String.isNotBlank(ServiceNotesforCustomerCamroseMotorsports)) {
          ServiceNotesforCustomerCamroseMotorsports = ServiceNotesforCustomerCamroseMotorsports.removeEnd('\n');
        }
        index = 0;
        ServiceConcernCamrose = '';
        if(String.isNotBlank(ServiceConcern)) {
          while (index < ServiceConcern.length()) {
            ServiceConcernCamrose  += ServiceConcern.substring(index, Math.min(index + 100,ServiceConcern.length())) + '\n';
            index += 100;
          }
        }  
        if(String.isNotBlank(ServiceConcernCamrose)) {
          ServiceConcernCamrose = ServiceConcernCamrose.removeEnd('\n');
        }
	  	index = 0;
        ServiceCauseCamrose = '';
        if(String.isNotBlank(ServiceCause)) {
          while (index < ServiceCause.length()) {
            ServiceCauseCamrose  += ServiceCause.substring(index, Math.min(index + 100,ServiceCause.length())) + '\n';
            index += 100;
          }
        }  
        if(String.isNotBlank(ServiceCauseCamrose)) {
          ServiceCauseCamrose = ServiceCauseCamrose.removeEnd('\n');
        }
		index = 0;
        ServiceCorrectionCamrose = '';
        if(String.isNotBlank(ServiceCorrection)) {
          while (index < ServiceCorrection.length()) {
            ServiceCorrectionCamrose  += ServiceCorrection.substring(index, Math.min(index + 100,ServiceCorrection.length())) + '\n';
            index += 100;
          }
        }  
        if(String.isNotBlank(ServiceCorrectionCamrose)) {
          ServiceCorrectionCamrose = ServiceCorrectionCamrose.removeEnd('\n');
		}
    }

    public void setServiceSOLIFields(List<Service_Order_Line_Item__c> soliList) {
        String ServiceJobItemsStr = '';
        String QtyServiceJobItemsStr = '';
        List<Decimal> qtyServiceJobItemsList = new List<Decimal>();
        for(Service_Order_Line_Item__c soLineItem : soliList) {
            ServiceJobItemsStr += soLineItem.Item_Code__c + ' - ' + soLineItem.Item_Description__c + '\n';
            QtyServiceJobItemsStr += formatToDecimal(soLineItem.Qty_Needed__c) + '\n';
        }
		this.ServiceJobItems = String.isNotBlank(ServiceJobItemsStr) ? ServiceJobItemsStr.left(ServiceJobItemsStr.length()-1) : '';
        this.QtyServiceJobItems = String.isNotBlank(QtyServiceJobItemsStr) ? QtyServiceJobItemsStr.left(QtyServiceJobItemsStr.length()-1) : '';
    }

    public void setFIProductFields(List<F_I_Product__c> fiProducts){
      for(F_I_Product__c fiProductItem : fiProducts){
        if(fiProductItem.Vendor_product__r.Description__c.contains('GAP')){
          this.GAPDescriptionPrice = formatToDecimal(fiProductItem.Vendor_product__r.price__c);
          this.GAPCodeUnitFeeDescription = fiProductItem.Vendor_product__r.Description__c;
          this.GAPVendorProductTerm = fiProductItem.Vendor_Product__r.Term__c != null ? String.valueOf(fiProductItem.Vendor_Product__r.Term__c) : '';
          break;
        }
      }
      if(String.isBlank(this.GAPDescriptionPrice)){
        this.GAPDescriptionPrice = '';
      }
      if(String.isBlank(this.GAPCodeUnitFeeDescription)){
        this.GAPCodeUnitFeeDescription = '';
      }
      if(String.isBlank(this.GAPVendorProductTerm)){
        this.GAPVendorProductTerm = '';
      }
    }
    
    public void setDealFinancingFields(Deal_Finance__c dealFinanceRec) {
    	this.FinanceCompany = dealFinanceRec.Finance_Company__r.Name;
        String financebillingStreet = (dealFinanceRec.Finance_Company__r.BillingStreet == null ) ? '' : dealFinanceRec.Finance_Company__r.BillingStreet;
        List<String> fbsList = financebillingStreet.split('\n');
        this.FinanceCompanyBillingAddress1 = (fbsList.size() > 0) ? fbsList[0].replace('\n', ' ') : '';
        this.FinanceCompanyBillingAddress2 = (fbsList.size() > 1) ? fbsList[1].replace('\n', ' ') : '';
        this.FinanceCompanyBillingAddress1and2 = this.FinanceCompanyBillingAddress1 + ' ' + this.FinanceCompanyBillingAddress2;
        this.FinanceCompanyBillingCity = dealFinanceRec.Finance_Company__r.BillingCity != null ? dealFinanceRec.Finance_Company__r.BillingCity : '';
        this.FinanceCompanyBillingState = dealFinanceRec.Finance_Company__r.BillingState != null ? dealFinanceRec.Finance_Company__r.BillingState : '';
        this.FinanceCompanyBillingZipCode = dealFinanceRec.Finance_Company__r.BillingPostalCode != null ? dealFinanceRec.Finance_Company__r.BillingPostalCode : '';
    	this.DealFinanceEstimatedPayment = formatToDecimal((dealFinanceRec.Estimated_Payment__c != null) ? dealFinanceRec.Estimated_Payment__c : 0);
    	this.DealFinanceLoanPayments = formatToDecimal(getLoanTerm(dealFinanceRec));
        this.DealFinanceInterestRate = formatToDecimal((dealFinanceRec.Interest_Rate__c != null) ? dealFinanceRec.Interest_Rate__c : 0 );
        this.DealFinanceLoanTerm = formatToDecimal((dealFinanceRec.Loan_Term__c != null) ? dealFinanceRec.Loan_Term__c : 0 );
        this.DealFinancePaymentFrequency = dealFinanceRec.Payment_Frequency__c != null ? dealFinanceRec.Payment_Frequency__c : '';
        this.FinanceCompanyBillingAddressCityStateZipCode = (String.isNotBlank(this.FinanceCompanyBillingAddress1and2) ? this.FinanceCompanyBillingAddress1and2.trim().replace('\n','') + ' ' : '') + (String.isNotBlank(this.FinanceCompanyBillingCity) ? this.FinanceCompanyBillingCity + ' ' : '') + (String.isNotBlank(this.FinanceCompanyBillingState) ? this.FinanceCompanyBillingState + ' ' : '') + (String.isNotBlank(this.FinanceCompanyBillingZipCode) ? this.FinanceCompanyBillingZipCode : '');
        this.ProductDealFinanceEstimatedPaymentAndLoanTerm = formatToDecimal((String.isNotBlank(this.DealFinanceEstimatedPayment) ? Decimal.valueOf(this.DealFinanceEstimatedPayment.replaceAll(',','')) : 0) * (String.isNotBlank(this.DealFinanceLoanTerm) ? Decimal.valueOf(this.DealFinanceLoanTerm.replaceAll(',','')) : 0));
        this.FinanceCompanyBillingCityStateZipCode = this.FinanceCompanyBillingCity + ' ' + this.FinanceCompanyBillingState + ' ' + this.FinanceCompanyBillingZipCode;
        this.FinanceCompanyVendorTaxID = (dealFinanceRec.Finance_Company__r.Vendor_Tax_Id__c != null ? dealFinanceRec.Finance_Company__r.Vendor_Tax_Id__c : '');
        this.DealFinanceCommission = formatToDecimal((dealFinanceRec.Finance_Commission__c != null) ? dealFinanceRec.Finance_Commission__c : 0 );
	}
    
    public void setDealUnitFields(Deal_Item__c dealItemRec) {
        if(dealItemRec.Customer_Owned_Unit__c == null) {
            this.UnitMake = (dealItemRec.Unit_Make__c != null) ? dealItemRec.Unit_Make__r.Name : '';
            this.UnitModel = (dealItemRec.Unit_Model__c != null) ? dealItemRec.Unit_Model__r.Name__c : '';
            this.UnitSubModel = (dealItemRec.Sub_Model__c != null) ? dealItemRec.Sub_Model__r.Sub_Model_Name__c : '';
            this.UnitYear = dealItemRec.Year__c != null ? String.valueOf(dealItemRec.Year__c) : '';
            this.UnitVIN = '';
            this.UnitStockNumber = '';
            this.UnitExteriorColour = (dealItemRec.Colour__c != null) ? dealItemRec.Colour__c : '';
            this.UnitMakeModel = String.isNotBlank(this.UnitMake) ? this.UnitMake + ' ' + this.UnitModel : this.UnitModel;
            this.UnitRegistrationNumber = '';
            this.UnitComplianceDate = '';
        } else {
            this.UnitMake = (dealItemRec.Customer_Owned_Unit__r.Unit_Make__c != null) ? dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name : '';
            this.UnitModel = (dealItemRec.Customer_Owned_Unit__r.Unit_Model__c != null) ? dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
            this.UnitSubModel = (dealItemRec.Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
            this.UnitYear = dealItemRec.Customer_Owned_Unit__r.Year__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Year__c) : '';
            this.UnitStockNumber = dealItemRec.Customer_Owned_Unit__r.Stock_Id__c;
            this.UnitExteriorColour = (dealItemRec.Customer_Owned_Unit__r.Colour__c != null) ? dealItemRec.Customer_Owned_Unit__r.Colour__c : '';
            this.UnitInteriorColour = (dealItemRec.Customer_Owned_Unit__r.Interior_Colour__c != null) ? dealItemRec.Customer_Owned_Unit__r.Interior_Colour__c : '';
            this.UnitMakeModel = String.isNotBlank(this.UnitMake) ? this.UnitMake + ' ' + this.UnitModel : this.UnitModel;
            this.UnitRegistrationExpirydate = dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c) : '';
            this.UnitYearFirstREGO = dealItemRec.Customer_Owned_Unit__r.Year_Of_1st_Rego__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Year_Of_1st_Rego__c) : '';
            this.UnitRegistrationNumber = dealItemRec.Customer_Owned_Unit__r.Plate__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Plate__c) : '';
            this.UnitEngineSize = dealItemRec.Customer_Owned_Unit__r.Displacement__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Displacement__c) : '';
            this.UnitOtherNumber = dealItemRec.Customer_Owned_Unit__r.Other_Serial_No__c != null ? dealItemRec.Customer_Owned_Unit__r.Other_Serial_No__c : '';
            this.UnitEngineNumber = dealItemRec.Customer_Owned_Unit__r.Engine_Serial_No__c != null ? dealItemRec.Customer_Owned_Unit__r.Engine_Serial_No__c : '';
            this.UnitOtherData01 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_01__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_01__c : '';
            this.UnitOtherData02 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_02__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_02__c : '';
            this.UnitOtherData03 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_03__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_03__c : '';
            this.UnitOtherData04 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_04__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_04__c : '';
            this.UnitOtherData05 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_05__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_05__c : '';
            this.UnitOtherData06 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_06__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_06__c : '';
            this.UnitOtherData07 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_07__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_07__c : '';
            this.UnitOtherData11 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_11__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_11__c : '';
            this.UnitDateStockedin = dealItemRec.Customer_Owned_Unit__r.Date_Stocked_In__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Date_Stocked_In__c) : '';
            this.UnitOtherData08 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_08__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_08__c : '';
            this.UnitComplianceDate = dealItemRec.Customer_Owned_Unit__r.Compliance_Date__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Compliance_Date__c) : '';
            this.UnitNotes = dealItemRec.Customer_Owned_Unit__r.Notes__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Notes__c) : '';
            this.UnitCylinders = dealItemRec.Customer_Owned_Unit__r.Cylinders__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Cylinders__c) : '';
            this.UnitOtherData09 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_09__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_09__c : '';
            this.UnitOtherData10 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_10__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_10__c : '';
            this.UnitOtherData12 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_12__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_12__c : '';
            this.UnitOtherData13 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_13__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_13__c : '';
            this.UnitOtherData14 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_14__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_14__c : '';
            this.UnitDisplacement = dealItemRec.Customer_Owned_Unit__r.Displacement__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Displacement__c) : '';
            this.UnitModelDescription = (dealItemRec.Customer_Owned_Unit__r.Unit_Model__c != null) ? dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Model_Description__c : '';
            this.UnitSubModelDescription = (dealItemRec.Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Description__c : '';
            this.UnitConsignorName = (dealItemRec.Customer_Owned_Unit__r.Account__c != null) ? dealItemRec.Customer_Owned_Unit__r.Account__r.Name : '';
            this.UnitConsignorEmailAddress = (dealItemRec.Customer_Owned_Unit__r.Account__c != null) ? dealItemRec.Customer_Owned_Unit__r.Account__r.Email_Address__c : '';
            this.UnitConsignorBillingStreet = (dealItemRec.Customer_Owned_Unit__r.Account__c != null) ? dealItemRec.Customer_Owned_Unit__r.Account__r.BillingStreet : '';
            this.UnitConsignorBillingCity = (dealItemRec.Customer_Owned_Unit__r.Account__c != null) ? dealItemRec.Customer_Owned_Unit__r.Account__r.BillingCity : '';
            this.UnitConsignorBillingState = (dealItemRec.Customer_Owned_Unit__r.Account__c != null) ? dealItemRec.Customer_Owned_Unit__r.Account__r.BillingState : '';
            this.UnitConsignorPostalCode = (dealItemRec.Customer_Owned_Unit__r.Account__c != null) ? dealItemRec.Customer_Owned_Unit__r.Account__r.BillingPostalCode : '';
            this.UnitConsignorPhoneNumber = (dealItemRec.Customer_Owned_Unit__r.Account__c != null) ? dealItemRec.Customer_Owned_Unit__r.Account__r.Phone_Number__c : '';
            this.UnitConsignorOtherPhone = (dealItemRec.Customer_Owned_Unit__r.Account__c != null) ? dealItemRec.Customer_Owned_Unit__r.Account__r.Mobile__c : '';
            this.UnitManufacturedDate = (dealItemRec.Customer_Owned_Unit__r.Manufactured_Date__c != null) ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Manufactured_Date__c) : '';
            this.UnitManufacturedDateMonth = (dealItemRec.Customer_Owned_Unit__r.Manufactured_Date__c != null) ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Manufactured_Date__c.month()) : '';
            this.UnitManufacturedDateYear = (dealItemRec.Customer_Owned_Unit__r.Manufactured_Date__c != null) ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Manufactured_Date__c.year()) : '';
            this.UnitOtherData15 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_15__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_15__c : '';
            this.UnitRegistrationSerialNumber = dealItemRec.Customer_Owned_Unit__r.Registration_Serial__c != null ? dealItemRec.Customer_Owned_Unit__r.Registration_Serial__c : '';
            this.NewUnit = dealItemRec.Customer_Owned_Unit__r.New_Unit__c;
            this.UnitModelWithThirtyLetters = String.isNotBlank(this.UnitModel) ? (this.UnitModel.length() > 30 ? this.UnitModel.substring(0,30) : this.UnitModel) : '';
            this.OldUnit = !dealItemRec.Customer_Owned_Unit__r.New_Unit__c;
            
            setUnitMileageFields(dealItemRec.Mileage__c);
            setUnitVINFields(dealItemRec.Customer_Owned_Unit__r.VIN_Number__c);
        }
        this.MultiLineUnitMake = String.isNotBlank(this.UnitMake) ? this.UnitMake.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitModel = String.isNotBlank(this.UnitModel) ? this.UnitModel.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitSubModel = String.isNotBlank(this.UnitSubModel) ? this.UnitSubModel.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData01 = String.isNotBlank(this.UnitOtherData01) ? this.UnitOtherData01.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData02 = String.isNotBlank(this.UnitOtherData02) ? this.UnitOtherData02.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData03 = String.isNotBlank(this.UnitOtherData03) ? this.UnitOtherData03.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData04 = String.isNotBlank(this.UnitOtherData04) ? this.UnitOtherData04.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData05 = String.isNotBlank(this.UnitOtherData05) ? this.UnitOtherData05.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData06 = String.isNotBlank(this.UnitOtherData06) ? this.UnitOtherData06.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData07 = String.isNotBlank(this.UnitOtherData07) ? this.UnitOtherData07.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData08 = String.isNotBlank(this.UnitOtherData08) ? this.UnitOtherData08.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData09 = String.isNotBlank(this.UnitOtherData09) ? this.UnitOtherData09.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData10 = String.isNotBlank(this.UnitOtherData10) ? this.UnitOtherData10.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData11 = String.isNotBlank(this.UnitOtherData11) ? this.UnitOtherData11.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData12 = String.isNotBlank(this.UnitOtherData12) ? this.UnitOtherData12.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData13 = String.isNotBlank(this.UnitOtherData13) ? this.UnitOtherData13.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData14 = String.isNotBlank(this.UnitOtherData14) ? this.UnitOtherData14.replaceFirst(' ', '\n') : '';
        this.MultiLineUnitOtherData15 = String.isNotBlank(this.UnitOtherData15) ? this.UnitOtherData15.replaceFirst(' ', '\n') : '';

        this.UnitComplianceDateMonth01 = (this.UnitComplianceDate.length() > 0 ? this.UnitComplianceDate.subString(0, 1) : '');
        this.UnitComplianceDateMonth02 = (this.UnitComplianceDate.length() > 1 ? this.UnitComplianceDate.subString(1, 2) : '');
        this.UnitComplianceDateYear01 = (this.UnitComplianceDate.length() > 3 ? '2' : '');
        this.UnitComplianceDateYear02 = (this.UnitComplianceDate.length() > 3 ? '0' : '');
        this.UnitComplianceDateYear03 = (this.UnitComplianceDate.length() > 3 ? this.UnitComplianceDate.subString(3, 4) : '');
        this.UnitComplianceDateYear04 = (this.UnitComplianceDate.length() > 4 ? this.UnitComplianceDate.subString(4, 5) : '');
        this.UnitRegistrationExpiryMonth = dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c.month()) : '';
        this.UnitRegistrationExpiryDay =  dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c.day()) : '';
        this.UnitRegistrationExpiryYear = dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c.year()) : '';
        integer index = 0;
        UnitNotesGleeson = '';
        if(String.isNotBlank(UnitNotes)) {
            while (index < UnitNotes.length()) {
                if (UnitNotes.substring(index, Math.min(index + 50,UnitNotes.length())).Contains('\n')){
                    integer indexOfNewLine = UnitNotes.indexOf('\n',index);
                    UnitNotesGleeson  += UnitNotes.substring(index,indexOfNewLine) + '\n';
                    index = indexOfNewLine + 1;
                }
                else{
                    UnitNotesGleeson  += UnitNotes.substring(index, Math.min(index + 45,UnitNotes.length())) + '\n';
                    index += 45;
                }      
            }
        }  
        if(String.isNotBlank(UnitNotesGleeson)) {
          UnitNotesGleeson = UnitNotesGleeson.removeEnd('\n');
        }
        this.UnitDescription = this.UnitYear + ' ' + this.UnitMake + ' ' + this.UnitModel + ' ' + this.UnitSubModel;
        
        Decimal totalStampDutyDec = (dealItemRec.Stamp_Duty_Total__c != null) ? dealItemRec.Stamp_Duty_Total__c : 0;
        Decimal unitTotalBasePriceDec = 0;
        Decimal unitTotalFactoryOptionsDec = 0;
        Decimal unitTotalDealerInstalledOptionsDec = 0;
        Decimal unitTotalPriceWithTaxDec = 0;
        Decimal unitTotalSalesTax = 0;
        Decimal unitTotalPriceWithSalesTax = 0;
        
        for(Deal_Unit_Price_Cost__c dealUPCRec : dealItemRec.Deal_Unit_Prices_Costs__r){
            if(dealUPCRec.Type__c == 'Factory'){
                unitTotalFactoryOptionsDec += (dealUPCRec.Total_Price__c != null) ? dealUPCRec.Total_Price__c : 0;
            } else if(dealUPCRec.Type__c == 'Dealer') {
                unitTotalDealerInstalledOptionsDec += (dealUPCRec.Total_Price__c != null) ? dealUPCRec.Total_Price__c : 0;
            } else if(dealUPCRec.Type__c == 'Base') {
                unitTotalBasePriceDec += getBasePrice(dealUPCRec);
            }
            if(dealUPCRec.Sales_Tax_Percentage__c != null) {
                unitTotalSalesTax += (dealUPCRec.Qty__c * dealUPCRec.Price__c * dealUPCRec.Sales_Tax_Percentage__c)/100;
                unitTotalPriceWithTaxDec += ((dealUPCRec.Qty__c * dealUPCRec.Price__c)*(1 + dealUPCRec.Sales_Tax_Percentage__c/100));
            }
        }
        unitTotalSalesTax = unitTotalSalesTax.setScale(2, RoundingMode.HALF_UP);
        unitTotalPriceWithTaxDec = unitTotalPriceWithTaxDec.setScale(2, RoundingMode.HALF_UP);
        unitTotalPriceWithSalesTax = unitTotalPriceWithTaxDec;
        Decimal unitTotalPriceWithNonFeeOptionsDec = 0;
        Decimal unitTotalPriceDec = 0;
        Decimal unitPriceWithPartLabourDec = 0;
        Decimal unitTotalOptionsPartsDec = 0;
        Decimal unitTotalOptionsLabourDec = 0;
        Decimal unitTotalOptionsSubletDec = 0;
        Decimal unitTotalPriceWithoutOptionDec = 0;
        unitTotalPriceDec = unitPriceWithPartLabourDec = unitTotalPriceWithNonFeeOptionsDec = unitTotalPriceWithoutOptionDec = 
					(unitTotalBasePriceDec + unitTotalFactoryOptionsDec + unitTotalDealerInstalledOptionsDec + totalStampDutyDec).setScale(2, RoundingMode.HALF_UP);
				
        Integer untaggedFeeCounter = 0;
        Integer untaggedPartCounter = 0;
        
        Decimal uccFilingTagUnitFee = 0;
        Decimal unitFeeGasTagUnitFeeDec = 0;
        Decimal unitFeeLicTagUnitFeeDec = 0;
        Decimal unitFeeWARRUnitFeeDec = 0;
        Decimal unitFeeDOCTagUnitFee = 0;
	    Decimal unitFeeREGTagUnitFee = 0;
	    Decimal unitFeeINSTagUnitFee = 0;
        Decimal UnitTotalOptionsAndFeesDec = 0;
        decimal totalUnitFeeWithNoTag = 0;
        Decimal adminTagUnitFee = 0;
        Decimal unitFeeTITLETagUnitFee = 0;
		Decimal docCodeUnitFee = 0;
		Decimal tefCodeUnitFee = 0;
		Decimal warrCodeUnitFee = 0;
		Decimal frtCodeUnitFee = 0;
		Decimal pdiCodeUnitFee = 0;
		Decimal stateCodeUnitFee = 0;
        Decimal frtoutCodeUnitFee = 0;
        Decimal gapCodeUnitFee = 0;
        Decimal title_FeeCodeUnitFee = 0;
        Decimal escCodeUnitFee = 0;
        Decimal nintyDay_WarrantyFeeCodeUnitFee = 0;
        Decimal prepaid_MaintenanceFeeCodeUnitFee = 0;
        Decimal registrationFeeCodeUnitFee = 0;
        Decimal plateTransferFeeCodeUnitFee = 0;
        Decimal vinInspectionFeeCodeUnitFee = 0;
        Decimal vinTradeFeeCodeUnitFee = 0;
        String docCodeFeeName = '';
        String escCodeFeeName = '';
        String nintyDayWarrantyCodeFeeName = '';
        String prepaidMaintenanceCodeFeeName = '';
        Decimal discCodeUnitFee = 0;
        Decimal license1CodeUnitFee = 0;
        Decimal payableDeliveryUnitFee = 0;
        Decimal rebateCodeFeePrice = 0;
        Decimal unitFeeTRANTagUnitFee = 0;
        Decimal unitFeeLIENTagUnitFee = 0;
        Decimal unitFeePLATETagUnitFee = 0;
        Decimal dealerDeliveryUnitFee = 0;
        Decimal insuranceDealProduct = 0;
        Decimal consumerCreditInsurance = 0;
        Decimal processingCodeUnitFee = 0;
        Decimal iwsEWCodeUnitFee = 0;
        Decimal iwsEWOptionCodeUnitFee = 0;
        Decimal tregTagUnitFee = 0;
        Decimal locregTagUnitFee = 0;
        Decimal texregTagUnitFee = 0;
        Decimal btagTagUnitFee = 0;
        Decimal inspTagUnitFee = 0;
        Decimal procTagUnitFee = 0;
        Decimal hutTagUnitFee = 0;
        Decimal origTagUnitFee = 0;

        List<String> UnitOptionLaborCodeNameList = new List<String>();
        this.UnitOptionListing = '';
        boolean firstOccurrence = false;
        
        DealItem dealItemObj = new DealItem();
        for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
        	Decimal totalPrice = getOptionAndFeePrice(optionAndFeeRec);
            unitTotalPriceDec += totalPrice;
            UnitTotalOptionsAndFeesDec += totalPrice;
            if(optionAndFeeRec.Sales_Tax_Percentage__c != null){
                unitTotalSalesTax += (optionAndFeeRec.Qty__c * optionAndFeeRec.Price__c * optionAndFeeRec.Sales_Tax_Percentage__c)/100;
                unitTotalPriceWithTaxDec += ((optionAndFeeRec.Qty__c * optionAndFeeRec.Price__c)*(1 + optionAndFeeRec.Sales_Tax_Percentage__c/100));
            }
            this.UnitOptionListing += (optionAndFeeRec.Item_Code__c != null ? optionAndFeeRec.Item_Code__c : '') + '\t';
            this.UnitOptionListing += (optionAndFeeRec.Item_Description__c != null ? optionAndFeeRec.Item_Description__c : '') + '\t';
            this.UnitOptionListing += '$' + formatToDecimal(totalPrice) + '\n';

            if(!firstOccurrence && optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Description__c.contains('GAP')) {
                this.GAPCodeUnitFeeDescription = optionAndFeeRec.Product__r.Description__c;
                this.GAPVendorProductTerm = optionAndFeeRec.Product__r.Term__c != null ? String.valueOf(optionAndFeeRec.Product__r.Term__c) : '';
                this.GAPDescriptionPrice = formatToDecimal(optionAndFeeRec.Product__r.price__c);
                firstOccurrence = true;
            }
            
            if(optionAndFeeRec.Fee__c == null) {
            	unitTotalPriceWithNonFeeOptionsDec += totalPrice;

            	if(optionAndFeeRec.Part__c != null) {
	            	unitPriceWithPartLabourDec += totalPrice; 
                    if(String.isBlank(optionAndFeeRec.Part__r.Assigned_Tag_1__c) && String.isBlank(optionAndFeeRec.Part__r.Assigned_Tag_2__c)) {
                        setUnitPartWithNoTagFields(++untaggedPartCounter, optionAndFeeRec.Item_Description__c, totalPrice);
                    }  
	            }
                if(optionAndFeeRec.Labour_Code__c != null) {
	            	unitPriceWithPartLabourDec += totalPrice; 
                    UnitOptionLaborCodeNameList.add(optionAndFeeRec.Labour_Code__r.Name__c);
	            }
                if(optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Type__c == Constants.SUBLET) {
                    unitTotalOptionsSubletDec += totalPrice;
	            }
           
	            unitTotalOptionsPartsDec += (optionAndFeeRec.Part__c != null ? totalPrice : 0);
	            unitTotalOptionsLabourDec += (optionAndFeeRec.Labour_Code__c != null ? totalPrice : 0);
            } else if(optionAndFeeRec.Fee__c != null) {
				if(String.isNotBlank(optionAndFeeRec.Fee__r.Code__c)){
					if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('DOC')){
						docCodeUnitFee += totalPrice;
                        docCodeFeeName += optionAndFeeRec.Fee__r.Code__c;
					}
					if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('TEF')){
						tefCodeUnitFee += totalPrice;
					}
					if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('WARR')){
						warrCodeUnitFee += totalPrice;
					}
					if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('FRTUTV') || optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('FRTSXS') || optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('FRTATV') || optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('FRTUTV 22') || optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('FRTSXS 22') || optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('FRTATV 22')){
						frtCodeUnitFee += totalPrice;
					}
					if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('PDISXS') || optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('PDIATV')){
						pdiCodeUnitFee += totalPrice;
					}
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('State Fee') || optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('State Fees')){
                      stateCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('FRTOUT')){
                        frtoutCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('GAP')){
                        gapCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('Title Fee')){
                        title_FeeCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('ESC')){
                        escCodeUnitFee += totalPrice;
                        escCodeFeeName += optionAndFeeRec.Fee__r.Code__c;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('90 Day Warranty')){
                        nintyDay_WarrantyFeeCodeUnitFee += totalPrice;
                        nintyDayWarrantyCodeFeeName += optionAndFeeRec.Fee__r.Code__c;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('Prepaid Maintenance')){
                        prepaid_MaintenanceFeeCodeUnitFee += totalPrice;
                        prepaidMaintenanceCodeFeeName += optionAndFeeRec.Fee__r.Code__c;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('Registration Fee')){
                        registrationFeeCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('Plate Transfer')){
                        plateTransferFeeCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('VIN Inspection')){
                        vinInspectionFeeCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('VIN Trade')){
                        vinTradeFeeCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('DISC')){
                        discCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('License1')){
                        license1CodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('PAYABLE DELIVERY')){
                        payableDeliveryUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('Rebate')){
                        rebateCodeFeePrice += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('Del')){
                        dealerDeliveryUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('Processing')){
                        processingCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('IWS EW')){
                        iwsEWCodeUnitFee += totalPrice;
                    }
                    if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('IWS EW Option')){
                        iwsEWOptionCodeUnitFee += totalPrice;
                    }
                }
                
            	if(String.isBlank(optionAndFeeRec.Fee__r.Assigned_Tag_1__c) && String.isBlank(optionAndFeeRec.Fee__r.Assigned_Tag_2__c)) {
                    decimal unitFeePrice = GeneralConfiguration.getTaxIncludingPricing() ? optionAndFeeRec.Price_When_Tax_Included__c : optionAndFeeRec.Price__c;
                    totalUnitFeeWithNoTag += unitFeePrice;
                    setUnitFeeWithNoTagFields(++untaggedFeeCounter, optionAndFeeRec.Item_Description__c, unitFeePrice);
            	} else {
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'UCC') || 
                                                        dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'UCC')) {
                        uccFilingTagUnitFee += totalPrice;
                    }
			    	if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'GAS') || 
			    										dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'GAS')) {
			    		unitFeeGasTagUnitFeeDec += totalPrice;
			    	} 
			    	if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'LIC') || 
    													dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'LIC')) {
			    		unitFeeLicTagUnitFeeDec += totalPrice;
			    	} 
			    	if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'WARR') || 
			    										dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'WARR')) {
			    		unitFeeWARRUnitFeeDec += totalPrice;
			    	}
			        if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'DOC') || 
                              dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'DOC')) {
                        unitFeeDOCTagUnitFee += totalPrice;
            	    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'REG') || 
                                    dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'REG')) {
                        unitFeeREGTagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'INS') || 
                                    dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'INS')) {
                        unitFeeINSTagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'ADMIN') || 
                              dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'ADMIN')) {
                        adminTagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'TITLE') ||
                              dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'TITLE')){
                        unitFeeTITLETagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'TRAN') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'TRAN')) {
                        unitFeeTRANTagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'LIEN') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'LIEN')) {
                        unitFeeLIENTagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'PLATE') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'PLATE')) {
                        unitFeePLATETagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'TREG') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'TREG')) {
                        tregTagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'LOCREG') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'LOCREG')) {
                        locregTagUnitFee += totalPrice;
                    }
					if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'TEXREG') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'TEXREG')) {
                        texregTagUnitFee += totalPrice;
                    }
					if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'BTAG') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'BTAG')) {
                        btagTagUnitFee += totalPrice;
                    }
					if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'INSP') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'INSP')) {
                        inspTagUnitFee += totalPrice;
                    }
					if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'PROC') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'PROC')) {
                        procTagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'HUT') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'HUT')) {
                        hutTagUnitFee += totalPrice;
                    }
                    if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'ORIG') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'ORIG')) {
                        origTagUnitFee += totalPrice;
                    }
                }
            }
            if(optionAndFeeRec.Product__c != null && optionAndFeeRec.Product__r.Type__c == Constants.DEAL_PRODUCT) {
                consumerCreditInsurance += optionAndFeeRec.Product__r.Code__c.equalsIgnoreCase('Consumer Credit insurance') ? totalPrice : 0;
                insuranceDealProduct += optionAndFeeRec.Product__r.Code__c.equalsIgnoreCase('Insurance') ? totalPrice : 0;
            }
        }
        //Kit header
        List<String> kitList = new List<String>();
        for(Deal_Kit_Header__c dealKitRec : dealItemRec.Deal_Kit_Headers__r){
            kitList.add(dealKitRec.Code__c + '-' + dealKitRec.Description__c);
        }
        this.KitCodeAndDiscription = String.join(kitList, '\n');

        unitTotalPriceWithTaxDec = unitTotalPriceWithTaxDec.setScale(2, RoundingMode.HALF_UP);
        unitTotalSalesTax = unitTotalSalesTax.setScale(2, RoundingMode.HALF_UP);
        this.UnitInvoiceDate = dealItemRec.deal__r.Invoice_Number__c != null &&  dealItemRec.deal__r.Invoice_Number__r.Invoice_Date__c != null ?  BPUtility.getFormatedDateTime(dealItemRec.deal__r.Invoice_Number__r.Invoice_Date__c) : '';
        this.TotalStampduty = formatToDecimal(totalStampDutyDec);
        this.UnitTotalBasePrice = formatToDecimal(unitTotalBasePriceDec);
        this.UnitTotalFactoryOptions = formatToDecimal(unitTotalFactoryOptionsDec);
        this.UnitTotalDealerInstalledOptions = formatToDecimal(unitTotalDealerInstalledOptionsDec);
        this.UnitTotalPriceWithNonFeeOptions = formatToDecimal(unitTotalPriceWithNonFeeOptionsDec);
        this.UnitTotalPriceWithPartLabour = formatToDecimal(unitPriceWithPartLabourDec);
        this.UnitTotalPrice = formatToDecimal(unitTotalPriceWithoutOptionDec);
        this.UnitTotalSalesTax = formatToDecimal(unitTotalSalesTax);
        this.UnitTotalOptionsParts = formatToDecimal(unitTotalOptionsPartsDec);
        this.UnitTotalOptionsLabor = formatToDecimal(unitTotalOptionsLabourDec);
        this.UnitAllOptionLaborCodeName = string.join(UnitOptionLaborCodeNameList,',');
        this.UnitTotalOptionsPartsAndLabor = formatToDecimal(unitTotalOptionsPartsDec + unitTotalOptionsLabourDec);
        this.UnitTotalOptionsPartsLaborAndSublet = formatToDecimal(unitTotalOptionsPartsDec + unitTotalOptionsLabourDec + unitTotalOptionsSubletDec);
        this.UnitTotalOptionsPartsAndSublet = formatToDecimal(unitTotalOptionsPartsDec + unitTotalOptionsSubletDec);
        this.UnitFeeGasTagUnitFee = formatToDecimal(unitFeeGasTagUnitFeeDec);
        this.UnitFeeLicTagUnitFee = formatToDecimal(unitFeeLicTagUnitFeeDec);
        this.UnitFeeWARRUnitFee = formatToDecimal(unitFeeWARRUnitFeeDec);
		this.UnitFeeDOCTagUnitFee = formatToDecimal(unitFeeDOCTagUnitFee);
		this.UnitFeeREGTagUnitFee = formatToDecimal(unitFeeREGTagUnitFee);
		this.UnitFeeINSTagUnitFee = formatToDecimal(unitFeeINSTagUnitFee);
		this.DOCCodeUnitFee = formatToDecimal(docCodeUnitFee);
		this.TEFCodeUnitFee = formatToDecimal(tefCodeUnitFee);
		this.WARRCodeUnitFee = formatToDecimal(warrCodeUnitFee);
		this.FRTCodeUnitFee = formatToDecimal(frtCodeUnitFee);
		this.PDICodeUnitFee = formatToDecimal(pdiCodeUnitFee);
		this.StateCodeUnitFee = formatToDecimal(stateCodeUnitFee);
        this.FRTOUTCodeUnitFee = formatToDecimal(frtoutCodeUnitFee);
        this.ADMINTagUnitFee = formatToDecimal(adminTagUnitFee);
        this.UnitFeeTITLETagUnitFee = formatToDecimal(unitFeeTITLETagUnitFee);
        this.GAPCodeUnitFee = formatToDecimal(gapCodeUnitFee);
        this.Title_FeeCodeUnitFee = formatToDecimal(title_FeeCodeUnitFee);
        this.ESCCodeUnitFee = formatToDecimal(escCodeUnitFee);
        this.NintyDay_WarrantyFeeCodeUnitFee = formatToDecimal(nintyDay_WarrantyFeeCodeUnitFee);
        this.Prepaid_MaintenanceFeeCodeUnitFee = formatToDecimal(prepaid_MaintenanceFeeCodeUnitFee);
        this.RegistrationFeeCodeUnitFee = formatToDecimal(registrationFeeCodeUnitFee);
        this.PlateTransferFeeCodeUnitFee = formatToDecimal(plateTransferFeeCodeUnitFee);
        this.VINInspectionFeeCodeUnitFee = formatToDecimal(vinInspectionFeeCodeUnitFee);
        this.VINTradeFeeCodeUnitFee = formatToDecimal(vinTradeFeeCodeUnitFee);
        this.DISCCodeUnitFee = formatToDecimal(discCodeUnitFee);
        this.UnitTotalPricePlusOptionsTax =  GeneralConfiguration.getTaxIncludingPricing() ? formatToDecimal(unitTotalPriceDec) : formatToDecimal(unitTotalPriceWithTaxDec);
        this.UnitTotalOptionsAndFees = formatToDecimal(UnitTotalOptionsAndFeesDec);
        this.UnitTotalPriceWithAllOptions = formatToDecimal(unitTotalPriceWithoutOptionDec + UnitTotalOptionsAndFeesDec);
        this.WarrantyAndNoTagFeeUnitTotal = formatToDecimal(unitPriceWithPartLabourDec + unitFeeWARRUnitFeeDec + totalUnitFeeWithNoTag);
		this.UnitTotalPriceLaborRegInsTagFee = formatToDecimal(unitTotalPriceWithoutOptionDec + unitTotalOptionsLabourDec + unitFeeREGTagUnitFee + unitFeeINSTagUnitFee);
        this.SumOfBasePriceSalesTaxAndDOCFee = formatToDecimal(unitTotalBasePriceDec + unitTotalSalesTax + docCodeUnitFee);
        this.SumOfRegistrationPlateTransferVINInspectionAndVINTrade = formatToDecimal(registrationFeeCodeUnitFee + PlateTransferFeeCodeUnitFee + vinInspectionFeeCodeUnitFee + vinTradeFeeCodeUnitFee);
        this.DOCCodeFeeName = docCodeFeeName;
        this.ESCCodeFeeName = escCodeFeeName;
        this.NintyDayWarrantyCodeFeeName = nintyDayWarrantyCodeFeeName;
        this.PrepaidMaintenanceCodeFeeName = prepaidMaintenanceCodeFeeName;
        this.License1CodeUnitFee = formatToDecimal(license1CodeUnitFee);
        this.PayableDeliveryUnitFee = formatToDecimal(payableDeliveryUnitFee);
        this.RebateCodeFeePrice = formatToDecimal(rebateCodeFeePrice);
        this.UnitFeeTRANTagUnitFee = formatToDecimal(unitFeeTRANTagUnitFee);
        this.UnitFeeLIENTagUnitFee = formatToDecimal(unitFeeLIENTagUnitFee);
        this.PLATETagUnitFee = formatToDecimal(unitFeePLATETagUnitFee);
        this.UCCFilingTagUnitFee = formatToDecimal(uccFilingTagUnitFee);
        this.UnitTotalPriceWithSalesTax = formatToDecimal(unitTotalPriceWithSalesTax);
        this.DealerDeliveryUnitFee = formatToDecimal(dealerDeliveryUnitFee);
        this.InsuranceDealProduct = formatToDecimal(insuranceDealProduct);
        this.ConsumerCreditInsurance = formatToDecimal(consumerCreditInsurance);
        this.ProcessingCodeUnitFee = formatToDecimal(processingCodeUnitFee);
        this.IWSEWCodeUnitFee = formatToDecimal(iwsEWCodeUnitFee);
        this.IWSEWOptionCodeUnitFee = formatToDecimal(iwsEWOptionCodeUnitFee);
        this.UnitTotalWithFactoryDealerInstalledAndPartOptions = formatToDecimal(unitTotalBasePriceDec + unitTotalFactoryOptionsDec + unitTotalDealerInstalledOptionsDec + unitTotalOptionsPartsDec);
        this.SumOftotalUnitFeeWithNoTagAndStampDuty = formatToDecimal(totalUnitFeeWithNoTag + totalStampDutyDec);
        this.TREGTagUnitFee = formatToDecimal(tregTagUnitFee);
        this.LOCREGTagUnitFee = formatToDecimal(locregTagUnitFee);
        this.TEXREGTagUnitFee = formatToDecimal(texregTagUnitFee);
        this.BTAGTagUnitFee = formatToDecimal(btagTagUnitFee);
        this.INSPTagUnitFee = formatToDecimal(inspTagUnitFee);
        this.PROCTagUnitFee = formatToDecimal(procTagUnitFee);
        this.HUTTagUnitFee = formatToDecimal(hutTagUnitFee);
        this.ORIGTagUnitFee = formatToDecimal(origTagUnitFee);
        this.SumOfDOCAndORIGTagUnitFee = formatToDecimal(unitFeeDOCTagUnitFee + origTagUnitFee);
    }
	
    public void setAllDealUnitFields(List<Deal_Item__c> dealItemRecords) {
        Decimal DealTotalPartsAndLaborAmountTemp = 0;
		Decimal dealTotalPartLaborAndFee = 0;
		Decimal dealTotalOptionPart = 0;
		Decimal dealTotalOptionLabor = 0;
		Decimal dealTotalFee = 0;
        Decimal dealRideAwayPrice = 0;
		List<String> dealPartFeeDescriptionList = new List<String>();
	    Decimal dealTotalUnitAmount = 0;
        Decimal allUnitsDOCTagUnitFee = 0;
        Decimal allUnitsLOCREGTagUnitFee = 0;
        Decimal allUnitsTEXREGTagUnitFee = 0;
        Decimal allUnitsBTAGTagUnitFee = 0;
        Decimal allUnitsINSPTagUnitFee = 0;
        Decimal allUnitsPROCTagUnitFee = 0;
        Decimal allUnitsTITLETagUnitFee = 0;
        Decimal allUnitsFRTOUTCodeUnitFee = 0;

        DealItem dealItemObj = new DealItem();
        for(Deal_Item__c  dealItemRec : dealItemRecords) {
            Decimal unitTotalOptionsParts = 0;
            Decimal unitTotalOptionsLabour = 0;
			Decimal unitTotalOptionFee = 0;
            for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
                Decimal totalPrice = getOptionAndFeePrice(optionAndFeeRec);
                unitTotalOptionsParts += (optionAndFeeRec.Part__c != null ? totalPrice : 0);
                unitTotalOptionsLabour += (optionAndFeeRec.Labour_Code__c != null ? totalPrice : 0);
                if(optionAndFeeRec.Fee__c != null || optionAndFeeRec.Part__c != null){
                    dealPartFeeDescriptionList.add(optionAndFeeRec.Item_Code__c+'-'+optionAndFeeRec.Item_Description__c);
                }
                if(optionAndFeeRec.Fee__c != null) {
                    unitTotalOptionFee += GeneralConfiguration.getTaxIncludingPricing() ? optionAndFeeRec.Price_When_Tax_Included__c : optionAndFeeRec.Price__c;
                    if(String.isNotBlank(optionAndFeeRec.Fee__r.Assigned_Tag_1__c) || String.isNotBlank(optionAndFeeRec.Fee__r.Assigned_Tag_2__c)) {
                        if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'DOC') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'DOC')) {
                            allUnitsDOCTagUnitFee += totalPrice;
                        }
                        if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'LOCREG') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'LOCREG')) {
                            allUnitsLOCREGTagUnitFee += totalPrice;
                        }
						if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'TEXREG') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'TEXREG')) {
                            allUnitsTEXREGTagUnitFee += totalPrice;
                        }
						if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'BTAG') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'BTAG')) {
                            allUnitsBTAGTagUnitFee += totalPrice;
                        }
						if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'INSP') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'INSP')) {
                            allUnitsINSPTagUnitFee += totalPrice;
                        }
						if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'PROC') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'PROC')) {
                            allUnitsPROCTagUnitFee += totalPrice;
                        }
						if(dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_1__c, 'TITLE') || dealItemObj.isRequiredTagExistOnFee(optionAndFeeRec.Fee__r.Assigned_Tag_2__c, 'TITLE')) {
                            allUnitsTITLETagUnitFee += totalPrice;
                        }
                    }
                    if(String.isNotBlank(optionAndFeeRec.Fee__r.Code__c)){
                        if(optionAndFeeRec.Fee__r.Code__c.equalsIgnoreCase('FRTOUT')){
                            allUnitsFRTOUTCodeUnitFee += totalPrice;
                        }
                    }
                }
            }
			dealTotalOptionPart += unitTotalOptionsParts;
			dealTotalOptionLabor += unitTotalOptionsLabour;
			dealTotalFee += unitTotalOptionFee;
			dealTotalPartLaborAndFee += unitTotalOptionsParts + unitTotalOptionsLabour + unitTotalOptionFee;
            DealTotalPartsAndLaborAmountTemp += unitTotalOptionsParts + unitTotalOptionsLabour;

	        if(String.isNotBlank(dealItemRec.Type__c) && dealItemRec.Type__c == 'Unit'){
	    	    for(Deal_Unit_Price_Cost__c dupcRecord : dealItemRec.Deal_Unit_Prices_Costs__r){
			        if(dupcRecord.Type__c == 'Factory' || dupcRecord.Type__c == 'Dealer'){
				        dealTotalUnitAmount += (dupcRecord.Total_Price__c != null) ? dupcRecord.Total_Price__c : 0;
			        } else if(dupcRecord.Type__c == 'Base') {
				        dealTotalUnitAmount += getBasePrice(dupcRecord);
			        }
		        }
	        }
            dealRideAwayPrice += dealItemRec.Rideaway_Pricing_Total__c != null ? dealItemRec.Rideaway_Pricing_Total__c : 0;
        }
        this.DealPartAndFee = string.join(dealPartFeeDescriptionList,'\n');
		this.DealTotalOptionsParts = formatToDecimal(dealTotalOptionPart);
		this.DealTotalOptionsLabor = formatToDecimal(dealTotalOptionLabor);
		this.DealTotalFee = formatToDecimal(dealTotalFee);
		this.DealTotalPartLaborAndFee = formatToDecimal(dealTotalPartLaborAndFee);
        this.DealTotalPartsAndLaborAmount = formatToDecimal(DealTotalPartsAndLaborAmountTemp);
	    this.DealTotalUnitAmount = formatToDecimal(dealTotalUnitAmount);
        this.DealRideAwayPrice = formatToDecimal(dealRideAwayPrice);
        for(String dealPartFeeDescriptionItem : dealPartFeeDescriptionList){
            integer index = 0;
            if(String.isNotBlank(dealPartFeeDescriptionItem)){
                while (index < dealPartFeeDescriptionItem.length()){
                    DealPartAndFeeFarnleysYamaha += dealPartFeeDescriptionItem.substring(index, Math.min(index + 40,dealPartFeeDescriptionItem.length())) + '\n';
                    index += 40;
                }
            }
        }
        if(String.isNotBlank(DealPartAndFeeFarnleysYamaha)) {
          DealPartAndFeeFarnleysYamaha = DealPartAndFeeFarnleysYamaha.removeEnd('\n');
        }
        this.AllUnitsDOCTagUnitFee = formatToDecimal(allUnitsDOCTagUnitFee);
        this.SecondUnitVIN = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.VIN_Number__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.VIN_Number__c : '';
        this.SecondUnitMake = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Make__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Make__r.Name : '';
        this.SecondUnitModel = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Model__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
        this.SecondUnitSubModel = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
        this.SecondUnitYear = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Year__c != null) ? String.valueOf(dealItemRecords[1].Customer_Owned_Unit__r.Year__c) : '';
        this.SecondUnitStockNumber = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Stock_Id__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Stock_Id__c:'';
        this.SecondUnitTotalPrice = (dealItemRecords.size() > 1 ? setUnitTotalPrices(dealItemRecords[1]): '0');
        this.SecondUnitRegistrationNumber = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Plate__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Plate__c : '';
        this.SecondUnitEngineNumber = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Engine_Serial_No__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Engine_Serial_No__c : '';
        this.SecondUnitOtherData01 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_01__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_01__c : '';
        this.SecondUnitExteriorColour = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Colour__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Colour__c : '';
        this.SecondUnitOdometer = (dealItemRecords.size() > 1 && String.valueOf(dealItemRecords[1].Mileage__c) != null) ? String.valueOf(dealItemRecords[1].Mileage__c) : '';
        this.SecondUnitYearFirstREGO = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Year_Of_1st_Rego__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Year_Of_1st_Rego__c : '';
        this.SecondUnitComplianceDate = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Compliance_Date__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Compliance_Date__c : '';
        this.SecondUnitRegistrationExpirydate = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Reg_Expiry_Date__c != null) ?  String.valueOf(dealItemRecords[1].Customer_Owned_Unit__r.Reg_Expiry_Date__c) : '';
        this.SecondUnitTotalStampDuty = (dealItemRecords.size() > 1 && dealItemRecords[1].Stamp_Duty_Total__c != null) ? formatToDecimal(dealItemRecords[1].Stamp_Duty_Total__c) : '0';
        //Second Unit Multiline Unit Make, Unit Model, and Unit Sub Model
        this.MultiLineSecondUnitMake = String.isNotBlank(this.SecondUnitMake) ? this.SecondUnitMake.replaceFirst(' ', '\n') : '';
        this.MultiLineSecondUnitModel = String.isNotBlank(this.SecondUnitModel) ? this.SecondUnitModel.replaceFirst(' ', '\n') : '';
        this.MultiLineSecondUnitSubModel = String.isNotBlank(this.SecondUnitSubModel) ? this.SecondUnitSubModel.replaceFirst(' ', '\n') : '';
        this.ThirdUnitVIN = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.VIN_Number__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.VIN_Number__c : '';
        this.ThirdUnitMake = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Make__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Make__r.Name : '';
        this.ThirdUnitModel = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Model__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
        this.ThirdUnitSubModel = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
        this.ThirdUnitYear = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Year__c != null) ? String.valueOf(dealItemRecords[2].Customer_Owned_Unit__r.Year__c) : '';
        this.ThirdUnitStockNumber = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Stock_Id__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Stock_Id__c:'';
        this.ThirdUnitTotalPrice = (dealItemRecords.size() > 2 ? setUnitTotalPrices(dealItemRecords[2]): '0');
        //Third Unit Multiline Unit Make, Unit Model, and Unit Sub Model
        this.MultiLineThirdUnitMake = String.isNotBlank(this.ThirdUnitMake) ? this.ThirdUnitMake.replaceFirst(' ', '\n') : '';
        this.MultiLineThirdUnitModel = String.isNotBlank(this.ThirdUnitModel) ? this.ThirdUnitModel.replaceFirst(' ', '\n') : '';
        this.MultiLineThirdUnitSubModel = String.isNotBlank(this.ThirdUnitSubModel) ? this.ThirdUnitSubModel.replaceFirst(' ', '\n') : '';
        this.FourthUnitVIN = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.VIN_Number__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.VIN_Number__c : '';
        this.FourthUnitMake = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Make__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Make__r.Name : '';
        this.FourthUnitModel = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Model__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
        this.FourthUnitSubModel = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
        this.FourthUnitYear = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Year__c != null) ? String.valueOf(dealItemRecords[3].Customer_Owned_Unit__r.Year__c) : '';
        this.FourthUnitStockNumber = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Stock_Id__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Stock_Id__c:'';
        this.FourthUnitTotalPrice = (dealItemRecords.size() > 3 ? setUnitTotalPrices(dealItemRecords[3]): '0');
        //Fourth Unit Multiline Unit Make, Unit Model, and Unit Sub Model
        this.MultiLineFourthUnitMake = String.isNotBlank(this.FourthUnitMake) ? this.FourthUnitMake.replaceFirst(' ', '\n') : '';
        this.MultiLineFourthUnitModel = String.isNotBlank(this.FourthUnitModel) ? this.FourthUnitModel.replaceFirst(' ', '\n') : '';
        this.MultiLineFourthUnitSubModel = String.isNotBlank(this.FourthUnitSubModel) ? this.FourthUnitSubModel.replaceFirst(' ', '\n') : '';
        this.FifthUnitVIN = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.VIN_Number__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.VIN_Number__c : '';
        this.FifthUnitMake = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Make__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Make__r.Name : '';
        this.FifthUnitModel = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Model__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
        this.FifthUnitSubModel = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
        //Fifth Unit Multiline Unit Make, Unit Model, and Unit Sub Model
        this.MultiLineFifthUnitMake = String.isNotBlank(this.FifthUnitMake) ? this.FifthUnitMake.replaceFirst(' ', '\n') : '';
        this.MultiLineFifthUnitModel = String.isNotBlank(this.FifthUnitModel) ? this.FifthUnitModel.replaceFirst(' ', '\n') : '';
        this.MultiLineFifthUnitSubModel = String.isNotBlank(this.FifthUnitSubModel) ? this.FifthUnitSubModel.replaceFirst(' ', '\n') : '';
        this.FifthUnitYear = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Year__c != null) ? String.valueOf(dealItemRecords[4].Customer_Owned_Unit__r.Year__c) : '';
        this.FifthUnitStockNumber = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Stock_Id__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Stock_Id__c:'';
        this.FifthUnitTotalPrice = (dealItemRecords.size() > 4 ? setUnitTotalPrices(dealItemRecords[4]): '0');
        this.SecondUnitOtherData02 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_02__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_02__c : '';
        this.SecondUnitOtherData03 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_03__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_03__c : '';
        this.SecondUnitOtherData04 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_04__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_04__c : '';
        this.SecondUnitOtherData05 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_05__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_05__c : '';
        this.SecondUnitOtherData06 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_06__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_06__c : '';
        this.SecondUnitOtherData07 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_07__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_07__c : '';
        this.SecondUnitOtherData08 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_08__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_08__c : '';
        this.SecondUnitOtherData09 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_09__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_09__c : '';
        this.SecondUnitOtherData10 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_10__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_10__c : '';
        this.SecondUnitOtherData11 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_11__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_11__c : '';
        this.SecondUnitOtherData12 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_12__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_12__c : '';
        this.SecondUnitOtherData13 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_13__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_13__c : '';
        this.SecondUnitOtherData14 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_14__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_14__c : '';
        this.SecondUnitOtherData15 = (dealItemRecords.size() > 1 && dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_15__c != null) ? dealItemRecords[1].Customer_Owned_Unit__r.Unit_Data_15__c : '';
        this.ThirdUnitOtherData01 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_01__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_01__c : '';
        this.ThirdUnitOtherData02 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_02__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_02__c : '';
        this.ThirdUnitOtherData03 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_03__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_03__c : '';
        this.ThirdUnitOtherData04 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_04__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_04__c : '';
        this.ThirdUnitOtherData05 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_05__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_05__c : '';
        this.ThirdUnitOtherData06 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_06__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_06__c : '';
        this.ThirdUnitOtherData07 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_07__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_07__c : '';
        this.ThirdUnitOtherData08 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_08__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_08__c : '';
        this.ThirdUnitOtherData09 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_09__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_09__c : '';
        this.ThirdUnitOtherData10 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_10__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_10__c : '';
        this.ThirdUnitOtherData11 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_11__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_11__c : '';
        this.ThirdUnitOtherData12 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_12__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_12__c : '';
        this.ThirdUnitOtherData13 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_13__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_13__c : '';
        this.ThirdUnitOtherData14 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_14__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_14__c : '';
        this.ThirdUnitOtherData15 = (dealItemRecords.size() > 2 && dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_15__c != null) ? dealItemRecords[2].Customer_Owned_Unit__r.Unit_Data_15__c : '';
        this.FourthUnitOtherData01 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_01__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_01__c : '';
        this.FourthUnitOtherData02 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_02__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_02__c : '';
        this.FourthUnitOtherData03 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_03__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_03__c : '';
        this.FourthUnitOtherData04 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_04__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_04__c : '';
        this.FourthUnitOtherData05 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_05__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_05__c : '';
        this.FourthUnitOtherData06 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_06__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_06__c : '';
        this.FourthUnitOtherData07 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_07__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_07__c : '';
        this.FourthUnitOtherData08 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_08__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_08__c : '';
        this.FourthUnitOtherData09 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_09__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_09__c : '';
        this.FourthUnitOtherData10 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_10__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_10__c : '';
        this.FourthUnitOtherData11 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_11__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_11__c : '';
        this.FourthUnitOtherData12 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_12__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_12__c : '';
        this.FourthUnitOtherData13 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_13__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_13__c : '';
        this.FourthUnitOtherData14 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_14__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_14__c : '';
        this.FourthUnitOtherData15 = (dealItemRecords.size() > 3 && dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_15__c != null) ? dealItemRecords[3].Customer_Owned_Unit__r.Unit_Data_15__c : '';
        this.FifthUnitOtherData01 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_01__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_01__c : '';
        this.FifthUnitOtherData02 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_02__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_02__c : '';
        this.FifthUnitOtherData03 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_03__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_03__c : '';
        this.FifthUnitOtherData04 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_04__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_04__c : '';
        this.FifthUnitOtherData05 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_05__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_05__c : '';
        this.FifthUnitOtherData06 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_06__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_06__c : '';
        this.FifthUnitOtherData07 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_07__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_07__c : '';
        this.FifthUnitOtherData08 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_08__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_08__c : '';
        this.FifthUnitOtherData09 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_09__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_09__c : '';
        this.FifthUnitOtherData10 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_10__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_10__c : '';
        this.FifthUnitOtherData11 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_11__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_11__c : '';
        this.FifthUnitOtherData12 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_12__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_12__c : '';
        this.FifthUnitOtherData13 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_13__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_13__c : '';
        this.FifthUnitOtherData14 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_14__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_14__c : '';
        this.FifthUnitOtherData15 = (dealItemRecords.size() > 4 && dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_15__c != null) ? dealItemRecords[4].Customer_Owned_Unit__r.Unit_Data_15__c : '';
        this.AllUnitsLOCREGTagUnitFee = formatToDecimal(allUnitsLOCREGTagUnitFee);
        this.AllUnitsTEXREGTagUnitFee = formatToDecimal(allUnitsTEXREGTagUnitFee);
        this.AllUnitsBTAGTagUnitFee = formatToDecimal(allUnitsBTAGTagUnitFee);
        this.AllUnitsINSPTagUnitFee = formatToDecimal(allUnitsINSPTagUnitFee);
        this.AllUnitsPROCTagUnitFee = formatToDecimal(allUnitsPROCTagUnitFee);
        this.AllUnitsTITLETagUnitFee = formatToDecimal(allUnitsTITLETagUnitFee);
        this.AllUnitsFRTOUTCodeUnitFee = formatToDecimal(allUnitsFRTOUTCodeUnitFee);
    }

    private String setUnitTotalPrices(Deal_Item__c dealItemRec){
        Decimal unitTotalPrice = (dealItemRec.Stamp_Duty_Total__c != null) ? dealItemRec.Stamp_Duty_Total__c : 0;
        for(Deal_Unit_Price_Cost__c dealUPCRec : dealItemRec.Deal_Unit_Prices_Costs__r){
            if(dealUPCRec.Type__c == 'Factory'){
                unitTotalPrice += (dealUPCRec.Total_Price__c != null) ? dealUPCRec.Total_Price__c : 0;
            } else if(dealUPCRec.Type__c == 'Dealer') {
                unitTotalPrice += (dealUPCRec.Total_Price__c != null) ? dealUPCRec.Total_Price__c : 0;
            } else if(dealUPCRec.Type__c == 'Base') {
                unitTotalPrice += getBasePrice(dealUPCRec);
            }
        }
        return String.valueOf(unitTotalPrice.setScale(2, RoundingMode.HALF_UP));
    }

	public void setFirstFiveOptionFeeAndPart(List<Deal_Item__c> dealItemRecords){
		List<String> dealPartFeeDescriptionList = new List<String>();
		List<String> dealPartAndFeePriceList = new List<STring>();
		List<String> dealPartDescriptionList = new List<String>();
        List<String> dealPartPriceList = new List<STring>();
        Decimal totalDealPartPrice = 0;

		for(Deal_Item__c  dealItemRec : dealItemRecords) {
			for(Option_Fee__c optionAndFeeRec : dealItemRec.Options_Fees__r) {
				String dealPartAndFeePrice = '';
                if(optionAndFeeRec.Fee__c != null || optionAndFeeRec.Part__c != null){
                    dealPartFeeDescriptionList.add(optionAndFeeRec.Item_Code__c+'-'+optionAndFeeRec.Item_Description__c);
                    dealPartAndFeePrice = GeneralConfiguration.getTaxIncludingPricing() ? String.valueOf((optionAndFeeRec.Price_When_Tax_Included__c*optionAndFeeRec.Qty__c).setScale(2, RoundingMode.HALF_UP)) : String.valueOf((optionAndFeeRec.Price__c*optionAndFeeRec.Qty__c).setScale(2, RoundingMode.HALF_UP));
					dealPartAndFeePriceList.add(dealPartAndFeePrice);
                }
                if(optionAndFeeRec.Part__c != null){
                    dealPartDescriptionList.add(optionAndFeeRec.Item_Code__c+'-'+optionAndFeeRec.Item_Description__c);
                    String dealPartPrice = GeneralConfiguration.getTaxIncludingPricing() ? String.valueOf((optionAndFeeRec.Price_When_Tax_Included__c*optionAndFeeRec.Qty__c).setScale(2, RoundingMode.HALF_UP)) : String.valueOf((optionAndFeeRec.Price__c*optionAndFeeRec.Qty__c).setScale(2, RoundingMode.HALF_UP));
                    dealPartPriceList.add(dealPartPrice);
                    totalDealPartPrice += (String.isNotBlank(dealPartPrice) ? Decimal.valueOf(dealPartPrice.replaceAll(',','')) : 0);
                }
			}
		}
        this.TotalDealPartPrice = formatToDecimal(totalDealPartPrice);
        this.DealPartDescriptionList = string.join(dealPartDescriptionList,'\n');
        this.DealPartPriceList = string.join(dealPartPriceList,'\n');

		if(dealPartFeeDescriptionList.size() > 0){
			this.DealPartAndFeeName1 = dealPartFeeDescriptionList.get(0);
			this.DealPartAndFeePrice1 = dealPartAndFeePriceList.get(0);
		}
		if(dealPartFeeDescriptionList.size() > 1){
			this.DealPartAndFeeName2 = dealPartFeeDescriptionList.get(1);
			this.DealPartAndFeePrice2 = dealPartAndFeePriceList.get(1);
		}
		if(dealPartFeeDescriptionList.size() > 2){
			this.DealPartAndFeeName3 = dealPartFeeDescriptionList.get(2);
			this.DealPartAndFeePrice3 = dealPartAndFeePriceList.get(2);
		}
		if(dealPartFeeDescriptionList.size() > 3){
			this.DealPartAndFeeName4 = dealPartFeeDescriptionList.get(3);
			this.DealPartAndFeePrice4 = dealPartAndFeePriceList.get(3);
		}
		if(dealPartFeeDescriptionList.size() > 4){
			this.DealPartAndFeeName5 = dealPartFeeDescriptionList.get(4);
			this.DealPartAndFeePrice5 = dealPartAndFeePriceList.get(4);
		}
        if(dealPartFeeDescriptionList.size() > 5){
            this.DealPartAndFeeName6 = dealPartFeeDescriptionList.get(5);
            this.DealPartAndFeePrice6 = dealPartAndFeePriceList.get(5);
        }
    }

    public void setDealTradeInFields(Deal_Item__c dealItemRec) {
    	if(dealItemRec.Customer_Owned_Unit__c == null) {
            this.TradeInUnitMake = (dealItemRec.Unit_Make__c != null) ? dealItemRec.Unit_Make__r.Name : '';
            this.TradeInUnitModel = (dealItemRec.Unit_Model__c != null) ? dealItemRec.Unit_Model__r.Name__c : '';
            this.TradeInUnitSubModel = (dealItemRec.Sub_Model__c != null) ? dealItemRec.Sub_Model__r.Sub_Model_Name__c : '';
            this.TradeInUnitYear = dealItemRec.Year__c != null ? String.valueOf(dealItemRec.Year__c) : '';
            this.TradeInUnitVIN = '';
            this.TradeInUnitExteriorColour = (dealItemRec.Colour__c != null) ? dealItemRec.Colour__c : '';
            this.TradeInUnitEngineNumber = '';
			this.TradeInUnitStockNumber = '';			
        } else {
            this.TradeInUnitMake = (dealItemRec.Customer_Owned_Unit__r.Unit_Make__c != null) ? dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name : '';
            this.TradeInUnitModel = (dealItemRec.Customer_Owned_Unit__r.Unit_Model__c != null) ? dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
            this.TradeInUnitSubModel = (dealItemRec.Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
            this.TradeInUnitYear = dealItemRec.Customer_Owned_Unit__r.Year__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Year__c) : '';
            this.TradeInUnitExteriorColour = (dealItemRec.Customer_Owned_Unit__r.Colour__c != null) ? dealItemRec.Customer_Owned_Unit__r.Colour__c : '';
            this.TradeInUnitEngineSize = dealItemRec.Customer_Owned_Unit__r.Displacement__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Displacement__c) : '';
            this.TradeInUnitYearFirstREGO = dealItemRec.Customer_Owned_Unit__r.Year_Of_1st_Rego__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Year_Of_1st_Rego__c) : '';
            this.TradeInUnitOtherNumber = dealItemRec.Customer_Owned_Unit__r.Other_Serial_No__c != null ? dealItemRec.Customer_Owned_Unit__r.Other_Serial_No__c : '';
			this.TradeInUnitOtherData01 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_01__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_01__c : '';
            this.TradeInUnitRegistriationNumber = dealItemRec.Customer_Owned_Unit__r.Plate__c != null ? dealItemRec.Customer_Owned_Unit__r.Plate__c : '';
            this.TradeInUnitRegistrationExpirydate = dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c) : '';
            this.TradeInUnitEngineNumber = dealItemRec.Customer_Owned_Unit__r.Engine_Serial_No__c != null ? dealItemRec.Customer_Owned_Unit__r.Engine_Serial_No__c : '';
			this.TradeInUnitStockNumber = dealItemRec.Customer_Owned_Unit__r.Stock_Id__c;
            this.TradeInUnitOtherData03 = dealItemRec.Customer_Owned_Unit__r.Unit_Data_03__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Data_03__c : '';
            this.TradeInRegistrationSerialNumber = dealItemRec.Customer_Owned_Unit__r.Registration_Serial__c != null ? dealItemRec.Customer_Owned_Unit__r.Registration_Serial__c : '';
            
	        setTradeInUnitMileageFields(dealItemRec.Mileage__c);
            setTradeInUnitVINFields(dealItemRec.Customer_Owned_Unit__r.VIN_Number__c);
        }
        this.TradeInUnitDescription = this.TradeInUnitYear + ' ' + this.TradeInUnitMake + ' ' + this.TradeInUnitModel + ' ' + this.TradeInUnitSubModel;
        this.TradeInUnitYear01 = this.TradeInUnitYear.length() > 0 ? this.TradeInUnitYear.subString(0, 1) : '';
        this.TradeInUnitYear02 = this.TradeInUnitYear.length() > 1 ? this.TradeInUnitYear.subString(1, 2) : '';
        this.TradeInUnitYear03 = this.TradeInUnitYear.length() > 2 ? this.TradeInUnitYear.subString(2, 3) : '';
        this.TradeInUnitYear04 = this.TradeInUnitYear.length() > 3 ? this.TradeInUnitYear.subString(3, 4) : '';
        
        Decimal agreedValue = dealItemRec.Agreed_Value__c != null ? dealItemRec.Agreed_Value__c.setScale(2, RoundingMode.HALF_UP) : 0;
        Decimal lienPayout = dealItemRec.Lien_Payout__c != null ? dealItemRec.Lien_Payout__c : 0;
        this.TradeInTotal = formatToDecimal(agreedValue);
        //this.TaxableAmountAfterTax  = String.valueOf(0.0625 * (Integer.valueOf(this.TaxableAmount)));
        if(dealItemRec.Lien_Payout__c != null && dealItemRec.Lien_Payout__c != 0) {
        	this.TradeInUnitLienPayout = formatToDecimal(lienPayout);
        }
        this.LienFinanceCompanyName = (dealItemRec.Finance_Company__r.Name != null ? dealItemRec.Finance_Company__r.Name : '');
        String LienFinanceCompanybillingStreet = (dealItemRec.Finance_Company__r.BillingStreet == null ) ? '' : dealItemRec.Finance_Company__r.BillingStreet;
        List<String> bsList = LienFinanceCompanybillingStreet.split('\n');
        this.LienFinanceCompanyAddress1 = (bsList.size() > 0) ? bsList[0].replace('\n', ' ') : '';
        this.LienFinanceCompanyAddress2 = (bsList.size() > 1) ? bsList[1].replace('\n', ' ') : '';
        this.LienFinanceCompanyAddress1and2 = this.LienFinanceCompanyAddress1 + ' ' + this.LienFinanceCompanyAddress2;
        this.LienFinanceCompanyCity = dealItemRec.Finance_Company__r.BillingCity != null ? dealItemRec.Finance_Company__r.BillingCity : '';
        this.LienFinanceCompanyState = dealItemRec.Finance_Company__r.BillingState != null ? dealItemRec.Finance_Company__r.BillingState : '';
        this.LienFinanceCompanyZipCode = dealItemRec.Finance_Company__r.BillingPostalCode != null ? dealItemRec.Finance_Company__r.BillingPostalCode : '';
        this.LienFinanceCompanyCityStateZipCode = this.LienFinanceCompanyCity + ' ' + this.LienFinanceCompanyState + ' ' + this.LienFinanceCompanyZipCode;
        this.LienFinanceCompanyAddress1CityStateZipCode = this.LienFinanceCompanyAddress1 + ' ' + this.LienFinanceCompanyCityStateZipCode;
        this.VendorTaxID = (dealItemRec.Finance_Company__r.Vendor_Tax_Id__c != null ? dealItemRec.Finance_Company__r.Vendor_Tax_Id__c : '');

        this.TradeInUnitNetAllowance = formatToDecimal(agreedValue - lienPayout);

        Decimal tradeInTax = 0;
        Boolean isTaxIncludingPricing = GeneralConfiguration.getTaxIncludingPricing();
        dealItemRec.Agreed_Value__c = dealItemRec.Agreed_Value__c != null ? dealItemRec.Agreed_Value__c : 0;
        if(!isTaxIncludingPricing) {
            tradeInTax = ((dealItemRec.Agreed_Value__c * dealItemRec.Default_Unit_Sales_Tax_Percentage__c)/100).setScale(2, RoundingMode.HALF_UP);
        } else {
            tradeInTax = (dealItemRec.Agreed_Value__c - (dealItemRec.Agreed_Value__c / (1 + dealItemRec.Default_Unit_Sales_Tax_Percentage__c/100))).setScale(2, RoundingMode.HALF_UP);
        }

        this.TradeInSalesTaxesAmount = formatToDecimal(tradeInTax * -1);
        DateTime tradeInUnitRegistrationExpirydate =  (dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c != null ? dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c : system.now());
        this.TradeInUnitRegistrationExpiryDay = tradeInUnitRegistrationExpirydate.format('dd');
        this.TradeInUnitRegistrationExpiryMonth =  tradeInUnitRegistrationExpirydate.format('MM');
        this.TradeInUnitRegistrationExpiryYear = String.valueOf(tradeInUnitRegistrationExpirydate.year());
        //TradeInUnit Multiline Unit Make, Unit Model, and Unit Sub Model
        this.MultiLineTradeInUnitMake = String.isNotBlank(this.TradeInUnitMake) ? this.TradeInUnitMake.replaceFirst(' ', '\n') : '';
        this.MultiLineTradeInUnitModel = String.isNotBlank(this.TradeInUnitModel) ? this.TradeInUnitModel.replaceFirst(' ', '\n') : '';
        this.MultiLineTradeInUnitSubModel = String.isNotBlank(this.TradeInUnitSubModel) ? this.TradeInUnitSubModel.replaceFirst(' ', '\n') : '';
    }

    public void setAllDealTradeInFields(List<Deal_Item__c> dealItemRecords) {
        Decimal agreedValue = 0;
        Decimal lienPayout = 0;
        for(Deal_Item__c  dealItemRec : dealItemRecords) {
            agreedValue += dealItemRec.Agreed_Value__c != null ? dealItemRec.Agreed_Value__c.setScale(2, RoundingMode.HALF_UP) : 0;
            lienPayout += dealItemRec.Lien_Payout__c != null ? dealItemRec.Lien_Payout__c.setScale(2, RoundingMode.HALF_UP) : 0;
        }    
        this.DealTotalTradeInsAmount = formatToDecimal(agreedValue);
        this.DealTotalLienPayoutAmount = formatToDecimal(lienPayout);
    }

    public void setSecondDealTradeInFields(Deal_Item__c dealItemRec) {
        Decimal agreedValue = dealItemRec.Agreed_Value__c != null ? dealItemRec.Agreed_Value__c : 0;
        Decimal lienPayout = dealItemRec.Lien_Payout__c != null ? dealItemRec.Lien_Payout__c : 0;
        this.SecondTradeInUnitVIN = dealItemRec.Customer_Owned_Unit__r.VIN_Number__c != null ? dealItemRec.Customer_Owned_Unit__r.VIN_Number__c : '';
        this.SecondTradeInUnitOdometer = (dealItemRec.Mileage__c != null) ? String.valueOf(dealItemRec.Mileage__c) : '';
        this.SecondTradeInUnitLienPayout = formatToDecimal((lienPayout).setScale(2, RoundingMode.HALF_UP));
        this.SecondTradeInUnitAllowance = formatToDecimal((agreedValue - lienPayout).setScale(2, RoundingMode.HALF_UP));
        this.SecondTradeInUnitYear = dealItemRec.Customer_Owned_Unit__r.Year__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Year__c) : '';
        this.SecondTradeInUnitMake = dealItemRec.Customer_Owned_Unit__r.Unit_Make__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Make__r.Name : '';
        this.SecondTradeInUnitModel = dealItemRec.Customer_Owned_Unit__r.Unit_Model__c != null ? dealItemRec.Customer_Owned_Unit__r.Unit_Model__r.Name__c : '';
        this.SecondTradeInUnitTotal = formatToDecimal(agreedValue);
        this.SecondTradeInUnitSubModel = (dealItemRec.Customer_Owned_Unit__r.Sub_Model__c != null) ? dealItemRec.Customer_Owned_Unit__r.Sub_Model__r.Sub_Model_Name__c : '';
        this.SecondTradeInUnitExteriorColour = (dealItemRec.Customer_Owned_Unit__r.Colour__c != null) ? dealItemRec.Customer_Owned_Unit__r.Colour__c : '';
        this.SecondTradeInUnitEngineSize = dealItemRec.Customer_Owned_Unit__r.Displacement__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Displacement__c) : '';
        this.SecondTradeInUnitYearFirstREGO = dealItemRec.Customer_Owned_Unit__r.Year_Of_1st_Rego__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Year_Of_1st_Rego__c) : '';
        this.SecondTradeInUnitOtherNumber = dealItemRec.Customer_Owned_Unit__r.Other_Serial_No__c != null ? dealItemRec.Customer_Owned_Unit__r.Other_Serial_No__c : '';
        this.SecondTradeInUnitRegistriationNumber = dealItemRec.Customer_Owned_Unit__r.Plate__c != null ? dealItemRec.Customer_Owned_Unit__r.Plate__c : '';
        this.SecondTradeInUnitRegistrationExpirydate = dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c != null ? String.valueOf(dealItemRec.Customer_Owned_Unit__r.Reg_Expiry_Date__c) : '';
        this.SecondTradeInUnitEngineNumber = dealItemRec.Customer_Owned_Unit__r.Engine_Serial_No__c != null ? dealItemRec.Customer_Owned_Unit__r.Engine_Serial_No__c : '';
        this.SecondTradeInUnitStockNumber = dealItemRec.Customer_Owned_Unit__r.Stock_Id__c;
        this.SecondTradeInLienFinanceCompanyName = (dealItemRec.Finance_Company__r.Name != null ? dealItemRec.Finance_Company__r.Name : '');
        String LienFinanceCompanybillingStreet = (dealItemRec.Finance_Company__r.BillingStreet == null ) ? '' : dealItemRec.Finance_Company__r.BillingStreet;
        List<String> bsList = LienFinanceCompanybillingStreet.split('\n');
        this.SecondTradeInLienFinanceCompanyAddress1 = (bsList.size() > 0) ? bsList[0].replace('\n', ' ') : '';
        this.SecondTradeInLienFinanceCompanyAddress2 = (bsList.size() > 1) ? bsList[1].replace('\n', ' ') : '';
        this.SecondTradeInLienFinanceCompanyAddress1and2 = this.SecondTradeInLienFinanceCompanyAddress1 + ' ' + this.SecondTradeInLienFinanceCompanyAddress2;
        this.SecondTradeInLienFinanceCompanyCity = dealItemRec.Finance_Company__r.BillingCity != null ? dealItemRec.Finance_Company__r.BillingCity : '';
        this.SecondTradeInLienFinanceCompanyState = dealItemRec.Finance_Company__r.BillingState != null ? dealItemRec.Finance_Company__r.BillingState : '';
        this.SecondTradeInLienFinanceCompanyZipCode = dealItemRec.Finance_Company__r.BillingPostalCode != null ? dealItemRec.Finance_Company__r.BillingPostalCode : '';
        this.SecondTradeInLienFinanceCompanyCityStateZipCode = this.SecondTradeInLienFinanceCompanyCity + ' ' + this.SecondTradeInLienFinanceCompanyState + ' ' + this.SecondTradeInLienFinanceCompanyZipCode;
        //SecondTradeInUnit Multiline Unit Make, Unit Model, and Unit Sub Model
        this.MultiLineSecondTradeInUnitMake = String.isNotBlank(this.SecondTradeInUnitMake) ? this.SecondTradeInUnitMake.replaceFirst(' ', '\n') : '';
        this.MultiLineSecondTradeInUnitModel = String.isNotBlank(this.SecondTradeInUnitModel) ? this.SecondTradeInUnitModel.replaceFirst(' ', '\n') : '';
        this.MultiLineSecondTradeInUnitSubModel = String.isNotBlank(this.SecondTradeInUnitSubModel) ? this.SecondTradeInUnitSubModel.replaceFirst(' ', '\n') : '';
        this.SecondTradeInUnitInteriorColour = (dealItemRec.Customer_Owned_Unit__r.Interior_Colour__c != null) ? dealItemRec.Customer_Owned_Unit__r.Interior_Colour__c : '';
        this.SecondTradeInTotal = dealItemRec.Agreed_Value__c != null ? formatToDecimal(dealItemRec.Agreed_Value__c.setScale(2, RoundingMode.HALF_UP)) : '0';
    }

    private String formatToDecimal(Decimal decVal) {
    	return BPUtility.formatToDecimal(decVal);
    }
    
    public void setOtherDealRelatedFields(Deal__c dealRec, List<CO_Deposit__c> dealDepositList, List<CO_Invoice_Payment__c> invoicePaymentList, List<Deal_Finance__c> dealFinanceList) {
    	Decimal totalAmount = 0;
        Decimal dealDepositAmount = 0;
    	if(dealRec.Invoice_Number__c != null) {
    		for(CO_Invoice_Payment__c paymentRec : invoicePaymentList) {
	    		if(paymentRec.Amount__c != null && !paymentRec.Payment_Method__c.equalsIgnoreCase(QBUtil.CHARGE_ACCOUNT) && 
	    				!paymentRec.Payment_Method__c.equalsIgnoreCase('Financing')) {
	    			totalAmount += paymentRec.Amount__c;
	    		}
	    	}
    	} else {
	    	for(CO_Deposit__c depositRec : dealDepositList) {
	    		if(depositRec.Deal__c != null && depositRec.Amount__c != null) {
	    			totalAmount += depositRec.Amount__c;
                    if(this.DealFirstDepositDate == null){
                        this.DealFirstDepositDate = depositRec.Payment_Date__c != null ? String.valueOf(depositRec.Payment_Date__c) : '';
                    }
                    dealDepositAmount += depositRec.Amount__c;
                    if(this.DealDepositType == null){
                        this.DealDepositType = depositRec.Payment_Method__c != null ? String.valueOf(depositRec.Payment_Method__c) : '';
                    }
	    		}
	    	}
	    	for(CO_Invoice_Payment__c paymentRec : invoicePaymentList) {
	    		if(paymentRec.Amount__c != null) {
	    			totalAmount += paymentRec.Amount__c;
	    		}
	    	}
    	}
        if(dealFinanceList != null && !dealFinanceList.isEmpty()) {
            if(((dealRec.Invoice_Number__c != null && dealFinanceList[0].DF_Commission_in_FI_company_payments__c) || (dealRec.Invoice_Number__c == null && GeneralConfiguration.getConfigurations().DF_commission_in_FI_company_payments__c && !dealFinanceList[0].Finance_Company__r.Commissions_not_in_finance_payments__c)) && dealFinanceList[0].Finance_Commission__c != null){
                totalAmount -= dealFinanceList[0].Finance_Commission__c;
            }
        }
        this.DealDeposit = formatToDecimal(dealDepositAmount);
    	this.DealTotalAmountPaid = formatToDecimal(totalAmount);
    	this.DealTotalBalanceDue = formatToDecimal(dealRec.Deal_Total__c - totalAmount);
    	this.DealTotal = formatToDecimal(dealRec.Deal_Total__c != null ? dealRec.Deal_Total__c : 0);
    	this.DealAmountFinanced = formatToDecimal(dealFinanceList.size() > 0 ? (dealRec.Amount_Financed__c != null ? dealRec.Amount_Financed__c : 0) : 0);
    	this.DealFinanceDownPayment = formatToDecimal(dealRec.Down_Payment__c != null ? dealRec.Down_Payment__c : 0);
    }
    
    private void setUnitMileageFields(Decimal mileageValue) {
        if(mileageValue != null) {
            Integer mileageValInt = Integer.valueOf(mileageValue.setScale(0, RoundingMode.HALF_UP));
            this.UnitOdometer = String.valueOf(mileageValInt);
            if(mileageValue > 0 && this.UnitOdometer.length() > 0) {
                Integer counter = this.UnitOdometer.length();
                this.UnitOdometer6 = (counter > 0 && this.UnitOdometer.length() >= counter) ? this.UnitOdometer.subString(counter - 1, counter--) : '';
                this.UnitOdometer5 = (counter > 0 && this.UnitOdometer.length() >= counter) ? this.UnitOdometer.subString(counter - 1, counter--) : '';
                this.UnitOdometer4 = (counter > 0 && this.UnitOdometer.length() >= counter) ? this.UnitOdometer.subString(counter - 1, counter--) : '';
                this.UnitOdometer3 = (counter > 0 && this.UnitOdometer.length() >= counter) ? this.UnitOdometer.subString(counter - 1, counter--) : '';
                this.UnitOdometer2 = (counter > 0 && this.UnitOdometer.length() >= counter) ? this.UnitOdometer.subString(counter - 1, counter--) : '';
                this.UnitOdometer1 = (counter > 0 && this.UnitOdometer.length() >= counter) ? this.UnitOdometer.subString(counter - 1, counter--) : '';
            }
        }
    }
    
    private void setTradeInUnitMileageFields(Decimal mileageValue) {
        if(mileageValue != null && mileageValue.intValue() > 0) {
            String unitOdometerStr = this.TradeInUnitOdometer = String.valueOf(mileageValue.intValue());
            Integer counter = unitOdometerStr.length();
            this.TradeInUnitOdometer6 = (counter > 0 && unitOdometerStr.length() >= counter) ? unitOdometerStr.subString(counter - 1, counter--) : '';
            this.TradeInUnitOdometer5 = (counter > 0 && unitOdometerStr.length() >= counter) ? unitOdometerStr.subString(counter - 1, counter--) : '';
            this.TradeInUnitOdometer4 = (counter > 0 && unitOdometerStr.length() >= counter) ? unitOdometerStr.subString(counter - 1, counter--) : '';
            this.TradeInUnitOdometer3 = (counter > 0 && unitOdometerStr.length() >= counter) ? unitOdometerStr.subString(counter - 1, counter--) : '';
            this.TradeInUnitOdometer2 = (counter > 0 && unitOdometerStr.length() >= counter) ? unitOdometerStr.subString(counter - 1, counter--) : '';
            this.TradeInUnitOdometer1 = (counter > 0 && unitOdometerStr.length() >= counter) ? unitOdometerStr.subString(counter - 1, counter--) : '';
        }
    }
    
    private void setUnitVINFields(String VINNumber) {
        if(String.isBlank(VINNumber)) {
            this.UnitVIN = 'VIN Unknown';
        } else {
            this.UnitVIN = VINNumber;
            Integer counter = 0;
            this.UnitVINLast6Digits = (this.UnitVIN.length() > 6) ? this.UnitVIN.right(6) : this.UnitVIN;
            this.UnitVIN01 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN02 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN03 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN04 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN05 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN06 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN07 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN08 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN09 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN10 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN11 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN12 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN13 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN14 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN15 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN16 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN17 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN18 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
            this.UnitVIN19 = (this.UnitVIN.length() > counter) ? this.UnitVIN.subString(counter, ++counter) : '';
        }
    }

    private void setTradeInUnitVINFields(String VINNumber) {
        if(String.isBlank(VINNumber)) {
            this.TradeInUnitVIN = 'VIN Unknown';
        } else {
            this.TradeInUnitVIN = VINNumber;
            Integer counter = 0;
            this.TradeInUnitVIN01 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN02 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN03 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN04 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN05 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN06 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN07 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN08 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN09 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN10 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN11 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN12 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN13 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN14 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN15 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN16 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN17 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN18 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
            this.TradeInUnitVIN19 = (this.TradeInUnitVIN.length() > counter) ? this.TradeInUnitVIN.subString(counter, ++counter) : '';
        }
    }
    
    private Decimal getBasePrice(Deal_Unit_Price_Cost__c baseUnitPrice) {
        Decimal price = ((baseUnitPrice.Price__c != null) ? baseUnitPrice.Price__c : 0).setScale(2, RoundingMode.HALF_UP);
        Decimal taxRate = ((baseUnitPrice.Sales_Tax_Percentage__c != null) ? baseUnitPrice.Sales_Tax_Percentage__c : 0).setScale(2, RoundingMode.HALF_UP);
        Decimal salesTax = ((taxRate * price) / 100).setScale(2, RoundingMode.HALF_UP);
        
        if(GeneralConfiguration.getTaxIncludingPricing()) {
            price = (baseUnitPrice.Price_When_Tax_Included__c != null ? baseUnitPrice.Price_When_Tax_Included__c : (price + salesTax)).setScale(2, RoundingMode.HALF_UP);
        }
        return price;
    }
    
    private Decimal getOptionAndFeePrice(Option_Fee__c optionAndFeeRec) {
        Decimal totalPrice = (optionAndFeeRec.Price__c != null) ? optionAndFeeRec.Price__c.setScale(2, RoundingMode.HALF_UP) : 0.00;
        if(GeneralConfiguration.getTaxIncludingPricing()) {
        	Decimal taxRate = optionAndFeeRec.Sales_Tax_Percentage__c != null ? optionAndFeeRec.Sales_Tax_Percentage__c.setScale(4, RoundingMode.HALF_UP) : 0.00;
            totalPrice = (optionAndFeeRec.Price_When_Tax_Included__c != null) ? optionAndFeeRec.Price_When_Tax_Included__c.setScale(2, RoundingMode.HALF_UP) : 
                                            (totalPrice * (1 + taxRate /100)).setScale(2, RoundingMode.HALF_UP);
        }           
        totalPrice = totalPrice != null ? totalPrice : 0;
        Decimal qty = optionAndFeeRec.Qty__c != null ? optionAndFeeRec.Qty__c : 0;
        totalPrice = (totalPrice * qty).setScale(2, RoundingMode.HALF_UP);
        
        return totalPrice;
    }
    
    private static Decimal getTotalSalesTax(Deal_Item__c dealItemRec) {
    	return dealItemRec.Deal__r.Sales_Tax_Total__c != null ? dealItemRec.Deal__r.Sales_Tax_Total__c.setScale(2, RoundingMode.HALF_UP) : 0;
    }
    
    private Decimal getLoanTerm(Deal_Finance__c dealFinanceRec) {
    	if(dealFinanceRec.Loan_Term__c != null && dealFinanceRec.Term_Type__c != null && dealFinanceRec.Payment_Frequency__c != null) {
            if (dealFinanceRec.Term_Type__c == 'Months') {
                if (dealFinanceRec.Payment_Frequency__c == 'Monthly') {
                    return (dealFinanceRec.Loan_Term__c * 1);
                } else if (dealFinanceRec.Payment_Frequency__c == 'Semi-Monthly') {
                    return (dealFinanceRec.Loan_Term__c * 2);
                } else if (dealFinanceRec.Payment_Frequency__c == 'Weekly') {
                    return (dealFinanceRec.Loan_Term__c * 4.33);
                } else if (dealFinanceRec.Payment_Frequency__c == 'Bi-Weekly') {
                    return (dealFinanceRec.Loan_Term__c * 2.16);
                } else if(dealFinanceRec.Payment_Frequency__c == 'Annual') {
                    return (dealFinanceRec.Loan_Term__c * 12);
                } else if(dealFinanceRec.Payment_Frequency__c == 'Bi-annual') {
                    return (dealFinanceRec.Loan_Term__c * 24);
                }
            } else if (dealFinanceRec.Term_Type__c == 'Years') {
                if (dealFinanceRec.Payment_Frequency__c == 'Monthly') {
                    return (dealFinanceRec.Loan_Term__c * 12);
                } else if (dealFinanceRec.Payment_Frequency__c == 'Semi-Monthly') {
                    return (dealFinanceRec.Loan_Term__c * 24);
                } else if (dealFinanceRec.Payment_Frequency__c == 'Weekly') {
                    return (dealFinanceRec.Loan_Term__c * 52);
                } else if (dealFinanceRec.Payment_Frequency__c == 'Bi-Weekly') {
                    return (dealFinanceRec.Loan_Term__c * 26);
                } else if(dealFinanceRec.Payment_Frequency__c == 'Annual') {
                    return (dealFinanceRec.Loan_Term__c);
                } else if(dealFinanceRec.Payment_Frequency__c == 'Bi-annual') {
                    return (dealFinanceRec.Loan_Term__c * 2 );
                }
            }
    	}
    	return 0;
    }
    
    private void setUnitFeeWithNoTagFields(Integer counter, String description, Decimal price) {
    	String priceStr = formatToDecimal(price);
    	
    	if(counter == 1) {
    		this.UnitFee1NoTagName = description;
    		this.UnitFee1NoTagPrice = priceStr;
    	} else if(counter == 2) {
    		this.UnitFee2NoTagName = description;
    		this.UnitFee2NoTagPrice = priceStr;
    	} else if(counter == 3) {
    		this.UnitFee3NoTagName = description;
    		this.UnitFee3NoTagPrice = priceStr;
    	} else if(counter == 4) {
    		this.UnitFee4NoTagName = description;
    		this.UnitFee4NoTagPrice = priceStr;
    	} else if(counter == 5) {
    		this.UnitFee5NoTagName = description;
    		this.UnitFee5NoTagPrice = priceStr;
    	} else if(counter == 6) {
    		this.UnitFee6NoTagName = description;
    		this.UnitFee6NoTagPrice = priceStr;
    	}
    }

    private void setUnitPartWithNoTagFields(Integer counter, String description, Decimal price) {
    	String priceStr = formatToDecimal(price);
    	
    	if(counter == 1) {
    		this.UnitPart1NoTagName = description;
        this.UnitPart1NoTagPrice = priceStr;
    	} else if(counter == 2) {
    		this.UnitPart2NoTagName = description;
        this.UnitPart2NoTagPrice = priceStr;
    	} else if(counter == 3) {
    		this.UnitPart3NoTagName = description;
        this.UnitPart3NoTagPrice = priceStr;
    	} else if(counter == 4) {
    		this.UnitPart4NoTagName = description;
        this.UnitPart4NoTagPrice = priceStr;
    	} else if(counter == 5) {
    		this.UnitPart5NoTagName = description;
        this.UnitPart5NoTagPrice = priceStr;
    	} else if(counter == 6) {
    		this.UnitPart6NoTagName = description;
        this.UnitPart6NoTagPrice = priceStr;
    	} else if(counter == 7) {
            this.UnitPart7NoTagName = description;
            this.UnitPart7NoTagPrice = priceStr;
        } else if(counter == 8) {
            this.UnitPart8NoTagName = description;
            this.UnitPart8NoTagPrice = priceStr;
        } else if(counter == 9) {
            this.UnitPart9NoTagName = description;
            this.UnitPart9NoTagPrice = priceStr;
        } else if(counter == 10) {
            this.UnitPart10NoTagName = description;
            this.UnitPart10NoTagPrice = priceStr;
        } else if(counter == 11) {
            this.UnitPart11NoTagName = description;
            this.UnitPart11NoTagPrice = priceStr;
        } else if(counter == 12) {
            this.UnitPart12NoTagName = description;
            this.UnitPart12NoTagPrice = priceStr;
        } else if(counter == 13) {
            this.UnitPart13NoTagName = description;
            this.UnitPart13NoTagPrice = priceStr;
        } else if(counter == 14) {
            this.UnitPart14NoTagName = description;
            this.UnitPart14NoTagPrice = priceStr;
        } else if(counter == 15) {
            this.UnitPart15NoTagName = description;
            this.UnitPart15NoTagPrice = priceStr;
        } else if(counter == 16) {
            this.UnitPart16NoTagName = description;
            this.UnitPart16NoTagPrice = priceStr;
        } else if(counter == 17) {
            this.UnitPart17NoTagName = description;
            this.UnitPart17NoTagPrice = priceStr;
        } else if(counter == 18) {
            this.UnitPart18NoTagName = description;
            this.UnitPart18NoTagPrice = priceStr;
        } else if(counter == 19) {
            this.UnitPart19NoTagName = description;
            this.UnitPart19NoTagPrice = priceStr;
        } else if(counter == 20) {
            this.UnitPart20NoTagName = description;
            this.UnitPart20NoTagPrice = priceStr;
        }
    }

    public void setUnitPreviousOwnerFields(List<Customer_Owned_Unit__c> similarUnits) {
        if(similarUnits.size() > 0){
            this.UnitPrevOwnerName = String.isNotBlank(similarUnits[0].Account__r.Name) ? similarUnits[0].Account__r.Name : '';
            
            String billingStreet = (similarUnits[0].Account__r.BillingStreet == null ) ? '' : similarUnits[0].Account__r.BillingStreet;
            List<String> bsList = billingStreet.split('\n');
            this.UnitPrevOwnerStreetAddress1 = (bsList.size() > 0) ? bsList[0].replace('\n', ' ') : '';
            this.UnitPrevOwnerStreetAddress2 = (bsList.size() > 1) ? bsList[1].replace('\n', ' ') : '';
            this.UnitPrevOwnerStreetAddress1and2 = this.UnitPrevOwnerStreetAddress1 + ' ' + this.UnitPrevOwnerStreetAddress2;
            
            this.UnitPrevOwnerCity = String.isNotBlank(similarUnits[0].Account__r.BillingCity) ? similarUnits[0].Account__r.BillingCity : '';
            this.UnitPrevOwnerState = String.isNotBlank(similarUnits[0].Account__r.BillingState) ? similarUnits[0].Account__r.BillingState : '';
            this.UnitPrevOwnerZIPCode = String.isNotBlank(similarUnits[0].Account__r.BillingPostalCode) ? similarUnits[0].Account__r.BillingPostalCode : '';
        } else {
            this.UnitPrevOwnerName = this.BusinessName;
            this.UnitPrevOwnerStreetAddress1 = this.BusinessAddressLine1;
            this.UnitPrevOwnerStreetAddress2 = this.BusinessAddressLine2;
            this.UnitPrevOwnerStreetAddress1and2 = this.BusinessAddress1and2;
            this.UnitPrevOwnerCity = this.BusinessCity;
            this.UnitPrevOwnerState = this.BusinessState;
            this.UnitPrevOwnerZIPCode = this.BusinessZipcode;
        }
        this.UnitPrevOwnerAddress = (String.isNotBlank(this.UnitPrevOwnerStreetAddress1and2) ? this.UnitPrevOwnerStreetAddress1and2 + ' ' : '' ) + (String.isNotBlank(this.UnitPrevOwnerCity) ? this.UnitPrevOwnerCity + ' ' : '' ) + (String.isNotBlank(this.UnitPrevOwnerState) ? this.UnitPrevOwnerState + ' ' : '' ) + (String.isNotBlank(this.UnitPrevOwnerZIPCode) ? this.UnitPrevOwnerZIPCode : '');
    }
    
    public void setGSTPSTTax(Map<String, Decimal> salesTaxNameToTaxValue){
        for(String taxName : salesTaxNameToTaxValue.keySet()){
            this.GSTOnlyUnitSale = formatToDecimal(taxName.containsIgnoreCase('GST') ? salesTaxNameToTaxValue.get(taxName) : 0);
            this.PSTOnlyUnitSale = formatToDecimal(taxName.containsIgnoreCase('PST') ? salesTaxNameToTaxValue.get(taxName) : 0);
            this.FETTaxAmount = formatToDecimal(taxName.containsIgnoreCase('FET') ? salesTaxNameToTaxValue.get(taxName) : 0);
        }       
    }
    

    public void dealCalculatedField(){
        this.NetPurchasePrice = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? (Decimal.valueOf(this.UnitTotalPrice.replaceAll(',',''))) : 0) - (String.isNotBlank(this.TradeInTotal) ? (Decimal.valueOf(this.TradeInTotal.replaceAll(',',''))) : 0 ));
        this.NetBasePurchasePrice = formatToDecimal((String.isNotBlank(this.UnitTotalBasePrice) ? (Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',',''))) : 0) - (String.isNotBlank(this.TradeInTotal) ? (Decimal.valueOf(this.TradeInTotal.replaceAll(',',''))) : 0 ));
		this.DifferenceOfTradeInTotalAndUnitTotal = formatToDecimal(( String.isNotBlank(this.WarrantyAndNoTagFeeUnitTotal) ? Decimal.valueOf(this.WarrantyAndNoTagFeeUnitTotal.replaceAll(',','')) : 0 ) - (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0 ));
		
		this.UnitTotalPriceAnd5OptionsPartFee = formatToDecimal(
		(String.isNotBlank(this.UnitTotalPriceLaborRegInsTagFee) ? Decimal.valueOf(this.UnitTotalPriceLaborRegInsTagFee.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.DealPartAndFeePrice1) ? Decimal.valueOf(this.DealPartAndFeePrice1.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.DealPartAndFeePrice2) ? Decimal.valueOf(this.DealPartAndFeePrice2.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.DealPartAndFeePrice3) ? Decimal.valueOf(this.DealPartAndFeePrice3.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.DealPartAndFeePrice4) ? Decimal.valueOf(this.DealPartAndFeePrice4.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.DealPartAndFeePrice5) ? Decimal.valueOf(this.DealPartAndFeePrice5.replaceAll(',','')) : 0));
		
        this.DealPartAndFeePrice1To3Total = formatToDecimal(
        (String.isNotBlank(this.DealPartAndFeePrice1) ? Decimal.valueOf(this.DealPartAndFeePrice1.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice2) ? Decimal.valueOf(this.DealPartAndFeePrice2.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice3) ? Decimal.valueOf(this.DealPartAndFeePrice3.replaceAll(',','')) : 0));

        this.DealPartAndFeePrice1To5Total = formatToDecimal(
        (String.isNotBlank(this.DealPartAndFeePrice1) ? Decimal.valueOf(this.DealPartAndFeePrice1.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice2) ? Decimal.valueOf(this.DealPartAndFeePrice2.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice3) ? Decimal.valueOf(this.DealPartAndFeePrice3.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice4) ? Decimal.valueOf(this.DealPartAndFeePrice4.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice5) ? Decimal.valueOf(this.DealPartAndFeePrice5.replaceAll(',','')) : 0));

        this.DifferenceOfUnitTotalPriceWithAllOptionsAndTradeInTotal = formatToDecimal(( String.isNotBlank(this.UnitTotalPriceWithAllOptions) ? Decimal.valueOf(this.UnitTotalPriceWithAllOptions.replaceAll(',','')) : 0 ) - (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0 ));
        
		this.DealTotalDuePayble = formatToDecimal(
		(String.isNotBlank(this.UnitTotalPriceAnd5OptionsPartFee) ? Decimal.valueOf(this.UnitTotalPriceAnd5OptionsPartFee.replaceAll(',','')) : 0) - (String.isNotBlank(this.DealTotalAmountPaid) ? Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',','')) : 0) - (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0) - (String.isNotBlank(this.DealTotalLienPayoutAmount) ? Decimal.valueOf(this.DealTotalLienPayoutAmount.replaceAll(',','')) : 0));
		
        this.DifferenceOfUnitTotalPriceWithNonFeeOptionsAndTradeInTotal = formatToDecimal(( String.isNotBlank(this.UnitTotalPriceWithNonFeeOptions) ? Decimal.valueOf(this.UnitTotalPriceWithNonFeeOptions.replaceAll(',','')) : 0 ) - (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0 ));
        
        this.TotalUnitPriceFeeOfCodeAndNoTagFee = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFee1NoTagPrice) ? Decimal.valueOf(this.UnitFee1NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFee2NoTagPrice) ? Decimal.valueOf(this.UnitFee2NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFee3NoTagPrice) ? Decimal.valueOf(this.UnitFee3NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFee4NoTagPrice) ? Decimal.valueOf(this.UnitFee4NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFee5NoTagPrice) ? Decimal.valueOf(this.UnitFee5NoTagPrice.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.UnitFee6NoTagPrice) ? Decimal.valueOf(this.UnitFee6NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DOCCodeUnitFee) ? Decimal.valueOf(this.DOCCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TEFCodeUnitFee) ? Decimal.valueOf(this.TEFCodeUnitFee.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.FRTCodeUnitFee) ? Decimal.valueOf(this.FRTCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.PDICodeUnitFee) ? Decimal.valueOf(this.PDICodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.WARRCodeUnitFee) ? Decimal.valueOf(this.WARRCodeUnitFee.replaceAll(',','')) : 0));
		
		this.TotalDeliverPriceOfVehicle = formatToDecimal((String.isNotBlank(this.DifferenceOfTradeInTotalAndUnitTotal) ? Decimal.valueOf(this.DifferenceOfTradeInTotalAndUnitTotal.replaceAll(',','')) : 0) + (String.isNotBlank(this.StateCodeUnitFee) ? Decimal.valueOf(this.StateCodeUnitFee.replaceAll(',','')) : 0));
        this.SumOfBasePricePartsPriceAndFRTOUTFee = formatToDecimal(( String.isNotBlank(this.UnitTotalBasePrice) ? Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',','')) : 0 ) + (String.isNotBlank(this.TotalDealPartPrice) ? Decimal.valueOf(this.TotalDealPartPrice.replaceAll(',','')) : 0 ) + (String.isNotBlank(this.FRTOUTCodeUnitFee) ? Decimal.valueOf(this.FRTOUTCodeUnitFee.replaceAll(',','')) : 0 ));
        this.SumOfBasePricePartsPriceFRTOUTFeeAndDOCFee =  formatToDecimal(( String.isNotBlank(this.SumOfBasePricePartsPriceAndFRTOUTFee) ? Decimal.valueOf(this.SumOfBasePricePartsPriceAndFRTOUTFee.replaceAll(',','')) : 0 ) + (String.isNotBlank(this.DOCCodeUnitFee) ? Decimal.valueOf(this.DOCCodeUnitFee.replaceAll(',','')) : 0 ));
        this.DiffOfProdDealFinanceEstimatedPaymentAndLoanTermAndDealAmountFinanced = formatToDecimal((String.isNotBlank(this.ProductDealFinanceEstimatedPaymentAndLoanTerm) ? Decimal.valueOf(this.ProductDealFinanceEstimatedPaymentAndLoanTerm.replaceAll(',','')) : 0) - (String.isNotBlank(this.DealAmountFinanced) ? Decimal.valueOf(this.DealAmountFinanced.replaceAll(',','')) : 0));
        this.SumOfProdDealFinanceEstimatedPaymentAndLoanTermAndDealFinanceDownPayment = formatToDecimal((String.isNotBlank(this.ProductDealFinanceEstimatedPaymentAndLoanTerm) ? Decimal.valueOf(this.ProductDealFinanceEstimatedPaymentAndLoanTerm.replaceAll(',','')) : 0) + (String.isNotBlank(this.DealFinanceDownPayment) ? Decimal.valueOf(this.DealFinanceDownPayment.replaceAll(',','')) : 0));
        this.SumOfUnitTotalPriceAndSalesTax = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0) + (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0));
        this.SumOfTradeInTotalAndDealTotalAmountPaid = formatToDecimal((String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0) + (String.isNotBlank(this.DealTotalAmountPaid) ? Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',','')) : 0));
        this.DiffOfUnitTotalPriceWithSalesTaxAndTradeInTotalWithDealTotalAmountPaid = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalPriceAndSalesTax) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndSalesTax.replaceAll(',','')) : 0) - (String.isNotBlank(this.SumOfTradeInTotalAndDealTotalAmountPaid) ? Decimal.valueOf(this.SumOfTradeInTotalAndDealTotalAmountPaid.replaceAll(',','')) : 0));
        this.AmountFinancedTrakPowersports = formatToDecimal((String.isNotBlank(this.DiffOfUnitTotalPriceWithSalesTaxAndTradeInTotalWithDealTotalAmountPaid) ? Decimal.valueOf(this.DiffOfUnitTotalPriceWithSalesTaxAndTradeInTotalWithDealTotalAmountPaid.replaceAll(',','')) : 0) + (String.isNotBlank(this.SumOfFeesTrakPowersports) ? Decimal.valueOf(this.SumOfFeesTrakPowersports.replaceAll(',','')) : 0));
        this.SumOfFeesTrakPowersports = formatToDecimal((String.isNotBlank(this.GAPCodeUnitFee) ? Decimal.valueOf(this.GAPCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.GAPDescriptionPrice) ? Decimal.valueOf(this.GAPDescriptionPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.RegistrationFeeCodeUnitFee) ? Decimal.valueOf(this.RegistrationFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.PlateTransferFeeCodeUnitFee) ? Decimal.valueOf(this.PlateTransferFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.VINInspectionFeeCodeUnitFee) ? Decimal.valueOf(this.VINInspectionFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.VINTradeFeeCodeUnitFee) ? Decimal.valueOf(this.VINTradeFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.Title_FeeCodeUnitFee) ? Decimal.valueOf(this.Title_FeeCodeUnitFee.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.ESCCodeUnitFee) ? Decimal.valueOf(this.ESCCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DOCCodeUnitFee) ? Decimal.valueOf(this.DOCCodeUnitFee.replaceAll(',','')) : 0)+     
        (String.isNotBlank(this.NintyDay_WarrantyFeeCodeUnitFee) ? Decimal.valueOf(this.NintyDay_WarrantyFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.Prepaid_MaintenanceFeeCodeUnitFee) ? Decimal.valueOf(this.Prepaid_MaintenanceFeeCodeUnitFee.replaceAll(',','')) : 0));
        
        this.TotalUnitPriceOfCodeAndNoTagPart = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart1NoTagPrice) ? Decimal.valueOf(this.UnitPart1NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart2NoTagPrice) ? Decimal.valueOf(this.UnitPart2NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart3NoTagPrice) ? Decimal.valueOf(this.UnitPart3NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart4NoTagPrice) ? Decimal.valueOf(this.UnitPart4NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart5NoTagPrice) ? Decimal.valueOf(this.UnitPart5NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart6NoTagPrice) ? Decimal.valueOf(this.UnitPart6NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DOCCodeUnitFee) ? Decimal.valueOf(this.DOCCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TEFCodeUnitFee) ? Decimal.valueOf(this.TEFCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.FRTCodeUnitFee) ? Decimal.valueOf(this.FRTCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.PDICodeUnitFee) ? Decimal.valueOf(this.PDICodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.WARRCodeUnitFee) ? Decimal.valueOf(this.WARRCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DISCCodeUnitFee) ? Decimal.valueOf(this.DISCCodeUnitFee.replaceAll(',','')) : 0));

		this.DifferenceOfTotalUnitPriceCodeAndNoTagFeeAndTradeInTotal = formatToDecimal(( String.isNotBlank(this.TotalUnitPriceFeeOfCodeAndNoTagFee) ? Decimal.valueOf(this.TotalUnitPriceFeeOfCodeAndNoTagFee.replaceAll(',','')) : 0 ) - (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0 ));
        this.DifferenceOfTotalUnitPriceCodeAndNoTagPartAndTradeInTotal = formatToDecimal(( String.isNotBlank(this.TotalUnitPriceOfCodeAndNoTagPart) ? Decimal.valueOf(this.TotalUnitPriceOfCodeAndNoTagPart.replaceAll(',','')) : 0 ) - (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0 ));
		
		this.TotalSalesTaxAndDifferenceOfUnitPriceWithCodeAndNoTagFeeAndTradeInTotal = formatToDecimal(( String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0 ) + (String.isNotBlank(this.DifferenceOfTotalUnitPriceCodeAndNoTagFeeAndTradeInTotal) ? Decimal.valueOf(this.DifferenceOfTotalUnitPriceCodeAndNoTagFeeAndTradeInTotal.replaceAll(',','')) : 0 ));
        this.TotalSalesTaxAndDifferenceOfTotalUnitPriceCodeAndNoTagPartAndTradeInTotal = formatToDecimal(( String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0 ) + (String.isNotBlank(this.DifferenceOfTotalUnitPriceCodeAndNoTagPartAndTradeInTotal) ? Decimal.valueOf(this.DifferenceOfTotalUnitPriceCodeAndNoTagPartAndTradeInTotal.replaceAll(',','')) : 0 ));
        this.DifferOfUnitTotalBasePriceAndDISCCodeUnitFee = formatToDecimal((String.isNotBlank(this.UnitTotalBasePrice) ? Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',','')) : 0) - (String.isNotBlank(this.DISCCodeUnitFee) ? Decimal.valueOf(this.DISCCodeUnitFee.replaceAll(',','')) : 0));
        this.SumOfTop9PartsPriceAndDifferOfUnitTotalBasePriceAndDISCCodeUnitFee = formatToDecimal((String.isNotBlank(this.UnitPart1NoTagPrice) ? Decimal.valueOf(this.UnitPart1NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart2NoTagPrice) ? Decimal.valueOf(this.UnitPart2NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart3NoTagPrice) ? Decimal.valueOf(this.UnitPart3NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart4NoTagPrice) ? Decimal.valueOf(this.UnitPart4NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart5NoTagPrice) ? Decimal.valueOf(this.UnitPart5NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart6NoTagPrice) ? Decimal.valueOf(this.UnitPart6NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart7NoTagPrice) ? Decimal.valueOf(this.UnitPart7NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart8NoTagPrice) ? Decimal.valueOf(this.UnitPart8NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitPart9NoTagPrice) ? Decimal.valueOf(this.UnitPart9NoTagPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DifferOfUnitTotalBasePriceAndDISCCodeUnitFee) ? Decimal.valueOf(this.DifferOfUnitTotalBasePriceAndDISCCodeUnitFee.replaceAll(',','')) : 0));
        this.SumOfUnitTotalSalesTaxTop9PartsPriceAndDifferOfUnitTotalBasePriceAndDISCCodeFee = formatToDecimal((String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOfTop9PartsPriceAndDifferOfUnitTotalBasePriceAndDISCCodeUnitFee) ? Decimal.valueOf(this.SumOfTop9PartsPriceAndDifferOfUnitTotalBasePriceAndDISCCodeUnitFee.replaceAll(',','')) : 0));
        this.TotalPurchasePriceForFTruck = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalSalesTaxTop9PartsPriceAndDifferOfUnitTotalBasePriceAndDISCCodeFee) ? Decimal.valueOf(this.SumOfUnitTotalSalesTaxTop9PartsPriceAndDifferOfUnitTotalBasePriceAndDISCCodeFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.License1CodeUnitFee) ? Decimal.valueOf(this.License1CodeUnitFee.replaceAll(',','')) : 0));
        this.SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceAndDOCTagUnitFee = formatToDecimal((String.isNotBlank(this.UnitTotalBasePrice) ? Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeDOCTagUnitFee) ? Decimal.valueOf(this.UnitFeeDOCTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceDOCTagUnitFeeLICTagUnitFeeAndTotalSalesTax = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceAndDOCTagUnitFee) ? Decimal.valueOf(this.SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceAndDOCTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeLicTagUnitFee) ? Decimal.valueOf(this.UnitFeeLicTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0));
        this.SumOfNetPurchasePriceDOCTagREGTagTITLETagUnitFee = formatToDecimal(
        (String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeDOCTagUnitFee) ? Decimal.valueOf(this.UnitFeeDOCTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0));

        this.DifferenceOfNetPurchasePriceAndRebateFee = formatToDecimal((String.isNotBlank(this.UnitTotalBasePrice) ? (Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitTotalFactoryOptions) ? (Decimal.valueOf(this.UnitTotalFactoryOptions.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitTotalDealerInstalledOptions) ? (Decimal.valueOf(this.UnitTotalDealerInstalledOptions.replaceAll(',',''))) : 0) -
        ((String.isNotBlank(this.TradeInTotal) ? (Decimal.valueOf(this.TradeInTotal.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.RebateCodeFeePrice) ? (Decimal.valueOf(this.RebateCodeFeePrice.replaceAll(',',''))) : 0 )));
        this.SumOfRegtTitleTranFeeAndSalesTax = formatToDecimal((String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? (Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? (Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',',''))) : 0));
        this.SumOfTradeInTotalAndTaxesAmount = formatToDecimal((String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TradeInSalesTaxesAmount) ? Decimal.valueOf(this.TradeInSalesTaxesAmount.replaceAll(',','')) : 0));
        this.SumOfNetPurchasePrice_DealTotalSalesTaxes_TradeInUnitLienPayout = formatToDecimal((String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealTotalSalesTaxes) ? Decimal.valueOf(this.DealTotalSalesTaxes.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TradeInUnitLienPayout) ? Decimal.valueOf(this.TradeInUnitLienPayout.replaceAll(',','')) : 0));
        this.SumOfTradeInTotalAndSecondTradeInUnitAllowance = formatToDecimal((String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SecondTradeInUnitAllowance) ? Decimal.valueOf(this.SecondTradeInUnitAllowance.replaceAll(',','')) : 0));
        this.SumOfAllDealUnitTotalPrices = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SecondUnitTotalPrice) ? Decimal.valueOf(this.SecondUnitTotalPrice.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.ThirdUnitTotalPrice) ? Decimal.valueOf(this.ThirdUnitTotalPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.FourthUnitTotalPrice) ? Decimal.valueOf(this.FourthUnitTotalPrice.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.FifthUnitTotalPrice) ? Decimal.valueOf(this.FifthUnitTotalPrice.replaceAll(',','')) : 0));
        this.DiffOfUnitTotalPriceAndSumOfTradeInTotalAndTradeInUnitLienPayoute = formatToDecimal((String.isNotBlank(this.SumOfAllDealUnitTotalPrices) ? Decimal.valueOf(this.SumOfAllDealUnitTotalPrices.replaceAll(',','')) : 0) -
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0) -
        (String.isNotBlank(this.TradeInUnitLienPayout) ? Decimal.valueOf(this.TradeInUnitLienPayout.replaceAll(',','')) : 0));
        this.ReidsSumOfFeesAndOtherPrices = formatToDecimal((String.isNotBlank(this.DiffOfUnitTotalPriceAndSumOfTradeInTotalAndTradeInUnitLienPayoute) ? Decimal.valueOf(this.DiffOfUnitTotalPriceAndSumOfTradeInTotalAndTradeInUnitLienPayoute.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.DealTotalSalesTaxes) ? Decimal.valueOf(this.DealTotalSalesTaxes.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.AllUnitsDOCTagUnitFee) ? Decimal.valueOf(this.AllUnitsDOCTagUnitFee.replaceAll(',','')) : 0));
        this.DiffOfReidsSumOfFeesAndOtherPricesAndDealTotalAmountPaid = formatToDecimal((String.isNotBlank(this.ReidsSumOfFeesAndOtherPrices) ? Decimal.valueOf(this.ReidsSumOfFeesAndOtherPrices.replaceAll(',','')) : 0) -
        (String.isNotBlank(this.DealTotalAmountPaid) ? Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',','')) : 0));
        this.UnitTaxForReids = formatToDecimal((String.isNotBlank(this.DifferenceOfUnitTotalPriceWithNonFeeOptionsAndTradeInTotal) ? (Decimal.valueOf(this.DifferenceOfUnitTotalPriceWithNonFeeOptionsAndTradeInTotal.replaceAll(',',''))) : 0) * (.0625)); //Calculation of 6.25% of DifferenceOfUnitTotalPriceWithNonFeeOptionsAndTradeInTotal
        this.SumOfTITLETagREGTagAndTRANTagUnitFee=  formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfTITLETagTRANTagUnitFeeAndUnitTotalSalesTax=  formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceDOCTagREGTagTITLETagUnitFee = formatToDecimal(
        (String.isNotBlank(this.SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceAndDOCTagUnitFee) ? (Decimal.valueOf(this.SumOfUnitTotalBasePriceTradeInTotalNetPurchasePriceAndDOCTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0));
        // SumOfNetPurchasePriceUnitTotalSalesTaxUnitFeeTITLETagUnitFee = NetPurchasePrice + UnitTotalSalesTax + UnitFeeTITLETagUnitFee
        this.SumOfNetPurchasePriceUnitTotalSalesTaxUnitFeeTITLETagUnitFee =  formatToDecimal((String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0));
        // SumOfNetPurchasePriceTITLETagLICTagTotalSalesTax = NetPurchasePrice + UnitFeeTITLETagUnitFee + UnitFeeLICTagUnitFee + UnitTotalSalesTax
        this.SumOfNetPurchasePriceTITLETagLICTagTotalSalesTax =  formatToDecimal((String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0));
        
        this.SumOfNetPurchasePriceTotalSalesTaxREGTagADMINTagUnitFee = formatToDecimal((String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.ADMINTagUnitFee) ? Decimal.valueOf(this.ADMINTagUnitFee.replaceAll(',','')) : 0));
        
        this.SumOfUnitTotalBasePriceUnitTotalSalesTaxTITLETagTRANTagREGTagDOCTagUnitFee = formatToDecimal((String.isNotBlank(this.UnitTotalBasePrice) ? (Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? (Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? (Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeDOCTagUnitFee) ? (Decimal.valueOf(this.UnitFeeDOCTagUnitFee.replaceAll(',',''))) : 0));

        this.SumOfDealTotalTradeInsAmountAndDealDeposit = formatToDecimal((String.isNotBlank(this.DealTotalTradeInsAmount) ? (Decimal.valueOf(this.DealTotalTradeInsAmount.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.DealTotalAmountPaid) ? (Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',',''))) : 0));

        this.DifferenceofTotalDownpaymentAndTotalCashPrice = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalBasePriceUnitTotalSalesTaxTITLETagTRANTagREGTagDOCTagUnitFee) ? (Decimal.valueOf(this.SumOfUnitTotalBasePriceUnitTotalSalesTaxTITLETagTRANTagREGTagDOCTagUnitFee.replaceAll(',',''))) : 0) -
        (String.isNotBlank(this.SumOfDealTotalTradeInsAmountAndDealDeposit) ? (Decimal.valueOf(this.SumOfDealTotalTradeInsAmountAndDealDeposit.replaceAll(',',''))) : 0));

        this.DifferenceOfUnitTotalPriceAndTradeInTotal = formatToDecimal(( String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0 ) - (String.isNotBlank(this.DealTotalTradeInsAmount) ? Decimal.valueOf(this.DealTotalTradeInsAmount.replaceAll(',','')) : 0 ));

        this.SumOfNetPriceUnitTotalSalesTaxTITLETagTRANTagLICTagUnitFee = formatToDecimal((String.isNotBlank(this.DifferenceOfUnitTotalPriceAndTradeInTotal) ? (Decimal.valueOf(this.DifferenceOfUnitTotalPriceAndTradeInTotal.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeLicTagUnitFee) ? (Decimal.valueOf(this.UnitFeeLicTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? (Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? (Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',',''))) : 0));
        //SumOfUnitFeeTITLEUnitFeeREGTotalSalesTax  = UnitFeeTITLETagUnitFee + UnitFeeREGTagUnitFee + UnitTotalSalesTax
        this.SumOfUnitFeeTITLEUnitFeeREGTotalSalesTax = formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0));
        //SumOfTotalBasePriceTotalSalesTaxAndTradeInTotal = UnitTotalBasePrice + UnitTotalSalesTax + TradeInTotal
        this.SumOfTotalBasePriceTotalSalesTaxAndTradeInTotal = formatToDecimal((String.isNotBlank(this.UnitTotalBasePrice) ? Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0));
        // SumOfTITLETagUnitFeeTotalSalesTax = UnitFeeTITLETagUnitFee + UnitTotalSalesTax
        this.SumOfTITLETagUnitFeeTotalSalesTax = formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0));
        this.SumOfFeeTITLETagFeeLICTagFeeDOCTagFee = formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.UnitFeeDOCTagUnitFee) ? Decimal.valueOf(this.UnitFeeDOCTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfFeeTITLETagFeeLICTagFeeDOCTagFeeUnitTotalPriceAndSalesTax = formatToDecimal((String.isNotBlank(this.SumOfFeeTITLETagFeeLICTagFeeDOCTagFee) ? Decimal.valueOf(this.SumOfFeeTITLETagFeeLICTagFeeDOCTagFee.replaceAll(',','')) : 0) + (String.isNotBlank(this.SumOfUnitTotalPriceAndSalesTax) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndSalesTax.replaceAll(',','')) : 0));
        this.SumOfDealPartAndFeePrice1To3TotalAndUnitTotalPriceAndSalesTax = formatToDecimal((String.isNotBlank(this.DealPartAndFeePrice1To3Total) ? Decimal.valueOf(this.DealPartAndFeePrice1To3Total.replaceAll(',','')) : 0) + (String.isNotBlank(this.SumOfUnitTotalPriceAndSalesTax) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndSalesTax.replaceAll(',','')) : 0));
        this.SumOfDealPartAndFeePrice1To5TotalAndUnitTotalPriceAndSalesTax = formatToDecimal((String.isNotBlank(this.DealPartAndFeePrice1To5Total) ? Decimal.valueOf(this.DealPartAndFeePrice1To5Total.replaceAll(',','')) : 0) + (String.isNotBlank(this.SumOfUnitTotalPriceAndSalesTax) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndSalesTax.replaceAll(',','')) : 0));
        this.SumOfUnitTotalOptionsAndFeesAndUnitTotalPriceAndSalesTax = formatToDecimal((String.isNotBlank(this.UnitTotalOptionsAndFees) ? Decimal.valueOf(this.UnitTotalOptionsAndFees.replaceAll(',','')) : 0) + (String.isNotBlank(this.SumOfUnitTotalPriceAndSalesTax) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndSalesTax.replaceAll(',','')) : 0));
        this.DiffOfTradeInTotalAndTotalLienPayout = formatToDecimal((String.isNotBlank(this.DealTotalTradeInsAmount) ? Decimal.valueOf(this.DealTotalTradeInsAmount.replaceAll(',','')) : 0) - (String.isNotBlank(this.DealTotalLienPayoutAmount) ? Decimal.valueOf(this.DealTotalLienPayoutAmount.replaceAll(',','')) : 0));
        this.DiffOfTradeInTotalAndTotalLienPayoutAndDealTotalAmountPaid = formatToDecimal((String.isNotBlank(this.DiffOfTradeInTotalAndTotalLienPayout) ? Decimal.valueOf(this.DiffOfTradeInTotalAndTotalLienPayout.replaceAll(',','')) : 0) - (String.isNotBlank(this.DealTotalAmountPaid) ? Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',','')) : 0));
        this.NetTradeAllowanceAndDealTotalAmountPaid = formatToDecimal((String.isNotBlank(this.DiffOfTradeInTotalAndTotalLienPayout) ? Decimal.valueOf(this.DiffOfTradeInTotalAndTotalLienPayout.replaceAll(',','')) : 0) + (String.isNotBlank(this.DealTotalAmountPaid) ? Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',','')) : 0));
        this.TotalBalanceDueForAMPR = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalOptionsAndFeesAndUnitTotalPriceAndSalesTax) ? Decimal.valueOf(this.SumOfUnitTotalOptionsAndFeesAndUnitTotalPriceAndSalesTax.replaceAll(',','')) : 0) - (String.isNotBlank(this.NetTradeAllowanceAndDealTotalAmountPaid) ? Decimal.valueOf(this.NetTradeAllowanceAndDealTotalAmountPaid.replaceAll(',','')) : 0));
		
        this.DiffOFUnitTotalBasePriceTotalOptionsAndFeesAndTradeInTotal = formatToDecimal(((String.isNotBlank(this.UnitTotalBasePrice) ? Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalOptionsAndFees) ? Decimal.valueOf(this.UnitTotalOptionsAndFees.replaceAll(',','')) : 0))-
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0)
        );

        this.SumOfDealDepositAndDealFinanceDownPayment = formatToDecimal((String.isNotBlank(this.DealDeposit) ? Decimal.valueOf(this.DealDeposit.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealFinanceDownPayment) ? Decimal.valueOf(this.DealFinanceDownPayment.replaceAll(',','')) : 0));

        this.TotalBalanceDueExpertAuto = formatToDecimal((String.isNotBlank(this.DiffOFUnitTotalBasePriceTotalOptionsAndFeesAndTradeInTotal) ? Decimal.valueOf(this.DiffOFUnitTotalBasePriceTotalOptionsAndFeesAndTradeInTotal.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.PSTOnlyUnitSale) ? Decimal.valueOf(this.PSTOnlyUnitSale.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.GSTOnlyUnitSale) ? Decimal.valueOf(this.GSTOnlyUnitSale.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TradeInUnitLienPayout) ? Decimal.valueOf(this.TradeInUnitLienPayout.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.SumOfDealDepositAndDealFinanceDownPayment) ? Decimal.valueOf(this.SumOfDealDepositAndDealFinanceDownPayment.replaceAll(',','')) : 0));

        this.BalanceOnDeliveryExpertAuto = formatToDecimal((String.isNotBlank(this.TotalBalanceDueExpertAuto) ? Decimal.valueOf(this.TotalBalanceDueExpertAuto.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.DealAmountFinanced) ? Decimal.valueOf(this.DealAmountFinanced.replaceAll(',','')) : 0));
        this.SumOfFeeTITLETagFeeLICTagFee = formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+(String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfFeeTITLETagFeeLICTagDealTotalSalesTaxes = formatToDecimal((String.isNotBlank(this.SumOfFeeTITLETagFeeLICTagFee) ? Decimal.valueOf(this.SumOfFeeTITLETagFeeLICTagFee.replaceAll(',','')) : 0)+(String.isNotBlank(this.DealTotalSalesTaxes) ? Decimal.valueOf(this.DealTotalSalesTaxes.replaceAll(',','')) : 0));
        this.SumOfADMINTagPLATETagTITLETagTRANUnitFeeAndTotalSalesTax = formatToDecimal((String.isNotBlank(this.ADMINTagUnitFee) ? Decimal.valueOf(this.ADMINTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.PLATETagUnitFee) ? Decimal.valueOf(this.PLATETagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0));
        this.SumOfUnitTotalPriceTRANUnitFeeREGTagUnitFeeGSTOnlyUnitSale = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.GSTOnlyUnitSale) ? Decimal.valueOf(this.GSTOnlyUnitSale.replaceAll(',','')) : 0));
        // DiffOfBasePricePlusUnitTotalOptionsAndFeesAndTradeInTotal = UnitTotalBasePrice + UnitTotalOptionsAndFees - TradeInTotal
        this.DiffOfBasePricePlusUnitTotalOptionsAndFeesAndTradeInTotal = formatToDecimal((String.isNotBlank(this.UnitTotalBasePrice) ? Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.UnitTotalOptionsAndFees) ? Decimal.valueOf(this.UnitTotalOptionsAndFees.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0));
        // SubtotalForProMarine = DiffOfBasePricePlusUnitTotalOptionsAndFeesAndTradeInTotal + DealTotalSalesTaxes + UnitFeeLICTagUnitFee +UCCFilingTagUnitFee
        this.SubtotalForProMarine = formatToDecimal((String.isNotBlank(this.DiffOfBasePricePlusUnitTotalOptionsAndFeesAndTradeInTotal) ? Decimal.valueOf(this.DiffOfBasePricePlusUnitTotalOptionsAndFeesAndTradeInTotal.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.DealTotalSalesTaxes) ? Decimal.valueOf(this.DealTotalSalesTaxes.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0)+
		(String.isNotBlank(this.UCCFilingTagUnitFee) ? Decimal.valueOf(this.UCCFilingTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfNetPurchasePriceAndDOCTagUnitFee = formatToDecimal((String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeDOCTagUnitFee) ? Decimal.valueOf(this.UnitFeeDOCTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfNetPurchasePriceDOCTagUnitFeeLICTagUnitFeeAndUnitTotalSalesTax = formatToDecimal((String.isNotBlank(this.SumOfNetPurchasePriceAndDOCTagUnitFee) ? Decimal.valueOf(this.SumOfNetPurchasePriceAndDOCTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0));
        this.DiffOfUnitTotalPriceWithSalesTaxAndDealTotalAmountPaid = formatToDecimal((String.isNotBlank(this.UnitTotalPriceWithSalesTax) ? Decimal.valueOf(this.UnitTotalPriceWithSalesTax.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.DealTotalAmountPaid) ? Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',','')) : 0));
        this.UnitTotalPricePartLaborPartNDealTotalFeeStampduty = formatToDecimal(
        (String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealTotalPartsAndLaborAmount) ? Decimal.valueOf(this.DealTotalPartsAndLaborAmount.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealTotalFee) ? Decimal.valueOf(this.DealTotalFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TotalStampduty) ? Decimal.valueOf(this.TotalStampduty.replaceAll(',','')) : 0));
        this.TotalPurchaseAmountForBusStop = formatToDecimal(
        (String.isNotBlank(this.UnitTotalPricePartLaborPartNDealTotalFeeStampduty) ? Decimal.valueOf(this.UnitTotalPricePartLaborPartNDealTotalFeeStampduty.replaceAll(',','')) : 0)- 
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.DealDeposit) ? Decimal.valueOf(this.DealDeposit.replaceAll(',','')) : 0));
        this.SumOfDealTotalAndGSTOnlyUnitSale = formatToDecimal(
        (String.isNotBlank(this.DealTotal) ? Decimal.valueOf(this.DealTotal.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.GSTOnlyUnitSale) ? Decimal.valueOf(this.GSTOnlyUnitSale.replaceAll(',','')) : 0));
        this.SumOfDealTotalFeeAndStampduty = formatToDecimal((String.isNotBlank(this.DealTotalFee) ? Decimal.valueOf(this.DealTotalFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TotalStampduty) ? Decimal.valueOf(this.TotalStampduty.replaceAll(',','')) : 0));
        this.HighwayTaxForIDealCarsTrailers = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? (( Decimal.valueOf(this.UnitTotalPrice.replaceAll(',',''))*3) / 100).setScale(2, RoundingMode.HALF_UP) : 0));
        this.SumOfUnitTotalPriceAndHighwayTax = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.HighwayTaxForIDealCarsTrailers) ? Decimal.valueOf(this.HighwayTaxForIDealCarsTrailers.replaceAll(',','')) : 0));
        this.SumOfDealDepositAndTradeInTotal= formatToDecimal((String.isNotBlank(this.DealDeposit) ? Decimal.valueOf(this.DealDeposit.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0));
        this.DiffOfUnitTotalPriceHighwayTaxAndDealDepositTradeInTotal= formatToDecimal((String.isNotBlank(this.SumOfUnitTotalPriceAndHighwayTax) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndHighwayTax.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.SumOfDealDepositAndTradeInTotal) ? Decimal.valueOf(this.SumOfDealDepositAndTradeInTotal.replaceAll(',','')) : 0));
        this.SumOfLICTagFeeREGTagFee = formatToDecimal((String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0));
        this.SumOfTITLETagLICTagAndREGagUnitFee=  formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfDealTotalTradeInsAndGSTAmount = formatToDecimal((String.isNotBlank(this.DealTotalTradeInsAmount) ? Decimal.valueOf(this.DealTotalTradeInsAmount.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.GSTOnlyUnitSale) ? Decimal.valueOf(this.GSTOnlyUnitSale.replaceAll(',','')) : 0));
        this.SumOfPlateTransferVINInspectionAndVINTrade = formatToDecimal((String.isNotBlank(this.PlateTransferFeeCodeUnitFee) ? Decimal.valueOf(this.PlateTransferFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.VINInspectionFeeCodeUnitFee) ? Decimal.valueOf(this.VINInspectionFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.VINTradeFeeCodeUnitFee) ? Decimal.valueOf(this.VINTradeFeeCodeUnitFee.replaceAll(',','')) : 0));

        this.SumOfTitleRegPlateTransferVINInspectionAndVINTrade = formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.PlateTransferFeeCodeUnitFee) ? Decimal.valueOf(this.PlateTransferFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.VINInspectionFeeCodeUnitFee) ? Decimal.valueOf(this.VINInspectionFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.VINTradeFeeCodeUnitFee) ? Decimal.valueOf(this.VINTradeFeeCodeUnitFee.replaceAll(',','')) : 0));

        this.SumOfESCNintyDayWarrantyPrepaid_MaintenanceFeeCode = formatToDecimal((String.isNotBlank(this.ESCCodeUnitFee) ? Decimal.valueOf(this.ESCCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.NintyDay_WarrantyFeeCodeUnitFee) ? Decimal.valueOf(this.NintyDay_WarrantyFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.Prepaid_MaintenanceFeeCodeUnitFee) ? Decimal.valueOf(this.Prepaid_MaintenanceFeeCodeUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice1) ? Decimal.valueOf(this.DealPartAndFeePrice1.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice2) ? Decimal.valueOf(this.DealPartAndFeePrice2.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealPartAndFeePrice3) ? Decimal.valueOf(this.DealPartAndFeePrice3.replaceAll(',','')) : 0));

        this.SumOfTotalBasePriceTotalSaletaxAndVeriousFeeForMPLaw = formatToDecimal((String.isNotBlank(this.UnitTotalBasePrice) ? Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOfTitleRegPlateTransferVINInspectionAndVINTrade) ? Decimal.valueOf(this.SumOfTitleRegPlateTransferVINInspectionAndVINTrade.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOfESCNintyDayWarrantyPrepaid_MaintenanceFeeCode) ? Decimal.valueOf(this.SumOfESCNintyDayWarrantyPrepaid_MaintenanceFeeCode.replaceAll(',','')) : 0));

        this.UnpaidBalanceOfCashSalesPrice = formatToDecimal((String.isNotBlank(this.SumOfTotalBasePriceTotalSaletaxAndVeriousFeeForMPLaw) ? Decimal.valueOf(this.SumOfTotalBasePriceTotalSaletaxAndVeriousFeeForMPLaw.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.SumOfTradeInTotalAndDealTotalAmountPaid) ? Decimal.valueOf(this.SumOfTradeInTotalAndDealTotalAmountPaid.replaceAll(',','')) : 0));
        this.SubTotalRRVSalesContract = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.DealPartAndFeePrice1) ? Decimal.valueOf(this.DealPartAndFeePrice1.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.DealPartAndFeePrice2) ? Decimal.valueOf(this.DealPartAndFeePrice2.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.DealPartAndFeePrice3) ? Decimal.valueOf(this.DealPartAndFeePrice3.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.DealPartAndFeePrice4) ? Decimal.valueOf(this.DealPartAndFeePrice4.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.DealPartAndFeePrice5) ? Decimal.valueOf(this.DealPartAndFeePrice5.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.DealerDeliveryUnitFee) ? Decimal.valueOf(this.DealerDeliveryUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.ConsumerCreditInsurance) ? Decimal.valueOf(this.ConsumerCreditInsurance.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.InsuranceDealProduct) ? Decimal.valueOf(this.InsuranceDealProduct.replaceAll(',','')) : 0));
        this.PurchasePriceInclusiveOfGST = formatToDecimal((String.isNotBlank(this.SubTotalRRVSalesContract) ? Decimal.valueOf(this.SubTotalRRVSalesContract.replaceAll(',','')) : 0 )+
        (String.isNotBlank(this.GSTOnlyUnitSale) ? Decimal.valueOf(this.GSTOnlyUnitSale.replaceAll(',','')) : 0));
        this.TotalPurchasePriceForRRVSalesContract = formatToDecimal((String.isNotBlank(this.SubTotalRRVSalesContract) ? Decimal.valueOf(this.SubTotalRRVSalesContract.replaceAll(',','')) : 0 ) +
        (String.isNotBlank(this.TotalStampduty) ? Decimal.valueOf(this.TotalStampduty.replaceAll(',','')) : 0 ) +
        (String.isNotBlank(this.UnitFeeLicTagUnitFee) ? Decimal.valueOf(this.UnitFeeLicTagUnitFee.replaceAll(',','')) : 0));
        this.TotalSattlementRRVSaleContract = formatToDecimal((String.isNotBlank(this.SumOfDealTotalTradeInsAndGSTAmount) ? Decimal.valueOf(this.SumOfDealTotalTradeInsAndGSTAmount.replaceAll(',','')) : 0 ) +
        (String.isNotBlank(this.TradeInUnitLienPayout) ? Decimal.valueOf(this.TradeInUnitLienPayout.replaceAll(',','')) : 0 ) +
        (String.isNotBlank(this.DealTotalAmountPaid) ? Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',','')) : 0));
        //Total of Unit total price with Stamp Duty and DealerInstalled Option
        this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitTotalDealerInstalledOptions) ? Decimal.valueOf(this.UnitTotalDealerInstalledOptions.replaceAll(',','')) : 0));
        //Total of Unit total price without Stamp Duty and DealerInstalled Option
        this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptionsWithoutStampDuty = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions.replaceAll(',','')) : 0) - 
        (String.isNotBlank(this.TotalStampduty) ? Decimal.valueOf(this.TotalStampduty.replaceAll(',','')) : 0));
        this.DiffOfSumOfUnitTotalPriceAndUnitTotalDealerInstalledOptionsAndTradeInTotal = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0));
        this.MPSportsAmountDue = formatToDecimal((String.isNotBlank(this.DiffOfSumOfUnitTotalPriceAndUnitTotalDealerInstalledOptionsAndTradeInTotal) ? Decimal.valueOf(this.DiffOfSumOfUnitTotalPriceAndUnitTotalDealerInstalledOptionsAndTradeInTotal.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TradeInUnitLienPayout) ? Decimal.valueOf(this.TradeInUnitLienPayout.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.ProcessingCodeUnitFee) ? Decimal.valueOf(this.ProcessingCodeUnitFee.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.DealTotalAmountPaid) ? Decimal.valueOf(this.DealTotalAmountPaid.replaceAll(',','')) : 0));
        this.NewWorldRVAmountOfTaxCollected =  formatToDecimal((String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',','')) : 0) * 0.06);
        this.SumOfTITLETagTRANTagREGTagLIENTagUnitFee = formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? (Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeLIENTagUnitFee) ? (Decimal.valueOf(this.UnitFeeLIENTagUnitFee.replaceAll(',',''))) : 0));
        this.SumOfUnitTotalSalesTaxTITLETagTRANTagREGTagLIENTagUnitFee = formatToDecimal((String.isNotBlank(this.UnitTotalSalesTax) ? (Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? (Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeLIENTagUnitFee) ? (Decimal.valueOf(this.UnitFeeLIENTagUnitFee.replaceAll(',',''))) : 0));
        this.SumOfTITLETagTranTagLICTagAndREGagUnitFee = formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0));
        this.DiffOfUnitTotalPriceDealerInstalledOptionsAndTradeInTotal = formatToDecimal((( String.isNotBlank(this.UnitTotalPrice) ? Decimal.valueOf(this.UnitTotalPrice.replaceAll(',','')) : 0 ) +
        (String.isNotBlank(this.UnitTotalDealerInstalledOptions) ? (Decimal.valueOf(this.UnitTotalDealerInstalledOptions.replaceAll(',',''))) : 0)) - 
        (String.isNotBlank(this.TradeInTotal) ? Decimal.valueOf(this.TradeInTotal.replaceAll(',','')) : 0 ));
        this.TotalSalePriceFRVBuyersOrder = formatToDecimal(( String.isNotBlank(this.DiffOfUnitTotalPriceDealerInstalledOptionsAndTradeInTotal) ? Decimal.valueOf(this.DiffOfUnitTotalPriceDealerInstalledOptionsAndTradeInTotal.replaceAll(',','')) : 0 ) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? (Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',',''))) : 0) + 
        (String.isNotBlank(this.SumOfTITLETagTranTagLICTagAndREGagUnitFee) ? (Decimal.valueOf(this.SumOfTITLETagTranTagLICTagAndREGagUnitFee.replaceAll(',',''))) : 0) + 
        (String.isNotBlank(this.UnitFeeDOCTagUnitFee) ? (Decimal.valueOf(this.UnitFeeDOCTagUnitFee.replaceAll(',',''))) : 0));
        this.SecondNetPurchasePrice = formatToDecimal((String.isNotBlank(this.SecondUnitTotalPrice) ? (Decimal.valueOf(this.SecondUnitTotalPrice.replaceAll(',',''))) : 0) - (String.isNotBlank(this.SecondTradeInUnitTotal) ? (Decimal.valueOf(this.SecondTradeInUnitTotal.replaceAll(',',''))) : 0 ));
        this.SumOfFirstandSecondTradeInUnitTotal = formatToDecimal((String.isNotBlank(this.TradeInTotal) ? (Decimal.valueOf(this.TradeInTotal.replaceAll(',',''))) : 0) + (String.isNotBlank(this.SecondTradeInUnitTotal) ? (Decimal.valueOf(this.SecondTradeInUnitTotal.replaceAll(',',''))) : 0 ));
        this.SumOfFirstandSecondUnitTotal = formatToDecimal((String.isNotBlank(this.UnitTotalPrice) ? (Decimal.valueOf(this.UnitTotalPrice.replaceAll(',',''))) : 0) + (String.isNotBlank(this.SecondUnitTotalPrice) ? (Decimal.valueOf(this.SecondUnitTotalPrice.replaceAll(',',''))) : 0 ));
        this.TotalNetPurchasePrice = formatToDecimal((String.isNotBlank(this.SumOfFirstandSecondUnitTotal) ? (Decimal.valueOf(this.SumOfFirstandSecondUnitTotal.replaceAll(',',''))) : 0) - (String.isNotBlank(this.SumOfFirstandSecondTradeInUnitTotal) ? (Decimal.valueOf(this.SumOfFirstandSecondTradeInUnitTotal.replaceAll(',',''))) : 0 ));
        if(String.isNotBlank(this.BusinessName)) {
            if(this.BusinessName.substring(0,3).equalsIgnoreCase('RTR')){
                this.PolicyNumber = this.BusinessName.substring(0,3).toUppercase();
            } else{
                for(String temp : this.BusinessName.trim().split(' ')){
                    this.PolicyNumber += ((temp != null && temp.subString(0, 1).isalpha()) ? temp.subString(0, 1).toUppercase() : '');
                }
            }
        }
        this.PolicyNumber += (String.isNotBlank(this.UnitVIN) && this.UnitVIN.length() > 8) ? this.UnitVIN.subString(this.UnitVIN.length()-8, this.UnitVIN.length()) : this.UnitVIN;
        this.SumOfUnitTotalDealerInstalledOptionsAndDealTotalFee = formatToDecimal((String.isNotBlank(this.UnitTotalDealerInstalledOptions) ? (Decimal.valueOf(this.UnitTotalDealerInstalledOptions.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.DealTotalFee) ? (Decimal.valueOf(this.DealTotalFee.replaceAll(',',''))) : 0));
        this.DifferenceOfUnitOtherData02WithUnitOtherData01 = formatToDecimal((String.isNotBlank(this.UnitOtherData02) && BPUtility.isDecimal(this.UnitOtherData02) ? (Decimal.valueOf(this.UnitOtherData02.replaceAll(',',''))) : 0) -
        (String.isNotBlank(this.UnitOtherData01) && BPUtility.isDecimal(this.UnitOtherData01) ? (Decimal.valueOf(this.UnitOtherData01.replaceAll(',',''))) : 0));
        this.SumOfUnitData01AndUnitData02 = formatToDecimal((String.isNotBlank(this.UnitOtherData01) && BPUtility.isDecimal(this.UnitOtherData01) ? (Decimal.valueOf(this.UnitOtherData01.replaceAll(',',''))) : 0)+
        (String.isNotBlank(this.UnitOtherData02) && BPUtility.isDecimal(this.UnitOtherData02) ? (Decimal.valueOf(this.UnitOtherData02.replaceAll(',',''))) : 0));
        this.SumOfTITLETagLICTagAndREGTagUnitFee = formatToDecimal((String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeLICTagUnitFee) ? Decimal.valueOf(this.UnitFeeLICTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfDealTotalTITLETagLICTagAndREGTagUnitFee = formatToDecimal((String.isNotBlank(this.SumOfTITLETagLICTagAndREGTagUnitFee) ? Decimal.valueOf(this.SumOfTITLETagLICTagAndREGTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealTotal) ? Decimal.valueOf(this.DealTotal.replaceAll(',','')) : 0));
        this.SumOfBasePricePartsPriceFRTOUTFeeAndFETTax = formatToDecimal(( String.isNotBlank(this.UnitTotalBasePrice) ? Decimal.valueOf(this.UnitTotalBasePrice.replaceAll(',','')) : 0 ) + (String.isNotBlank(this.TotalDealPartPrice) ? Decimal.valueOf(this.TotalDealPartPrice.replaceAll(',','')) : 0 ) + (String.isNotBlank(this.FRTOUTCodeUnitFee) ? Decimal.valueOf(this.FRTOUTCodeUnitFee.replaceAll(',','')) : 0 ) + (String.isNotBlank(this.FETTaxAmount) ? Decimal.valueOf(this.FETTaxAmount.replaceAll(',','')) : 0 ));
        this.SumOfProductDealFinanceEstimatedPaymentAndLoanTermAndDealDeposit = formatToDecimal((String.isNotBlank(this.ProductDealFinanceEstimatedPaymentAndLoanTerm) ? Decimal.valueOf(this.ProductDealFinanceEstimatedPaymentAndLoanTerm.replaceAll(',','')) : 0) + 
        (String.isNotBlank(this.DealDeposit) ? Decimal.valueOf(this.DealDeposit.replaceAll(',','')) : 0));
        this.SumOfLicTagREGTagAndTRANTagUnitFee=  formatToDecimal((String.isNotBlank(this.UnitFeeLicTagUnitFee) ? Decimal.valueOf(this.UnitFeeLicTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfUnitTotalPriceTotalInstalledOptionsStampdutyREGTagTRANUnitFee = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TotalStampduty) ? Decimal.valueOf(this.TotalStampduty.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfUnitTotalPriceWithAllOptionsAndDealTotalFees = formatToDecimal((String.isNotBlank(this.UnitTotalPriceWithAllOptions) ? Decimal.valueOf(this.UnitTotalPriceWithAllOptions.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealTotalFee) ? Decimal.valueOf(this.DealTotalFee.replaceAll(',','')) : 0));
        this.SumOfPlateTranTitleFeesAndDealTotalSalesTaxes = formatToDecimal((String.isNotBlank(this.PLATETagUnitFee) ? Decimal.valueOf(this.PLATETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeTRANTagUnitFee) ? Decimal.valueOf(this.UnitFeeTRANTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.DealTotalSalesTaxes) ? Decimal.valueOf(this.DealTotalSalesTaxes.replaceAll(',','')) : 0));
        this.SumOfPlateTranTitleFeesDealTotalSalesTaxesUnitTotalPriceWithAllOptionsAndDealTotalFees = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalPriceWithAllOptionsAndDealTotalFees) ? Decimal.valueOf(this.SumOfUnitTotalPriceWithAllOptionsAndDealTotalFees.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOfPlateTranTitleFeesAndDealTotalSalesTaxes) ? Decimal.valueOf(this.SumOfPlateTranTitleFeesAndDealTotalSalesTaxes.replaceAll(',','')) : 0));
        this.SumOFDOCTagUnitFeeAndPartsAddedToDeal = formatToDecimal((String.isNotBlank(this.AllUnitsDOCTagUnitFee) ? Decimal.valueOf(this.AllUnitsDOCTagUnitFee.replaceAll(',','')) : 0) + 
        (String.isNotBlank(this.DealTotalOptionsParts) ? Decimal.valueOf(this.DealTotalOptionsParts.replaceAll(',','')) : 0));
        
        this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsStampDutyAndNoTagFee = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptions.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOFDOCTagUnitFeeAndPartsAddedToDeal) ? Decimal.valueOf(this.SumOFDOCTagUnitFeeAndPartsAddedToDeal.replaceAll(',','')) : 0));
        
        this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsAndDOCTagUnitFee = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptionsWithoutStampDuty) ? Decimal.valueOf(this.SumOfUnitTotalPriceAndUnitTotalDealerInstalledOptionsWithoutStampDuty.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOFDOCTagUnitFeeAndPartsAddedToDeal) ? Decimal.valueOf(this.SumOFDOCTagUnitFeeAndPartsAddedToDeal.replaceAll(',','')) : 0));
        
        this.SumOfRegtTitleFeeAndSalesTax = formatToDecimal((String.isNotBlank(this.UnitFeeREGTagUnitFee) ? (Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? (Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',',''))) : 0) +
        (String.isNotBlank(this.UnitTotalSalesTax) ? (Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',',''))) : 0));
        this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsStampDutyNoTagFeeRegtTitleFeeAndSalesTax = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsStampDutyAndNoTagFee) ? Decimal.valueOf(this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsStampDutyAndNoTagFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOfRegtTitleFeeAndSalesTax) ? Decimal.valueOf(this.SumOfRegtTitleFeeAndSalesTax.replaceAll(',','')) : 0));
        this.SumOfDealTotalStampdutyRegTagUnitFee =  formatToDecimal((String.isNotBlank(this.DealTotal) ? Decimal.valueOf(this.DealTotal.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.TotalStampduty) ? Decimal.valueOf(this.TotalStampduty.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitFeeREGTagUnitFee) ? Decimal.valueOf(this.UnitFeeREGTagUnitFee.replaceAll(',','')) : 0));
        this.SumOfUnitTotalWithFactoryDealerInstalledPartLaborOptionsStampDutyNoTagFeeRegtTitleFeeAndSalesTax = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsStampDutyAndNoTagFee) ? Decimal.valueOf(this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsStampDutyAndNoTagFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOfRegtTitleFeeAndSalesTax) ? Decimal.valueOf(this.SumOfRegtTitleFeeAndSalesTax.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitTotalOptionsLabor) ? Decimal.valueOf(this.UnitTotalOptionsLabor.replaceAll(',','')) : 0));
        
        this.SumOfUnitTotalWithFactoryDealerInstalledPartLaborOptionsAndDOCTagUnitFeeRegtTitleFeeAndSalesTax = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsAndDOCTagUnitFee) ? Decimal.valueOf(this.SumOfUnitTotalWithFactoryDealerInstalledPartOptionsAndDOCTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.SumOfRegtTitleFeeAndSalesTax) ? Decimal.valueOf(this.SumOfRegtTitleFeeAndSalesTax.replaceAll(',','')) : 0) +
        (String.isNotBlank(this.UnitTotalOptionsLabor) ? Decimal.valueOf(this.UnitTotalOptionsLabor.replaceAll(',','')) : 0));

        this.SumOfUnitTotalOptionsAndFeesAndUnitTotalPriceWithSalesTax = formatToDecimal((String.isNotBlank(this.unitTotalPriceWithSalesTax) ? Decimal.valueOf(this.unitTotalPriceWithSalesTax.replaceAll(',','')) : 0) + 
        (String.isNotBlank(this.UnitTotalOptionsAndFees) ? Decimal.valueOf(this.UnitTotalOptionsAndFees.replaceAll(',','')) : 0));
        this.SevenPercOfNetPurchasePrice = formatToDecimal((String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',',''))*0.07 : 0));
        this.DealAmountFinancedMinusCommission = formatToDecimal((String.isNotBlank(this.DealAmountFinanced) ? Decimal.valueOf(this.DealAmountFinanced.replaceAll(',','')) : 0) - 
        (String.isNotBlank(this.DealFinanceCommission) ? Decimal.valueOf(this.DealFinanceCommission.replaceAll(',','')) : 0));
        this.SumOfUnitTotalWithFactoryDealerInstalledPartLaborOptionsAndDOCTagUnitFeeRegtTitleFeeAndSalesTaxMinusDealDeposit = formatToDecimal((String.isNotBlank(this.SumOfUnitTotalWithFactoryDealerInstalledPartLaborOptionsAndDOCTagUnitFeeRegtTitleFeeAndSalesTax) ? Decimal.valueOf(this.SumOfUnitTotalWithFactoryDealerInstalledPartLaborOptionsAndDOCTagUnitFeeRegtTitleFeeAndSalesTax.replaceAll(',','')) : 0)-
        (String.isNotBlank(this.DealDeposit) ? Decimal.valueOf(this.DealDeposit.replaceAll(',','')) : 0));
        this.SumOfTREGTagUnitFeeAndTITLETagUnitFee = formatToDecimal((String.isNotBlank(this.TREGTagUnitFee) ? Decimal.valueOf(this.TREGTagUnitFee.replaceAll(',','')) : 0)+
        (String.isNotBlank(this.UnitFeeTITLETagUnitFee) ? Decimal.valueOf(this.UnitFeeTITLETagUnitFee.replaceAll(',','')) : 0));
        this.SevenPercOfNetBasePurchasePrice = formatToDecimal((String.isNotBlank(this.NetBasePurchasePrice) ? Decimal.valueOf(this.NetBasePurchasePrice.replaceAll(',',''))*0.07 : 0));
        this.VehicleBillofSaleSubTotal = formatToDecimal((String.isNotBlank(this.DifferenceOfTradeInTotalAndUnitTotal) ? Decimal.valueOf(this.DifferenceOfTradeInTotalAndUnitTotal.replaceAll(',','')) : 0)+ 
        (String.isNotBlank(this.UnitTotalSalesTax) ? Decimal.valueOf(this.UnitTotalSalesTax.replaceAll(',','')) : 0) + 
        (String.isNotBlank(this.UnitFeeLicTagUnitFee) ? Decimal.valueOf(this.UnitFeeLicTagUnitFee.replaceAll(',','')) : 0) + 
        (String.isNotBlank(this.UnitFeeGasTagUnitFee) ? Decimal.valueOf(this.UnitFeeGasTagUnitFee.replaceAll(',','')) : 0) + 
        (String.isNotBlank(this.TradeInUnitLienPayout) ? Decimal.valueOf(this.TradeInUnitLienPayout.replaceAll(',','')) : 0));
        this.SixPointTwoFivePercOfNetPurchasePrice = formatToDecimal((String.isNotBlank(this.NetPurchasePrice) ? Decimal.valueOf(this.NetPurchasePrice.replaceAll(',',''))*0.0625 : 0));
    }

    private void setCOBuyerFields(Account coBuyerRec) {
        this.CoBuyerName = coBuyerRec != null ? coBuyerRec.Name : '';
        this.CoBuyerLicenseNumber = coBuyerRec != null ? coBuyerRec.Drivers_License__c : '';
        
        if(coBuyerRec.Type__c == 'Individual') {
            this.CoBuyerFirstName = (coBuyerRec.FirstName__c != null) ? coBuyerRec.FirstName__c : '';
            this.CoBuyerLastName = (coBuyerRec.LastName__c != null) ? coBuyerRec.LastName__c : '';
            this.CoBuyerEmail = coBuyerRec.Email__c != null ? coBuyerRec.Email__c : '';
            this.CoBuyerPhoneNumber = coBuyerRec.Formatted_Home_number__c != null ? coBuyerRec.Formatted_Home_number__c : '';
        } else {
            this.CoBuyerFirstName = '';
            this.CoBuyerLastName = (coBuyerRec.Name != null)? coBuyerRec.Name : '';
            this.CoBuyerEmail = coBuyerRec.Work_Email__c != null ? coBuyerRec.Work_Email__c : '';
            this.CoBuyerPhoneNumber = coBuyerRec.Formatted_Work_Number__c != null ? coBuyerRec.Formatted_Work_Number__c : '';
        }
        
        String billingStreet = (coBuyerRec.BillingStreet == null ) ? '' : coBuyerRec.BillingStreet;
        List<String> bsList = billingStreet.split('\n');
        this.CoBuyerAddress1 = (bsList.size() > 0) ? bsList[0].replace('\n', ' ') : '';
        this.CoBuyerAddress2 = (bsList.size() > 1) ? bsList[1].replace('\n', ' ') : '';
        this.CoBuyerStreetAddress1and2 = this.CoBuyerAddress1 + ' ' + this.CoBuyerAddress2;
        this.CoBuyerCity = coBuyerRec.BillingCity != null ? coBuyerRec.BillingCity : '';
        this.CoBuyerState = coBuyerRec.BillingState != null ? coBuyerRec.BillingState : '';
        this.CoBuyerZipCode = coBuyerRec.BillingPostalCode != null ? coBuyerRec.BillingPostalCode : '';
        this.CoBuyerBillingCityState = this.CoBuyerCity + ' ' + this.CoBuyerState;
        this.CoBuyerAddress = this.CoBuyerStreetAddress1and2 + ' ' + this.CoBuyerCity + ' ' +  this.CoBuyerState + ' ' + this.CoBuyerZipCode;
        this.CoBuyerBillingCityStateZIPCode = this.CoBuyerCity + ' ' + this.CoBuyerState + ' ' + this.CoBuyerZipCode;
        this.CoBuyerDOB = coBuyerRec.Birth_Date__c != null ? BPUtility.getFormatedDateTime(Datetime.newInstance(coBuyerRec.Birth_Date__c.year(), coBuyerRec.Birth_Date__c.month(), coBuyerRec.Birth_Date__c.day())) : '';
        this.CoBuyerMobile = coBuyerRec.Formatted_Mobile_Number__c != null ? coBuyerRec.Formatted_Mobile_Number__c : '';
        this.CoBuyerDOBDay = coBuyerRec.Birth_Date__c != null ? String.valueOf(coBuyerRec.Birth_Date__c.day()) : '';
        this.CoBuyerDOBMonth = coBuyerRec.Birth_Date__c != null ? String.valueOf(coBuyerRec.Birth_Date__c.month()) : '';
        this.CoBuyerDOBYear = coBuyerRec.Birth_Date__c != null ? String.valueOf(coBuyerRec.Birth_Date__c.year()) : '';
        this.CoBuyerDLExpiryDate = coBuyerRec.Drivers_License_Expiry_Date__c != null ? BPUtility.getFormatedDateTime(Datetime.newInstance(coBuyerRec.Drivers_License_Expiry_Date__c.year(), coBuyerRec.Drivers_License_Expiry_Date__c.month(), coBuyerRec.Drivers_License_Expiry_Date__c.day())) : '';
        this.CoBuyerAgOtherID = coBuyerRec.Ag_Other_ID__c != null ? coBuyerRec.Ag_Other_ID__c : '';
        this.CoBuyerCompanyName = coBuyerRec.Company_Name__c != null ? coBuyerRec.Company_Name__c : '';
        this.CoBuyerMiddleName = coBuyerRec.Middle_Name__c != null ? coBuyerRec.Middle_Name__c : '';
        this.CoBuyerTaxID = coBuyerRec.Tax_ID__c != null ? coBuyerRec.Tax_ID__c : '';
        this.CoBuyerBillingCountyParish = coBuyerRec.Billing_County_Parish__c != null ? coBuyerRec.Billing_County_Parish__c : '';
        this.CoBuyerShippingCountyParish = coBuyerRec.Shipping_County_Parish__c != null ? coBuyerRec.Shipping_County_Parish__c : '';
        this.CoBuyerDOBLCDetails = String.isNotBlank(this.CoBuyerLicenseNumber) ? this.CoBuyerLicenseNumber : String.isNotBlank(this.CoBuyerDOB) ? this.CoBuyerDOB : '';

    }

    private void setShippingAddressFields(CO_Header__c coRec) {
        if(coRec != null && (coRec.Customer_Shipping_Address__c != null || coRec.Customer__c != null)) {
            String shippingStreet;
            if(coRec.Customer_Shipping_Address__c != null) {
                Contact shipAdd = coRec.Customer_Shipping_Address__r;
                shippingStreet = (shipAdd.MailingStreet == null ) ? '' : shipAdd.MailingStreet;
                this.CustomerShippingCity = String.isNotBlank(shipAdd.MailingCity) ? shipAdd.MailingCity : '';
                this.CustomerShippingCountyParish = shipAdd.Mailing_County_Parish__c != null ? String.valueOf(shipAdd.Mailing_County_Parish__c) : '';
                this.CustomerShippingState = String.isNotBlank(shipAdd.MailingState) ? shipAdd.MailingState : '';
                this.CustomerShippingZIPCode = String.isNotBlank(shipAdd.MailingPostalCode) ? shipAdd.MailingPostalCode : '';
                this.CustomerShippingCountry = (shipAdd.MailingCountry == null) ? '' : shipAdd.MailingCountry;
            } else if(coRec.Customer__c != null) {
                Account customerRec = coRec.Customer__r;
                shippingStreet = (customerRec.BillingStreet == null ) ? '' : customerRec.BillingStreet;
                this.CustomerShippingCity = String.isNotBlank(customerRec.BillingCity) ? customerRec.BillingCity : '';
                this.CustomerShippingCountyParish = customerRec.Billing_County_Parish__c != null ? String.valueOf(customerRec.Billing_County_Parish__c) : '';
                this.CustomerShippingState = String.isNotBlank(customerRec.BillingState) ? customerRec.BillingState : '';
                this.CustomerShippingZIPCode = String.isNotBlank(customerRec.BillingPostalCode) ? customerRec.BillingPostalCode : '';
                this.CustomerShippingCountry = (customerRec.BillingCountry == null) ? '' : customerRec.BillingCountry;
            }
            List<String> ssList = shippingStreet.split('\n');
            this.CustomerShippingStreetAddress1 = (ssList.size() > 0) ? ssList[0].replace('\n', ' ') : '';
            this.CustomerShippingStreetAddress2 = (ssList.size() > 1) ? ssList[1].replace('\n', ' ') : '';
            this.CustomerShippingStreetAddress1and2 = this.CustomerShippingStreetAddress1 + ' ' + this.CustomerShippingStreetAddress2;
            this.CustomershippingCityStateZipCode = this.CustomerShippingCity + ' ' + this.CustomerShippingState + ' ' + this.CustomerShippingZIPCode;
            this.CustomerShippingAddress = this.CustomerShippingStreetAddress1and2 + ' ' + this.CustomershippingCityStateZipCode;
            this.CustomerTwoLineShippingAddress = this.CustomerShippingAddress;
            this.CustomerShippingAddress = this.CustomerShippingAddress.replace('\r\n',' ');
            this.CustomerShippingAddress = this.CustomerShippingAddress.replace('\n',' ');
            this.CustomerShippingAddress = this.CustomerShippingAddress.replace('\r',' ');
            this.CustomerShippingStreetAddress1and2AndCity = ((String.isNotBlank(this.CustomerShippingStreetAddress1and2) ? this.CustomerShippingStreetAddress1and2+' ' : '') + (String.isNotBlank(this.CustomerShippingCity) ? this.CustomerShippingCity : '')).trim();
            
            this.ShippingMailingStreet = String.isNotBlank(this.CustomerShippingStreetAddress1and2) ? this.CustomerShippingStreetAddress1and2 : '';
            this.ShippingMailingCity = String.isNotBlank(this.CustomerShippingCity) ? this.CustomerShippingCity : '';
            this.ShippingMailingState = String.isNotBlank(this.CustomerShippingState) ? this.CustomerShippingState : '';
            this.ShippingMailingZIPCode = String.isNotBlank(this.CustomerShippingZIPCode) ? this.CustomerShippingZIPCode : '';
        }
    }
}