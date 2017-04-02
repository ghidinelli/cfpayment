/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is a customer that can be loaded and saved to the authorize.net system
	
	
	Licensed under the Apache License, Version 2.0 (the "License"); you 
	may not use this file except in compliance with the License. You may 
	obtain a copy of the License at:
	 
		http://www.apache.org/licenses/LICENSE-2.0
		 
	Unless required by applicable law or agreed to in writing, software 
	distributed under the License is distributed on an "AS IS" BASIS, 
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
	See the License for the specific language governing permissions and 
	limitations under the License.
*/
component accessors="true"
{


	//These properties are named in the same format so we can use the getMemento to create our sending packet 

	property name="customerVaultId" 					getter="true" setter="true";
	
	property name="card" 								getter="true" setter="true";

	//Billing Info
	property name="billingId" 		type="string"	getter="true"	setter="true";
	property name="firstName" 		type="string"	getter="true"	setter="true";
	property name="lastName" 		type="string"	getter="true"	setter="true";
	property name="company" 		type="string"	getter="true"	setter="true";
	property name="address" 		type="string"	getter="true"	setter="true";
	property name="address2" 		type="string"	getter="true"	setter="true";
	property name="city" 			type="string"	getter="true"	setter="true";
	property name="state" 			type="string"	getter="true"	setter="true";
	property name="zip" 			type="string"	getter="true"	setter="true";
	property name="country" 		type="string"	getter="true"	setter="true";
	property name="phoneNumber" 	type="string"	getter="true"	setter="true";
	property name="faxNumber" 		type="string"	getter="true"	setter="true";
	property name="email" 			type="string"	getter="true"	setter="true";


	//Shipping Info
	property name="shippingId" 		type="string"	getter="true"	setter="true";
	property name="shippingFirstname" 		type="string"	getter="true"	setter="true";
	property name="shippingLastname" 		type="string"	getter="true"	setter="true";
	property name="shippingCompany" 		type="string"	getter="true"	setter="true";
	property name="shippingAddress" 		type="string"	getter="true"	setter="true";
	property name="shippingAddress2" 		type="string"	getter="true"	setter="true";
	property name="shippingCity" 			type="string"	getter="true"	setter="true";
	property name="shippingState" 			type="string"	getter="true"	setter="true";
	property name="shippingZip" 			type="string"	getter="true"	setter="true";
	property name="shippingCountry" 		type="string"	getter="true"	setter="true";
	property name="shippingPhoneNumber" 	type="string"	getter="true"	setter="true";
	property name="shippingFaxNumber" 		type="string"	getter="true"	setter="true";
	property name="shippingEmail" 			type="string"	getter="true"	setter="true";
	//property name="processor_id" 						getter="true" setter="true";

	
	property name="payment" 							getter="true" setter="true" default="creditcard";
	property name="orderid"								getter="true" setter="true";
	property name="orderDescription"					getter="true" setter="true";


	//Should be an array
	property name="merchantDefinedField1" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField2" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField3" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField4" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField5" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField6" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField7" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField8" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField9" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField10" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField11" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField12" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField13" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField14" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField15" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField16" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField17" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField18" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField19" 				type="string"	getter="true" setter="true";
	property name="merchantDefinedField20" 				type="string"	getter="true" setter="true";

	//returned fields?
	property name="shippingCarrier" 					getter="true" setter="true";
	property name="shipping" 							getter="true" setter="true";
	property name="trackingNumber" 					getter="true" setter="true";
	property name="shippingDate" 						getter="true" setter="true";
	property name="cc_hash" 							getter="true" setter="true";
	property name="cc_bin" 								getter="true" setter="true";
// ponumber****
// tax****
// tax_exempt****
// shipping****
	
	//Takes a struct of data that comes in and populates the properties
	public any function populate(struct indata){
		var funcMapping ={
			"customer_vault_id" : setCustomerVaultId,
			"billing_id" : setBillingId,
			"first_name" : setFirstName,
			"last_name" : setLastName,
			"company" : setCompany,
			"address" : setAddress,
			"address_1" : setAddress,
			"address2" : setAddress2,
			"address_2" : setAddress2,
			"city" : setCity,
			"state" : setState,
			"zip" : setZip,
			"postal_code" : setZip,
			"country" : setCountry,
			"phone_number" : setPhoneNumber,
			"phone" : setPhoneNumber,
			"fax_number" : setFaxNumber,
			"fax" : setFaxNumber,
			"email" : setEmail,
			"shipping_id" : setShippingId,
			"shipping_firstname" : setShippingFirstname,
			"shipping_first_name" : setShippingFirstname,
			"shipping_lastname" : setShippingLastname,
			"shipping_last_name" : setShippingLastname,
			"shipping_company" : setShippingCompany,
			"shipping_address" : setShippingAddress,
			"shipping_address_1" : setShippingAddress,
			"shipping_address2" : setShippingAddress2,
			"shipping_address_2" : setShippingAddress2,
			"shipping_city" : setShippingCity,
			"shipping_state" : setShippingState,
			"shipping_zip" : setShippingZip,
			"shipping_postal_code" : setShippingZip,
			"shipping_country" : setShippingCountry,
			"shipping_phone_number" : setShippingPhoneNumber,
			"shipping_fax_number" : setShippingFaxNumber,
			"shipping_email" : setShippingEmail,
			//"processor_id" : setProcessorId,
			"payment" : setPayment,
			"orderid" : setOrderid,
			"order_description" : setOrderDescription,
			"merchant_defined_field1" : setMerchantDefinedField1,
			"merchant_defined_field2" : setMerchantDefinedField2,
			"merchant_defined_field3" : setMerchantDefinedField3,
			"merchant_defined_field4" : setMerchantDefinedField4,
			"merchant_defined_field5" : setMerchantDefinedField5,
			"merchant_defined_field6" : setMerchantDefinedField6,
			"merchant_defined_field7" : setMerchantDefinedField7,
			"merchant_defined_field8" : setMerchantDefinedField8,
			"merchant_defined_field9" : setMerchantDefinedField9,
			"merchant_defined_field10" : setMerchantDefinedField10,
			"merchant_defined_field11" : setMerchantDefinedField11,
			"merchant_defined_field12" : setMerchantDefinedField12,
			"merchant_defined_field13" : setMerchantDefinedField13,
			"merchant_defined_field14" : setMerchantDefinedField14,
			"merchant_defined_field15" : setMerchantDefinedField15,
			"merchant_defined_field16" : setMerchantDefinedField16,
			"merchant_defined_field17" : setMerchantDefinedField17,
			"merchant_defined_field18" : setMerchantDefinedField18,
			"merchant_defined_field19" : setMerchantDefinedField19,
			"merchant_defined_field20" : setMerchantDefinedField20,
			"shipping_carrier" : setShippingCarrier,
			"shipping" : setShipping,
			"tracking_number" : setTrackingNumber,
			"shipping_date" : setShippingDate,
			"cc_hash" : setCC_hash,
			"cc_bin" : setCC_bin,
		};


		//These are the keys that are ignored. We can ignore them generally 
		//var ignoredfields = "sec_code,check_name,account_holder_type,customertaxid,check_hash,processor_id,account_type,cc_issue_number,check_aba,check_account,cc_exp,website,cc_start_date,cc_number,cell_phone";
		for(var st in indata){
			if(st EQ "card"){
				//deal with cards differently?
				setCard(indata[st]);
			}
			else if (structKeyExists(funcMapping, st)){
				funcMapping[st](indata[st]); //Called the mapped function	
			}
			
		}
		
		return this;
	}
	public Struct function getMemento(){
		var ret = {
			"customer_vault_id" : getCustomerVaultId(),
			"billing_id" : getBillingId(),
			"first_name" : getFirstName(),
			"last_name" : getLastName(),
			"company" : getCompany(),
			"address" : getAddress(),
			"address2" : getAddress2(),
			"city" : getCity(),
			"state" : getState(),
			"zip" : getZip(),
			"country" : getCountry(),
			"phone_number" : getPhoneNumber(),
			"fax_number" : getFaxNumber(),
			"email" : getEmail(),
			"shipping_id" : getShippingId(),
			"shipping_firstname" : getShippingFirstname(),
			"shipping_lastname" : getShippingLastname(),
			"shipping_company" : getShippingCompany(),
			"shipping_address" : getShippingAddress(),
			"shipping_address2" : getShippingAddress2(),
			"shipping_city" : getShippingCity(),
			"shipping_state" : getShippingState(),
			"shipping_zip" : getShippingZip(),
			"shipping_country" : getShippingCountry(),
			"shipping_phone_number" : getShippingPhoneNumber(),
			"shipping_fax_number" : getShippingFaxNumber(),
			"shipping_email" : getShippingEmail(),
			//"processor_id" : getProcessorId(),
			"payment" : getPayment(),
			"orderid" : getOrderid(),
			"order_description" : getOrderDescription(),
			"merchant_defined_field1" : getMerchantDefinedField1(),
			"merchant_defined_field2" : getMerchantDefinedField2(),
			"merchant_defined_field3" : getMerchantDefinedField3(),
			"merchant_defined_field4" : getMerchantDefinedField4(),
			"merchant_defined_field5" : getMerchantDefinedField5(),
			"merchant_defined_field6" : getMerchantDefinedField6(),
			"merchant_defined_field7" : getMerchantDefinedField7(),
			"merchant_defined_field8" : getMerchantDefinedField8(),
			"merchant_defined_field9" : getMerchantDefinedField9(),
			"merchant_defined_field10" : getMerchantDefinedField10(),
			"merchant_defined_field11" : getMerchantDefinedField11(),
			"merchant_defined_field12" : getMerchantDefinedField12(),
			"merchant_defined_field13" : getMerchantDefinedField13(),
			"merchant_defined_field14" : getMerchantDefinedField14(),
			"merchant_defined_field15" : getMerchantDefinedField15(),
			"merchant_defined_field16" : getMerchantDefinedField16(),
			"merchant_defined_field17" : getMerchantDefinedField17(),
			"merchant_defined_field18" : getMerchantDefinedField18(),
			"merchant_defined_field19" : getMerchantDefinedField19(),
			"merchant_defined_field20" : getMerchantDefinedField20(),
			"shipping_carrier" : getShippingCarrier(),
			"shipping" : getShipping(),
			"tracking_number" : getTrackingNumber(),
			"shipping_date" : getShippingDate(),
			"cc_hash" : getCC_hash(),
			"cc_bin" : getCC_bin(),
		};

		if(!isNull(getCard())) {
				ret["ccnumber"] = getCard().getAccount();
				ret["ccexp"] = DateFormat(getCard().getExpirationDate(), "MMYY");
		}

	
		return ret;
	}


}