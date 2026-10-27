//
//  GkashPaymentIOSApp.swift
//  GkashPaymentIOS
//
//  Created by Gkash on 07/09/2022.
//

import SwiftUI
import os

@main
struct GkashPaymentIOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        mirrorPrintToUnifiedLog()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            print("scenePhase: \(phase)")
        }
    }
}

#if DEBUG
// Kept for the life of the app, closing its read end would kill the app with SIGPIPE on the next print
private let stdoutPipe = Pipe()

// print() on a device run can sit in the stdout buffer and is lost if the app is killed,
// so forward each line to the unified log, which reaches Xcode's console as it happens
private func mirrorPrintToUnifiedLog() {
    setvbuf(stdout, nil, _IOLBF, 0)
    dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    let logger = Logger(subsystem: "com.gkash.GkashPaymentIOS", category: "print")
    let buffer = LineBuffer()
    stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
        buffer.data.append(handle.availableData)
        // A long line can arrive across several reads, so only log complete lines
        while let newline = buffer.data.firstIndex(of: 0x0A) {
            let line = String(decoding: buffer.data[buffer.data.startIndex..<newline], as: UTF8.self)
            buffer.data.removeSubrange(buffer.data.startIndex...newline)
            logger.notice("\(line, privacy: .public)")
        }
    }
}

private final class LineBuffer {
    var data = Data()
}
#endif
