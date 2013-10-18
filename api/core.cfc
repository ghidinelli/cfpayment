<!---
	$Id$

	Copyright 2007 Brian Ghidinelli (http://www.ghidinelli.com/)

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
<cfcomponent name="core" output="false" displayname="CFPAYMENT Core" hint="The core API for CFPAYMENT">

	<!---
	NOTES:
	* This is the main object that will be invoked
	* Create the object and init() it with a configuration object

	USAGE:
		requires a configuration object that looks like:

			.path (REQUIRED, to gateway cfc, could be "itransact.itransact_cc" or "bogus.gateway")
			.id (a unique id you give your gateways.  If only ever have one, use 1)
			.mid (merchant account number)
			.username
			.password
			...
			(these are arbitrary keys passed to the gateway on init so if not using l/p, pass here)

	--->

	<!--- pseudo-constructor --->
	<cfset variables.instance = structNew() />
	<cfset variables.instance.VERSION = "@VERSION@" />


	<cffunction name="init" output="false" access="public" returntype="any" hint="Initialize the core API and return a reference to it">
		<cfargument name="config" type="struct" required="true" />

		<cfset variables.instance.config = arguments.config />

		<!--- the core service expects a structure of configuration information to be passed to it
			  telling it what gateway to use and so forth --->
		<cftry>
			<!--- instantiate gateway and initialize it with the passed configuration --->
			<cfset variables.instance.gateway = createObject("component", "gateway.#lCase(variables.instance.config.path)#").init(config = variables.instance.config, service = this) />

			<cfcatch type="template">
				<!--- these are errors in the gateway itself, need to bubble them up for debugging --->
				<cfrethrow />
			</cfcatch>
			<cfcatch type="application">
				<cfthrow message="Invalid Gateway Specified" type="cfpayment.InvalidGateway" />
			</cfcatch>
			<cfcatch type="any">
				<cfrethrow />
			</cfcatch>
		</cftry>

		<cfreturn this />
	</cffunction>


	<!--- PUBLIC METHODS --->

	<cffunction name="getGateway" access="public" output="false" returntype="any" hint="return the gateway or throw an error">
		<cfreturn variables.instance.gateway />
	</cffunction>

	<!--- getters and setters --->
	<cffunction name="getVersion" access="public" output="false" returntype="string">
		<cfif isNumeric(variables.instance.version)>
			<cfreturn variables.instance.version />
		<cfelse>
			<cfreturn "SVN" />
		</cfif>
	</cffunction>

	<cffunction name="createCreditCard" output="false" access="public" returntype="any" hint="return a credit card object for population">
		<cfreturn createObject("component", "model.creditcard").init(argumentCollection = arguments) />
	</cffunction>

	<cffunction name="createEFT" output="false" access="public" returntype="any" hint="create an electronic funds transfer (EFT) object for population">
		<cfreturn createObject("component", "model.eft").init(argumentCollection = arguments) />
	</cffunction>

	<cffunction name="createOAuth" output="false" access="public" returntype="any" hint="create a representation for OAuth credentials to perform actions on behalf of someone">
		<cfreturn createObject("component", "model.oauth").init(argumentCollection = arguments) />
	</cffunction>

	<cffunction name="createToken" output="false" access="public" returntype="any" hint="create a remote storage token for population">
		<cfreturn createObject("component", "model.token").init(argumentCollection = arguments) />
	</cffunction>

	<cffunction name="createMoney" output="false" access="public" returntype="any" hint="Create a money component for amount and currency conversion and formatting">
		<cfreturn createObject("component", "model.money").init(argumentCollection = arguments) />
	</cffunction>

	<cffunction name="getAccountType" output="false" access="public" returntype="any">
		<cfargument name="Account" type="any" required="true" />
		<cfreturn lcase(listLast(getMetaData(arguments.account).fullname, ".")) />
	</cffunction>	

	<!--- statuses to determine success and failure --->
	<cffunction name="getStatusUnprocessed" output="false" access="public" returntype="any" hint="This status is used to denote the transaction wasn't performed">
		<cfreturn -1 />
	</cffunction>
	<cffunction name="getStatusSuccessful" output="false" access="public" returntype="any" hint="This status indicates success">
		<cfreturn 0 />
	</cffunction>
	<cffunction name="getStatusPending" output="false" access="public" returntype="any" hint="This status indicates when we have sent a request to the gateway and are awaiting response (Transaction API or delayed settlement like ACH)">
		<cfreturn 1 />
	</cffunction>
	<cffunction name="getStatusDeclined" output="false" access="public" returntype="any" hint="This status indicates a declined transaction">
		<cfreturn 2 />
	</cffunction>
	<cffunction name="getStatusFailure" output="false" access="public" returntype="any" hint="This status indicates something went wrong like the gateway threw an error but we believe the transaction was not processed">
		<cfreturn 3 />
	</cffunction>
	<cffunction name="getStatusTimeout" output="false" access="public" returntype="any" hint="This status indicates the remote server doesn't answer meaning we don't know if transaction was processed">
		<cfreturn 4 />
	</cffunction>
	<cffunction name="getStatusUnknown" output="false" access="public" returntype="any" hint="This status indicates an exception we don't know how to handle (yet)">
		<cfreturn 99 />
	</cffunction>
	<cffunction name="getStatusErrors" output="false" access="public" returntype="any" hint="This defines which statuses are errors">
		<cfreturn "3,4,99" />
	</cffunction>
</cfcomponent>