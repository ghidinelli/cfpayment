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
		if(structKeyExists(arguments.data, 'status')) local.response.setStatus(translateStatus(arguments.data.status));
		if(structKeyExists(arguments.data, 'message') && isArray(arguments.data.message)) local.response.setMessage(arrayToList(arguments.data.message));
		if(structKeyExists(arguments.data, 'statusCode')) local.response.setStatusCode(arguments.data.statusCode);
		if(structKeyExists(arguments.data, 'tokenId')) local.response.setTokenId(arguments.data.tokenId);
		if(structKeyExists(arguments.data, 'transactionId')) local.response.setTransactionId(arguments.data.transactionId);

		local.response.setParsedResult(arguments.data);
		local.response.setResult(serializeJson(arguments.data));

		return local.response;
	}
	
	private struct function accountData(required any account, struct options=structNew()) {
		local.bankData = structNew();

		if(getService().getAccountType(arguments.account) == 'eft') {
			local.bankAccountObj = createObject('java', 'com.basecommercepay.client.BankAccount');

			//Populate bank account object data passed in to this object
			local.bankAccountObj.setName(arguments.account.getFirstName() & ' ' & arguments.account.getLastName());
			local.bankAccountObj.setAccountNumber(toString(arguments.account.getAccount()));
			local.bankAccountObj.setRoutingNumber(toString(arguments.account.getRoutingNumber()));

			//Check that bank account type is valid, otherwise return error
			try {
				//local.bankAccountObj[arguments.account.getAccountType()] is accessing the java object's field, simmilar to accessing struct values in CF
				local.bankAccountObj.setType(local.bankAccountObj[arguments.account.getAccountType()]);
			} catch(any e) {
				local.bankData.status = 'FAILED';
				if(!isDefined('arguments.account')) local.bankData.message = ['Missing account object in arguments'];
				else if(arguments.account.getAccountType() == '') local.bankData.message = ['Missing account type'];
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
				local.bankData.status = local.bankAccountObj.getStatus();
				local.bankData.message = local.bankAccountObj.getMessages();
				local.bankData.statusCode = 400;
			} else if(local.bankAccountObj.isStatus(local.bankAccountObj.XS_BA_STATUS_ACTIVE)) {
				//Get BaseCommerce returned data and insert into intermediate struct for later insertion into cfpayment response object
				local.bankData.tokenId = local.bankAccountObj.getToken();
				local.bankData.type = local.bankAccountObj.getType();
				local.bankData.status = local.bankAccountObj.getStatus();
				local.bankData.statusCode = 200;
			} else {
				local.bankData.status = local.bankAccountObj.getStatus();
				local.bankData.message = ['Status not expected: "#local.bankAccountObj.getStatus()#"'];
				local.bankData.statusCode = 400;
			}
		} else {
			local.bankData.status = local.bankAccountObj.getStatus();
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
			//local.bankAccountTransactionObj[arguments.options.method] is accessing the java object's field, simmilar to accessing struct values in CF
			local.bankAccountTransactionObj.setMethod(local.bankAccountTransactionObj[arguments.options.method]);
		} catch(any e) {
			local.transactionData.status = 'FAILED';
			if(!isDefined('arguments.options')) local.transactionData.message = ['Missing options in arguments'];
			else if(!structKeyExists(arguments.options, 'method')) local.transactionData.message = ['Missing message in arguments.options'];
			else if(arguments.options.method == '') local.transactionData.message = ['Missing transaction method'];
			else local.transactionData.message = ['Invalid transaction method passed in: #arguments.options.method#'];
			local.transactionData.statusCode = 400;
			return local.transactionData;
		}

		//Check that effective date (days from now) is a valid integer within range
		if(structKeyExists(arguments.options, 'effectiveDate') && isDate(arguments.options.effectiveDate)) {
			local.bankAccountTransactionObj.setEffectiveDate(arguments.options.effectiveDate);
		}

		//Set up client connection object
		local.baseCommerceClientObj = createObject('java', 'com.basecommercepay.client.BaseCommerceClient');
		local.baseCommerceClientObj.init(variables.cfpayment.Username, variables.cfpayment.Password, variables.cfpayment.MerchantAccount);
		local.baseCommerceClientObj.setSandbox(variables.cfpayment.TestMode);
		
		//Send transaction request to BaseCommerce api and update transaction object with result
		local.bankAccountTransactionObj = local.baseCommerceClientObj.processBankAccountTransaction(local.bankAccountTransactionObj);

		//Extract data and handle errors
		if(local.bankAccountTransactionObj.isStatus(local.bankAccountTransactionObj.XS_BAT_STATUS_FAILED)) {
			local.transactionData.status = local.bankAccountTransactionObj.getStatus();
			local.transactionData.message = local.bankAccountTransactionObj.getMessages();
			local.transactionData.statusCode = 400;
		} else if(local.bankAccountTransactionObj.isStatus(local.bankAccountTransactionObj.XS_BAT_STATUS_CREATED)) {
			//Get BaseCommerce returned data and insert into intermediate struct for later insertion into cfpayment response object
			local.transactionData.tokenId = local.bankAccountTransactionObj.getToken();
			local.transactionData.transactionId = local.bankAccountTransactionObj.getBankAccountTransactionId();
			local.transactionData.type = local.bankAccountTransactionObj.getType();
			local.transactionData.status = local.bankAccountTransactionObj.getStatus();
			local.transactionData.effectiveDate = local.bankAccountTransactionObj.getEffectiveDate();
			local.transactionData.settlementDate = local.bankAccountTransactionObj.getSettlementDate();
			local.transactionData.accountType = local.bankAccountTransactionObj.getAccountType();
			local.transactionData.amount = local.bankAccountTransactionObj.getAmount();
			local.transactionData.merchantTransactionID = local.bankAccountTransactionObj.getMerchantTransactionID();
			local.transactionData.method = local.bankAccountTransactionObj.getMethod();
			local.transactionData.statusCode = 200;
		} else {
			local.transactionData.status = local.bankAccountTransactionObj.getStatus();
			local.transactionData.message = ['Status not expected: "#local.transactionData.getStatus()#"'];
			local.transactionData.statusCode = 400;
		}

		return local.transactionData;
	}

	private any function translateStatus(required any status) {
		switch (arguments.status) 
		{
			case 'ACTIVE':
			case 'CREATED':
				return getService().getStatusSuccessful();
				break;

			case 'FAILED':
				return getService().getStatusFailure();
				break;

			default:
				throw(type = 'Application', message = 'Unknown BaseCommerce Status: #arguments.status#');
		}		
	}
}	
