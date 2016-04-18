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



	property name="customer_vault_id" 					getter="true" setter="true";
	property name="billing_id" 							getter="true" setter="true";
	property name="card" 								getter="true" setter="true";
	property name="payment" 							getter="true" setter="true" default="creditcard";
	property name="orderid"								getter="true" setter="true";
	property name="order_description"					getter="true" setter="true";
	//Should be an array
	property name="merchant_defined_fields" 			type="array"	getter="true" setter="true";

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

	public Struct function getMemento(){

		var ret = {};
		var proparr = getMetadata(this).properties;

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