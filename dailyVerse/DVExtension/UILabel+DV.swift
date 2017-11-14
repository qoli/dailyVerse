//
//  UILabel+DV.swift
//  dailyVerse
//
//  Created by itamaker on 2017/11/14.
//  Copyright © 2017年 庫倪. All rights reserved.
//

import UIKit

/*
 setLineSpacing 設定行高 / lineHeightMultiple / 字距
 */
extension UILabel {
    
    func typesetting(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0, characterSpacing: CGFloat = 0.0) {
        
        guard let labelText = self.text else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        
        let attributedString: NSMutableAttributedString
        if let labelattributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelattributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        
        // 處理字距
        attributedString.addAttribute(NSAttributedStringKey.kern, value: characterSpacing, range: NSRange(location: 0, length: attributedString.length - 1))
        
        // 處理行高
        attributedString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
}

