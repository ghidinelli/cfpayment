<cfcomponent output="false" displayname="LoggingAdvice" hint="I advise service layer methods and apply logging." extends="coldspring.aop.MethodInterceptor">
<!---
	$Id

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

	<!--- simple logging, based on http://www.coldspringframework.org/coldspring/examples/quickstart/index.cfm?page=aop --->

	<cffunction name="init" returntype="any" output="false" access="public" hint="Constructor">
		<cfreturn this />
	</cffunction>

	<cffunction name="invokeMethod" returntype="any" access="public" output="false" hint="">
		<cfargument name="methodInvocation" type="coldspring.aop.MethodInvocation" required="true" hint="" />
		<cfset var local =  StructNew() />

		<cfif NOT StructKeyExists(request, "logData")>
			<cfset request.logData=ArrayNew(1)>
		</cfif>

		<!--- Capture the arguments and method name being invoked. --->
		<cfset local.logData = StructNew() />
		<cfset local.logData.arguments = StructCopy(arguments.methodInvocation.getArguments()) />
		<cfset local.logData.method = arguments.methodInvocation.getMethod().getMethodName() />
		<cfset ArrayAppend(request.logData, duplicate(local.logData)) />

		<!--- Proceed with the method call to the underlying CFC. --->
		<cfset local.result = arguments.methodInvocation.proceed() />

		<!--- Return the result of the method call. --->
		<cfif structKeyExists(local, "result")>
			<cfreturn local.result />
		<cfelse>
			<cfreturn />
		</cfif>
	</cffunction>

</cfcomponent>