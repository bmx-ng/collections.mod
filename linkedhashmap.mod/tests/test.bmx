SuperStrict

Framework brl.standardio
Import brl.maxunit
Import Collections.LinkedHashMap
Import BRL.StringBuilder

New TTestSuite.run()


Type TReverseStringComparator Implements IEqualityComparator<String>
    Method Equals:Int(a:String, b:String)
        Return a.Equals(b, True) ' if it's the same one way, it will be the same the other
    End Method

    Method HashCode:UInt(value:String)
        Return Reverse(value).HashCode()
    End Method

    Method Reverse:String(s:String)
        Local sb:TStringBuilder = New TStringBuilder
        For Local i:Int = s.Length - 1 To 0 Step -1
            sb.AppendChar(s[i])
        Next
        Return sb.ToString()
    End Method
End Type

Type TLinkedHashMapTest Extends TTest

	Method TestEmpty() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>

		AssertEquals(0, m.Count(), "Empty map count = 0")
		AssertTrue(m.IsEmpty(), "Empty map IsEmpty()")

		Local saw:Int = 0
		For Local n:IMapNode<String,String> = EachIn m
			saw :+ 1
		Next
		AssertEquals(0, saw, "No iteration items on empty map")

		AssertTrue(Not m.ContainsKey("nope"), "Empty map does not contain key")
		AssertTrue(Not m.Remove("nope"), "Remove missing key returns False")

		Local out:String = "untouched"
		AssertTrue(Not m.TryGetValue("nope", out), "TryGetValue missing returns False")
		AssertEquals("untouched", out, "TryGetValue leaves out var unchanged when missing")
	End Method

	Method TestAddAndCountAndIterationOrder() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>
		m.Add("b","bee")
		m.Add("a","aye")
		m.Add("c","see")

		AssertEquals(3, m.Count(), "Count after three adds")
		AssertTrue(m.ContainsKey("a") And m.ContainsKey("b") And m.ContainsKey("c"), "ContainsKey after add")

		' insertion order should be: b, a, c
		Local expectK:String[] = ["b","a","c"]
		Local expectV:String[] = ["bee","aye","see"]
		Local i:Int = 0
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expectK[i], n.GetKey(), "Iteration key order")
			AssertEquals(expectV[i], n.GetValue(), "Iteration value order")
			i :+ 1
		Next
		AssertEquals(3, i, "Iteration count matches")
	End Method

	Method TestAddDuplicateThrows() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>
		m.Add("x","one")

		Local threw:Int = False
		Try
			m.Add("x","two")
		Catch e:TArgumentException
			threw = True
		End Try
		AssertTrue(threw, "Add duplicate throws TArgumentException")
		AssertEquals("one", m["x"], "Duplicate Add did not overwrite")
	End Method

	Method TestPutOverwriteAndReturnOld() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>

		Local old:String = m.Put("k","v1")
		AssertTrue(old = Null, "Put on new key returns Null (default)")
		AssertEquals("v1", m["k"], "Put inserted value")

		old = m.Put("k","v2")
		AssertEquals("v1", old, "Put returns old value on overwrite")
		AssertEquals("v2", m["k"], "Put overwrote value")

		' Order should still be [k] (same key)
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals("k", n.GetKey(), "Iteration key still k")
			AssertEquals("v2", n.GetValue(), "Iteration sees updated value")
			i :+ 1
		Next
		AssertEquals(1, i, "Only one entry after overwrite")
	End Method

	Method TestContainsValueAndTryGet() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>
		m.Add("a","1")
		m.Add("b","2")
		m.Add("c","3")

		AssertTrue(m.ContainsValue("2"), "ContainsValue positive")
		AssertTrue(Not m.ContainsValue("9"), "ContainsValue negative")

		Local v:String = "x"
		AssertTrue(m.TryGetValue("b", v), "TryGetValue found")
		AssertEquals("2", v, "TryGetValue output correct")
		v = "unchanged"
		AssertTrue(Not m.TryGetValue("z", v), "TryGetValue missing")
		AssertEquals("unchanged", v, "TryGetValue leaves var unchanged on miss")
	End Method

	Method TestIndexerGetSet() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>

		m["a"] = "alpha"
		AssertEquals("alpha", m["a"], "Indexer set then get")

		Local got:String = m["b"]
		AssertTrue(got = Null, "Indexer get of missing returns Null")

		m["a"] = "ALPHA"
		AssertEquals("ALPHA", m["a"], "Indexer update existing")

		' Order should be just ["a"]
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals("a", n.GetKey(), "Order still contains only a")
			i :+ 1
		Next
		AssertEquals(1, i, "Only one entry")
	End Method

	Method TestKeysAndValuesCollectionsOrdered() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>
		m.Add("b","2")
		m.Add("a","1")
		m.Add("c","3")

		Local ks:ICollection<String> = m.Keys()
		Local vs:ICollection<String> = m.Values()

		AssertEquals(3, ks.Count(), "Keys.Count")
		AssertEquals(3, vs.Count(), "Values.Count")

		' LinkedHashMap should preserve insertion order: b,a,c and 2,1,3
		Local expectK:String[] = ["b","a","c"]
		Local expectV:String[] = ["2","1","3"]

		Local i:Int = 0
		For Local k:String = EachIn ks
			AssertEquals(expectK[i], k, "Keys iteration order (insertion)")
			i :+ 1
		Next
		AssertEquals(3, i, "Keys iterated 3 items")

		i = 0
		For Local v:String = EachIn vs
			AssertEquals(expectV[i], v, "Values iteration order (insertion)")
			i :+ 1
		Next
		AssertEquals(3, i, "Values iterated 3 items")
	End Method

	Method TestClear() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>
		m.Add("a","1"); m.Add("b","2"); m.Add("c","3")

		AssertEquals(3, m.Count(), "Precondition count")
		m.Clear()
		AssertEquals(0, m.Count(), "Count after Clear")
		AssertTrue(m.IsEmpty(), "IsEmpty after Clear")
		AssertTrue(Not m.ContainsKey("a"), "No keys after Clear")

		Local saw:Int
		For Local n:IMapNode<String,String> = EachIn m
			saw :+ 1
		Next
		AssertEquals(0, saw, "No iteration after Clear")
	End Method

	Method TestRemoveExistingAndMissingAndOrder() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>
		m.Add("one","1")
		m.Add("two","2")
		m.Add("three","3")
		m.Add("four","4")
		AssertEquals(4, m.Count(), "Precondition: 4 items")

		' remove "two"
		AssertTrue(m.Remove("two"), "Remove existing key returns True")
		AssertTrue(Not m.ContainsKey("two"), "Removed key no longer present")
		AssertEquals(3, m.Count(), "Count decremented after removal")

		' remaining iteration should be: one, three, four
		Local expectK:String[] = ["one","three","four"]
		Local expectV:String[] = ["1","3","4"]
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expectK[i], n.GetKey(), "Order after removal key")
			AssertEquals(expectV[i], n.GetValue(), "Order after removal value")
			i :+ 1
		Next
		AssertEquals(3, i, "Iterated 3 remaining items")

		' remove missing
		AssertTrue(Not m.Remove("nope"), "Remove on missing returns False")
		AssertEquals(3, m.Count(), "Count unchanged when removing missing")
	End Method

	Method TestResizeAndMassOperationsAndOrder() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>

		' Insert 0..99 in order
		For Local i:Int = 0 Until 100
			Local k:String = "k" + i
			m[k] = "v" + i
		Next

		AssertEquals(100, m.Count(), "Count after inserting 100 keys")

		' Verify values and order are intact after resizes
		Local idx:Int = 0
		For Local n:IMapNode<String,String> = EachIn m
			Local kExpected:String = "k" + idx
			Local vExpected:String = "v" + idx
			AssertEquals(kExpected, n.GetKey(), "Order preserved after resize key")
			AssertEquals(vExpected, n.GetValue(), "Order preserved after resize value")
			idx :+ 1
		Next
		AssertEquals(100, idx, "Iterated 100 items")

		' Remove even keys
		For Local i:Int = 0 Until 100 Step 2
			AssertTrue(m.Remove("k" + i), "Remove even key k" + i)
		Next
		AssertEquals(50, m.Count(), "Count after removing 50 even keys")

		' Order should now be k1,k3,k5,...,k99
		idx = 1
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals("k" + idx, n.GetKey(), "Order after mass removals key")
			AssertEquals("v" + idx, n.GetValue(), "Order after mass removals value")
			idx :+ 2
		Next
		AssertEquals(101, idx, "Ended at 101 after iterating odds 1..99")

		' Add 20 new keys (appended in insertion order)
		For Local i:Int = 0 Until 20
			m["z" + i] = "Z" + i
		Next
		AssertEquals(70, m.Count(), "Count after inserting 20 new keys")

		' tail should be z0..z19
		Local seenZ:Int
		For Local n:IMapNode<String,String> = EachIn m
			If n.GetKey().StartsWith("z") Then
				seenZ :+ 1
			End If
		Next
		AssertEquals(20, seenZ, "Saw all z* keys in iteration")
	End Method

	Method TestComparatorHashingIndependenceFromOrder() { test }
		' Ensure odd hash doesn't affect insertion order.
		Local cmp:TReverseStringComparator = New TReverseStringComparator
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>(cmp)

		m.Add("ab","1")
		m.Add("cd","2")
		m.Add("ef","3")

		Local expect:String[] = ["ab","cd","ef"]
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expect[i], n.GetKey(), "Insertion order preserved with custom comparator")
			i :+ 1
		Next
		AssertEquals(3, i, "Iterated 3 entries")
	End Method

	Method TestHeavyCollisionsConstantHashOrder() { test }
		Local cmp:TCollKeyComparator = New TCollKeyComparator
		Local m:TLinkedHashMap<TCollKey,String> = New TLinkedHashMap<TCollKey,String>(cmp)

		For Local i:Int = 0 Until 2000
			m.Add(New TCollKey(i), "v" + i)
		Next
		AssertEquals(2000, m.Count(), "All colliding keys inserted")

		' Order should be 0..1999
		Local i:Int = 0
		For Local n:IMapNode<TCollKey,String> = EachIn m
			AssertEquals(i, n.GetKey().id, "Collision iteration order by insertion id")
			AssertEquals("v" + i, n.GetValue(), "Collision iteration value by insertion id")
			i :+ 1
		Next
		AssertEquals(2000, i, "Iterated all colliding entries")

		' Remove evens and ensure remaining order is odds in original order
		For Local j:Int = 0 Until 2000 Step 2
			AssertTrue(m.Remove(New TCollKey(j)), "Remove even key " + j)
		Next
		AssertEquals(1000, m.Count(), "Half removed")

		i = 1
		For Local n:IMapNode<TCollKey,String> = EachIn m
			AssertEquals(i, n.GetKey().id, "Remaining order is odd ids")
			i :+ 2
		Next
		AssertEquals(2001, i, "Ended at 2001 after iterating odds")
	End Method

	Method TestHeavyCollisionsClusteredHashesOrder() { test }
		Local cmp:TCollKeyClusteredComparator = New TCollKeyClusteredComparator
		Local m:TLinkedHashMap<TCollKeyClustered,String> = New TLinkedHashMap<TCollKeyClustered,String>(cmp)

		For Local i:Int = 0 Until 4000
			m[New TCollKeyClustered(i)] = "v" + i
		Next
		AssertEquals(4000, m.Count(), "Clustered keys inserted")

		' Spot check retrieval
		For Local i:Int = 0 Until 4000 Step 19
			AssertEquals("v" + i, m[New TCollKeyClustered(i)], "Clustered lookup " + i)
		Next

		' Remove every 5th key
		For Local i:Int = 0 Until 4000 Step 5
			AssertTrue(m.Remove(New TCollKeyClustered(i)), "Remove clustered key " + i)
		Next

		AssertTrue(m.Count() >= 3000 And m.Count() <= 3200, "Count after clustered removals is in expected range")

		' Remaining order should be original order with holes (skipping removed)
		Local nextExpected:Int = 0
		For Local n:IMapNode<TCollKeyClustered,String> = EachIn m
			' Advance nextExpected to the next non-removed id
			While (nextExpected Mod 5) = 0
				nextExpected :+ 1
			Wend
			AssertEquals(nextExpected, n.GetKey().id, "Order after clustered removals matches insertion order minus removed")
			nextExpected :+ 1
		Next
	End Method

	Method TestMaxSizeInsertionOrderFifoEviction() { test }
		' FIFO eviction: accessOrder = False, maxSize = 3
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>(Null, False, 3)

		m.Add("a","1")
		m.Add("b","2")
		m.Add("c","3")

		' exceed capacity; should evict oldest inserted ("a")
		m.Add("d","4")

		AssertEquals(3, m.Count(), "Count capped to maxSize")
		AssertTrue(Not m.ContainsKey("a"), "FIFO eviction removed oldest inserted")
		AssertTrue(m.ContainsKey("b") And m.ContainsKey("c") And m.ContainsKey("d"), "Remaining keys present")

		' order should now be b,c,d
		Local expect:String[] = ["b","c","d"]
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expect[i], n.GetKey(), "FIFO order after eviction")
			i :+ 1
		Next
		AssertEquals(3, i, "Iterated 3 items")
	End Method

	Method TestAccessOrderTouchOnGet() { test }
		' accessOrder = True, no max size needed to test reordering
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>(Null, True)

		m.Add("a","1")
		m.Add("b","2")
		m.Add("c","3")

		' Access "a" then "b" should move them to end in that order:
		Local tmp:String
		AssertTrue(m.TryGetValue("a", tmp), "TryGetValue a exists")
		AssertEquals("1", tmp, "a value correct")
		AssertTrue(m.TryGetValue("b", tmp), "TryGetValue b exists")
		AssertEquals("2", tmp, "b value correct")

		' Expected order: c, a, b
		Local expect:String[] = ["c","a","b"]
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expect[i], n.GetKey(), "Access-order iteration after touches")
			i :+ 1
		Next
		AssertEquals(3, i, "Iterated 3 items")
	End Method

	Method TestAccessOrderLruEviction() { test }
		' LRU eviction: accessOrder = True, maxSize = 3
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>(Null, True, 3)

		m.Add("a","1")
		m.Add("b","2")
		m.Add("c","3")

		' Touch "a" so it becomes most-recent:
		Local tmp:String
		AssertTrue(m.TryGetValue("a", tmp), "Touch a")
		AssertEquals("1", tmp, "a value")

		' Insert "d" => should evict least-recently-used = "b"
		m.Add("d","4")

		AssertEquals(3, m.Count(), "Count capped to maxSize")
		AssertTrue(Not m.ContainsKey("b"), "LRU eviction removed least recently used (b)")
		AssertTrue(m.ContainsKey("a") And m.ContainsKey("c") And m.ContainsKey("d"), "Remaining keys present")

		' After touch+insert, order should be: c, a, d
		Local expect:String[] = ["c","a","d"]
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expect[i], n.GetKey(), "LRU order after eviction")
			i :+ 1
		Next
		AssertEquals(3, i, "Iterated 3 items")
	End Method

	Method TestSetMaxSizeEvictsImmediatelyWhenLowered() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>(Null, False)

		For Local i:Int = 0 Until 5
			m.Add("k" + i, "v" + i)
		Next
		AssertEquals(5, m.Count(), "Precondition: 5 entries")

		' Lower max size; should immediately evict oldest until size==2
		m.SetMaxSize(2)

		AssertEquals(2, m.Count(), "Count reduced to new maxSize")

		' Oldest inserted were k0,k1,k2 -> removed, leaving k3,k4
		AssertTrue(Not m.ContainsKey("k0"), "k0 evicted")
		AssertTrue(Not m.ContainsKey("k1"), "k1 evicted")
		AssertTrue(Not m.ContainsKey("k2"), "k2 evicted")
		AssertTrue(m.ContainsKey("k3") And m.ContainsKey("k4"), "Newest remain")

		' Order should be k3,k4
		Local expect:String[] = ["k3","k4"]
		Local idx:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expect[idx], n.GetKey(), "Order after shrink eviction")
			idx :+ 1
		Next
		AssertEquals(2, idx, "Iterated 2 items")
	End Method

	Method TestSetMaxSizeLruShrinkUsesCurrentOrder() { test }
		' With accessOrder True, shrinking should evict from current LRU head
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>(Null, True)

		m.Add("a","1")
		m.Add("b","2")
		m.Add("c","3")
		m.Add("d","4")
		m.Add("e","5")
		AssertEquals(5, m.Count(), "Precondition 5 entries")

		' Touch c and a (make them most-recent)
		Local tmp:String
		AssertTrue(m.TryGetValue("c", tmp), "Touch c")
		AssertTrue(m.TryGetValue("a", tmp), "Touch a")

		' Current order should be: b, d, e, c, a
		' Now shrink to 3: evict from head => remove b then d, leaving e,c,a
		m.SetMaxSize(3)

		AssertEquals(3, m.Count(), "Count reduced to 3")
		AssertTrue(Not m.ContainsKey("b"), "b evicted as LRU")
		AssertTrue(Not m.ContainsKey("d"), "d evicted next as LRU")
		AssertTrue(m.ContainsKey("e") And m.ContainsKey("c") And m.ContainsKey("a"), "Expected survivors remain")

		Local expect:String[] = ["e","c","a"]
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expect[i], n.GetKey(), "LRU order after shrink")
			i :+ 1
		Next
		AssertEquals(3, i, "Iterated 3 items")
	End Method

	Method TestAccessOrderDoesNotAffectContainsKey() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>(Null, True)

		m.Add("a","1")
		m.Add("b","2")
		m.Add("c","3")

		' ContainsKey should not change order
		AssertTrue(m.ContainsKey("a"), "ContainsKey(a) true")
		AssertTrue(m.ContainsKey("b"), "ContainsKey(b) true")

		Local expect:String[] = ["a","b","c"]
		Local i:Int
		For Local n:IMapNode<String,String> = EachIn m
			AssertEquals(expect[i], n.GetKey(), "Order unchanged by ContainsKey")
			i :+ 1
		Next
		AssertEquals(3, i, "Iterated 3 items")
	End Method

	Method TestFailFastIfAccessReordersDuringIteration() { test }
		Local m:TLinkedHashMap<String,String> = New TLinkedHashMap<String,String>(Null, True)

		m.Add("a","1")
		m.Add("b","2")
		m.Add("c","3")

		Local threw:Int = False
		Try
			' Iteration begins...
			For Local n:IMapNode<String,String> = EachIn m
				' Access another key triggers Touch+version bump => should throw
				Local tmp:String
				m.TryGetValue("a", tmp)
			Next
		Catch e:TInvalidOperationException
			threw = True
		End Try

		AssertTrue(threw, "Iterator fails fast if access-order mutation occurs during iteration")
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
