<cfscript>
	gwParams = {};
	gwParams.Path = "goemerchant.goemerchant";

	// except for password values must be entered here
	gwParams.MerchantAccount = "";
	gwParams.userName = ""; // GEM transcenter ID
	gwParams.password = ""; // not used

	gwParams.mid = ""; //found in test mode virtual terminal - unique to your account
	gwParams.tid = ""; //found in test mode virtual terminal - unique to your account

	svc = createObject("cfpayment.api.core");
	svc.init(gwParams);

	account = svc.createCreditCard();
	account.setAccount(4111111111111111);
	account.setMonth(10);
	account.setYear(21);
	account.setVerificationValue();
	account.setFirstName("John");
	account.setLastName("Doe");
	account.setAddress("888");
	account.setPostalCode("77777");
	gw = svc.getGateway();
	money = svc.createMoney();
	errors=ArrayNew(1);
	money.init(100); //in cents
	options = {};
	options.order_id = "1234ORDER#dateFormat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmssL')#";

	//Authorize - Test AVS

	for(variables.cents = 100; variables.cents <= 190; variables.cents += 5)
	{
		options.order_id = "1234ORDER#dateFormat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmssL')#";
		money.setCents(variables.cents); // goEMerchant uses specific dollar amounts for test cases
		gemResponse = gw.authorize(money, account, options);

		writeOutput("Authorize - Test AVS<br />");
		writeOutput('<div style="font-family:Courier;">');
		writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
		writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
		writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
		writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
		writeOutput('CVV Rsp&nbsp; : (#account.getVerificationValue()#) - #gemResponse.getCVVCode()# - #gemResponse.getCVVMessage()#<br />');
		writeOutput('AVS Rsp&nbsp; : #gemResponse.getAVSCode()# - #gemResponse.getAVSMessage()#<br />');
		writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');
		getPageContext().getOut().flush();
	}

	// Void - Success expected

	gemResponse = gw.void(gemResponse.getTransactionID(), options);

	writeOutput("Void - Success expected<br />");
	writeOutput('<div style="font-family:Courier;">');
	writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
	writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
	writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
	writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
	writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');

	// Purchase

	options.order_id = "1234ORDER#dateFormat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmssL')#";
	money.setCents(100); // goEMerchant uses specific dollar amounts for test cases
	gemResponse = gw.purchase(money, account, options);
	account.setVerificationValue();

	writeOutput("Purchase<br />");
	writeOutput('<div style="font-family:Courier;">');
	writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
	writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
	writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
	writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
	writeOutput('CVV Rsp&nbsp; : (#account.getVerificationValue()#) - #gemResponse.getCVVCode()# - #gemResponse.getCVVMessage()#<br />');
	writeOutput('AVS Rsp&nbsp; : #gemResponse.getAVSCode()# - #gemResponse.getAVSMessage()#<br />');
	writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');

	// Credit - Failure expected

	gemResponse = gw.credit(money, gemResponse.getTransactionID(), options);

	writeOutput("Credit - Failure expected - you can only credit a transaction that has been through the nightly batch settlement.<br />");
	writeOutput('<div style="font-family:Courier;">');
	writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
	writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
	writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
	writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
	writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');

	//Authorize - Test CVV

	variables.cvvList = "123,456,789,012,345";
	money.setCents(195); // goEMerchant uses specific dollar amounts for test cases

	for(variables.cvv = 1; variables.cvv < 6; variables.cvv++)
	{
		account.setVerificationValue(listGetAt(variables.cvvList, variables.cvv));
		options.order_id = "1234ORDER#dateFormat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmssL')#";
		gemResponse = gw.authorize(money, account, options);

		writeOutput("Authorize - Test CVV<br />");
		writeOutput('<div style="font-family:Courier;">');
		writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
		writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
		writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
		writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
		writeOutput('CVV Rsp&nbsp; : (#account.getVerificationValue()#) - #gemResponse.getCVVCode()# - #gemResponse.getCVVMessage()#<br />');
		writeOutput('AVS Rsp&nbsp; : #gemResponse.getAVSCode()# - #gemResponse.getAVSMessage()#<br />');
		writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');
		getPageContext().getOut().flush();
	}

	// Settle (capture) - Success expected

	account.setVerificationValue();
	gemResponse = gw.capture(money, gemResponse.getTransactionID(), options);

	writeOutput("Settle (capture) - Success expected<br />");
	writeOutput('<div style="font-family:Courier;">');
	writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
	writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
	writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
	writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
	writeOutput('CVV Rsp&nbsp; : (#account.getVerificationValue()#) - #gemResponse.getCVVCode()# - #gemResponse.getCVVMessage()#<br />');
	writeOutput('AVS Rsp&nbsp; : #gemResponse.getAVSCode()# - #gemResponse.getAVSMessage()#<br />');
	writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');

	//Authorize - Test Decline

	for(variables.cents = 200; variables.cents <= 454; variables.cents++) // there are some gaps that are not specific errors but you will get a decline
	{
		options.order_id = "1234ORDER#dateFormat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmssL')#";
		money.setCents(variables.cents); // goEMerchant uses specific dollar amounts for test cases
		gemResponse = gw.authorize(money, account, options);

		writeOutput("Authorize - Test Decline<br />");
		writeOutput('<div style="font-family:Courier;">');
		writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
		writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
		writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
		writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
		writeOutput('CVV Rsp&nbsp; : (#account.getVerificationValue()#) - #gemResponse.getCVVCode()# - #gemResponse.getCVVMessage()#<br />');
		writeOutput('AVS Rsp&nbsp; : #gemResponse.getAVSCode()# - #gemResponse.getAVSMessage()#<br />');
		writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');
		getPageContext().getOut().flush();
	}

	options.order_id = "1234ORDER#dateFormat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmssL')#";
	money.setCents(493); // goEMerchant uses specific dollar amounts for test cases
	gemResponse = gw.authorize(money, account, options);

	writeOutput("Authorize - Test Decline<br />");
	writeOutput('<div style="font-family:Courier;">');
	writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
	writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
	writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
	writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
	writeOutput('CVV Rsp&nbsp; : (#account.getVerificationValue()#) - #gemResponse.getCVVCode()# - #gemResponse.getCVVMessage()#<br />');
	writeOutput('AVS Rsp&nbsp; : #gemResponse.getAVSCode()# - #gemResponse.getAVSMessage()#<br />');
	writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');

	options.order_id = "1234ORDER#dateFormat(now(), 'yyyymmdd')##timeformat(now(), 'HHmmssL')#";
	money.setCents(999); // goEMerchant uses specific dollar amounts for test cases
	gemResponse = gw.authorize(money, account, options);

	writeOutput("Authorize - Test Decline<br />");
	writeOutput('<div style="font-family:Courier;">');
	writeOutput('Amount&nbsp;&nbsp; : #money.getAmount()#<br />');
	writeOutput('Status&nbsp;&nbsp; : #gemResponse.getStatus()#<br />');
	writeOutput('TransID&nbsp; : #gemResponse.getTransactionID()#<br />');
	writeOutput('TokenID&nbsp; : #gemResponse.getTokenID()#<br />');
	writeOutput('CVV Rsp&nbsp; : (#account.getVerificationValue()#) - #gemResponse.getCVVCode()# - #gemResponse.getCVVMessage()#<br />');
	writeOutput('AVS Rsp&nbsp; : #gemResponse.getAVSCode()# - #gemResponse.getAVSMessage()#<br />');
	writeOutput('Auth Rsp : #gemResponse.getMessage()#<p />');

	writeOutput('</div>');

</cfscript>

