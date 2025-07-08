//
//  TextViewCell.swift
//  Off Day
//
//  Created by Ci Zi on 2025/5/23.
//

import UIKit
import SnapKit

class TextViewCell: UITableViewCell {
    private var textView: PlaceholderTextView = {
        let textView = PlaceholderTextView()
        textView.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 11, bottom: 8, right: 11)

        return textView
    }()
    
    var textDidChanged: ((String) -> ())?
    
    override var tintColor: UIColor! {
        didSet {
            textView.tintColor = tintColor
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.bottom.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(0.0)
            make.height.greaterThanOrEqualTo(100.0)
        }
        textView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(text: String?, placeholder: String?) {
        textView.text = text
        textView.placeholder = placeholder
    }
    
    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder() && super.resignFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder() && super.becomeFirstResponder()
    }
}

extension TextViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textDidChanged?(textView.text ?? "")
    }
}

class PlaceholderTextView: UITextView {
    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            placeholderLabel.sizeToFit()
        }
    }
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .placeholderText
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override var tintColor: UIColor! {
        didSet {
            self.inputAccessoryView?.tintColor = tintColor
        }
    }
    
    override var text: String! {
        didSet {
            textDidChange()
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupViews()
        addDoneButtonOnKeyboard()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
    }
    
    private func setupViews() {
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: nil)
        
        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top).inset(8)
            make.leading.trailing.equalTo(self).inset(16)
            make.width.equalTo(self).offset(32)
        }
    }
    
    @objc
    private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    fileprivate func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: String(localized: "button.done"), style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        self.inputAccessoryView = doneToolbar
    }

    @objc
    fileprivate func doneButtonAction() {
        self.resignFirstResponder()
    }
}
