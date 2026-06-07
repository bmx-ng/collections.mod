SuperStrict

Framework brl.standardio
Import collections.intmap
Import BRL.MaxUnit

New TTestSuite.run()

Type TIntMapTest Extends TTest

	Method test() { test }

		Local map:TIntMap = New TIntMap

		Local count:Int

		For Local key:TIntKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "initial empty count")

		map.Insert(1, "One")
		map.Insert(-1, "Two")
		map.Insert($7fffffff, "Three")

		count = 0

		For Local key:TIntKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(3, count, "count after inserts")

		AssertNotNull(map.ValueForKey($7fffffff))
		AssertNotNull(map.ValueForKey(-1))
		AssertNull(map.ValueForKey(0))
		AssertNull(map.ValueForKey(2))

		AssertTrue(map.Remove($7fffffff), "key removed")
		AssertFalse(map.Remove($7fffffff), "key not found")

		count = 0

		map.Clear()
		map.Clear()

		For Local key:TIntKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "count after clear")

		map.Insert(4, "Four")

		count = 0

		For Local key:TIntKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(1, count, "count after insert")

		AssertTrue(map.Remove(4))

		count = 0

		For Local key:TIntKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "count after last remove")

	End Method

End Type

