# PyHelper
Extra Python Interop for invocation, arguments and return types

# Install:

IPM (ZPM): install alwo-pyhelper

# TupleOut feature
When accessing IRIS methods from Python there are some useful output parameters that are convenient to also access in addition to a return type.
Consider the following example where we retrieve the text value found at a location in an HL7 message:
```python
> import iris
> hl7=iris.cls("EnsLib.HL7.Message")._OpenId(145,0)
> hl7.GetValueAt("MSH:9.1")
'OUL'
```
As a non-empty value was retuned we can be reasonably confident that the function succeeded as intended.
But what happens if we try an invalid path?
```python
> hl7.GetValueAt("<&$BadMSH:9.1")
''
```
An empty value was returned. However is this empty string valid, OR did something go wrong?
The class in our example, EnsLib.HL7.Message, provides a supporting OUTPUT parameter "pStatus" that will inform on the validity of value being returned.
Using the TupleOut feature we can access both the return value and this method success status in one operation.
```python
> hl7=iris.cls("EnsLib.HL7.Message")._OpenId(145,0)
> val, status = iris.cls("alwo.PyHelper").TupleOut(hl7,"GetValueAt",['pStatus'],1,"<&$BadMSH:9.1")
> val==''
True
> iris.cls("%SYSTEM.Status").IsError(status)
1
> iris.cls("%SYSTEM.Status").DisplayError(status)
ERROR <Ens>ErrGeneral: No segment found at path '<&$BadMSH'1
```

## Arguments explained

 Name | Description
 -----|---------------------------------------------------
 objectOrReference | An instance of an iris object OR its classname (including package)
 methodname | The method name to be called. Note this method can only be an instance method, if an instance was  also passed in for the first argument
 namesForOutput | This is a python list of string names corresponding to the specific OUTPUT arguments and the order you wish to return in the tuple. Note, where a method returns a non-null value, the first output is returned as the second tuple item. If there was no return from the method then the first output item occupies position one.
 returnsValue | Indicate whether a return value is expected from the method invocation. "1" = Yes, "0" = No
 args | Optionally one or more arguments. Where there arguments are Python Lists or Python Dictionaries, they will be specially handled to interop with IRIS List and Array types used by methods internally

# IRIS List and Array to / from Python List and Dictionary
Supporting functions
## ArrayFrompyDict
## ListFrompyList
## toPyListOrString
## pyDictFromArray

