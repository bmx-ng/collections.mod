SuperStrict

Module Collections.BlockingQueue

Import Collections.Queue

?threaded
Import BRL.threads
Import BRL.Time


Rem
bbdoc: A thread-safe first-in, first-out (FIFO) collection of elements.
about: Implements a queue as a circular array. Elements stored in a #TBlockingQueue are inserted at one end and removed from the other.
Use a #TBlockingQueue if you need to access the information in the same order that it is stored in the collection and you need to ensure that the collection is thread-safe.
A call to #Dequeue will block if the queue is empty. A call to #Enqueue will block if the queue is full.
The capacity of a #TBlockingQueue is the number of elements the #TBlockingQueue can hold. Once the queue is full, any attempt to add an element will block until space is available.
End Rem
Type TBlockingQueue<T> Extends TQueue<T>

	Private
		Field lock:TMutex
		Field notEmpty:TCondVar
		Field notFull:TCondVar
	Public

	Method New(capacity:Int = 16)
		Super.New(capacity)
		lock = TMutex.Create()
		notEmpty = TCondVar.Create()
		notFull = TCondVar.Create()
	End Method
	
	Method Enqueue(element:T)
		lock.Lock()
		While full
			notFull.Wait(lock)
		Wend
		Super.Enqueue(element)
		notEmpty.Signal()
		lock.Unlock()
	End Method
	
	Rem
	bbdoc: Adds an element to the end of the #TBlockingQueue, waiting up to the specified wait time if necessary for space to become available
	about: If the queue is full, the operation will block until space becomes available or the specified timeout elapses.
	Throws a #TTimeoutException if the operation times out.
	End Rem
	Method Enqueue(element:T, timeout:ULong, unit:ETimeUnit = ETimeUnit.Milliseconds)
		Local timeoutMs:ULong = TimeUnitToMillis(timeout, unit)
	
		Local startTime:ULong = CurrentUnixTime()
		lock.Lock()
		While full
			Local now:ULong = CurrentUnixTime()
			If timeout > 0 And now - startTime >= timeoutMs
				lock.Unlock()
				Throw New TTimeoutException("The operation timed out after " + timeoutMs + "ms")
			End If
			notFull.TimedWait(lock, Int(timeoutMs - (now - startTime)))
		Wend
		Super.Enqueue(element)
		notEmpty.Signal()
		lock.Unlock()
	End Method
	
	Rem
	bbdoc: Removes and returns the element at the beginning of the #TBlockingQueue, waiting up to the specified wait time if necessary for an element to become available.
	about: If the queue is empty, the operation will block until an element becomes available or the specified timeout elapses.
	Throws a #TTimeoutException if the operation times out.
	End Rem
	Method Dequeue:T(timeout:ULong, unit:ETimeUnit = ETimeUnit.Milliseconds)
		Local timeoutMs:ULong = TimeUnitToMillis(timeout, unit)
	
		Local startTime:Long = CurrentUnixTime()
		lock.Lock()
		While IsEmpty()
			Local now:ULong = CurrentUnixTime()
			If timeout > 0 And now - startTime >= timeoutMs
				lock.Unlock()
				Throw New TTimeoutException("The operation timed out after " + timeoutMs + "ms")
			End If
			notEmpty.TimedWait(lock, Int(timeoutMs - (now - startTime)))
		Wend
		Local element:T = Super.Dequeue()
		notFull.Signal()
		lock.Unlock()
		Return element
	End Method

	Method Dequeue:T()
		lock.Lock()
		While IsEmpty()
			notEmpty.Wait(lock)
		Wend
		Local element:T = Super.Dequeue()
		notFull.Signal()
		lock.Unlock()
		Return element
	End Method
	
	Method TryDequeue:Int(value:T Var)
		lock.Lock()
		If IsEmpty()
			lock.Unlock()
			Return False
		End If
		value = Super.Dequeue()
		notFull.Signal()
		lock.Unlock()
		Return True
	End Method
	
	Method TryPeek:Int(value:T Var)
		lock.Lock()
		If IsEmpty()
			lock.Unlock()
			Return False
		End If
		value = data[head]
		lock.Unlock()
		Return True
	End Method
	
	Method Clear()
		lock.Lock()
		Super.Clear()
		notFull.Signal()
		lock.Unlock()
	End Method
	
	Method TrimExcess()
		' noop since a blocking queue does not grow beyond its initial capacity
	End Method
	
	Method Resize()
		lock.Lock()
		Super.Resize()
		notFull.Signal()
		lock.Unlock()
	End Method
	
End Type

Rem
bbdoc: A thread-safe first-in, first-out (FIFO) collection of elements that supports the concept of tasks.
about: When a task is complete, the task should call the #TaskDone method to signal that the task is done.
End Rem
Type TBlockingTaskQueue<T> Extends TQueue<T>

	Private
		Field lock:TMutex
		Field notEmpty:TCondVar
		Field notFull:TCondVar
		Field allTasksDone:TCondVar
		Field taskLock:TMutex
		Field unfinishedTasks:Int
	Public

	Method New(capacity:Int = 16)
		Super.New(capacity)
		lock = TMutex.Create()
		notEmpty = TCondVar.Create()
		notFull = TCondVar.Create()
		allTasksDone = TCondVar.Create()
		taskLock = TMutex.Create()
		unfinishedTasks = 0
	End Method
	
	Method Enqueue(element:T)
		lock.Lock()
		While full
			notFull.Wait(lock)
		Wend
		Super.Enqueue(element)
		taskLock.Lock()
		unfinishedTasks :+ 1
		taskLock.Unlock()
		notEmpty.Signal()
		lock.Unlock()
	End Method
	
	Rem
	bbdoc: Adds an element to the end of the #TBlockingTaskQueue, waiting up to the specified wait time if necessary for space to become available
	about: If the queue is full, the operation will block until space becomes available or the specified timeout elapses.
	Throws a #TTimeoutException if the operation times out.
	End Rem
	Method Enqueue(element:T, timeout:ULong, unit:ETimeUnit = ETimeUnit.Milliseconds)
		Local timeoutMs:ULong = TimeUnitToMillis(timeout, unit)
	
		Local startTime:ULong = CurrentUnixTime()
		lock.Lock()
		While full
			Local now:ULong = CurrentUnixTime()
			If timeout > 0 And now - startTime >= timeoutMs
				lock.Unlock()
				Throw New TTimeoutException("The operation timed out after " + timeoutMs + "ms")
			End If
			notFull.TimedWait(lock, Int(timeoutMs - (now - startTime)))
		Wend
		Super.Enqueue(element)
		taskLock.Lock()
		unfinishedTasks :+ 1
		taskLock.Unlock()
		notEmpty.Signal()
		lock.Unlock()
	End Method
	
	Rem
	bbdoc: Removes and returns the element at the beginning of the #TBlockingTaskQueue, waiting up to the specified wait time if necessary for an element to become available.
	about: If the queue is empty, the operation will block until an element becomes available or the specified timeout elapses.
	Throws a #TTimeoutException if the operation times out.
	End Rem
	Method Dequeue:T(timeout:ULong, unit:ETimeUnit = ETimeUnit.Milliseconds)
		Local timeoutMs:ULong = TimeUnitToMillis(timeout, unit)
	
		Local startTime:Long = CurrentUnixTime()
		lock.Lock()
		While IsEmpty()
			Local now:ULong = CurrentUnixTime()
			If timeout > 0 And now - startTime >= timeoutMs
				lock.Unlock()
				Throw New TTimeoutException("The operation timed out after " + timeoutMs + "ms")
			End If
			notEmpty.TimedWait(lock, Int(timeoutMs - (now - startTime)))
		Wend
		Local element:T = Super.Dequeue()
		notFull.Signal()
		lock.Unlock()
		Return element
	End Method

	Method Dequeue:T()
		lock.Lock()
		While IsEmpty()
			notEmpty.Wait(lock)
		Wend
		Local element:T = Super.Dequeue()
		notFull.Signal()
		lock.Unlock()
		Return element
	End Method
	
	Method TryDequeue:Int(value:T Var)
		lock.Lock()
		If IsEmpty()
			lock.Unlock()
			Return False
		End If
		value = Super.Dequeue()
		notFull.Signal()
		lock.Unlock()
		Return True
	End Method
	
	Method TryPeek:Int(value:T Var)
		lock.Lock()
		If IsEmpty()
			lock.Unlock()
			Return False
		End If
		value = data[head]
		lock.Unlock()
		Return True
	End Method
	
	Method Clear()
		lock.Lock()
		Super.Clear()
		taskLock.Lock()
		unfinishedTasks = 0
		allTasksDone.Signal()
		taskLock.Unlock()
		notFull.Signal()
		lock.Unlock()
	End Method
	
	Method TrimExcess()
		' noop since a blocking queue does not grow beyond its initial capacity
	End Method
	
	Method Resize()
		lock.Lock()
		Super.Resize()
		notFull.Signal()
		lock.Unlock()
	End Method

	Rem
	bbdoc: Signals that a task is done.
	End Rem
	Method TaskDone()
		taskLock.Lock()
		If unfinishedTasks > 0 Then
			unfinishedTasks :- 1
			If unfinishedTasks = 0 Then
				allTasksDone.Signal()
			End If
		End If
		taskLock.Unlock()
	End Method

	Rem
	bbdoc: Waits until all tasks are done.
	End Rem
	Method Join()
		taskLock.Lock()
		While unfinishedTasks > 0
			allTasksDone.Wait(taskLock)
		Wend
		taskLock.Unlock()
	End Method
	
End Type
?
