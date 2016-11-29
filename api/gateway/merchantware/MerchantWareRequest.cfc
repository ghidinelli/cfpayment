/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is an implementation of Cayan MerchantWare API. 
	See:
https://ps1.merchantware.net/Merchantware/ws/RetailTransaction/v4/Credit.asmx

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
component {

	variables.validTransactions = "SaleKeyed,Sale";

	public Array function createPayload(String required requestType, Any required merchantAuthentication, Any required money, Any  account, Any transactionId, Any customer, Struct options={}){

		var ret = [];
		if(!isValidTransactionType(requestType)){
		 	throw(type="cfpayment.UnknownTransactionType", message="transactionType, #requestType# is not known");
		}

		// if(!structKeyExists(options, "ipaddress")){
		// 	options["ipaddress"]=CGI.remote_addr;
		// }

		var ret = [];

			

			
			addKey(ret, "merchantName", merchantAuthentication.merchantName);
			addKey(ret, "merchantSiteId", merchantAuthentication.merchantSiteId);
			addKey(ret, "merchantKey", merchantAuthentication.merchantKey);
			addKey(ret, "invoiceNumber", options.invoiceNumber?:"");
			if(!isNull(transactionid)){
				addKey(ret, "transactionid", transactionId);
			}
			if(!isNull(money)){
				addKey(ret, "amount",Trim(money.getAmount()));
				//addKey(ret, "currency",money.getCurrency());
			}

			
			if(!isNull(account)){
				addKey(ret, "cardNumber",account.getAccount());
				addKey(ret, "expirationDate",DateFormat(account.getExpirationDate(), "MMYY"));
				
				addKey(ret, "cardholder", account.getFirstName() & " " & account.getLastName());

				//addKey(ret, "company", account.getcompany());
				addKey(ret, "avsStreetAddress", account.getaddress());
				// //addKey(ret, "address2", account.getaddress2());
				// addKey(ret, "city", account.getcity());
				// addKey(ret, "state", account.getRegion());
				
				addKey(ret, "avsStreetZipCode", account.getPostalCode());
				// addKey(ret, "country", account.getcountry());

				addKey(ret, "cardSecurityCode",account.getVerificationValue());
			}

			addKey(ret, "forceDuplicate", options.forceDuplicate?:true);
			addKey(ret, "registerNumber", options.registerNumber?:"");
			addKey(ret, "merchantTransactionId", options.merchantTransactionId?:"");

			// if(!isNull(customer)){
			// 	var customer = customer.getMemento();



			// 	for(var k in customer){

			// 		if(k EQ "address" && !isNull(customer[k])){
			// 			var address = customer[k];

			// 			addKey(ret, "firs_tname", address.getFirstName());
			// 			addKey(ret, "last_name", address.getLastName());
			// 			addKey(ret, "company", address.getcompany());
			// 			addKey(ret, "address1", address.getaddress());
			// 			addKey(ret, "address2", address.getAddress2());
			// 			addKey(ret, "city", address.getCity());
			// 			addKey(ret, "state", address.getState());
			// 			addKey(ret, "zip", address.getZip());
			// 			addKey(ret, "country", address.getcountry());
			// 			addKey(ret, "phone", address.getphoneNumber());
			// 			addKey(ret, "fax", address.getphoneNumber());
			// 			addKey(ret, "email", address.getEmail());
			// 		}
			// 		else if(k EQ "shippingaddress" && !isNull(customer[k])){
			// 			var address = customer[k];
			// 			addKey(ret, "shipping_firstname", address.getFirstName());
			// 			addKey(ret, "shipping_lastname", address.getLastName());
			// 			addKey(ret, "shipping_company", address.getcompany());
			// 			addKey(ret, "shipping_address1", address.getaddress());
			// 			addKey(ret, "shipping_address2", address.getAddress2());
			// 			addKey(ret, "shipping_city", address.getCity());
			// 			addKey(ret, "shipping_state", address.getState());
			// 			addKey(ret, "shipping_zip", address.getZip());
			// 			addKey(ret, "shipping_country", address.getcountry());
			// 			addKey(ret, "shipping_phone", address.getphoneNumber());
			// 			addKey(ret, "shipping_fax", address.getphoneNumber());
			// 			addKey(ret, "shipping_email", address.getEmail());
			// 		}

			// 		//Dont add fields we don't have
			// 		else if(!isNull(customer[k])){
			// 				addKey(ret, k, customer[k]);	
			// 		}

					
					
			// 	}
			// }
			
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
}