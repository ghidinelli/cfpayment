component
	displayname='BaseCommerce Interface'
	output=false
	extends='cfpayment.api.gateway.base' {

	variables.cfpayment.GATEWAY_NAME = 'BaseCommerce';
	variables.cfpayment.GATEWAY_VERSION = '1.0';
	
	public string function getProcessorID() {
		return variables.cfpayment.ProcessorID;
	}

	//Implement primary methods
	public any function purchase(required any money, struct options=structNew()) {
		arguments.options.batType = 'XS_BAT_TYPE_DEBIT';
		return populateResponse(transactionData(argumentcollection = arguments));
	}
	
	public any function credit(required any money, struct options=structNew()) {
		arguments.options.batType = 'XS_BAT_TYPE_CREDIT';
		return populateResponse(transactionData(argumentcollection = arguments));
	}
	
	public any function store(required any account, struct options=structNew()) {
		return populateResponse(accountData(account, options));
	}

	//Private Functions
	private any function populateResponse(required struct data) {
		//Response object populated outside of the gateway connection methods (accountData, transactionData) to allow for mocking of data in offline unit tests
		local.response = createResponse();
		if(structKeyExists(arguments.data, 'status')) local.response.setStatus(arguments.data.status);
		if(structKeyExists(arguments.data, 'message')) local.response.setMessage(arguments.data.message);
		if(structKeyExists(arguments.data, 'statusCode')) local.response.setStatusCode(arguments.data.statusCode);
		if(structKeyExists(arguments.data, 'tokenId')) local.response.setTokenId(arguments.data.tokenId);
		if(structKeyExists(arguments.data, 'transactionId')) local.response.setTransactionId(arguments.data.transactionId);
		if(structKeyExists(arguments.data, 'result')) local.response.setParsedResult(deserializeJson(arguments.data.result));
		if(structKeyExists(arguments.data, 'result')) local.response.setResult(arguments.data.result);
		return local.response;
	}
	
	private struct function accountData(required any account, struct options=structNew()) {
		local.bankData = structNew();

		if(getService().getAccountType(arguments.account) == 'eft') {
			local.bankAccountObj = createObject('java', 'com.basecommercepay.client.BankAccount');
			//Populate bank account object data passed in to this object
			local.bankAccountObj.setName(arguments.options.name);
			local.bankAccountObj.setAccountNumber(toString(arguments.account.getAccount()));
			local.bankAccountObj.setRoutingNumber(toString(arguments.account.getRoutingNumber()));

			//Check that bank account type is valid, otherwise return error
			try {
				local.bankAccountObj.setType(local.bankAccountObj[arguments.account.getAccountType()]);
			} catch(any e) {
				local.bankData.status = 3;
				if(arguments.account.getAccountType() == '') local.bankData.message = ['Missing account type'];
				else local.bankData.message = ['Invalid account type passed in: #arguments.account.getAccountType()#'];
				local.bankData.statusCode = 400;
				return local.bankData;
			}

			//Set up connection object
			local.baseCommerceClientObj = createObject('java', 'com.basecommercepay.client.BaseCommerceClient');
			local.baseCommerceClientObj.init(variables.cfpayment.Username, variables.cfpayment.Password, variables.cfpayment.MerchantAccount);
			local.baseCommerceClientObj.setSandbox(variables.cfpayment.TestMode);
			
			//Send account request to BaseCommerce api and update bank account object with result
			local.bankAccountObj = baseCommerceClientObj.addBankAccount(bankAccountObj);

			//Extract data and handle errors
			if(local.bankAccountObj.isStatus(local.bankAccountObj.XS_BA_STATUS_FAILED)) {
				local.bankData.status = 3;
				local.bankData.message = local.bankAccountObj.getMessages();
				local.bankData.statusCode = 400;
			} else if(local.bankAccountObj.isStatus(local.bankAccountObj.XS_BA_STATUS_ACTIVE)) {
				//Get BaseCommerce returned data and insert into intermediate struct for later insertion into cfpayment response object
				local.bankData.tokenId = local.bankAccountObj.getToken();
				local.responseData = structNew();
				local.responseData.type = local.bankAccountObj.getType();
				local.responseData.status = local.bankAccountObj.getStatus();
				local.bankData.result = serializeJson(local.responseData);
				local.bankData.statusCode = 200;
			} else {
				local.bankData.status = 3;
				local.bankData.message = ['Status not expected: "#local.bankAccountObj.getStatus()#"'];
				local.bankData.statusCode = 400;
			}
		} else {
			local.bankData.status = 3;
			local.bankData.message = ['Unsupported account type: "#getService().getAccountType(arguments.account)#"'];
			local.bankData.statusCode = 400;
		}

		return local.bankData;
	}

	private any function transactionData(required any money, any account, struct options=structNew()) {
		local.transactionData = structNew();
		local.bankAccountTransactionObj = createObject('java', 'com.basecommercepay.client.BankAccountTransaction');

		//Populate transaction object with data passed into this method
		local.bankAccountTransactionObj.setType(local.bankAccountTransactionObj[arguments.options.batType]);
		local.bankAccountTransactionObj.setAmount(arguments.money.getAmount());
		local.bankAccountTransactionObj.setToken(arguments.options.tokenId);

		//Check that transaction method is valid, otherwise return error
		try {
			local.bankAccountTransactionObj.setMethod(local.bankAccountTransactionObj[arguments.options.method]);
		} catch(any e) {
			local.transactionData.status = 3;
			if(arguments.options.method == '') local.transactionData.message = ['Missing transaction method'];
			else local.transactionData.message = ['Invalid transaction method passed in: #arguments.options.method#'];
			local.transactionData.statusCode = 400;
			return local.transactionData;
		}

		//Check that effective date (days from now) is a valid integer within range
		param name='arguments.options.effectiveDateDaysFromNow' default='';
		if(isValid('integer', arguments.options.effectiveDateDaysFromNow) && arguments.options.effectiveDateDaysFromNow >= 0 && arguments.options.effectiveDateDaysFromNow <= 1000) {
			local.locale = createObject('java', 'java.util.Locale');
			local.calendarObj = createObject('java', 'java.util.GregorianCalendar').init(local.locale.US);
			local.calendarObj.set(local.calendarObj.DAY_OF_YEAR, local.calendarObj.get(local.calendarObj.DAY_OF_YEAR) + arguments.options.effectiveDateDaysFromNow);
			local.effectiveDate = local.calendarObj.getTime();
			local.bankAccountTransactionObj.setEffectiveDate(local.effectiveDate);
		} else {
			local.transactionData.status = 3;
			if(arguments.options.effectiveDateDaysFromNow == '') local.transactionData.message = ['Missing Effective date (days from now)'];
			else if(!isNumeric(arguments.options.effectiveDateDaysFromNow)) local.transactionData.message = ['Effective date (days from now) is not a number'];
			else if(arguments.options.effectiveDateDaysFromNow < 0) local.transactionData.message = ['Effective date (days from now) must be 0 or greater'];
			else if(arguments.options.effectiveDateDaysFromNow > 1000) local.transactionData.message = ['Effective date (days from now) must be 1000 or lower'];
			else if(!isValid('integer', arguments.options.effectiveDateDaysFromNow)) local.transactionData.message = ['Effective date (days from now) must be an integer'];
			else local.transactionData.message = ['Effective date (days from now) is not valid'];
			local.transactionData.statusCode = 400;
			return local.transactionData;
		}

		//Set up client connection object
		local.baseCommerceClientObj = createObject('java', 'com.basecommercepay.client.BaseCommerceClient');
		local.baseCommerceClientObj.init(variables.cfpayment.Username, variables.cfpayment.Password, variables.cfpayment.MerchantAccount);
		local.baseCommerceClientObj.setSandbox(variables.cfpayment.TestMode);
		
		//Send transaction request to BaseCommerce api and update transaction object with result
		local.bankAccountTransactionObj = local.baseCommerceClientObj.processBankAccountTransaction(local.bankAccountTransactionObj);

		//Extract data and handle errors
		if(local.bankAccountTransactionObj.isStatus(local.bankAccountTransactionObj.XS_BAT_STATUS_FAILED)) {
			local.transactionData.status = 3;
			local.transactionData.message = local.bankAccountTransactionObj.getMessages();
			local.transactionData.statusCode = 400;
		} else if(local.bankAccountTransactionObj.isStatus(local.bankAccountTransactionObj.XS_BAT_STATUS_CREATED)) {
			//Get BaseCommerce returned data and insert into intermediate struct for later insertion into cfpayment response object
			local.transactionData.tokenId = local.bankAccountTransactionObj.getToken();
			local.transactionData.transactionId = local.bankAccountTransactionObj.getBankAccountTransactionId();
			local.responseData = structNew();
			local.responseData.type = local.bankAccountTransactionObj.getType();
			local.responseData.status = local.bankAccountTransactionObj.getStatus();
			local.responseData.effectiveDate = local.bankAccountTransactionObj.getEffectiveDate();
			local.responseData.settlementDate = local.bankAccountTransactionObj.getSettlementDate();
			local.responseData.accountType = local.bankAccountTransactionObj.getAccountType();
			local.responseData.amount = local.bankAccountTransactionObj.getAmount();
			local.responseData.merchantTransactionID = local.bankAccountTransactionObj.getMerchantTransactionID();
			local.responseData.method = local.bankAccountTransactionObj.getMethod();
			local.transactionData.result = serializeJson(local.responseData);
			local.transactionData.statusCode = 200;
		} else {
			local.transactionData.status = 3;
			local.transactionData.message = ['Status not expected: "#local.transactionData.getStatus()#"'];
			local.transactionData.statusCode = 400;
		}

		return local.transactionData;
	}
}	
