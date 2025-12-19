//  Created by Jonathan Nobels on 2025-12-16.
//

import Foundation
import SwiftData

@Model
final class Bookmark {
    var timestamp: Date
    var name: String
    var url: String

    init(timestamp: Date, name: String, url: String) {
        self.timestamp = timestamp
        self.name = name
        self.url = url
    }
}

final class HomePage {
    let key: String

    static var standard = HomePage(key: "default_homepage")

    init(key: String) {
        self.key = key
    }

    var url: String {
        get {
            UserDefaults.standard.string(forKey: "homepage") ?? "https://tailscale.com"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "homepage")

        }
    }

    var bookmark: Bookmark {
        Bookmark(timestamp: Date(), name: "Home Page", url: url)
    }
}
