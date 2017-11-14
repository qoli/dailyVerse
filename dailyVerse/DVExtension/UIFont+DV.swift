//
//  UIFont+DV.swift
//  dailyVerse
//
//  Created by itamaker on 2017/11/14.
//  Copyright © 2017年 庫倪. All rights reserved.
//

import UIKit

/*
 文字樣式
 */
extension UIFont {
    
    @nonobjc class var dlyMainTextStyle: UIFont {
        return UIFont(name: "PingFangTC-Light", size: 16.0)!
    }
    
    @nonobjc class var dlyTodayTextStyle: UIFont {
        return UIFont(name: "PingFangTC-Semibold", size: 10.0)!
    }
    
    @nonobjc class var dlyDateTextStyle: UIFont {
        return UIFont(name: "PingFangTC-Regular", size: 10.0)!
    }
}
