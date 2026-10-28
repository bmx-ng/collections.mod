SuperStrict

' Compares representative built-in and object key types on the same workload.

Framework BRL.StandardIO
Import Collections.HashMap

Const ENTRY_COUNT:Int = 100000
Const LOOKUP_PASSES:Int = 50

Global checksum:Long

Print "HashMap key-type benchmark"
BenchmarkInt()
BenchmarkLong()
BenchmarkString()
BenchmarkObject("object sequential hash", ENTRY_COUNT, LOOKUP_PASSES, HASH_SEQUENTIAL)
BenchmarkObject("object high-bit hash", 4096, 5, HASH_HIGH_BITS)
BenchmarkObject("object permuted hash", ENTRY_COUNT, LOOKUP_PASSES, HASH_PERMUTED)
Print "checksum: " + checksum

Function PrintElapsed(label:String, buildStarted:Int, lookupStarted:Int)
	Print label + ": build=" + (lookupStarted - buildStarted) + " ms; lookup=" + (MilliSecs() - lookupStarted) + " ms"
End Function

Function BenchmarkInt()
	Local map:THashMap<Int,Int> = New THashMap<Int,Int>(ENTRY_COUNT)
	Local buildStarted:Int = MilliSecs()
	For Local key:Int = 0 Until ENTRY_COUNT
		map[key] = key + 1
	Next
	Local lookupStarted:Int = MilliSecs()
	For Local pass:Int = 0 Until LOOKUP_PASSES
		For Local key:Int = 0 Until ENTRY_COUNT
			checksum :+ map[key]
		Next
	Next
	PrintElapsed("Int", buildStarted, lookupStarted)
End Function

Function BenchmarkLong()
	Local map:THashMap<Long,Int> = New THashMap<Long,Int>(ENTRY_COUNT)
	Local buildStarted:Int = MilliSecs()
	For Local key:Int = 0 Until ENTRY_COUNT
		map[Long(key)] = key + 1
	Next
	Local lookupStarted:Int = MilliSecs()
	For Local pass:Int = 0 Until LOOKUP_PASSES
		For Local key:Int = 0 Until ENTRY_COUNT
			checksum :+ map[Long(key)]
		Next
	Next
	PrintElapsed("Long", buildStarted, lookupStarted)
End Function

Function BenchmarkString()
	Local keys:String[ENTRY_COUNT]
	Local map:THashMap<String,Int> = New THashMap<String,Int>(ENTRY_COUNT)
	For Local key:Int = 0 Until ENTRY_COUNT
		keys[key] = "key-" + key
	Next
	Local buildStarted:Int = MilliSecs()
	For Local key:Int = 0 Until ENTRY_COUNT
		map[keys[key]] = key + 1
	Next
	Local lookupStarted:Int = MilliSecs()
	For Local pass:Int = 0 Until LOOKUP_PASSES
		For Local key:Int = 0 Until ENTRY_COUNT
			checksum :+ map[keys[key]]
		Next
	Next
	PrintElapsed("String", buildStarted, lookupStarted)
End Function

Const HASH_SEQUENTIAL:Int = 0
Const HASH_HIGH_BITS:Int = 1
Const HASH_PERMUTED:Int = 2

Function BenchmarkObject(label:String, count:Int, lookupPasses:Int, hashMode:Int)
	Local keys:TBenchmarkKey[count]
	Local map:THashMap<TBenchmarkKey,Int> = New THashMap<TBenchmarkKey,Int>(count)
	For Local key:Int = 0 Until count
		keys[key] = New TBenchmarkKey(key, hashMode)
	Next
	Local buildStarted:Int = MilliSecs()
	For Local key:Int = 0 Until count
		map[keys[key]] = key + 1
	Next
	Local lookupStarted:Int = MilliSecs()
	For Local pass:Int = 0 Until lookupPasses
		For Local key:Int = 0 Until count
			checksum :+ map[keys[key]]
		Next
	Next
	PrintElapsed(label, buildStarted, lookupStarted)
End Function

Type TBenchmarkKey
	Field value:Int
	Field hashMode:Int

	Method New(value:Int, hashMode:Int)
		Self.value = value
		Self.hashMode = hashMode
	End Method

	Method HashCode:UInt()
		Select hashMode
			Case HASH_HIGH_BITS
				Return UInt(value) Shl 16
			Case HASH_PERMUTED
				Return UInt(value) * UInt($9e3779b9)
		End Select
		Return UInt(value)
	End Method
End Type
