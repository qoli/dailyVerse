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
        Alamofire.request("https://www.taiwanbible.com/blog/dailyverse.jsp").responseString { response in
            if response.result.isSuccess {
                var s: String! = response.result.value
                s = s.replacingOccurrences(of: "\r", with: "")
                s = s.replacingOccurrences(of: "\n", with: "")
                s = s.trimmingCharacters(in: .whitespacesAndNewlines)
                
                self.todayWidget.text = s
                
            }
        }
    }
    
}
