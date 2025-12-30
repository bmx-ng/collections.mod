SuperStrict

Module Collections.LinkedHashMap

Import Collections.IMap
Import Collections.immutablelist

Rem
bbdoc: A hash map that maintains insertion order or access order of its entries.
about: This is a hash map implementation that maintains a doubly-linked list of its entries to
preserve insertion order or access order (for LRU caching). It supports optional maximum size
with automatic eviction of least-recently-used entries.
End Rem
Type TLinkedHashMap<K, V> Implements IMap<K, V>

	Private
	Const EMPTY:Int = -1

	Field _entries:TLinkedHashEntry<K,V>[]  ' table slots hold entry refs
	Field _dibs:Int[]
	Field _size:Int
	Field _version:Int
	Field _comparator:IEqualityComparator<K>

	' insertion-order list
	Field _head:TLinkedHashEntry<K,V>
	Field _tail:TLinkedHashEntry<K,V>

	' options for lru and fifo eviction
	Field _accessOrder:Int     ' False=Insertion order (default), True=Access order (LRU)
	Field _maxSize:Int         ' 0 = unbounded; >0 = max entries, evict LRU on insert

	Public

	Method New()
	End Method

	Rem
	bbdoc: Creates a new #TLinkedHashMap.
	about: @comparator is an optional equality comparator for the keys.
	If @accessOrder is #True, the map maintains access order (LRU) instead of insertion order.
	If @maxSize is greater than 0, the map will either evict least-recently-used entries when the size exceeds maxSize, or if @accessOrder is #False (the default), evict oldest entries (FIFO).
	End Rem
	Method New(comparator:IEqualityComparator<K>, accessOrder:Int = False, maxSize:Int = 0)
		_comparator = comparator
		_accessOrder = accessOrder
		_maxSize = maxSize
	End Method

	Rem
	bbdoc: Creates a new #TLinkedHashMap with an initial capacity.
	about: @initialCapacity is the initial capacity of the map.
	@comparator is an optional equality comparator for the keys.
	If @accessOrder is #True, the map maintains access order (LRU) instead of insertion order.
	If @maxSize is greater than 0, the map will either evict least-recently-used entries when the size exceeds maxSize, or if @accessOrder is #False (the default), evict oldest entries (FIFO).
	End Rem
	Method New(initialCapacity:Int, comparator:IEqualityComparator<K> = Null, accessOrder:Int = False, maxSize:Int = 0)
		_comparator = comparator
		_accessOrder = accessOrder
		_maxSize = maxSize
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
		_entries = Null
		_dibs = Null
		_size = 0
		_head = Null
		_tail = Null
		_version :+ 1
	End Method

	Method GetIterator:IIterator<IMapNode<K,V>>()
		Return New TLinkedHashMapIterator<K,V>(Self)
	End Method

	Method Keys:ICollection<K>()
		If _size = 0 Then
			Return New TEmptyImmutableList<K>
		End If
		Return New TLinkedHashMapKeysView<K,V>(Self)
	End Method

	Method Values:ICollection<V>()
		If _size = 0 Then
			Return New TEmptyImmutableList<V>
		End If
		Return New TLinkedHashMapValuesView<K,V>(Self)
	End Method

	Method CopyTo(array:IMapNode<K,V>[], index:Int = 0)
		Local i:Int = index
		Local n:TLinkedHashEntry<K,V> = _head
		While n
			array[i] = n
			i :+ 1
			n = n._next
		Wend
	End Method

	Method Add(key:K, value:V)
		If FindIndex(key) >= 0 Then
			Throw New TArgumentException("An element with the same key already exists in the map")
		End If
		InsertNew(key, value)
	End Method

	Method Put:V(key:K, value:V)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			Local e:TLinkedHashEntry<K,V> = _entries[idx]
			Local old:V = e._value
			e._value = value
			If Not Touch(e) Then ' treat update as access
				_version :+ 1
			End If
			Return old
		End If

		InsertNew(key, value)
		Local def:V
		Return def
	End Method

	Method ContainsKey:Int(key:K)
		Return FindIndex(key) >= 0
	End Method

	Method TryGetValue:Int(key:K, value:V Var)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			Local e:TLinkedHashEntry<K,V> = _entries[idx]
			value = e._value
			Touch(e)
			Return True
		End If
		Return False
	End Method

	Method Operator [] :V(key:K)
		Local idx:Int = FindIndex(key)
		If idx >= 0 Then
			Local e:TLinkedHashEntry<K,V> = _entries[idx]
			Local value:V = e._value
			Touch(e)
			Return value
		End If
		Local def:V
		Return def
	End Method

	Method Operator []= (key:K, value:V)
		Put(key, value)
	End Method

	Method Remove:Int(key:K)
		Local idx:Int = FindIndex(key)
		If idx < 0 Then
			Return False
		End If

		' unlink entry from list first
		Unlink(_entries[idx])

		RemoveAt(idx)
		_version :+ 1
		Return True
	End Method

	Method ContainsValue:Int(value:V)
		Local n:TLinkedHashEntry<K,V> = _head
		While n
			If n._value = value Then
				Return True
			End If
			n = n._next
		Wend
		Return False
	End Method

	Rem
	bbdoc: Sets the maximum size of the map. If the current size exceeds maxSize, the least-recently-used entries will be evicted.
	about: A maxSize of 0 means the map is unbounded.
	End Rem
	Method SetMaxSize(maxSize:Int)
		_maxSize = maxSize
		EvictIfNeeded()
	End Method

	' -----------------------
	' Internals
	' -----------------------
	Private

	Method KeysEqual:Int(a:K, b:K)
		If _comparator Then
			Return _comparator.Equals(a, b)
		End If
		Return DefaultComparator_Equals(a, b)
	End Method

	Method GetHash:Int(key:K)
		If _comparator Then
			Return _comparator.HashCode(key)
		End If
		Return DefaultComparator_HashCode(key)
	End Method

	Method EnsureCapacity(minCount:Int)
		Local cap:Int = 0
		If _dibs Then
			cap = _dibs.Length
		End If

		If cap = 0 Then
			Local newCap:Int = 8
			While newCap < minCount * 2
				newCap :* 2
			Wend
			Resize(newCap)
		Else
			If Float(minCount) / Float(cap) > 0.8 Then
				Resize(cap * 2)
			End If
		End If
	End Method

	Method Resize(newCapacity:Int)
		Local oldEntries:TLinkedHashEntry<K,V>[] = _entries
		Local oldDibs:Int[] = _dibs

		_entries = New TLinkedHashEntry<K,V>[newCapacity]
		_dibs = New Int[newCapacity]
		For Local i:Int = 0 Until newCapacity
			_dibs[i] = EMPTY
		Next

		' Rebuild the table by walking insertion order.
		_size = 0
		Local n:TLinkedHashEntry<K,V> = _head
		While n
			InsertEntryNoResize(n)
			n = n._next
		Wend

		_version :+ 1
	End Method

	Method FindIndex:Int(key:K)
		If _dibs = Null Then
			Return -1
		End If

		Local cap:Int = _dibs.Length
		If cap = 0 Then
			Return -1
		End If

		Local hash:Int = GetHash(key) & $7fffffff
		Local idx:Int = hash Mod cap
		Local dib:Int = 0

		While True
			Local slotDib:Int = _dibs[idx]
			If slotDib = EMPTY Then
				Return -1
			End If
			If slotDib < dib Then
				Return -1
			End If

			Local e:TLinkedHashEntry<K,V> = _entries[idx]
			If e And KeysEqual(e._key, key) Then
				Return idx
			End If

			idx = (idx + 1) Mod cap
			dib :+ 1
		Wend
	End Method

	Method LinkLast(e:TLinkedHashEntry<K,V>)
		e._prev = _tail
		e._next = Null
		If _tail Then
			_tail._next = e
		Else
			_head = e
		End If
		_tail = e
	End Method

	Method Unlink(e:TLinkedHashEntry<K,V>)
		Local p:TLinkedHashEntry<K,V> = e._prev
		Local n:TLinkedHashEntry<K,V> = e._next

		If p Then
			p._next = n
		Else
			_head = n
		End If
		
		If n Then
			n._prev = p
		Else
			_tail = p
		End If

		e._prev = Null
		e._next = Null
	End Method

	Method InsertNew(key:K, value:V)
		EnsureCapacity(_size + 1)
		Local e:TLinkedHashEntry<K,V> = New TLinkedHashEntry<K,V>
		e._key = key
		e._value = value
		e._map = Self
		LinkLast(e)
		InsertEntryNoResize(e)
		_version :+ 1

		EvictIfNeeded()
	End Method

	Method InsertEntryNoResize(e:TLinkedHashEntry<K,V>)
		Local cap:Int = _dibs.Length
		Local hash:Int = GetHash(e._key) & $7fffffff
		Local idx:Int = hash Mod cap
		Local dibVal:Int = 0

		While True
			Local slotDib:Int = _dibs[idx]
			If slotDib = EMPTY Then
				_entries[idx] = e
				_dibs[idx] = dibVal
				_size :+ 1
				Return
			End If

			If slotDib < dibVal Then
				' swap entry refs (linked list pointers remain inside entry objects)
				Local tmpE:TLinkedHashEntry<K,V> = _entries[idx]
				Local tmpDib:Int = _dibs[idx]

				_entries[idx] = e
				_dibs[idx] = dibVal

				e = tmpE
				dibVal = tmpDib
			End If

			idx = (idx + 1) Mod cap
			dibVal :+ 1
		Wend
	End Method

	Method RemoveAt(index:Int)
		Local cap:Int = _dibs.Length
		Local i:Int = index

		While True
			Local j:Int = (i + 1) Mod cap

			If _dibs[j] = EMPTY Or _dibs[j] = 0 Then
				_dibs[i] = EMPTY
				_entries[i] = Null
				Exit
			End If

			_entries[i] = _entries[j]
			_dibs[i] = _dibs[j] - 1

			i = j
		Wend

		_size :- 1
	End Method

	Method Touch:Int(entry:TLinkedHashEntry<K,V>)
		' Only when access-order mode is enabled and entry isn't already the tail
		If Not _accessOrder Then
			Return False
		End If

		If entry = Null Then
			Return False
		End If

		If entry = _tail Then
			Return False
		End If
		
		Unlink(entry)
		LinkLast(entry)
		_version :+ 1
		Return True
	End Method

	Method EvictIfNeeded()
		If _maxSize <= 0 Then Return

		' Evict LRU entries from the head until size <= maxSize
		While _size > _maxSize And _head
			Local k:K = _head._key
			Remove(k)
		Wend
	End Method

End Type

Type TLinkedHashEntry<K,V> Implements IMapNode<K,V>
	Field _key:K
	Field _value:V

	' doubly-linked insertion order
	Field _prev:TLinkedHashEntry<K,V>
	Field _next:TLinkedHashEntry<K,V>

	' owning map (optional, only needed for version/validation if you want)
	Field _map:TLinkedHashMap<K,V>

	Method GetKey:K()
		Return _key
	End Method

	Method GetValue:V()
		Return _value
	End Method

	Method HasNext:Int()
		Return _next <> Null
	End Method

	Method NextNode:IMapNode<K,V>()
		Return _next
	End Method
End Type

Type TLinkedHashMapIterator<K,V> Implements IIterator<IMapNode<K,V>>
	Private
	Field map:TLinkedHashMap<K,V>
	Field node:TLinkedHashEntry<K,V>
	Field started:Int
	Field version:Int

	Public
	Method New(map:TLinkedHashMap<K,V>)
		Self.map = map
		version = map._version
	End Method

	Method Current:IMapNode<K,V>()
		Return node
	End Method

	Method MoveNext:Int()
		If version <> map._version Then
			Throw New TInvalidOperationException("Collection was modified during iteration")
		End If

		If Not started Then
			started = True
			node = map._head
			Return node <> Null
		End If

		If node Then
			node = node._next
			Return node <> Null
		End If

		Return False
	End Method
End Type

Type TLinkedHashMapKeysView<K,V> Implements ICollection<K>
	Private
	Field _map:TLinkedHashMap<K,V>

	Public
	Method New(map:TLinkedHashMap<K,V>)
		Self._map = map
	End Method

	Method Count:Int()
		Return _map.Count()
	End Method

	Method IsEmpty:Int()
		Return _map.IsEmpty()
	End Method

	Method Clear()
		UnsupportedOperationError()
	End Method

	Method CopyTo(arr:K[], index:Int = 0)
		Local i:Int = index
		Local n:TLinkedHashEntry<K,V> = _map._head
		While n
			arr[i] = n._key
			i:+1
			n = n._next
		Wend
	End Method

	Method GetIterator:IIterator<K>()
		Return New TLinkedHashMapKeysIterator<K,V>(_map)
	End Method
End Type

Type TLinkedHashMapKeysIterator<K,V> Implements IIterator<K>
	Private
	Field _map:TLinkedHashMap<K,V>
	Field _node:TLinkedHashEntry<K,V>
	Field _started:Int
	Field _version:Int
	Field _current:K

	Public
	Method New(map:TLinkedHashMap<K,V>)
		Self._map = map
		_version = map._version
	End Method

	Method Current:K()
		Return _current
	End Method

	Method MoveNext:Int()
		If _version <> _map._version Then
			Throw New TInvalidOperationException("Collection was modified during iteration")
		End If

		If Not _started Then
			_started = True
			_node = _map._head
		ElseIf _node Then
			_node = _node._next
		End If

		If _node Then
			_current = _node._key
			Return True
		End If

		Local def:K
		_current = def
		Return False
	End Method
End Type

Type TLinkedHashMapValuesView<K,V> Implements ICollection<V>
	Private
	Field _map:TLinkedHashMap<K,V>

	Public
	Method New(map:TLinkedHashMap<K,V>)
		Self._map = map
	End Method

	Method Count:Int()
		Return _map.Count()
	End Method

	Method IsEmpty:Int()
		Return _map.IsEmpty()
	End Method

	Method Clear()
		UnsupportedOperationError()
	End Method

	Method CopyTo(array:V[], index:Int = 0)
		Local i:Int = index
		Local n:TLinkedHashEntry<K,V> = _map._head
		While n
			array[i] = n._value
			i :+ 1
			n = n._next
		Wend
	End Method

	Method GetIterator:IIterator<V>()
		Return New TLinkedHashMapValuesIterator<K,V>(_map)
	End Method
End Type

Type TLinkedHashMapValuesIterator<K,V> Implements IIterator<V>
	Private
	Field _map:TLinkedHashMap<K,V>
	Field _node:TLinkedHashEntry<K,V>
	Field _started:Int
	Field _version:Int
	Field _current:V

	Public
	Method New(map:TLinkedHashMap<K,V>)
		Self._map = map
		_version = map._version
	End Method

	Method Current:V()
		Return _current
	End Method

	Method MoveNext:Int()
		If _version <> _map._version Then
			Throw New TInvalidOperationException("Collection was modified during iteration")
		End If

		If Not _started Then
			_started = True
			_node = _map._head
		ElseIf _node Then
			_node = _node._next
		End If

		If _node Then
			_current = _node._value
			Return True
		End If

		Local def:V
		_current = def
		Return False
	End Method
End Type
