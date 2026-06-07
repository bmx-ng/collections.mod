SuperStrict

Framework brl.standardio
Import brl.map
Import BRL.MaxUnit

New TTestSuite.run()

Type TPtrMapTest Extends TTest

	Method test() { test }

		Local map:TPtrMap = New TPtrMap

		Local count:Int

		For Local key:TPtrKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "initial empty count")

		map.Insert(Byte Ptr(12345), "One")
		map.Insert(Byte Ptr(2222), "Two")
		map.Insert(Byte Ptr(100), "Three")

		count = 0

		For Local key:TPtrKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(3, count, "count after inserts")

		AssertNotNull(map.ValueForKey(Byte Ptr(12345)))
		AssertNotNull(map.ValueForKey(Byte Ptr(100)))
		AssertNull(map.ValueForKey(Byte Ptr(42)))
		AssertNull(map.ValueForKey(Byte Ptr(900000)))

		AssertTrue(map.Remove(Byte Ptr(2222)), "key removed")
		AssertFalse(map.Remove(Byte Ptr(2222)), "key not found")

		count = 0

		map.Clear()
		map.Clear()

		For Local key:TPtrKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "count after clear")

		map.Insert(Byte Ptr(440000), "Four")

		count = 0

		For Local key:TPtrKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(1, count, "count after insert")

		AssertTrue(map.Remove(Byte Ptr(440000)))

		count = 0

		For Local key:TPtrKey = Eachin map.Keys()
			count :+ 1
		Next

		AssertEquals(0, count, "count after last remove")

	End Method


End Type
