#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


function /T TextWave2JSONArray(tw)
	WAVE /T tw
	variable len = dimsize(tw,0),i=0
	if (len==0)
		return "[]"
	endif
	string json ="["+quote(tw[i])
	for(i=1;i<len;i+=1)	// Initialize variables;continue test
		json += ","+quote(tw[i])		// Condition;update loop variables
	endfor						// Execute body code until continue test is FALSE
	return json + "]"
end

function /T Wave2JSONArray(w)
	WAVE w
	variable len = dimsize(w,0),i=0
	if (len==0)
		return "[]"
	endif
	string json ="["+num2str(w[i])
	for(i=1;i<len;i+=1)	// Initialize variables;continue test
		json += ","+num2str(w[i])+	""		// Condition;update loop variables
	endfor						// Execute body code until continue test is FALSE
	return json + "]"
end


function /T KeyValueNumJSON(Key,num)
	string key
	variable num
	return quote(key)+":"+num2str(num)
end

function /T KeyStringJSON(Key,value)
	string key,value
	return quote(key)+":"+quote(value)
end

function /T KeyObjectJSON(Key,value)
	string key, value
	return quote(key)+":"+value
end

 function /t quote(s)
	string s
	return "\""+s+"\""
end