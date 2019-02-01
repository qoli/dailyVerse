//dailyVerse
//
//Copyright (c) 2017 Qoli Wong - https://github.com/qoli/dailyVerse
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import UIKit
import AVFoundation

import Alamofire
import Spring
import SwiftDate
import SwiftyJSON
import DynamicBlurView
import TouchVisualizer
import NotificationBannerSwift
import MMMaterialDesignSpinner



// 狀態欄通知的背景顏色
class CustomBannerColors: BannerColorsProtocol {
    func color(for style: BannerStyle) -> UIColor {
        return UIColor.dlyCoralPink
    }
}

// Main View
class ViewController: UIViewController, UITableViewDataSource, UITabBarDelegate {

    @IBOutlet weak var dateText: UILabel!
    @IBOutlet weak var dayText: UILabel!
    @IBOutlet weak var mainText: UILabel!
    @IBOutlet weak var overlayerView: UIView!
    @IBOutlet weak var mainView: UIView!

    @IBOutlet weak var AboutUIView: UIView!
    @IBOutlet weak var aboutMainTextView: SpringView!
    @IBOutlet weak var aboutVersion: UILabel!
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

    var traditionalChinese: Bool = true

    var longPressNumber: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        print("> viewDidLoad")
        print("")

        UI_Before()
        init_spinner()
        init_today()
        init_verse()
        UI_After()

//        play(url: "http://media.fhl.net/Cantonese1/1/1_024.mp3")

    }

    @IBAction func longPressTouch(_ sender: UILongPressGestureRecognizer) {
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

        // 刷新版本號
        // Get the app's main bundle
        let mainBundle = Bundle.main
        
        let appVersion = mainBundle.infoDictionary!["CFBundleShortVersionString"] as? String
        let build = mainBundle.infoDictionary!["CFBundleVersion"] as? String
//        print(appVersion)
        
        aboutVersion.text =  "version \(appVersion ?? "0") (Build \(build ?? "0"))"
        
        if Locale.preferredLanguages[0] == "zh-Hans-CN" {
            traditionalChinese = false
        }

    }

    // 一些數據載入好后的調整
    func UI_After() {
        dateText.typesetting(lineSpacing: 1, lineHeightMultiple: 1, characterSpacing: 1.5)

        chapterUITableView.estimatedRowHeight = 120
        chapterUITableView.rowHeight = UITableViewAutomaticDimension
    }

    // 重新處理全局變量
    func UI_updateData() {
        print("> UI_updateData()")

        let matched = self.matches(for: "\\S*", in: dailyVerse.replacingOccurrences(of: ":", with: " "))
        var r = matched
        r = r.filter { $0 != "" }
        print(r)

        print(r[1])
        
        textChapterTitle = String(r[0]) //重新賦值章節標題
        textChapterNumber = Int(r[1]) ?? 99 //重新賦值第 N 章節
        
        if textChapterNumber == 99 {
            self.UIStatusMessage(Message: "尋找章節失敗")
            textChapterNumber = 1
        }

        self.updateDataBool = true
        self.chapterUITableView.reloadData()

    }

    // didReceiveMemoryWarning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("didReceiveMemoryWarning")
    }

    // Try Button
    @IBAction func tryButton(_ sender: UIButton) {

    }

    // 打開﹣關於界面
    @IBAction func openAbout(_ sender: UIButton) {

        self.AboutUIView.alpha = 1
        aboutMainTextView.animation = "slideUp"
        aboutMainTextView.animate()
        aboutImage.animation = "fadeIn"
        aboutImage.animate()


        blurView = DynamicBlurView(frame: view.bounds)
        self.overlayerView.backgroundColor = UIColor.dlyWhite0

        UIView.animate(withDuration: 0.5) {
            self.blurView.blurRadius = 15
            self.overlayerView.backgroundColor = UIColor.dlyWhite50
        }

        blurView.tag = 101
        self.overlayerView.isHidden = false
        self.mainView.addSubview(self.blurView)
    }

    // 關閉﹣關於界面
    @IBAction func closeAbout(_ sender: UIButton) {
        UIView.animate(withDuration: 0.6) {
            self.blurView.blurRadius = 0
            self.AboutUIView.alpha = 0
        }

        self.aboutMainTextView.animation = "fall"
        self.aboutMainTextView.animate()
        aboutImage.animation = "fadeOut"
        aboutImage.animate()

        let _ = setTimeout(0.6) {
            self.overlayerView.isHidden = true
            if let viewWithTag = self.view.viewWithTag(101) {
                viewWithTag.removeFromSuperview()
            }
        }

    }
    @IBOutlet var AudioButton: UIButton!

    var player: AVPlayer?
    var isPlaying: Bool = false
    var isReadlyPlay: Bool = false
    var apiDataAudio: JSON = []

    func playAudio() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
    }

    func getAudioURL() {

        let sortName = self.traditionalChinese(longName: textChapterTitle)
        let parameters: Parameters = [
            "link": "https://bible.fhl.net/new/read.php",
            "chap": textChapterNumber,
            "chineses": sortName
        ]

        api.request(
            URL: "https://bible.5mlstudio.com/voice.php",
            Parameters: parameters,
            success: { value in
                let json = JSON(value)
                self.readlyForPlay(url: json["url"].string!)
                self.apiDataAudio = json
            },
            failure: { error in
                print(error)
                self.UIStatusMessage(Message: (error as AnyObject).localizedDescription)
            }
        )
    }


    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        if keyPath == "rate" {
            if player?.rate == 1 {
                print("Playing")
                isPlaying = true
                AudioButton.setTitle("播放中", for: .normal)
            } else {
                print("Stop")
                isPlaying = false
                AudioButton.setTitle("朗讀", for: .normal)
            }
        }
        
        if keyPath == #keyPath(AVPlayer.currentItem.status) {
            let newStatus: AVPlayerItemStatus
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
            } else {
                newStatus = .unknown
            }
            if newStatus == .failed {
                NSLog("Error: \(String(describing: self.player?.currentItem?.error?.localizedDescription)), error: \(String(describing: self.player?.currentItem?.error))")
                print("failed")
            }
        }
    }

    // Getting error from Notification payload
    func newErrorLogEntry(_ notification: Notification) {
        guard let object = notification.object, let playerItem = object as? AVPlayerItem else {
            return
        }
        guard let errorLog: AVPlayerItemErrorLog = playerItem.errorLog() else {
            return
        }
        NSLog("Error: \(errorLog)")
    }

    func failedToPlayToEndTime(_ notification: Notification) {
        print("failedToPlayToEndTime")
    }

    func readlyForPlay(url: String) {
        print("readlyForPlay: \(url)")
        self.isReadlyPlay = true

        guard let url = URL(string: url) else {
            print("Invalid URL")
            self.UIStatusMessage(Message: "Invalid URL")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            self.player = AVPlayer(playerItem: item)
            self.player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions(rawValue: NSKeyValueObservingOptions.new.rawValue | NSKeyValueObservingOptions.old.rawValue), context: nil)
            self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new, .initial], context: nil)
            // Watch notifications
            let center = NotificationCenter.default
            center.addObserver(self, selector: Selector(("newErrorLogEntry:")), name: .AVPlayerItemNewErrorLogEntry, object: player?.currentItem)
            center.addObserver(self, selector: Selector(("failedToPlayToEndTime:")), name: .AVPlayerItemFailedToPlayToEndTime, object: player?.currentItem)

            // play
            self.player?.pause()
        } catch {
            print(error)
            self.UIStatusMessage(Message: (error as AnyObject).localizedDescription)
        }
    }

    func switchAudio() {
        if !isReadlyPlay {
            self.getAudioURL()
        } else {
            self.playAudio()
        }
    }

    @IBAction func audioTap(_ sender: Any) {
        print("> audioTap()")
        self.switchAudio()
    }

    @IBAction func audioLongPress(_ sender: Any) {

        if longPressNumber == 0 {
            print("> audioLongPress()")

            // 1
            let optionMenu = UIAlertController(title: nil, message: "選擇版本", preferredStyle: .actionSheet)

            for (index, subJson): (String, JSON) in apiDataAudio["versionName"] {
                optionMenu.addAction(UIAlertAction(title: subJson.stringValue, style: .default, handler: { action in
                    let arr: Array = self.apiDataAudio["audioURL"].arrayValue
                    self.readlyForPlay(url: arr[Int(index)!].stringValue)
                    
                    let _ = self.setTimeout(0.8) {
                        self.switchAudio()
                    }
                }))

            }

            // 4
            optionMenu.addAction(UIAlertAction(title: "關閉", style: .cancel))

            // 5
            self.present(optionMenu, animated: true, completion: nil)

            let _ = setTimeout(4.0) {
                self.longPressNumber = 0
            }
        }

        longPressNumber = longPressNumber + 1
    }

    // 關閉﹣詳細章節界面
    @IBAction func closeChapterView(_ sender: UIButton) {

        chapterView.alpha = 1
        UIView.animate(withDuration: 0.3) {
            self.chapterView.alpha = 0
        }
        let _ = setTimeout(0.3) {
            self.chapterView.isHidden = true
        }
    }

    // 打開﹣詳細章節界面
    @IBAction func tapPress(_ sender: UITapGestureRecognizer) {
        print("> tapPress()")

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

    // 表格
    // （載入詳細章節）

    func tableData() {

        let sortName = self.traditionalChinese(longName: textChapterTitle)

        print("中文縮寫：\(sortName)，traditionalChinese（Bool）：\(traditionalChinese)")

        var gb: String = "0"

        if traditionalChinese {
            gb = "0"
        } else {
            gb = "1"
        }

        let parameters: Parameters = [
            "link": "https://bible.fhl.net/json/qb.php",
            "gb": gb,
            "chap": textChapterNumber,
            "chineses": sortName
        ]
        
        // 重置播放狀態
        self.isReadlyPlay = false
        self.AudioButton.setTitle("...", for: .normal)
        self.getAudioURL()

        api.request(
            URL: "https://bible.5mlstudio.com/bible.php",
            Parameters: parameters,
            success: { value in
                // Table Data
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
            },
            failure: { error in
                print(error)
                self.UIStatusMessage(Message: (error as AnyObject).localizedDescription)
            }
        )

    }

    // 運算表格數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("> Table View...")

        if self.updateDataBool {
            print("VerseArray count: \(self.verseArray.count)")
            return self.verseArray.count + 2
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

        } else if indexPath.row == self.verseArray.count + 1 {

            let BlankTableCell = tableView.dequeueReusableCell(withIdentifier: "chapterCell") as! ChapterCell
            BlankTableCell.ChapterLaberTitle.text = ""
            BlankTableCell.backgroundColor = UIColor.dlyPaleGrey
            return BlankTableCell

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
//        print("> longPress: \(longPressNumber)")

        if longPressNumber == 0 {
            init_verse()
            updateTableBool = false
            updateDataBool = false
            self.UIStatusMessage(Message: "重新載入數據")

            let _ = setTimeout(4.0) {
                self.longPressNumber = 0
            }
        }

        longPressNumber = longPressNumber + 1

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
        dateText.textAlignment = .right
    }

    // 初始化金句
    func init_verse() {
        let t: UILabel! = self.mainText
        t.text = ""

        spinnerView.startAnimating()

        let _ = setTimeout(0.6) {
            Alamofire.request("https://bible.5mlstudio.com")
                .responseString { response in
                    if response.result.isSuccess {
                        var s: String! = response.result.value
                        s = s.replacingOccurrences(of: "\r", with: "")
                        s = s.replacingOccurrences(of: "\n", with: "")
                        s = s.trimmingCharacters(in: .whitespacesAndNewlines)

                        if !self.traditionalChinese {

                        }

                        self.dailyVerse = s
                        t.text = s
                        t.typesetting(lineSpacing: 1.5, lineHeightMultiple: 2, characterSpacing: 2)
                        t.textAlignment = .center
                        self.spinnerView.stopAnimating()
                        self.UI_updateData()

                    } else {
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
    // （載入詳細章節用）
    func intIntoString(number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style(rawValue: UInt(CFNumberFormatterRoundingMode.roundHalfDown.rawValue))!
        let string: String = formatter.string(from: NSNumber(value: number))!
        return string
    }

    // 聖經詳細名字轉中文縮寫
    // （載入詳細章節用）
    func traditionalChinese(longName: String) -> String {

        var traditional: [String: String] = [
            "創世記": "創",
            "出埃及記": "出",
            "利未記": "利",
            "民數記": "民",
            "申命記": "申",
            "約書亞記": "書",
            "士師記": "士",
            "路得記": "得",
            "撒母耳記上": "撒上",
            "撒母耳記下": "撒下",
            "列王紀上": "王上",
            "列王紀下": "王下",
            "歷代志上": "代上",
            "歷代志下": "代下",
            "以斯拉記": "拉",
            "尼希米記": "尼",
            "以斯帖記": "斯",
            "約伯記": "伯",
            "詩篇": "詩",
            "箴言": "箴",
            "傳道書": "傳",
            "雅歌": "歌",
            "以賽亞書": "賽",
            "耶利米書": "耶",
            "耶利米哀歌": "哀",
            "以西結書": "結",
            "但以理書": "但",
            "何西阿書": "何",
            "約珥書": "珥",
            "阿摩司書": "摩",
            "俄巴底亞書": "俄",
            "約拿書": "拿",
            "彌迦書": "彌",
            "那鴻書": "鴻",
            "哈巴谷書": "哈",
            "西番雅書": "番",
            "哈該書": "該",
            "撒迦利亞書": "亞",
            "瑪拉基書": "瑪",
            "馬太福音": "太",
            "馬可福音": "可",
            "路加福音": "路",
            "約翰福音": "約",
            "使徒行傳": "徒",
            "羅馬書": "羅",
            "哥林多前書": "林前",
            "哥林多後書": "林後",
            "加拉太書": "加",
            "以弗所書": "弗",
            "腓立比書": "腓",
            "歌羅西書": "西",
            "帖撒羅尼迦前書": "帖前",
            "帖撒羅尼迦後書": "帖後",
            "提摩太前書": "提前",
            "提摩太後書": "提後",
            "提多書": "多",
            "腓利門書": "門",
            "希伯來書": "來",
            "雅各書": "雅",
            "彼得前書": "彼前",
            "彼得後書": "彼後",
            "約翰壹書": "約一",
            "約翰貳書": "約二",
            "約翰參書": "約三",
            "猶大書": "猶",
            "啟示錄": "啟",
            "哥前": "林前",
            "哥後": "林後",
            "歌前": "林前",
            "歌後": "林後",
            "希": "來",
            "約翰一書": "約一",
            "約翰二書": "約二",
            "約翰三書": "約三",
            "約壹": "約一",
            "約貳": "約二",
            "約參": "約三",
            "啓示錄": "啟",
            "啓": "啟",
            "创": "創",
            "书": "書",
            "诗": "詩",
            "传": "傳",
            "赛": "賽",
            "结": "結",
            "弥": "彌",
            "鸿": "鴻",
            "该": "該",
            "亚": "亞",
            "玛": "瑪",
            "约": "約",
            "罗": "羅",
            "林后": "林後",
            "帖后": "帖後",
            "提后": "提後",
            "门": "門",
            "来": "來",
            "彼后": "彼後",
            "约一": "約一",
            "约二": "約二",
            "约三": "約三",
            "犹": "猶",
            "启": "啟",
            "哥后": "林後",
            "歌后": "林後",
            "约翰一书": "約一",
            "约翰二书": "約二",
            "约翰三书": "約三",
            "约壹": "約一",
            "约贰": "約二",
            "约参": "約三"
        ];

        return (traditional[longName] ?? "")
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


