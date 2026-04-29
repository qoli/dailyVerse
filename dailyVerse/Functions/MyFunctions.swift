//
//  MyFunctions.swift
//  dailyVerse
//
//  Created by 庫倪 on 2018/1/13.
//  Copyright © 2018年 庫倪. All rights reserved.
//

import Foundation

func getCurrentLanguage() -> String {
    let preferredLang = Bundle.main.preferredLocalizations.first! as NSString
    print("OS Language: \(preferredLang)")
    
    switch String(describing: preferredLang) {
    case "en-US", "en-CN":
        return "en"//英文
    case "zh-Hans-US", "zh-Hans-CN", "zh-Hans":
        return "sc"//中文
    case "zh-TW", "zh-HK", "zh-Hant", "zh-Hant-CN":
        return "tc"//中文
    default:
        return "en"
    }
}
