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

	//primary id set by authorise.net
	property name="customerProfileId" 	getter="true" setter="true";
	property name="merchantCustomerId" 	getter="true" setter="true";
	property name="description" 		getter="true" setter="true";
	property name="email" 				getter="true" setter="true";
	property name="service" 				getter="true" setter="true";

	
	property name="paymentProfiles"		type="array" getter="true" setter="true";


	function init(service){
		setService(service);
		return this;
	}
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

		if(!isNull(getCustomerProfileId()) && !isEmpty(getCustomerProfileId())){
			return true;
		}


		return false;
	}



	public customer function populate(XML responseXML){


		setMerchantCustomerId(getXMLElementText(responseXML, "merchantCustomerId"));
		setDescription(getXMLElementText(responseXML, "description"));
		setEmail(getXMLElementText(responseXML, "email"));
		setCustomerProfileId(getXMLElementText(responseXML, "customerProfileId"));
		

		//TODO: find out if this is actually correct and we get an array of paymentProfiles back, documentation is lacking at this point:
		//http://developer.authorize.net/api/reference/#customer-profiles-create-customer-profile

		var paymentProfiles = XMLSearch(responseXML, "//:paymentProfiles");
		for(var paymentProfile in paymentProfiles){
			var pp = new paymentProfile(service=getService()).populate(paymentProfile);
			addPaymentProfile(pp);
			
		}

		
		return this;
	}

	private function getXMLElementText(XML responseXML, String elementName, default=""){
		var searchItem = XMLSearch(responseXML, "//:#elementName#");
		return ArrayLen(searchItem)?searchItem[1].xmlText : default;
	}

	public void function addPaymentProfile(PaymentProfile profile){

		var profiles = getPaymentProfiles();
			profiles = isNull(profiles) ? [] : profiles;

			profiles.append(profile);
			setPaymentProfiles(profiles);
	}
}