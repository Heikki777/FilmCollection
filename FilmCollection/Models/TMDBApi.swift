//
//  TMDBApi.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 13/02/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit
import Alamofire

public enum RequestType: String {
    case GET, POST
}

class SearchRequest {
    var method = RequestType.GET
    var text = ""
    
    init(text: String) {
        self.text = text
    }
}

class TMDBApi{
    
    static let baseURL: String = "https://api.themoviedb.org/"
    static let posterImageBaseURL: String = "https://image.tmdb.org/t/p/"
    static let version: Int = 3
    
    private let apiKey: String = "a62c4199a4ee1f2fcec39ddffc60199f" //TMDB_API_KEY
    
    private init(){
        return
    }
    
    static let shared: TMDBApi = TMDBApi()
    
    lazy var downloader: Downloader = {
        return Downloader.shared
    }()
    
    lazy var jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()

    var searchDataTask: URLSessionDataTask?
    var movieImagesDataTask: URLSessionDataTask?
    
    func search(query: String, page: Int = 1) -> Promise<[FilmSearchResult]> {
        
        return Promise { result in
            
            if query.isEmpty {
                result.fulfill([])
                return
            }
            
            var urlString = "\(TMDBApi.baseURL)\(TMDBApi.version)/search/movie?api_key=\(self.apiKey)&query=\(query)&language=en-US&include_adult=false&page=\(page)"
            urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let url = URL.init(string: urlString)!
            let queue = DispatchQueue.init(label: "backgroundThread", qos: .background, attributes: .concurrent)

            Alamofire.request(url)
            .validate()
            .responseData(queue: queue, completionHandler: { (dataResponse) in
                if let error = dataResponse.error{
                    if let response = dataResponse.response,
                        let headers = response.allHeaderFields as? [String: Any],
                        let retryAfter = headers["Retry-After"] as? String,
                        let seconds = Int(retryAfter){
                        if response.statusCode == 429{
                            result.reject(TMDBApiError.RequestLimitExceeded(seconds))
                            return
                        }
                    }
                    result.reject(error)
                }
                else if let data = dataResponse.data{
                    if let filmSearchResponse = try? self.jsonDecoder.decode(FilmSearchResponse.self, from: data){
                        result.fulfill(filmSearchResponse.results)
                    }
                }
            })
        }
    }
    
    func loadMovie(_ movieId: Int, append: [String] = []) -> Promise<Film> {
        return Promise { result in
            let appendToResponse = (append.isEmpty) ? "" : "&append_to_response=" + append.joined(separator: ",")
            let url = URL(string: "https://api.themoviedb.org/3/movie/\(movieId)?api_key=\(self.apiKey)&language=en-US\(appendToResponse)")!
            let queue = DispatchQueue.init(label: "bgThread1", qos: .background, attributes: .concurrent)

            Alamofire.request(url)
            .validate()
            .responseData(queue: queue, completionHandler: { (dataResponse) in

                if let error = dataResponse.error{
                    //print(error.localizedDescription)
                    if let response = dataResponse.response,
                    let headers = response.allHeaderFields as? [String: Any],
                    let retryAfter = headers["Retry-After"] as? String,
                    let seconds = Int(retryAfter){
                        if response.statusCode == 429{
                            result.reject(TMDBApiError.RequestLimitExceeded(seconds))
                            return
                        }
                    }
                    result.reject(error)
                }
                else if let data = dataResponse.data{
                    if let movie = try? self.jsonDecoder.decode(Film.self, from: data){
                        result.fulfill(movie)
                    }
                    else{
                        print("Decoding movie failed")
                        result.reject(TMDBApiError.DecodeMovieError)
                    }
                }
            })
        }
    }
    
    func loadVideos(_ movieId: Int) -> Promise<[Video]> {
        return Promise { result in
            let url = URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/videos?api_key=\(self.apiKey)&language=en-US")!
            let queue = DispatchQueue.init(label: "backgroundThread", qos: .background, attributes: .concurrent)

            Alamofire.request(url)
            .validate()
            .responseData(queue: queue, completionHandler: { (dataResponse) in
                if let error = dataResponse.error{
                    //print(error.localizedDescription)
                    if let response = dataResponse.response,
                        let headers = response.allHeaderFields as? [String: Any],
                        let retryAfter = headers["Retry-After"] as? String,
                        let seconds = Int(retryAfter){
                        if response.statusCode == 429{
                            result.reject(TMDBApiError.RequestLimitExceeded(seconds))
                            return
                        }
                    }
                    result.reject(error)
                }
                else if let data = dataResponse.data{
                    if let videoResponse = try? self.jsonDecoder.decode(VideoResponse.self, from: data){
                        let videos = videoResponse.results
                        result.fulfill(videos)
                    }
                }
                result.reject(TMDBApiError.DecodeVideosError)
            })
        }
    }
    
    func loadImage(withPath path: String?, size: PosterSize = .original) -> Promise<UIImage> {
        return Promise { result in
            guard let path = path else{
                return result.reject(TMDBApiError.ImageError("No path"))
            }
        
            let url = TMDBApi.getPosterURL(size: size, imagePath: path) 
            let queue = DispatchQueue.init(label: "backgroundThread", qos: .background, attributes: .concurrent)

            Alamofire.request(url)
            .validate()
            .responseData(queue: queue, completionHandler: { (dataResponse) in
                if let error = dataResponse.error{
                    //print(error.localizedDescription)
                    if let response = dataResponse.response,
                        let headers = response.allHeaderFields as? [String: Any],
                        let retryAfter = headers["Retry-After"] as? String,
                        let seconds = Int(retryAfter){
                        if response.statusCode == 429{
                            result.reject(TMDBApiError.RequestLimitExceeded(seconds))
                            return
                        }
                    }
                    result.reject(error)
                }
                else if let data = dataResponse.data{
                    if let image = UIImage.init(data: data){
                        result.fulfill(image)
                    }
                }
                result.reject(TMDBApiError.DataError("No image data"))
            })
        }
    }
    
    func loadCredits(forPersonWithID id: Int) -> Promise<(crew: [CrewMember], cast: [CastMember])>{
        return Promise { result in
            let url = URL(string: "https://api.themoviedb.org/3/person/\(id)/movie_credits?api_key=\(self.apiKey)&language=en-US")!
            let queue = DispatchQueue.init(label: "backgroundThread", qos: .background, attributes: .concurrent)

            Alamofire.request(url)
            .validate()
            .responseData(queue: queue, completionHandler: { (dataResponse) in
                if let error = dataResponse.error{
                    if let response = dataResponse.response,
                        let headers = response.allHeaderFields as? [String: Any],
                        let retryAfter = headers["Retry-After"] as? String,
                        let seconds = Int(retryAfter){
                        if response.statusCode == 429{
                            result.reject(TMDBApiError.RequestLimitExceeded(seconds))
                            return
                        }
                    }
                    result.reject(error)
                }
                else if let data = dataResponse.data{
                    if let creditsResponse = try? self.jsonDecoder.decode(Credits.self, from: data){
                        let cast = creditsResponse.cast
                        let crew = creditsResponse.crew
                        result.fulfill((crew: crew, cast: cast))
                    }
                    else{
                        result.reject(TMDBApiError.DecodePersonMovieCreditsError)
                    }
                }
                else{
                    result.reject(TMDBApiError.DecodePersonMovieCreditsError)
                }
            })
        }
    }
    
    func loadImages(personId: Int, progressHandler: ((Float) -> Void)? = nil) -> Promise<[UIImage]>{
        
        return Promise { result in
            let urlString = "https://api.themoviedb.org/3/person/\(personId)/images?api_key=\(self.apiKey)"
            let url = URL.init(string: urlString)!
            
            DispatchQueue.global().async {
                Alamofire.request(url)
                .validate()
                .responseData(completionHandler: { dataResponse in
                    if let error = dataResponse.error{
                        if let response = dataResponse.response,
                            let headers = response.allHeaderFields as? [String: Any],
                            let retryAfter = headers["Retry-After"] as? String,
                            let seconds = Int(retryAfter){
                            if response.statusCode == 429{
                                result.reject(TMDBApiError.RequestLimitExceeded(seconds))
                                return
                            }
                        }
                        result.reject(error)
                    }
                    
                    guard let data = dataResponse.data else{
                        result.reject(TMDBApiError.DataError("No data in response"))
                        return
                    }
                    if let personImagesResponse = try? self.jsonDecoder.decode(PersonImagesResponse.self, from: data){
                        let imagePromises = personImagesResponse.profiles.map{
                            self.loadImage(withPath: $0.file_path)
                        }
                        
                        var imagesLoaded: Float = 0
                        imagePromises.forEach({ (imagePromise) in
                            imagePromise.done({ (image) in
                                imagesLoaded += 1
                                progressHandler?(imagesLoaded / Float(imagePromises.count))
                            })
                        })
                    
                        when(fulfilled: imagePromises)
                        .done({ (images) in
                            result.fulfill(images)
                            progressHandler?(1)
                        })
                        .catch({ (error) in
                            result.reject(error)
                        })
                    }
                    else{
                        result.reject(TMDBApiError.DecodeImagesError)
                    }
                })
            }
        }

    }
    
    func loadImages(_ movieId: Int, size: PosterSize = .original, progressHandler: @escaping (Float) -> Void) -> Promise<FilmImages> {

        return Promise { result in
            var postersLoaded: Bool = false
            var backdropsLoaded: Bool = false
            let images = FilmImages()

            func fulFillCheck(){
                if postersLoaded && backdropsLoaded {
                    result.fulfill(images)
                }
            }
            
            let urlString = "https://api.themoviedb.org/3/movie/\(movieId)/images?api_key=\(self.apiKey)"
            let url = URL.init(string: urlString)!
            
            var loaded: Float = 0
            var numberOfPosterImagesLoaded = 0
            var numberOfBackdropImagesLoaded = 0
            
            let queue = DispatchQueue.init(label: "backgroundThread", qos: .background, attributes: .concurrent)
            
            Alamofire.request(url)
            .validate()
            .responseData(queue: queue, completionHandler: { (response) in
                if let error = response.error{
                    result.reject(error)
                }
                else if let data = response.data{
                    if let imagesResponse = try? self.jsonDecoder.decode(ImagesResponse.self, from: data){
                        var posterImages: [(data: ImageData, image:UIImage)?] = Array.init(repeating: nil, count: imagesResponse.posters.count)
                        var backdropImages: [(data: ImageData, image:UIImage)?] = Array.init(repeating: nil, count: imagesResponse.backdrops.count)
                        let totalNumberOfImages: Float = Float(imagesResponse.backdrops.count) + Float(imagesResponse.posters.count)
                       
                        // Load poster images
                        imagesResponse.posters.enumerated().forEach({ (i, imageData) in
                            let url = TMDBApi.getPosterURL(size: size, imagePath: imageData.filePath)
                            attempt{
                                Downloader.shared.loadImage(url: url)
                            }
                            .done{ image in
                                posterImages[i] = (data: imageData, image: image)
                            }
                            .ensure {
                                numberOfPosterImagesLoaded += 1
                                loaded += 1
                                progressHandler(loaded / totalNumberOfImages)
                                if numberOfPosterImagesLoaded == imagesResponse.posters.count{
                                    postersLoaded = true
                                    images.posters = posterImages.compactMap { $0 }
                                    fulFillCheck()
                                }
                            }
                            .catch { error in
                                //print(error.localizedDescription)
                            }
                        })
                        
                        // Load backdrop images
                        imagesResponse.backdrops.enumerated().forEach({ (i, imageData) in
                            let url = TMDBApi.getPosterURL(size: size, imagePath: imageData.filePath)
                            attempt{
                                Downloader.shared.loadImage(url: url)
                            }
                            .done{ image in
                                backdropImages[i] = (data: imageData, image: image)
                            }
                            .ensure {
                                numberOfBackdropImagesLoaded += 1
                                loaded += 1
                                progressHandler(loaded / totalNumberOfImages)
                                if numberOfBackdropImagesLoaded == imagesResponse.backdrops.count{
                                    backdropsLoaded = true
                                    images.backdrops = backdropImages.compactMap { $0 }
                                    fulFillCheck()
                                }
                            }
                            .catch { error in
                                //print(error.localizedDescription)
                            }
                        })
                    }
                    else{
                        result.reject(TMDBApiError.DecodeImagesError)
                    }
                }
                else{
                    result.reject(TMDBApiError.DataError("Data is nil"))
                }
            })
        }
    }
    
    func loadCredits(_ movieId: Int, retryCount: Int = 0) -> Promise<Credits> {
        return Promise { result in
            let url = URL(string: "https://api.themoviedb.org/3/movie/\(movieId)/credits?api_key=a62c4199a4ee1f2fcec39ddffc60199f")!
            let queue = DispatchQueue.init(label: "backgroundThread", qos: .background, attributes: .concurrent)

            Alamofire.request(url)
            .validate()
            .responseData(queue: queue, completionHandler: { (response) in
                if let error = response.error{
                    result.reject(error)
                }
                else if let data = response.data{
                    if let creditsResponse = try? self.jsonDecoder.decode(CreditsResponse.self, from: data){
                        let credits = Credits(crew: creditsResponse.crew, cast: creditsResponse.cast)
                        result.fulfill(credits)
                    }
                }
            })
        }
    }
    
    func loadPersonDetails(_ personId: Int) -> Promise<PersonDetailInformation> {
        return Promise { result in
            let url = URL(string: "https://api.themoviedb.org/3/person/\(personId)?api_key=a62c4199a4ee1f2fcec39ddffc60199f")!
            let queue = DispatchQueue.init(label: "backgroundThread", qos: .background, attributes: .concurrent)

            Alamofire.request(url)
            .validate()
            .responseData(queue: queue, completionHandler: { (response) in
                if let error = response.error{
                    result.reject(error)
                }
                else if let data = response.data{
                    if let personDetailInformation = try? self.jsonDecoder.decode(PersonDetailInformation.self, from: data){
                        result.fulfill(personDetailInformation)
                    }
                }
            })
        }
    }
    
    static func getPosterURL(size: PosterSize, imagePath: String) -> URL{
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

enum TMDBApiError: Error{
    case InvalidURL
    case DecodeMovieError
    case DecodeCreditsError
    case DecodeImagesError
    case DecodeSearchResponseError
    case BadStatus(status: Int)
    case DataError(String)
    case DecodingError(String)
    case DecodePersonMovieCreditsError
    case ImageError(String)
    case DecodeVideosError
    case RequestLimitExceeded(Int)
}

enum MovieError: Error{
    case missingData(String)
}
