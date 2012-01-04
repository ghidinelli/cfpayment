<cfcomponent name="CoreTest" extends="mxunit.framework.TestCase" output="false">

	<cffunction name="setUp" returntype="void" access="public" output="false">	

		<cfset var gw = structNew() />

		<cfscript>  
			variables.svc = createObject("component", "cfpayment.api.core");
			
			gw.path = "bogus.unittest";
			gw.GatewayID = 1;
			gw.MerchantAccount = 101010101;
			gw.Username = 'test';
			gw.Password = 'test';
			
			variables.svc.init(gw);
			
		</cfscript>
	</cffunction>


	<cffunction name="dohttpcall_fails_with_array_payload" access="public" mxunit:expectedException="cfpayment.InvalidParameter.Payload" output="false">
		<cfset var gw = variables.svc.getGateway() />
		<cfset var options = structNew() />
		<cfset options["invalidType"] = arrayNew(1) />
		
		<cfset makePublic(gw, "doHttpCall") />
		
		<!--- passing array as options will generate an exception, trapped by mxunit:ExpectedException --->
		<cfset response = gw.doHttpCall(url = '', method = 'get', timeout = 30, headers = structNew(), payload = options) />
	</cffunction>


	<cffunction name="dohttpcall_fails_without_get_or_post" access="public" mxunit:expectedException="cfpayment.InvalidParameter.Method" output="false">
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "doHttpCall") />
		
		<!--- passing something other than get/post generates exception, trapped by mxunit:ExpectedException --->
		<cfset response = gw.doHttpCall(url = '', method = 'put', timeout = 30, headers = structNew(), payload = structNew()) />
	</cffunction>
	
	
	<cffunction name="process_cfhttp_broken" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_return_broken_cfhttp_response", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusUnknown(), "Status should be unknown because cfhttp contains no keys") />
	</cffunction>


	<cffunction name="process_cfhttp_undefined" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_return_void", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset debug(response.getMemento()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusUnknown(), "Status should be unknown because cfhttp is undefined") />
	</cffunction>


	<cffunction name="process_http_status_code_200_ok" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_http_success", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusPending(), "Status should be pending (not subsequently modified by an error state)") />
		<cfset assertTrue(response.getResult() EQ "<test />", "The result should only include our mocked </test>") />
	</cffunction>

	<cffunction name="process_http_status_code_404" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_http_404", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusFailure(), "Status should be failure for 404") />
	</cffunction>

	<cffunction name="process_empty_http_status_code" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_http_empty_status_code", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusUnknown(), "Unknown HTTP status code so unknown payment status, was: #response.getStatus()#") />
	</cffunction>

	<cffunction name="process_httpfailure" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_error_httpfailure", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusFailure(), "Status should be failure for unsuccessfully reaching gateway") />
	</cffunction>
	
	<cffunction name="process_requesttimeout" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_error_requesttimeout", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusTimeout(), "Status should be timeout") />
	</cffunction>

	<cffunction name="process_http_status_code_302" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_http_302", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusFailure(), "Status should be failure for 302 permanently moved (CF won't follow this, so it's like a 404)") />
	</cffunction>

	<cffunction name="process_http_status_code_503" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_http_503", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusFailure(), "Status should be failure for service unavailable (HTTP 503)") />
	</cffunction>

	<cffunction name="process_http_status_code_500" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_http_500", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusUnknown(), "Status should be unknown for a 500 server error (we don't know if the transaction finished or not)") />
	</cffunction>

	<cffunction name="process_error_unknown" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "mock_error_unknown", "doHttpCall") />
		
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<cfset assertTrue(response.getStatus() EQ variables.svc.getStatusUnknown(), "Status should be unknown for an unknown failure cause (we don't know if the transaction finished or not)") />
	</cffunction>


	<!--- test RequestTimeOut manipulation --->
	<cffunction name="manipulate_timeout" access="public" output="false">
		<cfset var response = "" />
		<cfset var gw = variables.svc.getGateway() />

		<cfset makePublic(gw, "getCurrentRequestTimeout") />
		<cfset makePublic(gw, "process") />
		<cfset injectMethod(gw, this, "dohttp_check_requesttimeout", "doHttpCall") /><!--- makes doHttpCall return the current timeout for verification --->
	
		<cfset assertTrue(gw.getTimeout() EQ 300, "Baseline cfpayment timeout is 300 seconds or 5 minutes") />
		<!--- this may vary based upon your environment and CF version! --->
		<cfset assertTrue(gw.getCurrentRequestTimeout() NEQ 0, "Default page timeout is: #gw.getCurrentRequestTimeout()#, 0 means your system doesn't support determining this dynamically; try CF8?") />
		
		<cfset gw.setTimeout(5) />
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<!--- the getResult() is set to the timeout value because of our mock function for doHttpCall --->
		<cfset assertTrue(response.getResult() EQ gw.getCurrentRequestTimeout(), "When page timeout > cfpayment timeout, result should be = page timeout; was: #response.getResult()#") />

		<cfset gw.setTimeout(500) />
		<cfset response = gw.process(method = 'post', payload = structNew()) />
		<!--- the getResult() is set to the timeout value because of our mock function for doHttpCall --->
		<cfset assertTrue(response.getResult() EQ 510, "When page timeout < cfpayment timeout, result should be = cfpayment timeout + 10 seconds; was: #response.getResult()#") />

	</cffunction>
	
	
	<cffunction name="check_setters" output="false" access="public" returntype="any">
		<cfset var gw = variables.svc.getGateway() />
		<cfset makePublic(gw, "getUsername") />
		<cfset makePublic(gw, "getPassword") />

		<cfset assertTrue(gw.getGatewayID() EQ 1, "The value should have been 1, was: #gw.getGatewayID()#") />
		<cfset assertTrue(gw.getGatewayName() EQ "Bogus Gateway", "The value should have been 'Base Gateway'") />
		<cfset assertTrue(gw.getGatewayVersion() EQ "1.1", "The value should have been 1.0") />
		<cfset assertTrue(gw.getUsername() EQ "test", "The value should have been test") />
		<cfset assertTrue(gw.getPassword() EQ "test", "The value should have been test") />
		<!--- no setter available for gateway url - needed?  probably not, should be hardcoded by gateway developer --->
		<cfset assertTrue(gw.getGatewayURL() EQ "http://localhost/", "The value should have been http://localhost/") />
	</cffunction>


	<cffunction name="test_verifyRequiredOptions_pass" output="false" access="public" returntype="any">
		<cfset var gw = variables.svc.getGateway() />
		<cfset var res = "" />
		<cfset var options = {id = 1, name = 'test' } />
		<cfset makePublic(gw, "verifyRequiredOptions") />
		<cfset res = gw.verifyRequiredOptions(options, "id,name") />
	</cffunction>


	<cffunction name="test_verifyRequiredOptions_error" output="false" access="public" returntype="any" mxunit:expectedException="cfpayment.MissingParameter.Option">
		<cfset var gw = variables.svc.getGateway() />
		<cfset var res = "" />
		<cfset var options = {id = 1 } />
		<cfset makePublic(gw, "verifyRequiredOptions") />
		<cfset res = gw.verifyRequiredOptions(options, "id,name") />
	</cffunction>

 
	<cffunction name="undefined_purchase" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().purchase(money = '', account = '') />
	</cffunction>
	<cffunction name="undefined_authorize" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().authorize(money = '', account = '') />
	</cffunction>
	<cffunction name="undefined_capture" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().capture(money = '', authorization = '') />
	</cffunction>
	<cffunction name="undefined_credit" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().credit(money = '', transactionid = '') />
	</cffunction>
	<cffunction name="undefined_void" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().void(transactionid = '') />
	</cffunction>
	<cffunction name="undefined_search" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().search(options = structNew()) />
	</cffunction>
	<cffunction name="undefined_status" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().status(transactionid = '') />
	</cffunction>
	<cffunction name="undefined_recurring" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().recurring(mode = '', money = '', account = '', options = structNew()) />
	</cffunction>
	<cffunction name="undefined_settle" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().settle() />
	</cffunction>
	<cffunction name="undefined_supports" access="public" mxunit:expectedException="cfpayment.MethodNotImplemented" output="false">
		<cfset variables.svc.getGateway().supports(type = '') />
	</cffunction>








	<!--- MOCKS AND SUPPORTING FUNCTIONS --->

	<cffunction name="mock_http_success" output="false" access="private" returntype="any">
		<cfset var res = {fileContent = '<test />', statusCode = '200 OK', errorDetail = 'Unit Test errorDetail Value' } />
		<cfreturn res />
	</cffunction>
	<cffunction name="mock_http_404" output="false" access="private" returntype="any">
		<cfset var res = {fileContent = '', statusCode = '404 Not Found', errorDetail = 'Unit Test errorDetail Value' } />
		<cfreturn res />
	</cffunction>
	<cffunction name="mock_http_302" access="private" output="false">
		<cfset var res = {fileContent = '', statusCode = '302 Moved Temporarily', errorDetail = 'Unit Test errorDetail Value' } />
		<cfreturn res />
	</cffunction>
	<cffunction name="mock_http_503" access="private" output="false">
		<cfset var res = {fileContent = '', statusCode = '503 Service Unavailable', errorDetail = 'Unit Test errorDetail Value' } />
		<cfreturn res />
	</cffunction>
	<cffunction name="mock_http_500" access="private" output="false">
		<cfset var res = {fileContent = '', statusCode = '500 Server Error', errorDetail = 'Unit Test errorDetail Value' } />
		<cfreturn res />
	</cffunction>
	<cffunction name="mock_http_empty_status_code" output="false" access="private" returntype="any">
		<cfset var res = {fileContent = '', statusCode = '', errorDetail = 'Unit Test errorDetail Value' } />
		<cfreturn res />
	</cffunction>
	<cffunction name="mock_return_broken_cfhttp_response" output="false" access="private" returntype="any">
		<cfreturn structNew() />
	</cffunction>
	<cffunction name="mock_return_void" output="false" access="private" returntype="void">
		<cfset var foo = false />
	</cffunction>


	
	<cffunction name="mock_error_httpfailure" access="private" output="false">
		<cfthrow type="COM.Allaire.ColdFusion.HTTPFailure" message="COM.Allaire.ColdFusion.HTTPFailure" detail="Unit Test Exception" />
	</cffunction>
	<cffunction name="mock_error_requesttimeout" access="private" output="false">
		<cfthrow type="coldfusion.runtime.RequestTimedOutException" message="coldfusion.runtime.RequestTimedOutException" detail="Unit Test Exception" />
	</cffunction>
	<cffunction name="mock_error_unknown" access="private" output="false">
		<cfthrow type="COM.Allaire.ColdFusion.SomeOtherError" message="COM.Allaire.ColdFusion.SomeOtherError" detail="Unit Test Exception" />
	</cffunction>


	<cffunction name="dohttp_check_requesttimeout" output="false" access="private" returntype="any">
		<!--- for testing purposes, we shoehorn the request timeout after process() sets it into the result value so we can test in our assertion --->
		<cfset var timeout = createObject("java", "coldfusion.runtime.RequestMonitor").getRequestTimeout() />
		<cfset var res = {fileContent = timeout, statusCode = '200 OK', errorDetail = 'Unit Test errorDetail Value' } />
		<cfreturn res />
	</cffunction>

</cfcomponent>
