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

	UPDATES:
		 3-FEB-2009-MBM: added check for order_id and szNewOrderNumber to payload in newcharge() method
--->
<cfcomponent displayname="SkipJack Credit Card Object" extends="skipjack" hint="Used for processing credit card payments via SkipJack" output="false">

	<cffunction name="getIsCCEnabled" access="public" output="false" returntype="boolean">
		<cfreturn true />
	</cffunction>

	<!--- implement primary methods --->
	<cffunction name="authorize" output="false" access="public" returntype="any" hint="Perform an authorization immediately followed by a capture/settle">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" /><!--- credit card or eft object --->
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset var payload = StructNew() />
		<cfset setGatewayAction("authorize") />

		<!--- check for required options --->
		<cfset VerifyRequiredOptions(arguments.options, "email,order_id") />

		<!--- setup payload --->
		<cfset addInvoice(payload, arguments.options) />
		<cfset addCreditCard(payload, arguments.account) />
		<cfset addAddress(payload, arguments.options, arguments.account) />
		<cfset addCustomerData(payload, arguments.options) />
		<cfset addUserDefined(payload, arguments.options) />
		<cfset addMisc(payload, arguments.options) />
		<cfset addCredentials(payload, arguments.options) />
		<cfset addAmount(payload, arguments.money) />
		<cfreturn process(payload=payload, options=arguments.options) />
	</cffunction>

	<cffunction name="capture" access="public" output="false" returntype="any" hint="Confirms an authorization with direction to charge the account">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="authorization" type="any" required="true" />
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset var payload = StructNew() />
		<cfset setGatewayAction("capture") />

		<cfset addStatusAction(payload, variables.cfpayment.SKIPJACK_CHANGE_STATUS_SETTLE) />
		<cfset addForcedSettlement(payload, arguments.options) />
		<cfset addTransactionId(payload, arguments.authorization) />
		<cfset addCredentials(payload, arguments.options) />
		<cfset addAmount(payload, arguments.money) />

		<cfreturn process(payload=payload, options=arguments.options) />
	</cffunction>

	<cffunction name="credit" access="public" output="false" returntype="any" hint="Returns an amount back to the previously charged account.  Only for use with captured transactions.">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="identification" type="any" required="true" />
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset var payload = StructNew() />
		<cfset setGatewayAction("credit") />

		<cfset addStatusAction(payload, variables.cfpayment.SKIPJACK_CHANGE_STATUS_CREDIT) />
		<cfset addForcedSettlement(payload, arguments.options) />
		<cfset addTransactionId(payload, arguments.identification) />
		<cfset addCredentials(payload, arguments.options) />
		<cfset addAmount(payload, arguments.money) />

		<cfreturn process(payload=payload, options=arguments.options) />
	</cffunction>

	<cffunction name="newcharge" access="public" output="false" returntype="any" hint="">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="identification" type="any" required="true" />
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset var payload = StructNew() />
		<cfset setGatewayAction("newcharge") />

		<!--- check for required options --->
		<cfset VerifyRequiredOptions(arguments.options, "order_id") /><!--- if order_id not passed, it will default to "1", which is likely undesireable--->

		<cfset addInvoice(payload, arguments.options) />
		<cfset addStatusAction(payload, variables.cfpayment.SKIPJACK_CHANGE_STATUS_NEWCHARGE) />
		<cfset addForcedSettlement(payload, arguments.options) />
		<cfset addTransactionId(payload, arguments.identification) />
		<cfset addCredentials(payload, arguments.options) />
		<cfset addAmount(payload, arguments.money) />

		<cfreturn process(payload=payload, options=arguments.options) />
	</cffunction>

	<cffunction name="purchase" output="false" access="public" returntype="any" hint="Perform an authorization immediately followed by a capture/settle">
		<cfargument name="money" type="any" required="true" />
		<cfargument name="account" type="any" required="true" /><!--- credit card or eft object --->
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset var response = "" />

		<cfset response = authorize(argumentCollection=arguments) />

		<cfif response.getSuccess()>
			<cfset response = capture(arguments.money, response.getTransactionId(), arguments.options) />
		</cfif>

		<cfreturn response />
	</cffunction>

	<cffunction name="recurring" output="false" access="public" returntype="any" hint="Perform an add/edit recurring transaction">
		<cfargument name="mode" type="any" required="true" /><!--- must be one of: add, edit, delete, get --->
		<cfargument name="money" type="any" required="false" />
		<cfargument name="account" type="any" required="false" /><!--- credit card or eft object --->
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset var payload = StructNew() />
		<cfset setGatewayAction("recurring") />

		<!--- setup payload --->
		<cfif ListFindNoCase("add,edit", arguments.mode)>
			<cfif not StructKeyExists(arguments, "money")>
				<cfthrow message="Money is a required parameter." type="cfpayment.MissingParameter.Money">
			</cfif>
			<cfif not StructKeyExists(arguments, "account")>
				<cfthrow message="Account is a required parameter." type="cfpayment.MissingParameter.Account">
			</cfif>
			<!--- check for required options --->
			<cfset VerifyRequiredOptions(arguments.options, "email,order_id") />
			<!--- populate the payload --->
			<cfset addInvoice(payload, arguments.options) />
			<cfset addCreditCard(payload, arguments.account) />
			<cfset addAddress(payload, arguments.options, arguments.account) />
			<cfset addCustomerData(payload, arguments.options) />
			<cfset addUserDefined(payload, arguments.options) />
			<cfset addMisc(payload, arguments.options) />
			<cfset addCredentials(payload, arguments.options) />
			<cfset addAmount(payload, arguments.money) />
			<cfset addRecurringFields(payload, arguments.mode, arguments.options) />
		<cfelseif ListFindNoCase("delete,get", arguments.mode)>
			<!--- populate the payload --->
			<cfset addCredentials(payload, arguments.options) />
			<cfset addRecurringFields(payload, arguments.mode, arguments.options) />
		<cfelse>
			<cfthrow message="Invalid Recurring Mode Logic" type="cfpayment">
		</cfif>

		<!--- append the mode to the gateway action so we can get at the proper gateway url --->
		<cfset setGatewayAction("recurring_#arguments.mode#") />
		<cfreturn process(payload=payload, options=arguments.options) />
	</cffunction>

	<cffunction name="status" access="public" output="false" returntype="any" hint="Reconstruct a response object for a previously executed transaction">
		<cfargument name="transactionid" type="any" required="true" /><!--- in SkipJack, this is actually the application-generated unique order number --->
		<cfargument name="options" type="struct" required="false" />
		<cfset var payload = StructNew() />
		<cfset setGatewayAction("status") />

		<cfset payload["szOrderNumber"]=arguments.transactionid>
		<!--- also allow the transaction date to be passed in --->
		<cfif isDate(GetOption(arguments.options, "transaction_date"))>
			<!--- format should be mm/dd/yyyy --->
			<cfset payload["szDate"]=DateFormat(GetOption(arguments.options, "transaction_date"), "mm/dd/yyyy")>
		</cfif>
		<cfset addCredentials(payload, arguments.options) />
		<cfreturn process(payload=payload, options=arguments.options) />
	</cffunction>

	<cffunction name="void" access="public" output="false" returntype="any" hint="Cancels a previously captured transaction that has not yet settled">
		<cfargument name="authorization" type="any" required="true" />
		<cfargument name="options" type="struct" default="#StructNew()#" />
		<cfset var payload = StructNew() />
		<cfset setGatewayAction("void") />

		<cfset addStatusAction(payload, variables.cfpayment.SKIPJACK_CHANGE_STATUS_DELETE) />
		<cfset addForcedSettlement(payload, arguments.options) />
		<cfset addTransactionId(payload, arguments.authorization) />
		<cfset addCredentials(payload, arguments.options) />

		<cfreturn process(payload=payload, options=arguments.options) />
	</cffunction>


	<!---

		PRIVATE METHODS

	 --->
	<cffunction name="addInvoice" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="options" type="any" required="true"/>
		<cfset var ctr = 0 />
		<cfset var currOrder = "" />
		<cfset var orderStr = "" />
		<cfif ListFindNoCase("authorize", getGatewayAction())>
			<cfset arguments.payload["ordernumber"]=GetOption(arguments.options, "order_id") />
			<cfset arguments.payload["customercode"]=GetOption(arguments.options, "Customer") />
			<cfset arguments.payload["invoicenumber"]=GetOption(arguments.options, "Invoice") />
			<cfset arguments.payload["orderdescription"]=GetOption(arguments.options, "Description") />
			<cfif StructKeyExists(arguments.options, "Order")>
				<cfif isArray(arguments.options.order)>
					<!--- array of structs --->
					<cfset arguments.payload["orderstring"]="" />
					<cfloop from="1" to="#ArrayLen(arguments.options.order)#" index="ctr">
						<!---
							==Order Keys==
							* Required *
								SKU				(ItemNumber)
								Description		(ItemDescription)
								DeclaredValue	(ItemCost)
								Quantity
								Taxable (Y/N)
							* Optional *
								UnitOfMeasure
								ItemDiscount
								ExtendedAmount
								CommodityCode
								VatTaxAmount
								VatTaxRate
								AlternateTaxAmount
								TaxRate
								TaxType
								TaxAmount
						--->
						<cfset currOrder = arguments.options.order[ctr] />
						<cfif isStruct(currOrder)>
							<cftry>
								<cfset orderStr="">
								<cfset orderStr=ListAppend(orderStr, currOrder.sku, "~") />
								<cfset orderStr=ListAppend(orderStr, replace(currOrder.description, "~", "_", "ALL"), "~") />
								<cfset orderStr=ListAppend(orderStr, currOrder.declaredValue, "~") />
								<cfset orderStr=ListAppend(orderStr, currOrder.quantity, "~") />
								<cfset orderStr=ListAppend(orderStr, currOrder.taxable, "~") />
								<!--- <cfset orderStr=ListAppend(orderStr, currOrder.taxRate, "~")> --->
								<cfset arguments.payload["orderstring"]=ListAppend(arguments.payload["orderstring"], orderStr, "||") />
							<cfcatch>
								<cfthrow message="Invalid OrderStruct" type="cfpayment.InvalidParameter.OrderStruct" />
							</cfcatch>
							</cftry>
						<cfelse>
							<cfthrow message="Invalid OrderArray" type="cfpayment.InvalidParameter.OrderArray" />
						</cfif>
					</cfloop>
				<cfelse>
					<!--- simple string --->
					<cfset arguments.payload["orderstring"]=arguments.options.order />
				</cfif>
			<cfelse>
				<cfset arguments.payload["orderstring"]=variables.cfpayment.SKIPJACK_ORDER_STRING_DUMMY_VALUES />
			</cfif>
		<cfelseif ListFindNoCase("recurring", getGatewayAction())>
			<!--- required fields --->
			<cfset arguments.payload["rtOrderNumber"]=GetOption(arguments.options, "order_id") />
			<cfset arguments.payload["rtItemNumber"]=GetOption(arguments.options, "ItemNumber") />
			<cfset arguments.payload["rtItemDescription"]=GetOption(arguments.options, "ItemDescription") />
		<cfelseif ListFindNoCase("newcharge", getGatewayAction())>
			<cfset arguments.payload["szNewOrderNumber"]=GetOption(arguments.options, "order_id") />
		<cfelse>
			<cfthrow message="Invalid GatewayAction Logic in AddInvoice" type="cfpayment.InvalidParameter" />
		</cfif>
	</cffunction>

	<cffunction name="addAddress" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="options" type="any" required="true"/>
		<cfargument name="account" type="any" required="true"/>
		<cfset var address = "" />
		<cfset var billing_address = "" />
		<cfset var shipping_address = "" />
		<!---
		There are 3 different addresses you can use. There are billing_address, shipping_address, or you can
		just pass in address and it will be used for both. This is the common pattern to use for the address:

		if billing_address is passed, use that for billing_address, otherwise use address
		if shipping_address is passed, use that for shipping_address, otherwise use billing_address

		Address Structure - The address is a structure with the following keys:
		    * name
		    * company
		    * address1
		    * address2
		    * city
		    * state
		    * country
		    * postalcode
		    * phone
		--->
		<cfif StructKeyExists(arguments.options, "billing_address")>
			<cfset billing_address = arguments.options.billing_address />
		<cfelse>
			<cfif StructKeyExists(arguments.options, "address")>
				<cfset billing_address = arguments.options.address />
			<cfelse>
				<cfthrow message="Missing Address Structure" type="cfpayment.MissingParameter.Address" />
			</cfif>
		</cfif>

		<!--- note: name gets set in the addCreditCard() method --->
		<cfif getGatewayAction() eq "recurring">
			<cfset arguments.payload["rtAddress1"] = getOption(billing_address, "address1") />
			<cfset arguments.payload["rtAddress2"] = getOption(billing_address, "address2") />
			<cfset arguments.payload["rtCity"] = getOption(billing_address, "city") />
			<cfset arguments.payload["rtState"] = getOption(billing_address, "state") />
			<cfset arguments.payload["rtPostalcode"] = getOption(billing_address, "postalcode") />
			<cfset arguments.payload["rtCountry"] = getOption(billing_address, "country") />
			<cfset arguments.payload["rtPhone"] = getOption(billing_address, "phone") />
		<cfelse>
			<cfset arguments.payload["streetaddress"] = getOption(billing_address, "address1") />
			<cfset arguments.payload["streetaddress2"] = getOption(billing_address, "address2") />
			<cfset arguments.payload["city"] = getOption(billing_address, "city") />
			<cfset arguments.payload["state"] = getOption(billing_address, "state") />
			<cfset arguments.payload["zipcode"] = getOption(billing_address, "postalcode") />
			<cfset arguments.payload["country"] = getOption(billing_address, "country") />
			<cfset arguments.payload["phone"] = getOption(billing_address, "phone") />
			<cfif StructKeyExists(arguments.options, "shipping_address")>
				<cfset arguments.payload["shipToName"] = getOption(arguments.options.shipping_address, "name") />
				<cfset arguments.payload["shipToStreetaddress"] = getOption(arguments.options.shipping_address, "address1") />
				<cfset arguments.payload["shipToCity"] = getOption(arguments.options.shipping_address, "city") />
				<cfset arguments.payload["shipToState"] = getOption(arguments.options.shipping_address, "region") />
				<cfset arguments.payload["shipToZipcode"] = getOption(arguments.options.shipping_address, "postalcode") />
				<cfset arguments.payload["shipToCountry"] = getOption(arguments.options.shipping_address, "country") />
				<cfset arguments.payload["shipToPhone"] = getOption(arguments.options.shipping_address, "phone") />
			</cfif>
			<!--- skipjack requires shiptophone to be sent --->
			<cfif (not structKeyExists(arguments.payload, "shipToPhone")) and (structKeyExists(arguments.payload, "phone"))>
				<cfset arguments.payload["shipToPhone"] = arguments.payload["phone"] />
			</cfif>
		</cfif>
	</cffunction>

	<cffunction name="addCustomerData" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="options" type="any" required="true"/>
		<cfif ListFindNoCase("authorize", getGatewayAction())>
			<cfset arguments.payload["email"]=arguments.options.Email />
		<cfelseif getGatewayAction() eq "recurring">
			<cfset arguments.payload["rtEmail"]=arguments.options.Email />
		<cfelse>
			<cfthrow message="Invalid GatewayAction Logic in AddCustomerData" type="cfpayment.InvalidParameter" />
		</cfif>
	</cffunction>

	<cffunction name="addMisc" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="options" type="any" required="true"/>
		<cfif getGatewayAction() eq "recurring">
			<cfset arguments.payload["rtComment"]=getOption(arguments.options, "Comment") />
		<cfelse>
			<cfset arguments.payload["comment"]=getOption(arguments.options, "Comment") />
		</cfif>
	</cffunction>

	<cffunction name="addAmount" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="money" type="any" required="true"/>
		<cfif ListFindNoCase("authorize", getGatewayAction())>
			<cfset arguments.payload["transactionamount"]=arguments.money.getAmount() />
		<cfelseif getGatewayAction() eq "recurring">
			<cfset arguments.payload["rtAmount"]=arguments.money.getAmount() />
		<cfelse>
			<cfset arguments.payload["szAmount"]=arguments.money.getAmount() />
		</cfif>
	</cffunction>

	<cffunction name="addCredentials" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="options" type="any" required="true"/>
		<cfif ListFindNoCase("authorize", getGatewayAction())>
			<cfset arguments.payload["Serialnumber"]=getMerchantAccount() />
		<cfelse>
			<cfset arguments.payload["szSerialNumber"]=getMerchantAccount() />
		</cfif>
		<cfif ListFindNoCase("recurring,capture,void,credit,newcharge,status", getGatewayAction())>
			<cfset arguments.payload["szDeveloperSerialNumber"] = getOption(arguments.options, "DeveloperSerialNumber") />
		</cfif>
	</cffunction>

	<cffunction name="addStatusAction" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="statusAction" type="any" required="true"/>
		<cfset arguments.payload["szDesiredStatus"]=arguments.statusAction />
	</cffunction>

	<cffunction name="addTransactionId" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="transactionId" type="any" required="true"/>
		<cfset arguments.payload["szTransactionId"]=arguments.transactionId />
	</cffunction>

	<cffunction name="addForcedSettlement" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="options" type="any" required="true"/>
		<cfif len(GetOption(arguments.options, "force_settlement"))>
			<cfset arguments.payload["szForceSettlement"]=GetOption(arguments.options, "force_settlement") />
		<cfelse>
			<cfset arguments.payload["szForceSettlement"]="0" />
		</cfif>
	</cffunction>

	<cffunction name="addUserDefined" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="options" type="any" required="true"/>
		<cfset var keylist = "" />
		<cfset var key = "" />
		<cfset var udfStruct = StructNew() />
		<!--- User-Defined Data --->
		<!---
			NOTE: For SkiJack reporting purposes, these must be put in the same order each-and-every time. Note that SkipJack will report
				the values in REVERSE order of how they are specified via the cfhttpparam tags, so the order here must be the reverse
				of what we actually want later. To assure the order, we will create a separate structure under the payload key and pass
				the _keylist along. The base.process() method will check for a structure vs. simple value and for the _keylist and
				assure that they will go in the order specified in the _keylist.
		--->
		<cfif structKeyExists(arguments.options, "UserDefined") and isStruct(arguments.options.UserDefined)>
			<cfset udfStruct=StructCopy(arguments.options.UserDefined)>
			<!--- user defined fields will show up in reverse order of how they are output in the http params section --->
			<cfif NOT structKeyExists(arguments.options.UserDefined, "_KeyList")>
				<!--- alphabetize the keys for consistency --->
				<cfset udfStruct._keylist=ListSort(StructKeyList(udfStruct), "textnocase", "asc") />
			</cfif>
			<!--- put in reverse alpha-order so they show up in alpha order in the skipjack admin --->
			<cfset udfStruct._keylist=ListReverse(udfStruct._keylist)>
			<!--- add to the payload (note that this key won't actually get output anywhere) --->
			<cfset arguments.payload["USERDEFINED"]=StructCopy(udfStruct) />
		</cfif>
	</cffunction>

	<cffunction name="addCreditCard" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="account" type="any" required="true"/>
		<cfif getGatewayAction() eq "recurring">
			<cfset arguments.payload["rtAccountnumber"]=arguments.account.getAccount() />
			<cfset arguments.payload["rtExpMonth"]=arguments.account.getMonth() />
			<cfset arguments.payload["rtExpYear"]=arguments.account.getYear() />
			<cfset arguments.payload["rtName"]=arguments.account.getName() />
		<cfelse>
			<cfset arguments.payload["accountnumber"]=arguments.account.getAccount() />
			<cfset arguments.payload["month"]=arguments.account.getMonth() />
			<cfset arguments.payload["year"]=arguments.account.getYear() />
			<cfset arguments.payload["cvv2"]=arguments.account.getVerificationValue() />
			<cfset arguments.payload["sjName"]=arguments.account.getName() />
		</cfif>
	</cffunction>

	<cffunction name="addRecurringFields" output="false" access="private" returntype="void" hint="">
		<cfargument name="payload" type="any" required="true"/>
		<cfargument name="mode" type="any" required="true"/>
		<cfargument name="options" type="any" required="true"/>
		<cfif ListFindNoCase("add", arguments.mode)>
			<cfset arguments.payload["rtStartingDate"] = getOption(arguments.options, "StartingDate") />
			<!--- frequency is stored as a normalized option named "periodicity" --->
			<cfset arguments.payload["rtFrequency"] = getPeriodicityValue(getOption(arguments.options, "Periodicity")) />
			<cfset arguments.payload["rtTotalTransactions"] = getOption(arguments.options, "TotalTransactions") />
		<cfelseif ListFindNoCase("edit,delete,get", arguments.mode)>
			<cfset arguments.payload["szPaymentId"] = getOption(arguments.options, "PaymentId") />
			<!---
				NOTE for edit:
				If this variable is supplied, only the individual transaction within a Recurring Payment record schedule will be edited.
				If this variable is NOT SUPPLIED, the payment is globally edited for ALL

				NOTE for delete:
				Including the szTransactionDate variable in the request will ONLY DELETE the individual
				transaction matching the specified date within this Recurring Payment schedule.

				NOTE for get:
				If this variable is sent in the request all transactions will be retrieved for the individual Recurring
				Payment. If this variable is not sent, all Recurring Payments for the Merchant will be returned.
			--->
			<cfset arguments.payload["szTransactionDate"] = getOption(arguments.options, "TransactionDate") />
		<cfelse>
			<cfthrow message="Invalid Mode Logic in addRecurringFields" type="cfpayment.InvalidParameter" />
		</cfif>
	</cffunction>

	<cfscript>
	/**
	* Reverses a list.
	* Modified by RCamden to use var scope
	*
	* @param list      List to be modified.
	* @param delimiter      Delimiter for the list. Defaults to a comma.
	* @return Returns a list.
	* @author Stephen Milligan (spike@spike.org.uk)
	* @version 2, July 17, 2001
	*/
	function ListReverse(list) {

	    var newlist = "";
	    var i = 0;
	    var delims = "";
	    var thisindex = "";
	    var thisitem = "";

	    var argc = ArrayLen(arguments);
	    if (argc EQ 1) {
	        ArrayAppend(arguments,',');
	    }
	    delims = arguments[2];
	    while (i LT listlen(list,delims))
	    {
	    thisindex = listlen(list,delims)-i;
	    thisitem = listgetat(list,thisindex,delims);
	newlist = listappend(newlist,thisitem,delims);
	i = i +1;
	    }
	return newlist;
	}
	</cfscript>

</cfcomponent>