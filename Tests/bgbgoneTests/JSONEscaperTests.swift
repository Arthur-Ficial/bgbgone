import BgBgOneCore

func runJSONEscaperTests() {
    test("JSONEscaper escapes all required JSON string characters") {
        let raw = "quote:\" slash:\\ newline:\n tab:\t carriage:\r backspace:\u{08} formfeed:\u{0C}"
        let escaped = JSONEscaper.escape(raw)
        try assertEqual(
            escaped,
            "quote:\\\" slash:\\\\ newline:\\n tab:\\t carriage:\\r backspace:\\b formfeed:\\f"
        )
    }

    test("JSONEscaper encodes other ASCII control characters as unicode escapes") {
        try assertEqual(JSONEscaper.escape("x\u{001F}y"), "x\\u001Fy")
    }
}
