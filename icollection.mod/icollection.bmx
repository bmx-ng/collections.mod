SuperStrict

Rem
bbdoc: Collection interface.
about: A collection represents a group of values that can be queried and enumerated.
End Rem
Module Collections.ICollection

Rem
bbdoc: Collection interface.
about: A collection represents a group of values that can be queried and
enumerated.

Collections provide the number of contained values, can be copied into an
array, and support iteration through the #IIterable interface.
EndRem
Interface ICollection<T> Extends IIterable<T>

	Rem
	bbdoc: Returns the number of values in the collection.
	returns: The number of values contained in the collection.
	EndRem
	Method Count:Int()

	Rem
	bbdoc: Copies the collection to an array.
	param: The destination array.
	param: The array index at which copying begins.
	about:
	Values are copied in the collection's iteration order.

	The destination array must have sufficient space to receive all copied
	values.
	EndRem
	Method CopyTo(array:T[], index:Int = 0)

	Rem
	bbdoc: Determines whether the collection contains any values.
	returns: #True if the collection contains no values; otherwise #False.
	about:
	This method is equivalent to testing whether #Count returns zero, but
	may be more efficient for some implementations.
	EndRem
	Method IsEmpty:Int()

	Rem
	bbdoc: Removes all values from the collection.
	about:
	After this method completes, #Count returns zero and #IsEmpty returns
	#True.
	EndRem
	Method Clear()

End Interface

