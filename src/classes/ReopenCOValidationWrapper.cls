/** 
* Author: Nidhi Sharma
* Since: July 28, 2021
* Name: ReopenCOValidationWrapper 
* Description: Apex class which contains Reopening co validation fields.
**/
public without sharing class ReopenCOValidationWrapper {
    
    public String ErrorMsg = '';
    public List<ConditionWrapper> ConditionList;
    public List<String> MessageList;
	
	public ReopenCOValidationWrapper(){}
	
	public ReopenCOValidationWrapper(String invoiceType, Map<String, Boolean> validationTextToFlagValueMap, String errorMsg) {
		setFields(invoiceType, validationTextToFlagValueMap, errorMsg);
	}
	
	public ReopenCOValidationWrapper(ReopenDealService.ReOpenDealValidationWrapper reopenDealValidationWrapper) {
		Map<String, Boolean> validationTextToFlagValueMap = new Map<String, Boolean>();
		if(reopenDealValidationWrapper != null) {
			validationTextToFlagValueMap.put(ReopenUtil.INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING, reopenDealValidationWrapper.AccEntriesCanBeRemoved);
			validationTextToFlagValueMap.put(ReopenUtil.SOLD_UNIT_CAN_BE_PUT_BACK_INTO_STOCK, reopenDealValidationWrapper.CanSoldUnitsBeReversed);
			validationTextToFlagValueMap.put(ReopenUtil.TRADE_INS_CAN_BE_ASSIGNED_BACK_TO_THE_CUSTOMER, reopenDealValidationWrapper.CanTradedInUnitsBeReversed);
			this.ErrorMsg = reopenDealValidationWrapper.ErrroMsg;
		}
		setFields(ReopenUtil.INVOICE_TYPE_DEAL, validationTextToFlagValueMap, this.ErrorMsg);
	}
	
	private void setFields(String invoiceType, Map<String, Boolean> validationTextToFlagValueMap, String errorMsg) {
		this.ConditionList = new List<ConditionWrapper>();
		this.MessageList = new List<String>();
		this.ErrorMsg = errorMsg;
		
		if(String.isNotBlank(invoiceType)) {
			if(validationTextToFlagValueMap != null && ReopenUtil.invoiceTypeToConditionTextsMap.containsKey(invoiceType)) {
				for(String conditionText : ReopenUtil.invoiceTypeToConditionTextsMap.get(invoiceType)) {
					if(conditionText.equalsIgnoreCase(ReopenUtil.INVOICE_CAN_BE_REMOVED_FROM_ACCOUNTING) && String.isBlank(AccountingUtil.activeAccIntegrationName)) {
						continue;
					}
					if(validationTextToFlagValueMap.containsKey(conditionText)) {
						this.ConditionList.add(new ConditionWrapper(conditionText, validationTextToFlagValueMap.get(conditionText)));
					} else {
						this.ConditionList.add(new ConditionWrapper(conditionText, false));
					}
				}
			}
			if(ReopenUtil.invoiceTypeToReopenMessageList.containsKey(invoiceType)) {
				for(String message : ReopenUtil.invoiceTypeToReopenMessageList.get(invoiceType)) {
					this.MessageList.add(message);
				}
			}
		}
	}
	
	public class ConditionWrapper {
		public String ConditionText;
		public Boolean IsValidToReopen;
		
		public ConditionWrapper(String text, Boolean isValid) {
			this.ConditionText = text;
			this.IsValidToReopen = isValid;
		}
	}
}