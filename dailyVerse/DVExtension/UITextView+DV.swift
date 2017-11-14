//
//  UITextView+DV.swift
//  dailyVerse
//
//  Created by itamaker on 2017/11/14.
//  Copyright © 2017年 庫倪. All rights reserved.
//

import UIKit

/*
 UI Text View 垂直居中
 */

extension UITextView {
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}
