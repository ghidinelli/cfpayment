component accessors="true"
extends="cfpayment.api.model.response"
{
	property name="resultCode" 										getter="true" setter="true";
	property name="messageCode" 									getter="true" setter="true";
	property name="messageText" 									getter="true" setter="true";
	property name="customerProfileId"								getter="true" setter="true";
	property name="customerPaymentProfileIdList" 	type="array" 	getter="true" setter="true";
	property name="customerShippingAddressIdList" 	type="array" 	getter="true" setter="true";
	property name="validationDirectResponseList" 	type="array"	getter="true" setter="true";



	//Add items to arrays
	public void function addCustomerPaymentProfileId(String id){

		var paymentProfileList = getCustomerPaymentProfileIdList();
			paymentProfileList = isNull(paymentProfileList) ? [] : paymentProfileList;

			paymentProfileList.append(id);
			setCustomerPaymentProfileIdList(paymentProfileList);
	}
	public void function addCustomerShippingAddressId(Any id){
		var shipIDList = getCustomerPaymentProfileIdList();
				shipIDList = isNull(shipIDList) ? [] : shipIDList;

				shipIDList.append(id);
				setCustomerShippingAddressIdList(shipIDList);
	}

	public void function addvalidationDirectResponse(String  directResponse){
		var directResponseList = getValidationDirectResponseList();
			directResponseList = isNull(directResponseList) ? [] : directResponseList;
			
			directResponseList.append(directResponse);
			setValidationDirectResponseList(directResponseList);
	}
}