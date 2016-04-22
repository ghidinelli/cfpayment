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

	variables.MerchantWareService = ""; //Needs to be configured at startup

	
	function init(){
		super.init(argumentCollection=arguments);

		//Create the webservice 

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
		variables.MerchantWareService = createObject("webservice", "#variables.cfpayment.GATEWAY_LIVE_URL#?wsdl");

		return this;

	}

	function purchase(Any required money, Any account, Struct options={}){

		//Need to append /SaleKeyed to url
		var requestType = "SaleKeyed";
		var creds = getMerchantAuthentication();


		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			invoiceNumber:"",
			amount:money.getCents(),
			cardNumber:account.getAccount(),
			expirationDate=DateFormat(account.getExpirationDate(), "MMYY"),
			cardholder=account.getName(),
			avsStreetAddress=account.getAddress(),
			avsStreetZipCode=account.getPostalCode(),
			cardSecurityCode=account.getVerificationValue(),
			forceDuplicate=getTestMode(),
			registerNumber="",
			merchantTransactionId="",
		}

		if(StructKeyExists(options,"invoiceNumber")){
			args["invoiceNumber"]=options.invoiceNumber;
		}
		if(StructKeyExists(options,"registerNumber")){
			args["registerNumber"]=options.registerNumber;
		}
		if(StructKeyExists(options,"merchantTransactionId")){
			args["merchantTransactionId"]=options.merchantTransactionId;
		}
		

		var resp = variables.MerchantWareService.SaleKeyed(argumentCollection=args );


			//Raw result	
		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType": "SaleKeyed"
		};

		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;
	}

	function purchaseVault(required money, Any vaultToken, Struct options={}){

		var requestType = "SaleVault";
		var creds = getMerchantAuthentication();


		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			invoiceNumber:"",
			amount:money.getCents(),
			vaultToken: vaultToken,
			forceDuplicate=getTestMode(),
			registerNumber="",
			merchantTransactionId="",
		}

		if(StructKeyExists(options,"invoiceNumber")){
			args["invoiceNumber"]=options.invoiceNumber;
		}
		if(StructKeyExists(options,"registerNumber")){
			args["registerNumber"]=options.registerNumber;
		}
		if(StructKeyExists(options,"merchantTransactionId")){
			args["merchantTransactionId"]=options.merchantTransactionId;
		}
		

		var resp = variables.MerchantWareService.SaleVault(argumentCollection=args );


			//Raw result	
		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType": "SaleVault"
		};

		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;
	}

	function authorize(Any required money, Any requred account, Struct options={}){

		var requestType = "PreAuthorizationKeyed";
		var creds = getMerchantAuthentication();

		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			invoiceNumber:"",
			amount:money.getCents(),
			cardNumber:account.getAccount(),
			expirationDate=DateFormat(account.getExpirationDate(), "MMYY"),
			cardholder=account.getName(),
			avsStreetAddress=account.getAddress(),
			avsStreetZipCode=account.getPostalCode(),
			cardSecurityCode=account.getVerificationValue(),
			registerNumber="",
			merchantTransactionId="",
		}

		if(StructKeyExists(options,"invoiceNumber")){
			args["invoiceNumber"]=options.invoiceNumber;
		}
		if(StructKeyExists(options,"registerNumber")){
			args["registerNumber"]=options.registerNumber;
		}
		if(StructKeyExists(options,"merchantTransactionId")){
			args["merchantTransactionId"]=options.merchantTransactionId;
		}
		
		var resp = variables.MerchantWareService.PreAuthorizationKeyed(argumentCollection=args );
		//Raw result	
		
		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType": "PreAuthorizationKeyed"
		};
		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;
	}

	function capture(Any required money, String required authorization, Struct options={}){

		var requestType = "PostAuthorization";
		var creds = getMerchantAuthentication();

		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			invoiceNumber:"",
			amount:money.getCents(),
			token:authorization,
			registerNumber="",
			merchantTransactionId="",
		}

		if(StructKeyExists(options,"invoiceNumber")){
			args["invoiceNumber"]=options.invoiceNumber;
		}
		if(StructKeyExists(options,"registerNumber")){
			args["registerNumber"]=options.registerNumber;
		}
		if(StructKeyExists(options,"merchantTransactionId")){
			args["merchantTransactionId"]=options.merchantTransactionId;
		}
		
		var resp = variables.MerchantWareService.PostAuthorization(argumentCollection=args );
		//Raw result	
		
		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType": "PostAuthorization"
		};
		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;
	}

	public Any function refund(required Any transactionID, required Any money, Struct options={}){

		var requestType = "Refund";
		var creds = getMerchantAuthentication();

		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			invoiceNumber:"",
			overrideAmount:money.getCents(),
			token:transactionID,
			registerNumber="",
			merchantTransactionId="",
		}

		if(StructKeyExists(options,"invoiceNumber")){
			args["invoiceNumber"]=options.invoiceNumber;
		}
		if(StructKeyExists(options,"registerNumber")){
			args["registerNumber"]=options.registerNumber;
		}
		if(StructKeyExists(options,"merchantTransactionId")){
			args["merchantTransactionId"]=options.merchantTransactionId;
		}
		
		var resp = variables.MerchantWareService.Refund(argumentCollection=args );
		//Raw result	
		
		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType": "Refund"
		};
		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;
	}


	function credit(Any required transactionID, Any required money, Struct options={}) {

		throw("Method Not Implemented");

	}



	function void(required Any transactionID, Struct options={}) {

		var requestType = "Void";
		var creds = getMerchantAuthentication();

		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			
			token:transactionID,
			registerNumber="",
			merchantTransactionId="",
		}


		if(StructKeyExists(options,"registerNumber")){
			args["registerNumber"]=options.registerNumber;
		}
		if(StructKeyExists(options,"merchantTransactionId")){
			args["merchantTransactionId"]=options.merchantTransactionId;
		}
		
		var resp = variables.MerchantWareService.Void(argumentCollection=args );
		//Raw result	
		
		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType": "Void"
		};
		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;

	}

	function store(String merchantDefinedToken="", required account) {

		var requestType = "VaultBoardCreditKeyed";
		var creds = getMerchantAuthentication();

		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			merchantDefinedToken=merchantDefinedToken,
			cardNumber:account.getAccount(),
			expirationDate=DateFormat(account.getExpirationDate(), "MMYY"),
			cardholder=account.getName(),
			avsStreetAddress=account.getAddress(),
			avsStreetZipCode=account.getPostalCode(),
		}


		var resp = variables.MerchantWareService.VaultBoardCreditKeyed(argumentCollection=args );
		//Raw result	
		
		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType": "Void"
		};
		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;

	}

	function unstore(String vaultToken="") {

		var requestType = "VaultDeleteToken";
		var creds = getMerchantAuthentication();

		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			vaultToken=vaultToken,
		}


		var resp = variables.MerchantWareService.VaultDeleteToken(argumentCollection=args );
		//Raw result	

		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType": "VaultDeleteToken"
		};
		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;

	}


	function getCustomer(String merchantDefinedToken="") {

		var requestType = "VaultFindPaymentInfo";
		var creds = getMerchantAuthentication();

		var args = {
			merchantName:creds.merchantName,
			merchantSiteId:creds.merchantSiteId,
			merchantKey:creds.merchantKey,
			vaultToken=merchantDefinedToken,
		}


		var resp = variables.MerchantWareService.VaultFindPaymentInfo(argumentCollection=args );
		//Raw result	
		
		var result = {
			"parsedResult": resp,
			"service" : super.getService(),
			"testmode" : super.getTestMode(),
			"requestType":requestType
		};
		var formattedresponse = new MerchantWareResponse(argumentCollection=result);

		return formattedresponse;

	}

	function getMerchantAuthentication(){
		
		return {
			"merchantName" : variables.cfpayment.merchantName,
      		"merchantSiteId" : variables.cfpayment.merchantSiteID,
      		"merchantKey" : variables.cfpayment.merchantKey
			
			 
		}
	}
}