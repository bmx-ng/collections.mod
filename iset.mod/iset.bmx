SuperStrict

Module Collections.ISet

Interface ISet<T> Extends ICollection<T>

	' Basic set operations
	Method Add:Int(element:T)
	Method Contains:Int(element:T)
	Method Remove:Int(element:T)

	' Set algebra (mutating this set)
	Method Complement(other:IIterable<T>)
	Method Intersection(other:IIterable<T>)
	Method IsProperSubsetOf:Int(other:IIterable<T>)
	Method IsProperSupersetOf:Int(other:IIterable<T>)
	Method IsSubsetOf:Int(other:IIterable<T>)
	Method IsSupersetOf:Int(other:IIterable<T>)
	Method Overlaps:Int(other:IIterable<T>)
	Method SymmetricDifference(other:IIterable<T>)
	Method UnionOf(other:IIterable<T>)

End Interface
