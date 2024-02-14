Class alwo.PyHelper.Test Extends %UnitTest.TestCase
{

Property oMulti As alwo.PyHelper.ExampleMulti;

/// Run by <B>RunTest</B> immediately before each test method in the test class is run.<br>
/// <dl>
/// <dt><i>testname</i>
/// <dd>Name of the test to be run. Required. 
/// </dl> 
Method OnBeforeOneTest(testname As %String) As %Status
{
	set ..oMulti=##class(alwo.PyHelper.ExampleMulti).%New()
	Quit $$$OK
}

Method AssertEquals(args...)
{
	do $$$AssertEquals(args(1),args(2))
}

/// do ##class(%UnitTest.Manager).DebugRunTestCase("","alwo.PyHelper.Test","","pyTestMultiGet")
Method TestMultiGet()
{
	// {'_value': 1, 'A': {'A': 3, 'B': {'_value': 4, 'C': 5}}}
	set ..oMulti.Prop1=1
	set ..oMulti.Prop1("A","A")=3
	set ..oMulti.Prop1("A","B")=4
	set ..oMulti.Prop1("A","B","C")=5
	do ..pyTestMultiGet(..oMulti)
}

Method pyTestMultiGet(m) [ Language = python ]
{
	import iris
	x=iris.cls("alwo.PyHelper").MultiGet(m,"Prop1")
	print(x)
	self.AssertEquals(x,1,None)
	
	x=iris.cls("alwo.PyHelper").MultiGet(m,"Prop1",None,'A','A')
	self.AssertEquals(x,3,None)
	
	x=iris.cls("alwo.PyHelper").MultiGet(m,"Prop1",None,'A','B')
	self.AssertEquals(x,4,None)
	
	x=iris.cls("alwo.PyHelper").MultiGet(m,"Prop1",None,'A','B','C')
	self.AssertEquals(x,5,None)
}

/// do ##class(%UnitTest.Manager).DebugRunTestCase("","alwo.PyHelper.Test","","TestMultiGet2")
Method TestMultiGet2()
{
	// iris.cls("alwo.PyHelper").MultiGet(shopper,"Basket")
	//{'Fruit': {'apples':10, 'pears':3, 'oranges':4}}
	set ..oMulti.Prop1("Fruit","apples")=10
	set ..oMulti.Prop1("Fruit","pears")=3
	set ..oMulti.Prop1("Fruit","oranges")=4
	
	do ..pyTestMultiGet2(..oMulti)
}

Method pyTestMultiGet2(m) [ Language = python ]
{
	import iris
	x=iris.cls("alwo.PyHelper").MultiGet(m,"Prop1",None)
	self.AssertEquals(x,None,None)
	x=iris.cls("alwo.PyHelper").MultiGet(m,"Prop1",None,'Fruit')
	self.AssertEquals(x,None,None)
	
	x=iris.cls("alwo.PyHelper").MultiGet(m,"Prop1",None,'Fruit','apples')
	self.AssertEquals(x,10,None)
	x=iris.cls("alwo.PyHelper").MultiGet(m,"Prop1",None,'Fruit','pears')
	self.AssertEquals(x,3,None)
}

/// do ##class(%UnitTest.Manager).DebugRunTestCase("","alwo.PyHelper.Test","","TestMultiSet")
Method TestMultiSet()
{
	do ..pyTestMultiSet(..oMulti)
	do $$$AssertEquals($G(..oMulti.Prop1),1)
	do $$$AssertEquals($G(..oMulti.Prop1("Fruit")),"")
	do $$$AssertEquals($G(..oMulti.Prop1("Fruit","apples")),9)
	do $$$AssertEquals($G(..oMulti.Prop1("Fruit","pears")),4)
	do $$$AssertEquals($G(..oMulti.Prop1("Fruit","oranges")),5)
}

Method pyTestMultiSet(m) [ Language = python ]
{
	import iris
	iris.cls("alwo.PyHelper").MultiSet(m,"Prop1",1)
	iris.cls("alwo.PyHelper").MultiSet(m,"Prop1",9,"Fruit","apples")
	iris.cls("alwo.PyHelper").MultiSet(m,"Prop1",4,"Fruit","pears")
	iris.cls("alwo.PyHelper").MultiSet(m,"Prop1",5,"Fruit","oranges")
}

/// do ##class(%UnitTest.Manager).DebugRunTestCase("","alwo.PyHelper.Test","","TestMultiKeys")
Method TestMultiKeys()
{
	set ..oMulti.Prop1("Fruit","apples")=10
	set ..oMulti.Prop1("Fruit","pears")=3
	set ..oMulti.Prop1("Fruit","oranges")=4
	
	do ..pyTestMultiKeys(..oMulti)
}

Method pyTestMultiKeys(m) [ Language = python ]
{
	import iris
	x=iris.cls("alwo.PyHelper").MultiKeys(m,"Prop1","Fruit")
	self.AssertEquals(len(x),3,None)
	self.AssertEquals(x[0],'apples',None)
	self.AssertEquals(x[2],'pears',None)
	self.AssertEquals(x[1],'oranges',None)
}

/// do ##class(%UnitTest.Manager).DebugRunTestCase("","alwo.PyHelper.Test","","TestMultiReplace")
Method TestMultiReplace()
{
	set ..oMulti.Prop1("Fruit","apples")=23
	set ..oMulti.Prop1("Fruit","pears")=12
	set ..oMulti.Prop1("Fruit","oranges")=14
	
	do ..pyTestMultiReplace(..oMulti)
	
	do $$$AssertEquals($D(..oMulti.Prop1("Fruit")),0)
	do $$$AssertEquals($D(..oMulti.Prop1("Tools")),10)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","saw")),1)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","hammer")),2)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","screws")),38)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","nails")),46)
	
	kill ..oMulti.Prop1
	set ..oMulti.Prop1("Tools","mallet")=1
	set ..oMulti.Prop1("Tools","spanner")=2
	set ..oMulti.Prop1("Tools","screwdriver")=3
	do ..pyTestMultiReplace2(..oMulti)
	
	do $$$AssertEquals($D(..oMulti.Prop1("Fruit")),0)
	do $$$AssertEquals($D(..oMulti.Prop1("Tools")),10)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","saw")),1)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","hammer")),2)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","screws")),38)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","nails")),46)
	
	do $$$AssertEquals(+$G(..oMulti.Prop1("Tools","mallet")),0)
	do $$$AssertEquals(+$G(..oMulti.Prop1("Tools","spanner")),0)
	do $$$AssertEquals(+$G(..oMulti.Prop1("Tools","screwdriver")),0)
}

Method pyTestMultiReplace(m) [ Language = python ]
{
	import iris
	x={'Tools':{'saw':1,'hammer':2,'screws':38,'nails':46}}
	iris.cls("alwo.PyHelper").MultiReplace(m,"Prop1",x)
}

Method pyTestMultiReplace2(m) [ Language = python ]
{
	import iris
	x={'saw':1,'hammer':2,'screws':38,'nails':46}
	iris.cls("alwo.PyHelper").MultiReplace(m,"Prop1",x,"Tools")
}

/// do ##class(%UnitTest.Manager).DebugRunTestCase("","alwo.PyHelper.Test","","TestMultiMerge")
Method TestMultiMerge()
{
	// Attach to root
	set ..oMulti.Prop1("Fruit","apples")=23
	set ..oMulti.Prop1("Fruit","pears")=12
	set ..oMulti.Prop1("Fruit","oranges")=14
	
	do ..pyTestMultiMerge(..oMulti)
	
	do $$$AssertEquals($D(..oMulti.Prop1("Fruit")),10)
	do $$$AssertEquals($G(..oMulti.Prop1("Fruit","apples")),23)
	do $$$AssertEquals($G(..oMulti.Prop1("Fruit","pears")),12)
	do $$$AssertEquals($G(..oMulti.Prop1("Fruit","oranges")),14)
	do $$$AssertEquals($D(..oMulti.Prop1("Tools")),10)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","saw")),1)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","hammer")),2)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","screws")),38)
	do $$$AssertEquals($G(..oMulti.Prop1("Tools","nails")),46)
	
	// Attach to sub-key
	Kill ..oMulti.Prop1
	set ..oMulti.Prop1("Items","Fruit","apples")=23
	set ..oMulti.Prop1("Items","Fruit","pears")=12
	set ..oMulti.Prop1("Items","Fruit","oranges")=14
	
	do ..pyTestMultiMerge2(..oMulti)
	
	do $$$AssertEquals($D(..oMulti.Prop1("Items","Fruit")),10)
	do $$$AssertEquals($G(..oMulti.Prop1("Items","Fruit","apples")),23)
	do $$$AssertEquals($G(..oMulti.Prop1("Items","Fruit","pears")),12)
	do $$$AssertEquals($G(..oMulti.Prop1("Items","Fruit","oranges")),14)
	do $$$AssertEquals($D(..oMulti.Prop1("Items","Tools")),10)
	do $$$AssertEquals($G(..oMulti.Prop1("Items","Tools","saw")),1)
	do $$$AssertEquals($G(..oMulti.Prop1("Items","Tools","hammer")),2)
	do $$$AssertEquals($G(..oMulti.Prop1("Items","Tools","screws")),38)
	do $$$AssertEquals($G(..oMulti.Prop1("Items","Tools","nails")),46)
}

Method pyTestMultiMerge(m) [ Language = python ]
{
	import iris
	x={'Tools':{'saw':1,'hammer':2,'screws':38,'nails':46}}
	iris.cls("alwo.PyHelper").MultiMerge(m,"Prop1",x)
}

Method pyTestMultiMerge2(m) [ Language = python ]
{
	import iris
	x={'saw':1,'hammer':2,'screws':38,'nails':46}
	iris.cls("alwo.PyHelper").MultiMerge(m,"Prop1",x,"Items","Tools")
}

/// do ##class(%UnitTest.Manager).DebugRunTestCase("","alwo.PyHelper.Test","","TestMultiDel")
Method TestMultiDel()
{
	set ..oMulti.Prop1("Items","Fruit","apples")=23
	set ..oMulti.Prop1("Items","Fruit","pears")=12
	set ..oMulti.Prop1("Items","Fruit","oranges")=14
	
	do ..pyTestMultiDel(..oMulti)
	
	do $$$AssertEquals($D(..oMulti.Prop1),0)
	
	set ..oMulti.Prop1("Items","Fruit","apples")=23
	set ..oMulti.Prop1("Items","Fruit","pears")=12
	set ..oMulti.Prop1("Items","Fruit","oranges")=14
	set ..oMulti.Prop1("Items","Tools","mallet")=1
	set ..oMulti.Prop1("Items","Tools","spanner")=2
	set ..oMulti.Prop1("Items","Tools","screwdriver")=3
	
	do ..pyTestMultiDel2(..oMulti)
	do $$$AssertEquals($D(..oMulti.Prop1("Items","Fruit")),0)
	do $$$AssertEquals($D(..oMulti.Prop1("Items","Tools")),10)
}

Method pyTestMultiDel(m) [ Language = python ]
{
	import iris
	iris.cls("alwo.PyHelper").MultiDel(m,"Prop1")
}

Method pyTestMultiDel2(m) [ Language = python ]
{
	import iris
	iris.cls("alwo.PyHelper").MultiDel(m,"Prop1","Items","Fruit")
}

}

