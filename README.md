MASM4 --------
--------------

I'm using a linked list for our data structure.
The ListNode STRUCT currently has 3 attributes:
		dPosition 	--- the number of the node inserted
				(this one will need some working on later when saving data and restarting the program as the count will reset).
		NodeData	--- holds the address of an string whose memory is allocated by the bailey macro
		NextPtr		---	points to the next node in the list
		
The last node in the list currently points a ListNode STRUCT initialized to NULL in all fields called lListTail.
The memory label (variable) pListHead points to (holds the address of) the first ListNode in the list.
The memory label pLastAddr points to the address of the last ListNode in the list.

As of this first push options 1 and 2 are finished and working properly.