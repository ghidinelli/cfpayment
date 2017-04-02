/*
	Copyright 2016 Mark Drew (http://markdrew.io)

	This is an implementation of paylinedata API.
	See:
	https://secure.paylinedatagateway.com/gw/merchants/resources/integration/integration_portal.php#transaction_types

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
	displayname="PaylineData API Interface"
	hint="https://secure.paylinedatagateway.com/gw/merchants/resources/integration/integration_portal.php"
{

	variables.cfpayment.GATEWAY_NAME = "PaylineData";
	variables.cfpayment.GATEWAY_VERSION = "1.0";


	//Same endpoint, but different credentials
	variables.cfpayment.GATEWAY_TEST_URL = "https://secure.paylinedatagateway.com/api/transact.php";
	variables.cfpayment.GATEWAY_LIVE_URL = "https://secure.paylinedatagateway.com/api/transact.php";

	variables.cfpayment.QUERY_URL = "https://secure.paylinedatagateway.com/api/query.php"

	/**
		Check that the credentials are correct
	*/
	public boolean function hasValidCredentials(){
		var requestPayload = {
			requestType="sale",
			merchantAuthentication=getMerchantAuthentication(),
		}

		var PaylineRequest = new PaylineRequest(getTestMode());
		var payload = PaylineRequest.createPayload(
				argumentCollection=requestPayload
			);

		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();
		var resp = new PaylineResponse(argumentCollection=result);

//If we actually got some kind of result
		if(result.statuscode NEQ "200"){
			return false;
		}
		var mem = resp.getMemento();
		if(resp.getMessage() EQ "Authentication Failed"){
			return false;
		}
		//Most other answers could be a "pass?"

		return true;
	}

	function purchase(required Any  money, Any account, String customer_vault_id, Struct options={}){

		var requestPayload = {
			requestType="sale",
			merchantAuthentication=getMerchantAuthentication(),
			money=money,
			options=options
		}

		if(!IsNull(account)){
			requestPayload['account'] =account;
		}

		if(!IsNull(customer_vault_id)){
			requestPayload['customer_vault_id'] =customer_vault_id;
		}

		var PaylineRequest = new PaylineRequest(getTestMode());
		var payload = PaylineRequest.createPayload(
				argumentCollection=requestPayload
			);



		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;
	}

	function canSwipe(){
		return false;
	}
	
	function authorize(Any required money, Any requred account, Struct options={}){

		//create the struct to send:
		var PaylineRequest = new PaylineRequest(getTestMode());


		var payload = PaylineRequest.createPayload(
				requestType="auth",
				merchantAuthentication=getMerchantAuthentication(),
				money=money,
				account=account,
				options=options
			);


		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;
	}

	function capture(Any required money, String required authorization, Struct options={}){

		options['transactionid'] = authorization;

		var PaylineRequest = new PaylineRequest(getTestMode());
		var payload = PaylineRequest.createPayload(
				requestType="capture",
				merchantAuthentication=getMerchantAuthentication(),
				money=money,
				options=options
			);


		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;
	}

	function credit(Any required transactionID, Any required money, Struct options={}) {

		var PaylineRequest = new PaylineRequest(getTestMode());
		var payload = PaylineRequest.createPayload(
				requestType="credit",
				merchantAuthentication=getMerchantAuthentication(),
				money=money,
				transactionId = transactionID,
				options=options
			);

		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;

	}

	function refund(Any required transactionID, Any required money, Struct options={}) {

		var PaylineRequest = new PaylineRequest(getTestMode());
		var payload = PaylineRequest.createPayload(
				requestType="refund",
				merchantAuthentication=getMerchantAuthentication(),
				money=money,
				transactionId = transactionID,
				options=options
			);

		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;

	}


	function void(Any required transactionID, Struct options={}) {

		options['transactionid'] = transactionID;

		var PaylineRequest = new PaylineRequest(getTestMode());
		var payload = PaylineRequest.createPayload(
				requestType="void",
				merchantAuthentication=getMerchantAuthentication(),
				options=options
			);


		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;

		}


	function validate(Any requred account, Struct options={}){

		//create the struct to send:
		var PaylineRequest = new PaylineRequest(getTestMode());


		var payload = PaylineRequest.createPayload(
				requestType="validate",
				merchantAuthentication=getMerchantAuthentication(),
				account=account,
				options=options
			);


		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;
	}

	function update(Any required transactionID, Struct options={}){

		//create the struct to send:
		var PaylineRequest = new PaylineRequest(getTestMode());


		var payload = PaylineRequest.createPayload(
				requestType="update",
				merchantAuthentication=getMerchantAuthentication(),
				transactionid=transactionID,
				options=options
			);


		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;
	}

	function store(required customer){

		var PaylineRequest = new PaylineRequest(getTestMode());


		var payload = PaylineRequest.createPayload(
				requestType="add_customer",
				merchantAuthentication=getMerchantAuthentication(),
				customer=arguments.customer

			);

		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;

	}

	function unstore(required String customer_vault_id ){
		var payload = [];
		var auth = getMerchantAuthentication();

		ArrayAppend(payload, {
				"name": "customer_vault_id",
				"value": customer_vault_id
			});
		ArrayAppend(payload, {
				"name": "customer_vault",
				"value": "delete_customer"
			});


		ArrayAppend(payload, {
				"name": "username",
				"value": auth.username
			});
		ArrayAppend(payload, {
				"name": "password",
				"value": auth.password
			});

		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;

	}

	function getCustomer(required String customer_vault_id ){

		var payload = [];
		var auth = getMerchantAuthentication();
		//We are not doing a full query implementation, so let's just see what it returns.
		ArrayAppend(payload, {
				"name": "customer_vault_id",
				"value": customer_vault_id
			});
		ArrayAppend(payload, {
				"name": "report_type",
				"value": "customer_vault"
			});

		ArrayAppend(payload, {
				"name": "report_type",
				"value": "customer_vault"
			});
		ArrayAppend(payload, {
				"name": "username",
				"value": auth.username
			});
		ArrayAppend(payload, {
				"name": "password",
				"value": auth.password
			});




		//Raw result
		var result  = super.process(payload = payload, url=variables.cfpayment.QUERY_URL);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();

		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;




	}
	function updateCustomer(required customer){

		var PaylineRequest = new PaylineRequest(getTestMode());


		var payload = PaylineRequest.createPayload(
				requestType="update_customer",
				merchantAuthentication=getMerchantAuthentication(),
				customer=arguments.customer

			);

		//Raw result
		var result  = super.process(payload = payload);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();



		 var resp = new PaylineResponse(argumentCollection=result);
		return resp;

	}


	//FACTORY METHODS

	public customer function createCustomer(){
		return new customer(argumentCollection=arguments);
	}

	public address function createAddress(){
		return new address(argumentCollection=arguments);
	}
	/*
		Override basic doHTTPCall meethod
	*/
	private Struct function doHttpCall(
			String required url,
			String method="GET",
			numeric required timeout,
			struct headers={},
			Array payload=[],
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






			var HTTP = new HTTP(url=arguments.url, method=arguments.method, timeout=arguments.timeout, throwonerror="no");

			for(var h in headers){
				HTTP.addParam(name=h, value=headers[h], type="header");
			}

			//The actual array of form attributes
			for(var p in payload){


				HTTP.addParam(name=p.name, value=p.value, type="formField");
			}


			for(var f in files){
				HTTP.addParam(name=f, file=files[f], type="file");
			}


			var res = HTTP.send();

		return res.getPrefix();
	}


	function getMerchantAuthentication(){
		return {
			"username":variables.cfpayment.username,
			"password": variables.cfpayment.password

		}
	}
}
