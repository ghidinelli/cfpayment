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
component accessors="true" {

	property name="merchantCustomerId" getter="true" setter="true";
	property name="description" getter="true" setter="true";
	property name="email" getter="true" setter="true";

	property name="paymentProfiles" getter="true" setter="true";


	/*
		The id can either be merchantCustomerId, description or email, if they are all null then it is not valid
	*/
	public boolean function hasValidID(){

		if(!isNull(getMerchantCustomerId()) && !isEmpty(getMerchantCustomerId())){
			return true;
		}
		if(!isNull(getDescription()) && !isEmpty(getDescription())){
			return true;
		}
		if(!isNull(getEmail()) && !isEmpty(getEmail())){
			return true;
		}

		return false;
	}

}