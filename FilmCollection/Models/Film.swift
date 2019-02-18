//
//  Film.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 28/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import PromiseKit

// MARK: - Film
class Film: NSObject, Codable, Rateable, HasVideo, HasCredits, Reviewable {
    
    static var dateFormatter: DateFormatter = {
        return DateFormatter()
    }()
    
    var adult: Bool?
    var backdropPath: String?
    var budget: Int?
    var genres: [Genre]?
    var id: Int
    var originalLanguage: String?
    var originalTitle: String
    var overview: String?
    var posterPath: String?
    var productionCompanies: [Company]?
    var releaseDate: String?
    var productionCountries: [Country]?
    var revenue: Int?
    var runtime: Int?
    var spokenLanguages: [Language]?
    var status: String?
    var tagline: String?
    var title: String
    var video: Bool?
    var smallPosterImage: UIImage? = nil
    var largePosterImage: UIImage? = nil
    var credits: Credits = Credits()
    
    weak var entity: FilmEntity? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        guard let entity = (appDelegate.filmEntities.filter { Int($0.id) == self.id }).first else { return nil }
        return entity
    }
    
    var sortingTitle: String {
        let articles = ["A ", "An ", "The "]
        for article in articles{
            if title.starts(with: article){
                let range = title.startIndex..<title.index(title.startIndex, offsetBy: article.count)
                var result = title
                result.removeSubrange(range)
                return result
            }
        }
        return title
    }
    
    // MARK: - Rateable
    var rating: Rating = .NotRated
    
    // MARK: - Reviewable
    var review: String? = nil
    
    // MARK: - HasVideo
    var videos: [Video] = []
    
    var year: Int?{
        get{
            if let releaseDate = releaseDate{
                let dateFormatter = Film.dateFormatter
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: releaseDate){
                    dateFormatter.dateFormat = "yyyy"
                    return Int(dateFormatter.string(from: date))
                }
            }
            return nil
        }
    }
    var titleYear: String{
        get{
            if let year = year{
                return "\(title) (\(year))"
            }
            return "\(title)"
        }
    }
    var directors: [CrewMember]{
        get{
            return credits.crew.filter{$0.job?.lowercased() == "director"}
        }
    }
    
    // MARK: - Equatable
    static func ==(lhs: Film, rhs: Film) -> Bool{
        return lhs.id == rhs.id
    }
    
    struct Genre: Codable{
        var id: Int
        var name: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
        }
    }
    
    struct Company: Codable{
        var name: String?
        var id: Int?
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
        }
    }
    
    struct Country: Codable{
        var iso_3166_1: String?
        var name: String?
        
        enum CodingKeys: String, CodingKey {
            case iso_3166_1
            case name
        }
    }
    
    struct Language: Codable{
        var iso_639_1: String?
        var name: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case budget
        case credits
        case genres
        case id
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview
        case posterPath = "poster_path"
        case productionCompanies = "production_companies"
        case releaseDate = "release_date"
        case productionCountries = "production_contries"
        case revenue
        case runtime
        case spokenLanguages = "spoken_languages"
        case status
        case tagline
        case title
        case video
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.adult = try? values.decode(Bool.self, forKey: .adult)
        self.backdropPath = try? values.decode(String.self, forKey: .backdropPath)
        self.budget = try? values.decode(Int.self, forKey: .budget)
        self.genres = try? values.decode([Genre].self, forKey: .genres)
        self.id = try values.decode(Int.self, forKey: .id)
        self.originalTitle = try values.decode(String.self, forKey: .originalTitle)
        self.originalLanguage = try? values.decode(String.self, forKey: .originalLanguage)
        self.overview = try? values.decode(String.self, forKey: .overview)
        self.posterPath = try? values.decode(String.self, forKey: .posterPath)
        self.productionCompanies = try? values.decode([Company].self, forKey: .productionCompanies)
        self.releaseDate = try? values.decode(String.self, forKey: .releaseDate)
        self.productionCountries = try? values.decode([Country].self, forKey: .productionCountries)
        self.revenue = try? values.decode(Int.self, forKey: .revenue)
        self.runtime = try? values.decode(Int.self, forKey: .runtime)
        self.spokenLanguages = try? values.decode([Language].self, forKey: .spokenLanguages)
        self.status = try? values.decode(String.self, forKey: .status)
        self.tagline = try? values.decode(String.self, forKey: .tagline)
        self.title = try values.decode(String.self, forKey: .title)
        self.video = try? values.decode(Bool.self, forKey: .video)
        
        if (values.contains(.credits)){
            self.credits = try values.decode(Credits.self, forKey: .credits)
        }
    }
    
    init(id: Int, title: String, originalTitle: String, smallPosterImage: UIImage){
        self.title = title
        self.id = id
        self.originalTitle = originalTitle
        self.smallPosterImage = smallPosterImage
        
        super.init()
        
        if let filmEntity = entity {
            self.rating = Rating(rawValue: Int(filmEntity.rating)) ?? .NotRated
            self.review = filmEntity.review
        }
    }
    
    func loadPosterImages() -> Promise<(small: UIImage, large: UIImage)>{
        // Load posters
        return Promise { result in
            if let posterPath = self.posterPath{
                
                let largePosterURL = TMDBApi.getPosterURL(size: .w500, imagePath: posterPath)
                let smallPosterURL = TMDBApi.getPosterURL(size: .w92, imagePath: posterPath)
                let promises = [
                    Downloader.shared.loadImage(url: smallPosterURL),
                    Downloader.shared.loadImage(url: largePosterURL)
                ]
                attempt{
                    when(fulfilled: promises).done({ (images) in
                        result.fulfill((small: images[0], large: images[1]))
                    })
                }
                .catch({ (error) in
                    print("Loading poster images for the movie: \(self.title) failed")
                    print(error.localizedDescription)
                    result.reject(error)
                })
            }
            else{
                result.reject(MovieError.missingData("posterPath"))
            }
        }
    }
    
    func loadSmallPosterImage() -> Promise<UIImage>{
        return Promise { result in
            if let posterPath = self.posterPath{

                let smallPosterURL = TMDBApi.getPosterURL(size: .w92, imagePath: posterPath)
                Downloader.shared.loadImage(url: smallPosterURL)
                .done({ (image) in
                    result.fulfill(image)
                })
                .catch({ (error) in
                    print("Loading poster images for the movie: \(self.title) failed")
                    print(error.localizedDescription)
                })
            }
            else{
                result.reject(MovieError.missingData("posterPath"))
            }
        }
    }
    
    func loadLargePosterImage() -> Promise<UIImage>{
        return Promise { result in
            if let posterPath = self.posterPath{
                let bigPosterURL = TMDBApi.getPosterURL(size: .w500, imagePath: posterPath)
                Downloader.shared.loadImage(url: bigPosterURL)
                .done({ (image) in
                    result.fulfill(image)
                })
                .catch({ (error) in
                    print("Loading poster images for the movie: \(self.title) failed")
                    print(error.localizedDescription)
                })
            }
            else{
                result.reject(MovieError.missingData("posterPath"))
            }
        }
    }
    
    func getSectionTitle(sortingRule: SortingRule) -> String{
        switch sortingRule {
        case .rating:
            return self.rating.description
        case .title:
            if let first = self.sortingTitle.first{
                return String.init(first)
            }
            return ""
        case .year:
            if let year = self.year{
                return "\(year)"
            }
            return "Unknown"
        }
    }
}
