/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is a a response object that is returned from the authorize.net system whenever
	we have interactions with transaction based actions. 
	
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

	property name="resultCode" 										getter="true" setter="true";
	property name="messageCode" 									getter="true" setter="true";
	property name="messageText" 									getter="true" setter="true";
	property name="responseType"					type="string"	getter="true" setter="true";


	function init(){

		super.init(argumentCollection=arguments);


		if(!hasError()){
			var xmlResponse = XMLParse(getResult());
				setParsedResult(xmlResponse);


			var messages = XMLSearch(xmlResponse, "//:messages")[1]; //Should work, always you get a message
			
			//If this errors is because the service didn't actually respond which means hasError() should be true;
			setResultCode(messages.resultCode.xmlText);
			setMessageCode(messages.message.code.xmlText);
			setMessageText(messages.message.text.xmlText);
			setMessage(getMessageCode() & ": " & getMessageText());

			if(getResultCode() EQ "OK"){
				setStatus(getService().getStatusSuccessful());
				setResponseType(xmlResponse.XmlRoot.xmlName);

				processTransactionResponse(xmlResponse);



			}

		}



		return this;
	}


		private void function processTransactionResponse(XML xmlResponse){

			var transResponse = xmlResponse.createTransactionResponse.transactionResponse;
			// handle common response fields
			if(structKeyExists(transResponse, "responseCode")){
				setMessage(transResponse.responseCode.XMLText);
			}
			if (structKeyExists(transResponse, "transId")){
				setTransactionID(transResponse.transId.XMLText);
			}
			
			if (structKeyExists(transResponse, "authCode")){
				setAuthorization(transResponse.authCode.XmlText);
			}
			// handle common "success" fields
			if (structKeyExists(transResponse, "avsResultCode")){
				setAVSCode(transResponse.avsResultCode.XmlText);					
			}

			if (structKeyExists(transResponse, "cvvResultCode")){
				setCVVCode(transResponse.cvvResultCode.XmlText);					
			}
		

							// see if the response was successful
			switch (transResponse.responseCode.XmlText) {
				case "1": {
					setStatus(getService().getStatusSuccessful());
					break;
				}
				case "2": {
					setStatus(getService().getStatusDeclined());
					break;
				}
				case "4": {
					setStatus(5); // On hold (this status value is not currently defined in core.cfc)
					break;
				}
				default: {
					setStatus(getService().getStatusFailure()); // only other known state is 3 meaning, "error in transaction data or system error"
				}
			}

	}

	


}