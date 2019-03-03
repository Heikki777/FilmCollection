//
//  FilmTableViewCell.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 30/01/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Alamofire
import Nuke

class FilmTableViewCellExpanded: UITableViewCell {

    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var directorLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    
    var film: Film?
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
    
    func configure(withFilm film: Film){
        
        self.film = film
        
        titleLabel.text = film.titleYear
        
        // Director(s)
        let directors = film.directors
        directorLabel.isHidden = true
        if directors.count > 0{
            let directorsString = directors.compactMap{$0.name}.joined(separator: ", ")
            directorLabel.text = "\(pluralS("Director", count: directors.count)): \(directorsString)"
            directorLabel.isHidden = false
        }
        
        // Image
        if let posterPath = film.posterPath {
            let posterURL = TMDBApi.getImageURL(size: .w92, imagePath: posterPath)
            Nuke.loadImage(with: posterURL, into: posterImageView)
        }
        
        // Genres
        if let genres = film.genres{
            genreLabel.text = "Genre: " + genres.map{$0.name}.joined(separator: ", ")
        }
        
        ratingLabel.text = "Rating: " + film.rating.description
    }
    
}

