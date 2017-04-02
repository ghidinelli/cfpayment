/*
	Copyright 2016 Mark Drew (http://markdrew.io)
		
	This is an address object that can be used to store billTo addresses etc. 
	
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
	accessors="true"
{
	property name="firstName" 		type="string"	getter="true"	setter="true";
	property name="lastName" 		type="string"	getter="true"	setter="true";
	property name="company" 		type="string"	getter="true"	setter="true";
	property name="address" 		type="string"	getter="true"	setter="true";
	property name="address2" 		type="string"	getter="true"	setter="true";
	property name="city" 			type="string"	getter="true"	setter="true";
	property name="state" 			type="string"	getter="true"	setter="true";
	property name="zip" 			type="string"	getter="true"	setter="true";
	property name="country" 		type="string"	getter="true"	setter="true";
	property name="phoneNumber" 	type="string"	getter="true"	setter="true";
	property name="email" 			type="string"	getter="true"	setter="true";
	property name="faxNumber" 		type="string"	getter="true"	setter="true";
	property name="cellPhoneNumber" type="string"	getter="true"	setter="true";
	property name="website" 		type="string"	getter="true"	setter="true";


	public Struct function getMemento(){

		var ret = {};
		var proparr = getMetadata(this).properties;

		for(var prop in proparr){
			
			ret[prop.name] = prop.getter? this["get#prop.name#"]() : variables[prop.name];	
			
			
		}
		return ret;
	}
}