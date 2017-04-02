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

	/**
		Check that the credentials are correct
	*/
	public boolean function hasValidCredentials(){
		//Should do a purchase with a test card
		var expDate = dateAdd("m", randRange(1, 20), Now());
		var money = getService().createMoney(5000);
		var account = getService().createCreditCard();
			account.setAccount("4111111111111111");
			account.setMonth(Month(expDate));
			account.setYear(Year(expDate));
			account.setVerificationValue(900);

		var options = {
			"refId": getTickCount() //Authorize.net requires a unique order id for each transaction.
		};

		var ret = purchase(money=money,account=account,options=options);

		//Make sure it's just the credentials


		if(ret.getMessageText() EQ "User authentication failed due to invalid authentication values."){
			return false;
		}

		if(ret.getMessageCode() EQ "E00007"){
			return false;
		}

		//There could be other errors but we are ignoring it

		return true;



	}





	// private any function createValidCard(svc, card="4111111111111111", CVV=900, expDate=dateAdd("m", randRange(1, 20), Now()), ZipCode=46201){
	//
	// 	var account = svc.createCreditCard();
	// 		account.setAccount(card);
	// 		account.setMonth(Month(expDate));
	// 		account.setYear(Year(expDate));
	// 		account.setVerificationValue(CVV);
	// 		account.setFirstName("John");
	// 		account.setLastName("Doe");
	// 		account.setAddress(getTickCount() & " Boulevard Road"); //Hopefully avoids duplicate transaction errors
	// 		account.setPostalCode(ZipCode);
	// 	return account;
	// }

	function purchase(required Any money, Any account=nullValue(), Any customer=nullValue(), Any paymentProfile=nullValue(), Struct options={}){

		//we either need an account (ergo a creditcard) OR a (customer and payment profile)

		if(!isNull(account)){
			if(lcase(listLast(getMetaData(arguments.account).fullname, ".")) NEQ "creditcard"){
			throw("The account type #lcase(listLast(getMetaData(arguments.account).fullname, "."))# is not supported by this gateway.", "", "cfpayment.InvalidAccount");
			}
		}

		if(isNull(account) && isNull(customer) && isNull(paymentProfile)){
			throw("Either a creditcard/account is needed or a customer and payment profile. None of these have been passed in");
		}
		//need a refID presume?
		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());

		var argumentColls = {
			"transactionType" : "authCaptureTransaction",
			"merchantAuthentication" : getMerchantAuthentication(),
			"money" : arguments.money,
			"options" : arguments.options,
			"paymentProfile": arguments.paymentProfile
		};

		if(!IsNull(account)){
			argumentColls["account"] = account;
		}

		if(!IsNull(customer)){
			argumentColls["customer"] = customer;
		}

		var payload = RequestXMLProcessor.createTransactionRequest(
					argumentCollection=argumentColls
						);


		var results = {};

		//Now go and process it
		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();

		var resp = new transactionResponse(argumentCollection=result);



		return resp;

	}

	function function canSwipe(){
		return false;
	}
	
	function authorize(required Any money, Any requred account, Struct options={}){
		if(lcase(listLast(getMetaData(arguments.account).fullname, ".")) NEQ "creditcard"){
			throw("The account type #lcase(listLast(getMetaData(arguments.account).fullname, "."))# is not supported by this gateway.", "", "cfpayment.InvalidAccount");
		}

		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createTransactionRequest(
						transactionType="authOnlyTransaction",
						merchantAuthentication=getMerchantAuthentication(),
						money=arguments.money,
						account=account,
						options=options);

			//Now go and process it
		var result  = super.process(payload = payload);
		var resp = createResponse(argumentCollection=result);

		// do some meta-checks for gateway-level errors (as opposed to auth/decline errors)
			if (NOT resp.hasError()) {

				// we need to have a result; otherwise that's an error in itself
				if (len(resp.getResult())) {
					var xmlResponse = XMLParse(resp.getResult());
					resp.setParsedResult(xmlResponse);

					//Successful response, deal with the actual codes.
					var hasTransactionResponse = structKeyExists(xmlResponse, "createTransactionResponse") && structKeyExists(xmlResponse.createTransactionResponse, "transactionResponse");

					var hasErrorRsponse = structKeyExists(xmlResponse, "ErrorResponse");

					if(hasTransactionResponse){
						processTransactionResponse(xmlResponse, resp);
					}

					else if(hasErrorRsponse) {

						processErrorResponse(xmlResponse, resp);

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

		return resp;

	}

	function capture(required Any money, String required authorization, Struct options={}){
		options.refTransID = authorization;

		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createTransactionRequest(
						transactionType="priorAuthCaptureTransaction",
						merchantAuthentication=getMerchantAuthentication(),
						money=money,
						account=nullValue(),
						options=options);
		var result  = super.process(payload = payload);
		var resp = createResponse(argumentCollection=result);

		// do some meta-checks for gateway-level errors (as opposed to auth/decline errors)
			if (NOT resp.hasError()) {

				// we need to have a result; otherwise that's an error in itself
				if (len(resp.getResult())) {
					var xmlResponse = XMLParse(resp.getResult());
					resp.setParsedResult(xmlResponse);

					//Successful response, deal with the actual codes.
					var hasTransactionResponse = structKeyExists(xmlResponse, "createTransactionResponse") && structKeyExists(xmlResponse.createTransactionResponse, "transactionResponse");

					var hasErrorRsponse = structKeyExists(xmlResponse, "ErrorResponse");

					if(hasTransactionResponse){
						processTransactionResponse(xmlResponse, resp);
					}

					else if(hasErrorRsponse) {

						processErrorResponse(xmlResponse, resp);

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

		return resp;

	}

	function credit(Any required transactionID, Any required money, Any requred account, Struct options={}) {



		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createTransactionRequest(
						transactionType="refundTransaction",
						merchantAuthentication=getMerchantAuthentication(),
						money=money,
						account=account,
						options=options);
		var result  = super.process(payload = payload);
		var resp = createResponse(argumentCollection=result);

		// do some meta-checks for gateway-level errors (as opposed to auth/decline errors)
			if (NOT resp.hasError()) {

				// we need to have a result; otherwise that's an error in itself
				if (len(resp.getResult())) {
					var xmlResponse = XMLParse(resp.getResult());
					resp.setParsedResult(xmlResponse);

					//Successful response, deal with the actual codes.
					var hasTransactionResponse = structKeyExists(xmlResponse, "createTransactionResponse") && structKeyExists(xmlResponse.createTransactionResponse, "transactionResponse");

					var hasErrorRsponse = structKeyExists(xmlResponse, "ErrorResponse");

					if(hasTransactionResponse){
						processTransactionResponse(xmlResponse, resp);
					}

					else if(hasErrorRsponse) {

						processErrorResponse(xmlResponse, resp);

					}
				}
				else {
					resp.setStatus(getService().getStatusUnknown()); // Authorize.net didn't return a response
				}
			}




			if (resp.getStatus() EQ getService().getStatusSuccessful()) {
				result["result"] = "REFUNDED";
			}
			else if (resp.getStatus() EQ getService().getStatusDeclined()) {
				result["result"] = "NOT REFUNDED";

			}
			else {
				result["result"] = "ERROR";

			}

		return resp;

	}

	function void(Any required transactionID, Struct options={}) {

		options.refTransID = transactionID;

        var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createTransactionRequest(
						transactionType="voidTransaction",
						merchantAuthentication=getMerchantAuthentication(),
						money=nullValue(),
						account=nullValue(),
						options=options);

		var result  = super.process(payload = payload);
		var resp = createResponse(argumentCollection=result);

		// do some meta-checks for gateway-level errors (as opposed to auth/decline errors)
			if (NOT resp.hasError()) {

				// we need to have a result; otherwise that's an error in itself
				if (len(resp.getResult())) {
					var xmlResponse = XMLParse(resp.getResult());
					resp.setParsedResult(xmlResponse);

					//Successful response, deal with the actual codes.
					var hasTransactionResponse = structKeyExists(xmlResponse, "createTransactionResponse") && structKeyExists(xmlResponse.createTransactionResponse, "transactionResponse");

					var hasErrorRsponse = structKeyExists(xmlResponse, "ErrorResponse");

					if(hasTransactionResponse){
						processTransactionResponse(xmlResponse, resp);
					}

					else if(hasErrorRsponse) {

						processErrorResponse(xmlResponse, resp);

					}
				}
				else {
					resp.setStatus(getService().getStatusUnknown()); // Authorize.net didn't return a response
				}
			}




			if (resp.getStatus() EQ getService().getStatusSuccessful()) {
				result["result"] = "VOIDED";
			}
			else if (resp.getStatus() EQ getService().getStatusDeclined()) {
				result["result"] = "NOT VOIDED";

			}
			else {
				result["result"] = "ERROR";

			}

		return resp;
	}

	//shortcut to storeCustomer
	function store(){
		return storeCustomer(argumentCollection=arguments);
	}

	//shortcut to deleteCustomer
	function unstore(){
		return deleteCustomer(argumentCollection=arguments);
	}

	/*
		Creates a new customer record
	*/

	function storeCustomer(required customer) {

		if(!customer.hasValidID()){
			throw("No valid id defined in customer");
		}

		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
						requestType="createCustomerProfileRequest",
						merchantAuthentication=getMerchantAuthentication(),
						customer=customer,
						options={});
		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();

		var resp = new customerResponse(argumentCollection=result);


		//if there isnt an http error, go and process the response:
		if (NOT resp.hasError()) {



			var xmlResponse = XMLParse(resp.getResult());

			var messages = XMLSearch(xmlResponse, "//:messages")[1]; //Should work, always you get a message




			//There should generally always be a messsage
			resp.setResultCode(messages.resultCode.xmlText);
			resp.setMessageCode(messages.message.code.xmlText);
			resp.setMessageText(messages.message.text.xmlText);
			resp.setMessage(resp.getMessageCode() & ": " & resp.getMessageText());


			if(resp.getResultCode() EQ "OK"){
				//Move this to the constructor of the response
				var customerID = XMLSearch(xmlResponse, "//:customerProfileId"); //Might not work if it fails right?

				resp.setCustomerProfileId(customerID[1].xmlText);

				var customerPaymentProfileIdList  = XMLSearch(xmlResponse, "//:customerPaymentProfileIdList/:numericString");

				//Loop through the xmlChildren
				for(var ppid in customerPaymentProfileIdList){
					resp.addCustomerPaymentProfileId(ppid.xmlText);
				}

				var customerShippingAddressIdList  = XMLSearch(xmlResponse, "//:customerShippingAddressIdList/:numericString");

				//Loop through the xmlChildren
				for(var shipid in customerShippingAddressIdList){
					resp.addCustomerShippingAddressId(shipid.xmlText);
				}


				var validationDirectResponseList  = XMLSearch(xmlResponse, "//:validationDirectResponseList/:string");
				for(var directResponse in validationDirectResponseList){
					resp.addvalidationDirectResponse(directResponse.xmlText);
				}
				resp.setStatus(getService().getStatusSuccessful());
			}
			else {
				resp.setStatus(getService().getStatusFailure());
			}


		}

		return resp;
	}

	function getCustomer(required customerId) {


		//Create a fake customer just for the request:

		var customer = createCustomer();
			customer.setCustomerProfileId(customerId);


		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
						requestType="getCustomerProfileRequest",
						merchantAuthentication=getMerchantAuthentication(),
						customer=customer,
						options={});

		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();


		var resp = new customerResponse(argumentCollection=result);

		if (NOT resp.hasError()) {
			var xmlResponse = XMLParse(resp.getResult());

			var messages = XMLSearch(xmlResponse, "//:messages")[1]; //Should work, always you get a message

			//There should generally always be a messsage
			resp.setResultCode(messages.resultCode.xmlText);
			resp.setMessageCode(messages.message.code.xmlText);
			resp.setMessageText(messages.message.text.xmlText);
			resp.setMessage(resp.getMessageCode() & ": " & resp.getMessageText());


			if(resp.getResultCode() EQ "OK"){
				//Parse the thing

				resp.setCustomer(createCustomer().populate(xmlResponse));



				resp.setStatus(getService().getStatusSuccessful());
			}
			else {
				resp.setStatus(getService().getStatusFailure());
			}


		}

		return resp;
	}

	function listCustomerIds() {

		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
						requestType="getCustomerProfileIdsRequest",
						merchantAuthentication=getMerchantAuthentication(),
						customer=nullValue(),
						options={});

		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();


		//Does this actually need a customer response?

		var resp = new customerResponse(argumentCollection=result);


		var ret = resp.getIds();
		return ret;
	}

	function updateCustomer(required customer) {

		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
						requestType="updateCustomerProfileRequest",
						merchantAuthentication=getMerchantAuthentication(),
						customer=customer,
						options={});

		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();


		//Does this actually need a customer response?

		var resp = new customerResponse(argumentCollection=result);
		return resp;
	}


	function deleteCustomer(required customer){
		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
						requestType="deleteCustomerProfileRequest",
						merchantAuthentication=getMerchantAuthentication(),
						customer=customer,
						options={});


		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();

		var resp = new customerResponse(argumentCollection=result);


		return resp;
	}

	function addPaymentProfile(required customer, required paymentProfile){
		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
						requestType="createCustomerPaymentProfileRequest",
						merchantAuthentication=getMerchantAuthentication(),
						customer=customer,
						paymentProfile=paymentProfile,
						options={});

		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();

		var resp = new customerResponse(argumentCollection=result);


		return resp;
	}

	function getPaymentProfile(required customerId, required paymentProfileId){
		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());

		//Creeate a mock customer and a mock pauyment profile
		var customer = createCustomer();
			customer.setCustomerProfileId(customerID);
		var profile = createPaymentProfile();
			profile.setCustomerPaymentProfileId(paymentProfileId);

		var payload = RequestXMLProcessor.createCustomerRequest(
						requestType="getCustomerPaymentProfileRequest",
						merchantAuthentication=getMerchantAuthentication(),
						customer=customer,
						paymentProfile=profile,
						options={});


		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();

		var resp = new customerResponse(argumentCollection=result);



		return resp;
	}

	function getPaymentProfileList(Date required expiryMonth, string orderBy="id",boolean orderDescending=false,numeric limit=1000,numeric offset=1){
		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var search = {
			"month":DateFormat(expiryMonth, "YYYY-MM"),
			"sorting": {
				"orderBy": orderBy,
				"orderDescending" : orderDescending
			},
			"paging": {
				"limit": limit,
				"offset": offset
			}
		};
		var payload = RequestXMLProcessor.createCustomerRequest(
						requestType="getCustomerPaymentProfileListRequest",
						merchantAuthentication=getMerchantAuthentication(),
						search=search
					);


		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();
		var resp = new customerResponse(argumentCollection=result);

		return resp;
	}


	function validatePaymentProfile(required customerId, required paymentProfileId){

		var customer = createCustomer();
			customer.setCustomerProfileId(customerID);
		var profile = createPaymentProfile();
			profile.setCustomerPaymentProfileId(paymentProfileId);

		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
					requestType="validateCustomerPaymentProfileRequest",
					merchantAuthentication=getMerchantAuthentication(),
					customer=customer,
					paymentProfile=profile,
					options={});

		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();

		var resp = new customerResponse(argumentCollection=result);

		return resp;

	}

	function updatePaymentProfile(required customerId, required paymentProfile){

		var customer = createCustomer();
			customer.setCustomerProfileId(customerID);


		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
					requestType="updateCustomerPaymentProfileRequest",
					merchantAuthentication=getMerchantAuthentication(),
					customer=customer,
					paymentProfile=paymentProfile,
					options={});



		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();

		var resp = new customerResponse(argumentCollection=result);

		return resp;

	}

	function deletePaymentProfile(required customerId, required paymentProfileId){

		var customer = createCustomer();
			customer.setCustomerProfileId(customerID);
		var profile = createPaymentProfile();
			profile.setCustomerPaymentProfileId(paymentProfileId);

		var RequestXMLProcessor = new AuthorizenetXMlRequest(getTestMode());
		var payload = RequestXMLProcessor.createCustomerRequest(
					requestType="deleteCustomerPaymentProfileRequest",
					merchantAuthentication=getMerchantAuthentication(),
					customer=customer,
					paymentProfile=profile,
					options={});



		var result  = super.process(payload = payload);
			result["service"] = super.getService();
			result["testmode"] = super.getTestMode();

		var resp = new customerResponse(argumentCollection=result);

		return resp;

	}

	/**
		PRIVATE FUNCTIONS
	**/

	private void function processCustomerResponseMessages(respObject, xmlResponse){

	}
	private customerResponse function createCustomerResponse(XML xmlResponse){

		var resp = new customerResponse();
		//var messages = XMLSearch(xmlResponse, "//*messages");
		return resp;
	}

	public customer function createCustomer(){
		arguments.service = getService();
		return new customer(argumentCollection=arguments);
	}

	public PaymentProfile function createPaymentProfile(){
		arguments.service = getService();
		return new PaymentProfile(argumentCollection=arguments);
	}

	public address function createAddress(){
		return new address(argumentCollection=arguments);
	}


	private void function processTransactionResponse(XML xmlResponse, Any resultObj){

		var transResponse = xmlResponse.createTransactionResponse.transactionResponse;
		// handle common response fields
		if(structKeyExists(transResponse, "responseCode")){
			resultObj.setMessage(transResponse.responseCode.XMLText);
		}
		if (structKeyExists(transResponse, "transId")){
			resultObj.setTransactionID(transResponse.transId.XMLText);
		}

		if (structKeyExists(transResponse, "authCode")){
			resultObj.setAuthorization(transResponse.authCode.XmlText);
		}
		// handle common "success" fields
		if (structKeyExists(transResponse, "avsResultCode")){
			resultObj.setAVSCode(transResponse.avsResultCode.XmlText);
		}

		if (structKeyExists(transResponse, "cvvResultCode")){
			resultObj.setCVVCode(transResponse.cvvResultCode.XmlText);
		}
		if (isDefined("transResponse.errors.error.errorText")){
			resultObj.setMessage(resultObj.getMessage() & ": " & transResponse.errors.error.errorText.XMLText);
		}

						// see if the response was successful
		switch (transResponse.responseCode.XmlText) {
			case "1": {
				resultObj.setStatus(getService().getStatusSuccessful());
				break;
			}
			case "2": {
				resultObj.setStatus(getService().getStatusDeclined());
				break;
			}
			case "4": {
				resultObj.setStatus(5); // On hold (this status value is not currently defined in core.cfc)
				break;
			}
			default: {
				resultObj.setStatus(getService().getStatusFailure()); // only other known state is 3 meaning, "error in transaction data or system error"
			}
		}

	}

	private void function processErrorResponse(XML xmlResponse, Any resultObj){

		resultObj.setStatus(getService().getStatusFailure());


		resultObj.setMessage("There has been an error");




		if(isDefined("xmlResponse.ErrorResponse.messages.message")){
			if(structKeyExists(xmlResponse.ErrorResponse.messages.message, "code")){
				resultObj.setMessage(xmlResponse.ErrorResponse.messages.message.code.xmlText);
			}
			if(structKeyExists(xmlResponse.ErrorResponse.messages.message, "text")){
				resultObj.setMessage(resultObj.getMessage() & ": " & xmlResponse.ErrorResponse.messages.message.text.xmlText);
			}
		}



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
