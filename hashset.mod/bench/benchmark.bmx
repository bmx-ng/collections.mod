SuperStrict

Framework BRL.StandardIO
Import Collections.HashSet

Const ENTRY_COUNT:Int = 100000
Const BUILD_PASSES:Int = 30
Const LOOKUP_PASSES:Int = 100

Global checksum:Long

Print "HashSet benchmark (" + ENTRY_COUNT + " entries)"
BenchmarkBuild()
BenchmarkBulkConstructors()
BenchmarkContains()
BenchmarkIteration()
BenchmarkRemoveRefill()
BenchmarkClearRefill()
Print "checksum: " + checksum

Function Fill(set:THashSet<Int>)
	For Local i:Int = 0 Until ENTRY_COUNT
		checksum :+ set.Add(i)
	Next
End Function

Function BenchmarkIteration()
	Local set:THashSet<Int> = New THashSet<Int>
	Fill(set)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until LOOKUP_PASSES
		For Local value:Int = EachIn set
			checksum :+ value
		Next
	Next
	PrintElapsed("iteration", started)

	started = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Local values:Int[] = set.ToArray()
		checksum :+ values.Length
	Next
	PrintElapsed("to array", started)
End Function

Function BenchmarkBulkConstructors()
	Local values:Int[ENTRY_COUNT]
	For Local i:Int = 0 Until values.Length
		values[i] = i
	Next

	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Local set:THashSet<Int> = New THashSet<Int>(values)
		checksum :+ set.Count()
	Next
	PrintElapsed("array constructor", started)

	Local source:THashSet<Int> = New THashSet<Int>(values)
	started = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Local set:THashSet<Int> = New THashSet<Int>(source, Null)
		checksum :+ set.Count()
	Next
	PrintElapsed("counted iterable constructor", started)
End Function

Function PrintElapsed(label:String, started:Int)
	Print label + ": " + (MilliSecs() - started) + " ms"
End Function

Function BenchmarkBuild()
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Local set:THashSet<Int> = New THashSet<Int>
		Fill(set)
	Next
	PrintElapsed("build", started)
End Function

Function BenchmarkContains()
	Local set:THashSet<Int> = New THashSet<Int>
	Fill(set)
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until LOOKUP_PASSES
		For Local i:Int = 0 Until ENTRY_COUNT
			checksum :+ set.Contains(i)
		Next
	Next
	PrintElapsed("contains hits", started)

	started = MilliSecs()
	For Local pass:Int = 0 Until LOOKUP_PASSES
		For Local i:Int = ENTRY_COUNT Until ENTRY_COUNT * 2
			checksum :+ set.Contains(i)
		Next
	Next
	PrintElapsed("contains misses", started)
End Function

Function BenchmarkRemoveRefill()
	Local set:THashSet<Int> = New THashSet<Int>
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Fill(set)
		For Local i:Int = 0 Until ENTRY_COUNT
			checksum :+ set.Remove(i)
		Next
	Next
	PrintElapsed("remove/refill", started)
End Function

Function BenchmarkClearRefill()
	Local set:THashSet<Int> = New THashSet<Int>
	Local started:Int = MilliSecs()
	For Local pass:Int = 0 Until BUILD_PASSES
		Fill(set)
		set.Clear()
	Next
	PrintElapsed("clear/refill", started)
End Function
