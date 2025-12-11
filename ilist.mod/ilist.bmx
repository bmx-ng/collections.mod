SuperStrict

Module Collections.IList

Import Collections.ICollection

Interface IList<T> Extends ICollection<T>

	Method Add(element:T)
	Method Contains:Int(element:T)
	Method Get:T(index:Int)
	Method IndexOf:Int(element:T)
	Method Insert(index:Int, element:T)
	Method LastIndexOf:Int(element:T)
	Method Remove:Int(element:T)
	Method RemoveAt:T(index:Int)
	Method Set(index:Int, value:T)
	Method Operator [] :T(index:Int)
	Method Operator []= (index:Int, value:T)

End Interface
