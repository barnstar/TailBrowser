//  Created by Jonathan Nobels on 2025-12-18.
//


import Combine
import TailscaleKit
import SwiftUI

final class StatusViewModel:  ObservableObject {
    @Published var statusText: String = ""
    @Published var statusIconName: String = "questionmark.circle"
    @Published var needsAuth: Bool = false
    @Published var running: Bool = false
    @Published var tsnetState: Ipn.State?

    var authURL: String? = nil
    var observers: [AnyCancellable] = []
    var requestedInteractiveLogin = false

    let manager: TSNetManager

    let authManager = AuthManager()

    init(manager: TSNetManager) {
        self.manager = manager
        observeAuthURL()
    }

    private func observeAuthURL() {
        manager.model.$state
            .removeDuplicates()
            .combineLatest(manager.model.$browseToURL)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state, browseToURL in
                guard let self else { return }

                if state == .NeedsLogin {
                    authURL = browseToURL
                    needsAuth = true
                    if requestedInteractiveLogin, let browseToURL {
                        requestedInteractiveLogin = false
                        authManager.showAuth(authURL: browseToURL)
                    }
                } else {
                    requestedInteractiveLogin = false
                    needsAuth = false
                    authURL = nil
                    authManager.cancel()
                }

                running = state == .Running
                tsnetState = state
            }
            .store(in: &observers)

        manager.model.$tailnetName
            .combineLatest(manager.model.$state)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name, state in
                guard let self else { return }
                updateStatusText(state, name: name)
            }.store(in: &observers)
    }

    private func updateStatusText(_ state: Ipn.State?, name: String?) {
        let mapping = mapState(state, name)
        statusText = mapping.text
        statusIconName = mapping.icon
    }

    private func mapState(_ state: Ipn.State?, _ name: String?) -> (text: String, icon: String) {
        switch state {
        case .some(.Running):
            return ("Connected\n\(name ?? "--")", "checkmark.circle.fill")
        case .some(.NeedsLogin):
            return ("Login Required", "person.crop.circle.badge.exclamationmark")
        case .some(.Stopped):
            return ("Stopped", "stop.circle.fill")
        case .some(.Starting):
            return ("Starting…", "hourglass.circle.fill")
        case .some(.NoState):
            fallthrough
        case .none:
            return ("Connecting…", "arrow.trianglehead.2.clockwise.rotate.90.icloud")
        default:
            // Fallback for any other states not explicitly handled
            return ("Working…", "ellipsis.circle")
        }
    }

    func showAuth() {
        if let authURL {
            authManager.showAuth(authURL: authURL)
        } else {
            requestedInteractiveLogin = true
            Task {
                try await manager.localAPIClient?.startLoginInteractive()
            }
        }
    }

    func logout() {
        Task {
            let currentUser = try? await manager.localAPIClient?.currentProfile()
            if let currentUser {
                try? await manager.localAPIClient?.deleteProfile(profileID: currentUser.id)
            }
        }
    }
}
