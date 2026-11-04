#if canImport(LinkKit) && canImport(UIKit)
import FrugaSDK
import LinkKit

enum LinkKitOutcomeMapping {
  static func errorTypeAndCode(_ code: ExitErrorCode) -> (type: String, code: String) {
    switch code {
    case let .apiError(inner): ("API_ERROR", inner.description)
    case let .authError(inner): ("AUTH_ERROR", inner.description)
    case let .assetReportError(inner): ("ASSET_REPORT_ERROR", inner.description)
    case let .internal(raw): ("INTERNAL", raw)
    case let .institutionError(inner): ("INSTITUTION_ERROR", inner.description)
    case let .itemError(inner): ("ITEM_ERROR", inner.description)
    case let .invalidInput(inner): ("INVALID_INPUT", inner.description)
    case let .invalidRequest(inner): ("INVALID_REQUEST", inner.description)
    case let .rateLimitExceeded(inner): ("RATE_LIMIT_EXCEEDED", inner.description)
    case let .unknown(type, raw): (type, raw)
    @unknown default: (code.description, "UNKNOWN")
    }
  }

  static func exitStatus(_ status: ExitStatus) -> String {
    status.description
  }

  static func success(
    publicToken: String,
    linkSessionId: String,
    institution: (id: String, name: String)?,
    accountCount: Int
  ) -> _FrugaPlaidLinkOutcome {
    .success(
      _FrugaPlaidLinkSuccess(
        publicToken: publicToken,
        linkSessionId: linkSessionId,
        institutionId: institution?.id,
        institutionName: institution?.name,
        accountCount: accountCount
      )
    )
  }

  static func exit(
    linkSessionId: String?,
    plaidRequestId: String?,
    exitStatus: ExitStatus?,
    error: LinkKitExitErrorFields?
  ) -> _FrugaPlaidLinkOutcome {
    .exit(
      _FrugaPlaidLinkExit(
        linkSessionId: linkSessionId,
        plaidRequestId: plaidRequestId,
        exitStatus: exitStatus.map(Self.exitStatus),
        error: error.map { fields in
          let mapped = errorTypeAndCode(fields.code)
          return _FrugaPlaidLinkError(
            type: mapped.type,
            code: mapped.code,
            message: fields.message,
            displayMessage: fields.displayMessage
          )
        }
      )
    )
  }
}
#endif
