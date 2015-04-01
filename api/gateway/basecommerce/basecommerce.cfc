component
	displayname='BaseCommerce Interface'
	output=false
	extends='cfpayment.api.gateway.base' {

	variables.cfpayment.GATEWAY_NAME = 'BaseCommerce';
	variables.cfpayment.GATEWAY_VERSION = '1.0';
	variables.cfpayment.GATEWAY_LIVE_URL = '';
	variables.cfpayment.GATEWAY_TEST_URL = '';
	variables.cfpayment.ProcessorID = '';
	
	public string function getProcessorID() {
		return variables.cfpayment.ProcessorID;
	}

	private any function process(required struct payload, struct options=structNew()) {
		local.response = '';
		local.results = structNew();
		local.pairs = '';
		local.ii = '';
		local.p = arguments.payload; //shortcut (by reference)

		//Create structure of URL parameters; swap in test parameters if necessary
		if(getTestMode()) {
			local.p['username'] = '';
			local.p['password'] = '';
		} else {
			local.p['username'] = getUsername();
			local.p['password'] = getPassword();
		}
		//Optionally include a procesor id for specifying a specific backend
		if(len(getProcessorID())) {
			local.p['processor_id'] = getProcessorID();
		}
		
		//Provide optional data
		structAppend(local.p, arguments.options, true);
		
		//Process standard and common CFPAYMENT mappings into Braintree-specific values
		if(structKeyExists(arguments.options, 'orderId')) {
			local.p['order_id'] = arguments.options.orderId;
		}
		if(structKeyExists(arguments.options, 'tokenId')) {
			local.p['customer_vault_id'] = arguments.options.tokenId;
		}

		//BaseCommerce does not use cfhttp
		//local.response = createResponse(argumentCollection = super.process(payload = local.p));
		//So use empty response instead
		local.response = createResponse(argumentCollection = createEmptyResponse(payload = local.p));

		//We do some meta-checks for gateway-level errors (as opposed to auth/decline errors)
		if(!local.response.hasError()) {

			//we need to have a result; otherwise that's an error in itself	
			if(len(local.response.getResult())) {

				if(isXML(local.response.getResult())) {
					//Returned from query api, just shoehorn it in and return the result
					local.results = xmlParse(local.response.getResult());					
					
					//Store parsed result
					local.response.setParsedResult(local.results);
					
					//Check returned XML for success/failure
					if(structKeyExists(local.results.xmlRoot, 'error_response')) {
						local.response.setStatus(getService().getStatusFailure());
					} else {
						local.response.setStatus(getService().getStatusSuccessful());
					}
				} else {
					local.pairs = listToArray(local.response.getResult(), '&');
					//split the variable=value
					for(local.ii=1; local.ii <= arrayLen(pairs); local.ii++) {
						if(listLen(local.pairs[local.ii], '=') GT 1) {
							local.results[listFirst(local.pairs[local.ii], '=')] = listLast(local.pairs[local.ii], '=');
						} else {
							local.results[listFirst(local.pairs[local.ii], '=')] = '';
						}
                    }
                    
					//store parsed result
					local.response.setParsedResult(local.results);
	
					//handle common response fields
					if(structKeyExists(local.results, 'response_code')) {
						local.response.setMessage(variables.braintree[local.results.response_code]);
					}
					if(structKeyExists(local.results, 'response_text')) {
						local.response.setMessage(local.response.getMessage() & ': ' & variables.braintree[local.results.response_text]);
					}
					if(structKeyExists(local.results, 'transactionid')) {
						local.response.setTransactionID(local.results.transactionid);
					}
					if(structKeyExists(local.results, 'authcode')) {
						local.response.setAuthorization(local.results.authcode);
					}
					if(structKeyExists(local.results, 'customer_vault_id')) {
						local.response.setTokenID(local.results.customer_vault_id);
					}
					
					//handle common 'success' fields
					if(structKeyExists(local.results, 'avsresponse')) {
						local.response.setAVSCode(local.results.avsresponse);
					}
					if(structKeyExists(local.results, 'cvvresponse')) {
						local.response.setCVVCode(local.results.cvvresponse);
					}
	
					//see if the response was successful
					if(local.results.response EQ '1') {
						local.response.setStatus(getService().getStatusSuccessful());
					} else if(local.results.response EQ '2') {
						local.response.setStatus(getService().getStatusDeclined());
					} else {
						//only other known state is 3 meaning, 'error in transaction data or system error'
						local.response.setStatus(getService().getStatusFailure());
					}
				}
			} else {
				//This is bad, because Braintree didn't return a response.  Uh oh!
				local.response.setStatus(getService().getStatusUnknown());
			}
		}
		
		return local.response;
	}

	private any function createResponse() {
		return createObject("component", "cfpayment.api.gateway.basecommerce.response").init(argumentCollection = arguments, service = getService());
	}
	
	private any function CreateEmptyResponse(struct payload=structNew()) {
		local.response = structNew();
		
		local.response.message = '';
		local.response.result = '';
		local.response.status = 0;
		local.response.statusCode = '';
		local.response.testMode = true;
		local.response.requestData = structNew();
		local.response.requestData['gateway_url'] = '';
		local.response.requestData['headers'] = structNew();
		local.response.requestData['http_method'] = '';
		local.response.requestData['payload'] = arguments.payload;
		
		return local.response;
	}

	//Implement primary methods
	public any function purchase(required any money, any account, struct options=structNew()) {
		local.argumentCollection = structNew();
		local.argumentCollection.money = arguments.money;
		if(isDefined('arguments.account')) local.argumentCollection.money = arguments.account;
		local.argumentCollection.options = arguments.options;
		local.argumentCollection.options.batType = 'XS_BAT_TYPE_CREDIT';
		return transaction(argumentCollection = local.argumentCollection);
	}
	
	public any function credit(required any money, any account, struct options=structNew()) {
		local.argumentCollection = structNew();
		local.argumentCollection.money = arguments.money;
		if(isDefined('arguments.account')) local.argumentCollection.money = arguments.account;
		local.argumentCollection.options = arguments.options;
		local.argumentCollection.options.batType = 'XS_BAT_TYPE_DEBIT';
		return transaction(argumentCollection = local.argumentCollection);
	}
	
	public any function store(required any account, struct options=structNew()) {
		switch(getService().getAccountType(arguments.account)) {
			case 'creditcard':
			break;
			case 'eft':
				local.bankAccountObj = createObject('java', 'com.basecommercepay.client.BankAccount');
				local.bankAccountObj.setName(arguments.options.name);
				local.bankAccountObj.setAccountNumber(toString(arguments.account.getAccount()));
				local.bankAccountObj.setRoutingNumber(toString(arguments.account.getRoutingNumber()));
				local.bankAccountObj.setType(bankAccountObj[arguments.account.getAccountType()]);

				local.baseCommerceClientObj = createObject('java', 'com.basecommercepay.client.BaseCommerceClient');
				local.baseCommerceClientObj.init(variables.cfpayment.Username, variables.cfpayment.Password, variables.cfpayment.MerchantAccount);
				local.baseCommerceClientObj.setSandbox(variables.cfpayment.TestMode);
				local.bankAccountObj = baseCommerceClientObj.addBankAccount(bankAccountObj);

				if(bankAccountObj.isStatus(bankAccountObj.XS_BA_STATUS_FAILED)) {
					bankAccountObj.getMessages();
				} else if(bankAccountObj.isStatus(bankAccountObj.XS_BA_STATUS_ACTIVE)) {
					bankAccountObj.getToken();
				}
			break;
			default:
				throw(type='cfpayment.InvalidAccount', message='Account type of token is not supported by this method');
		}
		return bankAccountObj;

		/*
		local.post['customer_vault'] = 'add_customer';
		local.post = addCustomer(post = local.post, account = arguments.account);

		if(structKeyExists(arguments.options, 'tokenId')) {
			local.post['customer_vault_id'] = arguments.options.tokenId;
			local.post['customer_vault'] = 'update_customer';
		}
		return process(payload = post, options = arguments.options);
		*/
	}

	//Private Functions
	private any function transaction(required any money, any account, struct options=structNew()) {
		bankAccountTransactionObj = createObject('java', 'com.basecommercepay.client.BankAccountTransaction');
		bankAccountTransactionObj.setType(bankAccountTransactionObj[arguments.options.batType]);
		bankAccountTransactionObj.setMethod(bankAccountTransactionObj.XS_BAT_METHOD_CCD);
		bankAccountTransactionObj.setAmount(arguments.money.getAmount());

		locale = createObject('java', 'java.util.Locale');
		calendarObj = createObject('java', 'java.util.GregorianCalendar').init(locale.US);
		calendarObj.set(calendarObj.DAY_OF_YEAR, calendarObj.get(calendarObj.DAY_OF_YEAR) + 3);
		effectiveDate = calendarObj.getTime();
		bankAccountTransactionObj.setEffectiveDate(effectiveDate);
		bankAccountTransactionObj.setToken(arguments.options.tokenId);


		local.baseCommerceClientObj = createObject('java', 'com.basecommercepay.client.BaseCommerceClient');
		local.baseCommerceClientObj.init(variables.cfpayment.Username, variables.cfpayment.Password, variables.cfpayment.MerchantAccount);
		local.baseCommerceClientObj.setSandbox(variables.cfpayment.TestMode);
		bankAccountTransactionObj = local.baseCommerceClientObj.processBankAccountTransaction(bankAccountTransactionObj);

		return bankAccountTransactionObj;
		/*
		local.post = structNew();
		local.post['amount'] = arguments.money.getAmount();
		if(structKeyExists(arguments, 'account') && getService().getAccountType(arguments.account) EQ 'eft') {
			local.post['type'] = 'credit';
			local.post = addEFT(post = local.post, account = arguments.account, options = arguments.options);
		} else if(structKeyExists(arguments.options, 'tokenId')) {
			local.post['type'] = 'credit';
			local.post['customer_vault_id'] = arguments.options.tokenId;
		}
		return process(payload = local.post, options = arguments.options);
		*/
	}

	private any function addCustomer(required struct post, required any account) {
		arguments.post['firstname'] = arguments.account.getFirstName();
		arguments.post['lastname'] = arguments.account.getLastName();
		arguments.post['address1'] = arguments.account.getAddress();
		arguments.post['city'] = arguments.account.getCity();
		arguments.post['state'] = arguments.account.getRegion();
		arguments.post['zip'] = arguments.account.getPostalCode();
		arguments.post['country'] = arguments.account.getCountry();
	
		return arguments.post;
	}

	private any function addEFT(required struct post, required any account, struct options=structNew()) {
		arguments.post['payment'] = 'check';
		arguments.post['checkname'] = arguments.account.getName();
		arguments.post['checkaba'] = arguments.account.getRoutingNumber();
		arguments.post['checkaccount'] = arguments.account.getAccount();
		arguments.post['account_type'] = arguments.account.getAccountType();
		arguments.post['phone'] = arguments.account.getPhoneNumber();
		arguments.post['sec_code'] = arguments.account.getSEC();

		//convert SEC code to braintree values
		if(arguments.account.getSEC() EQ 'PPD') {
			arguments.post['account_holder_type'] = 'personal';
		} else if(arguments.account.getSEC() EQ 'CCD') {
			arguments.post['account_holder_type'] = 'business';
		}

		//if we want to save the instrument to the vault; check if we have an optional vault id
		if(structKeyExists(arguments.options, 'tokenize')) {
			arguments.post['customer_vault'] = 'add_customer';
			if(structKeyExists(arguments.options, 'tokenId')) {
				arguments.post['customer_vault_id'] = arguments.options.tokenId;
			}
		}
	
		return arguments.post;
	}
}
