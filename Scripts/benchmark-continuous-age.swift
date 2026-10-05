import Foundation
import Dispatch

@main
struct Benchmark {
    static func main() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        struct Fixtures: Decodable { let cases: [Case] }
        struct Case: Decodable { let input: FitnessAgeInput }
        let cases = try JSONDecoder().decode(Fixtures.self, from: data).cases
        let calculator = FitnessAgeCalculator()
        var checksum = 0.0
        for _ in 0..<100 { for testCase in cases { checksum += calculator.calculate(testCase.input).fitnessAge } }
        var times: [Double] = []
        times.reserveCapacity(10_000)
        for iteration in 0..<10_000 {
            let input = cases[iteration % cases.count].input
            let start = DispatchTime.now().uptimeNanoseconds
            let result = calculator.calculate(input)
            let elapsed = DispatchTime.now().uptimeNanoseconds - start
            checksum += result.fitnessAge + result.overallScore + result.confidence
            times.append(Double(elapsed) / 1_000_000)
        }
        times.sort()
        print("core fractional calculation Release (-O), 10000 samples; median_ms=\(times[times.count / 2]); p95_ms=\(times[times.count * 95 / 100]); max_ms=\(times.last!); checksum=\(checksum)")
    }
}
