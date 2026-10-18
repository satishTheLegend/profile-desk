import Foundation

/// OS authentication callbacks have a separate epoch from selection ownership.
struct NativeLockState {
    struct Ticket { fileprivate let generation: UInt64; fileprivate let wasLocked: Bool }
    private(set) var locked: Bool
    private var generation: UInt64 = 0
    init(locked: Bool = true) { self.locked = locked }
    mutating func lock() { generation &+= 1; locked = true }
    mutating func invalidateAuthentication() { generation &+= 1 }
    func beginAuthentication() -> Ticket { Ticket(generation:generation,wasLocked:locked) }
    mutating func finishAuthentication(_ ticket: Ticket, success: Bool, foreground: Bool) -> Bool {
        guard ticket.generation == generation else { return false }
        generation &+= 1
        guard foreground else { return false }
        locked = success ? false : ticket.wasLocked
        return success
    }
}
