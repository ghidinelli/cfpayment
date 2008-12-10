<!DOCTYPE beans PUBLIC "-//SPRING//DTD BEAN//EN" "http://www.springframework.org/dtd/spring-beans.dtd">
<!--
	$Id$

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
-->
<beans>
	<bean id="cfpaymentCore" class="cfpayment.api.core">
		<constructor-arg name="config">
		<map>
			<!-- these values should be passed in as a structure to the DefaultXmlBeanFactory init() function -->
			<entry key="path"><value>${Path}</value></entry>
			<entry key="MerchantAccount"><value>${MerchantAccount}</value></entry>
			<entry key="userName"><value>${UserName}</value></entry>
			<entry key="password"><value>${Password}</value></entry>
		</map>
		</constructor-arg>
	</bean>

	<!-- use this bean id for no logging -->
	<bean id="cfpaymentGW" factory-bean="cfpaymentCore" factory-method="getGateway" />

	<!-- use this bean id for logging gateway calls -->
	<bean id="cfpaymentGWlogging" class="coldspring.aop.framework.ProxyFactoryBean">
		<property name="target">
			<ref bean="cfpaymentGW" />
		</property>
		<property name="interceptorNames">
			<list>
				<value>loggingAdvisor</value>
			</list>
		</property>
	</bean>

	<bean id="loggingAdvice" class="cfpayment.contrib.coldspring.loggingadvice" />

	<bean id="loggingAdvisor" class="coldspring.aop.support.NamedMethodPointcutAdvisor">
		<property name="advice">
			<ref bean="loggingAdvice" />
		</property>
		<property name="mappedNames">
			<value>*</value><!-- specify a specific function name here if desired -->
		</property>
	</bean>

</beans>
