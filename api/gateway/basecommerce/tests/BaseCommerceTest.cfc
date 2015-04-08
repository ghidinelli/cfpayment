component
	displayname='BaseCommerce Tests'
	output=false
	extends='mxunit.framework.TestCase' {

	public void function setUp() {
		local.gw.path = 'basecommerce.basecommerce';
		//Test account
		local.gw.Username = '';
		local.gw.Password = '';
		local.gw.MerchantAccount = '';
		local.gw.TestMode = true;

		// create gw and get reference			
		variables.svc = createObject('component', 'cfpayment.api.core').init(local.gw);
		variables.gw = variables.svc.getGateway();

		//if set to false, will try to connect to remote service to check these all out
		variables.localMode = true;
		variables.debugMode = false;
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
		if(arguments.response.hasError()) {
			if(arrayLen(arguments.response.getMessage())) {
				assertTrue(false, 'Message returned from BaseCommerce: <br />#arrayToList(arguments.response.getMessage(), "<br />")#');
			} else {
				assertTrue(false, 'Error found but no error message attached');
			}
		}
		if(isSimpleValue(arguments.response.getParsedResult())) assertTrue(false, 'Parsed response is a string, expected a structure. Returned string = "#arguments.response.getParsedResult()#"');
		assertTrue(isStruct(arguments.response.getParsedResult()), 'Parsed response is not a structure');
		assertFalse(structIsEmpty(arguments.response.getParsedResult()), 'Parsed response structure is empty');
		assertTrue(arguments.response.getSuccess(), 'Success flag indicates failure');
	}

	private void function standardErrorResponseTests(required any response) {
		if(variables.debugMode) {
			debug(arguments.response.haserror());
			debug(arguments.response.getMessage());
		}
		if(isSimpleValue(arguments.response)) assertTrue(false, 'Response returned a simple value: "#arguments.response#"');
		assertTrue(isObject(arguments.response), 'Invalid: response is not an object');
		assertTrue(arguments.response.hasError(), 'No errors indicated in response');
		assertTrue(isSimpleValue(arguments.response.getMessage()), 'Error Message response not a string');
		assertTrue(len(arguments.response.getMessage()), 'No error messages available');
		assertFalse(arguments.response.getSuccess(), 'Success flag indicates success, but should indicate failure');
	}

	//TESTS
	public void function testCreateAccount() {
		createAccountTest();
	}

	public void function testCreditAccount() {
		local.accountToken = createAccountTest();

		//Credit account
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDate = dateAdd('d', 8, now());
		offlineInjector(variables.gw, this, 'mockCreditAccountOk', 'transactionData');
		local.credit = variables.gw.credit(money = variables.svc.createMoney(500, 'USD'), account = local.account, options = local.options);
		standardResponseTests(local.credit);
		assertTrue(local.credit.getParsedResult().amount == 5, 'The credit amount requested and the actual credit given is different, should be 5, is: #local.credit.getParsedResult().amount#');
		assertTrue(local.credit.getTransactionId() > 0, 'Invalid transaction id returned: #local.credit.getTransactionId()#');
		assertTrue(local.credit.getParsedResult().type == 'CREDIT', 'Incorrect transaction type, should be "CREDIT", is: "#local.credit.getParsedResult().type#"');
	}

	public void function testDebitAccount() {
		local.accountToken = createAccountTest();

		//Debit account
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		offlineInjector(variables.gw, this, 'mockDebitAccountOk', 'transactionData');
		local.debit = variables.gw.purchase(money = variables.svc.createMoney(400, 'USD'), account = local.account, options = local.options);
		standardResponseTests(local.debit);
		assertTrue(local.debit.getParsedResult().amount == 4, 'The credit amount requested and the actual credit given is different, should be 4, is: #local.debit.getParsedResult().amount#');
		assertTrue(local.debit.getTransactionId() > 0, 'Invalid transaction id returned: #local.debit.getTransactionId()#');
		assertTrue(local.debit.getParsedResult().type == 'DEBIT', 'Incorrect transaction type, should be "CREDIT", is: "#local.debit.getParsedResult().type#"');
	}

	public void function testCreateInvalidAccountFails() {
		local.argumentCollection = structNew();
		local.accountNumberString = '7';
		local.argumentCollection.account = createInvalidAccount(local.accountNumberString);
		offlineInjector(variables.gw, this, 'mockCreateInvalidAccountFails', 'accountData');
		local.accountToken = variables.gw.store(argumentCollection = local.argumentCollection);
		standardErrorResponseTests(local.accountToken);
		assertTrue(local.accountToken.getMessage() == 'Account Number must be at least 5 digits', 'Incorrect error message: "#local.accountToken.getMessage()#", expected: "Account Number must be at least 5 digits"');
	}

	public void function testCreateAccountWithInvalidRoutingNumberFails() {
		local.argumentCollection = structNew();
		local.accountRoutingNumberString = '123';
		local.argumentCollection.account = createAccountWithInvalidRoutingNumber(local.accountRoutingNumberString);
		offlineInjector(variables.gw, this, 'mockCreateAccountWithInvalidRoutingNumberFails', 'accountData');
		local.accountToken = variables.gw.store(argumentCollection = local.argumentCollection);
		standardErrorResponseTests(local.accountToken);
		assertTrue(local.accountToken.getMessage() == 'Invalid Routing Number', 'Incorrect error message: "#local.accountToken.getMessage()#", expected: "Invalid Routing Number"');
	}

	public void function testCreateAccountWithInvalidAccountTypeFails() mxunit:expectedException='BaseCommerce Type' {
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccountWithInvalidAccountType('XS_BA_TYPE_THISWILLFAIL');
		offlineInjector(variables.gw, this, 'mockCreateAccountWithInvalidAccountTypeFails', 'accountData');
		variables.gw.store(argumentCollection = local.argumentCollection);
	}

	public void function testCreateAccountWithMissingAccountTypeFails() mxunit:expectedException='BaseCommerce Type' {
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccountWithMissingAccountType();
		offlineInjector(variables.gw, this, 'mockCreateAccountWithMissingAccountTypeFails', 'accountData');
		variables.gw.store(argumentCollection = local.argumentCollection);
	}

	public void function testCreditAccountWithInvalidAmountFails() {
		local.accountToken = createAccountTest();

		//Credit account (unsuccessfully)
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		offlineInjector(variables.gw, this, 'mockCreditDebitAccountWithInvalidAmountFails', 'transactionData');
		local.credit = variables.gw.credit(money = variables.svc.createMoney(-1000, 'USD'), account = local.account, options = local.options);
		standardErrorResponseTests(local.credit);
		assertTrue(local.credit.getMessage() == 'Invalid Amount', 'Incorrect error message: "#local.credit.getMessage()#", expected: "Invalid Amount"');
	}

	public void function testDebitAccountWithInvalidAmountFails() {
		local.accountToken = createAccountTest();

		//Credit account (unsuccessfully)
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		offlineInjector(variables.gw, this, 'mockCreditDebitAccountWithInvalidAmountFails', 'transactionData');
		local.debit = variables.gw.credit(money = variables.svc.createMoney(-2, 'USD'), account = local.account, options = local.options);
		standardErrorResponseTests(local.debit);
		assertTrue(local.debit.getMessage() == 'Invalid Amount', 'Incorrect error message: "#local.debit.getMessage()#", expected: "Invalid Amount"');
	}

	public void function testCreditAccountWithInvalidAccountTokenFails() {
		local.account = variables.svc.createToken(id = 'lk1j43k324h32j4h32hk***FAKE***32j4h3k432kh43jkh');
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		offlineInjector(variables.gw, this, 'mockCreditAccountWithInvalidAccountTokenFails', 'transactionData');
		local.credit = variables.gw.credit(money = variables.svc.createMoney(-1000, 'USD'), account = local.account, options = local.options);
		standardErrorResponseTests(local.credit);
		assertTrue(local.credit.getMessage() == 'No bank account exists for given token', 'Incorrect error message: "#local.credit.getMessage()#", expected: "No bank account exists for given token"');
	}

	public void function testCreditAccountWithInvalidMethodFails() {
		local.accountToken = createAccountTest();

		//Credit account (unsuccessfully)
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.options = structNew();
		local.options.sec = 'THISWILLFAIL'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		offlineInjector(variables.gw, this, 'mockCreditAccountWithInvalidMethodFails', 'transactionData');
		local.credit = variables.gw.credit(money = variables.svc.createMoney(1500, 'USD'), account = local.account, options = local.options);
		standardErrorResponseTests(local.credit);
		assertTrue(local.credit.getMessage() == 'Invalid transaction method passed in: XS_BAT_METHOD_#local.options.sec#', 'Incorrect error message: "#local.credit.getMessage()#", expected: "Invalid transaction method passed in: #local.options.sec#"');
	}

	public void function testCreditAccountFutureEffectiveDate() {
		local.accountToken = createAccountTest();

		//Credit account
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.effectiveDate = dateAdd('d', 4, nextSaturday()); // Wednesday of next week
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDate = local.effectiveDate;
		offlineInjector(variables.gw, this, 'mockCreditAccountFutureEffectiveDate', 'transactionData');
		local.credit = variables.gw.credit(money = variables.svc.createMoney(500, 'USD'), account = local.account, options = local.options);
		standardResponseTests(local.credit);
		assertTrue(dateCompare(local.effectiveDate, local.credit.getParsedResult().effectiveDate) == 0, 'Posted effective date (#local.effectiveDate#) and confirmed effective date (#local.credit.getParsedResult().effectiveDate#) don''t match');
	}

	public void function testCreditAccountPastEffectiveDate() {
		local.accountToken = createAccountTest();

		//Credit account
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.effectiveDate = dateAdd('d', -4, removeTimePart(now())); //4 days ago
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDate = local.effectiveDate;
		offlineInjector(variables.gw, this, 'mockCreditAccountPastEffectiveDate', 'transactionData');
		local.credit = variables.gw.credit(money = variables.svc.createMoney(500, 'USD'), account = local.account, options = local.options);
		standardResponseTests(local.credit);
		assertTrue(dateCompare(local.effectiveDate, local.credit.getParsedResult().effectiveDate) < 0, 'Posted date is in the past, returned effective date should be ammended to curtrent date but isn''t');
	}

	public void function testCreditAccountWeekendEffectiveDateMovedToWeekDay() {
		local.accountToken = createAccountTest();

		//Credit account
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.effectiveDate = nextSaturday();
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDate = local.effectiveDate;
		offlineInjector(variables.gw, this, 'mockCreditAccountWeekendEffectiveDateMovedToWeekDay', 'transactionData');
		local.credit = variables.gw.credit(money = variables.svc.createMoney(500, 'USD'), account = local.account, options = local.options);
		standardResponseTests(local.credit);
		assertTrue(dateCompare(local.effectiveDate, local.credit.getParsedResult().effectiveDate) < 0, 'Posted date is on the weekend, returned effective date should be ammended to next working day but isn''t');
	}

	public void function testCreditAccountSettlementDateIsTheBusinessDayAfterEffectiveDay() {
		local.accountToken = createAccountTest();

		//Credit account
		local.account = variables.svc.createToken(id = local.accountToken.getTokenId());
		local.effectiveDate = dateAdd('d', 4, nextSaturday()); // Wednesday of next week
		local.options = structNew();
		local.options.sec = 'CCD'; //XS_BAT_METHOD_CCD, XS_BAT_METHOD_PPD, XS_BAT_METHOD_TEL, XS_BAT_METHOD_WEB
		local.options.effectiveDate = local.effectiveDate;
		offlineInjector(variables.gw, this, 'mockCreditAccountSettlementDateIsTheBusinessDayAfterEffectiveDay', 'transactionData');
		local.credit = variables.gw.credit(money = variables.svc.createMoney(500, 'USD'), account = local.account, options = local.options);
		standardResponseTests(local.credit);
		assertTrue(dateDiff('d', local.effectiveDate, local.credit.getParsedResult().settlementdate) == 1, 'The settlement date should be the next working day after the effective day');
	}

	//HELPERS
	private any function createAccountTest() {
		local.argumentCollection = structNew();
		local.argumentCollection.account = createAccount();
		offlineInjector(variables.gw, this, 'mockCreateAccountOk', 'accountData');
		local.accountToken = gw.store(argumentCollection = local.argumentCollection);
		standardResponseTests(local.accountToken);
		assertTrue(local.accountToken.getTokenId() != '', 'Token not returned');
		return local.accountToken;
	}

	private date function nextSaturday(date day=now()) {
		//Saturday is day 7, subtract today from that to receive next saturday's date
		arguments.day = dateAdd('d', 7-dayOfWeek(arguments.day), removeTimePart(arguments.day));
		return arguments.day;
	}

	private date function removeTimePart(date day=now()) {
		return createDate(year(arguments.day), month(arguments.day), day(arguments.day));
	}
	
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
		local.account.setAccountType('checking');
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
		return { "MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"April, 06 2015 00:00:00","TRANSACTIONID":44067,"ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":5.0,"STATUS":0,"SETTLEMENTDATE":"April, 07 2015 00:00:00","TYPE":"CREDIT" };
	}

	private any function mockCreateAccountOk() {
		return { status=0, tokenId = 'a347d5a9bc92015fe68871403775f012d204002f9f8419590d4363088376c20e', type = 'CHECKING'};
	}

	private any function mockDebitAccountOk() {
		return { "MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"April, 06 2015 00:00:00","TRANSACTIONID":44068,"ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":4.0,"STATUS":0,"SETTLEMENTDATE":"April, 07 2015 00:00:00","TYPE":"DEBIT" };
	}

	private any function mockCreateInvalidAccountFails() {
		return { Status = 3, message = ['Account Number must be at least 5 digits'] };
	}

	private any function mockCreateAccountWithInvalidRoutingNumberFails() {
		return { Status = 3, message = ['Invalid Routing Number'] };
	}

	private any function mockCreateAccountWithInvalidAccountTypeFails() {
		throw(type = 'BaseCommerce Type', message = 'Unknown Account Type: XS_BA_TYPE_THISWILLFAIL');
	}

	private any function mockCreateAccountWithMissingAccountTypeFails() {
		throw(type = 'BaseCommerce Type', message = 'Unknown Account Type: ');
	}

	private any function mockCreateAccountWithMissingAccountType() {
		return { Status = 3, message = ['Missing account type'] };
	}

	private any function mockCreditDebitAccountWithInvalidAmountFails() {
		return { Status = 3, message = ['Invalid Amount'] };
	}

	private any function mockCreditAccountWithInvalidAccountTokenFails() {
		return { Status = 3, message = ['No bank account exists for given token'] };
	}
	
	private any function mockCreditAccountWithInvalidMethodFails() {
		return { Status = 3, message = ['Invalid transaction method passed in: XS_BAT_METHOD_THISWILLFAIL'] };
	}

	private any function mockCreditAccountWithInvalideffectiveDateDaysFromNowFails() {
		return { Status = 3, message = ['Effective date (days from now) must be 0 or greater'] };
	}

	private any function mockCreditAccountSettlementDateIsTheBusinessDayAfterEffectiveDay() {
		local.nextSaturday = dateAdd('d', 7-dayOfWeek(now()), now());
		local.effectiveDate = dateFormat(dateAdd('d', 4, local.nextSaturday), 'Mmm, dd yyyy') & ' 00:00:00';
		local.settlementDate = dateFormat(dateAdd('d', 5, local.nextSaturday), 'Mmm, dd yyyy') & ' 00:00:00';
		return {"MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"#local.effectiveDate#","TRANSACTIONID":44102,"ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":5.0,"STATUS":0,"SETTLEMENTDATE":"#local.settlementDate#","TYPE":"CREDIT"};
	}

	private any function mockCreditAccountWeekendEffectiveDateMovedToWeekDay() {
		local.nextSaturday = dateAdd('d', 7-dayOfWeek(now()), now());
		local.effectiveDate = dateFormat(dateAdd('d', 2, local.nextSaturday), 'Mmm, dd yyyy') & ' 00:00:00';
		local.settlementDate = dateFormat(dateAdd('d', 3, local.nextSaturday), 'Mmm, dd yyyy') & ' 00:00:00';
		return {"MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"#local.effectiveDate#","TRANSACTIONID":44158,"ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":5.0,"STATUS":0,"SETTLEMENTDATE":"#local.settlementDate#","TYPE":"CREDIT"};
	}

	private any function mockCreditAccountPastEffectiveDate() {
		local.effectiveDate = dateFormat(now(), 'Mmm, dd yyyy') & ' 00:00:00';
		local.settlementDate = dateFormat(dateAdd('d', 1, now()), 'Mmm, dd yyyy') & ' 00:00:00';
		return {"MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"#local.effectiveDate#","TRANSACTIONID":44160,"ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":5.0,"STATUS":0,"SETTLEMENTDATE":"#local.settlementDate#","TYPE":"CREDIT"};
	}

	private any function mockCreditAccountFutureEffectiveDate() {
		local.nextSaturday = dateAdd('d', 7-dayOfWeek(now()), now());
		local.effectiveDate = dateFormat(dateAdd('d', 4, local.nextSaturday), 'Mmm, dd yyyy') & ' 00:00:00';
		local.settlementDate = dateFormat(dateAdd('d', 5, local.nextSaturday), 'Mmm, dd yyyy') & ' 00:00:00';
		return {"MERCHANTTRANSACTIONID":0,"EFFECTIVEDATE":"#local.effectiveDate#","TRANSACTIONID":44161,"ACCOUNTTYPE":"CHECKING","METHOD":"CCD","AMOUNT":5.0,"STATUS":0,"SETTLEMENTDATE":"#local.settlementDate#","TYPE":"CREDIT"};
	}
}
