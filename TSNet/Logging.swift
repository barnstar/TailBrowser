//  Created by Jonathan Nobels on 2025-12-18.
//

import TailscaleKit

let logger = Logger()

struct Logger: TailscaleKit.LogSink {
    var logFileHandle: Int32?

    func log(_ message: String) {
        print("tsnet: \(message)")
    }
}
