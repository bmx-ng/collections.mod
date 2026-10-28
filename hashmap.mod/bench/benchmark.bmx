SuperStrict

Framework BRL.StandardIO
Import Collections.HashMap

Const ENTRY_COUNT:Int = 100000
Const BUILD_PASSES:Int = 30
Const LOOKUP_PASSES:Int = 100
Const ITERATION_PASSES:Int = 100
Const CHURN_PASSES:Int = 20

Global checksum:Long

Print "HashMap benchmark (" + ENTRY_COUNT + " entries)"
BenchmarkBuild(False)
BenchmarkBuild(True)
BenchmarkLookup()
BenchmarkIteration()
BenchmarkRemoveRefill()
BenchmarkClearRefill()
BenchmarkChurn()
Print "checksum: " + checksum

Function Fill(map:THashMap<Int, Int>)
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
		Local map:THashMap<Int, Int>
		If presized Then
			map = New THashMap<Int, Int>(ENTRY_COUNT)
		Else
			map = New THashMap<Int, Int>
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
	Local map:THashMap<Int, Int> = New THashMap<Int, Int>(ENTRY_COUNT)
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
	Local map:THashMap<Int, Int> = New THashMap<Int, Int>(ENTRY_COUNT)
	Fill(map)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until ITERATION_PASSES
		Local iterator:IIterator<Int> = map.Values().GetIterator()
		While iterator.MoveNext()
			checksum :+ iterator.Current()
		Wend
	Next
	PrintElapsed("value iteration", started)
End Function

Function BenchmarkRemoveRefill()
	Local map:THashMap<Int, Int> = New THashMap<Int, Int>(ENTRY_COUNT)
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
	Local map:THashMap<Int, Int> = New THashMap<Int, Int>(ENTRY_COUNT)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Fill(map)
		map.Clear()
	Next
	PrintElapsed("clear/refill (includes populated Clear)", started)
End Function

Function BenchmarkChurn()
	Local map:THashMap<Int, Int> = New THashMap<Int, Int>(ENTRY_COUNT)
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
