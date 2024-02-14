/// <pre>
/// Author - Alex Woodhead  2021-04-26 - V1 IRIS arrays and Lists to Py Dict and List<br/>
///                         2021-05-07 - Added support for py Dict and List back to IRIS array and List<br/>
///                                      Added Error log notifications for unsupported types.
///                                      Added string only keys for dictionaries
///                         2023-04-14 - Make IRIS Method return value + output parameters to be returnable to Python as tuple
///                         2023-04-16 - Resolve signatures for Base classes
///                                      Facilitate ByRef literals to also be returnable via Python via Tuple output.
///                                      Access for %objlasterror special variable via Tuple output.
///                         2023-04-23 - Added support for Multidimensional Property access and update:
/// 								     MultiGet - Retrieve the simple value or default from root or sub-key of multidimensional property 
/// 								     MultiSet - Set the value of multidimensional property at root or sub-key
/// 								     MultiKeys - Return a Python list of keys at property root or sub-key
/// 								     MultiReplace - Replace the whole property data or a sub-key with a python dictionary
/// 								     MultiMerge - Merge a python dictionary to root multidimensional property or sub-key
/// 								     MultiDel - Delete whole multidimensional property data or just a subkey
///                                      
/// </pre>
/// 
/// Mission:<br/>
/// A convenience utility to convert between:<ul>
/// <li>IRIS LIST and Python list</li>
/// <li>IRIS array and Python dictionary</li>
/// <li>Return Tuples to Python from IRIS Methods</li>
/// 
/// Method:<br/>
/// When converting IRIS arrays to Python dictionaries
/// the keys generated (for key,values) will always be strings.<br/>
/// This simplifies implementation IRIS->Python by providing consist output
/// whatever the invocation style is in IRIS.
/// <br/>
/// Conversion error information will be written to the IRIS event log<br/>
/// </br>
/// Whats is supported in both directions:<ul>
/// <li>Converting IRIS Arrays to Py Dictionaries</li>
/// <li>Converting IRIS multidimensional array to inner Py Dictionaries within Py Dictionaries</li>
/// <li>Converting IRIS Arrays that also contain lists to Dictionaries with values of Py Lists</li>
/// <li>Converting IRIS LIST to Py List</li>
/// </ul>
/// What is not supported:<ul>
/// <li>Converting Py Lists that contain Py Dictionaries into IRIS LISTS</li>
/// </ul>
Class alwo.PyHelper [ Abstract ]
{

ClassMethod A()
{
#define publist (kCount,k1,k2,k3,k4,k5,k6,k7,k8,k9,k10)
}

/// Allows dictionary key to be set
/// python language provides "[]" mutator
/// This method wraps this with a "Set" method
/// <example>
/// set impBi=##class(%SYS.Python).Import("builtins")
/// set pRequest=impBi.dict()
/// do ##class(Py.Helper).pyDictSet(pRequest,"Fname","Bob")
/// do ##class(Py.Helper).pyDictSet(pRequest,"Mname","Henry")
/// do ##class(Py.Helper).pyDictSet(pRequest,"Lname","Smith")
/// zw pRequest
/// pRequest=52@%SYS.Python  ; {'Fname': 'Bob', 'Mname': 'Henry', 'Lname': 'Smith'}  ; <OREF>
/// </example>
ClassMethod pyDictSet(ByRef dict As %SYS.Python, key, value)
{
	// Force key names to strings
	do ..pyDictSetInner(dict,""_key_"",value)
}

ClassMethod pyDictSetInner(ByRef dict As %SYS.Python, key, value) [ Language = python, Private ]
{
	dict[key]=value
}

/// Allows dictionary key to be removed
/// python language provides del keyword
/// This method wraps this with a "Kill" method
/// <example>
/// ; see pyDictSet method example for previous variable setup)
/// zw pRequest
/// pRequest=52@%SYS.Python  ; {'Fname': 'Bob', 'Mname': 'Henry', 'Lname': 'Smith'}  ; <OREF>
/// do ##class(Py.Helper).pyDictKill(pRequest,"Mname")
/// zw pRequest
/// pRequest=52@%SYS.Python  ; {'Fname': 'Bob', 'Lname': 'Smith'}  ; <OREF>
/// </example>
ClassMethod pyDictKill(ByRef dict As %SYS.Python, key)
{
	// Force key names to strings
	do ..pyDictKillInner(dict,""_key_"")
}

ClassMethod pyDictKillInner(ByRef dict As %SYS.Python, key) [ Language = python, Private ]
{
	del dict[key]
}

/// Convert IRIS array variable to python dictionary
/// Supports Nexted List Nodes as node values where IRIS Lists are converted to python Lists.
/// Where there is a node value AND sub-nodes the node value is given dictionary key "_value"
/// <example>
/// set array=123
/// set array(1)=456
/// set array("ADDRESS",1,"ADD1")="HouseOrFlatNumber"
/// set array("ADDRESS",1,"ADD2")="TownOrCity"
/// set array("ADDRESS",1,"ADD3")="CountyOrRegion"
/// set array("ADDRESS",1,"ADD4")="Country"
/// set array("ADDRESS",1,"ADD5")="ZIPCode"
/// set array("FNAME")="BOB"
/// set array("LNAME")="SMITH"
/// set array("ListTest",1)=$lb(1,2,$lb(3,4,"Five"))
/// set myPyDict=##class(Py.Helper).pyDictFromArray(.array)
/// zw myPyDict
/// myPyDict=46@%SYS.Python  ; {'_value': 123, '1': 456, 'ADDRESS': {1: {'ADD1': 'HouseOrFlatNumber', 'ADD2': 'TownOrCity', 'ADD3': 'CountyOrRegion', 'ADD4': 'Country', 'ADD5': 'ZIPCode'}}, 'FNAME': 'BOB', 'LNAME': 'SMITH', 'ListTest': {1: [1, 2, [3, 4, 'Five']]}}  ; <OREF>
/// </example>
ClassMethod pyDictFromArray(ByRef array, ByRef ret As %SYS.Python = {$$$NULLOREF}, ByRef impBi As %SYS.Python = {##class(%SYS.Python).Import("builtins")}) As %SYS.Python [ ProcedureBlock = 1 ]
{
	if ret=$$$NULLOREF {
		set ret=impBi.dict()
		if $Data(array)#2 {
			do ..pyDictSet(ret,"_value",..toPyListOrString(array,,impBi))  // Value of top node only
		}
	}
	set k1=""
	for {
		set k1=$O(array(k1),+1,data)
		quit:k1=""
		if $D(array(k1))=1 {
			do ..pyDictSet(ret,k1,..toPyListOrString(data,,impBi))
			continue
		}
		set k1dict=impBi.dict()
		do ..pyDictSet(ret,k1,k1dict)  // pre-append dictionary to Key
		if $D(array(k1))=11 {
			do ..pyDictSet(k1dict,"_value",..toPyListOrString(data,,impBi))
		}
		kill subarry
		merge subarry=array(k1)
		do ..pyDictFromArray(.subarry,k1dict,impBi)
	}
	quit ret
}

/// Convert IRIS array variable to python dictionary
/// <example>
/// set tlist=$LB(1,2,3,$LB("A","B","C"))
/// set myPyList=##class(Py.Helper).toPyListOrString(tlist)
/// myPyList=59@%SYS.Python  ; [1, 2, 3, ['A', 'B', 'C']]  ; <OREF>
/// </example>
ClassMethod toPyListOrString(ByRef data, ByRef ret As %SYS.Python = {$$$NULLOREF}, ByRef impBi As %SYS.Python = {##class(%SYS.Python).Import("builtins")}) As %SYS.Python
{
	quit:'$LISTVALID(data) data
	if ret=$$$NULLOREF {
		set ret=impBi.list()
	}
	set listLen=$ListLength(data)
	for i=1:1:listLen {
		set nData=$LG(data,i)
		if '$LISTVALID(nData) {
			do ret.append(nData)
		} else {
			set l1List=impBi.list()
			do ret.append(..toPyListOrString(nData,l1List,impBi))
		}
	}
	quit ret
}

/// Convert Python dictionary to IRIS array
/// <example>
/// USER>zw myPyDict
/// myPyDict=4@%SYS.Python  ; {'_value': 123, '1': 456, 'ADDRESS': {1: {'ADD1': 'HouseOrFlatNumber', 'ADD2': 'TownOrCity', 'ADD3': 'CountyOrRegion', 'ADD4': 'Country', 'ADD5': 'ZIPCode'}}, 'FNAME': 'BOB', 'LNAME': 'SMITH', 'ListTest': {1: [1, 2, [3, 4, 'Five']]}}  ; <OREF>
/// 
/// USER>kill echoArray
/// 
/// USER>do ##class(Py.Helper).ArrayFrompyDict(myPyDict,,.echoArray)
/// 
/// USER>zw echoArray
/// echoArray=123
/// echoArray(1)=456
/// echoArray("ADDRESS",1,"ADD1")="HouseOrFlatNumber"
/// echoArray("ADDRESS",1,"ADD2")="TownOrCity"
/// echoArray("ADDRESS",1,"ADD3")="CountyOrRegion"
/// echoArray("ADDRESS",1,"ADD4")="Country"
/// echoArray("ADDRESS",1,"ADD5")="ZIPCode"
/// echoArray("FNAME")="BOB"
/// echoArray("LNAME")="SMITH"
/// echoArray("ListTest",1)=$lb(1,2,$lb(3,4,"Five"))
/// </example>
ClassMethod ArrayFrompyDict(ByRef pyDict As %SYS.Python = {$$$NULLOREF}, ByRef impBi As %SYS.Python = {##class(%SYS.Python).Import("builtins")}, ByRef array, msgkeys = "") [ ProcedureBlock = 1 ]
{
	quit:'$IsObject(pyDict)
	// Itterate over the keys of the Dictionary
	set dictKeys=impBi.list(pyDict.keys())
	set dictValues=impBi.list(pyDict.values())
	set listLen=impBi.len(dictKeys)
	for i=1:1:listLen {
		kill data
		set key=..pyListGet(i,dictKeys)
		continue:key=""  // Can't use empty string key
		set data=..pyListGet(i,dictValues)
		if $IsObject(data) {
			if ..pyListIs(data) {
				set data=..ListFrompyList(data,impBi)
			} elseif ..pyDictIs(data) {
				kill innerArray
				do ..ArrayFrompyDict(data,impBi,.innerArray,msgkeys_"["_key_"]")
			} else {
				set $ZE="Class "_..%ClassName(1)_" Method ArrayFrompyDict. Unsupported value type """_..pyTypeName(data)_""" at key "_msgkeys_"["_key_"]"
				do BACK^%ETN
			}
		} else {
			set data=..toPyListOrString(data)	
		}
		if key="_value" {
			set array=data	// Strings and Lists
		} elseif $Data(innerArray)>1 {
			merge array(key)=innerArray  // Strings, 
			kill innerArray
		} else {
			set array(key)=data // lists and "sub-array"
		}
	}
	quit
}

/// Convert Python list to IRIS list
/// <example>
/// USER>zw myPyList
/// myPyList=7@%SYS.Python  ; [1, 2, 3, ['A', 'B', 'C']]  ; <OREF>
/// 
/// 
/// </example>
ClassMethod ListFrompyList(ByRef pyList As %SYS.Python = {$$$NULLOREF}, ByRef impBi As %SYS.Python = {##class(%SYS.Python).Import("builtins")}, msgkeys = "") As %SYS.Python [ ProcedureBlock = 1 ]
{
	set ret=$LB()
	// How to get length of list
	set listlen=impBi.len(pyList)
	for i=1:1:listlen {
		set data=##class(Py.Helper).pyListGet(i,pyList)
		// if data is also a list // TODO
		if $IsObject(data) {
			if ..pyListIs(data) {
			  set data=..ListFrompyList(data,impBi,,msgkeys_"["_i_"]")
			} else {
				set $ZE="Class "_..%ClassName(1)_" Method ListFrompyList. Unsupported value type """_..pyTypeName(data)_""" at position "_msgkeys_"["_i_"]"
				do BACK^%ETN	
			}
		}
		// add string / numeric / IRIS LIST to ret
		set ret=$LU(ret,i,data)
	}
	quit ret
}

/// Returns empty string on error
/// position starts at one to keep same as IRIS List
ClassMethod pyListGet(position As %Integer, ByRef pyList As %SYS.Python) As %SYS.Python [ Language = python ]
{
	ret=""
	try:
	  ret=(pyList[position-1])
	except:
	  print("Error in pyListGet")
	  
	return ret
}

ClassMethod pyListIs(ByRef pyList As %SYS.Python) As %SYS.Python [ Language = python ]
{
	return (type(pyList)==list)
}

ClassMethod pyDictIs(ByRef pyDict As %SYS.Python) As %SYS.Python [ Language = python ]
{
	return (type(pyDict)==dict)
}

ClassMethod pyTypeName(obj As %SYS.Python) As %String [ Language = python ]
{
	return type(obj).__name__
}

/// Method to present IRIS return values and output paramters as a tuple.<br/>
/// Consider the following example:
/// <example language="NONE">
/// > import iris
/// > hl7=iris.cls("EnsLib.HL7.Message")._OpenId(145,0)
/// > hl7.GetValueAt("MSH:9.1")
/// 'OUL'
/// </example>
/// Next we try an invalid path:
/// <example language="NONE">
/// > hl7.GetValueAt("<&$BadMSH:9.1")
/// ''
/// </example>
/// The empty value is provided, but we don't know whether the value really was an empty string OR the path had failed.<br/>
/// The GetValueAt method also has an OUTPUT parameter "pStatus" that could inform on the validity of the empty string value.
/// <example language="NONE">
/// > hl7=iris.cls("EnsLib.HL7.Message")._OpenId(145,0)
/// > val, status = iris.cls("alwo.PyHelper").TupleOut(hl7,"GetValueAt",['pStatus'],1,"<&$BadMSH:9.1")
/// > val==''
/// True
/// > iris.cls("%SYSTEM.Status").IsError(status)
/// 1
/// > iris.cls("%SYSTEM.Status").DisplayError(status)
/// ERROR <Ens>ErrGeneral: No segment found at path '<&$BadMSH'1
/// </example>
/// Arguments explained:<ul>
/// <li>objectOrReference - An instance of an iris object OR its classname (including package)</li>
/// <li>methodname - The method name to be called. Note this method can only be an instance method, if an instance was  also passed in for the first argument.</li>
/// <li>namesForOutput - This is a python list of string names corresponding to the specific OUTPUT arguments and the order you wish to return
/// in the tuple. Note, where a method returns a non-null value, the first output is returned as the second tuple item. If there was no return 
/// from the method then the first output item occupies position one.</li>
/// <li>returnsValue - Indicate whether a return value is expected from the method invocation. "1" = Yes, "0" = No</li>
/// <li>args - Optionally one or more arguments. Where there arguments are Python Lists or Python Dictionaries, they will be specially handled
/// to interop with IRIS List and Array types used by methods internally.</li>
/// </ul>
/// <h2>Returning ByRef literal as though Output</h2>
/// Historically internally parameters would be passed By-Reference for "dictionaries" for both input and output
/// The Output directive evolved later and so there is much implementation using ByRef when the API intention was intented for what is now just Output
/// There fore it is useful to be able to access internal ByRef literals as though they has been implemented as accessible Output parameters.
/// Simply include the ByRef parameter name and it will be included in the output Tuple
/// <example language="NONE">
/// > out,tsc=iris.cls("alwo.PyHelper").TupleOut("EnsLib.HL7.Message","%OpenId",['sc'],1,'er145999', 0)
/// > out
/// ''
/// > iris.cls("%SYSTEM.Status").DisplayError(tsc)
/// ERROR #5809: Object to Load not found, class 'EnsLib.HL7.Message', ID 'er145999'1
/// </example>
/// <h2>Support for %objlasterror</h2>
/// In objectscript there is access to percent variables across method scope.
/// There are scenarios where detecting or accessing special variable %objlasterror is useful after calling a CORE or thirdparty API
/// This utility allows implicit access to %objlasterror as though it has been defined as an Output parameter, when invoking methods from Python
/// <example language="NONE">
/// del _objlasterror
/// > out,_objlasterror=iris.cls("alwo.PyHelper").TupleOut("EnsLib.HL7.Message","%OpenId",['%objlasterror'],1,'er145999', 0)
/// 
/// > iris.cls("%SYSTEM.Status").DisplayError(_objlasterror)
/// ERROR #5809: Object to Load not found, class 'EnsLib.HL7.Message', ID 'er145999'1
/// </example>
ClassMethod TupleOut(objectOrReference As %RegisteredObject, methodname, namesForOutput, returnsValue = 1, args...) As %SYS.Python
{
	set implBi=##class(%SYS.Python).Import("builtins")
	
	if $IsObject(objectOrReference) {
		set theclassname=objectOrReference.%ClassName(1)
	} else {
		set theclassname=objectOrReference
	}
	
	// check this and base classes for signature
	do ..getFormalSpec(theclassname,methodname,.formalSpec,.success)
	quit:'success
	
	// the FormalSpec may come from inherited functionality
	
	
	if '$Data(namesForOutput) {
		set namesForOutput=$LB()	
	} elseif $IsObject(namesForOutput) &&("NoneType"=implBi.type(namesForOutput)."__name__") {
		// No output arguments have been requested
		set namesForOutput=$LB()
	} else {
		set namesForOutput=##class(Py.Helper).ListFrompyList(namesForOutput)	
	}
	
	if $Data(args) {
		for i=1:1:args {
			// Strip out the None objects that are passed in to represent undef arg
			if $D(args(i)),$IsObject(args(i)),"NoneType"=implBi.type(args(i))."__name__" kill args(i)
		}
	}
	
	if $D(args(1)) kill item merge item=args(1) do ..unwrapType(.item,.k1,implBi)
	if $D(args(2)) kill item merge item=args(2) do ..unwrapType(.item,.k2,implBi)
	if $D(args(3)) kill item merge item=args(3) do ..unwrapType(.item,.k3,implBi)
	if $D(args(4)) kill item merge item=args(4) do ..unwrapType(.item,.k4,implBi)
	if $D(args(5)) kill item merge item=args(5) do ..unwrapType(.item,.k5,implBi)
	if $D(args(6)) kill item merge item=args(6) do ..unwrapType(.item,.k6,implBi)
	if $D(args(7)) kill item merge item=args(7) do ..unwrapType(.item,.k7,implBi)
	if $D(args(8)) kill item merge item=args(8) do ..unwrapType(.item,.k8,implBi)
	if $D(args(9)) kill item merge item=args(9) do ..unwrapType(.item,.k9,implBi)
	if $D(args(10)) kill item merge item=args(10) do ..unwrapType(.item,.k10,implBi)
	
	// Associate name of item with output
	set argnum=+($O(args(""),-1))
	if formalSpec'="" {
		// if not elipsis ie: "args..."
		if ($P(formalSpec,",")'["...") {
			set itemcount=0
			for i=1:1:$L(formalSpec,",") {
				set name=$P($P(formalSpec,",",i),":")
				// incase there were default value content that included a commas and needs discarding
				continue:name'?1(.1(1"&",1"*").(1"%",1"_")1A,1A).AN  
				set itemcount=itemcount+1
				continue:$E(name)'?1(1"*",1"&")  // only interested in output arguments and ByRef if needed for literal
				set outname($E(name,2,*))=itemcount
				set:argnum<itemcount argnum=itemcount
			}
		}
	}
	
	// Now invoke method
	if $IsObject(objectOrReference) {
		if argnum=1 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1)
			}
		} elseif argnum=2 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2)
			}	
		} elseif argnum=3 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3)
			}	
		} elseif argnum=4 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4)
			}	
		} elseif argnum=5 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5)
			}	
		} elseif argnum=6 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6)
			}	
		} elseif argnum=7 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7)
			}	
		} elseif argnum=8 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8)
			}	
		}  elseif argnum=9 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8,.k9)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8,.k9)
			}	
		}  elseif argnum=10 {
			if 'returnsValue {
				do $ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8,.k9,.k10)
			} else {
				set ret=$ZOBJMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8,.k9,.k10)
			}	
		}
	} else {
		if argnum=1 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1)
			}
		} elseif argnum=2 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2)
			}	
		} elseif argnum=3 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3)
			}	
		} elseif argnum=4 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4)
			}	
		} elseif argnum=5 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5)
			}	
		} elseif argnum=6 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6)
			}	
		} elseif argnum=7 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7)
			}	
		} elseif argnum=8 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8)
			}	
		}  elseif argnum=9 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8,.k9)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8,.k9)
			}	
		}  elseif argnum=9 {
			if 'returnsValue {
				do $CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8,.k9,.k10)
			} else {
				set ret=$CLASSMETHOD(objectOrReference,methodname,.k1,.k2,.k3,.k4,.k5,.k6,.k7,.k8,.k9,.k10)
			}	
		}	
	}
	
	set outlist=implBi.list()
	if $D(ret) {
		kill outret
		do ..wrapType(.ret,.outret,implBi)
		do outlist.append(.outret)
	}
	// Setup turn list of arguments
	if namesForOutput'=$LB() {
		for i=1:1:$LL(namesForOutput) {
			set item=$ZSTRIP($LG(namesForOutput,i),"<>W")
			continue:item=""  // don't send nulls / none in requested list
			if '$Data(outname(item)) {
				if '$Data(outlist) {
					set outlist=$LB() quit	
				} elseif item="%objlasterror" {
					kill outret
					do ..wrapType($G(%objlasterror),.outret,implBi)
					do outlist.append(.outret)
				} else  {
					set outlist=outlist_$LB()
				}
			} else {
				kill outret
				set pos=outname(item)
				if 1=pos {
					do ..wrapType(.k1,.outret,implBi)
					do outlist.append(.outret)
				} elseif 2=pos {
					do ..wrapType(.k2,.outret,implBi)
					do outlist.append(.outret)
				} elseif 3=pos {
					do ..wrapType(.k3,.outret,implBi)
					do outlist.append(.outret)
				} elseif 4=pos {
					do ..wrapType(.k4,.outret,implBi)
					do outlist.append(.outret)
				} elseif 5=pos {
					do ..wrapType(.k5,.outret,implBi)
					do outlist.append(.outret)
				} elseif 6=pos {
					do ..wrapType(.k6,.outret,implBi)
					do outlist.append(.outret)
				} elseif 7=pos {
					do ..wrapType(.k7,.outret,implBi)
					do outlist.append(.outret)
				} elseif 8=pos {
					do ..wrapType(.k8,.outret,implBi)
					do outlist.append(.outret)
				} elseif 9=pos {
					do ..wrapType(.k9,.outret,implBi)
					do outlist.append(.outret)
				} elseif 10=pos {
					do ..wrapType(.k10,.outret,implBi)
					do outlist.append(.outret)
				}
			}
		}
	}
	if ($D(ret))&& (1=implBi.len(outlist)) {
		return outlist.pop()
	} elseif (implBi.len(outlist)>0) {
		return outlist	
	} else {
		return implBi.None
	}
}

ClassMethod unwrapType(ByRef item, ByRef ret, implBi = {##class(%SYS.Python).Import("builtins")}) [ Internal, Private ]
{
	if $IsObject(item) {
		if "dict"=implBi.type(item)."__name__" {
			do ..ArrayFrompyDict(item,implBi,.ret)	
		} elseif implBi.type(item)."__name__"?1(1"list",1"tuple") {
			set ret=..ListFrompyList(item,implBi)
		} elseif "NoneType"=implBi.type(namesForOutput)."__name__" {
			kill ret  // None => ObjectScript Undefined	
		} else {
			set ret=item  // Possibly passing back an IRIS class reference	
		}
	} else {
		set ret=item  // Passing back a primative convert to literal
	}
}

ClassMethod wrapType(ByRef item, ByRef ret, implBi = {##class(%SYS.Python).Import("builtins")}) [ Internal, Private ]
{
	if '$Data(item) {
		do ..getNone(.ret)
	} elseif $Data(item)>1 {
		do ..pyDictFromArray(.item,.ret, implBi)
	} elseif (""'=item)&&($ListValid(item)) {
		do ..toPyListOrString(.item,.ret,.implBi)
	} else {
		set ret=item	
	}
}

ClassMethod getNone(ByRef ret) As %SYS.Python [ Internal, Language = python, Private ]
{
ret=None
}

/// Search a class and its base classes for a method definition
ClassMethod getFormalSpec(classname, method, Output formalSpec As %String, Output success As %Boolean, ByRef checked)
{
	set formalSpec=""
	set success=0
	if ##class(%Dictionary.MethodDefinition).%ExistsId(classname_"||"_method) {
		set tMethod=##class(%Dictionary.MethodDefinition).%OpenId(classname_"||"_method,0)
		if $IsObject(tMethod) {
			set formalSpec=tMethod.FormalSpec
			set success=1
			quit
		}
	}
	#dim tClass as %Dictionary.ClassDefinition=##class(%Dictionary.ClassDefinition).%OpenId(classname,0)
	if '$IsObject(tClass) {
		quit
	}
	set super=$ZSTRIP(tClass.Super,"*W")
	quit:super=""
	for ipiece=1:1:$L(super,",") {
		set superItem=$Piece(super,",",ipiece)
		continue:superItem=""
		if superItem'["." {
			if "%"=$E(superItem) {
				set superItem="%Library."_$E(superItem,2,*)
			} else {
				// copy from parent
				set superItem=$P(classname,".",1,$L(classname,".")-1)_"."_superItem	
			}
		}
		// only test resolve once per base class defintion regardless how many times it might be includes in base tree
		continue:$Data(checked(superItem))
		set checked(superItem)=""
		continue:'##class(%Dictionary.ClassDefinition).%ExistsId(superItem)
		do ..getFormalSpec(superItem,method,.formalSpec,.success)
		quit:success
	}
}

ClassMethod UnpackArgsStopFirstNone(ByRef args, implBi = {##class(%SYS.Python).Import("builtins")}, Output kAry) [ ProcedureBlock = 0 ]
{
	
	kill kAry
	set (stop)=0
	set kAry=$G(args,0)
	
	if $Data(args) {
		for i=1:1:args {
			if stop {
				kill args(i)
				continue	
			}
			// Strip out the None objects that are passed in to represent undef arg
			if $D(args(i)),$IsObject(args(i)),"NoneType"=implBi.type(args(i))."__name__" {
				kill args(i)
				set kAry=i-1
				set stop=1  // No further processing after first None key found
				continue
			}
			if $D(args(i)) {
				kill item,ret merge item=args(i) do ..unwrapType(.item,.ret,implBi) merge kAry(i)=ret
			} else { quit }
		}
	}
	return
}

/// Make quoted arguments for mutidimensional keys access
ClassMethod QuoteKeys(implBi = {##class(%SYS.Python).Import("builtins")}, ByRef kAry)
{
	quit:0=kAry ""
	quit:'$D(kAry(1)) ""
	set ret="("_$$$QUOTE(kAry(1))
	for i=2:1:kAry {
		set ret=ret_","_$$$QUOTE(kAry(i))
	}
	quit ret_")"
}

/// Retrieves a single value if found at path through Multidimensional Property.
/// Returns value or Default<br/>
/// <example>
/// > iris.cls("alwo.PyHelper").MultiGet(stream,"Attributes",None,"Filename")
/// 'text/html'
/// Requesting an undefined key:
/// </example>
/// <example>
/// > iris.cls("alwo.PyHelper").MultiGet(stream,"Attributes",None,"Unknown")
/// None
/// </example>
/// Requesting the whole multidimensional property as dictionary
/// <example>
/// > iris.cls("alwo.PyHelper").MultiGet(shopper,"Basket")
/// {'Fruit': {'apples':10, 'pears':3, 'oranges':4}}
/// </example>
/// Default can be directed to be "None" or other value instead of empty string
/// <example>
/// iris.cls("alwo.PyHelper").MultiGet(shopper,"Basket",None)
/// </example>
ClassMethod MultiGet(object As %RegisteredObject, propertyName, default = "", keys...) As %SYS.Python
{
	
	set implBi=##class(%SYS.Python).Import("builtins")
	set ret=default
	return:'$Data(object) default
	return:'$IsObject(object) default
	return:'$Data(propertyName) default
	
	try {
		do ..unwrapType(.propertyName, .uwPropertyName, implBi)
		return:'$Data(uwPropertyName) default
		return:$LISTVALID(uwPropertyName) default
		return:""=uwPropertyName default
		
		return:'##class(%Dictionary.CompiledProperty).%ExistsId(object.%ClassName(1)_"||"_uwPropertyName) default
		
		do ..UnpackArgsStopFirstNone(.keys,implBi,.kAry)
		set eval="(item,object) set item=object."_uwPropertyName
		set:($G(kAry,0)>0) eval=eval_..QuoteKeys(implBi,.kAry)	
		x (eval, .item, object)
		return:'$Data(item) default
		if $Data(item) k ret d ..wrapType(.item,.ret,implBi)
		
	} catch {
		// For undefined keys
		set ret=default
	}
	return ret
}

/// Assign simple value to Path in Multidimensional Property
/// <example>
/// iris.cls("alwo.PyHelper").MultiSet(stream,"Attributes","text/html","Content-Type")
/// </example>
ClassMethod MultiSet(object As %RegisteredObject, propertyName, value, keys...)
{
	return:'$Data(object)
	return:'$IsObject(object)
	return:'$Data(propertyName)
	set implBi=##class(%SYS.Python).Import("builtins")
	
	try {
		do ..unwrapType(.propertyName, .uwPropertyName, implBi)
		return:'$Data(uwPropertyName)
		return:$LISTVALID(uwPropertyName)
		return:""=uwPropertyName
		
		return:'##class(%Dictionary.CompiledProperty).%ExistsId(object.%ClassName(1)_"||"_uwPropertyName)
		
		do ..UnpackArgsStopFirstNone(.keys,implBi,.kAry)
		
		do ..unwrapType(.value, .uwvalue, implBi)
		
		// set the value
		if (0=kAry) {
			x ("(object,value) s object."_uwPropertyName_"=value", object, value)
		} else {
			X ("(object,value) s object."_uwPropertyName_..QuoteKeys(implBi,.keys)_"=value",object, value)	
		}
		
	} catch {}
}

/// returns List of Key names at path in Multidimensional Property
/// <example>
/// > iris.cls("alwo.PyHelper").MultiKeys(shopper,"Prop1","Fruit")
/// ['apples','pears','oranges']
/// </example>
/// Note that keys automatically sort in Multidimensional properties
ClassMethod MultiKeys(object As %RegisteredObject, propertyName, keys...) As %SYS.Python
{
	set implBi=##class(%SYS.Python).Import("builtins")
	// unpack value
	set ret=implBi.list()
	return:'$IsObject(object) ret
	
	try {
		do ..unwrapType(.propertyName, .uwPropertyName, implBi)
		return:'$Data(uwPropertyName) ret
		return:$LISTVALID(uwPropertyName) ret
		return:""=uwPropertyName ret
		
		return:'##class(%Dictionary.CompiledProperty).%ExistsId(object.%ClassName(1)_"||"_uwPropertyName) ret

		do ..UnpackArgsStopFirstNone(.keys,implBi,.kAry)

		set keyBaseS="(item,object) set item=$Order(object."_uwPropertyName

		if (0=$G(kAry,0)) {
			set eval=keyBaseS_"(item))"  // No keys supplied so $Order on first key
		} else {
			set eval=keyBaseS_($E(..QuoteKeys(implBi,.kAry),1,*-1)_",item))")	
		}
		set item=""
		for {
			X (eval,.item,.object)
			quit:item=""
			do ret.append(item)
		}
	} catch err {}
	return ret
}

/// Replace the whole dictionary
/// <example>
/// > myBasket={'Fruit': {'apples':10, 'pears':3, 'oranges':4}}
/// > iris.cls("alwo.PyHelper").MultiReplace(m,"Things",myBasket)
/// </example>
ClassMethod MultiReplace(object As %RegisteredObject, propertyName, dict = "", keys...)
{
	return:'$IsObject(object)
	set implBi=##class(%SYS.Python).Import("builtins")
	
	try {
		do ..unwrapType(.propertyName, .uwPropertyName, implBi)
		return:'$Data(uwPropertyName)
		return:$LISTVALID(uwPropertyName)
		return:""=uwPropertyName
		
		return:'##class(%Dictionary.CompiledProperty).%ExistsId(object.%ClassName(1)_"||"_uwPropertyName)
		do ..ArrayFrompyDict(dict,implBi,.ary)
		
		do ..UnpackArgsStopFirstNone(.keys,implBi,.kAry)
		
		if kAry=0 {
			x ("(object) k object."_uwPropertyName, object)
		} else {
			x ("(object) k object."_uwPropertyName_..QuoteKeys(implBi,.kAry),object)
		}
		
		return:'$Data(ary)  /// empty array
		if kAry=0 {
			x ("(object,ary) m object."_uwPropertyName_"=ary", object, .ary)
		} else {
			X ("(object,ary) m object."_uwPropertyName_..QuoteKeys(implBi,.kAry)_"=ary",object, .ary)
		}
		
	} catch {}
}

/// Push the additional values into an existing multidimensional property
/// <example>
/// toolbox={'Tools':{'saw':1,'rasp':2,'sandpaper':5}}
/// iris.cls("alwo.PyHelper").MultiMerge(m,"Prop1",toolbox)
/// <example>
ClassMethod MultiMerge(object As %RegisteredObject, propertyName, dict, keys...)
{
	return:'$IsObject(object)
	set implBi=##class(%SYS.Python).Import("builtins")
	
	try {
		do ..unwrapType(.propertyName, .uwPropertyName, implBi)
		return:'$Data(uwPropertyName)
		return:$LISTVALID(uwPropertyName)
		return:""=uwPropertyName
		
		return:'##class(%Dictionary.CompiledProperty).%ExistsId(object.%ClassName(1)_"||"_uwPropertyName)
		do ..ArrayFrompyDict(dict,implBi,.ary)
		return:'$Data(ary)  /// empty array
		
		do ..UnpackArgsStopFirstNone(.keys,implBi,.kAry)
		
		if kAry=0 {
			x ("(object,ary) m object."_uwPropertyName_"=ary", object, .ary)
		} else {
			X ("(object,ary) m object."_uwPropertyName_..QuoteKeys(implBi,.kAry)_"=ary",object, .ary)
		}
	} catch {}
}

/// "del" is python for "kill"
/// <example>
/// import iris
/// m=iris.cls("Test.Example")._New()
/// myBasket={'Fruit': {'apples':10, 'pears':3, 'oranges':4}}
/// toolbox={'Tools':{'saw':1,'rasp':2,'sandpaper':5}}
/// iris.cls("alwo.PyHelper").MultiMerge(m,"Prop1",myBasket)
/// iris.cls("alwo.PyHelper").MultiMerge(m,"Prop1",toolbox)
/// # show two keys "Fruit" and "Tools"
/// iris.cls("alwo.PyHelper").MultiKeys(m,"Prop1")
/// # remove "Fruit" key
/// iris.cls("alwo.PyHelper").MultiDel(m,"Prop1","Fruit")
/// # show keys ['rasp', 'sandpaper', 'saw']
/// iris.cls("alwo.PyHelper").MultiKeys(m,"Prop1","Tools")
/// # remove sub key "saw"
/// iris.cls("alwo.PyHelper").MultiDel(m,"Prop1","Tools","saw")
/// # show sub keys: ['rasp', 'sandpaper']
/// iris.cls("alwo.PyHelper").MultiKeys(m,"Prop1","Tools")
/// </example>
ClassMethod MultiDel(object As %RegisteredObject, propertyName, keys...)
{
	return:'$IsObject(object)
	set implBi=##class(%SYS.Python).Import("builtins")
	
	try {
		do ..unwrapType(.propertyName, .uwPropertyName, implBi)
		return:'$Data(uwPropertyName)
		return:$LISTVALID(uwPropertyName)
		return:$L(uwPropertyName)=0
		
		do ..UnpackArgsStopFirstNone(.keys,implBi,.kAry)
		
		return:'##class(%Dictionary.CompiledProperty).%ExistsId(object.%ClassName(1)_"||"_uwPropertyName)
		if (0=kAry) {
			x ("(object) k object."_uwPropertyName,object)
		} else {
			x ("(object) k object."_uwPropertyName_..QuoteKeys(implBi,.kAry),object)
		}
	} catch {}
}

}

