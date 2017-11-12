//
//  SectionCell.swift
//  dailyVerse
//
//  Created by 庫倪 on 2017/11/12.
//  Copyright © 2017年 庫倪. All rights reserved.
//

import UIKit

class SectionCell: UITableViewCell {

    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var SectionNumberLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
