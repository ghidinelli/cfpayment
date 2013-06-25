<!---
	$Id$

	Copyright 2013 Andrew Penhorwood (http://www.coldbits.com/)

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
<cfcomponent name="payflowLibrary" output="false">

<!--- =======================================================================================================
	  init                                                                                                  =
	  ================================================================================================== --->
	<cffunction name       = "init"
				access     = "public"
				returntype = "component"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/25/2013">

		<cfset var config = StructNew()>

		<!--- Notes:
				1. It appears that paypal's service does not like the @ in the password even though Paypal manager allowed me to use that in my password.
				   I could never authenticate until I removed the @.
				2. You must setup a API user inside of Paypal Manager that accepts API_FULL_TRANSACTIONS.  I also setup the IP access just in case.
				   This user is different then the Admin user that you use to access paypal manager.
		 --->

		<!--- BEGIN *** These values MUST be configured according to the info sent to you from Paypal *** --->
		<cfset config['AcceptedCardTypes'] = "Visa,AmEx,Discover,MasterCard">	<!--- Card Types your account accepts.  Possible values: AmEx,AmExCorp,DinersClub,Discover,JCB,MasterCard,Visa --->
		<cfset config['Partner']         = "">
		<cfset config['MerchantAccount'] = "">
		<cfset config['userName']        = "">
		<cfset config['password']        = "">
		<!--- END   *** These values MUST be configured according to the info sent to you from Paypal *** --->

		<cfset variables['config'] = config>
		<cfset variables['person'] = genPerson()>	<!--- create test person. override data points here if you don't like the default ones --->

		<cfreturn this>
	</cffunction>

<!--- =======================================================================================================
	  getPerson                                                                                             =
	  ================================================================================================== --->
	<cffunction name       = "getPerson"
				access     = "public"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/25/2013">

		<cfreturn variables.person>
	</cffunction>

<!--- =======================================================================================================
	  getAcceptedCardTypes                                                                                  =
	  ================================================================================================== --->
	<cffunction name       = "getAcceptedCardTypes"
				access     = "public"
				returntype = "string"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/25/2013">

		<cfreturn variables.config.AcceptedCardTypes>
	</cffunction>

<!--- =======================================================================================================
	  getPartner                                                                                            =
	  ================================================================================================== --->
	<cffunction name       = "getPartner"
				access     = "public"
				returntype = "string"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/25/2013">

		<cfreturn variables.config.Partner>
	</cffunction>

<!--- =======================================================================================================
	  getMerchantAccount                                                                                    =
	  ================================================================================================== --->
	<cffunction name       = "getMerchantAccount"
				access     = "public"
				returntype = "string"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/25/2013">

		<cfreturn variables.config.MerchantAccount>
	</cffunction>

<!--- =======================================================================================================
	  getUserName                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "getUserName"
				access     = "public"
				returntype = "string"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/25/2013">

		<cfreturn variables.config.userName>
	</cffunction>

<!--- =======================================================================================================
	  getPassword                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "getPassword"
				access     = "public"
				returntype = "string"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/25/2013">

		<cfreturn variables.config.password>
	</cffunction>

<!--- =======================================================================================================
	  genValidOptions                                                                                       =
	  ================================================================================================== --->
	<cffunction name       = "genValidOptions"
				access     = "public"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="orderID" type="string" default="1234Order">

		<cfset var options = StructNew()>

		<cfset options['address']  = person.address>
		<cfset options['email']    = person.email>
		<cfset options['order_id'] = arguments.orderID>

		<cfreturn options>
	</cffunction>

<!--- =======================================================================================================
	  genPerson                                                                                             =
	  ================================================================================================== --->
	<cffunction name       = "genPerson"
				access     = "public"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="FirstName"  type="string" default="Fred">
		<cfargument name="LastName"   type="string" default="Flintstone">
		<cfargument name="domain"     type="string" default="bogus.com">

		<!--- if you are wonder this address is for Paypal, Inc --->
		<cfargument name="phone"      type="string" default="402-935-2050">
		<cfargument name="Address"    type="string" default="2211 N 1st St">
		<cfargument name="City"       type="string" default="San Jose">
		<cfargument name="State"      type="string" default="CA">
		<cfargument name="PostalCode" type="string" default="95131">
		<cfargument name="Country"    type="string" default="USA">

		<cfset var person = StructNew()>

		<cfset person['FirstName'] = arguments.FirstName>
		<cfset person['LastName']  = arguments.LastName>
		<cfset person['email']     =  person.Firstname & "." & person.LastName & "@" & arguments.domain>

		<cfset person.address = StructNew()>
		<cfset person.address['phone']      = arguments.phone>
		<cfset person.address['Address1']   = arguments.Address>
		<cfset person.address['City']       = arguments.City>
		<cfset person.address['State']      = arguments.State>
		<cfset person.address['PostalCode'] = arguments.PostalCode>
		<cfset person.address['Country']    = arguments.Country>

		<cfreturn person>
	</cffunction>

<!--- =======================================================================================================
	  genAmount                                                                                             =
	  ================================================================================================== --->
	<cffunction name       = "genAmount"
				access     = "public"
				returntype = "numeric"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfset var dollars = RandRange(10,1000,"SHA1PRNG")>
		<cfset var cents   = RandRange(10,99,"SHA1PRNG") / 100>

		<cfreturn dollars + cents>
	</cffunction>

<!--- =======================================================================================================
	  genCreditCard                                                                                         =
	  ================================================================================================== --->
	<cffunction name       = "genCreditCard"
				access     = "public"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">
		<cfargument name="cardtype" type="string" required="no">

		<cfset card = genValidCard(svc)>

		<cfswitch expression="#LCase(arguments.cardtype)#">
			<cfcase value="AmEx,AmericanExpress,American Express">
				<cfset card = genAmEx(svc)>
			</cfcase>

			<cfcase value="AmExCorp,AmericanExpressCorp,American Express Corp">
				<cfset card = genAmExCorp(svc)>
			</cfcase>

			<cfcase value="DinersClub,Diners Club">
				<cfset card = genDinersClub(svc)>
			</cfcase>

			<cfcase value="Discover">
				<cfset card = genDiscover(svc)>
			</cfcase>

			<cfcase value="JCB">
				<cfset card = genJCB(svc)>
			</cfcase>

			<cfcase value="MasterCard">
				<cfset card = genMasterCard(svc)>
			</cfcase>

			<cfcase value="Visa">
				<cfset card = genVisa(svc)>
			</cfcase>
		</cfswitch>

		<cfreturn card>
	</cffunction>

<!--- =======================================================================================================
	  genValidCard                                                                                          =
	  ================================================================================================== --->
	<cffunction name       = "genValidCard"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood based on code by Brian Ghidinelli"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">
		<cfargument name="cardNumber" type="string" default="4111111111111111">

		<!--- these values simulate a valid card with matching avs/cvv --->
		<cfset var creditcard = svc.createCreditCard()>

		<!--- who --->
		<cfset creditcard.setFirstName( person.FirstName )>
		<cfset creditcard.setLastName( person.LastName )>
		<cfset creditcard.setAddress( person.address.Address1 )>
		<cfset creditcard.setPostalCode( person.address.Postalcode )>

		<!--- account info --->
		<cfset creditcard.setAccount( arguments.cardNumber )>
		<cfset creditcard.setMonth( Month(now()) )>
		<cfset creditcard.setYear( year(now())+1 )>
		<cfset creditcard.setVerificationValue(123)>

		<cfreturn creditcard>
	</cffunction>

<!--- =======================================================================================================
	  genAmEx                                                                                               =
	  ================================================================================================== --->
	<cffunction name       = "genAmEx"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">

		<cfreturn genValidCard(svc, "371449635398431")>
	</cffunction>

<!--- =======================================================================================================
	  genAmExCorp                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "genAmExCorp"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">

		<cfreturn genValidCard(svc, "378734493671000")>
	</cffunction>

<!--- =======================================================================================================
	  genDinersClub                                                                                         =
	  ================================================================================================== --->
	<cffunction name       = "genDinersClub"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">

		<cfreturn genValidCard(svc, "38520000023237")>
	</cffunction>

<!--- =======================================================================================================
	  genDiscover                                                                                           =
	  ================================================================================================== --->
	<cffunction name       = "genDiscover"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">

		<cfreturn genValidCard(svc, "6011000990139424")>
	</cffunction>

<!--- =======================================================================================================
	  genJCB                                                                                                =
	  ================================================================================================== --->
	<cffunction name       = "genJCB"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">

		<cfreturn genValidCard(svc, "3566002020360505")>
	</cffunction>

<!--- =======================================================================================================
	  genMasterCard                                                                                         =
	  ================================================================================================== --->
	<cffunction name       = "genMasterCard"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">

		<cfreturn genValidCard(svc, "5105105105105100")>
	</cffunction>

<!--- =======================================================================================================
	  genVisa                                                                                               =
	  ================================================================================================== --->
	<cffunction name       = "genVisa"
				access     = "private"
				returntype = "struct"
				output     = "false"
				purpose    = ""
				author     = "Andrew Penhorwood"
				created    = "06/22/2013">

		<cfargument name="svc" type="component" required="yes">

		<cfreturn genValidCard(svc, "4012888888881881")>
	</cffunction>

</cfcomponent>
