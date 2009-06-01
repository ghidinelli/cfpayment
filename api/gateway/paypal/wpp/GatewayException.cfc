<!---

	Copyright 2009 Joseph Lamoree (http://www.lamoree.com/)

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
<cfcomponent output="false">

	<cfset variables.errorInfo = structNew() />

	<cffunction name="init" returntype="GatewayException" access="public" output="false">
		<cfargument name="exception" type="any" required="false" />
		<cfargument name="errorCode" type="string" required="false" />
		<cfargument name="type" type="string" required="false" />
		<cfargument name="message" type="string" required="false" />
		<cfargument name="detail" type="string" required="false" />

		<cfif structKeyExists(arguments, "exception")>
			<cfset setException(arguments.exception) />
		<cfelseif structKeyExists(arguments, "errorCode")>
			<cfset setErrorCode(getProperty(arguments, "errorCode")) />
		<cfelse>
			<cfset setType(getProperty(arguments, "type")) />
			<cfset setMessage(getProperty(arguments, "message")) />
			<cfset setDetail(getProperty(arguments, "detail")) />
		</cfif>
		<cfreturn this />
	</cffunction>

	<cffunction name="doThrow" returntype="void" access="public" output="false">
		<cfthrow type="#getType()#" message="#getMessage()#" detail="#getDetail()#" />
	</cffunction>

	<cffunction name="setException" returntype="void" access="private" output="false">
		<cfargument name="exception" type="any" required="true" />

		<cfset var p = getProperty(arguments.exception, "message") />
		<cfset var n = 0 />

		<cfset variables.exception = arguments.exception />
		<cfif n gt 0>
			<cfset setErrorCode(n) />
		<cfelse>
			<cfset setType(getProperty(variables.exception, "type")) />
			<cfset setMessage(getProperty(variables.exception, "message")) />
			<cfset setDetail(getProperty(variables.exception, "detail")) />
		</cfif>
	</cffunction>

	<cffunction name="setErrorCode" returntype="void" access="private" output="false">
		<cfargument name="errorCode" type="any" required="true" />

		<cfset var e = "null" />

		<cfset variables.errorCode = arguments.errorCode />
		<cfif structKeyExists(variables.errorInfo, variables.errorCode)>
			<cfset e = variables.errorInfo[variables.errorCode] />
			<cfset setType(e.type) />
			<cfset setMessage(e.message) />
			<cfset setDetail(e.message) />
		<cfelse>
			<cfset setType("UnknownGatewayException") />
			<cfset setMessage("An unknown exception has been thrown.") />
			<cfset setDetail("") />
		</cfif>
	</cffunction>

	<cffunction name="getProperty" returntype="any" access="private" output="false">
		<cfargument name="props" type="any" required="true" />
		<cfargument name="name" type="string" required="true" />
		<cfargument name="default" type="any" required="true" default="" />

		<cfif structKeyExists(arguments.props, arguments.name)>
			<cfreturn arguments.props[arguments.name] />
		<cfelse>
			<cfreturn arguments.default />
		</cfif>
	</cffunction>


	<cffunction name="getErrorCode" returntype="string" access="public" output="false">
		<cfreturn variables.errorCode />
	</cffunction>

	<cffunction name="getType" returntype="string" access="public" output="false">
		<cfreturn variables.type />
	</cffunction>
	<cffunction name="setType" returntype="void" access="private" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfset variables.type = arguments.type />
	</cffunction>

	<cffunction name="getMessage" returntype="string" access="public" output="false">
		<cfreturn variables.message />
	</cffunction>
	<cffunction name="setMessage" returntype="void" access="private" output="false">
		<cfargument name="message" type="string" required="true" />
		<cfset variables.message = arguments.message />
	</cffunction>

	<cffunction name="getDetail" returntype="string" access="public" output="false">
		<cfreturn variables.detail />
	</cffunction>
	<cffunction name="setDetail" returntype="void" access="private" output="false">
		<cfargument name="detail" type="string" required="true" />
		<cfset variables.detail = arguments.detail />
	</cffunction>

</cfcomponent>