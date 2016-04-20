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



	property name="customerVaultId" 					getter="true" setter="true";

	property name="billingId" 							getter="true" setter="true";
	property name="taxId" 								getter="true" setter="true";
	property name="shippingCarrier" 					getter="true" setter="true";
	property name="trackingNumber" 						getter="true" setter="true";
	property name="shippingDate" 						getter="true" setter="true";
	property name="shipping" 							getter="true" setter="true";
	property name="cchash" 							getter="true" setter="true";
	property name="ccbin" 								getter="true" setter="true";
	property name="processorId" 						getter="true" setter="true";

	property name="card" 								getter="true" setter="true";
	property name="payment" 							getter="true" setter="true" default="creditcard";
	property name="orderid"								getter="true" setter="true";
	property name="orderDescription"					getter="true" setter="true";
	//Should be an array
	property name="merchantDefinedFields" 			type="array"	getter="true" setter="true";

// ponumber****
// tax****
// tax_exempt****
// shipping****

	property name="address" getter="true" setter="true";
	property name="shippingaddress" getter="true" setter="true";

	
	property name="shipping_id" getter="true" setter="true";
	property name="shipping_email" getter="true" setter="true";


	public function addMerchantDefinedFiled(String value){

		var merchant = getMerchant_defined_fields();

		if(isNull(merchant) || !isArray(merchant)){
			setMerchant_defined_fields([]);
		}

		ArrayAppend(merchant, value);
		setMerchant_defined_fields(merchant);

		return this;
	}


	public customer function populate(XML responseXML){

		abort;

		// setMerchantCustomerId(getXMLElementText(responseXML, "merchantCustomerId"));
		// setDescription(getXMLElementText(responseXML, "description"));
		// setEmail(getXMLElementText(responseXML, "email"));
		

		// //TODO: find out if this is actually correct and we get an array of paymentProfiles back, documentation is lacking at this point:
		// //http://developer.authorize.net/api/reference/#customer-profiles-create-customer-profile

		// var paymentProfiles = XMLSearch(responseXML, "//:paymentProfiles");
		// for(var paymentProfile in paymentProfiles){
		// 	var pp = new paymentProfile(service=getService()).populate(paymentProfile);
		// 	addPaymentProfile(pp);
			
		// }

		
		return this;
	}



	public Struct function getMemento(){

		var ret = {};
		var proparr = getMetadata(this).properties;

		//mapped properties

		for(var prop in proparr){
			if(prop.name != "card"){
				ret[prop.name] = prop.getter? this["get#prop.name#"]() : variables[prop.name];	
			}
			else if(!isNull(getCard())) {
				ret["ccnumber"] = getCard().getAccount();
				ret["ccexp"] = DateFormat(getCard().getExpirationDate(), "MMYY");

			}
		}
		return ret;
	}


}