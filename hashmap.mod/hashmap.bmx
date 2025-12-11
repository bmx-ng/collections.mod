SuperStrict

Module Collections.HashMap

Import Collections.IMap
Import Collections.ICollection
Import Collections.ImmutableList

Type THashMap<K, V> Implements IMap<K, V>

	Private
	Const EMPTY:Int = -1

	Field _keys:K[]
	Field _values:V[]
	Field _dibs:Int[]      ' -1 = empty, >=0 distance from home
	Field _size:Int
	Field _version:Int
	Field _comparator:IComparator<K>
	
	Public

	Method New()
	End Method

	Method New(comparator:IComparator<K>)
		_comparator = comparator
	End Method

	Method New(initialCapacity:Int, comparator:IComparator<K> = Null)
		_comparator = comparator
		If initialCapacity > 0 Then
			EnsureCapacity(initialCapacity)
		End If
	End Method

	Method Count:Int()
		Return _size
	End Method

	Method IsEmpty:Int()
		Return _size = 0
	End Method

	Method Clear()
		_keys = Null
		_values = Null
		_dibs = Null
		_size = 0
		_version :+ 1
	End Method

	Method CopyTo(array:IMapNode<K,V>[], index:Int = 0)
		If _dibs = Null Then Return
		Local cap:Int = _dibs.Length
		Local iOut:Int = index
		For Local i:Int = 0 Until cap
			If _dibs[i] >= 0 Then
				array[iOut] = New THashMapNode<K,V>(Self, i)
				iOut :+ 1
			End If
		Next
	End Method

	Method GetIterator:IIterator<IMapNode<K,V>>()
		Return New THashMapIterator<K,V>(Self)
	End Method

	Method Keys:ICollection<K>()
		If _size = 0 Then
			Return New TEmptyImmutableList<K>
		End If

		Local keyArray:K[] = New K[_size]
		If _dibs Then
			Local idx:Int
			For Local i:Int = 0 Until _dibs.Length
				If _dibs[i] >= 0 Then
					keyArray[idx] = _keys[i]
					idx :+ 1
				End If
			Next
		End If
		Return New TImmutableList<K>(keyArray, True)
	End Method
	
	Method Values:ICollection<V>()
		If _size = 0 Then
			Return New TEmptyImmutableList<K>
		End If

		Local valueArray:V[] = New V[_size]
		Local idx:Int
		If _dibs Then
			For Local i:Int = 0 Until _dibs.Length
				If _dibs[i] >= 0 Then
					valueArray[idx] = _values[i]
					idx :+ 1
				End If
			Next
		End If
		Return New TImmutableList<V>(valueArray, True)
	End Method

	' Add: throws if key already exists
	Method Add(key:K, value:V)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			Throw New TArgumentException("An element with the same key already exists in the hash map")
		End If
		InsertNew(key, value)
	End Method

	' Put: upsert; returns old value or default/Null if new
	Method Put:V(key:K, value:V)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			Local old:V = _values[idx]
			_values[idx] = value
			_version :+ 1
			Return old
		End If

		InsertNew(key, value)

		Local def:V
		Return def
	End Method

	Method ContainsKey:Int(key:K)
		Return FindIndex(key) >= 0
	End Method

	Method Remove:Int(key:K)
		Local idx:Int = FindIndex(key)
		If idx < 0 Then
			Return False
		End If
		RemoveAt(idx)
		_version :+ 1
		Return True
	End Method

	Method TryGetValue:Int(key:K, value:V Var)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			value = _values[idx]
			Return True
		End If
		Return False
	End Method

	Method Operator [] :V(key:K)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			Return _values[idx]
		End If
		' default/Null value for V
		Local def:V
		Return def
	End Method

	Method Operator []= (key:K, value:V)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			_values[idx] = value
			_version :+ 1
		Else
			InsertNew(key, value)
		End If
	End Method

	Method ContainsValue:Int(value:V)
		If _dibs = Null Then Return False

		For Local i:Int = 0 Until _dibs.Length
			If _dibs[i] >= 0 Then
				If _values[i] = value Then
					Return True
				End If
			End If
		Next

		Return False
	End Method

	Private

	Method EnsureCapacity(minCount:Int)
		Local cap:Int
		If _dibs <> Null Then
			cap = _dibs.Length
		Else
			cap = 0
		End If

		If cap = 0 Then
			' Start with at least 8 slots
			Local newCap:Int = 8
			While newCap < minCount * 2
				newCap :* 2
			Wend
			Resize(newCap)
		Else
			' Resize when load factor exceeds ~0.8
			If Float(minCount) / Float(cap) > 0.8 Then
				Local newCap:Int = cap * 2
				Resize(newCap)
			End If
		End If
	End Method

	Method Resize(newCapacity:Int)
		Local oldKeys:K[] = _keys
		Local oldValues:V[] = _values
		Local oldDibs:Int[] = _dibs

		_keys = New K[newCapacity]
		_values = New V[newCapacity]
		_dibs = New Int[newCapacity]
		For Local i:Int = 0 Until newCapacity
			_dibs[i] = EMPTY
		Next

		_size = 0

		If oldDibs Then
			For Local i:Int = 0 Until oldDibs.Length
				If oldDibs[i] >= 0 Then
					InsertNewNoResize(oldKeys[i], oldValues[i])
				End If
			Next
		End If

		_version :+ 1
	End Method

	Method KeysEqual:Int(a:K, b:K)
		If _comparator Then
			Return _comparator.Compare(a, b) = 0
		Else
			' DefaultComparator_Compare is assumed to work for K
			Return DefaultComparator_Compare(a, b) = 0
		End If
	End Method

	Method GetHash:Int(key:K)
		Return Default_HashCode(key)
	End Method

	' Robin Hood lookup
	Method FindIndex:Int(key:K)
		If _dibs = Null Then Return -1

		Local cap:Int = _dibs.Length
		If cap = 0 Then Return -1

		Local hash:Int = GetHash(key) & $7fffffff
		Local idx:Int = hash Mod cap
		Local dib:Int = 0

		While True
			Local slotDib:Int = _dibs[idx]
			
			If slotDib = EMPTY Then
				' Hit an empty slot: key not present
				Return -1
			End If

			' If existing element has a smaller dib, our key would have stolen
			' its place if it were in the table, so we can stop.
			If slotDib < dib Then
				Return -1
			End If

			If KeysEqual(_keys[idx], key) Then
				Return idx
			End If

			idx = (idx + 1) Mod cap
			dib :+ 1
		Wend

		Return -1
	End Method

	' Public insert for new key
	Method InsertNew(key:K, value:V)
		EnsureCapacity(_size + 1)
		InsertNewNoResize(key, value)
	End Method

	' Core Robin Hood insertion, assumes table has space
	Method InsertNewNoResize(key:K, value:V)
		Local cap:Int = _dibs.Length
		Local hash:Int = GetHash(key) & $7fffffff
		Local idx:Int = hash Mod cap
		Local dibVal:Int = 0

		While True
			Local slotDib:Int = _dibs[idx]
			If slotDib = EMPTY Then
				' Empty slot: place here
				_keys[idx] = key
				_values[idx] = value
				_dibs[idx] = dibVal
				_size :+ 1
				_version :+ 1
				Return
			End If

			' Robin Hood step: if incoming dib is greater, swap
			If slotDib < dibVal Then
				' swap (key,value,dibVal) with occupant
				Local tmpKey:K = _keys[idx]
				Local tmpVal:V = _values[idx]
				Local tmpDib:Int = _dibs[idx]

				_keys[idx] = key
				_values[idx] = value
				_dibs[idx] = dibVal

				key = tmpKey
				value = tmpVal
				dibVal = tmpDib
			End If

			idx = (idx + 1) Mod cap
			dibVal :+ 1
		Wend
	End Method

	' Backwards-shift deletion
	Method RemoveAt(index:Int)
		Local cap:Int = _dibs.Length

		Local i:Int = index
		While True
			Local j:Int = (i + 1) Mod cap

			If _dibs[j] = EMPTY Or _dibs[j] = 0 Then
				' j is empty or its occupant is at home; just clear i and stop
				_dibs[i] = EMPTY

				' Clear key/value to allow GC if they are objects
				Local dk:K
				Local dv:V
				_keys[i] = dk
				_values[i] = dv

				Exit
			End If

			' shift j down to i
			_keys[i] = _keys[j]
			_values[i] = _values[j]
			_dibs[i] = _dibs[j] - 1
			i = j
		Wend

		_size :- 1
	End Method

End Type

Type THashMapNode<K, V> Implements IMapNode<K, V>

	Private
	Field map:THashMap<K,V>
	Field index:Int

	Public

	Method New(map:THashMap<K,V>, index:Int)
		Self.map = map
		Self.index = index
	End Method

	Method GetKey:K()
		Return map._keys[index]
	End Method

	Method GetValue:V()
		Return map._values[index]
	End Method

	Method HasNext:Int()
		If map._dibs = Null Then Return False
		Local cap:Int = map._dibs.Length
		Local i:Int = index + 1
		While i < cap
			If map._dibs[i] >= 0 Then
				Return True
			End If
			i :+ 1
		Wend
		Return False
	End Method

	Method NextNode:IMapNode<K,V>()
		If map._dibs = Null Then Return Null
		Local cap:Int = map._dibs.Length
		Local i:Int = index + 1
		While i < cap
			If map._dibs[i] >= 0 Then
				Return New THashMapNode<K,V>(map, i)
			End If
			i :+ 1
		Wend
		Return Null
	End Method

End Type

Type THashMapIterator<K, V> Implements IIterator<IMapNode<K,V>>

	Private
	Field map:THashMap<K,V>
	Field idx:Int
	Field currentNode:IMapNode<K,V>
	Field version:Int

	Public

	Method New(map:THashMap<K,V>)
		Self.map = map
		idx = -1
		version = map._version
	End Method

	Method Current:IMapNode<K,V>()
		Return currentNode
	End Method

	Method MoveNext:Int()
		If version <> map._version Then
			Throw New TInvalidOperationException("Collection was modified during iteration")
		End If

		If map._dibs = Null Then
			currentNode = Null
			Return False
		End If

		Local cap:Int = map._dibs.Length
		idx :+ 1
		While idx < cap
			If map._dibs[idx] >= 0 Then
				currentNode = New THashMapNode<K,V>(map, idx)
				Return True
			End If
			idx :+ 1
		Wend

		currentNode = Null
		Return False
	End Method

End Type
