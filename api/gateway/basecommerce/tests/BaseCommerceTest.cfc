component
	displayname='BaseCommerce Tests'
	output=false
	extends='mxunit.framework.TestCase' {

	public void function setUp() {
		var gw = structNew();

		gw.path = 'basecommerce.basecommerce';
		//Test account
		gw.Username = '';
		gw.Password = '';
		gw.MerchantAccount = '';
		gw.TestMode = true; // defaults to true anyways

		// create gw and get reference			
		variables.svc = createObject('component', 'cfpayment.api.core').init(gw);
		variables.gw = variables.svc.getGateway();

		//if set to false, will try to connect to remote service to check these all out
		variables.localMode = false;
		variables.debugMode = true;
	}

	private void function offlineInjector(required any receiver, required any giver, required string functionName, string functionNameInReceiver='') {
		if(variables.localMode) {
			injectMethod(arguments.receiver, arguments.giver, arguments.functionName, arguments.functionNameInReceiver);
		}
	}

	private void function standardResponseTests(required any response) {
		if(variables.debugMode) {
			debug(arguments.response.getParsedResult());
			debug(arguments.response.getResult());
		}
		if(isSimpleValue(arguments.response)) assertTrue(false, 'Response returned a simple value: "#arguments.response#"');
		assertTrue(isObject(arguments.response), 'Invalid: response is not an object');
		if(arguments.response.getStatusCode() != 200) {
			if(arguments.response.hasError()) {
				if(arrayLen(arguments.response.getMessage())) {
					assertTrue(false, 'Message returned from BaseCommerce: <br />#arrayToList(arguments.response.getMessage(), "<br />")#');
				} else {
					assertTrue(false, 'Error found but no error message attached');
				}
			}
			assertTrue(false, 'Status code should be 200, was: #arguments.response.getStatusCode()#');
		}
		if(isSimpleValue(arguments.response.getParsedResult())) assertTrue(false, 'Parsed response is a string, expected a structure. Returned string = "#arguments.response.getParsedResult()#"');
		assertTrue(isStruct(arguments.response.getParsedResult()), 'Parsed response is not a structure');
		assertFalse(structIsEmpty(arguments.response.getParsedResult()), 'Parsed response structure is empty');
	}

	private void function standardErrorResponseTests(required any response, required numeric expectedStatusCode) {
		if(variables.debugMode) {
			debug(arguments.expectedStatusCode);
			debug(arguments.response.haserror());
			debug(arguments.response.getMessage());
			debug(arguments.response.getStatusCode());
		}
		if(isSimpleValue(arguments.response)) assertTrue(false, 'Response returned a simple value: "#arguments.response#"');
		assertTrue(isObject(arguments.response), 'Invalid: response is not an object');
		assertTrue(arguments.response.getStatusCode() == arguments.expectedStatusCode, 'Status code should be #arguments.expectedStatusCode#, was: #arguments.response.getStatusCode()#');
		assertTrue(arguments.response.hasError(), 'No errors indicated in response');
		assertTrue(isSimpleValue(arguments.response.getMessage()), 'Error Message response not a string');
		assertTrue(len(arguments.response.getMessage()), 'No error messages available');
	}

	//TESTS
	public void function testCreateAccount() {
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Account';
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
		local.argumentCollection.options.name = 'Test Account';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid account status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');

		//Credit account
		local.options = structNew();
		local.options.tokenId = accountToken.getTokenId();
		local.options.method = 'XS_BAT_METHOD_CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDateDaysFromNow = 2;
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
		local.argumentCollection.options.name = 'Test Account';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect bank account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');

		//Debit account
		local.options = structNew();
		local.options.tokenId = accountToken.getTokenId();
		local.options.method = 'XS_BAT_METHOD_CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDateDaysFromNow = 0;
		offlineInjector(gw, this, 'mockDebitAccountOk', 'transactionData');
		debit = gw.purchase(money = variables.svc.createMoney(400, 'USD'), options = local.options);
		standardResponseTests(debit);
		assertTrue(debit.getParsedResult().accountType == 'CHECKING', 'Incorrect bank account type, should be "Checking", is: "#debit.getParsedResult().accountType#"');
		assertTrue(debit.getParsedResult().amount == 4, 'The credit amount requested and the actual credit given is different, should be 4, is: #debit.getParsedResult().amount#');
		assertTrue(debit.getTransactionId() > 0, 'Invalid transaction id returned: #debit.getTransactionId()#');
		assertTrue(debit.getParsedResult().Status == 'CREATED', 'Invalid transaction status: #debit.getParsedResult().Status#');
		assertTrue(debit.getParsedResult().type == 'DEBIT', 'Incorrect transaction type, should be "CREDIT", is: "#debit.getParsedResult().type#"');
	}

	public void function testCreateInvalidAccountFails() {
		local.argumentCollection = structNew();
		local.accountNumberString = '7';
		local.argumentCollection.account = createInvalidAccount(local.accountNumberString);
		local.argumentCollection.options.name = 'Test Invalid Account';
		offlineInjector(gw, this, 'mockCreateInvalidAccountFails', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardErrorResponseTests(accountToken, 400);
		assertTrue(accountToken.getMessage() == 'Account Number must be at least 5 digits', 'Incorrect error message: "#accountToken.getMessage()#", expected: "Account Number must be at least 5 digits"');
	}

	public void function testCreateAccountWithInvalidRoutingNumberFails() {
		local.argumentCollection = structNew();
		local.accountRoutingNumberString = '123';
		local.argumentCollection.account = createAccountWithInvalidRoutingNumber(local.accountRoutingNumberString);
		local.argumentCollection.options.name = 'Test Account With Invalid Routing Number';
		offlineInjector(gw, this, 'mockCreateAccountWithInvalidRoutingNumberFails', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardErrorResponseTests(accountToken, 400);
		assertTrue(accountToken.getMessage() == 'Invalid Routing Number', 'Incorrect error message: "#accountToken.getMessage()#", expected: "Invalid Routing Number"');
	}

	public void function testCreateAccountWithInvalidAccountTypeFails() {
		local.argumentCollection = structNew();
		local.accountTypeString = 'XS_BA_TYPE_THISWILLFAIL';
		local.argumentCollection.account = createAccountWithInvalidAccountType(local.accountTypeString);
		local.argumentCollection.options.name = 'Test Account With Invalid Account Type';
		offlineInjector(gw, this, 'mockCreateAccountWithInvalidAccountTypeFails', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardErrorResponseTests(accountToken, 400);
		assertTrue(accountToken.getMessage() == 'Invalid account type passed in: #local.accountTypeString#', 'Incorrect error message: "#accountToken.getMessage()#", expected: "Invalid account type passed in: #local.accountTypeString#"');
	}

	public void function testCreateAccountWithMissingAccountTypeFails() {
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccountWithMissingAccountType();
		local.argumentCollection.options.name = 'Test Account With Invalid Account Type';
		offlineInjector(gw, this, 'mockCreateAccountWithMissingAccountTypeFails', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardErrorResponseTests(accountToken, 400);
		assertTrue(accountToken.getMessage() == 'Missing account type', 'Incorrect error message: "#accountToken.getMessage()#", expected: "Missing account type"');
	}

	public void function testCreditAccountWithInvalidAmountFails() {
		//Create account (successfully)
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Account';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid account status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');

		//Credit account (unsuccessfully)
		local.options = structNew();
		local.options.tokenId = accountToken.getTokenId();
		local.options.method = 'XS_BAT_METHOD_CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDateDaysFromNow = 0;
		offlineInjector(gw, this, 'mockCreditDebitAccountWithInvalidAmountFails', 'transactionData');
		credit = gw.credit(money = variables.svc.createMoney(-1000, 'USD'), options = local.options);
		standardErrorResponseTests(credit, 400);
		assertTrue(credit.getMessage() == 'Invalid Amount', 'Incorrect error message: "#credit.getMessage()#", expected: "Invalid Amount"');
	}

	public void function testDebitAccountWithInvalidAmountFails() {
		//Create account (successfully)
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Account';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid account status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');

		//Credit account (unsuccessfully)
		local.options = structNew();
		local.options.tokenId = accountToken.getTokenId();
		local.options.method = 'XS_BAT_METHOD_CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDateDaysFromNow = 0;
		offlineInjector(gw, this, 'mockCreditDebitAccountWithInvalidAmountFails', 'transactionData');
		debit = gw.credit(money = variables.svc.createMoney(-2, 'USD'), options = local.options);
		standardErrorResponseTests(debit, 400);
		assertTrue(debit.getMessage() == 'Invalid Amount', 'Incorrect error message: "#debit.getMessage()#", expected: "Invalid Amount"');
	}

	public void function testCreditAccountWithInvalidAccountTokenFails() {
		local.options = structNew();
		local.options.tokenId = 'lk1j43k324h32j4h32hk***FAKE***32j4h3k432kh43jkh';
		local.options.method = 'XS_BAT_METHOD_CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDateDaysFromNow = 2;
		offlineInjector(gw, this, 'mockCreditAccountWithInvalidAccountTokenFails', 'transactionData');
		credit = gw.credit(money = variables.svc.createMoney(-1000, 'USD'), options = local.options);
		standardErrorResponseTests(credit, 400);
		assertTrue(credit.getMessage() == 'No bank account exists for given token', 'Incorrect error message: "#credit.getMessage()#", expected: "No bank account exists for given token"');
	}

	public void function testCreditAccountWithInvalidMethodFails() {
		//Create account (successfully)
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Account';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid account status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');

		//Credit account (unsuccessfully)
		local.options = structNew();
		local.options.tokenId = accountToken.getTokenId();
		local.options.method = 'XS_BAT_METHOD_THISWILLFAIL'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDateDaysFromNow = 0;
		offlineInjector(gw, this, 'mockCreditAccountWithInvalidMethodFails', 'transactionData');
		credit = gw.credit(money = variables.svc.createMoney(1500, 'USD'), options = local.options);
		standardErrorResponseTests(credit, 400);
		assertTrue(credit.getMessage() == 'Invalid transaction method passed in: #local.options.method#', 'Incorrect error message: "#credit.getMessage()#", expected: "Invalid transaction method passed in: #local.options.method#"');
	}

	public void function testCreditAccountWithInvalideffectiveDateDaysFromNowFails() {
		//Create account (successfully)
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		local.argumentCollection.options.name = 'Test Account';
		offlineInjector(gw, this, 'mockCreateAccountOk', 'accountData');
		accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(accountToken);
		assertTrue(accountToken.getParsedResult().Status == 'ACTIVE', 'Invalid account status: #accountToken.getParsedResult().Status#');
		assertTrue(accountToken.getParsedResult().type == 'CHECKING', 'Incorrect account type, should be "Checking", is: "#accountToken.getParsedResult().type#"');
		assertTrue(accountToken.getTokenId() != '', 'Token not returned');

		//Credit account (unsuccessfully)
		local.options = structNew();
		local.options.tokenId = accountToken.getTokenId();
		local.options.method = 'XS_BAT_METHOD_CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDate = createDate(2020, 1, 1);
		offlineInjector(gw, this, 'mockCreditAccountWithInvalideffectiveDateDaysFromNowFails', 'transactionData');
		credit = gw.credit(money = variables.svc.createMoney(700, 'USD'), options = local.options);
		standardErrorResponseTests(credit, 400);
		assertTrue(credit.getMessage() == 'Effective date (days from now) must be 0 or greater', 'Incorrect error message: "#credit.getMessage()#", expected: "Effective date (days from now) must be 0 or greater"');
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

	private any function createInvalidAccount(required string accountNumberString) {
		local.account = createAccount();
		local.account.setAccount(arguments.accountNumberString);
		return local.account;	
	}

	private any function createAccountWithInvalidRoutingNumber(required string accountRoutingNumberString) {
		local.account = createAccount();
		local.account.setRoutingNumber(arguments.accountRoutingNumberString);
		return local.account;	
	}

	private any function createAccountWithInvalidAccountType(required string accountTypeString) {
		local.account = createAccount();
		local.account.setAccountType(arguments.accountTypeString);
		return local.account;	
	}

	private any function createAccountWithMissingAccountType() {
		local.account = createAccount();
		local.account.setAccountType('');
		return local.account;	
	}

	//MOCKS
	private any function mockCreditAccountOk() {
		return { StatusCode = 200, transactionId = '43271', result = {"MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"April, 03 2015 00:00:00","ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":5.0,"STATUS":"CREATED","SETTLEMENTDATE":"April, 06 2015 00:00:00","TYPE":"CREDIT"} };
	}

	private any function mockCreateAccountOk() {
		return { statusCode = 200, tokenId = 'a347d5a9bc92015fe68871403775f012d204002f9f8419590d4363088376c20e', result = {"STATUS":"ACTIVE","TYPE":"CHECKING"} };
	}

	private any function mockDebitAccountOk() {
		return { StatusCode = 200, transactionId = '43275', result = {"MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"April, 03 2015 00:00:00","ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":4.0,"STATUS":"CREATED","SETTLEMENTDATE":"April, 06 2015 00:00:00","TYPE":"DEBIT"} };
	}

	private any function mockCreateInvalidAccountFails() {
		return { StatusCode = 400, Status = 3, message = ['Account Number must be at least 5 digits'] };
	}

	private any function mockCreateAccountWithInvalidRoutingNumberFails() {
		return { StatusCode = 400, Status = 3, message = ['Invalid Routing Number'] };
	}

	private any function mockCreateAccountWithInvalidAccountTypeFails() {
		return { StatusCode = 400, Status = 3, message = ['Invalid account type passed in: XS_BA_TYPE_THISWILLFAIL'] };
	}

	private any function mockCreateAccountWithMissingAccountTypeFails() {
		return { StatusCode = 400, Status = 3, message = ['Missing account type'] };
	}

	private any function mockCreateAccountWithMissingAccountType() {
		return { StatusCode = 400, Status = 3, message = ['Missing account type'] };
	}

	private any function mockCreditDebitAccountWithInvalidAmountFails() {
		return { StatusCode = 400, Status = 3, message = ['Invalid Amount'] };
	}

	private any function mockCreditAccountWithInvalidAccountTokenFails() {
		return { StatusCode = 400, Status = 3, message = ['No bank account exists for given token'] };
	}
	
	private any function mockCreditAccountWithInvalidMethodFails() {
		return { StatusCode = 400, Status = 3, message = ['Invalid transaction method passed in: XS_BAT_METHOD_THISWILLFAIL'] };
	}

	private any function mockCreditAccountWithInvalideffectiveDateDaysFromNowFails() {
		return { StatusCode = 400, Status = 3, message = ['Effective date (days from now) must be 0 or greater'] };
	}
}
