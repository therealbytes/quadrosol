package quadtree

import (
	"container/heap"
)

type pointItem struct {
	value    Point
	priority int
	index    int
}

// A pointHeap implements heap.Interface and holds pointItems.
type pointHeap []*pointItem

func (pq pointHeap) Len() int { return len(pq) }

func (pq pointHeap) Less(i, j int) bool {
	// We want Pop to give us the highest, not lowest, priority so we use greater than here.
	return pq[i].priority > pq[j].priority
}

func (pq pointHeap) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
	pq[i].index = i
	pq[j].index = j
}

func (pq *pointHeap) Push(x any) {
	n := len(*pq)
	item := x.(*pointItem)
	item.index = n
	*pq = append(*pq, item)
}

func (pq *pointHeap) Pop() any {
	old := *pq
	n := len(old)
	item := old[n-1]
	old[n-1] = nil  // avoid memory leak
	item.index = -1 // for safety
	*pq = old[0 : n-1]
	return item
}

// // update modifies the priority and value of an pointItem in the queue.
// func (pq *pointHeap) update(item *pointItem, value Point, priority int) {
// 	item.value = value
// 	item.priority = priority
// 	heap.Fix(pq, item.index)
// }

type PointPriorityQueue struct {
	heap *pointHeap
	cap  int
}

func NewPointPriorityQueue(cap int) *PointPriorityQueue {
	ph := make(pointHeap, 0)
	heap.Init(&ph)
	return &PointPriorityQueue{heap: &ph, cap: cap}
}

func (pq *PointPriorityQueue) Len() int {
	return pq.heap.Len()
}

func (pq *PointPriorityQueue) Cap() int {
	return pq.cap
}

func (pq *PointPriorityQueue) Full() bool {
	return pq.Len() == pq.cap
}

func (pq *PointPriorityQueue) Empty() bool {
	return pq.Len() == 0
}

func (pq *PointPriorityQueue) Peek() Point {
	item := (*pq.heap)[0]
	return item.value
}

func (pq *PointPriorityQueue) PeekPriority() int {
	item := (*pq.heap)[0]
	return item.priority
}

func (pq *PointPriorityQueue) Push(point Point, priority int) {
	if pq.Full() {
		if priority > pq.PeekPriority() {
			heap.Pop(pq.heap)
		} else {
			return
		}
	}
	item := &pointItem{
		value:    point,
		priority: priority,
	}
	heap.Push(pq.heap, item)
}

func (pq *PointPriorityQueue) Pop() Point {
	item := heap.Pop(pq.heap).(*pointItem)
	return item.value
}
