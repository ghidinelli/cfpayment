<!---
	$Id: response.cfc 111 2009-02-01 19:50:50Z briang $

	Copyright 2007 Brian Ghidinelli (http://www.ghidinelli.com/)
                   Mark Mazelin (http://www.mkville.com)

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
<cfcomponent name="response" extends="cfpayment.api.model.response" displayname="GoEmerchant Gateway Response" output="false">

	<!--- additional GoEmerchant constants --->
	<cfscript>
		structInsert(variables.cfpayment.ResponseAVS, " ", "AVS check not done.", true);
		structInsert(variables.cfpayment.ResponseCVV, " ", "CVV not supplied", true);
	</cfscript>

</cfcomponent>