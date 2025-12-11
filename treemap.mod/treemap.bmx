SuperStrict

Module Collections.TreeMap

Import Collections.IMap
Import Collections.Errors
Import Collections.ImmutableList

Rem
bbdoc: Represents a collection of keys and values.
End Rem
Type TTreeMap<K, V> Implements IMap<K,V>

	Private
	Field root:TTreeMapNode<K,V>
	Field size:Int
	
	Field comparator:IComparator<K>
	Public

	Rem
	bbdoc: Creates a new #TTreeMap instance using the default comparator.
	End Rem
	Method New()
	End Method
	
	Rem
	bbdoc: Creates a new #TTreeMap instance using the specified comparator.
	End Rem
	Method New(comparator:IComparator<K>)
		Assert comparator
		Self.comparator = comparator
	End Method

	Rem
	bbdoc: Returns an iterator that iterates through the #TTreeMap.
	End Rem
	Method GetIterator:IIterator<IMapNode<K,V>>()
		Return New TMapIterator<K,V>(FirstNode())
	End Method
	
	Rem
	bbdoc: Removes all elements from the #TTreeMap.
	End Rem
	Method Clear() Override
		root = Null
		size = 0
	End Method

	Rem
	bbdoc: Gets the number of key/value pairs contained in the #TTreeMap.
	End Rem
	Method Count:Int() Override
		Return size
	End Method

	Rem
	bbdoc: Returns #True if the #TTreeMap is empty, otherwise #False.
	End Rem
	Method IsEmpty:Int() Override
		Return size = 0
	End Method

	Method CopyTo(array:IMapNode<K,V>[], index:Int = 0)
	End Method
	
	Rem
	bbdoc: Returns the #TTreeMap keys as a collection.
	End Rem
	Method Keys:ICollection<K>() Override
		If size = 0 Then
			Return New TEmptyImmutableList<K>
		End If

		Local _keys:K[] = New K[size]
		Local i:Int = 0
		For Local node:IMapNode<K,V> = EachIn Self
			_keys[i] = node.GetKey()
			i :+ 1
		Next
		Return New TImmutableList<K>(_keys, True)
	End Method

	Rem
	bbdoc: Returns the #TTreeMap values as a collection.
	End Rem
	Method Values:ICollection<V>() Override
		If size = 0 Then
			Return New TEmptyImmutableList<V>
		End If

		Local _values:V[] = New V[size]
		Local i:Int = 0
		For Local node:IMapNode<K,V> = EachIn Self
			_values[i] = node.GetValue()
			i :+ 1
		Next
		Return New TImmutableList<V>(_values, True)
	End Method

	Rem
	bbdoc: Adds the specified key and value to the #TTreeMap.
	about: Throws an exception if an element with the specified key already exists.
	End Rem
	Method Add(key:K, value:V) Override
		If FindNode(key) Then
			Throw New TArgumentException("An element with the same key already exists in the map")
		End If
		_AddNew(key, value)
	End Method
	
	Private
	' Internal method to add a new node knowing that the key does not already exist
	Method _AddNew(key:K, value:V)
		Local node:TTreeMapNode<K,V>=root
		Local parent:TTreeMapNode<K,V>
		Local cmp:Int
		
		While node<>Null
			parent=node
			
			If comparator Then
				cmp = comparator.Compare(key, node.key)
			Else
				cmp = DefaultComparator_Compare(key, node.key)
			End If
			
			If cmp < 0 Then
				node=node.leftNode
			Else If cmp > 0 Then
				node=node.rightNode
			Else
				node.value = value
				Return
			End If
		Wend
		
		node=New TTreeMapNode<K,V>
		node.key=key
		node.value=value
		node.colour=0
		node.parent=parent

		size :+ 1

		If parent=Null
			root=node
			Return
		EndIf
		If cmp > 0 Then
			parent.rightNode=node
		Else
			parent.leftNode=node
		EndIf
		
		RepairAdd node		
	End Method
	Public

	Rem
	bbdoc: Adds a key/value pair to the #TTreeMap. If the key already exists, updates the value.
	returns: The old value if @key already existed; otherwise returns the default/#Null value for the value type.
	End Rem
	Method Put:V(key:K, value:V) Override
		Local node:TTreeMapNode<K,V> = FindNode(key)
		If node Then
			Local oldValue:V = node.value
			node.value = value
			Return oldValue
		Else
			_AddNew(key, value)
		End If
	End Method

	Rem
	bbdoc: Determines whether the #TTreeMap contains the specified key.
	returns: #True if the #TTreeMap contains an element with the specified key; otherwise, #False.
	End Rem
	Method ContainsKey:Int(key:K) Override
		Return FindNode( key )<>Null
	End Method
	
	Rem
	bbdoc: Determines whether the #TTreeMap contains a specific value.
	returns: #True if the #TTreeMap contains an element with the specified value; otherwise, #False.
	End Rem
	Method ContainsValue:Int(value:V)
		For Local node:IMapNode<K,V> = EachIn Self
			If value = node.GetValue() Then
				Return True
			End If
		Next
		Return False
	End Method

	Rem
	bbdoc: Removes the value with the specified key from the #TTreeMap.
	returns: #True if the element is successfully found and removed; otherwise, #False. This method returns #False if key is not found in the #TTreeMap.
	End Rem
	Method Remove:Int(key:K) Override
		Local node:TTreeMapNode<K,V> = FindNode(key)
		If node=Null Then
			Return False
		End If
		RemoveNode node
		size :- 1
		Return True
	End Method

	Rem
	bbdoc: Gets the value associated with the specified key.
	returns: #True if the #TTreeMap contains an element with the specified key; otherwise, #False.
	about: When this method returns, @value contains the value associated with the specified key, if the key is found;
	otherwise, @value will remain unchanged.
	End Rem
	Method TryGetValue:Int(key:K, value:V Var)
		Local node:TTreeMapNode<K,V> = FindNode(key)
		If node <> Null Then
			value = node.GetValue()
			Return True
		End If
		Return False
	End Method

	Rem
	bbdoc: Gets the element with the specified key.
	returns: The value if @key exists in the #TTreeMap; otherwise returns the default/#Null value for the value type.
	End Rem
	Method Operator [] :V(key:K)
		Local node:TTreeMapNode<K,V> = FindNode(key)

		If node Then
			Return node.value
		Else
			Local value:V
			Return value
		End If
	End Method

	Rem
	bbdoc: Sets the element with the specified key.
	about: Unlike with #Add, if @key already exists, the current value is replaced with @value.
	End Rem
	Method Operator []= (key:K, value:V)
		Local node:TTreeMapNode<K,V> = FindNode(key)

		If node Then
			node.value = value
		Else
			_AddNew(key, value)
		End If
	End Method

Private
	Method RotateLeft( node:TTreeMapNode<K,V> )
		Local child:TTreeMapNode<K,V>=node.rightNode
		node.rightNode=child.leftNode
		If child.leftNode<>Null
			child.leftNode.parent=node
		EndIf
		child.parent=node.parent
		If node.parent<>Null
			If node=node.parent.leftNode
				node.parent.leftNode=child
			Else
				node.parent.rightNode=child
			EndIf
		Else
			root=child
		EndIf
		child.leftNode=node
		node.parent=child
	End Method
	
	Method RotateRight( node:TTreeMapNode<K,V> )
		Local child:TTreeMapNode<K,V>=node.leftNode
		node.leftNode=child.rightNode
		If child.rightNode<>Null
			child.rightNode.parent=node
		EndIf
		child.parent=node.parent
		If node.parent<>Null
			If node=node.parent.rightNode
				node.parent.rightNode=child
			Else
				node.parent.leftNode=child
			EndIf
		Else
			root=child
		EndIf
		child.rightNode=node
		node.parent=child
	End Method
	
	Method RepairAdd( node:TTreeMapNode<K,V> )
		While node.parent And node.parent.colour=0 And node.parent.parent<>Null
			If node.parent = node.parent.parent.leftNode Then
				Local uncle:TTreeMapNode<K,V>=node.parent.parent.rightNode
				If uncle And uncle.colour = 0 Then
					node.parent.colour = 1
					uncle.colour = 1
					uncle.parent.colour = 0
					node = uncle.parent
				Else
					If node = node.parent.rightNode Then
						node = node.parent
						RotateLeft node
					EndIf
					node.parent.colour=1
					node.parent.parent.colour=0
					RotateRight node.parent.parent
				EndIf
			Else
				Local uncle:TTreeMapNode<K,V>=node.parent.parent.leftNode
				If uncle And uncle.colour=0
					node.parent.colour=1
					uncle.colour=1
					uncle.parent.colour=0
					node=uncle.parent
				Else
					If node = node.parent.leftNode Then
						node=node.parent
						RotateRight node
					EndIf
					node.parent.colour=1
					node.parent.parent.colour=0
					RotateLeft node.parent.parent
				EndIf
			EndIf
		Wend
		root.colour=1
	End Method

	Method FindNode:TTreeMapNode<K,V>( key:K )
		Local node:TTreeMapNode<K,V>=root
		While node<>Null
			Local cmp:Int
			If comparator Then
				cmp = comparator.Compare(key, node.key)
			Else
				cmp = DefaultComparator_Compare(key, node.key)
			End If

			If cmp > 0 Then
				node=node.rightNode
			Else If cmp < 0 Then
				node=node.leftNode
			Else
				Return node
			EndIf
		Wend
		Return node
	End Method

	Method FirstNode:TTreeMapNode<K,V>()
		Local node:TTreeMapNode<K,V> = root
		While node <> Null And node.leftNode <> Null
			node = node.leftNode
		Wend
		Return node
	End Method

	Method RemoveNode( node:TTreeMapNode<K,V> )
		Local splice:TTreeMapNode<K,V>
		Local child:TTreeMapNode<K,V>
		
		If node.leftNode = Null Then
			splice = node
			child = node.rightNode
		Else If node.rightNode = Null Then
			splice = node
			child = node.leftNode
		Else
			splice = node.leftNode
			While splice.rightNode <> Null
				splice = splice.rightNode
			Wend
			child = splice.leftNode
			node.key = splice.key
			node.value = splice.value
		EndIf
		
		Local parent:TTreeMapNode<K,V> = splice.parent
		If child <> Null Then
			child.parent = parent
		EndIf
		If parent = Null Then
			root = child
			Return
		EndIf
		If splice = parent.leftNode Then
			parent.leftNode = child
		Else
			parent.rightNode = child
		EndIf
		
		If splice.colour=1 Then
			RepairRemove child, parent
		End If
	End Method

	Method RepairRemove(node:TTreeMapNode<K,V>, parent:TTreeMapNode<K,V>)

		Function IsBlack:Int(n:TTreeMapNode<K,V>) Inline
			' Null is black in RB-trees
			Return n = Null Or n.colour = 1
		End Function

		Function IsRed:Int(n:TTreeMapNode<K,V>) Inline
			Return n <> Null And n.colour = 0
		End Function

		While node <> root And (node = Null Or node.colour = 1)
			Local leftBranch:Int = (parent <> Null And node = parent.leftNode)
			Local sib:TTreeMapNode<K,V> = Null
			If leftBranch Then
				If parent <> Null Then
					sib = parent.rightNode
				End If
			Else
				If parent <> Null Then
					sib = parent.leftNode
				End If
			End If

			' red sibling
			If IsRed(sib) Then
				sib.colour = 1
				parent.colour = 0
				If leftBranch Then
					RotateLeft parent
					If parent <> Null Then
						sib = parent.rightNode
					End If
				Else
					RotateRight parent
					If parent <> Null Then
						sib = parent.leftNode
					End If
				End If
			End If

			' Now sibling is black
			Local sibLeft:TTreeMapNode<K,V> = Null
			Local sibRight:TTreeMapNode<K,V> = Null
			If sib <> Null Then
				sibLeft = sib.leftNode
				sibRight = sib.rightNode
			End If

			If (leftBranch And IsBlack(sibLeft) And IsBlack(sibRight)) Or (Not leftBranch And IsBlack(sibRight) And IsBlack(sibLeft)) Then
				If sib <> Null Then
					sib.colour = 0
				End If
				node = parent
				If parent <> Null Then
					parent = parent.parent
				End If
			Else
				If leftBranch Then
					If IsBlack(sibRight) Then
						If sibLeft <> Null Then
							sibLeft.colour = 1
						End If
						If sib <> Null Then
							sib.colour = 0
						End If
						If sib <> Null Then
							RotateRight sib
						End If
						If parent <> Null Then
							sib = parent.rightNode
						End If
					End If
					If sib <> Null Then
						sib.colour = parent.colour
					End If
					parent.colour = 1
					If sib <> Null And sib.rightNode <> Null Then
						sib.rightNode.colour = 1
					End If
					RotateLeft parent
				Else
					If IsBlack(sibLeft) Then
						If sibRight <> Null Then
							sibRight.colour = 1
						End If
						If sib <> Null Then
							sib.colour = 0
						End If
						If sib <> Null Then
							RotateLeft sib
						End If
						If parent <> Null Then
							sib = parent.leftNode
						End If
					End If
					If sib <> Null Then
						sib.colour = parent.colour
					End If
					parent.colour = 1
					If sib <> Null And sib.leftNode <> Null Then
						sib.leftNode.colour = 1
					End If
					RotateRight parent
				End If
				node = root
			End If
		Wend

		If node <> Null Then
			node.colour = 1
		End If
	End Method

Public

	Method ToString:String()
	End Method
End Type

Rem
bbdoc: A #TTreeMap node representing a key/value pair.
End Rem
Type TTreeMapNode<K, V> Implements IMapNode<K,V>

	Field parent:TTreeMapNode<K,V>
	Field leftNode:TTreeMapNode<K,V>
	Field rightNode:TTreeMapNode<K,V>
	Field colour:Int

	Field key:K
	Field value:V

Public	
	Rem
	bbdoc: Returns the next node in the sequence.
	End Rem
	Method NextNode:TTreeMapNode<K,V>() Override
		Local node:TTreeMapNode<K,V> = Self
		If node.rightNode<>Null
			node=rightNode
			While node.leftNode <> Null
				node=node.leftNode
			Wend
			Return node
		EndIf
		Local parent:TTreeMapNode<K,V>=parent
		While parent And node=parent.rightNode
			node=parent
			parent=parent.parent
		Wend
		Return parent
	End Method

	Method HasNext:Int() Override
		Return NextNode() <> Null
	End Method

	Rem
	bbdoc: Returns the key for this node.
	End Rem
	Method GetKey:K() Override
		Return key
	End Method

	Rem
	bbdoc: Returns the value for this node.
	End Rem
	Method GetValue:V() Override
		Return value
	End Method
		
End Type

Type TMapIterator<K,V> Implements IIterator<IMapNode<K,V>> 
	Private
	Field initial:IMapNode<K,V>
	Field node:IMapNode<K,V>

	Public
	Method New(initial:IMapNode<K,V>)
		Self.initial = initial
	End Method

	Method Current:IMapNode<K,V>()
		Return node
	End Method

	Method HasNext:Int()
		If initial Then
			Return True
		End If

		If node Then
			Return node.HasNext()
		End If

		Return False
	End Method
	
	Method MoveNext:Int()
		If initial Then
			node = initial
			initial = Null
			Return True
		End If
		
		If node Then
			node = node.NextNode()
			Return node <> Null
		End If
		
		Return False
	End Method

End Type
