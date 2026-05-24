import Foundation

/// Single source of truth for `BgBgOneError.code` values.
/// Codes are stable wire identifiers; never rename, only add. Alphabetised.
///
/// Naming: `BGBG_<CATEGORY>_<NOUN>_<VERB?>`
///   CATEGORY ∈ { PARSE, USER, NORESULT, FRAMEWORK }
public enum ErrorCodes {
    // MARK: parser (exit 2)
    public static let parseColourUnknown               = "BGBG_PARSE_COLOUR_UNKNOWN"
    public static let parseCropMarginInvalid           = "BGBG_PARSE_CROP_MARGIN_INVALID"
    public static let parseFlagDuplicate               = "BGBG_PARSE_FLAG_DUPLICATE"
    public static let parseFlagMissingValue            = "BGBG_PARSE_FLAG_MISSING_VALUE"
    public static let parseFlagUnknown                 = "BGBG_PARSE_FLAG_UNKNOWN"
    public static let parseFlagValueInvalid            = "BGBG_PARSE_FLAG_VALUE_INVALID"
    public static let parseHttpBodyEmpty               = "BGBG_PARSE_HTTP_BODY_EMPTY"
    public static let parseHttpContentTypeUnsupported  = "BGBG_PARSE_HTTP_CONTENT_TYPE_UNSUPPORTED"
    public static let parseHttpFieldUnknown            = "BGBG_PARSE_HTTP_FIELD_UNKNOWN"
    public static let parseHttpFieldValueInvalid       = "BGBG_PARSE_HTTP_FIELD_VALUE_INVALID"
    public static let parseHttpJsonInvalid             = "BGBG_PARSE_HTTP_JSON_INVALID"
    public static let parseHttpJsonNotObject           = "BGBG_PARSE_HTTP_JSON_NOT_OBJECT"
    public static let parseHttpMultipartBoundaryMissing = "BGBG_PARSE_HTTP_MULTIPART_BOUNDARY_MISSING"
    public static let parseHttpMultipartInvalid        = "BGBG_PARSE_HTTP_MULTIPART_INVALID"
    public static let parseHttpRequestBodyTooLarge     = "BGBG_PARSE_HTTP_REQUEST_BODY_TOO_LARGE"
    public static let parseHttpRequestInvalid          = "BGBG_PARSE_HTTP_REQUEST_INVALID"
    public static let parseHttpRouteUnknown            = "BGBG_PARSE_HTTP_ROUTE_UNKNOWN"
    public static let parseRoiInvalid                  = "BGBG_PARSE_ROI_INVALID"

    // MARK: user (exit 1)
    public static let userBackgroundImageNotFound      = "BGBG_USER_BACKGROUND_IMAGE_NOT_FOUND"
    public static let userBackgroundImageUnreadable    = "BGBG_USER_BACKGROUND_IMAGE_UNREADABLE"
    public static let userBatchOutputConflict          = "BGBG_USER_BATCH_OUTPUT_CONFLICT"
    public static let userFormatUnsupported            = "BGBG_USER_FORMAT_UNSUPPORTED"
    public static let userHttpAuthenticationInvalid     = "BGBG_USER_HTTP_AUTHENTICATION_INVALID"
    public static let userHttpOriginForbidden           = "BGBG_USER_HTTP_ORIGIN_FORBIDDEN"
    public static let userImageDataEmpty               = "BGBG_USER_IMAGE_DATA_EMPTY"
    public static let userImageDecodeFail              = "BGBG_USER_IMAGE_DECODE_FAIL"
    public static let userImageReadFail                = "BGBG_USER_IMAGE_READ_FAIL"
    public static let userInputNotFound                = "BGBG_USER_INPUT_NOT_FOUND"
    public static let userInputCountMismatch           = "BGBG_USER_INPUT_COUNT_MISMATCH"
    public static let userJpegAlphaLoss                = "BGBG_USER_JPEG_ALPHA_LOSS"
    public static let userOutputDirNotWritable         = "BGBG_USER_OUTPUT_DIR_NOT_WRITABLE"
    public static let userOutputPathInvalid            = "BGBG_USER_OUTPUT_PATH_INVALID"
    public static let userServerPortInUse              = "BGBG_USER_SERVER_PORT_IN_USE"
    public static let userStdinEmpty                   = "BGBG_USER_STDIN_EMPTY"
    public static let userStdoutTTYRefuse              = "BGBG_USER_STDOUT_TTY_REFUSE"

    // MARK: no_result (exit 2)
    public static let noResultNoSubject                = "BGBG_NORESULT_NO_SUBJECT"
    public static let noResultMaskEmpty                = "BGBG_NORESULT_MASK_EMPTY"
    public static let noResultEmptyImage               = "BGBG_NORESULT_EMPTY_IMAGE"

    // MARK: framework (exit 3)
    public static let frameworkCIBlurUnavailable       = "BGBG_FRAMEWORK_CI_BLUR_UNAVAILABLE"
    public static let frameworkCIBlurNoOutput          = "BGBG_FRAMEWORK_CI_BLUR_NO_OUTPUT"
    public static let frameworkCGContextFail           = "BGBG_FRAMEWORK_CGCONTEXT_FAIL"
    public static let frameworkCGImageFail             = "BGBG_FRAMEWORK_CGIMAGE_FAIL"
    public static let frameworkCGDataProviderFail      = "BGBG_FRAMEWORK_CGDATA_PROVIDER_FAIL"
    public static let frameworkComposeFail             = "BGBG_FRAMEWORK_COMPOSE_FAIL"
    public static let frameworkCropFail                = "BGBG_FRAMEWORK_CROP_FAIL"
    public static let frameworkEncodeFail              = "BGBG_FRAMEWORK_ENCODE_FAIL"
    public static let frameworkMaskApplyFail           = "BGBG_FRAMEWORK_MASK_APPLY_FAIL"
    public static let frameworkMaskRenderFail          = "BGBG_FRAMEWORK_MASK_RENDER_FAIL"
    public static let frameworkResizeFail              = "BGBG_FRAMEWORK_RESIZE_FAIL"
    public static let frameworkServerSocketFail        = "BGBG_FRAMEWORK_SERVER_SOCKET_FAIL"
    public static let frameworkServerBindFail          = "BGBG_FRAMEWORK_SERVER_BIND_FAIL"
    public static let frameworkServerListenFail        = "BGBG_FRAMEWORK_SERVER_LISTEN_FAIL"
    public static let frameworkVisionFail              = "BGBG_FRAMEWORK_VISION_FAIL"
    public static let frameworkVisionNoMask            = "BGBG_FRAMEWORK_VISION_NO_MASK"
    public static let frameworkInternalInvariant       = "BGBG_FRAMEWORK_INTERNAL_INVARIANT"
}
