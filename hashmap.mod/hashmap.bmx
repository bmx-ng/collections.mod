SuperStrict

Rem
bbdoc: Collections/HashMap
End Rem
Module Collections.HashMap

Import Collections.IMap
Import Collections.ICollection
Import Collections.ImmutableList
Import Collections.Errors

Rem
bbdoc: A generic hash map implementation using Robin Hood hashing.
about: #THashMap provides average O(1) lookup, insertion and removal of
key/value pairs. Keys are compared and hashed using an optional
#IEqualityComparator; when no comparator is supplied the default equality
and hash functions for the key type are used.

Iteration order is undefined. The map automatically resizes when the load
factor exceeds approximately 0.8.
End Rem
Type THashMap<K, V> Implements IMap<K, V>

	Internal
	Const EMPTY:Int = -1

	Field _keys:K[]
	Field _values:V[]
	Field _dibs:Int[]      ' -1 = empty, >=0 distance from home
	Field _size:Int
	Field _version:Int
	Field _comparator:IEqualityComparator<K>
	
	Public

	Rem
	bbdoc: Creates a new empty #THashMap using the default equality comparator.
	End Rem
	Method New()
	End Method

	Rem
	bbdoc: Creates a new empty #THashMap using the specified equality comparator.
	param: An optional equality comparator for the keys. When #Null the default equality and hash functions for type K are used.
	End Rem
	Method New(comparator:IEqualityComparator<K>)
		_comparator = comparator
	End Method

	Rem
	bbdoc: Creates a new #THashMap with the specified initial capacity.
	param: The initial number of entries the map should be able to hold before resizing.
	param: An optional equality comparator for the keys. When #Null the default equality and hash functions for type K are used.
	End Rem
	Method New(initialCapacity:Int, comparator:IEqualityComparator<K> = Null)
		_comparator = comparator
		If initialCapacity > 0 Then
			EnsureCapacity(initialCapacity)
		End If
	End Method

	Rem
	bbdoc: Gets the number of key/value pairs contained in the #THashMap.
	returns: The number of elements currently stored in the map.
	End Rem
	Method Count:Int()
		Return _size
	End Method

	Rem
	bbdoc: Returns #True if the #THashMap is empty, otherwise #False.
	End Rem
	Method IsEmpty:Int()
		Return _size = 0
	End Method

	Rem
	bbdoc: Removes all elements from the #THashMap.
	End Rem
	Method Clear()
		_keys = Null
		_values = Null
		_dibs = Null
		_size = 0
		_version :+ 1
	End Method

	Rem
	bbdoc: Copies the map entries into the supplied array starting at the given index.
	param: The destination array of #IMapNode entries.
	param: The zero-based index in @array at which copying begins.
	End Rem
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

	Rem
	bbdoc: Returns an iterator that iterates through the #THashMap.
	returns: An #IIterator over the map's #IMapNode entries.
	about: The iteration order is undefined. Modifying the map while an
	iterator is active throws #TInvalidOperationException.
	End Rem
	Method GetIterator:IIterator<IMapNode<K,V>>()
		Return New THashMapIterator<K,V>(Self)
	End Method

	Rem
	bbdoc: Returns a collection containing the map's keys.
	returns: An #ICollection of the keys currently stored in the map.
	End Rem
	Method Keys:ICollection<K>()
		If _size = 0 Then
			Return New TEmptyImmutableList<K>
		End If

		Return New THashMapKeysView<K,V>(Self)
	End Method
	
	Rem
	bbdoc: Returns a collection containing the map's values.
	returns: An #ICollection of the values currently stored in the map.
	about: Values are not required to be unique.
	End Rem
	Method Values:ICollection<V>()
		If _size = 0 Then
			Return New TEmptyImmutableList<V>
		End If

		Return New THashMapValuesView<K,V>(Self)
	End Method

	Rem
	bbdoc: Adds a new key/value association.
	param: The key to add.
	param: The value to associate with the key.
	about: Throws #TArgumentException if the key already exists in the map.

	Use #Put or the indexed assignment operator when an existing value should
	be replaced.
	End Rem
	Method Add(key:K, value:V)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			Throw New TArgumentException("An element with the same key already exists in the hash map")
		End If
		InsertNew(key, value)
	End Method

	Rem
	bbdoc: Adds or replaces a key/value association.
	param: The key to add or update.
	param: The value to associate with the key.
	returns: The value previously associated with the key, or the default value of type V if the key was not present.
	about: If the key does not exist, a new association is created. Otherwise the
	existing value associated with the key is replaced.
	End Rem
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

	Rem
	bbdoc: Determines whether the map contains a key.
	param: The key to locate.
	returns: #True if the key is present; otherwise #False.
	End Rem
	Method ContainsKey:Int(key:K)
		Return FindIndex(key) >= 0
	End Method

	Rem
	bbdoc: Removes the association for a key.
	param: The key to remove.
	returns: #True if the key was removed; otherwise #False.
	End Rem
	Method Remove:Int(key:K)
		Local idx:Int = FindIndex(key)
		If idx < 0 Then
			Return False
		End If
		RemoveAt(idx)
		_version :+ 1
		Return True
	End Method

	Rem
	bbdoc: Attempts to retrieve the value associated with a key.
	param: The key to locate.
	param: Receives the associated value if the key is found.
	returns: #True if the key exists; otherwise #False.
	about: Unlike the indexed access operator, this method distinguishes between a
	missing key and a key associated with the default value of type V.
	End Rem
	Method TryGetValue:Int(key:K, value:V Var)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			value = _values[idx]
			Return True
		End If
		Return False
	End Method

	Rem
	bbdoc: Returns the value associated with a key.
	param: The key to locate.
	returns: The value associated with the specified key, or the default value of type V if the key is not present.
	about: Use #ContainsKey or #TryGetValue when the key may not exist.
	End Rem
	Method Operator [] :V(key:K)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			Return _values[idx]
		End If
		' default/Null value for V
		Local def:V
		Return def
	End Method

	Rem
	bbdoc: Adds or replaces the value associated with a key.
	param: The key to add or update.
	param: The value to associate with the key.
	about: This operator behaves the same as #Put, except that the previous value is
	not returned.
	End Rem
	Method Operator []= (key:K, value:V)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			_values[idx] = value
			_version :+ 1
		Else
			InsertNew(key, value)
		End If
	End Method

	Rem
	bbdoc: Determines whether the map contains a specific value.
	param: The value to locate.
	returns: #True if the map contains an element with the specified value; otherwise #False.
	End Rem
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
			Return _comparator.Equals(a, b)
		End If

		' DefaultComparator_Compare is assumed to work for K
		Return DefaultComparator_Equals(a, b)
	End Method

	Method GetHash:Int(key:K)
		If _comparator Then
			Return _comparator.HashCode(key)
		End If
		
		' DefaultComparator_HashCode is assumed to work for K
		Return DefaultComparator_HashCode(key)
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

Rem
bbdoc: A single key/value entry in a #THashMap.
about: Represents a map entry at a specific slot in the underlying hash table.
Instances are typically obtained via iteration or #CopyTo rather than constructed
directly.
End Rem
Type THashMapNode<K, V> Implements IMapNode<K, V>

	Private
	Field map:THashMap<K,V>
	Field index:Int

	Public

	Rem
	bbdoc: Creates a node referencing the entry at the given index in the map.
	param: The #THashMap that owns this entry.
	param: The slot index of the entry within the map's internal arrays.
	End Rem
	Method New(map:THashMap<K,V>, index:Int)
		Self.map = map
		Self.index = index
	End Method

	Rem
	bbdoc: Returns the key stored in this node.
	returns: The key associated with this map entry.
	End Rem
	Method GetKey:K()
		Return map._keys[index]
	End Method

	Rem
	bbdoc: Returns the value stored in this node.
	returns: The value associated with this map entry.
	End Rem
	Method GetValue:V()
		Return map._values[index]
	End Method

	Rem
	bbdoc: Deconstructs this node into its key and value components.
	param: Receives the key associated with this map entry.
	param: Receives the value associated with this map entry.
	End Rem
	Method Deconstruct(keyOut:K Var, valueOut:V Var)
		keyOut = map._keys[index]
		valueOut = map._values[index]
	End Method

	Rem
	bbdoc: Determines whether another node follows this node.
	returns: #True if a subsequent node is available; otherwise #False.
	End Rem
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

	Rem
	bbdoc: Returns the next node in the sequence.
	returns: The next map node, or #Null if no further nodes exist.
	End Rem
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

Rem
bbdoc: An iterator over the entries of a #THashMap.
about: Yields #IMapNode instances. The iteration order is undefined.
Modifying the underlying map while the iterator is active throws
#TInvalidOperationException.
End Rem
Type THashMapIterator<K, V> Implements IIterator<IMapNode<K,V>>

	Private
	Field map:THashMap<K,V>
	Field idx:Int
	Field currentNode:IMapNode<K,V>
	Field version:Int

	Public

	Rem
	bbdoc: Creates a new iterator positioned before the first entry of the map.
	param: The #THashMap to iterate.
	End Rem
	Method New(map:THashMap<K,V>)
		Self.map = map
		idx = -1
		version = map._version
	End Method

	Rem
	bbdoc: Returns the current element in the iteration.
	End Rem
	Method Current:IMapNode<K,V>()
		Return currentNode
	End Method

	Rem
	bbdoc: Advances the iterator to the next element.
	returns: #True if the iterator was successfully advanced; otherwise #False.
	about: Throws #TInvalidOperationException if the underlying map was modified
	after the iterator was created.
	End Rem
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

Rem
bbdoc: A read-only view of the keys contained in a #THashMap.
about: The view is backed by the map; changes to the map are reflected in the
view. The view does not support modification (e.g. #Clear throws
#TUnsupportedOperationException). Iteration order is undefined.
End Rem
Type THashMapKeysView<K,V> Implements ICollection<K>
	Private
	Field _map:THashMap<K,V>

	Public
	Rem
	bbdoc: Creates a keys view for the specified map.
	param: The #THashMap whose keys are exposed by this view.
	End Rem
	Method New(map:THashMap<K,V>)
		_map = map
	End Method

	Rem
	bbdoc: Gets the number of keys in the view.
	End Rem
	Method Count:Int()
		Return _map.Count()
	End Method
	
	Rem
	bbdoc: Returns #True if the keys view is empty.
	End Rem
	Method IsEmpty:Int()
		Return _map.IsEmpty()
	End Method

	Rem
	bbdoc: Not supported. Throws #TUnsupportedOperationException.
	End Rem
	Method Clear()
		UnsupportedOperationError()
	End Method

	Rem
	bbdoc: Copies the keys into the supplied array starting at the given index.
	End Rem
	Method CopyTo(array:K[], index:Int = 0)
		Local i:Int = index
		If _map._dibs Then
			For Local p:Int = 0 Until _map._dibs.Length
				If _map._dibs[p] >= 0 Then
					array[i] = _map._keys[p]
					i :+ 1
				End If
			Next
		End If
	End Method

	Rem
	bbdoc: Returns an iterator over the keys.
	End Rem
	Method GetIterator:IIterator<K>()
		Return New THashMapKeysIterator<K,V>(_map)
	End Method
End Type

Rem
bbdoc: An iterator over the keys of a #THashMap.
about: The iteration order is undefined. Modifying the underlying map while
the iterator is active throws #TInvalidOperationException.
End Rem
Type THashMapKeysIterator<K,V> Implements IIterator<K>
	Private
	Field _map:THashMap<K,V>
	Field _idx:Int
	Field _current:K
	Field _version:Int

	Public
	Rem
	bbdoc: Creates a new keys iterator positioned before the first key.
	param: The #THashMap whose keys will be iterated.
	End Rem
	Method New(map:THashMap<K,V>)
		_map = map
		_idx = -1
		_version = map._version
	End Method

	Rem
	bbdoc: Returns the current key in the iteration.
	End Rem
	Method Current:K()
		Return _current
	End Method

	Rem
	bbdoc: Advances the iterator to the next key.
	returns: #True if the iterator was successfully advanced; otherwise #False.
	about: Throws #TInvalidOperationException if the underlying map was modified
	after the iterator was created.
	End Rem
	Method MoveNext:Int()
		If _version <> _map._version Then
			Throw New TInvalidOperationException("Collection was modified during iteration")
		End If
		If _map._dibs = Null Then
			Return False
		End If

		Local cap:Int = _map._dibs.Length
		Repeat
			_idx :+ 1
			If _idx >= cap Then
				Local def:K
				_current = def
				Return False
			End If
		Until _map._dibs[_idx] >= 0

		_current = _map._keys[_idx]
		Return True
	End Method
End Type

Rem
bbdoc: A read-only view of the values contained in a #THashMap.
about: The view is backed by the map; changes to the map are reflected in the
view. Values are not required to be unique. The view does not support
modification (e.g. #Clear throws #TUnsupportedOperationException).
Iteration order is undefined.
End Rem
Type THashMapValuesView<K,V> Implements ICollection<V>
	Private
	Field _map:THashMap<K,V>

	Public
	Rem
	bbdoc: Creates a values view for the specified map.
	param: The #THashMap whose values are exposed by this view.
	End Rem
	Method New(map:THashMap<K,V>)
		_map = map
	End Method

	Rem
	bbdoc: Gets the number of values in the view.
	End Rem
	Method Count:Int()
		Return _map.Count()
	End Method

	Rem
	bbdoc: Returns #True if the values view is empty.
	End Rem
	Method IsEmpty:Int()
		Return _map.IsEmpty()
	End Method

	Rem
	bbdoc: Not supported. Throws #TUnsupportedOperationException.
	End Rem
	Method Clear()
		UnsupportedOperationError()
	End Method

	Rem
	bbdoc: Copies the values into the supplied array starting at the given index.
	End Rem
	Method CopyTo(array:V[], index:Int = 0)
		Local i:Int = index
		If _map._dibs Then
			For Local p:Int = 0 Until _map._dibs.Length
				If _map._dibs[p] >= 0 Then
					array[i] = _map._values[p]
					i :+ 1
				End If
			Next
		End If
	End Method

	Rem
	bbdoc: Returns an iterator over the values.
	End Rem
	Method GetIterator:IIterator<V>()
		Return New THashMapValuesIterator<K,V>(_map)
	End Method
End Type

Rem
bbdoc: An iterator over the values of a #THashMap.
about: The iteration order is undefined. Modifying the underlying map while
the iterator is active throws #TInvalidOperationException.
End Rem
Type THashMapValuesIterator<K,V> Implements IIterator<V>
	Private
	Field _map:THashMap<K,V>
	Field _idx:Int
	Field _current:V
	Field _version:Int

	Public
	Rem
	bbdoc: Creates a new values iterator positioned before the first value.
	param: The #THashMap whose values will be iterated.
	End Rem
	Method New(map:THashMap<K,V>)
		_map = map
		_idx = -1
		_version = map._version
	End Method

	Rem
	bbdoc: Returns the current value in the iteration.
	End Rem
	Method Current:V()
		Return _current
	End Method

	Rem
	bbdoc: Advances the iterator to the next value.
	returns: #True if the iterator was successfully advanced; otherwise #False.
	about: Throws #TInvalidOperationException if the underlying map was modified
	after the iterator was created.
	End Rem
	Method MoveNext:Int()
		If _version <> _map._version Then
			Throw New TInvalidOperationException("Collection was modified during iteration")
		End If

		If _map._dibs = Null Then
			Local def:V
			_current = def
			Return False
		End If

		Local cap:Int = _map._dibs.Length
		Repeat
			_idx :+ 1
			If _idx >= cap Then
				Local def2:V
				_current = def2
				Return False
			End If
		Until _map._dibs[_idx] >= 0

		_current = _map._values[_idx]
		Return True
	End Method
End Type