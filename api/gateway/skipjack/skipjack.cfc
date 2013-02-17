<!---
	$Id$

	Copyright 2008 Mark Mazelin (http://www.mkville.com/)

	Licensed under the Apache License, Version 2.0 (the "License"); you
	may not use this file except in compliance with the License. You may
	obtain a copy of the License at:

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
--->
<cfcomponent displayname="Base SkipJack Interface" extends="cfpayment.api.gateway.base" hint="Common functionality for SkipJack Gateway" output="false">

<!---
PROGRAM: skipjack.cfc
UPDATES:
	22-JAN-2009-MBM: added len() check on ParsedResult.szAuthorizationDeclinedMessage in ParseAuthorizeMessage()
	30-JAN-2009-MBM: added logic to MapGenericResponse() to find AuditId in response query and set response.TransactionId with the value (used for credit/newcharge items)
					 removed isValidCVV and isValidAVS checks in ParseAuthorizeMessage() since we don't pass in the validity options
	13-JAN-2011-MBM: change live url to use www instead of ms
--->
	<cfset variables.cfpayment.GATEWAY_NAME = "SkipJack" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.1" />
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "https://www.skipjackic.com/scripts/EvolvCC.dll?" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = "https://developer.skipjackic.com/scripts/EvolvCC.dll?" />
	<!--- gateway-specific variables --->
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD = StructNew() />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["authorize"] = "AuthorizeAPI" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["credit"] = "SJAPI_TransactionChangeStatusRequest" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["newcharge"] = "SJAPI_TransactionChangeStatusRequest" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["void"] = "SJAPI_TransactionChangeStatusRequest" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["capture"] = "SJAPI_TransactionChangeStatusRequest" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["status"] = "SJAPI_TransactionStatusRequest" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["recurring_add"] = "SJAPI_RecurringPaymentAdd" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["recurring_edit"] = "SJAPI_RecurringPaymentEdit" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["recurring_delete"] = "SJAPI_RecurringPaymentDelete" />
	<cfset variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD["recurring_get"] = "SJAPI_RecurringPaymentRequest" />

	<cfset variables.cfpayment.PERIODICITY_MAP["weekly"] = "0" /><!--- starting date + 7 days --->
	<cfset variables.cfpayment.PERIODICITY_MAP["biweekly"] = "1" /><!--- starting date + 14 days --->
	<cfset variables.cfpayment.PERIODICITY_MAP["semimonthly"] = "2" /><!--- Starting date + 15 days --->
	<cfset variables.cfpayment.PERIODICITY_MAP["monthly"] = "3" /><!--- Every month --->
	<cfset variables.cfpayment.PERIODICITY_MAP["quadweekly"] = "4" /><!--- Every fourth week --->
	<cfset variables.cfpayment.PERIODICITY_MAP["bimonthly"] = "5" /><!--- Every other month --->
	<cfset variables.cfpayment.PERIODICITY_MAP["quarterly"] = "6" /><!--- Every third month --->
	<cfset variables.cfpayment.PERIODICITY_MAP["semiyearly"] = "7" /><!--- Twice a year --->
	<cfset variables.cfpayment.PERIODICITY_MAP["yearly"] = "8" /><!--- Once a year --->
	<!--- not supported: daily --->

	<cfset variables.cfpayment.GatewayAction = "" />

	<!--- CONSTANTS --->
	<cfset variables.cfpayment.SKIPJACK_ORDER_STRING_DUMMY_VALUES = "1~None~0.00~0~N~||" />
	<cfset variables.cfpayment.SKIPJACK_ADD_RECURRING_RESPONSE_COLUMN_HEADERS = ListToArray("SerialNumber,ResponseCode,NumberOfRecords,RecurringPaymentId,OrderNumber,zReserved1,zReserved2,zReserved3,zReserved4,zReserved5,zReserved6,zReserved7") />
	<cfset variables.cfpayment.SKIPJACK_EDIT_RECURRING_RESPONSE_COLUMN_HEADERS = ListToArray("SerialNumber,ResponseCode,zReserved1,zReserved2,zReserved3,zReserved4,zReserved5,zReserved6,zReserved7,zReserved8,zReserved9,zReserved10") />
	<cfset variables.cfpayment.SKIPJACK_DELETE_RECURRING_RESPONSE_COLUMN_HEADERS = ListToArray("SerialNumber,ResponseCode,zReserved1,zReserved2,zReserved3,zReserved4,zReserved5,zReserved6,zReserved7,zReserved8,zReserved9,zReserved10") />
	<cfset variables.cfpayment.SKIPJACK_GET_RECURRING_RESPONSE_COLUMN_HEADERS = ListToArray("SerialNumber,ResponseCode,NumberOfRecords,zReserved1,zReserved2,zReserved3,zReserved4,zReserved5,zReserved6,zReserved7,zReserved8,zReserved9") />
	<!--- don't make these an array b/c we need them as a plain string list --->
	<cfset variables.cfpayment.SKIPJACK_GET_RECURRING_RESPONSE_DATA_COLUMN_HEADERS = "SerialNumber,DeveloperSerialNumber,RecurringPaymentId,CustomerName,PaymentFrequency,RecurringAmount,TransactionDate,TotalTransactions,RemainingTransactions,Email,Address1,Address2,Address3,Address4,City,State,PostalCode,Country,Phone,Fax,AccountNumber,ExpMonth,ExpYear,ItemNumber,ItemDescription,Comment,OrderNumber" />
	<cfset variables.cfpayment.SKIPJACK_CHANGE_STATUS_RESPONSE_COLUMN_HEADERS = ListToArray("SerialNumber,ResponseCode,NumberOfRecords,zReserved1,zReserved2,zReserved3,zReserved4,zReserved5,zReserved6,zReserved7,zReserved8,zReserved9") />
	<!--- don't make these an array b/c we need them as a plain string list --->
	<cfset variables.cfpayment.SKIPJACK_CHANGE_STATUS_RESPONSE_DATA_COLUMN_HEADERS = "SerialNumber,TransactionAmount,DesiredStatus,StatusResponse,StatusResponseMessage,OrderNumber,AuditID" />
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_STATUS_RESPONSE_COLUMN_HEADERS = ListToArray("SerialNumber,ResponseCode,NumberOfRecords,zReserved1,zReserved2,zReserved3,zReserved4,zReserved5,zReserved6,zReserved7,zReserved8,zReserved9") />
	<!--- don't make these an array b/c we need them as a plain string list --->
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_STATUS_RESPONSE_DATA_COLUMN_HEADERS = "SerialNumber,TransactionAmount,TransactionStatusCode,TransactionStatusMessage,OrderNumber,TransactionDateTime,TransactionID,ApprovalCode,BatchNumber" />

	<!---
	___SCENARIOS___ (from SkipJack_Integration_Guide.pdf, pp 70-79)
	* APPROVED:      szReturnCode = 1,   szIsApproved = 1,     szAuthorizationResponseCode = 6 digit code, AuthCode = 6 digit code
	* DECLINED:      szReturnCode = 1,   szIsApproved = 0,     szAuthorizationResponseCode = empty,        AuthCode = empty
	* NOT PROCESSED: szReturnCode = -35, szIsApproved = empty, szAuthorizationResponseCode = empty,        AuthCode = empty
	* APPROVED:      szReturnCode = 1,   szIsApproved = 1,     szAuthorizationResponseCode = 6 digit code, AuthCode = 6 digit code, szAVSResponseCode = X (full AVS match, but AVS filtering off)
	* APPROVED:      szReturnCode = 1,   szIsApproved = 1,     szAuthorizationResponseCode = 6 digit code, AuthCode = 6 digit code, szAVSResponseCode = P (partial AVS match, SkipJack AVS filtering threshold not breached)
	* DECLINED:      szReturnCode = 1,   szIsApproved = 0,     szAuthorizationResponseCode = 6 digit code, AuthCode = 6 digit code, szAVSResponseCode = P (partial AVS match, SkipJack AVS filtering reached therefore declined)
	* APPROVED:      szReturnCode = 1,   szIsApproved = 1,     szAuthorizationResponseCode = 6 digit code, AuthCode = 6 digit code, szCVV2ResponseCode = M (CVV Match)
	* DECLINED:      szReturnCode = 1,   szIsApproved = 0,     szAuthorizationResponseCode = empty,        AuthCode = empty,        szCVV2ResponseCode = N (CVV No Match - VISA and MasterCard)
	* APPROVED:      szReturnCode = 1,   szIsApproved = 1,     szAuthorizationResponseCode = 6 digit code, AuthCode = 6 digit code, szCVV2ResponseCode = empty (AMEX or Discover check the CVV but do not return a CVV response code, but this passed the CVV check b/c the transaction was not declined)
	* DECLINED:      szReturnCode = 1,   szIsApproved = 0,     szAuthorizationResponseCode = empty,        AuthCode = empty,        szCVV2ResponseCode = empty (AMEX or Discover check the CVV but do not return a CVV response code, but this failed the CVV check b/c the transaction was declined)

	__EXAMPLE DECLINED MESSAGES__
	Fail Amount : Authorization failed, card declined.
	Fail AVS	: ? not sure
	Fail CVV	: CVV2 Value supplied is invalid
	Fail CCNum	: Invalid credit card number
	--->
	<!--- return codes --->
	<cfset variables.cfpayment.SKIPJACK_SUCCESS_MESSAGE = "The transaction was successful.">

    <cfset variables.cfpayment.SKIPJACK_CHANGE_STATUS_SETTLE="SETTLE">
    <cfset variables.cfpayment.SKIPJACK_CHANGE_STATUS_DELETE="DELETE">
    <cfset variables.cfpayment.SKIPJACK_CHANGE_STATUS_CREDIT="CREDIT">
    <cfset variables.cfpayment.SKIPJACK_CHANGE_STATUS_NEWCHARGE="AUTHORIZEADDITIONAL">

	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS=StructNew()>
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["0"]="Idle">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["1"]="Authorized">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["2"]="Denied">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["3"]="Settled">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["4"]="Credited">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["5"]="Deleted">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["6"]="Archived">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["7"]="Pre-Authorized">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_CURRENT_STATUS["8"]="Split Settled">

	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_PENDING_STATUS=StructNew()>
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_PENDING_STATUS["0"]="Idle">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_PENDING_STATUS["1"]="Pending Credit">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_PENDING_STATUS["2"]="Pending Settlement">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_PENDING_STATUS["3"]="Pending Authorization">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_PENDING_STATUS["4"]="Pending Manual Settlement">
	<cfset variables.cfpayment.SKIPJACK_TRANSACTION_PENDING_STATUS["5"]="Pending Recurring">

	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES=StructNew()>
<!--- 	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-1"]="Error in request"> --->
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["0"]="Communication failure">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["1"]="Success">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-1"]="Invalid Command">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-2"]="Parameter Missing">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-3"]="Failed retrieving response">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-4"]="Invalid Status">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-5"]="Failed reading security flags">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-6"]="Developer serial number not found">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-7"]="Invalid Serial Number">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-11"]="Failed Adding Recurring Payment">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-12"]="Invalid Recurring Payment Frequency">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-13"]="Failed Delete of Recurring Payment">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-14"]="Failed Edit of Recurring Payment">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-15"]="Failure (Close Current Open Batch)">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-35"]="Invalid credit card number">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-37"]="Merchant processor unavailable">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-39"]="Length or value of HTML Serial Number">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-51"]="Length or value of zip code">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-52"]="Length or value in shipto zip code">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-53"]="Length or value in expiration date">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-54"]="Length or value of month or year of credit card account number">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-55"]="Length or value in streetaddress">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-56"]="Length or value in shiptoaddress">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-57"]="Length or value in transactionamount">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-58"]="Length or value in merchant name">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-59"]="Length or value in merchant address">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-60"]="Length or value in merchant state">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-61"]="Error length or value in shipto state">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-62"]="Error length or value in order string">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-64"]="Error empty phone number">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-65"]="Error empty sjname">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-66"]="Error empty e-mail">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-67"]="Error empty street address">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-68"]="Error empty city">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-69"]="Error empty state">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-70"]="Error empty zipcode">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-71"]="Empty ordernumber">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-72"]="Empty accountnumber">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-73"]="Empty month">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-74"]="Empty year">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-75"]="Empty serialnumber">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-76"]="Empty transactionamount">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-77"]="Empty orderstring">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-78"]="Empty shiptophone">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-79"]="Length or value sjname">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-80"]="Length shipto name">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-81"]="Length or value customer location">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-82"]="Length or value state">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-83"]="Length or value shiptophone">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-84"]="Duplicate ordernumber"><!--- only returned when reject dup trans is enabled --->
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-85"]="Airline leg info invalid Airline leg field value is invalid or empty.">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-86"]="Airline ticket info invalid Airline ticket info field is invalid or empty">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-87"]="Point of Sale check routing number must be 9 numeric digits Point of Sale check routing number is invalid or empty.">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-88"]="Point of Sale check account number missing or invalid Point of Sale check account number is invalid or empty.">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-89"]="Point of Sale check MICR missing or invalid Point of Sale check MICR invalid or empty.">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-90"]="Point of Sale check number missing or invalid Point of Sale check number invalid or empty.">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-91"]="Security Number invalid or empty">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-92"]="Approval code invalid">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-93"]="Blind credits request refused">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-94"]="Blind credits failed">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-95"]="Voice authorization request refused">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-96"]="Voice authorizations failed">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-97"]="Fraud rejection">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-98"]="Invalid discount amount">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-99"]="POS PIN Debit Pin Block Debit-specific">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-100"]="POS PIN Debit Invalid Key Serial Number Debit-specific">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-101"]="Invalid authentication data">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-102"]="Authentication data not allowed">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-103"]="POS Check Invalid Birth Date POS check dateofbirth variable contains a birth date in an incorrect format. Use MM/DD/YYYY format for this variable.">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-104"]="POS Check Invalid Identification Type POS check identificationtype variable contains a identification type value which is invalid. Use the single digit value where Social Security Number=1, Drivers License=2 for this variable.">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-105"]="Invalid trackdata">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-106"]="POS Check Invalid Account Type">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-107"]="POS PIN Debit Invalid Sequence Number">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-108"]="Invalid transaction ID">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-109"]="Invalid from account type">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-110"]="Pos Error Invalid To Account Type">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-112"]="Pos Error Invalid Auth Option">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-113"]="Pos Error Transaction Failed">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-114"]="Pos Error Invalid Incoming Eci">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-115"]="POS Check Invalid Check Type">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-116"]="POS Check Invalid Lane Number POS Check lane or cash register number is invalid. Use a valid lane or cash register number that has been configured in the Skipjack Merchant Account.">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-117"]="POS Check Invalid Cashier Number">
	<cfset variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES["-503"]="Request timed out">

	<cffunction name="init" output="false" access="public" returntype="any" hint="">
		<cfset super.init(argumentCollection=arguments)>
		<cfset variables.cfpayment.csvutils=CreateObject("component", "cfpayment.api.utils.csvutils")>
		<cfreturn this />
	</cffunction>

	<!--- shared process wrapper with gateway/transaction error handling --->
	<cffunction name="process" output="false" access="private" returntype="any">
		<cfargument name="payload" type="struct" required="true" />

		<cfset var response = "" />

		<!--- send it over the wire using the base gateway --->
		<cfset response = createResponse(argumentCollection = super.process(argumentCollection = arguments)) />

		<!--- we do some meta-checks for gateway-level errors (as opposed to auth/decline errors) --->
		<cfif NOT response.hasError()>

			<!--- we need to have a result we can parse; otherwise that's an error in itself --->
			<cfif len(response.getResult())>
				<!--- parse response results --->
				<cfset ParseResponse(response)>
			<cfelse>
				<!--- this is bad, because SkipJack didn't return a result --->
				<cfset response.setStatus(getService().getStatusUnknown()) />
			</cfif>
		</cfif>
		<!--- <cfdump var="#response.getMemento()#" label="response"><cfabort> --->
		<cfreturn response />
	</cffunction>

	<cffunction name="getGatewayAction" access="public" output="false" returntype="string">
		<cfargument name="shortaction" type="boolean" default="true"/>
		<!--- some processing (e.g. recurring) adds a mode to the end; normally return the action without the mode --->
		<cfif arguments.shortaction>
			<cfreturn ListFirst(variables.cfpayment.gatewayAction, "_") />
		<cfelse>
			<cfreturn variables.cfpayment.gatewayAction />
		</cfif>
	</cffunction>
	<cffunction name="setGatewayAction" access="public" output="false" returntype="void">
		<cfset variables.cfpayment.gatewayAction = arguments[1] />
	</cffunction>

	<!--- override getGatewayURL to inject the extra URL method per gateway method  --->
	<cffunction name="getGatewayURL" access="public" output="false" returntype="any" hint="">
		<cfset var gatewayURL=super.getGatewayURL()>
		<cfif structKeyExists(variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD, getGatewayAction(shortaction=false))>
			<cfset gatewayURL=gatewayURL & variables.cfpayment.SKIPJACK_GATEWAY_URL_METHOD[getGatewayAction(shortaction=false)]>
		<cfelse>
			<cfthrow message="Invalid GatewayAction Specified" type="cfpayment.InvalidParameter.GatewayAction" />
		</cfif>
		<cfreturn gatewayURL>
	</cffunction>


<!---

PARSE RESPONSE

--->
<cffunction name="ParseResponse" output="false" access="private" returntype="void" hint="">
	<cfargument name="Response" type="any" required="true"/>
	<cfset var ResponseMap="">
	<cfif ListFindNoCase("authorize", getGatewayAction())>
		<cfset ResponseMap=ParseAuthorizeResponse(argumentCollection=arguments)>
		<cfset arguments.Response.setAuthorization(ResponseMap.AuthCode)>
		<cfif structKeyExists(ResponseMap, "szTransactionFileName")>
			<cfset arguments.Response.setTransactionId(ResponseMap.szTransactionFileName)>
		<cfelseif structKeyExists(ResponseMap, "szTransactionId")>
			<cfset arguments.Response.setTransactionId(ResponseMap.szTransactionId)>
		</cfif>
		<!--- Skipjack will often return a zero AVS Response Code when the CVV fails, so we check for it and ignore it since it is an invalid value --->
		<cfif trim(ResponseMap.szAVSResponseCode) NEQ "0">
			<cfset arguments.Response.setAVSCode(ResponseMap.szAVSResponseCode)>
		</cfif>
		<cfset arguments.Response.setCVVCode(ResponseMap.szCVV2ResponseCode)>
	<cfelseif ListFindNoCase("recurring", getGatewayAction())>
		<cfif ListLast(getGatewayAction(shortaction=false), "_") eq "get">
			<cfset ResponseMap=ParseGetRecurringResponse(argumentCollection=arguments)>
		<cfelse>
			<cfset ResponseMap=ParseRecurringResponse(argumentCollection=arguments)>
			<cfif structKeyExists(ResponseMap, "RecurringPaymentId")>
				<cfset arguments.Response.setTransactionId(ResponseMap.RecurringPaymentId)>
			</cfif>
		</cfif>
	<cfelseif ListFindNoCase("capture,credit,void,newcharge", getGatewayAction())>
		<cfset ResponseMap=ParseChangeStatusResponse(argumentCollection=arguments)>
	<cfelseif ListFindNoCase("status", getGatewayAction())>
		<cfset ResponseMap=ParseGetTransactionStatusResponse(argumentCollection=arguments)>
	<cfelse>
		<!--- comment out cfdump for production --->
		<!--- <cfsavecontent variable="tmp"><cfdump var="#arguments.Response.getResult()#"></cfsavecontent> --->
		<cfthrow message="Invalid Logic to ParseResponse for #getGatewayAction()#" type="cfpayment.InvalidParameter.skipjack.GatewayAction" detail="#tmp#">
	</cfif>
	<!--- save the parsed result --->
	<cfset arguments.Response.setParsedResult(duplicate(ResponseMap))>
	<!--- set the status based on the success factor --->
	<cfif isStruct(ResponseMap) AND StructKeyExists(ResponseMap, "success") AND ResponseMap.success>
		<cfset arguments.Response.setStatus(getService().getStatusSuccessful())>
	<cfelse>
		<cfif arguments.Response.getStatus() EQ getService().getStatusPending()>
			<cfset arguments.Response.setStatus(getService().getStatusUnknown())>
		</cfif>
	</cfif>
	<!--- now parse any messages we need to return --->
	<cfset ParseMessage(arguments.response)>
</cffunction>

<cffunction name="ParseMessage" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true"/>
	<cfset var ParsedResult=arguments.Response.getParsedResult()>
	<cfset var message="">
	<cfif ListFindNoCase("authorize", getGatewayAction())>
		<cfset message=ParseAuthorizeMessage(arguments.response)>
	<cfelse>
		<!--- generic message handling --->
		<cfif len(arguments.Response.getMessage())>
			<!--- don't change the message if it's already set (e.g. line 2 of response) --->
			<cfreturn>
		</cfif>
		<cfif arguments.Response.getSuccess()>
			<cfset message=variables.cfpayment.SKIPJACK_SUCCESS_MESSAGE>
			<cfset arguments.Response.setStatus(getService().getStatusSuccessful())>
		<cfelseif StructKeyExists(ParsedResult, "ResponseCode") AND (ParsedResult.ResponseCode)>
			<cfif structKeyExists(variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES, ParsedResult.ResponseCode)>
				<cfset message=variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES[ParsedResult.ResponseCode]>
			<cfelse>
				<cfset message="Unknown Gateway ResponseCode">
			</cfif>
			<cfset arguments.Response.setStatus(getService().getStatusFailure())>
			<!--- <cfthrow message="Invalid Logic to ParseMessage for #getGatewayAction()#" type="cfpayment.InvalidParameter.skipjack.GatewayAction"> --->
		<cfelse>
			<cfif structKeyExists(ParsedResult, "szAuthorizationDeclinedMessage") and (len(ParsedResult.szAuthorizationDeclinedMessage))>
				<cfset message=ParsedResult.szAuthorizationDeclinedMessage>
			<cfelse>
				<!--- <cfsavecontent variable="tmp"><cfdump var="#arguments.response.getMemento()#" label="response"></cfsavecontent><cfthrow detail="#tmp#"> --->
				<cfset message="Unknown Gateway Failure">
			</cfif>
		</cfif>
	</cfif>
	<cfset arguments.Response.setMessage(message)>
</cffunction>

<!---

AUTHORIZE

--->
<cffunction name="ParseAuthorizeResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true"/>
	<cfset var ResponseMap=MapAuthorizeResponse(arguments.response)>
	<cfset ResponseMap["success"]=StructKeyExists(ResponseMap, "szIsApproved") and (ResponseMap.szIsApproved EQ "1")>
	<!--- <cfdump var="#ResponseMap#" label="ResponseMap"><cfabort> --->
	<cfreturn ResponseMap />
</cffunction>

<cffunction name="MapAuthorizeResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true"/>
	<cfset var lines=SplitLines(arguments.Response.getResult())>
	<cfset var keys="">
	<cfset var values="">
	<cfset var ctr=0>
	<cfset var res=StructNew()>
	<cfif ArrayLen(lines) NEQ 2>
		<cfthrow message="Invalid Authorize Response Result" type="cfpayment.skipjack.InvalidResponseResult">
	</cfif>
 	<cfset keys=SplitLine(lines[1])>
	<cfset values=SplitLine(lines[2])>
	<cfloop from="1" to="#ArrayLen(keys)#" index="ctr">
		<cfset res[keys[ctr]]=values[ctr]>
	</cfloop>
	<!--- <cfdump var="#lines#" label="lines"><cfdump var="#keys#" label="keys"><cfdump var="#values#" label="values"><cfdump var="#res#" label="res"><cfabort> --->
	<cfreturn res />
</cffunction>

<cffunction name="ParseAuthorizeMessage" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true"/>
	<cfset var ret="">
	<cfset var ParsedResult=arguments.Response.getParsedResult()>
	<cfif arguments.Response.getSuccess()>
		<cfset ret=variables.cfpayment.SKIPJACK_SUCCESS_MESSAGE>
		<cfset arguments.Response.setStatus(getService().getStatusSuccessful())>
	<!--- give error message priority to the szAuthorizationDeclinedMessage returned from skipjack --->
	<cfelseif StructKeyExists(ParsedResult, "szAuthorizationDeclinedMessage") and (len(ParsedResult.szAuthorizationDeclinedMessage))>
		<cfset ret=ParsedResult.szAuthorizationDeclinedMessage>
		<cfset arguments.Response.setStatus(getService().getStatusFailure())>
<!--- 	<cfelseif not arguments.Response.isValidCVV(AllowBlankCode=true)><!--- TODO: should these extra "allow" arguments be configurable --->
		<cfset ret="Security Code Error: " & arguments.Response.getCVVMessage()>
		<cfset arguments.Response.setStatus(getService().getStatusFailure())>
	<cfelseif not arguments.Response.isValidAVS(AllowStreetOnlyMatch=true)><!--- TODO: should these extra "allow" arguments be configurable --->
		<cfset ret="Address Verification Error: " & arguments.Response.getAVSMessage()>
		<cfset arguments.Response.setStatus(getService().getStatusFailure())> --->
	<cfelseif ParsedResult.szReturnCode>
		<cfset ret=variables.cfpayment.SKIPJACK_RETURN_CODE_MESSAGES[ParsedResult.szReturnCode]>
		<cfset arguments.Response.setStatus(getService().getStatusFailure())>
	<cfelse>
		<cfset ret=ParsedResult.szAuthorizationDeclinedMessage>
	</cfif>
	<cfreturn ret>
</cffunction>

<!---

RECURRING

--->
<cffunction name="ParseRecurringResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true"/>
	<cfset var ResponseMap=MapRecurringResponse(arguments.response)>
	<cfif arguments.response.getStatus() EQ getService().getStatusPending()>
		<cfset ResponseMap["success"]=StructKeyExists(ResponseMap, "ResponseCode") and (ResponseMap.ResponseCode EQ "0")>
	<cfelse>
		<cfset ResponseMap["success"]=false>
	</cfif>
	<cfreturn ResponseMap />
</cffunction>

<cffunction name="MapRecurringResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true"/>
	<cfset var lines=SplitLines(arguments.Response.getResult())>
	<cfset var keys="">
	<cfset var values="">
	<cfset var ctr=0>
	<cfset var numKeys=0>
	<cfset var numValues=0>
	<cfset var res=StructNew()>
	<cfif ArrayLen(lines) GTE 1 AND ArrayLen(lines) LTE 2>
	 	<cfset keys=variables.cfpayment.SKIPJACK_ADD_RECURRING_RESPONSE_COLUMN_HEADERS>
		<cfset values=SplitLine(lines[1])>
		<cfset numKeys=ArrayLen(keys)>
		<cfset numValues=ArrayLen(values)>
		<cfif numKeys eq numValues>
			<cfloop from="1" to="#numKeys#" index="ctr">
				<cfset res[keys[ctr]]=values[ctr]>
			</cfloop>
		<cfelse>
			<cfthrow message="Invalid Recurring Response Result (keys/values)" type="cfpayment.skipjack.InvalidResponseResult">
		</cfif>
		<cfif ArrayLen(lines) EQ 2>
			<!--- extra message on line two --->
			<cfset arguments.response.setMessage(lines[2])>
			<cfset arguments.Response.setStatus(getService().getStatusFailure())>
		</cfif>
	<cfelse>
		<!--- <cfsavecontent variable="tmp"><cfdump var="#lines#" label="lines"><cfdump var="#keys#" label="keys"><cfdump var="#values#" label="values"></cfsavecontent>
		<cfthrow message="Invalid Recurring Response Result" type="cfpayment.skipjack.InvalidResponseResult" detail="#tmp#"> --->
		<cfthrow message="Invalid Recurring Response Result" type="cfpayment.skipjack.InvalidResponseResult">
	</cfif>
	<!--- <cfdump var="#lines#" label="lines"><cfdump var="#keys#" label="keys"><cfdump var="#values#" label="values"> --->
	<cfreturn res />
</cffunction>

<!---
GET RECURRING
--->
<cffunction name="ParseGetRecurringResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true" />
	<cfreturn MapGenericDataResponse(
				arguments.response,
				variables.cfpayment.SKIPJACK_GET_RECURRING_RESPONSE_COLUMN_HEADERS,
				variables.cfpayment.SKIPJACK_GET_RECURRING_RESPONSE_DATA_COLUMN_HEADERS
				) />
</cffunction>

<!---
GET CHANGE_STATUS
--->
<cffunction name="ParseChangeStatusResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true" />
	<cfset var StatusResponseList="">
	<cfset var ResponseMap=MapGenericDataResponse(
				arguments.response,
				variables.cfpayment.SKIPJACK_CHANGE_STATUS_RESPONSE_COLUMN_HEADERS,
				variables.cfpayment.SKIPJACK_CHANGE_STATUS_RESPONSE_DATA_COLUMN_HEADERS
				) />
	<!--- do further processing to check for individual failures --->
	<cfif ResponseMap["success"]>
		<cfif structKeyExists(ResponseMap, "ResultDataQuery") and isQuery(ResponseMap.ResultDataQuery)>
			<cfset StatusResponseList=ValueList(ResponseMap.ResultDataQuery.StatusResponse)>
			<cfif ListFindNoCase(StatusResponseList, "UNSUCCESSFUL") OR ListFindNoCase(StatusResponseList, "NOT ALLOWED")>
				<cfset ResponseMap["success"]=false>
				<cfset arguments.Response.setMessage("The transaction succeeded, but one or more individual items failed.")>
				<cfset arguments.Response.setStatus(getService().getStatusDeclined())>
			</cfif>
		</cfif>
	</cfif>
	<cfreturn ResponseMap />
</cffunction>

<!---
GET TRANSACTION STATUS
--->
<cffunction name="ParseGetTransactionStatusResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true" />
	<cfreturn MapGenericDataResponse(
				arguments.response,
				variables.cfpayment.SKIPJACK_TRANSACTION_STATUS_RESPONSE_COLUMN_HEADERS,
				variables.cfpayment.SKIPJACK_TRANSACTION_STATUS_RESPONSE_DATA_COLUMN_HEADERS
				) />
</cffunction>

<!---

GENERIC RESPONSE DATA MAPPERS

--->
<!--- the error message is actually on a second line, separated by chr(10)+chr(13)
FROM: Skipjack Integration Guide.pdf, pp 87-97
1. Status Record (Header Record) is the first record returned and contains information about the
subsequent records.
  1 - HTML Serial Number
  2 - Error Code
      Response Error Code indicating success or error conditions.
		 0 = Success
		-1 = Invalid Command
		-2 = Parameter Missing
		-3 = Failed retrieving response
		-4 = Invalid Status
		-5 = Failed reading security flags
		-6 = Developer serial number not found
		-7 = Invalid Serial Number
  3 - Number of records in the response

2. Response Record (Data Record) is the second and subsequent record(s) returned for
successful transactions (szErrorCode=0) and includes transaction information described in
the table below.
An Error Record is returned as the third record only when an error condition exists
(szErrorCode != 0). An Error Record contains a brief text description of the transaction error.

"123123123123","-6","","","","","","","","","",""
Developer serialnumber doesn't match account.

"123123123123","-2","","","","","","","","","",""
Parameter Missing: (szDeveloperSerialNumber)

**This is a successful, non-error return (for get transaction response):
"123123123123","0","1","","","","","","","","",""
"123123123123","100.0000","30","Settled","987987987987","08/22/07 23:55:15","11223344556677.103","123456","456456456456"
--->
<cffunction name="MapGenericDataResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true" />
	<cfargument name="ResponseColumnHeaders" type="any" required="true" />
	<cfargument name="DataColumnHeaders" type="any" required="true" />
	<cfset var ResponseMap=MapGenericResponse(argumentCollection = arguments) />
	<cfif arguments.response.getStatus() EQ getService().getStatusPending()>
		<cfset ResponseMap["success"]=StructKeyExists(ResponseMap, "ResponseCode") and (ResponseMap.ResponseCode EQ "0")>
	<cfelse>
		<cfset ResponseMap["success"]=false>
	</cfif>
	<cfreturn ResponseMap />
</cffunction>

<cffunction name="MapGenericResponse" output="false" access="private" returntype="any" hint="">
	<cfargument name="Response" type="any" required="true"/>
	<cfargument name="ResponseColumnHeaders" type="any" required="true" />
	<cfargument name="DataColumnHeaders" type="any" required="true" />
	<cfset var lines=SplitLines(arguments.Response.getResult())>
	<cfset var keys="">
	<cfset var values="">
	<cfset var ctr=0>
	<cfset var numKeys=0>
	<cfset var numValues=0>
	<cfset var res=StructNew()>
	<cfset var dataArray="">
	<cfset var dataList="">
	<cfif ArrayLen(lines) GTE 1>
	 	<cfset keys=arguments.ResponseColumnHeaders>
		<cfset values=SplitLine(lines[1])>
		<cfset numKeys=ArrayLen(keys)>
		<cfset numValues=ArrayLen(values)>
		<cfif numKeys eq numValues>
			<cfloop from="1" to="#numKeys#" index="ctr">
				<cfset res[keys[ctr]]=values[ctr]>
			</cfloop>
		<cfelse>
			<cfthrow message="Invalid Response Result (keys/values=#numKeys#/#numValues#)" detail="#lines.toString()#" type="cfpayment.skipjack.InvalidResponseResult">
		</cfif>
		<cfif StructKeyExists(res, "NumberOfRecords") and (isNumeric(res.NumberOfRecords)) and (res.NumberOfRecords GT 0)>
			<!--- successful return: map out returned data records --->
			<!--- save to the result structure --->
			<cfset dataArray=duplicate(lines)>
			<!--- remove the first line from the lines array --->
			<cfset ArrayDeleteAt(dataArray, 1)>
			<!--- append the column names as the first row --->
 			<cfset ArrayPrepend(dataArray, arguments.DataColumnHeaders)>
			<!--- convert to a list for passing to CSVtoQuery function --->
			<cfset dataList=ArrayToList(dataArray, chr(10))>
			<!--- convert to a query --->
			<!--- <cfsavecontent variable="tmp"><cfdump var="#variables.cfpayment.csvutils.CSVtoQuery(CSV=dataList, FirstRowColumnNames=true, trim=true, trimData=true)#"></cfsavecontent><cfthrow message="Invalid Response Result (keys/values)" type="cfpayment.skipjack.InvalidResponseResult" detail="#tmp#"> --->
			<cfset res.ResultDataQuery=variables.cfpayment.csvutils.CSVtoQuery(CSV=dataList, FirstRowColumnNames=true, trim=true, trimData=true)>
			<cfset res.ResultDataArray=duplicate(dataArray)>
			<!--- if the result of this request returns a single record, see if there is an audit id; if so, set the response transaction id value to it (e.g. during a credit/newcharge call) --->
			<cfif (res.ResultDataQuery.RecordCount EQ 1)>
				<!--- change status request returns AuditId --->
				<cfif ListFindNoCase(res.ResultDataQuery.ColumnList, "AuditID") AND len(res.ResultDataQuery.AuditID)>
				<cfset arguments.Response.setTransactionId(res.ResultDataQuery.AuditID)>
				<!--- get trans status request returns TransactionId --->
				<cfelseif ListFindNoCase(res.ResultDataQuery.ColumnList, "TransactionID") AND len(res.ResultDataQuery.TransactionID)>
					<cfset arguments.Response.setTransactionId(res.ResultDataQuery.TransactionID)>
				</cfif>
			</cfif>
		<cfelseif StructKeyExists(res, "ResponseCode") and (res.ResponseCode NEQ "0") AND (ArrayLen(lines) EQ 2)>
			<!--- extra message on line two --->
			<cfset arguments.response.setMessage(lines[2])>
			<cfset arguments.Response.setStatus(getService().getStatusFailure())>
		</cfif>
	<cfelse>
		<cfthrow message="Invalid Response Result" type="cfpayment.skipjack.InvalidResponseResult">
	</cfif>
	<!--- <cfdump var="#lines#" label="lines"><cfdump var="#keys#" label="keys"><cfdump var="#values#" label="values"> --->
	<cfreturn res />
</cffunction>

<!---

HELPER FUNCTIONS

--->
<cffunction name="SplitLines" output="false" access="private" returntype="any" hint="Split result lines on carriage return/line feed character. Returns an array of strings.">
	<cfargument name="lines" type="string" required="true"/>
	<!--- normalize EOL character --->
	<cfset var modlines=replace(replace(arguments.lines, "#chr(13)##chr(10)#", chr(10), "ALL"), chr(13), chr(10), "ALL")>
	<!--- <cfreturn javacast("string", arguments.lines).split("\n")> ---><!--- \r\n --->
	<cfreturn ListToArray(arguments.lines, chr(10))><!--- \r\n --->
</cffunction>

<cffunction name="SplitLine" output="false" access="private" returntype="any" hint="Split a csv line on double-quote and commas. Returns an array of strings.">
	<cfargument name="line" type="string" required="true"/>
	<cfset var modline=javacast("string", arguments.line).trim()>
	<cfset var lineLen=ListLen(modline)>
	<!--- change delimiter to char 9 --->
	<cfset modline=modline.replace(""",""", chr(9))>
	<!--- remove beginning and ending double-quotes --->
	<cfset modline=modline.substring(1, modline.length()-1)>
	<!--- split on the char 9 and return (use lineLen to include possible trailing empty values) --->
	<cfreturn modline.split(chr(9), lineLen)>
</cffunction>

</cfcomponent>