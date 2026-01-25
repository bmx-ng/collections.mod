SuperStrict

Rem
bbdoc: Collections/Errors
about: Defines exception types used by the collections module.
End Rem
Module Collections.Errors

Rem
bbdoc: Exception thrown when an attempt is made to access an element outside the valid range of indices.
End Rem
Type TIndexOutOfBoundsException Extends TBlitzException

	Method ToString:String() Override
		Return "Attempt to index element out of bounds."
	End Method

End Type

Rem
bbdoc: Exception thrown when attempting to access an element that does not exist.
End Rem
Type TNoSuchElementException Extends TBlitzException

	Method ToString:String() Override
		Return "No such Element."
	End Method

End Type

Rem
bbdoc: Exception thrown when an argument provided to a method is outside the allowable range of values.
End Rem
Type TArgumentOutOfRangeException Extends TBlitzException

	Method ToString:String() Override
		Return "Argument out of range."
	End Method

End Type

Rem
bbdoc: Exception thrown when an argument provided to a method is invalid.
End Rem
Type TArgumentException Extends TBlitzException

	Field message:String
	
	Method New(message:String)
		Self.message = message
	End Method

	Method ToString:String() Override
		Return message
	End Method

End Type

Rem
bbdoc: Exception thrown when a null argument is provided to a method that does not accept it.
End Rem
Type TArgumentNullException Extends TArgumentException

	Method New(arg:String)
		Self.message = arg + " cannot be null"
	End Method

End Type
