/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is an implementation of Cayan MerchantWare API. 
	See:
https://ps1.merchantware.net/Merchantware/ws/RetailTransaction/v4/Credit.asmx

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
	displayname="Merchantware API Interface"

{

	function purchase(Any required money, Any requred account, Struct options={}){

		var API = createObject("webservice", "https://ps1.merchantware.net/Merchantware/ws/RetailTransaction/v4/Credit.asmx?wsdl");

		dump(API);

		abort;
		throw("Method Not Implemented");
	}

	function authorize(Any required money, Any requred account, Struct options={}){

		throw("Method Not Implemented");
	}

	function capture(Any required money, String required authorization, Struct options={}){

		throw("Method Not Implemented");
	}

	function credit(Any required transactionID, Any required money, Struct options={}) {

		throw("Method Not Implemented");

	}
	function void(Any required transactionID, Struct options={}) {

		throw("Method Not Implemented");

	}

}