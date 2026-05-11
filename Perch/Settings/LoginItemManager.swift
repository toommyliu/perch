import ServiceManagement

protocol LoginItemManaging {
    var isEnabled: Bool { get }

    func setEnabled(_ isEnabled: Bool) throws
}

struct LoginItemManager: LoginItemManaging {
    var isEnabled: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }

    func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            guard !self.isEnabled else {
                return
            }

            try SMAppService.mainApp.register()
        } else {
            switch SMAppService.mainApp.status {
            case .notRegistered, .notFound:
                return
            case .enabled, .requiresApproval:
                try SMAppService.mainApp.unregister()
            @unknown default:
                return
            }
        }
    }
}
