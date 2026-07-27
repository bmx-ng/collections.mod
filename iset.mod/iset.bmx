SuperStrict

Rem
bbdoc: Collections/Set
about: Sets are collections that contain no duplicate values.
Each value is either present in the set or absent from it.
End Rem
Module Collections.ISet

Import Collections.ICollection

Rem
bbdoc: Set interface.
about: A set is a collection that contains no duplicate values. Each value is
either present in the set or absent from it.

Membership is determined using the set's equality comparison, so adding an
existing value has no effect.

In addition to basic operations such as adding, removing and testing for
membership, a set supports standard set algebra including union,
intersection, complement and symmetric difference.
EndRem
Interface ISet<T> Extends ICollection<T>

	Rem
	bbdoc: Adds a value to the set.
	param: The value to add.
	returns: #True if the value was added; otherwise #False if it was already present.
	EndRem
	Method Add:Int(element:T)

	Rem
	bbdoc: Determines whether the set contains a value.
	param: The value to locate.
	returns: #True if the value is contained in the set; otherwise #False.
	EndRem
	Method Contains:Int(element:T)

	Rem
	bbdoc: Removes a value from the set.
	param: The value to remove.
	returns: #True if the value was removed; otherwise #False if it was not present.
	EndRem
	Method Remove:Int(element:T)

	Rem
	bbdoc: Removes all values that are also contained in another collection.
	param: The values to remove from this set.
	about: This operation modifies this set so that it contains only values that do
	not appear in #other.
	EndRem
	Method Complement(other:IIterable<T>)

	Rem
	bbdoc: Retains only values also contained in another collection.
	param: The values to intersect with this set.
	about: After this operation, this set contains only values that are present in
	both collections.
	EndRem
	Method Intersection(other:IIterable<T>)

	Rem
	bbdoc: Determines whether this set is a proper subset of another collection.
	param: The collection to compare against.
	returns: #True if every value in this set exists in #other and #other contains additional values; otherwise #False.
	EndRem
	Method IsProperSubsetOf:Int(other:IIterable<T>)

	Rem
	bbdoc: Determines whether this set is a proper superset of another collection.
	param: The collection to compare against.
	returns: #True if every value in #other exists in this set and this set contains additional values; otherwise #False.
	EndRem
	Method IsProperSupersetOf:Int(other:IIterable<T>)

	Rem
	bbdoc: Determines whether this set is a subset of another collection.
	param: The collection to compare against.
	returns: #True if every value in this set exists in #other; otherwise #False.
	EndRem
	Method IsSubsetOf:Int(other:IIterable<T>)

	Rem
	bbdoc: Determines whether this set is a superset of another collection.
	param: The collection to compare against.
	returns: #True if every value in #other exists in this set; otherwise #False.
	EndRem
	Method IsSupersetOf:Int(other:IIterable<T>)

	Rem
	bbdoc: Determines whether this set shares any values with another collection.
	param: The collection to compare against.
	returns: #True if the collections contain at least one value in common; otherwise #False.
	EndRem
	Method Overlaps:Int(other:IIterable<T>)

	Rem
	bbdoc: Replaces the set with its symmetric difference with another collection.
	param: The collection to compare against.
	about: After this operation, the set contains values that appear in either
	collection, but not in both.
	EndRem
	Method SymmetricDifference(other:IIterable<T>)

	Rem
	bbdoc: Adds all values from another collection.
	param: The collection whose values are added.
	about: After this operation, the set contains every distinct value that appears
	in either collection.
	EndRem
	Method UnionOf(other:IIterable<T>)

End Interface
