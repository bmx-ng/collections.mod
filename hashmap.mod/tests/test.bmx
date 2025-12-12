SuperStrict

Framework brl.standardio
Import brl.maxunit
Import Collections.HashMap
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

Type THashMapTest Extends TTest

    Method TestEmpty() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>

        AssertEquals(0, m.Count(), "Empty map count = 0")
        AssertTrue(m.IsEmpty(), "Empty map IsEmpty()")
        ' iteration should be empty
        Local saw:Int = 0

        For Local n:IMapNode<String,String> = EachIn m
            saw :+ 1
        Next

        AssertEquals(0, saw, "No iteration items on empty map")
        ' ContainsKey/Remove/TryGetValue should be negative
        AssertTrue(Not m.ContainsKey("nope"), "Empty map does not contain key")
        AssertTrue(Not m.Remove("nope"), "Remove missing key returns False")
        Local out:String = "untouched"
        AssertTrue(Not m.TryGetValue("nope", out), "TryGetValue missing returns False")
        AssertEquals("untouched", out, "TryGetValue leaves out var unchanged when missing")
    End Method

    Method TestAddAndCount() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>
        m.Add("b","bee")
        m.Add("a","aye")
        m.Add("c","see")
        AssertEquals(3, m.Count(), "Count after three adds")
        AssertTrue(m.ContainsKey("a") And m.ContainsKey("b") And m.ContainsKey("c"), "ContainsKey after add")
    End Method

    Method TestAddDuplicateThrows() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>
        m.Add("x","one")
        Local threw:Int = False
        Try
            m.Add("x","two")
        Catch e:TArgumentException
            threw = True
        End Try
        AssertTrue(threw, "Add duplicate throws TArgumentException")
        ' value should remain the original (since Add should not overwrite)
        AssertEquals("one", m["x"], "Duplicate Add did not overwrite")
    End Method

    Method TestPutOverwriteAndReturnOld() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>
        Local old:String = m.Put("k","v1")
        AssertTrue(old = Null, "Put on new key returns Null (default)")
        AssertEquals("v1", m["k"], "Put inserted value")
        old = m.Put("k","v2")
        AssertEquals("v1", old, "Put returns old value on overwrite")
        AssertEquals("v2", m["k"], "Put overwrote value")
    End Method

    Method TestContainsValueAndTryGet() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>
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
        AssertEquals("unchanged", v, "TryGetValue leaves out var unchanged on miss")
    End Method

    Method TestIndexerGetSet() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>
        m["a"] = "alpha"
        AssertEquals("alpha", m["a"], "Indexer set then get")
        ' get of missing returns Null/default
        Local got:String = m["b"]
        AssertTrue(got = Null, "Indexer get of missing returns Null")
        ' setting existing key updates
        m["a"] = "ALPHA"
        AssertEquals("ALPHA", m["a"], "Indexer update existing")
    End Method

    ' *** UPDATED: order-agnostic Keys/Values test ***
    Method TestKeysAndValuesCollections() { test }

		Local m:THashMap<String,String> = New THashMap<String,String>
        m.Add("b","2")
        m.Add("a","1")
        m.Add("c","3")

		Local ks:ICollection<String> = m.Keys()
        Local vs:ICollection<String> = m.Values()

		AssertEquals(3, ks.Count(), "Keys.Count")
        AssertEquals(3, vs.Count(), "Values.Count")

		' keys should be exactly the set {a,b,c}, in ANY order
        Local seenA:Int, seenB:Int, seenC:Int
        Local total:Int
        For Local k:String = EachIn ks

            Select k
                Case "a"
                    seenA = True
                Case "b"
                    seenB = True
                Case "c"
                    seenC = True
                Default
                    AssertTrue(False, "Unexpected key in Keys(): " + k)
            End Select
            total :+ 1
        Next
        AssertEquals(3, total, "Exactly 3 keys in Keys()")
        AssertTrue(seenA And seenB And seenC, "All expected keys present in Keys()")

        ' values should be exactly the set {"1","2","3"}, in ANY order
        Local seen1:Int, seen2:Int, seen3:Int
        total = 0
        For Local v:String = EachIn vs
            Select v
                Case "1"
                    seen1 = True
                Case "2"
                    seen2 = True
                Case "3"
                    seen3 = True
                Default
                    AssertTrue(False, "Unexpected value in Values(): " + v)
            End Select
            total :+ 1
        Next
        AssertEquals(3, total, "Exactly 3 values in Values()")
        AssertTrue(seen1 And seen2 And seen3, "All expected values present in Values()")
    End Method

    Method TestClear() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>
        m.Add("a","1"); m.Add("b","2"); m.Add("c","3")
        AssertEquals(3, m.Count(), "Precondition count")
        m.Clear()
        AssertEquals(0, m.Count(), "Count after Clear")
        AssertTrue(m.IsEmpty(), "IsEmpty after Clear")
        AssertTrue(Not m.ContainsKey("a"), "No keys after Clear")
    End Method

    ' *** NEW: directly exercises Remove() on present and missing keys ***
    Method TestRemoveExistingAndMissing() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>
        m.Add("one","1")
        m.Add("two","2")
        m.Add("three","3")
        m.Add("four","4")
        AssertEquals(4, m.Count(), "Precondition: 4 items")

        ' remove a middle key
        AssertTrue(m.Remove("two"), "Remove existing key returns True")
        AssertTrue(Not m.ContainsKey("two"), "Removed key no longer present")
        AssertEquals(3, m.Count(), "Count decremented after removal")

        ' remove head-ish and tail-ish keys, different probe positions
        AssertTrue(m.Remove("one"), "Remove another existing key")
        AssertTrue(m.Remove("four"), "Remove yet another existing key")
        AssertTrue(Not m.ContainsKey("one"), "Key 'one' gone")
        AssertTrue(Not m.ContainsKey("four"), "Key 'four' gone")
        AssertEquals(1, m.Count(), "Only one key left")

        ' remaining key should still be retrievable
        AssertTrue(m.ContainsKey("three"), "Remaining key still present")
        AssertEquals("3", m["three"], "Remaining key still maps correctly")

        ' remove missing keys should be harmless
        AssertTrue(Not m.Remove("nope"), "Remove on missing returns False")
        AssertEquals(1, m.Count(), "Count unchanged when removing missing")
    End Method

    ' *** NEW: stresses Resize() + RemoveAt() by mass inserts/removes ***
    Method TestResizeAndMassOperations() { test }
        Local m:THashMap<String,String> = New THashMap<String,String>

        ' Insert a bunch of keys to force multiple resizes
        For Local i:Int = 0 Until 100
            Local k:String = "k" + i
            m[k] = "v" + i
        Next

        AssertEquals(100, m.Count(), "Count after inserting 100 keys")

        ' All keys must be present and correct
        For Local i:Int = 0 Until 100
            Local k:String = "k" + i
            Local v:String
            AssertTrue(m.TryGetValue(k, v), "Key present after resize: " + k)
            AssertEquals("v" + i, v, "Value correct after resize: " + k)
        Next

        ' Remove all even keys; this will exercise RemoveAt() and backwards shifting
        For Local i:Int = 0 Until 100 Step 2
            Local k:String = "k" + i
            AssertTrue(m.Remove(k), "Remove existing even key: " + k)
        Next

        AssertEquals(50, m.Count(), "Count after removing 50 even keys")

        ' Even keys gone, odd keys remain
        For Local i:Int = 0 Until 100
            Local k:String = "k" + i
            Local exists:Int = m.ContainsKey(k)
            If (i Mod 2) = 0 Then
                AssertTrue(Not exists, "Even key removed: " + k)
            Else
                AssertTrue(exists, "Odd key remains: " + k)
                AssertEquals("v" + i, m[k], "Odd key still maps correctly: " + k)
            End If
        Next

        ' Insert some new keys to reuse freed slots
        For Local i:Int = 0 Until 20
            Local k:String = "z" + i
            m[k] = "Z" + i
        Next

        AssertEquals(70, m.Count(), "Count after inserting 20 new keys")

        ' Check new keys
        For Local i:Int = 0 Until 20
            Local k:String = "z" + i
            AssertTrue(m.ContainsKey(k), "New key present: " + k)
            AssertEquals("Z" + i, m[k], "New key mapped correctly: " + k)
        Next
    End Method

    Method TestHeavyCollisionsConstantHash() { test }
        Local cmp:TCollKeyComparator = New TCollKeyComparator
        Local m:THashMap<TCollKey,String> = New THashMap<TCollKey,String>(cmp)

        ' Insert a lot of keys that ALL hash to 1
        For Local i:Int = 0 Until 2000
            Local k:TCollKey = New TCollKey(i)
            m.Add(k, "v" + i)
        Next

        AssertEquals(2000, m.Count(), "All colliding keys inserted")

        ' All keys must be findable and mapped correctly
        For Local i:Int = 0 Until 2000
            Local k:TCollKey = New TCollKey(i)
            Local v:String
            AssertTrue(m.TryGetValue(k, v), "Key found under heavy collisions: " + i)
            AssertEquals("v" + i, v, "Value correct for key " + i)
        Next

        ' Remove half (even ids), exercising RemoveAt() in long clusters
        For Local i:Int = 0 Until 2000 Step 2
            Local k:TCollKey = New TCollKey(i)
            AssertTrue(m.Remove(k), "Remove existing colliding key: " + i)
        Next

        AssertEquals(1000, m.Count(), "Half of the colliding keys removed")

        ' Even keys gone, odd keys remain and still correct
        For Local i:Int = 0 Until 2000
            Local k:TCollKey = New TCollKey(i)
            Local exists:Int = m.ContainsKey(k)
            If (i Mod 2) = 0 Then
                AssertTrue(Not exists, "Even colliding key was removed: " + i)
            Else
                AssertTrue(exists, "Odd colliding key still present: " + i)
                AssertEquals("v" + i, m[k], "Odd colliding key still maps correctly: " + i)
            End If
        Next
    End Method

    Method TestHeavyCollisionsClusteredHashes() { test }
        Local cmp:TCollKeyClusteredComparator = New TCollKeyClusteredComparator
        Local m:THashMap<TCollKeyClustered,String> = New THashMap<TCollKeyClustered,String>(cmp)

        ' Insert a bunch of keys that hash into just 8 buckets
        For Local i:Int = 0 Until 4000
            Local k:TCollKeyClustered = New TCollKeyClustered(i)
            m[k] = "v" + i
        Next

        AssertEquals(4000, m.Count(), "Clustered keys inserted")

        ' Check a sampling to ensure lookups work within long but bounded clusters
        For Local i:Int = 0 Until 4000 Step 7
            Local k:TCollKeyClustered = New TCollKeyClustered(i)
            Local v:String
            AssertTrue(m.TryGetValue(k, v), "Clustered key found: " + i)
            AssertEquals("v" + i, v, "Clustered key value correct: " + i)
        Next

        ' Remove every 5th key and ensure remaining ones are still resolvable
        For Local i:Int = 0 Until 4000 Step 5
            Local k:TCollKeyClustered = New TCollKeyClustered(i)
            AssertTrue(m.Remove(k), "Remove clustered key: " + i)
        Next

        ' Sanity check: we removed ~4000 / 5 = 800 keys
        AssertTrue(m.Count() >= 3000 And m.Count() <= 3200, "Count after clustered removals is in expected range")

        ' Verify spot checks: removed keys gone, neighbors still good
        For Local i:Int = 0 Until 4000
            Local k:TCollKeyClustered = New TCollKeyClustered(i)
            Local exists:Int = m.ContainsKey(k)
            If (i Mod 5) = 0 Then
                AssertTrue(Not exists, "Clustered key removed: " + i)
            Else
                If exists Then
                    AssertEquals("v" + i, m[k], "Clustered key still maps correctly: " + i)
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
