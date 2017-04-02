/*
	Copyright 2016  Mark Drew (http://markdrew.io)
		
	Helper class to genrate all the XML that is required to send to the  of the authorize.net API.

	http://developer.authorize.net/api/reference/index.html
	
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
component
	accessors="true"
	
{

	variables.validTransactions = "sale,auth,capture,refund,void,validate,update,credit,add_customer,update_customer";

	variables.validFields = {
		"update": "tracking_number,shipping,shipping_postal,ship_from_postal,shipping_country,shipping_carrier,shipping_date,order_description,order_date,customer_receipt,ponumber,summary_commodity_code,duty_amount,discount_amount,tax,national_tax_amount,alternate_tax_amount,alternate_tax_id,vat_tax_amount,vat_tax_rate,vat_invoice_reference_number,customer_vat_registration,merchant_vat_registration"
	}

	public Array function createPayload(String required requestType, Any required merchantAuthentication, Any required money, Any  account, String customer_vault_id, Any transactionId, Any customer, Struct options={}){

		if(!isValidTransactionType(requestType)){
		 	throw(type="cfpayment.UnknownTransactionType", message="transactionType, #requestType# is not known");
		}

		if(!structKeyExists(options, "ipaddress")){
			options["ipaddress"]=CGI.remote_addr;
		}


		
		
		var ret = [];

			if(ListFindNocase("update_customer,add_customer", requestType)){
				addKey(ret, "customer_vault", requestType);
			}
			else{
				addKey(ret, "type", requestType);
			}
	
			addKey(ret, "username", merchantAuthentication.username);
			addKey(ret, "password", merchantAuthentication.password);
			
			if(!isNull(transactionid)){
				addKey(ret, "transactionid", transactionId);
			}
			if(!isNull(money)){
				addKey(ret, "amount",money.getAmount());
				addKey(ret, "currency",money.getCurrency());
			}

			if(!isNull(customer_vault_id)){
				addKey(ret, "customer_vault_id",customer_vault_id);
			}
			
			if(!isNull(account)){
				addKey(ret, "ccnumber",account.getAccount());
				addKey(ret, "ccexp",DateFormat(account.getExpirationDate(), "MMYY"));
				addKey(ret, "cvv",account.getVerificationValue());
				addKey(ret, "ipaddress",options.ipaddress);
				addKey(ret, "first_name", account.getFirstName());
				addKey(ret, "last_name", account.getLastName());
				addKey(ret, "company", account.getcompany());
				addKey(ret, "address1", account.getaddress());
				//addKey(ret, "address2", account.getaddress2());
				addKey(ret, "city", account.getcity());
				addKey(ret, "state", account.getRegion());
				
				addKey(ret, "zip", account.getPostalCode());
				addKey(ret, "country", account.getcountry());
			}

			if(!isNull(customer)){
				var customer = customer.getMemento();

				for(var k in customer){
					if(!isNull(customer[k])){
						addKey(ret, k, customer[k]);	
					}
				}
			}
			
			for(var o in options){
				addKey(ret, o, options[o]);
			}
			
		return ret;
	
	}

	private boolean function isValidTransactionType(String type){
		return trueFalseFormat(listFindNoCase(variables.validTransactions, arguments.type));
	}

	private function addKey(arrayItem, name, value){
		if(!isNull(value)){
			arrayItem.append({"name":name, "value":value});
		}
		
	}

	private boolean function isValidField(string requestType, string field){
			

			//These are also valid
			//merchant_defined_field_#

	}
	
}