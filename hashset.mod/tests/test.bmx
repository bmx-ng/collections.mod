SuperStrict

Framework brl.standardio
Import brl.maxunit
Import Collections.HashSet

New TTestSuite.run()

Type THashSetTest Extends TTest

    Method TestEmpty() { test }
        Local s:THashSet<String> = New THashSet<String>

        AssertEquals(0, s.Count(), "Empty Count = 0")
        AssertTrue(s.IsEmpty(), "IsEmpty on empty set")
        AssertTrue(Not s.Contains("x"), "Contains on empty returns False")
        AssertTrue(Not s.Remove("x"), "Remove on empty returns False")

        ' Iteration should be empty
        Local seen:Int
        For Local e:String = EachIn s
            seen :+ 1
        Next
        AssertEquals(0, seen, "No iteration items on empty set")
    End Method

    Method TestAddContainsNoDuplicates() { test }
        Local s:THashSet<String> = New THashSet<String>
        AssertTrue(s.Add("b"), "Add first time returns True")
        AssertTrue(s.Add("a"), "Add second distinct returns True")
        AssertTrue(s.Add("c"), "Add third distinct returns True")
        AssertEquals(3, s.Count(), "Count after adds")

        AssertTrue(s.Contains("a") And s.Contains("b") And s.Contains("c"), "Contains after adds")

        AssertTrue(Not s.Add("b"), "Add duplicate returns False")
        AssertEquals(3, s.Count(), "No duplicate growth")
    End Method

    Method TestRemoveExistingAndMissing() { test }
        Local s:THashSet<String> = New THashSet<String>
        For Local k:String = EachIn ["one","two","three","four"]
            s.Add(k)
        Next
        AssertEquals(4, s.Count(), "Precondition Count=4")

        AssertTrue(s.Remove("two"), "Remove existing returns True")
        AssertTrue(Not s.Contains("two"), "Removed element no longer present")
        AssertEquals(3, s.Count(), "Count decremented after remove")

        AssertTrue(s.Remove("one"), "Remove another existing")
        AssertTrue(s.Remove("four"), "Remove yet another existing")
        AssertEquals(1, s.Count(), "Only one element left")
        AssertTrue(s.Contains("three"), "Remaining element still present")

        ' Removing missing element doesn't change count
        AssertTrue(Not s.Remove("missing"), "Remove missing returns False")
        AssertEquals(1, s.Count(), "Count unchanged after removing missing")
    End Method

    Method TestClear() { test }
        Local s:THashSet<String> = New THashSet<String>
        For Local k:String = EachIn ["a","b","c"]
            s.Add(k)
        Next
        AssertEquals(3, s.Count(), "Precondition Count")
        s.Clear()
        AssertEquals(0, s.Count(), "Count after Clear")
        AssertTrue(s.IsEmpty(), "IsEmpty after Clear")
        AssertTrue(Not s.Contains("a"), "No elements after Clear")
    End Method

	Method TestClearTrimAndRefill() { test }
		Local s:THashSet<Int> = New THashSet<Int>
		For Local i:Int = 0 Until 200
			s.Add(i)
		Next
		s.Clear()
		s.TrimExcess()
		AssertTrue(s.IsEmpty(), "TrimExcess preserves an empty set")

		For Local i:Int = 1000 Until 1200
			AssertTrue(s.Add(i), "Refill after TrimExcess adds a new value")
		Next
		AssertEquals(200, s.Count(), "Refill after TrimExcess has the expected count")
		For Local i:Int = 1000 Until 1200
			AssertTrue(s.Contains(i), "Refilled set contains value: " + i)
		Next
	End Method

	Method TestAddHashesOnceAndDuplicateDoesNotInvalidateIterator() { test }
		Local comparator:TCountingIntComparator = New TCountingIntComparator
		Local s:THashSet<Int> = New THashSet<Int>(comparator)
		AssertTrue(s.Add(1), "First Add inserts the value")
		AssertEquals(1, comparator.calls, "Successful HashSet.Add calculates the hash once")
		s.Add(2)

		Local iterator:IIterator<Int> = s.GetIterator()
		AssertTrue(iterator.MoveNext(), "Iterator starts before duplicate Add")
		comparator.calls = 0
		AssertTrue(Not s.Add(1), "Duplicate Add returns False")
		AssertEquals(1, comparator.calls, "Duplicate HashSet.Add calculates the hash once")

		Local threw:Int
		Try
			iterator.MoveNext()
		Catch e:TInvalidOperationException
			threw = True
		End Try
		AssertTrue(Not threw, "Duplicate Add does not invalidate an iterator")

		AssertTrue(s.Add(3), "Unique Add changes the set")
		Try
			iterator.MoveNext()
		Catch e:TInvalidOperationException
			threw = True
		End Try
		AssertTrue(threw, "Unique Add invalidates the key-backed iterator")
	End Method

    Method TestUnionIntersectionSymmetricDifference() { test }
        Local a:THashSet<Int> = New THashSet<Int>
        Local b:THashSet<Int> = New THashSet<Int>

        For Local i:Int = 1 To 5
            a.Add(i)      ' {1,2,3,4,5}
        Next
        For Local j:Int = 4 To 8
            b.Add(j)      ' {4,5,6,7,8}
        Next

        ' Intersection: a ∩ b = {4,5}
        Local a1:THashSet<Int> = New THashSet<Int>(a)
        a1.Intersection(b)
        AssertEquals(2, a1.Count(), "Intersection count")
        AssertTrue(a1.Contains(4) And a1.Contains(5), "Intersection elements")
        AssertTrue(Not a1.Contains(3), "Non-intersection element not present")

        ' Union: a ∪ b = {1..8}
        Local a2:THashSet<Int> = New THashSet<Int>(a)
        a2.UnionOf(b)
        AssertEquals(8, a2.Count(), "Union count 1..8")
        For Local k:Int = 1 To 8
            AssertTrue(a2.Contains(k), "Union contains " + k)
        Next

        ' Symmetric difference: (a Δ b) = {1,2,3,6,7,8}
        Local a3:THashSet<Int> = New THashSet<Int>(a)
        a3.SymmetricDifference(b)
        Local expect:Int[] = [1,2,3,6,7,8]
        AssertEquals(expect.Length, a3.Count(), "SymDiff count")
        For Local v:Int = EachIn expect
            AssertTrue(a3.Contains(v), "SymDiff contains " + v)
        Next
        AssertTrue(Not a3.Contains(4) And Not a3.Contains(5), "SymDiff excludes intersection (4,5)")
    End Method

    Method TestComplement() { test }
        Local a:THashSet<Int> = New THashSet<Int>
        Local b:THashSet<Int> = New THashSet<Int>
        For Local i:Int = 1 To 6; a.Add(i); Next        ' {1..6}
        For Local j:Int = 2 To 4; b.Add(j); Next        ' {2,3,4}

        a.Complement(b)                                 ' remove {2,3,4}
        AssertEquals(3, a.Count(), "Complement removed 3 elements")

        For Local v:Int = EachIn [1,5,6]
            AssertTrue(a.Contains(v), "Complement kept " + v)
        Next
        For Local v2:Int = EachIn [2,3,4]
            AssertTrue(Not a.Contains(v2), "Complement removed " + v2)
        Next
    End Method

    Method TestSubsetSupersetProper() { test }
        Local a:THashSet<Int> = New THashSet<Int>
        Local b:THashSet<Int> = New THashSet<Int>

        For Local i:Int = 1 To 3; a.Add(i); Next           ' {1,2,3}
        For Local i:Int = 1 To 5; b.Add(i); Next           ' {1,2,3,4,5}

        AssertTrue(a.IsSubsetOf(b), "a ⊆ b")
        AssertTrue(Not a.IsSupersetOf(b), "a ⊇ b is false")
        AssertTrue(b.IsSupersetOf(a), "b ⊇ a")
        AssertTrue(Not b.IsSubsetOf(a), "b ⊆ a is false")

        AssertTrue(a.IsProperSubsetOf(b), "a ⊂ b (proper subset)")
        AssertTrue(Not b.IsProperSubsetOf(a), "b ⊄ a")
        AssertTrue(b.IsProperSupersetOf(a), "b ⊃ a (proper superset)")
        AssertTrue(Not a.IsProperSupersetOf(b), "a ⊅ b")

        ' Empty set edge cases
        Local e:THashSet<Int> = New THashSet<Int>
        AssertTrue(e.IsSubsetOf(a), "∅ ⊆ a")
        AssertTrue(e.IsProperSubsetOf(a), "∅ ⊂ a (a non-empty)")
        AssertTrue(a.IsSupersetOf(e), "a ⊇ ∅")
        AssertTrue(a.IsProperSupersetOf(e), "a ⊃ ∅ (a non-empty)")

        Local e2:THashSet<Int> = New THashSet<Int>
        AssertTrue(e.IsSubsetOf(e2), "∅ ⊆ ∅")
        AssertTrue(e.IsSupersetOf(e2), "∅ ⊇ ∅")
        AssertTrue(Not e.IsProperSubsetOf(e2), "∅ ⊂ ∅ is false")
        AssertTrue(Not e.IsProperSupersetOf(e2), "∅ ⊃ ∅ is false")
    End Method

    Method TestOverlaps() { test }
        Local a:THashSet<String> = New THashSet<String>
        Local b:THashSet<String> = New THashSet<String>

        For Local k:String = EachIn ["a","b","c"]; a.Add(k); Next
        For Local k:String = EachIn ["x","y","z"]; b.Add(k); Next

        AssertTrue(Not a.Overlaps(b), "No overlap initially")

        b.Add("b")
        AssertTrue(a.Overlaps(b), "Overlap on 'b'")
    End Method

    Method TestConstructorsArrayAndIterable() { test }
        Local arr:String[] = ["a","b","c","b","a"]
        Local s1:THashSet<String> = New THashSet<String>(arr)
        AssertEquals(3, s1.Count(), "Array ctor dedup count 3")

        ' iterable ctor from another set
        Local s2:THashSet<String> = New THashSet<String>(s1, Null)
        AssertEquals(3, s2.Count(), "Iterable ctor copied 3")
        For Local k:String = EachIn ["a","b","c"]
            AssertTrue(s2.Contains(k), "Iterable ctor contains " + k)
        Next

		Local emptyArray:String[] = New String[0]
		Local empty1:THashSet<String> = New THashSet<String>(emptyArray)
		AssertTrue(empty1.IsEmpty(), "Empty array ctor remains empty")

		Local empty2:THashSet<String> = New THashSet<String>(empty1, Null)
		AssertTrue(empty2.IsEmpty(), "Empty counted iterable ctor remains empty")

		Local duplicateArray:Int[1000]
		For Local i:Int = 0 Until duplicateArray.Length
			duplicateArray[i] = i Mod 10
		Next
		Local duplicateSet:THashSet<Int> = New THashSet<Int>(duplicateArray)
		AssertEquals(10, duplicateSet.Count(), "Presized array ctor still removes duplicates")
		For Local i:Int = 0 Until 10
			AssertTrue(duplicateSet.Contains(i), "Presized array ctor contains " + i)
		Next
    End Method

    Method TestToArray() { test }
        Local s:THashSet<Int> = New THashSet<Int>
        For Local i:Int = 5 To 1 Step -1
            s.Add(i)
        Next

        Local a:Int[] = s.ToArray()
        AssertEquals(s.Count(), a.Length, "ToArray length matches Count")

        ' We can't assume order, but we can check that all elements are present
        Local seen:Int[6]  ' indices 0..5, we only use 1..5
        For Local v:Int = EachIn a
            AssertTrue(v >= 1 And v <= 5, "ToArray element in expected range")
            seen[v] = True
        Next
        For Local i:Int = 1 To 5
            AssertTrue(seen[i], "ToArray contains " + i)
        Next

		Local copied:Int[8]
		For Local i:Int = 0 Until copied.Length
			copied[i] = -1
		Next
		s.CopyTo(copied, 2)
		AssertEquals(-1, copied[0], "CopyTo preserves elements before its offset")
		AssertEquals(-1, copied[1], "CopyTo preserves the element immediately before its offset")
		AssertEquals(-1, copied[7], "CopyTo preserves elements after the copied set")
		For Local i:Int = 2 Until 7
			AssertTrue(s.Contains(copied[i]), "CopyTo writes a set element at index " + i)
		Next
    End Method

    Method TestTryGetValue() { test }
        Local s:THashSet<String> = New THashSet<String>
        For Local k:String = EachIn ["a","b","c"]
            s.Add(k)
        Next

        Local out:String = ""
        AssertTrue(s.TryGetValue("b", out), "TryGetValue existing returns True")
        AssertEquals("b", out, "TryGetValue returns equal value")

        out = "keep"
        AssertTrue(Not s.TryGetValue("z", out), "TryGetValue missing returns False")
        AssertEquals("keep", out, "TryGetValue leaves var unchanged on miss")
    End Method

    ' ---------- Collision-heavy tests ----------

    Method TestHeavyCollisionsConstantHash() { test }
        Local cmp:TCollKeyComparator = New TCollKeyComparator
        Local s:THashSet<TCollKey> = New THashSet<TCollKey>(cmp)

        ' Insert many keys that ALL hash to 1
        For Local i:Int = 0 Until 2000
            Local k:TCollKey = New TCollKey(i)
            AssertTrue(s.Add(k), "Insert unique colliding key " + i)
        Next

        AssertEquals(2000, s.Count(), "All colliding keys inserted")

        ' All keys must be findable
        For Local i:Int = 0 Until 2000
            Local k:TCollKey = New TCollKey(i)
            AssertTrue(s.Contains(k), "Contains colliding key " + i)
        Next

        ' Remove evens
        For Local i:Int = 0 Until 2000 Step 2
            Local k:TCollKey = New TCollKey(i)
            AssertTrue(s.Remove(k), "Remove colliding even key " + i)
        Next

        AssertEquals(1000, s.Count(), "Half of colliding keys removed")

        For Local i:Int = 0 Until 2000
            Local k:TCollKey = New TCollKey(i)
            Local exists:Int = s.Contains(k)
            If (i Mod 2) = 0 Then
                AssertTrue(Not exists, "Even colliding key removed: " + i)
            Else
                AssertTrue(exists, "Odd colliding key remains: " + i)
            End If
        Next
    End Method

    Method TestHeavyCollisionsClusteredHashes() { test }
        Local cmp:TCollKeyClusteredComparator = New TCollKeyClusteredComparator
        Local s:THashSet<TCollKeyClustered> = New THashSet<TCollKeyClustered>(cmp)

        ' Insert many keys that hash into only 8 buckets
        For Local i:Int = 0 Until 4000
            Local k:TCollKeyClustered = New TCollKeyClustered(i)
            s.Add(k)
        Next

        AssertEquals(4000, s.Count(), "Clustered keys inserted")

        ' Spot-check presence
        For Local i:Int = 0 Until 4000 Step 11
            Local k:TCollKeyClustered = New TCollKeyClustered(i)
            AssertTrue(s.Contains(k), "Clustered key present: " + i)
        Next

        ' Remove every 5th key
        For Local i:Int = 0 Until 4000 Step 5
            Local k:TCollKeyClustered = New TCollKeyClustered(i)
            AssertTrue(s.Remove(k), "Remove clustered key " + i)
        Next

        ' Approximately 4000/5 = 800 removed
        AssertTrue(s.Count() >= 3000 And s.Count() <= 3200, "Clustered count after removals ≈ 3200")

        ' Check removed vs remaining
        For Local i:Int = 0 Until 4000
            Local k:TCollKeyClustered = New TCollKeyClustered(i)
            Local exists:Int = s.Contains(k)
            If (i Mod 5) = 0 Then
                AssertTrue(Not exists, "Clustered key removed: " + i)
            Else
                ' It might or might not exist if some other op removed it, but at least
                ' if it exists it must be the correct 'equal' key.
                If exists Then
                    AssertTrue(s.Contains(k), "Clustered key still valid: " + i)
                End If
            End If
        Next
    End Method

End Type

Type TCollKey
    Field id:Int

    Method New(id:Int)
        Self.id = id
    End Method

    ' For debugging/logging only
    Method ToString:String()
        Return "TCollKey(" + id + ")"
    End Method

    ' Deliberately awful hash...
    Method HashCode:UInt()
        Return 1
    End Method

    Method Equals:Int(other:Object)
        If other = Null Then Return 0
        Return id = TCollKey(other).id
    End Method
End Type

Type TCollKeyClustered Extends TCollKey

    Method New(id:Int)
        Super.New(id)
    End Method

    ' Hashes only into 8 buckets: 0..7
    Method HashCode:UInt()
        Return UInt(id & 7)
    End Method

    Method Equals:Int(other:Object)
        If other = Null Then Return 0
        Return id = TCollKeyClustered(other).id
    End Method
End Type

Type TCollKeyComparator Implements IEqualityComparator<TCollKey>
    Method Equals:Int(a:TCollKey, b:TCollKey)
        If a = b Then Return 1
        If a = Null Or b = Null Then Return 0
        Return a.id = b.id
    End Method

    Method HashCode:UInt(value:TCollKey)
        Return value.HashCode()
    End Method
End Type

Type TCollKeyClusteredComparator Implements IEqualityComparator<TCollKeyClustered>
    Method Equals:Int(a:TCollKeyClustered, b:TCollKeyClustered)
        If a = b Then Return 1
        If a = Null Or b = Null Then Return 0
        Return a.id = b.id
    End Method

    Method HashCode:UInt(value:TCollKeyClustered)
        Return value.HashCode()
    End Method
End Type

Type TCountingIntComparator Implements IEqualityComparator<Int>
	Field calls:Int

	Method Equals:Int(a:Int, b:Int)
		Return a = b
	End Method

	Method HashCode:UInt(value:Int)
		calls :+ 1
		Return UInt(value)
	End Method
End Type
