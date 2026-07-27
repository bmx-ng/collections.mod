SuperStrict

Module Collections.IMap

Import Collections.ICollection

Rem
bbdoc: Represents a key/value entry in a map.
about: A map node contains a key and its associated value.

Nodes may also form a linked sequence. Use #HasNext to determine whether
another node follows this one, and #NextNode to access it.
End Rem
Interface IMapNode<K, V>

	Rem
	bbdoc: Returns the key stored in this node.
	returns: The key associated with this map entry.
	End Rem
	Method GetKey:K()

	Rem
	bbdoc: Returns the value stored in this node.
	returns: The value associated with this map entry.
	End Rem
	Method GetValue:V()

	Rem
	bbdoc: Determines whether another node follows this node.
	returns: #True if a subsequent node is available; otherwise #False.
	End Rem
	Method HasNext:Int()

	Rem
	bbdoc: Returns the next node in the sequence.
	returns: The next map node, or #Null if no further nodes exist.
	about: When #HasNext returns #False, this method returns #Null.
	End Rem
	Method NextNode:IMapNode<K,V>()

End Interface


Rem
bbdoc: Represents a collection of key/value associations.
about: A map associates each distinct key with a single value. Each key may appear
at most once within the map, while multiple keys may be associated with
equal values.

Maps provide efficient lookup, insertion and removal of values by key. As
an #ICollection of #IMapNode entries, a map can also be iterated to access
every key/value association.

Unless an implementation documents otherwise, no particular iteration order
should be assumed.
End Rem
Interface IMap<K, V> Extends ICollection<IMapNode<K,V>>

	Rem
	bbdoc: Returns a collection containing the map's keys.
	returns: A collection containing each key in the map.
	End Rem
	Method Keys:ICollection<K>()

	Rem
	bbdoc: Returns a collection containing the map's values.
	returns: A collection containing the value from each map entry.
	about: Values are not required to be unique. Multiple keys may be associated
	with equal values.
	End Rem
	Method Values:ICollection<V>()

	Rem
	bbdoc: Adds a new key/value association.
	param: The key to add.
	param: The value to associate with the key.
	about: Throws #TArgumentException if the key already exists in the map.

	Use #Put or the indexed assignment operator when an existing value should
	be replaced.
	End Rem
	Method Add(key:K, value:V)

	Rem
	bbdoc: Adds or replaces a key/value association.
	param: The key to add or update.
	param: The value to associate with the key.
	returns: The value previously associated with the key, or the default value of type V if the key was not present.
	about: If the key does not exist, a new association is created. Otherwise, the
	existing value associated with the key is replaced.
	End Rem
	Method Put:V(key:K, value:V)

	Rem
	bbdoc: Determines whether the map contains a key.
	param: The key to locate.
	returns: #True if the key is present; otherwise #False.
	End Rem
	Method ContainsKey:Int(key:K)

	Rem
	bbdoc: Removes the association for a key.
	param: The key to remove.
	returns: #True if the key was removed; otherwise #False.
	End Rem
	Method Remove:Int(key:K)

	Rem
	bbdoc: Attempts to retrieve the value associated with a key.
	param: The key to locate.
	param: Receives the associated value if the key is found.
	returns: #True if the key exists; otherwise #False.
	about: Unlike the indexed access operator, this method distinguishes between a
	missing key and a key associated with the default value of type V.
	End Rem
	Method TryGetValue:Int(key:K, value:V Var)

	Rem
	bbdoc: Returns the value associated with a key.
	param: The key to locate.
	returns: The value associated with the specified key.
	about: Use #ContainsKey or #TryGetValue when the key may not exist.
	End Rem
	Method Operator [] :V(key:K)

	Rem
	bbdoc: Adds or replaces the value associated with a key.
	param: The key to add or update.
	param: The value to associate with the key.
	about: This operator behaves the same as #Put, except that the previous value is
	not returned.
	End Rem
	Method Operator []= (key:K, value:V)

End Interface
