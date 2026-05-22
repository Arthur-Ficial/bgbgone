import Foundation
import BgBgOneCore

func runServerParsingTests() {
    test("multipart parser extracts text fields and file uploads") {
        let boundary = "Boundary123"
        let body = """
        --Boundary123\r
        Content-Disposition: form-data; name="format"\r
        \r
        png\r
        --Boundary123\r
        Content-Disposition: form-data; name="image_file"; filename="photo.jpg"\r
        Content-Type: image/jpeg\r
        \r
        abc123\r
        --Boundary123--\r
        """
        let form = try ServerFormParser.parseMultipart(Data(body.utf8), boundary: boundary)
        try assertEqual(form.fields["format"], "png")
        let upload = try assertNotNilAndUnwrap(form.files["image_file"])
        try assertEqual(upload.filename, "photo.jpg")
        try assertEqual(upload.contentType, "image/jpeg")
        try assertEqual(String(data: upload.data, encoding: .utf8), "abc123")
    }

    test("urlencoded parser decodes plus and percent escapes") {
        let form = ServerFormParser.parseURLEncoded(Data("bg_color=%23ffffff&crop=true&name=hello+world".utf8))
        try assertEqual(form.fields["bg_color"], "#ffffff")
        try assertEqual(form.fields["crop"], "true")
        try assertEqual(form.fields["name"], "hello world")
    }

    test("removal request maps supported fields to Config") {
        let form = ServerForm(
            fields: [
                "format": "jpg",
                "bg_color": "ffffff",
                "channels": "rgba",
                "crop": "true",
                "crop_margin": "12",
                "shadow_type": "drop",
                "quality": "80",
                "bg_fit": "contain",
                "feather": "4",
                "threshold": "0.55",
                "type": "person",
                "size": "auto"
            ],
            files: [
                "image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1, 2, 3]))
            ]
        )
        let request = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(request.input, .uploaded(Data([1, 2, 3]), filename: "photo.jpg"))
        try assertEqual(request.responseKind, .image)
        try assertEqual(request.config.inputs, ["/tmp/input.jpg"])
        try assertEqual(request.config.outputFormat, .jpeg)
        try assertTrue(request.config.cropToSubject)
        try assertEqual(request.config.cropMargins, ServerEdgeInsets(top: .pixels(12), right: .pixels(12), bottom: .pixels(12), left: .pixels(12)))
        try assertTrue(request.config.dropShadow)
        try assertEqual(request.config.quality, 80)
        try assertEqual(request.config.bgFit, .contain)
        try assertEqual(request.config.feather, 4.0)
        try assertEqual(request.config.threshold, 0.55)
        try assertEqual(request.config.algo, .person)
        if case .solidColor(let rgba) = request.config.background {
            try assertEqual(rgba.r, 1.0)
            try assertEqual(rgba.g, 1.0)
            try assertEqual(rgba.b, 1.0)
        } else {
            throw TestFailure("expected solid color background")
        }
    }

    test("channels alpha maps to mask-only output") {
        let form = ServerForm(fields: ["channels": "alpha"], files: [
            "image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1]))
        ])
        let request = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertTrue(request.config.maskOnly)
    }

    test("format json maps to JSON response with png image bytes") {
        let form = ServerForm(fields: ["format": "json"], files: [
            "image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1]))
        ])
        let request = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(request.responseKind, .json)
        try assertEqual(request.config.outputFormat, .png)
    }

    test("image_file_b64 is accepted as an input source") {
        let form = ServerForm(fields: ["image_file_b64": Data([9, 8, 7]).base64EncodedString()], files: [:])
        let request = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.bin", backgroundImagePath: nil)
        try assertEqual(request.input, .uploaded(Data([9, 8, 7]), filename: "image"))
    }

    test("network-backed image fields are rejected to preserve local-only runtime") {
        for fields in [["image_url": "https://example.com/in.jpg"], ["bg_image_url": "https://example.com/bg.jpg", "image_file_b64": "AQID"]] {
            do {
                _ = try ServerRemovalRequest.parse(form: ServerForm(fields: fields, files: [:]), inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
                throw TestFailure("expected throw")
            } catch let e as ServerAPIError {
                try assertEqual(e.status, 501)
                try assertEqual(e.code, "not_implementable")
            }
        }
    }

    test("zip output format is accepted") {
        let form = ServerForm(fields: ["format": "zip"], files: [
            "image_file": ServerUploadedFile(filename: "photo.jpg", contentType: "image/jpeg", data: Data([1]))
        ])
        let request = try ServerRemovalRequest.parse(form: form, inputPath: "/tmp/input.jpg", backgroundImagePath: nil)
        try assertEqual(request.responseKind, .zip)
        try assertEqual(request.config.outputFormat, .zip)
    }
}
