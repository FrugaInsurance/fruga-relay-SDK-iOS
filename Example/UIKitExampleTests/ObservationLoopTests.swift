import FrugaExampleUI
import Observation
import Testing

@testable import UIKitExample

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ObservationLoopTests {
  @Observable
  @MainActor
  final class Counter {
    var value = 0
  }

  private func settle() async {
    for _ in 0..<20 { await Task.yield() }
  }

  @Test func appliesNowAndAfterEveryChange() async {
    let counter = Counter()
    let loop = ObservationLoop()
    var seen: [Int] = []
    loop.start { seen.append(counter.value) }
    #expect(seen == [0])
    counter.value = 1
    await settle()
    counter.value = 2
    await settle()
    #expect(seen == [0, 1, 2])
    loop.stop()
  }

  @Test func stopsAfterStop() async {
    let counter = Counter()
    let loop = ObservationLoop()
    var seen: [Int] = []
    loop.start { seen.append(counter.value) }
    loop.stop()
    counter.value = 1
    await settle()
    #expect(seen == [0])
  }

  @Test func restartingReplacesTheEarlierRun() async {
    let counter = Counter()
    let loop = ObservationLoop()
    var first: [Int] = []
    var second: [Int] = []
    loop.start { first.append(counter.value) }
    loop.start { second.append(counter.value) }
    counter.value = 1
    await settle()
    #expect(first == [0])
    #expect(second == [0, 1])
    loop.stop()
  }
}
