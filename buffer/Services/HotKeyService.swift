import AppKit
import Carbon.HIToolbox

final class HotKeyService {
    static let shared = HotKeyService()
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    var onActivate: (() -> Void)?

    private init() {}

    func register() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4255_4646), id: 1) // "BUFF"

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                service.onActivate?()
            }
            return noErr
        }, 1, &eventType, selfPtr, &eventHandler)

        // Option + P (keycode 35 = P)
        RegisterEventHotKey(UInt32(kVK_ANSI_P), UInt32(optionKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
