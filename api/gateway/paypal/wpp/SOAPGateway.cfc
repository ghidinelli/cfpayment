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


	TODO: Everything

--->
<cfcomponent extents="cfpayment.api.gateway.base" hint="SOAP API Gateway for PayPal Website Payments Pro" output="false">

	<!--- cfpayment structure values override base class --->
	<cfset variables.cfpayment.GATEWAY_NAME = "SOAP API Gateway for PayPal Website Payments Pro" />
	<cfset variables.cfpayment.GATEWAY_VERSION = "1.0" />
	<cfset variables.cfpayment.GATEWAY_TEST_URL = "https://api-3t.sandbox.paypal.com/2.0/" />
	<cfset variables.cfpayment.GATEWAY_LIVE_URL = "https://api-3t.paypal.com/2.0/" />


</cfcomponent>