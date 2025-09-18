//
//  TextInputCell.swift
//  Off Day
//
//  Created by zici on 2023/6/13.
//

import UIKit
import SnapKit

class TextInputCell: UITableViewCell {
    private var textField: UITextField = {
        let textView = UITextFieldWithDoneButton()
        
        return textView
    }()
    
    var textDidChanged: ((String) -> ())?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.top.bottom.equalTo(contentView)
            make.leading.trailing.equalTo(contentView).inset(20.0)
            make.height.greaterThanOrEqualTo(44.0)
        }
        textField.tintColor = AppColor.offDay
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(text: String?, placeholder: String?, allowEdit: Bool = true) {
        textField.text = text
        textField.placeholder = placeholder
        textField.isEnabled = allowEdit
        if !allowEdit {
            textField.textColor = .systemGray
        }
    }
    
    @objc
    func editingChanged() {
        DispatchQueue.main.async {
            self.textDidChanged?(self.textField.text ?? "")
        }
    }
    
    public var keyboardIsShowing: Bool {
        return textField.isEditing
    }
    
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
        return super.becomeFirstResponder()
    }
}

class UITextFieldWithDoneButton: UITextField {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addDoneButtonOnKeyboard()
    }

    fileprivate func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: String(localized: "button.done"), style: .done, target: self, action: #selector(self.doneButtonAction))
        done.tintColor = AppColor.offDay

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        self.inputAccessoryView = doneToolbar
    }

    @objc fileprivate func doneButtonAction() {
        self.resignFirstResponder()
    }
}

