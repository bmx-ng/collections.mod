SuperStrict

Rem
bbdoc: Collections/HashSet
about: A hash-based set implementation that stores unique elements with average O(1) add, remove and contains operations.
It is backed by a #THashMap and does not maintain any particular element order.
End Rem
Module Collections.HashSet

Import Collections.ISet
Import Collections.HashMap
Import Collections.ArrayList

Rem
bbdoc: Represents a set of unique elements backed by a hash table.
about: Duplicate elements are not allowed. Equality and hashing are determined by the optional #IEqualityComparator supplied at construction time (or the default comparator for type T).
End Rem
Type THashSet<T> Implements ISet<T>

Private
	Field map:THashMap<T,Byte>  ' compact dummy value, always 1

Public

	Rem
	bbdoc: Creates an empty #THashSet using the default comparator/hash for T.
	End Rem
	Method New()
		map = New THashMap<T,Byte>
	End Method

	Rem
	bbdoc: Creates an empty #THashSet using the specified comparator.
	End Rem
	Method New(comparator:IEqualityComparator<T>)
		map = New THashMap<T,Byte>(comparator)
	End Method

	Rem
	bbdoc: Creates a #THashSet initialised from an array of elements.
	End Rem
	Method New(array:T[], comparator:IEqualityComparator<T> = Null)
		Local initialCapacity:Int
		If array Then initialCapacity = array.Length
		map = New THashMap<T,Byte>(initialCapacity, comparator)
		If array Then
			For Local element:T = EachIn array
				Add(element)
			Next
		End If
	End Method

	Rem
	bbdoc: Creates a #THashSet initialised from an #IIterable of elements.
	End Rem
	Method New(iterable:IIterable<T>, comparator:IEqualityComparator<T> = Null)
		Local collection:ICollection<T> = ICollection<T>(iterable)
		Local initialCapacity:Int
		If collection Then initialCapacity = collection.Count()
		map = New THashMap<T,Byte>(initialCapacity, comparator)
		If iterable Then
			For Local element:T = EachIn iterable
				Add(element)
			Next
		End If
	End Method

	' ------------------------------
	' IIterable<T>
	' ------------------------------
	Rem
	bbdoc: Returns an iterator that iterates through the elements of the set.
	End Rem
	Method GetIterator:IIterator<T>() Override
		Return New THashSetIterator<T>(map)
	End Method

	' ------------------------------
	' ICollection<T>
	' ------------------------------
	Rem
	bbdoc: Gets the number of elements contained in the set.
	End Rem
	Method Count:Int() Override
		Return map.Count()
	End Method

	Rem
	bbdoc: Copies the elements of the set to an array, starting at the specified array index.
	End Rem
	Method CopyTo(array:T[], index:Int = 0) Override
		map.Keys().CopyTo(array, index)
	End Method

	Rem
	bbdoc: Returns #True if the set contains no elements; otherwise, #False.
	End Rem
	Method IsEmpty:Int() Override
		Return map.IsEmpty()
	End Method

	Rem
	bbdoc: Removes all elements from the set.
	End Rem
	Method Clear() Override
		map.Clear()
	End Method

	Rem
	bbdoc: Reduces the allocated storage to the smallest capacity suitable for the current elements.
	about: Trimming an empty set releases all table storage.
	End Rem
	Method TrimExcess()
		map.TrimExcess()
	End Method

	' ------------------------------
	' ISet<T> – basic operations
	' ------------------------------

	Rem
	bbdoc: Adds an element to the set.
	returns: #True if the element was added; #False if it was already present.
	End Rem
	Method Add:Int(element:T) Override
		Return map.TryAdd(element, Byte(1))
	End Method

	Rem
	bbdoc: Determines whether the set contains the specified element.
	returns: #True if the element is found; otherwise, #False.
	End Rem
	Method Contains:Int(element:T) Override
		Return map.ContainsKey(element)
	End Method

	Rem
	bbdoc: Removes a specified element from the set.
	returns: #True if the element was found and removed; otherwise, #False.
	End Rem
	Method Remove:Int(element:T) Override
		Return map.Remove(element)
	End Method

	' ------------------------------
	' ISet<T> – set algebra
	' ------------------------------

	Rem
	bbdoc: Removes any element in the current set that is also in @other.
	about: After this operation the set contains only those elements that do not appear in @other.
	End Rem
	Method Complement(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		If IsEmpty() Then
			Return
		End If

		If other = Self Then
			Clear()
			Return
		End If

		Local setOther:THashSet<T> = THashSet<T>(other)
		If setOther Then
			For Local element:T = EachIn setOther
				Remove(element)
			Next
		Else
			For Local element:T = EachIn other
				Remove(element)
			Next
		End If
	End Method

	Rem
	bbdoc: Modifies the current set so that it contains only elements that are also in @other.
	End Rem
	Method Intersection(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		If IsEmpty() Then
			Return
		End If

		If other = Self Then
			' A ∩ A = A
			Return
		End If

		Local setOther:THashSet<T> = THashSet<T>(other)
		If Not setOther Then
			setOther = New THashSet<T>(other)
		End If

		' Collect elements to remove (can't modify underlying map while iterating it)
		Local toRemove:TArrayList<T> = New TArrayList<T>()
		For Local element:T = EachIn Self
			If Not setOther.Contains(element) Then
				toRemove.Add(element)
			End If
		Next

		For Local element:T = EachIn toRemove
			Remove(element)
		Next
	End Method

	Rem
	bbdoc: Determines whether the set is a proper subset of @other.
	returns: #True if every element of this set exists in @other and @other contains at least one additional element; otherwise #False.
	End Rem
	Method IsProperSubsetOf:Int(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		' Build a hash set from other (or reuse if it's already a THashSet)
		Local setOther:THashSet<T> = THashSet<T>(other)
		Local otherCount:Int
		If setOther Then
			otherCount = setOther.Count()
		Else
			setOther = New THashSet<T>(other)
			otherCount = setOther.Count()
		End If

		If Count() >= otherCount Then
			Return False
		End If

		For Local element:T = EachIn Self
			If Not setOther.Contains(element) Then
				Return False
			End If
		Next

		Return True
	End Method

	Rem
	bbdoc: Determines whether the set is a proper superset of @other.
	returns: #True if every element of @other exists in this set and this set contains at least one additional element; otherwise #False.
	End Rem
	Method IsProperSupersetOf:Int(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		If IsEmpty() Then
			Return False
		End If

		Local coll:ICollection<T> = ICollection<T>(other)
		If coll Then
			If coll.Count() = 0 Then
				' Non-empty set is always a proper superset of empty
				Return Count() > 0
			End If
			If Count() <= coll.Count() Then
				Return False
			End If
		End If

		For Local element:T = EachIn other
			If Not Contains(element) Then
				Return False
			End If
		Next

		Return True
	End Method

	Rem
	bbdoc: Determines whether the set is a subset of @other.
	returns: #True if every element of this set exists in @other; otherwise #False.
	End Rem
	Method IsSubsetOf:Int(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		If IsEmpty() Then
			' Empty set is subset of any collection (including empty)
			Return True
		End If

		Local setOther:THashSet<T> = THashSet<T>(other)
		If setOther Then
			If Count() > setOther.Count() Then
				Return False
			End If
		Else
			setOther = New THashSet<T>(other)
			If Count() > setOther.Count() Then
				Return False
			End If
		End If

		For Local element:T = EachIn Self
			If Not setOther.Contains(element) Then
				Return False
			End If
		Next

		Return True
	End Method

	Rem
	bbdoc: Determines whether the set is a superset of @other.
	returns: #True if every element of @other exists in this set; otherwise #False.
	End Rem
	Method IsSupersetOf:Int(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		Local coll:ICollection<T> = ICollection<T>(other)
		If coll Then
			If coll.Count() = 0 Then
				' Any set is a superset of the empty set
				Return True
			End If
		End If

		If IsEmpty() Then
			Return False
		End If

		For Local element:T = EachIn other
			If Not Contains(element) Then
				Return False
			End If
		Next

		Return True
	End Method

	Rem
	bbdoc: Determines whether the current set and @other share at least one common element.
	returns: #True if the collections contain at least one value in common; otherwise #False.
	End Rem
	Method Overlaps:Int(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		If IsEmpty() Then
			Return False
		End If

		For Local element:T = EachIn other
			If Contains(element) Then
				Return True
			End If
		Next

		Return False
	End Method

	Rem
	bbdoc: Modifies the current set so that it contains only elements that are present either in the current set or in @other, but not both.
	End Rem
	Method SymmetricDifference(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		If IsEmpty() Then
			UnionOf(other)
			Return
		End If

		If other = Self Then
			Clear()
			Return
		End If

		Local setOther:THashSet<T> = THashSet<T>(other)
		If Not setOther Then
			setOther = New THashSet<T>(other)
		End If

		For Local element:T = EachIn setOther
			If Contains(element) Then
				Remove(element)
			Else
				Add(element)
			End If
		Next
	End Method

	Rem
	bbdoc: Modifies the current set so that it contains all elements present in either the current set or @other.
	End Rem
	Method UnionOf(other:IIterable<T>)
		If Not other Then
			Throw New TArgumentNullException("other")
		End If

		If other = Self Then
			Return
		End If

		For Local element:T = EachIn other
			Add(element)
		Next
	End Method

	' ------------------------------
	' Extras (not required by ISet<T>, but handy)
	' ------------------------------

	Rem
	bbdoc: Searches the set for a given value and returns the equal value it finds, if any.
	returns: #True if an equal value was found; otherwise #False. When #True, @actualValue receives the stored element.
	End Rem
	Method TryGetValue:Int(value:T, actualValue:T Var)
		If Contains(value) Then
			actualValue = value
			Return True
		End If
		Return False
	End Method

	Rem
	bbdoc: Converts the set to an array of elements.
	returns: A new array containing every element of the set.
	End Rem
	Method ToArray:T[]()
		Local arr:T[Count()]
		CopyTo(arr)
		Return arr
	End Method

End Type

Rem
bbdoc: Iterator over #THashSet elements, backed by the underlying #THashMap iterator.
End Rem
Type THashSetIterator<T> Implements IIterator<T>

Private
	Field inner:IIterator<T>
	Field currentElement:T

Public

	Rem
	bbdoc: Creates a new iterator for the given map.
	End Rem
	Method New(map:THashMap<T,Byte>)
		inner = map.Keys().GetIterator()
	End Method

	Rem
	bbdoc: Gets the element at the current position of the iterator.
	End Rem
	Method Current:T()
		Return currentElement
	End Method

	Rem
	bbdoc: Advances the iterator to the next element of the set.
	returns: #True if the iterator was successfully advanced to the next element; #False if the iterator has passed the end of the collection.
	End Rem
	Method MoveNext:Int()
		If inner.MoveNext() Then
			currentElement = inner.Current()
			Return True
		End If
		Local def:T
		currentElement = def
		Return False
	End Method

End Type
