import Foundation

extension Data {
    func base32String() -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz234567").map{"\($0)"}

        var result = ""
        let bytes = [UInt8](self)
        for byteIndex in stride(from: 0, to: self.count, by: 5) {
            let maxOffset = (byteIndex + 5 >= self.count) ? self.count : byteIndex + 5
            let numberOfBytes = maxOffset - byteIndex

            var byte0: UInt8 = 0
            var byte1: UInt8 = 0
            var byte2: UInt8 = 0
            var byte3: UInt8 = 0
            var byte4: UInt8 = 0

            switch numberOfBytes {
            case 5:
                byte4 = UInt8(bytes[byteIndex + 4])
                fallthrough
            case 4:
                byte3 = UInt8(bytes[byteIndex + 3])
                fallthrough
            case 3:
                byte2 = UInt8(bytes[byteIndex + 2])
                fallthrough
            case 2:
                byte1 = UInt8(bytes[byteIndex + 1])
                fallthrough
            case 1:
                byte0 = UInt8(bytes[byteIndex + 0])
                fallthrough
            default:
                break
            }

            var encoded: [String] = .init(repeating: "=", count: 8)
            switch numberOfBytes {
            case 5:
                encoded[7] = alphabet[Int( byte4 & 0x1F )]
                fallthrough;
            case 4:
                encoded[6] = alphabet[Int( ((byte3 << 3) & 0x18) | ((byte4 >> 5) & 0x07) )]
                encoded[5] = alphabet[Int( ((byte3 >> 2) & 0x1F) )]
                fallthrough
            case 3:
                encoded[4] = alphabet[Int( ((byte2 << 1) & 0x1E) | ((byte3 >> 7) & 0x01) )]
                fallthrough
            case 2:
                encoded[2] = alphabet[Int( ((byte1 >> 1) & 0x1F) )]
                encoded[3] = alphabet[Int( ((byte1 << 4) & 0x10) | ((byte2 >> 4) & 0x0F) )]
                fallthrough
            case 1:
                encoded[0] = alphabet[Int( ((byte0 >> 3) & 0x1F) )]
                encoded[1] = alphabet[Int( ((byte0 << 2) & 0x1C) | ((byte1 >> 6) & 0x03)  )]
                fallthrough
            default:
                break
            }
            result += encoded.joined()
        }

        return result
    }
}
