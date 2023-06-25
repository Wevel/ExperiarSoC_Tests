import random
import numpy as np
import matplotlib.pyplot as plt


class Cache:

	def __init__(self, size: int) -> None:
		self.size = size

	def GetEvictionIndex(self) -> int:
		raise Exception(f"Not implemented function 'GetEvictionIndex' by class {type(self).__name__}")

	def GetEvictionValue(self) -> int:
		raise Exception(f"Not implemented function 'GetEvictionValue' by class {type(self).__name__}")

	def Insert(self, value: int):
		raise Exception(f"Not implemented function 'Insert' by class {type(self).__name__}")

	def Use(self, value: int) -> int:
		raise Exception(f"Not implemented function 'Use' by class {type(self).__name__}")

	def UseIndex(self, value: int) -> int:
		raise Exception(f"Not implemented function 'Use' by class {type(self).__name__}")


class LRUNode:

	def __init__(self, data: int, lastPointer: int, nextPointer: int) -> None:
		self.data = data
		self.lastPointer = lastPointer
		self.nextPointer = nextPointer


class LRUCache(Cache):

	def __init__(self, size: int) -> None:
		super().__init__(size)

		self.leastUsedPointer = 0
		self.mostUsedPointer = self.size - 1

		self.nodes = [LRUNode(-1, i - 1 if i > 0 else -1, i + 1 if i < self.size - 1 else -1) for i in range(self.size)]

		for i in range(self.size):
			self.Insert(i)

	def __str__(self) -> str:
		value = ""
		node = self.nodes[self.leastUsedPointer]

		while node.nextPointer >= 0:
			value += f"{node.data if node.data >= 0 else '_'} -> "
			node = self.nodes[node.nextPointer]

		value += f"{node.data}"
		return value

	def GetEvictionIndex(self) -> int:
		return self.leastUsedPointer

	def GetEvictionValue(self) -> int:
		return self.nodes[self.GetEvictionIndex()].data

	def GetRUPosition(self, value: int) -> int:
		position = 0
		node = self.nodes[self.leastUsedPointer]
		while node.nextPointer >= 0 and node.data != value:
			node = self.nodes[node.nextPointer]
			position += 1

		return position

	def Insert(self, value: int):
		index = self.GetEvictionIndex()
		self.nodes[index].data = value
		self.Use(value)

	def Use(self, value: int) -> int:
		index = -1
		for i, n in enumerate(self.nodes):
			if n.data == value:
				index = i
				break

		if index < 0:
			raise Exception(f"Invalid index '{index}' for value '{value}'")

		return self.UseIndex(index)

	def UseIndex(self, index: int) -> int:
		node = self.nodes[index]
		if self.mostUsedPointer == index:
			return node.data

		currentNodeNext = node.nextPointer
		currentNodeLast = node.lastPointer

		# Update most used
		self.nodes[self.mostUsedPointer].nextPointer = index
		node.lastPointer = self.mostUsedPointer
		node.nextPointer = -1
		self.mostUsedPointer = index

		if self.leastUsedPointer == index:
			# Update least used
			self.leastUsedPointer = currentNodeNext
			self.nodes[currentNodeNext].lastPointer = -1
		else:
			# Update link
			self.nodes[currentNodeLast].nextPointer = currentNodeNext
			self.nodes[currentNodeNext].lastPointer = currentNodeLast

		return node.data


class BinaryTreePLRUCache(Cache):

	def __init__(self, size: int) -> None:
		super().__init__(size)

		self.data = [-1 for i in range(self.size)]
		self.tree: list[list[bool]] = []

		levelSize = self.size // 2

		while levelSize >= 1:
			self.tree.append([False for _ in range(levelSize)])
			levelSize = levelSize // 2

		self.tree.reverse()

		for i in range(self.size):
			self.Insert(i)
			#print(self)

	def __str__(self) -> str:
		value = ""

		for i, level in enumerate(self.tree):
			value += "    " * (len(self.tree[len(self.tree) - i - 1]) - 1)
			for l in level:
				if l:
					value += f" -+-V"
				else:
					value += f"V-+- "
				value += "   "
				value += "        " * (len(self.tree) - i - 1)
			value += f"\n"

		for i in self.data:
			value += f"{i if i >= 0 else '_'}   "
		return value

	def GetEvictionIndex(self) -> int:
		index = 0

		for level in self.tree:
			index = (index << 1) | 1 if level[index] else index << 1

		return index

	def GetEvictionValue(self) -> int:
		return self.data[self.GetEvictionIndex()]

	def Insert(self, value: int):
		index = self.GetEvictionIndex()
		self.data[index] = value
		self.Use(value)

	def Use(self, value: int) -> int:
		index = -1
		for i, d in enumerate(self.data):
			if d == value:
				index = i
				break

		if index < 0:
			raise Exception(f"Invalid index '{index}' for value '{value}'")

		return self.UseIndex(index)

	def UseIndex(self, index: int) -> int:
		treeIndex = 0

		for i, level in enumerate(self.tree):
			if (index & (1 << (len(self.tree) - i - 1))) != 0:
				level[treeIndex] = False
				treeIndex = (treeIndex << 1) | 1
			else:
				level[treeIndex] = True
				treeIndex = treeIndex << 1

		return self.data[index]


class NRUCache(Cache):

	def __init__(self, size: int) -> None:
		super().__init__(size)

		self.data = [-1 for i in range(self.size)]
		self.used = [False for _ in range(self.size)]
		self.replacementPointer = 0

		for i in range(self.size):
			self.Insert(i)

	def __str__(self) -> str:
		value = ""

		for i in range(self.size):
			value += f"{'*' if self.used[i] else ' '} {self.data[i] if self.data[i] >= 0 else '_'}"

			if i == self.replacementPointer:
				value += f" <-"

			if i < self.size - 1:
				value += "\n"

		return value

	def GetEvictionIndex(self) -> int:
		for i in range(self.size):
			if not self.used[self.replacementPointer + i]:
				return self.replacementPointer + i

		raise Exception(f"Failed to find eviction index")

	def GetEvictionValue(self) -> int:
		return self.data[self.GetEvictionIndex()]

	def Insert(self, value: int):
		index = self.GetEvictionIndex()
		self.data[index] = value
		self.Use(value)

		self.replacementPointer = (self.replacementPointer + 1) % self.size

	def Use(self, value: int) -> int:
		index = -1
		for i, d in enumerate(self.data):
			if d == value:
				index = i
				break

		if index < 0:
			print(self)
			raise Exception(f"Invalid index '{index}' for value '{value}'")

		return self.UseIndex(index)

	def UseIndex(self, index: int) -> int:
		self.used[index] = True

		usedCount = 0
		for u in self.used:
			if u:
				usedCount += 1

		if usedCount == self.size:
			for i in range(self.size):
				self.used[i] = False

		return self.data[index]


def GetEvictionPages(size: int, pageUse: list[int]) -> list[tuple[int, int, int]]:
	lruCache = LRUCache(size)
	plruCache = BinaryTreePLRUCache(size)
	nruCache = NRUCache(size)

	evictionPages = []

	for item in pageUse:
		lruCache.UseIndex(item)
		plruCache.UseIndex(item)
		nruCache.UseIndex(item)

		evictionPages.append((lruCache.GetEvictionIndex(), plruCache.GetEvictionIndex(), nruCache.GetEvictionIndex()))

	return evictionPages


def GetDistribution(size: int, testCount: int):
	lruCache = LRUCache(size)
	plruCache = BinaryTreePLRUCache(size)
	nruCache = NRUCache(size)

	ruPosition = np.zeros((size, 2), dtype=np.int64)
	testCount = 100000
	for _ in range(testCount):
		value = random.randint(0, size - 1)
		lruCache.Use(value)
		plruCache.Use(value)
		nruCache.Use(value)
		ruPosition[lruCache.GetRUPosition(plruCache.GetEvictionValue()), 0] += 1
		ruPosition[lruCache.GetRUPosition(nruCache.GetEvictionValue()), 1] += 1

	return ruPosition / testCount


def GetTestStates():
	pageUse = []
	size = 16

	pageUse += [0x0, 0x2, 0x1, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf, 0x0, 0x2, 0x8, 0xc, 0x4, 0x3, 0xe, 0x6, 0xd, 0xa, 0xf, 0x9]

	activePages = [0]
	for item in pageUse[16:]:
		activePages.append(activePages[-1] | (1 << item))
	print(["0x%04x" % item for item in activePages])

	evictions = GetEvictionPages(size, pageUse)
	plt.figure()
	plt.plot(pageUse, label="Page Use")
	plt.plot([e[0] for e in evictions], label="LRU")
	plt.plot([e[1] for e in evictions], label="PLRU")
	plt.plot([e[2] for e in evictions], label="NRU")

	errors = [[], []]
	for i, e in enumerate(evictions):
		for j in range(3):
			if e[j] == pageUse[i]:
				errors[0].append(i)
				errors[1].append(e[j])

	plt.plot(errors[0], errors[1], "x", label="Error")
	print("Errors: ", len(errors[0]))

	plt.legend()
	plt.xlabel("Page use")
	plt.ylabel("Eviction Page Index")


def RunTest():
	# size = 16
	# lruCache = LRUCache(size)
	# plruCache = BinaryTreePLRUCache(size)
	# print(lruCache)
	# print(plruCache)
	# print(F"LRU: {lruCache.GetLRU()} PLRU:{plruCache.GetLRU()}")

	# def test(value:int):
	# 	print(f"{value}:")
	# 	lruCache.Use(value)
	# 	plruCache.Use(value)
	# 	print(lruCache)
	# 	print(plruCache)

	# 	print(F"LRU: {lruCache.GetLRU()} PLRU:{plruCache.GetLRU()}")

	# test(0)
	# test(2)
	# test(1)
	# test(1)
	# test(3)

	size = 16
	dist = GetDistribution(size, 1000000000 * (size**3))

	print(dist[-1, :])

	indices = np.array(range(size))
	plt.figure()
	plt.bar(indices - 0.2, dist[:, 0], width=0.4, label="PLRU")
	plt.bar(indices + 0.2, dist[:, 1], width=0.4, label="NRU")
	plt.legend()
	plt.yscale("log")
	plt.xlabel(f"Least Used: 0   Most Used: {size - 1}")
	plt.ylabel(f"Probability Distribution")

	GetTestStates()


if __name__ == "__main__":
	RunTest()

	plt.show()
