//
//  FilmTableViewCellSimple.swift
//  FilmCollection
//
//  Created by Sofia Digital on 27/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class FilmTableViewCellSimple: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    var movie: Movie?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(withMovie movie: Movie){
        self.movie = movie
        titleLabel.text = movie.titleYear
    }

}
