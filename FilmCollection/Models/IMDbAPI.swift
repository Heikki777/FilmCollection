//
//  IMDbAPI.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 20/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import Foundation
import Alamofire
import Gzip

class IMDbAPI {
    
    enum IMDbAPIError: Error {
        case DataStringConversionFailure
        case EmptyFile
        case RatingsNotLoaded
        case RatingNotAvailable
    }
    
    static var shared: IMDbAPI = {
        let api = IMDbAPI()
        return api
    }()
    
    static let baseURL: String = "https://datasets.imdbws.com/"
    static let ratingsPath: String = "title.ratings.tsv.gz"
    
    private init(){
        return
    }
    
    private var lastRatingsUpdate: Date?
    private var ratings: [String:Float] = [:]
    private var ratingsUpdateTimer: DispatchSourceTimer?
    
    func ratingForFilm(withIMDbId id: String, completion: @escaping (GenericResult<Float>) -> Void) {
        guard let rating = ratings[id] else {
            if lastRatingsUpdate == nil{
                completion(.failure(IMDbAPIError.RatingsNotLoaded))
            }
            else{
                completion(.failure(IMDbAPIError.RatingNotAvailable))
            }
            return
        }
        completion(.success(rating))
        
    }
    
    func setScheduledRatingsUpdate(withInterval interval: DispatchTimeInterval) {
        // Cancel previous timer
        ratingsUpdateTimer?.cancel()
        
        ratingsUpdateTimer = DispatchSource.makeTimerSource()
        ratingsUpdateTimer?.schedule(deadline: .now(), repeating: interval)
        ratingsUpdateTimer?.setEventHandler {
            self.loadRatings(completion: { (ratings) in
                DispatchQueue.main.async {
                    self.ratings = ratings
                    self.lastRatingsUpdate = Date()
                }
            })
        }
        ratingsUpdateTimer?.activate()
    }
    
    func cancelScheduledRatingsUpdate(){
        ratingsUpdateTimer?.cancel()
    }
    
    private func loadRatings(completion: @escaping ([String:Float]) -> Void) {
        
        let url = URL.init(string: IMDbAPI.baseURL + IMDbAPI.ratingsPath)!
        let queue = DispatchQueue.init(label: "loadRatings", qos: .userInitiated, attributes: .concurrent)
        
        Alamofire.request(url)
        .validate()
        .responseData(queue: queue) { (response) in
            
            var ratingsDictionary: [String: Float] = [:]
            defer {
                completion(ratingsDictionary)
            }
            
            do {
                if let error = response.error {
                    throw error
                }
                guard let data = response.data else {
                    return
                }
                let decompressedData: Data = try! data.gunzipped()
                guard let ratings = String.init(data: decompressedData, encoding: String.Encoding.utf8) else {
                    throw IMDbAPIError.DataStringConversionFailure
                }
                
                var lines = ratings.split(separator: "\n")
                
                guard !lines.isEmpty else {
                    throw IMDbAPIError.EmptyFile
                }
                
                lines.removeFirst() // Remove the header line
                
                lines.forEach({ (line) in
                    let columns = line.split(separator: "\t")
                    guard columns.count > 1 else { return }
                    let filmID = String(columns[0])
                    let averageRating = Float(String(columns[1]))
                    ratingsDictionary[filmID] = averageRating
                })
            }
            catch let error {
                print("IMDb ratings could not be loaded")
                print(error.localizedDescription)
            }
        }
    }
}
