SuperStrict

Framework BRL.StandardIO
Import Collections.LinkedHashMap

Const HASH_NORMAL:Int = 0
Const HASH_CLUSTERED:Int = 1
Const HASH_HIGH_BITS:Int = 2
Const HASH_CONSTANT:Int = 3

Global checksum:Long

Print "Bounded LinkedHashMap insertion benchmark"
Print "Each result measures replacement insertions after the map reaches maxSize."
Print ""

BenchmarkInt("Int, distributed, FIFO", 4096, 500000, HASH_NORMAL, False)
BenchmarkInt("Int, distributed, LRU mode", 4096, 500000, HASH_NORMAL, True)
BenchmarkInt("Int, 64 hash buckets", 2048, 100000, HASH_CLUSTERED, False)
BenchmarkInt("Int, high bits only", 512, 50000, HASH_HIGH_BITS, False)
BenchmarkInt("Int, constant hash", 256, 25000, HASH_CONSTANT, False)
BenchmarkStrings(4096, 100000)
BenchmarkResizeBoundaries()

Print ""
Print "checksum: " + checksum

Function BenchmarkInt(label:String, maxSize:Int, replacements:Int, hashMode:Int, accessOrder:Int)
	Local comparator:TCountingIntComparator = New TCountingIntComparator(hashMode)
	Local map:TLinkedHashMap<Int,Int> = New TLinkedHashMap<Int,Int>(comparator, accessOrder, maxSize)
	For Local key:Int = 0 Until maxSize
		map[key] = key
	Next

	comparator.Reset()
	Local started:Int = MilliSecs()
	For Local key:Int = maxSize Until maxSize + replacements
		map[key] = key
	Next
	Local elapsed:Int = MilliSecs() - started
	checksum :+ map.Count()

	Print label + ": " + elapsed + " ms; hashes=" + comparator.hashCalls + "; equals=" + comparator.equalsCalls
End Function

Function BenchmarkStrings(maxSize:Int, replacements:Int)
	Local keys:String[maxSize + replacements]
	For Local i:Int = 0 Until keys.Length
		keys[i] = "key-" + i
	Next

	Local comparator:TCountingStringComparator = New TCountingStringComparator
	Local map:TLinkedHashMap<String,Int> = New TLinkedHashMap<String,Int>(comparator, False, maxSize)
	For Local i:Int = 0 Until maxSize
		map[keys[i]] = i
	Next

	comparator.Reset()
	Local started:Int = MilliSecs()
	For Local i:Int = maxSize Until keys.Length
		map[keys[i]] = i
	Next
	Local elapsed:Int = MilliSecs() - started
	checksum :+ map.Count()

	Print "String, distributed, FIFO: " + elapsed + " ms; hashes=" + comparator.hashCalls + "; equals=" + comparator.equalsCalls
End Function

Function BenchmarkResizeBoundaries()
	Print ""
	Print "First replacement at exact load thresholds:"
	Local thresholds:Int[] = [6, 12, 25, 51, 102, 204, 409, 819]
	For Local maxSize:Int = EachIn thresholds
		Local comparator:TCountingIntComparator = New TCountingIntComparator(HASH_NORMAL)
		Local map:TLinkedHashMap<Int,Int> = New TLinkedHashMap<Int,Int>(comparator, False, maxSize)
		For Local key:Int = 0 Until maxSize
			map[key] = key
		Next

		comparator.Reset()
		map[maxSize] = maxSize
		checksum :+ map.Count()
		Print "  maxSize=" + maxSize + ": hashes=" + comparator.hashCalls + "; equals=" + comparator.equalsCalls
	Next
End Function

Type TCountingIntComparator Implements IEqualityComparator<Int>
	Field hashMode:Int
	Field hashCalls:Long
	Field equalsCalls:Long

	Method New(hashMode:Int)
		Self.hashMode = hashMode
	End Method

	Method Reset()
		hashCalls = 0
		equalsCalls = 0
	End Method

	Method Equals:Int(a:Int, b:Int)
		equalsCalls :+ 1
		Return a = b
	End Method

	Method HashCode:UInt(value:Int)
		hashCalls :+ 1
		Select hashMode
			Case HASH_CLUSTERED
				Return UInt(value & 63)
			Case HASH_HIGH_BITS
				Return UInt(value) Shl 16
			Case HASH_CONSTANT
				Return 1
		End Select
		Return UInt(value)
	End Method
End Type

Type TCountingStringComparator Implements IEqualityComparator<String>
	Field hashCalls:Long
	Field equalsCalls:Long

	Method Reset()
		hashCalls = 0
		equalsCalls = 0
	End Method

	Method Equals:Int(a:String, b:String)
		equalsCalls :+ 1
		Return a = b
	End Method

	Method HashCode:UInt(value:String)
		hashCalls :+ 1
		Return value.HashCode()
	End Method
End Type
