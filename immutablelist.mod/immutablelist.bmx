SuperStrict

Module Collections.ImmutableList

Import Collections.IList

Type TImmutableList<T> Implements IList<T>

	Private
	Field _items:T[]

	Public

	' --- Constructors ---

	Rem
	bbdoc: Creates a new #TImmutableList initialised by @items.
	about: If @safe is true, the provided array is used directly without making a copy.
	This assumes that the caller will not modify the array after passing it to this constructor.
	End Rem
	Method New(items:T[], safe:Int = False)
		If safe Then
			_items = items
			Return
		End If
		_items = items[..]
	End Method

	Method New(item:T)
		_items = New T[1]
		_items[0] = item
	End Method

	Method New(item0:T, item1:T)
		_items = New T[2]
		_items[0] = item0
		_items[1] = item1
	End Method

	Rem
	bbdoc: Creates a new #TImmutableList initialised by @iterable.
	about: The optional @size parameter can be used as a hint for the initial capacity of the internal storage.
	If @size is not provided or is -1, a default initial capacity is used.
	End Rem
	Method New(iterable:IIterable<T>, size:Int = -1)
		If size < 0 Then
			size = 16
		End If
		Local tempItems:T[] = New T[size]
		Local count:Int = 0
		
		If iterable Then
			For Local value:T = EachIn iterable
				If count >= tempItems.Length Then
					' Increase capacity
					tempItems = tempItems[..(tempItems.Length * 3) / 2 + 1]
				End If
				tempItems[count] = value
				count :+ 1
			Next
		End If
		
		' Trim array to actual size
		' If size matches, just use it directly
		If tempItems.Length = count Then
			_items = tempItems
			Return
		End If

		_items = tempItems[..count]
	End Method

	' --- IIterable<T> ---

	Method GetIterator:IIterator<T>() Override
		Return New TImmutableListIterator<T>(Self)
	End Method

	' --- ICollection<T> ---

	Method Count:Int() Override
		Return _items.Length
	End Method

	Method CopyTo(array:T[], index:Int = 0) Override
		For Local i:Int = 0 Until _items.Length
			If index + i >= array.Length Then
				Exit
			End If
			array[index + i] = _items[i]
		Next
	End Method

	Method IsEmpty:Int() Override
		Return _items.Length = 0
	End Method

	Method Clear() Override
		UnsupportedOperationError()
	End Method

	' --- IList<T> ---

	Method Add(element:T) Override
		UnsupportedOperationError()
	End Method

	Method Contains:Int(element:T) Override
		For Local i:Int = 0 Until _items.Length
			If _items[i] = element Then
				Return 1
			End If
		Next
		Return 0
	End Method

	Method Get:T(index:Int) Override
		If index < 0 Or index >= _items.Length Then
			Throw New TIndexOutOfBoundsException
		End If
		Return _items[index]
	End Method

	Method IndexOf:Int(element:T) Override
		For Local i:Int = 0 Until _items.Length
			If _items[i] = element Then
				Return i
			End If
		Next
		Return -1
	End Method

	Method Insert(index:Int, element:T) Override
		UnsupportedOperationError()
	End Method

	Method LastIndexOf:Int(element:T) Override
		For Local i:Int = _items.Length - 1 To 0 Step -1
			If _items[i] = element Then
				Return i
			End If
		Next
		Return -1
	End Method

	Method Remove:Int(element:T) Override
		UnsupportedOperationError()
	End Method

	Method RemoveAt:T(index:Int) Override
		UnsupportedOperationError()
	End Method

	Method Set(index:Int, value:T) Override
		UnsupportedOperationError()
	End Method

	Method Operator [] :T(index:Int)
		If index < 0 Or index >= _items.Length Then
			Throw New TIndexOutOfBoundsException
		End If
		Return _items[index]
	End Method

	Method Operator []= (index:Int, value:T)
		UnsupportedOperationError()
	End Method

End Type

Type TImmutableListIterator<T> Implements IIterator<T>

	Private

	Field _list:TImmutableList<T>
	Field _index:Int

	Public

	' --- Constructor ---

	Method New(list:TImmutableList<T>)
		_list = list
		_index = -1
	End Method

	' --- IIterator<T> ---

	Method Current:T() Override
		If _index < 0 Or _index >= _list.Count() Then
			Throw New TIndexOutOfBoundsException
		End If
		Return _list[_index]
	End Method
	
	Method MoveNext:Int() Override
		_index :+ 1
		Return _index < _list.Count()
	End Method

End Type

Type TEmptyImmutableList<T> Implements IList<T>

	Public

	' --- IIterable<T> ---

	Method GetIterator:IIterator<T>() Override
		Return New TEmptyImmutableListIterator<T>()
	End Method

	' --- ICollection<T> ---

	Method Count:Int() Override
		Return 0
	End Method

	Method CopyTo(array:T[], index:Int = 0) Override
		' No items to copy
	End Method

	Method IsEmpty:Int() Override
		Return True
	End Method

	Method Clear() Override
		UnsupportedOperationError()
	End Method

	' --- IList<T> ---

	Method Add(element:T) Override
		UnsupportedOperationError()
	End Method

	Method Contains:Int(element:T) Override
		Return False
	End Method

	Method Get:T(index:Int) Override
		Throw New TIndexOutOfBoundsException
	End Method

	Method IndexOf:Int(element:T) Override
		Return -1
	End Method

	Method Insert(index:Int, element:T) Override
		UnsupportedOperationError()
	End Method

	Method LastIndexOf:Int(element:T) Override
		Return -1
	End Method

	Method Remove:Int(element:T) Override
		UnsupportedOperationError()
	End Method

	Method RemoveAt:T(index:Int) Override
		UnsupportedOperationError()
	End Method

	Method Set(index:Int, value:T) Override
		UnsupportedOperationError()
	End Method

	Method Operator [] :T(index:Int)
		Throw New TIndexOutOfBoundsException
	End Method

	Method Operator []= (index:Int, value:T)
		UnsupportedOperationError()
	End Method

End Type

Type TEmptyImmutableListIterator<T> Implements IIterator<T>

	Public

	' --- Constructor ---

	Method New()
	End Method

	' --- IIterator<T> ---

	Method Current:T() Override
		Throw New TIndexOutOfBoundsException
	End Method
	
	Method MoveNext:Int() Override
		Return False
	End Method

End Type
