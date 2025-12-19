//  Created by Jonathan Nobels on 2025-12-18.
//

import AuthenticationServices

@MainActor
final class AuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {

    private var authSession: ASWebAuthenticationSession?

    func showAuth(authURL: String) {
        guard let url = URL(string: authURL) else { return }


        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { _, error in
            if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                logger.log("Auth failed \(error)")
            }
        }

        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = self

        self.authSession = session
        _ = session.start()
    }

    func cancel() {
        self.authSession?.cancel()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor(windowScene: UIApplication.shared.connectedScenes.first as! UIWindowScene)
    }

}
