SuperStrict

Framework brl.standardio
Import brl.maxunit
Import Collections.TreeSet


New TTestSuite.run()

Type TReverseStringComparator Implements IComparator<String>
    Method Compare:Int(a:String, b:String)
        If a = b Then Return 0
        If a > b Then Return -1
        Return 1
    End Method
End Type

Type TTreeSetTest Extends TTest

	' ---------- Basics ----------
	Method TestEmpty() { test }
		Local s:TTreeSet<String> = New TTreeSet<String>
		AssertEquals(0, s.Count(), "Empty Count = 0")
		AssertTrue(s.IsEmpty(), "IsEmpty on empty set")
		AssertTrue(Not s.Contains("x"), "Contains on empty returns False")
		AssertTrue(Not s.Remove("x"), "Remove on empty returns False")

		' TryGetValue should return False and leave var unchanged
		Local out:String = "unchanged"
		AssertTrue(Not s.TryGetValue("x", out), "TryGetValue missing returns False")
		AssertEquals("unchanged", out, "TryGetValue leaves out var unchanged")
		
		' Iteration should be empty
		Local seen:Int = 0
		For Local e:String = EachIn s
			seen :+ 1
		Next
		AssertEquals(0, seen, "No iteration items on empty set")
	End Method

	Method TestAddContainsNoDuplicates() { test }
		Local s:TTreeSet<String> = New TTreeSet<String>
		AssertTrue(s.Add("b"), "Add first time returns True")
		AssertTrue(s.Add("a"), "Add second distinct returns True")
		AssertTrue(s.Add("c"), "Add third distinct returns True")
		AssertEquals(3, s.Count(), "Count after adds")
		AssertTrue(s.Contains("a") And s.Contains("b") And s.Contains("c"), "Contains after adds")
		AssertTrue(Not s.Add("b"), "Add duplicate returns False")
		AssertEquals(3, s.Count(), "No duplicate growth")
	End Method

	' ---------- Removal ----------
	Method TestRemoveVariants() { test }
		Local s:TTreeSet<String> = New TTreeSet<String>
		' Build a small shape that tends to exercise leaf/one-child/two-children
		For Local k:String = EachIn ["b","a","d","c","e"]
			s.Add(k)
		Next
		AssertEquals(5, s.Count(), "Precondition Count=5")

		' Remove leaf (likely "a")
		AssertTrue(s.Remove("a"), "Remove leaf returns True")
		AssertTrue(Not s.Contains("a"), "Leaf removed")
		AssertEquals(4, s.Count(), "Count after leaf removal")

		' Remove node with one child (likely "d")
		AssertTrue(s.Remove("d"), "Remove one-child returns True")
		AssertTrue(Not s.Contains("d"), "One-child removed")
		AssertEquals(3, s.Count(), "Count after one-child removal")

		' Remove node with two children (likely "b")
		AssertTrue(s.Remove("b"), "Remove two-children returns True")
		AssertTrue(Not s.Contains("b"), "Two-children removed")
		AssertEquals(2, s.Count(), "Count after two-children removal")

		' Remaining should be sorted ascending: c, e
		Local expect:String[] = ["c","e"]
		Local i:Int = 0
		For Local e:String = EachIn s
			AssertEquals(expect[i], e, "In-order after removals")
			i :+ 1
		Next
	End Method

	' ---------- Order / iteration ----------
	Method TestIterationOrderSorted() { test }
		Local s:TTreeSet<String> = New TTreeSet<String>
		For Local k:String = EachIn ["j","a","m","b","l","i","z","x","c","k"]
			s.Add(k)
		Next
		Local prev:String = Null
		For Local e:String = EachIn s
			If prev <> Null Then
				AssertTrue(prev <= e, "Monotonic non-decreasing iteration order")
			End If
			prev = e
		Next
		AssertEquals(10, s.Count(), "Count after bulk adds (no dups)")
	End Method

	' ---------- TryGetValue ----------
	Method TestTryGetValue() { test }
		Local s:TTreeSet<String> = New TTreeSet<String>
		For Local k:String = EachIn ["a","b","c"]
			s.Add(k)
		Next

		Local out:String = ""
		AssertTrue(s.TryGetValue("b", out), "TryGetValue existing returns True")
		AssertEquals("b", out, "TryGetValue returns equal stored value")

		out = "keep"
		AssertTrue(Not s.TryGetValue("z", out), "TryGetValue missing returns False")
		AssertEquals("keep", out, "TryGetValue leaves var unchanged for missing")
	End Method

	' ---------- Views ----------
	Method TestViewBetweenAndMutability() { test }
		Local s:TTreeSet<String> = New TTreeSet<String>
		For Local k:String = EachIn ["a","b","c","d","e","f"]
			s.Add(k)
		Next

		Local sub:TTreeSet<String> = s.ViewBetween("b","d") ' expect b,c,d
		' Read via view
		Local seen:String[] = []
		For Local e:String = EachIn sub
			seen :+ [e]
		Next
		AssertEquals(3, seen.Length, "Subset size b..d inclusive is 3")
		AssertEquals("b", seen[0], "Subset[0]=b")
		AssertEquals("c", seen[1], "Subset[1]=c")
		AssertEquals("d", seen[2], "Subset[2]=d")

		' Mutate through view: remove "c"
		AssertTrue(sub.Remove("c"), "Remove via view")
		AssertTrue(Not s.Contains("c"), "Underlying set reflects view removal")

		' Removing outside the view via the view should fail or be no-op.
		' We only require: removing "a" from s should still work, and view should remain consistent.
		AssertTrue(s.Remove("a"), "Remove outside of view via main set")
		AssertTrue(Not s.Contains("a"), "Main set no longer has 'a'")
		AssertTrue(Not sub.Contains("a"), "View does not contain 'a'")
	End Method

	' ---------- Set algebra ----------
	Method TestUnionIntersectionSymmetricDifference() { test }
		Local a:TTreeSet<Int> = New TTreeSet<Int>
		Local b:TTreeSet<Int> = New TTreeSet<Int>
		For Local i:Int = 1 To 5
			a.Add(i)            ' {1,2,3,4,5}
		Next
		For Local j:Int = 4 To 8
			b.Add(j)            ' {4,5,6,7,8}
		Next

		' Intersection (in-place on a): now {4,5}
		Local a1:TTreeSet<Int> = New TTreeSet<Int>
		For Local i:Int = 1 To 5; a1.Add(i); Next
		a1.Intersection(b)
		AssertEquals(2, a1.Count(), "Intersection count")
		AssertTrue(a1.Contains(4) And a1.Contains(5), "Intersection elements")

		' UnionOf (in-place on a): {1..8}
		Local a2:TTreeSet<Int> = New TTreeSet<Int>
		For Local i:Int = 1 To 5; a2.Add(i); Next
		a2.UnionOf(b)
		AssertEquals(8, a2.Count(), "Union count {1..8}")
		For Local k:Int = 1 To 8
			AssertTrue(a2.Contains(k), "Union contains " + k)
		Next

		' SymmetricDifference (in-place on a): {1,2,3,6,7,8}
		Local a3:TTreeSet<Int> = New TTreeSet<Int>
		For Local i:Int = 1 To 5; a3.Add(i); Next
		a3.SymmetricDifference(b)
		Local expect:Int[] = [1,2,3,6,7,8]
		AssertEquals(expect.Length, a3.Count(), "SymDiff count")
		For Local v:Int = EachIn expect
			AssertTrue(a3.Contains(v), "SymDiff contains " + v)
		Next
		AssertTrue(Not a3.Contains(4) And Not a3.Contains(5), "SymDiff excludes intersection")
	End Method

	' ---------- Subset/superset (including proper) ----------
	Method TestSubsetSupersetProper() { test }
		Local a:TTreeSet<Int> = New TTreeSet<Int>
		Local b:TTreeSet<Int> = New TTreeSet<Int>
		For Local i:Int = 1 To 3; a.Add(i); Next           ' {1,2,3}
		For Local i:Int = 1 To 5; b.Add(i); Next           ' {1,2,3,4,5}

		AssertTrue(a.IsSubsetOf(b), "a ⊆ b")
		AssertTrue(Not a.IsSupersetOf(b), "a ⊇ b false")
		AssertTrue(b.IsSupersetOf(a), "b ⊇ a")
		AssertTrue(Not b.IsSubsetOf(a), "b ⊆ a false")

		AssertTrue(a.IsProperSubsetOf(b), "a ⊂ b proper")
		AssertTrue(Not b.IsProperSubsetOf(a), "b ⊄ a")
		AssertTrue(b.IsProperSupersetOf(a), "b ⊃ a proper")
		AssertTrue(Not a.IsProperSupersetOf(b), "a ⊅ b")

		' Empty set edge cases
		Local e:TTreeSet<Int> = New TTreeSet<Int>
		AssertTrue(e.IsSubsetOf(a), "∅ ⊆ a")
		AssertTrue(e.IsProperSubsetOf(a), "∅ ⊂ a (a non-empty)")
		AssertTrue(a.IsSupersetOf(e), "a ⊇ ∅")
		AssertTrue(a.IsProperSupersetOf(e), "a ⊃ ∅ (a non-empty)")
		' ∅ proper superset of ∅ is false; plain superset is true
		Local e2:TTreeSet<Int> = New TTreeSet<Int>
		AssertTrue(e.IsSupersetOf(e2), "∅ ⊇ ∅")
		AssertTrue(Not e.IsProperSupersetOf(e2), "∅ ⊃ ∅ is false")
		AssertTrue(e.IsSubsetOf(e2), "∅ ⊆ ∅")
		AssertTrue(Not e.IsProperSubsetOf(e2), "∅ ⊂ ∅ is false")
	End Method

	' ---------- Overlaps ----------
	Method TestOverlaps() { test }
		Local a:TTreeSet<String> = New TTreeSet<String>
		Local b:TTreeSet<String> = New TTreeSet<String>
		For Local k:String = EachIn ["a","b","c"]; a.Add(k); Next
		For Local k:String = EachIn ["x","y","z"]; b.Add(k); Next
		AssertTrue(Not a.Overlaps(b), "No overlap")
		b.Add("b")
		AssertTrue(a.Overlaps(b), "Overlap on 'b'")
	End Method

	' ---------- Complement ----------
	Method TestComplement() { test }
		Local a:TTreeSet<Int> = New TTreeSet<Int>
		Local b:TTreeSet<Int> = New TTreeSet<Int>
		For Local i:Int = 1 To 6; a.Add(i); Next       ' {1..6}
		For Local j:Int = 2 To 4; b.Add(j); Next       ' {2,3,4}
		a.Complement(b)                                 ' remove {2,3,4}
		AssertEquals(3, a.Count(), "Complement removed 3 elements")
		For Local v:Int = EachIn [1,5,6]
			AssertTrue(a.Contains(v), "Complement kept " + v)
		Next
		For Local v2:Int = EachIn [2,3,4]
			AssertTrue(Not a.Contains(v2), "Complement removed " + v2)
		Next
	End Method

	' ---------- Constructors ----------
	Method TestConstructorsArrayAndIterable() { test }
		Local arr:String[] = ["a","b","c","b","a"]
		Local s1:TTreeSet<String> = New TTreeSet<String>(arr)    ' from array (dedup)
		AssertEquals(3, s1.Count(), "Array ctor dedup count 3")

		' iterable ctor: use another set
		Local s2:TTreeSet<String> = New TTreeSet<String>(s1, Null)
		AssertEquals(3, s2.Count(), "Iterable ctor copied 3")
		For Local k:String = EachIn ["a","b","c"]
			AssertTrue(s2.Contains(k), "Iterable ctor contains " + k)
		Next
	End Method

	' ---------- ToArray ----------
	Method TestToArray() { test }
		Local s:TTreeSet<Int> = New TTreeSet<Int>
		For Local i:Int = 5 To 1 Step -1
			s.Add(i)
		Next
		Local a:Int[] = s.ToArray()
		AssertEquals(s.Count(), a.Length, "ToArray length matches Count")
		' Should be in-order ascending
		For Local i:Int = 0 Until a.Length - 1
			AssertTrue(a[i] <= a[i+1], "ToArray preserves sorted order")
		Next
	End Method

	' ---------- Custom comparator ----------
	Method TestCustomComparatorReverseOrder() { test }
		Local cmp:TReverseStringComparator = New TReverseStringComparator
		Local s:TTreeSet<String> = New TTreeSet<String>(cmp)
		For Local k:String = EachIn ["a","b","c"]
			s.Add(k)
		Next
		Local expect:String[] = ["c","b","a"]
		Local i:Int = 0
		For Local e:String = EachIn s
			AssertEquals(expect[i], e, "Reverse comparator iteration order")
			i :+ 1
		Next
	End Method

	' ---------- Fuzz / stability ----------
	Method TestFuzzInsertRemoveAndOrder() { test }
		Local s:TTreeSet<Int> = New TTreeSet<Int>
		Local seed:Int = 24681357
		For Local i:Int = 1 Until 200
			seed = (seed * 1103515245 + 12345) & $7fffffff
			Local k:Int = seed Mod 300
			s.Add(k) ' Add ignores dups
		Next
		' Order check
		Local first:Int = True
		Local prev:Int = 0
		For Local e:Int = EachIn s
			If Not first Then AssertTrue(prev <= e, "In-order after fuzz inserts")
			prev = e
			first = False
		Next

		' Remove a pattern of keys and re-check
		For Local k:Int = 0 To 150 Step 7
			s.Remove(k)
			AssertTrue(Not s.Contains(k), "Removed key " + k)
		Next

		Local prev2:Int = -2147483648
		For Local e2:Int = EachIn s
			AssertTrue(prev2 <= e2, "In-order after fuzz removals")
			prev2 = e2
		Next
	End Method

End Type
