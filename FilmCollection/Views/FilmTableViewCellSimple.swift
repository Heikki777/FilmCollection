//
//  FilmTableViewCellSimple.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 27/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class FilmTableViewCellSimple: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    var film: Film?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
    }
    
    
    func configure(withMovie film: Film){
        self.film = film
        titleLabel.text = film.titleYear
    }

}
