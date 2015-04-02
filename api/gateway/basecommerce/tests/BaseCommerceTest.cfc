component
	displayname='BaseCommerce Tests'
	output=false
	extends='mxunit.framework.TestCase' {

	public void function setUp() {
		var gw = structNew();

		gw.path = 'basecommerce.basecommerce';
		//Test account
		gw.Username = 'xxxxxxxxxxxxxxx';
		gw.Password = 'xxxxxxxxxxxxxxxxxx';
		gw.MerchantAccount = 'xxxxxxxxxxxxxxxxxxxxx';
		gw.TestMode = true; // defaults to true anyways

		// create gw and get reference			
		variables.svc = createObject('component', 'cfpayment.api.core').init(gw);
		variables.gw = variables.svc.getGateway();

		//if set to false, will try to connect to remote service to check these all out
		variables.localMode = false;
		variables.debugMode = false;
	}

	private void function offlineInjector(required any receiver, required any giver, required string functionName, string functionNameInReceiver='') {
		if(variables.localMode) {
			injectMethod(arguments.receiver, arguments.giver, arguments.functionName, arguments.functionNameInReceiver);
		}
	}

	private void function standardResponseTests(required any response) {
		if(debugMode) {
			debug(arguments.response.getParsedResult());
			debug(arguments.response.getResult());
		}

		if(isSimpleValue(arguments.response)) assertTrue(false, 'Response returned a simple value: "#arguments.response#"');
		if(!isObject(arguments.response)) assertTrue(false, 'Invalid: response is not an object');
		else if(arguments.response.getStatusCode() != 200) {
			if(arguments.response.hasError()) {
				if(arrayLen(arguments.response.getMessage())) {
					assertTrue(false, 'Message returned from BaseCommerce: <br />#arrayToList(arguments.response.getMessage(), "<br />")#');
				} else {
					assertTrue(false, 'Error found but no error message attached');
				}
			}
			assertTrue(false, 'Status code should be 200, was: #arguments.response.getStatusCode()#');
		} else if(isStruct(arguments.response.getParsedResult()) && structIsEmpty(arguments.response.getParsedResult())) {
			assertTrue(false, 'Response structure returned is empty');
		} else if(isSimpleValue(arguments.response.getParsedResult())) {
			assertTrue(false, 'Parsed response is a string, expected a structure. Returned string = "#arguments.response.getParsedResult()#"');
		}
	}

	private void function standardErrorResponseTests(required any response, required string expectedErrorType, required numeric expectedStatusCode) {
		if(debugMode) {
			debug(arguments.expectedErrorType);
			debug(arguments.expectedStatusCode);
			debug(arguments.response.getParsedResult());
			debug(arguments.response.getResult());
		}

		if(isSimpleValue(arguments.response)) assertTrue(false, 'Response returned a simple value: "#arguments.response#"');
		if(!isObject(arguments.response)) assertTrue(false, 'Invalid: response is not an object');
		else if(isStruct(arguments.response.getParsedResult()) && structIsEmpty(arguments.response.getParsedResult())) {
			assertTrue(false, 'Response structure returned is empty');
		} else if(isSimpleValue(arguments.response.getParsedResult())) {
			assertTrue(false, 'Parsed response is a string, expected a structure. Returned string = "#arguments.response.getParsedResult()#"');
		} else if(arguments.response.getStatusCode() != arguments.expectedStatusCode) {
			assertTrue(false, 'Status code should be #arguments.expectedStatusCode#, was: #arguments.response.getStatusCode()#');
		} else {
			if(structKeyExists(arguments.response.getParsedResult(), 'error')) {
				if(structKeyExists(arguments.response.getParsedResult().error, 'message') AND structKeyExists(arguments.response.getParsedResult().error, 'type')) {
					assertTrue(arguments.response.getParsedResult().error.type eq arguments.expectedErrorType, 'Received error type (#arguments.response.getParsedResult().error.type#), expected error type (#arguments.expectedErrorType#) from API');
				} else {
					assertTrue(false, 'Error message from API missing details');
				}
			} else {
				assertTrue(false, 'Object returned did not have an error');
			}
		}
	}

	//TESTS
	public void function testCreateAccount() {
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Accoiunt';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect bank account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');
	}

	public void function testCreditAccount() {
		//Create account
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Accoiunt';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid account status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');

		//Credit account
		local.options = structNew();
		local.options.tokenId = accountToken.getTokenId();
		offlineInjector(gw, this, 'mockCreditAccountOk', 'transactionData');
		credit = gw.credit(money = variables.svc.createMoney(500, 'USD'), options = local.options);
		standardResponseTests(credit);
		assertTrue(credit.getParsedResult().accountType == 'CHECKING', 'Incorrect bank account type, should be "Checking", is: "#credit.getParsedResult().accountType#"');
		assertTrue(credit.getParsedResult().amount == 5, 'The credit amount requested and the actual credit given is different, should be 5, is: #credit.getParsedResult().amount#');
		assertTrue(credit.getTransactionId() > 0, 'Invalid transaction id returned: #credit.getTransactionId()#');
		assertTrue(credit.getParsedResult().Status == 'CREATED', 'Invalid transaction status: #credit.getParsedResult().Status#');
		assertTrue(credit.getParsedResult().type == 'CREDIT', 'Incorrect transaction type, should be "CREDIT", is: "#credit.getParsedResult().type#"');
	}

	public void function testDebitAccount() {
		//Create account
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Accoiunt';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect bank account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');

		//Debit account
		local.options = structNew();
		local.options.tokenId = accountToken.getTokenId();
		offlineInjector(gw, this, 'mockDebitAccountOk', 'transactionData');
		debit = gw.purchase(money = variables.svc.createMoney(400, 'USD'), options = local.options);
		standardResponseTests(debit);
		assertTrue(debit.getParsedResult().accountType == 'CHECKING', 'Incorrect bank account type, should be "Checking", is: "#debit.getParsedResult().accountType#"');
		assertTrue(debit.getParsedResult().amount == 4, 'The credit amount requested and the actual credit given is different, should be 4, is: #debit.getParsedResult().amount#');
		assertTrue(debit.getTransactionId() > 0, 'Invalid transaction id returned: #debit.getTransactionId()#');
		assertTrue(debit.getParsedResult().Status == 'CREATED', 'Invalid transaction status: #debit.getParsedResult().Status#');
		assertTrue(debit.getParsedResult().type == 'DEBIT', 'Incorrect transaction type, should be "CREDIT", is: "#debit.getParsedResult().type#"');
	}

	//HELPERS
	private any function createAccount() {
		local.account = variables.svc.createEFT();
		local.account.setFirstName('John');
		local.account.setLastName('Doe');
		local.account.setAddress('123 Comox Street');
		local.account.setAddress2('West End');
		local.account.setCity('Vancouver');
		local.account.setRegion('BC');
		local.account.setPostalCode('V6G1S2');
		local.account.setCountry('Canada');
		local.account.setPhoneNumber('0123456789');
		local.account.setAccount(123123123123);
		local.account.setRoutingNumber(021000021);
		local.account.setCheckNumber();
		local.account.setAccountType('XS_BA_TYPE_CHECKING');
		local.account.setSEC();

		return local.account;	
	}

	//MOCKS
	private any function mockCreditAccountOk() {
		return { StatusCode = 200, transactionId = '43271', result = '{"MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"April, 03 2015 00:00:00","ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":5.0,"STATUS":"CREATED","SETTLEMENTDATE":"April, 06 2015 00:00:00","TYPE":"CREDIT"}' };
	}

	private any function mockCreateAccountOk() {
		return { statusCode = 200, tokenId = 'a347d5a9bc92015fe68871403775f012d204002f9f8419590d4363088376c20e', result = '{"STATUS":"ACTIVE","TYPE":"CHECKING"}' };
	}

	private any function mockDebitAccountOk() {
		return { StatusCode = 200, transactionId = '43275', result = '{"MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"April, 03 2015 00:00:00","ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":4.0,"STATUS":"CREATED","SETTLEMENTDATE":"April, 06 2015 00:00:00","TYPE":"DEBIT"}' };
	}
}
