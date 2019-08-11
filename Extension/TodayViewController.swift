//
//  TodayViewController.swift
//  Extension
//
//  Created by 庫倪 on 2017/11/12.
//  Copyright © 2017年 庫倪. All rights reserved.
//

import UIKit
import NotificationCenter
import Alamofire

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var todayWidget: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        init_verse()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func init_verse() {
        Alamofire.request("https://bible.5mlstudio.com").responseString { response in
            if response.result.isSuccess {
                var s: String! = response.result.value
                s = s.replacingOccurrences(of: "\r", with: "")
                s = s.replacingOccurrences(of: "\n", with: "")
                s = s.trimmingCharacters(in: .whitespacesAndNewlines)
                
                self.todayWidget.text = s
                self.todayWidget.typesetting(lineSpacing: 1, lineHeightMultiple: 1, characterSpacing: 1.2)
            } else {
                let urlParams = [
                    "text":"[ERROR]\n\r- dailyVerse \n\r- https://bible.5mlstudio.com \n\r- \(response.result.error?.localizedDescription ?? "Error on Today Extension")  \n\r- Value: \(response.result.value)"
                ]
                Alamofire.request("https://tgbot.lbyczf.com/sendMessage/9qvmshonjxf5csk5", method: .get, parameters: urlParams)
            }
        }
    }
    
}

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
        attributedString.addAttribute(NSAttributedString.Key.kern, value: characterSpacing, range: NSRange(location: 0, length: attributedString.length - 1))
        
        // 處理行高
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
}

