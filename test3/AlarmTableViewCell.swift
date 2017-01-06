//
//  AlarmTableViewCell.swift
//  test3
//
//  Created by Vivian Zhou on 11/30/16.
//  Copyright © 2016 viv. All rights reserved.
//

import UIKit

// controls each cell in the AlarmTableViewController
class AlarmTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    var alarm: Alarm?
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var onoffSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}
