//
//  FilmSearchResultTableViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 14/02/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Nuke

class FilmSearchResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var originalTitleLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var overviewLabel: UILabel!
    
    var imageLoadDataTask: URLSessionDataTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setImageURL(url: URL) {
        Nuke.loadImage(with: url, options: ImageLoadingOptions(placeholder: nil, transition: .fadeIn(duration: 0.33), failureImage: nil, failureImageTransition: nil, contentModes: nil), into: posterImageView, progress: nil, completion: nil)
    }
    
    func clear(){
        titleLabel.text = ""
        originalTitleLabel.text = ""
        posterImageView.image = nil
        overviewLabel.text = ""
    }

}
