SuperStrict

Framework brl.standardio
Import collections.objectmap
Import BRL.MaxUnit

New TTestSuite.run()

Type TObj
	Field value:Int
	Method New(value:Int)
		Self.value = value
	End Method

	Method Compare:Int(other:Object)
		Local obj:TObj = TObj(other)
		If Not obj Then
			Return -1
		End If
		If value < obj.value Then
			Return -1
		Else if value > obj.value Then
			Return 1
		End If
		Return 0
	End Method
End Type

Type TObjectMapTest Extends TTest

	Method test() { test }

		Local map:TObjectMap = New TObjectMap

		Local count:Int

		For Local key:Object = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "initial empty count")

		Local obj1:TObj = New TObj(1)
		Local obj2:TObj = New TObj(2)
		Local s3:String = "three"
		Local obj4:TObj = New TObj(4)
		Local obj1a:TObj = New TObj(1)

		Local obj11:TObj = New TObj(11)
		Local obj12:TObj = New TObj(12)

		map.Insert(obj1, "One")
		map.Insert(obj2, "Two")
		map.Insert(s3, "Three") ' mixed objects/Strings

		count = 0

		For Local key:Object = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(3, count, "count after inserts")

		AssertNotNull(map.ValueForKey(obj1))
		AssertNotNull(map.ValueForKey(obj1a)) ' different obj same compare
		AssertNotNull(map.ValueForKey("three"))
		AssertNull(map.ValueForKey(obj11))
		AssertNull(map.ValueForKey(obj12))

		AssertTrue(map.Remove(obj2), "key removed")
		AssertFalse(map.Remove(obj2), "key not found")

		count = 0

		map.Clear()

		For Local key:Object = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "count after clear")

		map.Clear() ' multiple cleans are ok

		map.Insert(obj4, "Four")

		count = 0

		For Local key:Object = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(1, count, "count after insert")

		AssertTrue(map.Remove(obj4))

		count = 0

		For Local key:Object = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "count after last remove")

	End Method

End Type
