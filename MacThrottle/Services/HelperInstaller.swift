import Foundation

enum HelperInstaller {
    static let monitorScript = """
        #!/bin/bash
        OUTPUT_FILE="/tmp/mac-throttle-thermal-state"

        while true; do
            THERMAL_OUTPUT=$(powermetrics -s thermal -n 1 -i 1 2>/dev/null | grep -i "Current pressure level")

            if echo "$THERMAL_OUTPUT" | grep -qi "sleeping"; then
                PRESSURE="sleeping"
            elif echo "$THERMAL_OUTPUT" | grep -qi "trapping"; then
                PRESSURE="trapping"
            elif echo "$THERMAL_OUTPUT" | grep -qi "heavy"; then
                PRESSURE="heavy"
            elif echo "$THERMAL_OUTPUT" | grep -qi "moderate"; then
                PRESSURE="moderate"
            elif echo "$THERMAL_OUTPUT" | grep -qi "nominal"; then
                PRESSURE="nominal"
            else
                PRESSURE="unknown"
            fi

            echo "{\\"pressure\\":\\"$PRESSURE\\",\\"timestamp\\":$(date +%s)}" > "$OUTPUT_FILE"
            chmod 644 "$OUTPUT_FILE"
            sleep 10
        done
        """

    static let launchDaemonPlist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.macthrottle.thermal-monitor</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/local/bin/mac-throttle-thermal-monitor</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
        </dict>
        </plist>
        """

    static let daemonPlistPath = "/Library/LaunchDaemons/com.macthrottle.thermal-monitor.plist"
    static let installedScriptPath = "/usr/local/bin/mac-throttle-thermal-monitor"

    static func install(update: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        let scriptPath = "/tmp/mac-throttle-thermal-monitor.sh"
        let plistPath = "/tmp/com.macthrottle.thermal-monitor.plist"

        do {
            try monitorScript.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try launchDaemonPlist.write(toFile: plistPath, atomically: true, encoding: .utf8)
        } catch {
            completion(.failure(error))
            return
        }

        let unloadCommand = update ? "launchctl unload \(daemonPlistPath) 2>/dev/null; " : ""

        let installCommands = """
            \(unloadCommand)cp '\(scriptPath)' \(installedScriptPath) && \
            chmod 755 \(installedScriptPath) && \
            cp '\(plistPath)' \(daemonPlistPath) && \
            chmod 644 \(daemonPlistPath) && \
            chown root:wheel \(daemonPlistPath) && \
            launchctl load \(daemonPlistPath)
            """

        let appleScript = """
            do shell script "\(installCommands)" with administrator privileges
            """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                let message = error[NSAppleScript.errorMessage] as? String ?? "Install failed"
                completion(.failure(HelperInstallerError.scriptFailed(message)))
            } else {
                let message = update ? "Helper updated!" : "Helper installed!"
                completion(.success(message))
            }
        }
    }

    static func uninstall(completion: @escaping (Result<String, Error>) -> Void) {
        let uninstallCommands = """
            launchctl unload \(daemonPlistPath) 2>/dev/null; \
            rm -f \(daemonPlistPath) \
            \(installedScriptPath) \
            /tmp/mac-throttle-thermal-state
            """

        let appleScript = """
            do shell script "\(uninstallCommands)" with administrator privileges
            """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                let message = error[NSAppleScript.errorMessage] as? String ?? "Uninstall failed"
                completion(.failure(HelperInstallerError.scriptFailed(message)))
            } else {
                completion(.success("Helper uninstalled"))
            }
        }
    }

    static func needsUpdate() -> Bool {
        guard let installed = try? String(contentsOfFile: installedScriptPath, encoding: .utf8) else {
            return false
        }
        let installedTrimmed = installed.trimmingCharacters(in: .whitespacesAndNewlines)
        let expectedTrimmed = monitorScript.trimmingCharacters(in: .whitespacesAndNewlines)
        return installedTrimmed != expectedTrimmed
    }
}

enum HelperInstallerError: LocalizedError {
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .scriptFailed(let message):
            return message
        }
    }
}
