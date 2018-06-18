//
//  PopoverTableViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 26/02/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class PopoverTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = (selected) ? .checkmark : .none
    }
    

}
