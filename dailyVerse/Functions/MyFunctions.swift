//
//  MyFunctions.swift
//  dailyVerse
//
//  Created by 庫倪 on 2018/1/13.
//  Copyright © 2018年 庫倪. All rights reserved.
//

import Foundation
import Alamofire

enum api {
    static func request(
        URL: String,
        Parameters: Parameters?,
        success: @escaping (_ dataRes: Any) -> (),
        failure: @escaping (_ dataRes: Any) -> ()
    ) {
        Alamofire.request(
            URL,
            parameters: Parameters
            )
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    success(value)
                case .failure(let error):
                    // 發送錯誤信息到開發者
                    // https://tgbot.lbyczf.com/sendMessage/9qvmshonjxf5csk5
 
                    // Add URL parameters
                    let urlParams = [
                        "text":"dailyVerse:\(error)",
                    ]
                    
                    // Fetch Request
                    Alamofire.request("https://tgbot.lbyczf.com/sendMessage/9qvmshonjxf5csk5", method: .get, parameters: urlParams)
                    failure(error)
                }
        }
    }
}


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
