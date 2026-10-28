SuperStrict

Framework BRL.StandardIO
Import Collections.LinkedHashMap

Const ENTRY_COUNT:Int = 100000
Const BUILD_PASSES:Int = 20
Const LOOKUP_PASSES:Int = 100
Const ITERATION_PASSES:Int = 100
Const CHURN_PASSES:Int = 10

Global checksum:Long

Print "LinkedHashMap benchmark (" + ENTRY_COUNT + " entries)"
BenchmarkBuild(False)
BenchmarkBuild(True)
BenchmarkLookup()
BenchmarkIteration()
BenchmarkRemoveRefill()
BenchmarkClearRefill()
BenchmarkChurn()
BenchmarkAccessOrder()
Print "checksum: " + checksum

Function Fill(map:TLinkedHashMap<Int,Int>)
	For Local i:Int = 0 Until ENTRY_COUNT
		map[i] = i + 1
	Next
End Function

Function PrintElapsed(label:String, started:Int)
	Print label + ": " + (MilliSecs() - started) + " ms"
End Function

Function BenchmarkBuild(presized:Int)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Local map:TLinkedHashMap<Int,Int>
		If presized Then
			map = New TLinkedHashMap<Int,Int>(ENTRY_COUNT)
		Else
			map = New TLinkedHashMap<Int,Int>
		End If
		Fill(map)
		checksum :+ map.Count()
	Next
	If presized Then
		PrintElapsed("build, presized", started)
	Else
		PrintElapsed("build, growing", started)
	End If
End Function

Function BenchmarkLookup()
	Local map:TLinkedHashMap<Int,Int> = New TLinkedHashMap<Int,Int>(ENTRY_COUNT)
	Fill(map)

	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until LOOKUP_PASSES
		For Local i:Int = 0 Until ENTRY_COUNT
			checksum :+ map[i]
		Next
	Next
	PrintElapsed("lookup hits", started)

	started = MilliSecs()
	For Local pass:Int = 0 Until LOOKUP_PASSES
		For Local i:Int = ENTRY_COUNT Until ENTRY_COUNT * 2
			checksum :+ map.ContainsKey(i)
		Next
	Next
	PrintElapsed("lookup misses", started)
End Function

Function BenchmarkIteration()
	Local map:TLinkedHashMap<Int,Int> = New TLinkedHashMap<Int,Int>(ENTRY_COUNT)
	Fill(map)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until ITERATION_PASSES
		For Local value:Int = EachIn map.Values()
			checksum :+ value
		Next
	Next
	PrintElapsed("ordered value iteration", started)
End Function

Function BenchmarkRemoveRefill()
	Local map:TLinkedHashMap<Int,Int> = New TLinkedHashMap<Int,Int>(ENTRY_COUNT)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Fill(map)
		For Local i:Int = 0 Until ENTRY_COUNT
			checksum :+ map.Remove(i)
		Next
	Next
	PrintElapsed("remove/refill", started)
End Function

Function BenchmarkClearRefill()
	Local map:TLinkedHashMap<Int,Int> = New TLinkedHashMap<Int,Int>(ENTRY_COUNT)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Fill(map)
		map.Clear()
	Next
	PrintElapsed("clear/refill (includes populated Clear)", started)
End Function

Function BenchmarkChurn()
	Local map:TLinkedHashMap<Int,Int> = New TLinkedHashMap<Int,Int>(ENTRY_COUNT)
	Fill(map)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until CHURN_PASSES
		Local firstKey:Int = pass * ENTRY_COUNT
		For Local i:Int = 0 Until ENTRY_COUNT
			checksum :+ map.Remove(firstKey + i)
			map[firstKey + ENTRY_COUNT + i] = i
		Next
	Next
	PrintElapsed("steady churn", started)
End Function

Function BenchmarkAccessOrder()
	Local map:TLinkedHashMap<Int,Int> = New TLinkedHashMap<Int,Int>(ENTRY_COUNT, Null, True)
	Fill(map)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until CHURN_PASSES
		For Local i:Int = 0 Until ENTRY_COUNT
			checksum :+ map[i]
		Next
	Next
	PrintElapsed("access-order touches", started)
End Function
