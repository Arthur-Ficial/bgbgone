import Foundation
import BgBgOneCore

func runServerCompatibilityTests() {
    func uploadedForm(fields: [String: String] = [:]) -> ServerForm {
        ServerForm(fields: fields, files: [
            "image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1, 2, 3]))
        ])
    }

    test("JSON request parser normalizes scalar fields") {
        let json = """
        {"image_file_b64":"AQID","crop":true,"size":"preview","scale":"50%","shadow_opacity":25}
        """
        let form = try ServerFormParser.parseJSON(Data(json.utf8))
        try assertEqual(form.fields["image_file_b64"], "AQID")
        try assertEqual(form.fields["crop"], "true")
        try assertEqual(form.fields["size"], "preview")
        try assertEqual(form.fields["scale"], "50%")
        try assertEqual(form.fields["shadow_opacity"], "25")
    }

    test("source validation rejects missing and multiple sources with API error codes") {
        do {
            _ = try ServerRemovalRequest.parse(form: ServerForm(), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
            throw TestFailure("expected missing source")
        } catch let e as ServerAPIError {
            try assertEqual(e.status, 400)
            try assertEqual(e.code, "missing_source")
        }

        do {
            _ = try ServerRemovalRequest.parse(
                form: ServerForm(
                    fields: ["image_file_b64": "AQID"],
                    files: ["image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1]))]
                ),
                inputPath: "/tmp/input.jpg",
                backgroundImagePath: nil
            )
            throw TestFailure("expected multiple sources")
        } catch let e as ServerAPIError {
            try assertEqual(e.status, 400)
            try assertEqual(e.code, "multiple_sources")
        }
    }

    test("network-backed source and background fields are accepted not-implementable cases") {
        for fields in [["image_url": "https://example.test/in.jpg"], ["bg_image_url": "https://example.test/bg.jpg", "image_file_b64": "AQID"]] {
            do {
                _ = try ServerRemovalRequest.parse(form: ServerForm(fields: fields), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
                throw TestFailure("expected not implementable")
            } catch let e as ServerAPIError {
                try assertEqual(e.status, 501)
                try assertEqual(e.code, "not_implementable")
                try assertTrue(e.title.contains("NOT IMPLEMENTABLE"))
            }
        }
    }

    test("format auto, json, zip, and webp compatibility decisions") {
        let transparent = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["format": "auto"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(transparent.responseKind, .image)
        try assertEqual(transparent.config.outputFormat, .png)

        let opaque = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["format": "auto", "bg_color": "fff"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(opaque.config.outputFormat, .jpeg)

        let json = try ServerRemovalRequest.parse(form: uploadedForm(), inputPath: "/tmp/input.jpg", backgroundImagePath: nil, acceptHeader: "application/json")
        try assertEqual(json.responseKind, .json)
        try assertEqual(json.config.outputFormat, .png)

        let zip = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["format": "zip"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(zip.responseKind, .zip)
        try assertEqual(zip.config.outputFormat, .zip)

        do {
            _ = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["format": "webp"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
            throw TestFailure("expected webp not implementable")
        } catch let e as ServerAPIError {
            try assertEqual(e.status, 501)
            try assertEqual(e.code, "not_implementable")
        }
    }

    test("canonical size values map to output megapixel caps") {
        let cases: [(String, Double)] = [
            ("preview", 0.25), ("full", 25.0), ("auto", 25.0), ("50MP", 50.0)
        ]
        for (raw, expected) in cases {
            let req = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["size": raw, "format": "jpg"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
            try assertEqual(req.config.maxOutputMegapixels, expected, " for \(raw)")
        }

        let pngFull = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["size": "full", "format": "png"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(pngFull.config.maxOutputMegapixels, 10.0)
    }

    test("old size names are rejected") {
        for raw in ["small", "regular", "medium", "hd", "4k"] {
            do {
                _ = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["size": raw]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
                throw TestFailure("expected invalid_size for \(raw)")
            } catch let e as ServerAPIError {
                try assertEqual(e.code, "invalid_size")
            }
        }
    }

    test("type and type_level parse to local algorithm and response metadata policy") {
        let person = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["type": "person", "type_level": "2"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(person.config.algo, .person)
        try assertEqual(person.typeHeaderValue, "person")

        let product = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["type": "product"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(product.config.algo, .auto)
        try assertEqual(product.typeHeaderValue, "product")

        let none = try ServerRemovalRequest.parse(form: uploadedForm(fields: ["type_level": "none"]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertNil(none.typeHeaderValue)
    }

    test("roi, crop margin variants, scale, position, semitransparency, and shadows parse") {
        let req = try ServerRemovalRequest.parse(
            form: uploadedForm(fields: [
                "roi": "10% 20% 90% 80%",
                "crop": "true",
                "crop_margin": "10px 20px 30px 40px",
                "scale": "50%",
                "position": "25% 75%",
                "semitransparency": "false",
                "shadow_type": "drop",
                "shadow_opacity": "25"
            ]),
            inputPath: "/tmp/input.jpg",
            backgroundImagePath: nil
        )
        try assertEqual(req.config.roi, ServerRectSpec(x1: .percent(0.10), y1: .percent(0.20), x2: .percent(0.90), y2: .percent(0.80)))
        try assertEqual(req.config.cropMargins, ServerEdgeInsets(top: .pixels(10), right: .pixels(20), bottom: .pixels(30), left: .pixels(40)))
        try assertEqual(req.config.scalePercent, 0.50)
        try assertEqual(req.config.position, ServerPosition(x: 0.25, y: 0.75))
        try assertFalse(req.config.semitransparency)
        try assertTrue(req.config.dropShadow)
        try assertEqual(req.config.shadowOpacity, 0.25)
    }

    test("local shared image controls parse through the server request") {
        let req = try ServerRemovalRequest.parse(
            form: uploadedForm(fields: [
                "quality": "77",
                "bg_fit": "tile",
                "feather": "6",
                "threshold": "0.35"
            ]),
            inputPath: "/tmp/input.jpg",
            backgroundImagePath: nil
        )
        try assertEqual(req.config.quality, 77)
        try assertEqual(req.config.bgFit, .tile)
        try assertEqual(req.config.feather, 6.0)
        try assertEqual(req.config.threshold, 0.35)
    }

    test("normalizedColor handles bare hex, prefixed hex, and rgb syntax") {
        try assertEqual(ServerCompatibilityParser.normalizedColor("fff"), "#fff")
        try assertEqual(ServerCompatibilityParser.normalizedColor("ffffff"), "#ffffff")
        try assertEqual(ServerCompatibilityParser.normalizedColor("ffffffff"), "#ffffffff")
        try assertEqual(ServerCompatibilityParser.normalizedColor("#abc"), "#abc")
        try assertEqual(ServerCompatibilityParser.normalizedColor("rgb:0,128,255"), "rgb:0,128,255")
        try assertEqual(ServerCompatibilityParser.normalizedColor("rgba:1,2,3,0.5"), "rgba:1,2,3,0.5")
        try assertEqual(ServerCompatibilityParser.normalizedColor("  white  "), "white")
    }

    test("bg_color upload via JSON request payload propagates to the parsed Config") {
        let json = """
        {"image_file_b64":"AQID","bg_color":"#0066cc","format":"jpg"}
        """
        let form = try ServerFormParser.parseJSON(Data(json.utf8))
        let req = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(req.config.outputFormat, .jpeg)
        if case .solidColor(let rgba) = req.config.background {
            try assertEqual(rgba.r, 0.0)
            try assertEqual(rgba.b, 204.0 / 255.0)
        } else {
            throw TestFailure("expected solid color background")
        }
    }

    test("bg_image_file_b64 maps to an .image background using the supplied path") {
        let form = ServerForm(
            fields: ["bg_image_file_b64": Data([4, 5, 6]).base64EncodedString()],
            files: ["image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1, 2, 3]))]
        )
        let req = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: "/tmp/bg.png")
        if case .image(let path) = req.config.background {
            try assertEqual(path, "/tmp/bg.png")
        } else {
            throw TestFailure("expected image background, got \(String(describing: req.config.background))")
        }
    }

    test("multiple background sources are rejected with multiple_bg_sources error") {
        let form = ServerForm(
            fields: [
                "bg_color": "#fff",
                "bg_image_file_b64": Data([1, 2, 3]).base64EncodedString()
            ],
            files: ["image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1]))]
        )
        do {
            _ = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: "/tmp/bg.png")
            throw TestFailure("expected multiple_bg_sources")
        } catch let e as ServerAPIError {
            try assertEqual(e.code, "multiple_bg_sources")
        }
    }

    test("type_level=none suppresses the X-Type header even when type is set") {
        let form = ServerForm(
            fields: ["type": "person", "type_level": "none"],
            files: ["image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1]))]
        )
        let req = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertNil(req.typeHeaderValue)
    }

    test("type_level=latest yields the literal type hint on the X-Type header") {
        let form = ServerForm(
            fields: ["type": "car", "type_level": "latest"],
            files: ["image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1]))]
        )
        let req = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(req.typeHeaderValue, "car")
    }

    test("opaque bg color over format=auto picks JPEG; transparent picks PNG") {
        let opaque = try ServerRemovalRequest.parse(form: ServerForm(
            fields: ["bg_color": "fff"],
            files: ["image_file": ServerUploadedFile(filename: "p.jpg", contentType: "image/jpeg", data: Data([1]))]
        ), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(opaque.config.outputFormat, .jpeg)

        let translucent = try ServerRemovalRequest.parse(form: ServerForm(
            fields: ["bg_color": "rgba:255,255,255,128"],
            files: ["image_file": ServerUploadedFile(filename: "p.jpg", contentType: "image/jpeg", data: Data([1]))]
        ), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(translucent.config.outputFormat, .png)
    }

    test("missing-boundary multipart request is rejected") {
        do {
            _ = try ServerFormParser.parseMultipart(Data("hello".utf8), boundary: "")
            throw TestFailure("expected parser error")
        } catch let e as BgBgOneError {
            if case .parser = e { } else { throw TestFailure("wrong error: \(e)") }
        }
    }

    test("invalid channels, geometry, matte, output, and shadow controls return API error codes") {
        let invalids: [(String, [String: String])] = [
            ("invalid_channels", ["channels": "rgb"]),
            ("invalid_roi", ["roi": "0 0 10"]),
            ("invalid_crop_margin", ["crop_margin": "bogus"]),
            ("invalid_scale", ["scale": "5%"]),
            ("invalid_position", ["position": "left"]),
            ("invalid_semitransparency", ["semitransparency": "maybe"]),
            ("invalid_quality", ["quality": "101"]),
            ("invalid_bg_fit", ["bg_fit": "stretch"]),
            ("invalid_feather", ["feather": "-1"]),
            ("invalid_threshold", ["threshold": "2"]),
            ("invalid_shadow_opacity", ["shadow_type": "drop", "shadow_opacity": "101"])
        ]
        for (code, fields) in invalids {
            do {
                _ = try ServerRemovalRequest.parse(form: uploadedForm(fields: fields), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
                throw TestFailure("expected \(code)")
            } catch let e as ServerAPIError {
                try assertEqual(e.status, 400, " for \(code)")
                try assertEqual(e.code, code)
            }
        }
    }
}
