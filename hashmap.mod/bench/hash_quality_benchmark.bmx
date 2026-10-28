SuperStrict

' Exercises both well-distributed and deliberately weak hashes so changes to
' HashMap's collision handling can be measured without penalising common keys.

Framework BRL.StandardIO
Import Collections.HashMap

Const HASH_SEQUENTIAL:Int = 0
Const HASH_PERMUTED:Int = 1
Const HASH_LOW_BUCKETS:Int = 2
Const HASH_HIGH_BITS:Int = 3
Const HASH_CONSTANT:Int = 4

Global checksum:Long

Print "HashMap hash-quality benchmark"
Benchmark("sequential", 100000, 50, HASH_SEQUENTIAL)
Benchmark("permuted", 100000, 50, HASH_PERMUTED)
Benchmark("64 low buckets", 4096, 5, HASH_LOW_BUCKETS)
Benchmark("high bits only", 4096, 5, HASH_HIGH_BITS)
Benchmark("constant", 2048, 5, HASH_CONSTANT)
Print "checksum: " + checksum

Function Benchmark(label:String, count:Int, lookupPasses:Int, hashMode:Int)
	Local comparator:TQualityComparator = New TQualityComparator(hashMode)
	Local map:THashMap<Int,Int> = New THashMap<Int,Int>(count, comparator)

	Local started:Int = MilliSecs()
	For Local key:Int = 0 Until count
		map[key] = key + 1
	Next
	Local buildElapsed:Int = MilliSecs() - started

	comparator.equalsCalls = 0
	started = MilliSecs()
	For Local pass:Int = 0 Until lookupPasses
		For Local key:Int = 0 Until count
			checksum :+ map[key]
		Next
	Next
	Local lookupElapsed:Int = MilliSecs() - started

	Print label + ": build=" + buildElapsed + " ms; lookup=" + lookupElapsed + " ms; equals=" + comparator.equalsCalls
End Function

Type TQualityComparator Implements IEqualityComparator<Int>
	Field hashMode:Int
	Field equalsCalls:Long

	Method New(hashMode:Int)
		Self.hashMode = hashMode
	End Method

	Method Equals:Int(left:Int, right:Int)
		equalsCalls :+ 1
		Return left = right
	End Method

	Method HashCode:UInt(value:Int)
		Select hashMode
			Case HASH_PERMUTED
				Return UInt(value) * UInt($9e3779b9)
			Case HASH_LOW_BUCKETS
				Return UInt(value & 63)
			Case HASH_HIGH_BITS
				Return UInt(value) Shl 16
			Case HASH_CONSTANT
				Return 1
		End Select
		Return UInt(value)
	End Method
End Type
