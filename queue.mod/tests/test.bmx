SuperStrict

Framework brl.standardio
Import brl.maxunit
Import Collections.Queue


New TTestSuite.run()

Type TQueueTest Extends TTest

	Method TestEnqueueDequeue() { test }
		Local queue:TQueue<Int> = New TQueue<Int>
		
		Local value:Int
		Local count:Int
		For Local i:Int = 0 Until 10
			queue.Enqueue(i)
			assertEquals(value, queue.Peek(), "Peek after enqueue should return the front value")
			count :+ 1
			assertEquals(count, queue.Count(), "Count should reflect number of items in queue")
		Next
		
		For Local i:Int = 0 Until 10
			assertEquals(count, queue.Count(), "size should reflect number of items in queue")
			assertEquals(value, queue.Peek(), "Peek before dequeue should return the front value")
			
			assertEquals(value, queue.Dequeue(), "Dequeue should return the front value")
			count :- 1
			value :+ 1

			assertEquals(count, queue.Count(), "size should reflect number of items in queue")
		Next
		
		assertEquals(0, queue.Count(), "Count should be 0 after dequeuing all items")
		assertTrue(queue.head = queue.tail, "head and tail should be equal when queue is empty")
	
	End Method

	Method TestClear() { test }
		Local queue:TQueue<Int> = New TQueue<Int>

		Local value:Int
		Local count:Int
		For Local i:Int = 0 Until 10
			queue.Enqueue(i)
			count :+ 1
		Next
		
		queue.Clear()
		assertEquals(0, queue.Count(), "Count should be 0 after Clear")
		assertTrue(queue.head = queue.tail, "head and tail should be equal after Clear")
		
	End Method

	Method TestGrowBeyondInitialCapacity() { test }

		Local queue:TQueue<Int> = New TQueue<Int>(4)
		For Local i:Int = 0 Until 10
			queue.Enqueue(i)
		Next
		assertEquals(10, queue.Count(), "Count after growth")
		For Local i:Int = 0 Until 10
			assertEquals(i, queue.Dequeue(), "Items should dequeue in FIFO order after growth")
		Next
		assertTrue(queue.IsEmpty(), "Queue should be empty")

	End Method

	Method TestGrowAfterWraparound() { test }

		Local queue:TQueue<Int> = New TQueue<Int>(4)
		queue.Enqueue(0)
		queue.Enqueue(1)
		queue.Enqueue(2)
		queue.Enqueue(3)
		assertEquals(0, queue.Dequeue())
		assertEquals(1, queue.Dequeue())
		queue.Enqueue(4)
		queue.Enqueue(5)
		' Queue is now full but wrapped: 2,3,4,5
		queue.Enqueue(6) ' should trigger resize
		For Local expected:Int = 2 To 6
			assertEquals(expected, queue.Dequeue(), "FIFO order should survive resize after wraparound")
		Next
		assertTrue(queue.IsEmpty())

	End Method

	Method TestTrimExcessPreservesOrder() { test }
		Local queue:TQueue<Int> = New TQueue<Int>(16)
		For Local i:Int = 0 Until 10
			queue.Enqueue(i)
		Next
		queue.TrimExcess()
		assertEquals(10, queue.Count(), "Count should survive TrimExcess")
		For Local i:Int = 0 Until 10
			assertEquals(i, queue.Dequeue(), "FIFO order should survive TrimExcess")
		Next
	End Method

	Method TestTrimExcessAfterWraparound() { test }

		Local queue:TQueue<Int> = New TQueue<Int>(8)
		For Local i:Int = 0 Until 8
			queue.Enqueue(i)
		Next
		For Local i:Int = 0 Until 3
			assertEquals(i, queue.Dequeue())
		Next
		For Local i:Int = 8 Until 11
			queue.Enqueue(i)
		Next
		' Queue should contain 3,4,5,6,7,8,9,10
		queue.TrimExcess()
		For Local expected:Int = 3 Until 11
			assertEquals(expected, queue.Dequeue(), "FIFO order should survive TrimExcess after wraparound")
		Next
		assertTrue(queue.IsEmpty())

	End Method

	Method TestTrimExcessEmptyQueue() { test }

		Local queue:TQueue<Int> = New TQueue<Int>(16)
		queue.TrimExcess()
		assertEquals(0, queue.Count())
		assertTrue(queue.IsEmpty())
		queue.Enqueue(42)
		assertEquals(42, queue.Dequeue(), "Queue should still work after trimming empty queue")

	End Method

	Method TestClearAfterWraparound() { test }

		Local queue:TQueue<Int> = New TQueue<Int>(8)
		For Local i:Int = 0 Until 8
			queue.Enqueue(i)
		Next
		For Local i:Int = 0 Until 3
			queue.Dequeue()
		Next
		For Local i:Int = 8 Until 11
			queue.Enqueue(i)
		Next
		queue.Clear()
		assertTrue(queue.IsEmpty())
		assertEquals(0, queue.Count())
		queue.Enqueue(42)
		assertEquals(42, queue.Dequeue())

	End Method

	Method TestContainsAfterWraparound() { test }

		Local queue:TQueue<Int> = New TQueue<Int>(8)
		For Local i:Int = 0 Until 8
			queue.Enqueue(i)
		Next
		For Local i:Int = 0 Until 3
			queue.Dequeue()
		Next
		For Local i:Int = 8 Until 11
			queue.Enqueue(i)
		Next
		assertFalse(queue.Contains(0))
		assertFalse(queue.Contains(1))
		assertFalse(queue.Contains(2))
		For Local i:Int = 3 Until 11
			assertTrue(queue.Contains(i))
		Next

	End Method

	Method TestDequeueEmptyThrows() { test }

		Local queue:TQueue<Int> = New TQueue<Int>(0)

		Try
			queue.Dequeue()
			Fail("Dequeue on empty queue should throw")
		Catch e:TInvalidOperationException
			assertEquals("The queue is empty", e.error, "Exception message should indicate empty queue")
		End Try

	End Method

End Type
