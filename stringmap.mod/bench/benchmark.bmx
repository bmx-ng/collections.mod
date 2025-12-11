SuperStrict

Framework brl.standardio
Import BRL.Map
Import Collections.StringMap
Import Random.Squares

SeedRnd( 2222222 )

Print "Building key data..."

' number of iterations per benchmark
Const benchmarkIterations:Int = 100

' string keys
Const maxSize:Int = 100000
Local seqKeysAscStr:String[] = New String[ maxSize ]
Local seqKeysDescStr:String[] = New String[ maxSize ]
Local randKeysStr:String[] = New String[ maxSize ]

' string keys of the form : "aaaaaaaa", "aaaaaabb"...
' so incrementing in base 26 with 'a' to 'z' as digits, but in pairs of chars... effectively "aaaa" but "aaaaaaaa"
For Local i:Int = 0 Until maxSize
	Local key:String = ""
	For Local j:Int = 0 Until 4
		Local c:Int = 97 + (i / (26 ^ j)) Mod 26
		key :+ Chr(c) + Chr(c)
	Next
	seqKeysAscStr[i] = key
	seqKeysDescStr[i] = key
	' random 8 chars
	randKeysStr[i] = ""
	For Local j:Int = 0 Until 8
		randKeysStr[i] :+ Chr(97 + Rnd(0, 26))
	Next
Next

Print "Running benchmarks..."

' benchmark sizes
Local sizes:Int[] = [10, 50, 100, 500, 1000, 5000, 10000, 50000]

' run benchmarks
For Local s:Int = 0 Until sizes.Length
	Local size:Int = sizes[s]

	Print "Size: " + size

	Local map:TMap = new TMap
	BenchmarkMapOperations( "TMap", map, seqKeysAscStr, seqKeysDescStr, randKeysStr, size )

	Local stringMap:TStringMap = new TStringMap
	BenchmarkStringMapOperations( "TStringMap", stringMap, seqKeysAscStr, seqKeysDescStr, randKeysStr, size )

Next


Function BenchmarkMapOperations( name:String, map:TMap, seqKeysAsc:String[], seqKeysDesc:String[], randKeys:String[], size:Int )

	Local value:String = "someValue"

	Print " Benchmarking " + name
	' Insert Sequential Ascending
	Local total:Long

	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			map.Insert( seqKeysAsc[i], value )
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
		map.Clear()
	Next
	
	Print "  Insert Seq Asc: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

	total = 0
	' Insert Sequential Descending
	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			map.Insert( seqKeysDesc[i], value )
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
		map.Clear()
	Next
	Print "  Insert Seq Desc: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

	total = 0
	' Insert Random
	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			map.Insert( randKeys[i], value )
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
		map.Clear()
	Next
	Print "  Insert Random: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

	' Lookup Sequential

	' pre-insert data
	For Local i:Int = 0 Until size
		map.Insert( seqKeysAsc[i], value )
	Next

	total = 0

	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			Local v:String = String(map[ seqKeysAsc[i] ])
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
	Next
	Print "  Lookup Seq Asc: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

	' Lookup Random
	total = 0
	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			Local v:String = String(map[ randKeys[i] ])
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
	Next
	Print "  Lookup Random: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

End Function

Function BenchmarkStringMapOperations( name:String, map:TStringMap, seqKeysAsc:String[], seqKeysDesc:String[], randKeys:String[], size:Int )

	Local value:String = "someValue"

	Print " Benchmarking " + name
	' Insert Sequential Ascending
	Local total:Long

	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			map.Insert( seqKeysAsc[i], value )
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
		map.Clear()
	Next
	
	Print "  Insert Seq Asc: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

	total = 0
	' Insert Sequential Descending
	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			map.Insert( seqKeysDesc[i], value )
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
		map.Clear()
	Next
	Print "  Insert Seq Desc: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

	total = 0
	' Insert Random
	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			map.Insert( randKeys[i], value )
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
		map.Clear()
	Next
	Print "  Insert Random: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

	' Lookup Sequential

	' pre-insert data
	For Local i:Int = 0 Until size
		map.Insert( seqKeysAsc[i], value )
	Next

	total = 0

	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			Local v:String = String(map[ seqKeysAsc[i] ])
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
	Next
	Print "  Lookup Seq Asc: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

	' Lookup Random
	total = 0
	For Local iter:Int = 0 Until benchmarkIterations
		Local startTime:Int = MilliSecs()
		For Local i:Int = 0 Until size
			Local v:String = String(map[ randKeys[i] ])
		Next
		Local endTime:Int = MilliSecs()
		total :+ (endTime - startTime)
	Next
	Print "  Lookup Random: " + total + " ms" + " (avg " + (total / benchmarkIterations) + " ms)"

End Function
