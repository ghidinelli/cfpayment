The GoEMerchant interface under, certain circumstances  returns a blank (" ") 
CVV and/or AVS value. In that case the value is left "un-set" or empty ("") 
in the response structure.

The most common case is if no CVV code is sent in, say for a recurring 
transaction, no CVV response is created. Empty AVS responses tend to be 
related to testing only.
