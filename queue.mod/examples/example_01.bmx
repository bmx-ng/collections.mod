SuperStrict

Framework brl.standardio
Import Collections.Queue


Local queue:TQueue<Int> = New TQueue<Int>

ShowContents(queue)

For Local i:Int = 0 Until 5
	queue.Enqueue(i)
Next

ShowContents(queue)

Print "Removed : " + queue.Dequeue()

ShowContents(queue)

Print "Removed : " + queue.Dequeue()

ShowContents(queue)

Print "Removed : " + queue.Dequeue()

ShowContents(queue)

Print "Removed : " + queue.Dequeue()

ShowContents(queue)

Print "Removed : " + queue.Dequeue()

ShowContents(queue)



Function ShowContents(queue:TQueue<Int>)
	Print "Queue contents :"
	If queue.IsEmpty() Then
		Print "    <empty>"
		Return
	End If
	For Local element:Int = EachIn queue
		Print "    " + element
	Next
End Function
