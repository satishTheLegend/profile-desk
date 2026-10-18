import UIKit

/// Covers Flutter routes as well as the web host before the system captures a preview.
@MainActor
final class WindowPrivacyCover: UIView {
    override var canBecomeFirstResponder: Bool { true }
    var unlock: (() -> Void)?
    private let label = UILabel()
    private let button = UIButton(type: .system)
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        isOpaque = true
        autoresizingMask = [.flexibleWidth,.flexibleHeight]
        accessibilityViewIsModal = true
        label.text = "Profile Desk is locked"
        label.font = .preferredFont(forTextStyle:.title2)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        button.setTitle("Unlock",for:.normal)
        button.titleLabel?.font = .preferredFont(forTextStyle:.headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self,action:#selector(unlockTapped),for:.touchUpInside)
        let stack = UIStackView(arrangedSubviews:[label,button])
        stack.axis = .vertical; stack.spacing = 20; stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo:centerXAnchor), stack.centerYAnchor.constraint(equalTo:centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo:leadingAnchor,constant:32), stack.trailingAnchor.constraint(lessThanOrEqualTo:trailingAnchor,constant:-32),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant:48)
        ])
    }
    required init?(coder:NSCoder) { fatalError("Storyboard initialization is unsupported") }
    @objc private func unlockTapped() { unlock?() }
    func authenticationFailed() { label.text = "Still locked. Use your device passcode or retry after authentication becomes available." }
    func show(in window: UIWindow?, allowUnlock: Bool, authenticating: Bool) {
        guard let window else { return }
        // End input before covering. An opaque overlay alone does not resign
        // Flutter's text input or stop a hardware keyboard targeting it.
        window.endEditing(true)
        frame = window.bounds
        if superview !== window { removeFromSuperview(); window.addSubview(self) }
        window.bringSubviewToFront(self)
        label.isHidden = !allowUnlock
        button.isHidden = !allowUnlock
        button.isEnabled = !authenticating
        becomeFirstResponder()
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {}
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {}
}
