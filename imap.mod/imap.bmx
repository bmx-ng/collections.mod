SuperStrict

Module Collections.IMap

Import Collections.ICollection

Interface IMapNode<K, V>

	Method GetKey:K()
	Method GetValue:V()
	Method HasNext:Int()
	Method NextNode:IMapNode<K,V>()

End Interface

Interface IMap<K, V> Extends ICollection<IMapNode<K,V>>

	Method Keys:ICollection<K>()
	Method Values:ICollection<V>()
	Method Add(key:K, value:V)
	Method Put:V(key:K, value:V)
	Method ContainsKey:Int(key:K)
	Method Remove:Int(key:K)
	Method TryGetValue:Int(key:K, value:V Var)
	Method Operator [] :V(key:K) ' get
	Method Operator []= (key:K, value:V) ' put

End Interface
