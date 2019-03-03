//
//  TMDbAPIResponseManager.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 01/03/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import Alamofire

final class TMDbAPIResponseManager<T: Decodable> {
    
    lazy var jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()
    
    func handleResponse(_ dataResponse: DataResponse<Data>) -> GenericResult<T> {
        
        if let response = dataResponse.response,
            let headers = response.allHeaderFields as? [String: Any],
            let retryAfter = headers["Retry-After"] as? String,
            let seconds = Int(retryAfter){
            if response.statusCode == 429 {
                print("REQUEST LIMIT EXCEEDED")
                return .failure(TMDBApiError.requestLimitExceeded(seconds))
            }
        }
        
        if let error = dataResponse.error {
            return .failure(error)
        }
        
        if let data = dataResponse.data {
            if let value = try? jsonDecoder.decode(T.self, from: data){
                return .success(value)
            }
            else {
                return .failure(TMDBApiError.decodingError)
            }
        }
        
        return .failure(TMDBApiError.unknownError)
    }
}
