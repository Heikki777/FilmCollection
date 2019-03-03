//
//  TMDBApi.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 13/02/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

public enum RequestType: String {
    case GET, POST
}

final class TMDBApi {
    
    static let baseURL: String = "https://api.themoviedb.org/"
    static let posterImageBaseURL: String = "https://image.tmdb.org/t/p/"
    static let version: Int = 3
    
    private let apiKey: String = "a62c4199a4ee1f2fcec39ddffc60199f" // TMDB_API_KEY
    
    private lazy var sessionManager: SessionManager = {
        let sessionManager = SessionManager()
        let requestRetrier = NetworkRequestRetrier()
        sessionManager.retrier = requestRetrier
        return sessionManager
    }()
    
    private init(){
        return
    }
    
    static let shared: TMDBApi = TMDBApi()
    
    lazy var jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()
    
    func search(query: String, page: Int = 1, completion: @escaping (GenericResult<FilmSearchResponse>) -> Void) {
    
        if query.isEmpty {
            completion(GenericResult.failure(TMDBApiError.emptySearchError))
            return
        }
        
        var urlString = "\(TMDBApi.baseURL)\(TMDBApi.version)/search/movie?api_key=\(self.apiKey)&query=\(query)&language=en-US&include_adult=false&page=\(page)"
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL.init(string: urlString)!
        let queue = DispatchQueue.init(label: "search", qos: .userInitiated, attributes: .concurrent)
        
        sessionManager.request(url)
        .validate()
        .responseData(queue: queue, completionHandler: { (dataResponse) in
            let result = TMDbAPIResponseManager<FilmSearchResponse>().handleResponse(dataResponse)
            completion(result)
        })
    }
    
    func loadFilm(_ movieId: Int, append: [String] = [], completion: @escaping (GenericResult<Film>) -> Void) {
        let appendToResponse = (append.isEmpty) ? "" : "&append_to_response=" + append.joined(separator: ",")
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(movieId)?api_key=\(self.apiKey)&language=en-US\(appendToResponse)")!
        let queue = DispatchQueue.init(label: "loadFilm", qos: .userInitiated, attributes: .concurrent)
        
        sessionManager.request(url)
        .validate()
        .responseData(queue: queue, completionHandler: { (dataResponse) in
            let result = TMDbAPIResponseManager<Film>().handleResponse(dataResponse)
            completion(result)
        })
    }
    
    func loadVideos(_ movieId: Int, completion: @escaping (GenericResult<VideoResponse>) -> Void) {
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/videos?api_key=\(self.apiKey)&language=en-US")!
        let queue = DispatchQueue.init(label: "loadVideos", qos: .userInitiated, attributes: .concurrent)

        sessionManager.request(url)
        .validate()
        .responseData(queue: queue, completionHandler: { (dataResponse) in
            let result = TMDbAPIResponseManager<VideoResponse>().handleResponse(dataResponse)
            completion(result)
        })
        
    }
    
    func loadCredits(forPersonWithID id: Int, completion: @escaping (GenericResult<Credits>) -> Void) {
        let url = URL(string: "https://api.themoviedb.org/3/person/\(id)/movie_credits?api_key=\(self.apiKey)&language=en-US")!
        let queue = DispatchQueue.init(label: "loadCredits", qos: .userInitiated, attributes: .concurrent)

        sessionManager.request(url)
        .validate()
        .responseData(queue: queue, completionHandler: { (dataResponse) in
            let result = TMDbAPIResponseManager<Credits>().handleResponse(dataResponse)
            completion(result)
        })
        
    }

    func loadPersonImages(personId: Int, completion: @escaping (GenericResult<PersonImagesResponse>) -> Void) {
        let urlString = "https://api.themoviedb.org/3/person/\(personId)/images?api_key=\(self.apiKey)"
        let url = URL.init(string: urlString)!
        let queue = DispatchQueue(label: "loadPersonImages", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)

        sessionManager.request(url)
        .validate()
        .responseData(queue: queue, completionHandler: { (dataResponse) in
            let result = TMDbAPIResponseManager<PersonImagesResponse>().handleResponse(dataResponse)
            completion(result)
        })
    }
    
    func loadFilmImages(_ movieId: Int, size: PosterSize = .original, completion: @escaping (GenericResult<ImagesResponse>) -> Void) {
        let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/images?api_key=\(self.apiKey)"
        let url = URL.init(string: urlString)!
        let queue = DispatchQueue(label: "loadFilmImages", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
        
        sessionManager.request(url)
        .validate()
        .responseData(queue: queue, completionHandler: { (dataResponse) in
            let result = TMDbAPIResponseManager<ImagesResponse>().handleResponse(dataResponse)
            completion(result)
        })
    }
    
    func loadCredits(_ movieId: Int, completion: @escaping (GenericResult<CreditsResponse>) -> Void) {
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/credits?api_key=a62c4199a4ee1f2fcec39ddffc60199f")!
        let queue = DispatchQueue.init(label: "loadCredits", qos: .userInitiated, attributes: .concurrent)

        sessionManager.request(url)
        .validate()
        .responseData(queue: queue, completionHandler: { (dataResponse) in
            let result = TMDbAPIResponseManager<CreditsResponse>().handleResponse(dataResponse)
            completion(result)
        })
    }
    
    func loadPersonDetails(_ personId: Int, completion: @escaping (GenericResult<PersonDetailInformation>) -> Void) {
        let url = URL(string: "https://api.themoviedb.org/3/person/\(personId)?api_key=a62c4199a4ee1f2fcec39ddffc60199f")!
        let queue = DispatchQueue.init(label: "loadPersonDetails", qos: .userInitiated, attributes: .concurrent)

        sessionManager.request(url)
        .validate()
        .responseData(queue: queue, completionHandler: { (dataResponse) in
            let result = TMDbAPIResponseManager<PersonDetailInformation>().handleResponse(dataResponse)
            completion(result)
        })
    }
    
    static func getImageURL(size: PosterSize, imagePath: String) -> URL{
        return URL(string: "\(TMDBApi.posterImageBaseURL)\(size)\(imagePath)")!
    }
    
    enum PosterSize: String{
        case w92
        case w154
        case w185
        case w342
        case w500
        case w780
        case original
    }
}

struct PersonImagesResponse: Decodable{
    var profiles: [ProfileImage]
    var id: Int?
}

struct ProfileImage: Decodable{
    var file_path: String
}

typealias Video = VideoResponse.Video
struct VideoResponse: Decodable{
    var id: Int
    var results: [Video]
    
    struct Video: Decodable{
        var id: String
        var iso_639_1: String
        var iso_3166_1: String
        var key: String
        var name: String
        var site: String
        var size: Int
        var type: VideoType
        
        private enum CodingKeys: String, CodingKey{
            case id
            case iso_639_1
            case iso_3166_1
            case key
            case name
            case site
            case size
            case type
        }
        
        enum VideoType: String, Decodable{
            case Trailer
            case Teaser
            case Clip
            case Featurette
        
            private enum CodingKeys: String, CodingKey{
                case Trailer
                case Teaser
                case Clip
                case Featurette
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey{
        case id
        case results
    }
}

typealias ImageData = ImagesResponse.ImageData
struct ImagesResponse: Decodable{
    var id: Int?
    var backdrops: [ImageData]
    var posters: [ImageData]
    
    struct ImageData: Decodable{
        var aspectRatio: Double
        var filePath: String
        var height: Int
        var width: Int
        
        private enum CodingKeys: String, CodingKey{
            case aspectRatio = "aspect_ratio"
            case filePath = "file_path"
            case height
            case width
        }
    }
}

struct PersonDetailInformation: Decodable{
    var adult: Bool?
    var alsoKnownAs: [String]
    var biography: String
    var birthDay: String?
    var deathDay: String?
    var gender: Int
    var id: Int
    var imdbId: String
    var name: String
    var placeOfBirth: String?
    var profilePath: String?
        
    private enum CodingKeys: String, CodingKey{
        case adult
        case alsoKnownAs = "also_known_as"
        case biography
        case birthDay = "birthday"
        case deathDay = "deathday"
        case gender
        case id
        case imdbId = "imdb_id"
        case name
        case placeOfBirth = "place_of_birth"
        case profilePath = "profile_path"
    }
    
}

typealias FilmSearchResult = FilmSearchResponse.FilmSearchResult
struct FilmSearchResponse: Decodable{
    var results: [FilmSearchResult]
    
    struct FilmSearchResult: Decodable{
        var title: String?
        var id: Int?
        var posterPath: String?
        var releaseDate: String?
        var originalTitle: String?
        var overview: String?
        
        private enum CodingKeys: String, CodingKey {
            case title
            case id
            case posterPath = "poster_path"
            case releaseDate = "release_date"
            case originalTitle = "original_title"
            case overview
        }
    }
}

struct CreditsResponse: Decodable{
    var id: Int
    var cast: [CastMember]
    var crew: [CrewMember]
}

enum TMDBApiError: Error {
    case invalidURL
    case decodeMovieError
    case decodeCreditsError
    case decodeImagesError
    case decodeSearchResponseError
    case decodePersonDetailError
    case emptySearchError
    case badStatus(status: Int)
    case dataError(String)
    case decodingError
    case decodePersonMovieCreditsError
    case imageError(String)
    case decodeVideosError
    case requestLimitExceeded(Int)
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "invalid URL"
        case .decodeMovieError:
            return "Decode movie error"
        case .decodeCreditsError:
            return "Decode credits error"
        case .decodeImagesError:
            return "Decode images error"
        case .decodeSearchResponseError:
            return "Decode search response error"
        case .decodePersonDetailError:
            return "Decode person detail error"
        case .emptySearchError:
            return "empty search error"
        case .badStatus(let status):
            return "Bad status: \(status)"
        case .dataError(_):
            return "Data error"
        case .decodingError:
            return "Decoding error"
        case .decodePersonMovieCreditsError:
            return "Decode person movie credits error"
        case .imageError(_):
            return "Image error"
        case .decodeVideosError:
            return "Decode videos error"
        case .requestLimitExceeded(_):
            return "Request limit exceeded"
        case .unknownError:
            return "Unknown error"
        }
    }
    
}

enum MovieError: Error{
    case missingData(String)
}
