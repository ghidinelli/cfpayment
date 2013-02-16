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
<cfcomponent name="response" displayname="Stripe Gateway Response" output="false" hint="Remaps hasErrors() for Stripe" extends="cfpayment.api.model.response">

	<cffunction name="hasError" access="public" output="false" returntype="boolean" hint="An error is determined by the status code; the list of good/bad is in the core API">
		<cfset var res = getParsedResult() />
		<cfreturn listFind(getService().getStatusErrors(), getStatus()) OR (isStruct(res) AND structKeyExists(res, "error"))  />
	</cffunction>

</cfcomponent>