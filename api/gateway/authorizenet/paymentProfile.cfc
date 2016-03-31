/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is a customer that can be loaded and saved to the authorize.net system
	
	
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
component accessors="true"
{

	property name="customerType" getter="true" setter="true";
	property name="paymentMethods" getter="true" setter="true" hint="Card that we can use with this profile";

	variables.custTypes = "individual,business";

	public function setCustomerType(String type){

		if(!listFindNoCase(variables.custTypes, type)){
			throw(type="cfpayment.authorizenet.illegalArgumentException", message="CustomerType can only be individual or business");
		}
		variables.customerType = type;
		return this;
	}
}