/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is an implementation of paylinedata API. 
	See:
	https://secure.paylinedatagateway.com/gw/merchants/resources/integration/integration_portal.php#transaction_types

	Licensed under the Apache License, Version 2.0 (the "License"); you 
	may not use this file except in compliance with the License. You may 
	obtain a copy of the License at:
	 
		http://www.apache.org/licenses/LICENSE-2.0
		 
	Unless required by applicable law or agreed to in writing, software 
	distributed under the License is distributed on an "AS IS" BASIS, 
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
	See the License for the specific language governing permissions and 
	limitations under the License.
*/
component
	extends="cfpayment.api.gateway.base"
	displayname="Authorize.net AIM Interface"
	hint="Authorize.net Gateway see http://developer.authorize.net/api/reference/"
{

	variables.cfpayment.GATEWAY_NAME = "PaylineData";
	variables.cfpayment.GATEWAY_VERSION = "1.0";
	

	//Same endpoint, but different credentials	
	variables.cfpayment.GATEWAY_TEST_URL = "https://secure.paylinedatagateway.com/api/transact.php";
	variables.cfpayment.GATEWAY_LIVE_URL = "https://secure.paylinedatagateway.com/api/transact.php";



	function purchase(Any required money, Any requred account, Struct options={} ){

		//create the struct to send:

		var payload = {

		}
		dump(payload);
		dump(this.getMerchantAccount());
		//abort;
	}
}