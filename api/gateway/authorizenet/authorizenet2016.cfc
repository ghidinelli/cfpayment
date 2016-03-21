/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is a updated implementation of the authorize.net API. 
	See:
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
	extends="cfpayment.api.gateway.base"
	displayname="Authorize.net AIM Interface"
	hint="Authorize.net Gateway see http://developer.authorize.net/api/reference/"

	{
	

	variables.cfpayment.GATEWAY_NAME = "Authorize.net";
	variables.cfpayment.GATEWAY_VERSION = "4.0";
	
	// The test URL requires a separate developer transKey and login
	// Request a developer account here: http://developer.authorize.net/testaccount/
	variables.cfpayment.GATEWAY_TEST_URL = "https://apitest.authorize.net/xml/v1/request.api";
	variables.cfpayment.GATEWAY_LIVE_URL = "https://api.authorize.net/xml/v1/request.api";


	function purchase(Any required money, Any requred account, Struct options={} ){


		if(lcase(listLast(getMetaData(arguments.account).fullname, ".")) NEQ "creditcard"){
			throw("The account type #lcase(listLast(getMetaData(arguments.account).fullname, "."))# is not supported by this gateway.", "", "cfpayment.InvalidAccount");
		}



		//need a refID presume?
		var RequestXMLProcessor = new AuthorizenetXMlRequest();
		var payload = RequestXMLProcessor.createTransactionRequest(
						transactionType="authCaptureTransaction",
						merchantAuthentication=getMerchantAuthentication(),
						money=arguments.money,
						account=account, 
						options=options);
	
		var results = {};

	//Now go and process it
		var result  = super.process(payload = payload);



		var resp = createResponse(argumentCollection=result);

	

	// do some meta-checks for gateway-level errors (as opposed to auth/decline errors)
			if (NOT resp.hasError()) {
	
				// we need to have a result; otherwise that's an error in itself
				if (len(resp.getResult())) {
				
					var xmlResponse = XMLParse(resp.getResult());
					var transResponse = xmlResponse.createTransactionResponse.transactionResponse;


				
					
					// handle common response fields
					if (structKeyExists(transResponse, "responseCode"))
						resp.setMessage(transResponse.responseCode.XMLText);


					if (isDefined("transResponse.errors.error.errorText"))
						resp.setMessage(resp.getMessage() & ": " & transResponse.errors.error.errorText.XMLText);

					if (structKeyExists(transResponse, "transId"))
						resp.setTransactionID(transResponse.transId.XMLText);



				
					
					if (structKeyExists(transResponse, "authCode"))
						resp.setAuthorization(transResponse.authCode.XmlText);



					
					// handle common "success" fields
					if (structKeyExists(transResponse, "avsResultCode"))
						resp.setAVSCode(transResponse.avsResultCode.XmlText);					

					if (structKeyExists(transResponse, "cvvResultCode"))
						resp.setCVVCode(transResponse.cvvResultCode.XmlText);					
	
					



					
					// see if the response was successful
					switch (transResponse.responseCode) {
						case "1": {
							resp.setStatus(getService().getStatusSuccessful());
							break;
						}
						case "2": {
							resp.setStatus(getService().getStatusDeclined());
							break;
						}
						case "4": {
							resp.setStatus(5); // On hold (this status value is not currently defined in core.cfc)
							break;
						}
						default: {
							resp.setStatus(getService().getStatusFailure()); // only other known state is 3 meaning, "error in transaction data or system error"
						}
					}
				
				

				}
				else {
					resp.setStatus(getService().getStatusUnknown()); // Authorize.net didn't return a response
				}
			}


		

			if (resp.getStatus() EQ getService().getStatusSuccessful()) {
				result["result"] = "CAPTURED";
			}
			else if (resp.getStatus() EQ getService().getStatusDeclined()) {
				result["result"] = "NOT CAPTURED";
				
			}
			else {
				result["result"] = "ERROR";
				
			}


		// store parsed result
		resp.setParsedResult(result);
		
		return resp;
	
	}

	function authorize(){

	}

	function capture(){

	}

	function credit() {

	}

	function void() {

	}

	function store() {

	}

	/*
		@hint: wrapper around the http call
	*/
	private Struct function doHttpCall(	
			String required url,
			String method="GET", 
			numeric required timeout, 
			struct headers={}, 
			XML payload={}, 
			boolean encoded=true, 
			Struct files={}){

		

			var CFHTTP = "";
			var key = "";
			var keylist = "";
			var skey = "";
			var paramType = "body";

			var ValidMethodTypes = "URL,GET,POST,PUT,DELETE";
			if(!listFindNoCase(ValidMethodTypes, arguments.method)){
				throw(message="Invalid Method",type="cfpayment.InvalidParameter.Method");
			}

			if(arguments.method EQ "URL"){
				paramType = "url";
			}

			var PayloadToSend = "";

			var HTTP = new HTTP(url=arguments.url, method=arguments.method, timeout=arguments.timeout, throwonerror="no");

			for(var h in headers){
				HTTP.addParam(name=h, value=headers[h], type="header");
			}

			//The actual XML content
			HTTP.addParam(value=toString(payload), type=paramType);

			for(var f in files){
				HTTP.addParam(name=f, file=files[f], type="file");
			}

			var res = HTTP.send();
			
		return res.getPrefix();
	}

	/*
		@hint: intercepts the call so that the result can be parsed nicer-er
	*/
	function createResponse(){



		
		return super.createResponse(argumentCollection=arguments);
	}

	function getMerchantAuthentication(){
		return {
			"name":variables.cfpayment.username,
			"transactionKey": variables.cfpayment.merchantAccount
			 
		}
	}
	
}