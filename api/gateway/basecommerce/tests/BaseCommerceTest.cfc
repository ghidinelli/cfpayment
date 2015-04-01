component
	displayname='BaseCommerce Tests'
	output=false
	extends='mxunit.framework.TestCase' {

	public void function setUp() {
		var gw = structNew();

		gw.path = 'basecommerce.basecommerce';
		//Test account
		gw.Username = 'xxxxxxxxxxxxx';
		gw.Password = 'xxxxxxxxxxxxxxx';
		gw.MerchantAccount = 'xxxxxxxxxxxxxxxxxx';
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
		else if(isStruct(arguments.response.getParsedResult()) && structIsEmpty(arguments.response.getParsedResult())) {
			assertTrue(false, 'Response structure returned is empty');
		} else if(isSimpleValue(arguments.response.getParsedResult())) {
			assertTrue(false, 'Parsed response is a string, expected a structure. Returned string = "#arguments.response.getParsedResult()#"');
		} else if(arguments.response.getStatusCode() != 200) {
			if(structKeyExists(arguments.response.getParsedResult(), 'error')) {
				assertTrue(false, 'Error From Stripe: (Type=#arguments.response.getParsedResult().error.type#) #arguments.response.getParsedResult().error.message#');
			}
			assertTrue(false, 'Status code should be 200, was: #arguments.response.getStatusCode()#');
		} else {
			assertTrue(arguments.response.getSuccess(), 'Response not successful');
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
		offlineInjector(gw, this, 'mockCreateAccountOk', 'doHttpCall');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		assertTrue(arrayLen(accountToken.getMessages()) == 0, '#arrayLen(accountToken.getMessages())# message(s) where returned from BaseCommerce: #arrayToList(accountToken.getMessages(), "<br />")#');
		assertTrue(accountToken.getStatus() == 'ACTIVE', 'Invalid status: #accountToken.getStatus()#');
		assertTrue(accountToken.getType() == 'CHECKING', 'Incorrect bank account type, should be Checking');
		assertTrue(accountToken.getToken() != '', 'Token not returned');
	}

	public void function testCreditAccount() {
		//Create account
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Accoiunt';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'doHttpCall');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		assertTrue(arrayLen(accountToken.getMessages()) == 0, '#arrayLen(accountToken.getMessages())# message(s) where returned from BaseCommerce: #arrayToList(accountToken.getMessages(), "<br />")#');
		assertTrue(accountToken.getStatus() == 'ACTIVE', 'Invalid status: #accountToken.getStatus()#');
		assertTrue(accountToken.getType() == 'CHECKING', 'Incorrect bank account type, should be Checking');
		assertTrue(accountToken.getToken() != '', 'Token not returned');

		//Credit account
		local.options = structNew();
		local.options.tokenId = accountToken.getToken();
		offlineInjector(gw, this, 'mockCreditAccountOk', 'doHttpCall');
		credit = gw.credit(money = variables.svc.createMoney(500, 'USD'), options = local.options);
		assertTrue(arrayLen(credit.getMessages()) == 0, '#arrayLen(credit.getMessages())# message(s) where returned from BaseCommerce: #arrayToList(credit.getMessages(), "<br />")#');
		assertTrue(credit.getBankAccountTransactionId() > 0, 'Invalid transaction id returned: #credit.getBankAccountTransactionId()#');
	}

	public void function testDebitAccount() {
		//Create account
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Accoiunt';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'doHttpCall');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		assertTrue(arrayLen(accountToken.getMessages()) == 0, '#arrayLen(accountToken.getMessages())# message(s) where returned from BaseCommerce: #arrayToList(accountToken.getMessages(), "<br />")#');
		assertTrue(accountToken.getStatus() == 'ACTIVE', 'Invalid status: #accountToken.getStatus()#');
		assertTrue(accountToken.getType() == 'CHECKING', 'Incorrect bank account type, should be Checking');
		assertTrue(accountToken.getToken() != '', 'Token not returned');

		//Debit account
		local.options = structNew();
		local.options.tokenId = accountToken.getToken();
		offlineInjector(gw, this, 'mockDebitAccountOk', 'doHttpCall');
		debit = gw.purchase(money = variables.svc.createMoney(500, 'USD'), options = local.options);
		assertTrue(arrayLen(debit.getMessages()) == 0, '#arrayLen(debit.getMessages())# message(s) where returned from BaseCommerce: #arrayToList(debit.getMessages(), "<br />")#');
		assertTrue(debit.getBankAccountTransactionId() > 0, 'Invalid transaction id returned: #debit.getBankAccountTransactionId()#');
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
		return { StatusCode = '200 OK', FileContent = '' };
	}

	private any function mockCreateAccountOk() {
		return { StatusCode = '200 OK', FileContent = '' };
	}

	private any function mockDebitAccountOk() {
		return { StatusCode = '200 OK', FileContent = '' };
	}
}
