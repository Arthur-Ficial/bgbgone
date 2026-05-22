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
