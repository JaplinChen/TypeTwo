import UIKit

class KeyboardViewController: UIInputViewController {

    // MARK: - UI

    private let containerView  = UIView()
    private let inputField     = UITextView()
    private let pasteButton    = UIButton(type: .system)
    private let translateButton = UIButton(type: .system)
    private let resultLabel    = UILabel()
    private let insertButton   = UIButton(type: .system)
    private let copyButton     = UIButton(type: .system)
    private let clearButton    = UIButton(type: .system)
    private let switchButton   = UIButton(type: .system)
    private let statusLabel    = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var currentResult: String?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        autoPasteIfClipboardChanged()
    }

    // MARK: - Layout

    private func buildUI() {
        view.backgroundColor = .systemGroupedBackground

        // Switch keyboard button (bottom-left, standard iOS convention)
        switchButton.setTitle("🌐", for: .normal)
        switchButton.addTarget(self, action: #selector(handleSwitchKeyboard), for: .touchUpInside)

        // Input area
        inputField.layer.cornerRadius = 8
        inputField.layer.borderWidth = 1
        inputField.layer.borderColor = UIColor.separator.cgColor
        inputField.backgroundColor = .secondarySystemGroupedBackground
        inputField.font = .systemFont(ofSize: 15)
        inputField.isScrollEnabled = true
        inputField.text = ""
        inputField.textColor = .label

        // Placeholder via status label inside input (overlay)
        let placeholder = UILabel()
        placeholder.text = "貼上或輸入要翻譯的文字..."
        placeholder.font = .systemFont(ofSize: 15)
        placeholder.textColor = .placeholderText
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        inputField.addSubview(placeholder)
        NSLayoutConstraint.activate([
            placeholder.topAnchor.constraint(equalTo: inputField.topAnchor, constant: 8),
            placeholder.leadingAnchor.constraint(equalTo: inputField.leadingAnchor, constant: 5),
        ])
        NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification,
                                               object: inputField, queue: .main) { [weak placeholder] _ in
            placeholder?.isHidden = !(self.inputField.text?.isEmpty ?? true)
        }

        // Paste button
        pasteButton.setTitle("貼上剪貼簿", for: .normal)
        pasteButton.addTarget(self, action: #selector(handlePaste), for: .touchUpInside)

        // Translate button
        translateButton.setTitle("翻譯", for: .normal)
        translateButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        translateButton.backgroundColor = .systemBlue
        translateButton.setTitleColor(.white, for: .normal)
        translateButton.layer.cornerRadius = 8
        translateButton.addTarget(self, action: #selector(handleTranslate), for: .touchUpInside)

        // Activity indicator
        activityIndicator.hidesWhenStopped = true

        // Result area
        resultLabel.numberOfLines = 0
        resultLabel.font = .systemFont(ofSize: 14)
        resultLabel.textColor = .label
        resultLabel.backgroundColor = .secondarySystemGroupedBackground
        resultLabel.layer.cornerRadius = 8
        resultLabel.layer.masksToBounds = true
        resultLabel.text = ""
        resultLabel.isHidden = true

        // Status label (errors)
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .systemRed
        statusLabel.numberOfLines = 2
        statusLabel.isHidden = true

        // Action buttons
        insertButton.setTitle("插入", for: .normal)
        insertButton.backgroundColor = .systemGreen
        insertButton.setTitleColor(.white, for: .normal)
        insertButton.layer.cornerRadius = 8
        insertButton.isHidden = true
        insertButton.addTarget(self, action: #selector(handleInsert), for: .touchUpInside)

        copyButton.setTitle("複製", for: .normal)
        copyButton.backgroundColor = .systemOrange
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.layer.cornerRadius = 8
        copyButton.isHidden = true
        copyButton.addTarget(self, action: #selector(handleCopy), for: .touchUpInside)

        clearButton.setTitle("清除", for: .normal)
        clearButton.setTitleColor(.systemRed, for: .normal)
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(handleClear), for: .touchUpInside)

        // Build stack
        let inputRow = makeHStack([pasteButton, UIView(), activityIndicator, translateButton],
                                   spacing: 8)
        let actionRow = makeHStack([insertButton, copyButton, UIView(), clearButton],
                                    spacing: 8)

        let stack = UIStackView(arrangedSubviews: [
            makeSwitchRow(),
            inputField,
            inputRow,
            statusLabel,
            resultLabel,
            actionRow,
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8),
            inputField.heightAnchor.constraint(equalToConstant: 72),
            translateButton.widthAnchor.constraint(equalToConstant: 64),
            insertButton.widthAnchor.constraint(equalToConstant: 64),
            copyButton.widthAnchor.constraint(equalToConstant: 64),
        ])
    }

    private func makeSwitchRow() -> UIView {
        let label = UILabel()
        label.text = "TypeTwo"
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return makeHStack([switchButton, label, UIView()], spacing: 4)
    }

    private func makeHStack(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal
        s.spacing = spacing
        s.alignment = .center
        return s
    }

    // MARK: - Actions

    @objc private func handleSwitchKeyboard() {
        advanceToNextInputMode()
    }

    @objc private func handlePaste() {
        if let str = UIPasteboard.general.string, !str.isEmpty {
            inputField.text = str
            NotificationCenter.default.post(name: UITextView.textDidChangeNotification,
                                            object: inputField)
        }
    }

    @objc private func handleTranslate() {
        let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }

        guard let config = ConfigReader.load() else {
            showStatus("請先開啟 TypeTwo App 完成翻譯引擎設定。")
            return
        }

        setTranslating(true)
        hideResult()

        Task {
            do {
                let result = try await TranslationClient.translate(text: text, config: config)
                await MainActor.run { self.showResult(result) }
            } catch {
                await MainActor.run { self.showStatus(error.localizedDescription) }
            }
            await MainActor.run { self.setTranslating(false) }
        }
    }

    @objc private func handleInsert() {
        guard let result = currentResult else { return }
        textDocumentProxy.insertText(result)
    }

    @objc private func handleCopy() {
        guard let result = currentResult else { return }
        UIPasteboard.general.string = result
        copyButton.setTitle("已複製", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.copyButton.setTitle("複製", for: .normal)
        }
    }

    @objc private func handleClear() {
        inputField.text = ""
        hideResult()
        NotificationCenter.default.post(name: UITextView.textDidChangeNotification,
                                        object: inputField)
    }

    // MARK: - State helpers

    private func setTranslating(_ active: Bool) {
        translateButton.isEnabled = !active
        active ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }

    private func showResult(_ text: String) {
        currentResult = text
        resultLabel.text = "  \(text)  "
        resultLabel.isHidden = false
        statusLabel.isHidden = true
        insertButton.isHidden = false
        copyButton.isHidden = false
        clearButton.isHidden = false
    }

    private func hideResult() {
        currentResult = nil
        resultLabel.isHidden = true
        insertButton.isHidden = true
        copyButton.isHidden = true
        clearButton.isHidden = true
        statusLabel.isHidden = true
    }

    private func showStatus(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
    }

    // MARK: - Auto-paste

    private var lastPasteboardCount = UIPasteboard.general.changeCount

    private func autoPasteIfClipboardChanged() {
        let current = UIPasteboard.general.changeCount
        guard current != lastPasteboardCount,
              let str = UIPasteboard.general.string, !str.isEmpty else { return }
        lastPasteboardCount = current
        inputField.text = str
        NotificationCenter.default.post(name: UITextView.textDidChangeNotification,
                                        object: inputField)
    }
}
