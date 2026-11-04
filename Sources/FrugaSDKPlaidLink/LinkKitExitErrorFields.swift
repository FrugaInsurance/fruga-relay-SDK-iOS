#if canImport(LinkKit) && canImport(UIKit)
import LinkKit

struct LinkKitExitErrorFields {
  let code: ExitErrorCode
  let message: String
  let displayMessage: String?
}
#endif
