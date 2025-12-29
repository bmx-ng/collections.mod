SuperStrict

Rem
bbdoc: Data structures/PtrMap
about: A maps data structure with Byte Ptr keys.
End Rem
Module Collections.PtrMap

ModuleInfo "Version: 1.13"
ModuleInfo "License: zlib/libpng"
ModuleInfo "Copyright: 2019-2025 Bruce A Henderson"

ModuleInfo "History: 1.13"
ModuleInfo "History: Moved generic-based maps to their own modules."
ModuleInfo "History: 1.12"
ModuleInfo "History: Refactored tree based maps to use brl.collections."

Import Collections.HashMap

Rem
bbdoc: A Tree map backed map with Byte Ptr keys and Object values.
End Rem
Type TPtrMap

	Field _map:THashMap<Byte Ptr, Object> = New THashMap<Byte Ptr, Object>()

	Method Clear()
		_map.Clear()
	End Method

	Method IsEmpty:Int()
		Return _map.IsEmpty()
	End Method

	Method Insert( key:Byte Ptr,value:Object )
		_map.Put(key, value)
	End Method

	Method Contains:Int( key:Byte Ptr )
		Return _map.ContainsKey(key)
	End Method

	Method ValueForKey:Object( key:Byte Ptr )
		Local v:Object
		If _map.TryGetValue( key, v ) Then
			Return v
		End If
		Return Null
	End Method

	Method ValueForKey:Int( key:Byte Ptr, value:Object Var )
		Return _map.TryGetValue( key, value )
	End Method

	Method Remove:Int( key:Byte Ptr )
		Return _map.Remove(key)
	End Method

	Method Keys:TPtrMapEnumerator()
		Local nodeEnumerator:TPtrKeyEnumerator = New TPtrKeyEnumerator
		nodeEnumerator._mapIterator = IIterator<IMapNode<Byte Ptr,Object>>(_map.GetIterator())
		Local mapEnumerator:TPtrMapEnumerator = New TPtrMapEnumerator
		mapEnumerator._enumerator = nodeEnumerator
		Return mapEnumerator
	End Method

	Method Values:TPtrMapEnumerator()
		Local nodeEnumerator:TPtrValueEnumerator = New TPtrValueEnumerator
		nodeEnumerator._mapIterator = IIterator<IMapNode<Byte Ptr,Object>>(_map.GetIterator())
		Local mapEnumerator:TPtrMapEnumerator = New TPtrMapEnumerator
		mapEnumerator._enumerator = nodeEnumerator
		Return mapEnumerator
	End Method

	Method Copy:TPtrMap()
		Local newMap:TPtrMap = New TPtrMap
		Local iter:IIterator<IMapNode<Byte Ptr,Object>> = IIterator<IMapNode<Byte Ptr,Object>>(_map.GetIterator())
		While iter.MoveNext()
			Local n:IMapNode<Byte Ptr,Object> = IMapNode<Byte Ptr,Object>(iter.Current())
			If n Then
				newMap._map.Add( n.GetKey(), n.GetValue() )
			End If
		Wend
		Return newMap
	End Method

	Method ObjectEnumerator:TPtrNodeEnumerator()
		Local nodeEnumerator:TPtrNodeEnumerator = New TPtrNodeEnumerator
		nodeEnumerator._mapIterator = IIterator<IMapNode<Byte Ptr,Object>>(_map.GetIterator())
		Return nodeEnumerator
	End Method

	Method Operator[]:Object(key:Byte Ptr)
		Return _map[key]
	End Method

	Method Operator[]=(key:Byte Ptr, value:Object)
		_map[key] = value
	End Method

End Type

Rem
bbdoc: Int holder for key returned by TPtrMap.Keys() enumerator.
about: Because a single instance of #TPtrKey is used during enumeration, #value changes on each iteration.
End Rem
Type TPtrKey
	Rem
	bbdoc: Byte Ptr key value.
	End Rem
	Field value:Byte Ptr
End Type

Type TPtrKeyValue

	Field _key:Byte Ptr
	Field _value:Object

	Method Key:Byte Ptr()
		Return _key
	End Method

	Method Value:Object()
		Return _value
	End Method
End Type

Type TPtrNodeEnumerator

	Method HasNext:Int()
		' If we’ve already advanced and not consumed, we know there is a next.
		If _ready Then
			Return True
		End If

		' Otherwise, try to move forward once.
		If _mapIterator.MoveNext() Then
			_ready = True
			Return True
		End If

		' No more elements.
		Return False
	End Method

	Method NextObject:Object()
		' Normal usage: HasNext was just called and set ready = True.
		If Not _ready Then
			' Be defensive: allow NextObject without HasNext.
			If Not _mapIterator.MoveNext() Then
				Return Null ' no more elements
			End If
		End If

		_ready = False
		Local n:IMapNode<Byte Ptr,Object> = IMapNode<Byte Ptr,Object>(_mapIterator.Current())
		If n Then
			_keyValue._key = n.GetKey()
			_keyValue._value = n.GetValue()
			Return _keyValue
		End If	
	End Method

	'***** PRIVATE *****
		
	Field _mapIterator:IIterator<IMapNode<Byte Ptr,Object>>
	Field _keyValue:TPtrKeyValue = New TPtrKeyValue
	Field _ready:Int

End Type

Type TPtrKeyEnumerator Extends TPtrNodeEnumerator
	Field _key:TPtrKey = New TPtrKey
	Method NextObject:Object() Override
		Local kv:TPtrKeyValue = TPtrKeyValue(Super.NextObject())
		If kv Then
			_key.value = kv._key
			Return _key
		End If
		Return Null
	End Method
End Type

Type TPtrValueEnumerator Extends TPtrNodeEnumerator
	Method NextObject:Object() Override
		Local kv:TPtrKeyValue = TPtrKeyValue(Super.NextObject())
		If kv Then
			Return kv._value
		End If
		Return Null
	End Method
End Type

Type TPtrMapEnumerator
	Method ObjectEnumerator:TPtrNodeEnumerator()
		Return _enumerator
	End Method
	Field _enumerator:TPtrNodeEnumerator
End Type
