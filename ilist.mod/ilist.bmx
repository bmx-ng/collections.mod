SuperStrict

Rem
bbdoc: Collections/List
about: Lists are ordered collections that support indexed access, insertion and removal.
End Rem
Module Collections.IList

Import Collections.ICollection

Rem
bbdoc: List interface.
about: A list is an ordered collection of values that can be accessed by a zero-based index.

Unlike a set, a list may contain duplicate values. The order of elements is defined by the
list implementation and is preserved by insertion and removal operations.

In addition to the operations provided by #ICollection, a list supports indexed access,
searching for the position of a value, and insertion or removal at a specific index.
EndRem
Interface IList<T> Extends ICollection<T>

	Rem
	bbdoc: Adds a value to the end of the list.
	param: The value to add.
	about: After this method completes, the new value is the last element in the list and
	#Count is increased by one.
	EndRem
	Method Add(element:T)

	Rem
	bbdoc: Determines whether the list contains a value.
	param: The value to locate.
	returns: #True if the value is found; otherwise #False.
	about: Equality is determined by the list implementation (typically reference equality
	for objects, or value equality for primitive types).
	EndRem
	Method Contains:Int(element:T)

	Rem
	bbdoc: Returns the value at the specified index.
	param: The zero-based index of the value to retrieve.
	returns: The value at the specified index.
	about: Throws #TIndexOutOfBoundsException if @index is less than zero or greater than
	or equal to #Count.
	EndRem
	Method Get:T(index:Int)

	Rem
	bbdoc: Returns the zero-based index of the first occurrence of a value.
	param: The value to locate.
	returns: The zero-based index of the first occurrence of @element, or -1 if the value is not found.
	EndRem
	Method IndexOf:Int(element:T)

	Rem
	bbdoc: Inserts a value at the specified index.
	param: The zero-based index at which the value should be inserted.
	param: The value to insert.
	about: Existing values at or after @index are shifted one position toward the end of
	the list. @index may be equal to #Count, in which case the value is appended.

	Throws #TIndexOutOfBoundsException if @index is less than zero or greater than #Count.
	EndRem
	Method Insert(index:Int, element:T)

	Rem
	bbdoc: Returns the zero-based index of the last occurrence of a value.
	param: The value to locate.
	returns: The zero-based index of the last occurrence of @element, or -1 if the value is not found.
	EndRem
	Method LastIndexOf:Int(element:T)

	Rem
	bbdoc: Removes the first occurrence of a value from the list.
	param: The value to remove.
	returns: #True if the value was found and removed; otherwise #False.
	about: Only the first matching occurrence is removed. Subsequent occurrences (if any)
	remain in the list.
	EndRem
	Method Remove:Int(element:T)

	Rem
	bbdoc: Removes the value at the specified index.
	param: The zero-based index of the value to remove.
	returns: The value that was removed from the list.
	about: Values after the removed index are shifted one position toward the start of the list.

	Throws #TIndexOutOfBoundsException if @index is less than zero or greater than or equal
	to #Count.
	EndRem
	Method RemoveAt:T(index:Int)

	Rem
	bbdoc: Replaces the value at the specified index.
	param: The zero-based index of the value to replace.
	param: The new value.
	about: Throws #TIndexOutOfBoundsException if @index is less than zero or greater than
	or equal to #Count.
	EndRem
	Method Set(index:Int, value:T)

	Rem
	bbdoc: Returns the value at the specified index.
	param: The zero-based index of the value to retrieve.
	returns: The value at the specified index.
	about: Equivalent to #Get. Throws #TIndexOutOfBoundsException if @index is out of range.
	EndRem
	Method Operator [] :T(index:Int)

	Rem
	bbdoc: Replaces the value at the specified index.
	param: The zero-based index of the value to replace.
	param: The new value.
	about: Equivalent to #Set. Throws #TIndexOutOfBoundsException if @index is out of range.
	EndRem
	Method Operator []= (index:Int, value:T)

End Interface