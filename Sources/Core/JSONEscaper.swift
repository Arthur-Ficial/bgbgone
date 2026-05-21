import Foundation

public enum JSONEscaper {
    public static func escape(_ value: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(value.utf8.count)

        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x22:
                escaped += "\\\""
            case 0x5C:
                escaped += "\\\\"
            case 0x08:
                escaped += "\\b"
            case 0x0C:
                escaped += "\\f"
            case 0x0A:
                escaped += "\\n"
            case 0x0D:
                escaped += "\\r"
            case 0x09:
                escaped += "\\t"
            case 0x00...0x1F:
                escaped += String(format: "\\u%04X", scalar.value)
            default:
                escaped.unicodeScalars.append(scalar)
            }
        }

        return escaped
    }
}
