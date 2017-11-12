//
//  ViewController.swift
//  dailyVerse
//
//  Created by 庫倪 on 2017/11/12.
//  Copyright © 2017年 庫倪. All rights reserved.
//

import UIKit

import SwiftDate
import Alamofire
import SwiftyJSON

import NotificationBannerSwift
import MMMaterialDesignSpinner
import DynamicBlurView
import Spring
import TouchVisualizer

// 狀態欄通知的背景顏色
class CustomBannerColors: BannerColorsProtocol {
    func color(for style: BannerStyle) -> UIColor {
        return UIColor.dlyCoralPink
    }

}

class ViewController: UIViewController, UITableViewDataSource, UITabBarDelegate {

    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var dayText: UILabel!
    @IBOutlet weak var mainText: UILabel!
    @IBOutlet weak var overlayerView: UIView!
    @IBOutlet weak var mainView: UIView!

    @IBOutlet weak var AboutUIView: UIView!
    @IBOutlet weak var aboutMainTextView: SpringView!
    @IBOutlet weak var aboutImage: SpringImageView!

    @IBOutlet weak var chapterView: UIView!
    @IBOutlet weak var chapterUITableView: UITableView!


    var spinnerView: MMMaterialDesignSpinner!
    var blurView: DynamicBlurView!

    var updateDataBool: Bool = false
    var updateTableBool: Bool = false

    var dailyVerse: String = ""
    var textChapterTitle: String = ""
    var textChapterNumber: Int = 0
    var verseArray = Dictionary<Int, String>()

    override func viewDidLoad() {
        super.viewDidLoad()

        print("> viewDidLoad")
        print("")

        //init_touch()

        UI_Before()
        init_spinner()
        init_today()
        init_verse()
        UI_After()

    }


    func init_touch() {
        var config = Configuration()
        config.color = UIColor.dlyBlack24
        Visualizer.start(config)
    }

    // 一些元件的預先設定
    func UI_Before() {
        self.overlayerView.backgroundColor = UIColor.dlyWhite0
        AboutUIView.backgroundColor = UIColor.dlyWhite0
        AboutUIView.isHidden = true

        chapterUITableView.separatorColor = UIColor.clear
        chapterUITableView.backgroundColor = UIColor.dlyPaleGrey
        
        chapterView.isHidden = true

    }

    // 一些數據載入好后的調整
    func UI_After() {
        dateText.typesetting(lineSpacing: 1, lineHeightMultiple: 1, characterSpacing: 1.5)

        chapterUITableView.estimatedRowHeight = 74
        chapterUITableView.rowHeight = UITableViewAutomaticDimension
    }

    // 重新處理全局變量
    func UI_updateData() {
        print("> UI_updateData")

        let matched = self.matches(for: "\\S*", in: dailyVerse)
        var r = matched
        r = r.filter { $0 != "" }
        print(r)

        textChapterTitle = String(r[0])
        textChapterNumber = Int(r[1])!

        self.updateDataBool = true
        self.chapterUITableView.reloadData()




    }

    // didReceiveMemoryWarning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning")
        // Dispose of any resources that can be recreated.
    }

    // Try Button
    @IBAction func tryButton(_ sender: UIButton) {

    }

    // 打開﹣關於界面
    @IBAction func openAbout(_ sender: UIButton) {

        aboutMainTextView.animation = "slideUp"
        aboutMainTextView.animate()
        aboutImage.animation = "fadeIn"
        aboutImage.animate()

        blurView = DynamicBlurView(frame: view.bounds)
        self.overlayerView.backgroundColor = UIColor.dlyWhite0
        overlayerView.isHidden = false
        UIView.animate(withDuration: 0.5) {
            self.blurView.blurRadius = 15
            self.overlayerView.backgroundColor = UIColor.dlyWhite50
        }
        blurView.tag = 101

        mainView.addSubview(blurView)
    }
    
    // 關閉﹣關於界面
    @IBAction func closeAbout(_ sender: UIButton) {
        UIView.animate(withDuration: 0.6) {
            self.blurView.blurRadius = 0
        }

        self.aboutMainTextView.animation = "fall"
        self.aboutMainTextView.animate()
        aboutImage.animation = "fadeOut"
        aboutImage.animate()

        setTimeout(0.7) {
            self.overlayerView.isHidden = true
            if let viewWithTag = self.view.viewWithTag(101) {
                viewWithTag.removeFromSuperview()
            }
        }

    }

    // 關閉﹣詳細章節界面
    @IBAction func closeChapterView(_ sender: UIButton) {

        chapterView.alpha = 1
        UIView.animate(withDuration: 0.3) {
            self.chapterView.alpha = 0
        }
        setTimeout(0.3) {
            self.chapterView.isHidden = true
        }
    }

    // 打開﹣詳細章節界面
    @IBAction func tapPress(_ sender: UITapGestureRecognizer) {
        print("> tapPress")
        
        if !updateTableBool {
            spinnerView.startAnimating()
            self.tableData()
        }
        
        chapterView.isHidden = false
        chapterView.alpha = 0.0
        UIView.animate(withDuration: 0.16) {
            self.chapterView.alpha = 1
        }
        


    }

    /*
     * 表格（詳細章節）
     */

    func tableData() {

        let parameters: Parameters = [
            "gb": "0",
            "chap": textChapterNumber,
            "chineses": "太"
        ]

        Alamofire.request("https://bible.fhl.net/json/qb.php", parameters: parameters).responseJSON { response in

            print("> 請求的 URL \(String(describing: response.request?.url))")

            switch response.result {

            case .success(let value):
                let json = JSON(value)

                for (_, subJson): (String, JSON) in json["record"] {
                    //  print("\(subJson["sec"]) - \(subJson["bible_text"])")
                    let k: Int = subJson["sec"].intValue
                    let b: String = subJson["bible_text"].string!
                    self.verseArray[k] = b
                }
                
                self.chapterUITableView.reloadData()
                self.spinnerView.stopAnimating()
                self.updateTableBool = true
                
                // print(self.verseArray)

            case .failure(let error):
                print("> 與 API 通信錯誤")
                print(error)
                self.UIStatusMessage(Message: "與 API 通信錯誤")
            }
        }
    }

    // 運算表格數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("> Table View...")

        if self.updateDataBool {
            print("VerseArray count: \(self.verseArray.count)")
            return self.verseArray.count + 1
        } else {
            return 2
        }


    }

    // 填充表格內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row == 0 {

            let ChapterTableCell = tableView.dequeueReusableCell(withIdentifier: "chapterCell") as! ChapterCell

            if !self.updateDataBool {
                ChapterTableCell.ChapterLaberTitle.text = "Loading..."
            } else {
                ChapterTableCell.ChapterLaberTitle.text = "\(textChapterTitle) · \(intIntoString(number: textChapterNumber))章"
            }

            ChapterTableCell.ChapterLaberTitle.typesetting(lineSpacing: 1, lineHeightMultiple: 1, characterSpacing: 2)
            ChapterTableCell.backgroundColor = UIColor.dlyPaleGrey
            return ChapterTableCell
        } else {

            if self.updateDataBool {

                let SectionTableCell = tableView.dequeueReusableCell(withIdentifier: "SectionLabelCell") as! SectionCell
                SectionTableCell.sectionLabel.text = self.verseArray[indexPath.row]
                SectionTableCell.SectionNumberLabel.text = String(indexPath.row)
                SectionTableCell.backgroundColor = UIColor.dlyPaleGrey
                SectionTableCell.sectionLabel.typesetting(lineSpacing: 1.5, lineHeightMultiple: 2, characterSpacing: 2)
                return SectionTableCell
            } else {
                
                let SectionTableCell = tableView.dequeueReusableCell(withIdentifier: "SectionLabelCell") as! SectionCell
                SectionTableCell.sectionLabel.text = "..."
                SectionTableCell.SectionNumberLabel.text = String(0)
                SectionTableCell.backgroundColor = UIColor.dlyPaleGrey
                SectionTableCell.sectionLabel.typesetting(lineSpacing: 1.5, lineHeightMultiple: 2, characterSpacing: 2)
                return SectionTableCell
            }


        }

    }


    // 長按﹣屏幕中央
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        print("> longPress")
        init_verse()
        updateTableBool = false
        updateDataBool = false
        self.UIStatusMessage(Message: "重新載入數據")
    }


    // 點擊﹣分享按鈕
    @IBAction func shareAction(_ sender: UIButton) {

        self.UIStatusMessage(Message: "正在開啟分享...")

        let shareText: String = dailyVerse
        let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: [])
        present(vc, animated: true)

    }

    // 初始化日期信息
    func init_today() {
        let date = DateInRegion()

        print(date)

        dayText.text = String(date.day)
        dateText.text = String("\(date.string(dateStyle: .long, timeStyle: .none)) · \(date.weekdayName)")
    }

    // 初始化金句
    func init_verse() {
        spinnerView.startAnimating()

        let t: UILabel! = self.mainText
        t.text = ""

        setTimeout(0.6) {
            Alamofire.request("https://www.taiwanbible.com/blog/dailyverse.jsp").responseString { response in
                if response.result.isSuccess {
                    var s: String! = response.result.value
                    s = s.replacingOccurrences(of: "\r", with: "")
                    s = s.replacingOccurrences(of: "\n", with: "")
                    s = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.dailyVerse = s
                    t.text = s
                    t.typesetting(lineSpacing: 1.5, lineHeightMultiple: 2, characterSpacing: 2)
                    t.textAlignment = .center
                    self.spinnerView.stopAnimating()
                    self.UI_updateData()

                } else {
                    // t.text = "Network problem"
                    self.UIStatusMessage(Message: "Network problem")
                }
            }
        }
    }

    // 初始化 spinner view
    func init_spinner() {
        spinnerView = MMMaterialDesignSpinner.init(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        spinnerView.center = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
        spinnerView.lineWidth = 3
        spinnerView.tintColor = UIColor.dlyDark

        self.view .addSubview(spinnerView)
    }

    // 顯示狀態欄的通知
    func UIStatusMessage(Message: String = "Message") {
        let banner = StatusBarNotificationBanner(title: Message, colors: CustomBannerColors())
        banner.show()
    }

    /**
     setTimeout()
     
     Shorthand method for create a delayed block to be execute on started Thread.
     
     This method returns ``Timer`` instance, so that user may execute the block
     within immediately or keep the reference for further cancelation by calling
     ``Timer.invalidate()``
     
     Example:
     let timer = setTimeout(0.3) {
     // do something
     }
     timer.invalidate()      // cancel it.
     */
    func setTimeout(_ delay: TimeInterval, block: @escaping () -> Void) -> Timer {
        return Timer.scheduledTimer(timeInterval: delay, target: BlockOperation(block: block), selector: #selector(Operation.main), userInfo: nil, repeats: false)
    }


    // 正則
    func matches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    // 數字轉中文
    func intIntoString(number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style(rawValue: UInt(CFNumberFormatterRoundingMode.roundHalfDown.rawValue))!
        let string: String = formatter.string(from: NSNumber(value: number))!
        return string
    }

}





/*
 App 顏色板
 */

extension UIColor {

    @nonobjc class var dlyCoralPink: UIColor {
        return UIColor(named: "coralPink")!
    }

    @nonobjc class var dlySoftBlue: UIColor {
        return UIColor(named: "softBlue")!
    }

    @nonobjc class var dlyBlack12: UIColor {
        return UIColor(named: "black12")!
    }

    @nonobjc class var dlyGunmetal: UIColor {
        return UIColor(named: "gunmetal")!
    }

    @nonobjc class var dlyGreyishBrown: UIColor {
        return UIColor(named: "greyishBrown")!
    }

    @nonobjc class var dlyDark: UIColor {
        return UIColor(named: "dark")!
    }

    @nonobjc class var dlyBlack24: UIColor {
        return UIColor(named: "black24")!
    }

    @nonobjc class var dlyWhite50: UIColor {
        return UIColor(named: "white50")!
    }

    @nonobjc class var dlyWhite: UIColor {
        return UIColor(named: "white")!
    }

    @nonobjc class var dlyWhite0: UIColor {
        return UIColor(named: "white0")!
    }

    @nonobjc class var dlyPaleGrey: UIColor {
        return UIColor(named: "paleGrey")!
    }
}

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

/*
 IB 追加陰影\圓角等樣式
 */

@IBDesignable
class DesignableView: UIView {
}

@IBDesignable
class DesignableButton: UIButton {
}

@IBDesignable
class DesignableLabel: UILabel {
}

extension UIView {

    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }

    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }

    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }

    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }

    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }

    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
}
