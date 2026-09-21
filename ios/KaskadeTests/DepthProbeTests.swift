import Testing
import CoreVideo
@testable import Kaskade

@Test func liestDenMittelpunktDerTiefenkarte() throws {
    var buffer: CVPixelBuffer?
    CVPixelBufferCreate(nil, 5, 5, kCVPixelFormatType_DepthFloat32, nil, &buffer)
    let b = try #require(buffer)

    CVPixelBufferLockBaseAddress(b, [])
    let basis = CVPixelBufferGetBaseAddress(b)!.assumingMemoryBound(to: Float32.self)
    let zeilenBytes = CVPixelBufferGetBytesPerRow(b) / MemoryLayout<Float32>.size
    for y in 0..<5 { for x in 0..<5 { basis[y * zeilenBytes + x] = 9.9 } }
    basis[2 * zeilenBytes + 2] = 1.75
    CVPixelBufferUnlockBaseAddress(b, [])

    let tiefe = try #require(DepthProbe.centerValue(of: b))
    #expect(abs(tiefe - 1.75) < 1e-5)
}
