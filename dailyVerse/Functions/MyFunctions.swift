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


