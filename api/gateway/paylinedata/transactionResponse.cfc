/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is a response from calls to the Payline API

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
	extends="cfpayment.api.model.response"
	{


		property name="orderID" 			getter="true" setter="true";
		property name="responseType"		type="string"	getter="true" setter="true";
		property name="responseCode"		type="numeric"	getter="true" setter="true";
		property name="response"			type="numeric"	getter="true" setter="true";
		property name="customerVaultId"	type="string"	getter="true" setter="true";



		function init(){
			super.init(argumentCollection=arguments);

			//ResultCodes:
			// 100	Transaction was approved.
			// 200	Transaction was declined by processor.
			// 201	Do not honor.
			// 202	Insufficient funds.
			// 203	Over limit.
			// 204	Transaction not allowed.
			// 220	Incorrect payment information.
			// 221	No such card issuer.
			// 222	No card number on file with issuer.
			// 223	Expired card.
			// 224	Invalid expiration date.
			// 225	Invalid card security code.
			// 240	Call issuer for further information.
			// 250	Pick up card.
			// 251	Lost card.
			// 252	Stolen card.
			// 253	Fraudulent card.
			// 260	Declined with further instructions available. (See response text)
			// 261	Declined-Stop all recurring payments.
			// 262	Declined-Stop this recurring program.
			// 263	Declined-Update cardholder data available.
			// 264	Declined-Retry in a few days.
			// 300	Transaction was rejected by gateway.
			// 400	Transaction error returned by processor.
			// 410	Invalid merchant configuration.
			// 411	Merchant account is inactive.
			// 420	Communication error.
			// 421	Communication error with issuer.
			// 430	Duplicate transaction at processor.
			// 440	Processor format error.
			// 441	Invalid transaction information.
			// 460	Processor feature not available.
			// 461	Unsupported card type.

			if(!hasError()){
				var parsedResult = parseResponse(getResult());
				setParsedResult(parsedResult);
				setResponseType(parsedResult.type);

				setAuthorization(parsedResult.authcode);
				setAVSCode(parsedResult.avsresponse);
				setCVVCode(parsedResult.cvvresponse);
				setOrderID(parsedResult.orderid);
				setTransactionID(parsedResult.transactionid);

				setResponseCode(parsedResult.response_code)
				setResponse(parsedResult.response);
				setMessage(parsedResult.responsetext);

				if(structKeyExists(parsedResult, "customer_vault_id")){
					setCustomerVaultId(parsedResult.customer_vault_id);
				}
				




				if(getResponseCode() EQ 100){
					setStatus(getService().getStatusSuccessful());
				}
				else{
					
					setStatus(getService().getStatusFailure());
				}
				

				

				
			}
		

			return this;

		}


	private struct function parseResponse(String response){
		var ret = {};
		var tuples=listToArray(response, "&", true);
		for(var t in tuples){
			var tup = listToArray(t, "=", true);

			ret[URLDecode(tup[1])] = arrayLen(tup) ==2 ? URLDecode(tup[2]) : "";
			
		}
		return ret;
	}
}