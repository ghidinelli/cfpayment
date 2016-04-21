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
component
	extends="cfpayment.api.gateway.base"
	displayname="Merchantware API Interface"

{

	variables.cfpayment.GATEWAY_LIVE_URL = "https://ps1.merchantware.net/Merchantware/ws/RetailTransaction/v4/Credit.asmx";

	
	function init(){
		super.init(argumentCollection=arguments);

		//we require 
		if(!structKeyExists(config, "merchantName")){
			throw("merchantName is required")
		}
		if(!structKeyExists(config, "merchantSiteId")){
			throw("merchantSiteId is required")
		}
		if(!structKeyExists(config, "merchantKey")){
			throw("merchantKey is required")
		}
		
		variables.cfpayment.merchantName = config.merchantName;
		variables.cfpayment.merchantSiteId = config.merchantSiteId;
		variables.cfpayment.merchantKey = config.merchantKey;

		return this;

	}

	function purchase(Any required money, Any requred account, Struct options={}){

		//Need to append /SaleKeyed to url
		var requestType = "SaleKeyed";

		var MerchantWareRequest = new MerchantWareRequest();
		var payload = MerchantWareRequest.createPayload(
				requestType=requestType,
				merchantAuthentication=getMerchantAuthentication(),
				money=money,
				account=account,
				options=options
			);


		var urlDest = variables.cfpayment.GATEWAY_LIVE_URL & "/" & requestType;
		var result  = super.process(payload = payload, url=urlDest);
		 	result["service"] = super.getService();
		 	result["testmode"] = super.getTestMode();
		 


		dump(result);
		dump([arguments, payload]);

		abort;		//Raw result	
		 var resp = new transactionResponse(argumentCollection=result);
		return resp;


	
		throw("Method Not Implemented");
	}

	function authorize(Any required money, Any requred account, Struct options={}){

		throw("Method Not Implemented");
	}

	function capture(Any required money, String required authorization, Struct options={}){

		throw("Method Not Implemented");
	}

	function credit(Any required transactionID, Any required money, Struct options={}) {

		throw("Method Not Implemented");

	}
	function void(Any required transactionID, Struct options={}) {

		throw("Method Not Implemented");

	}
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

				
				HTTP.addParam(name=p.name, value=Trim(p.value), type="formField");	
			}
			

			for(var f in files){
				HTTP.addParam(name=f, file=files[f], type="file");
			}

		
			var res = HTTP.send();
			
		return res.getPrefix();
	}


	function getMerchantAuthentication(){
		
		return {
			"merchantName" : variables.cfpayment.merchantName,
      		"merchantSiteId" : variables.cfpayment.merchantSiteID,
      		"merchantKey" : variables.cfpayment.merchantKey
			
			 
		}
	}
}