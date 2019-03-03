//
//  NetworkRequestRetrier.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 01/03/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import Alamofire

class NetworkRequestRetrier: RequestRetrier {
    
    var retriedRequests: [String: Int] = [:]
    let maxRetries: Int = 5
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        
        guard let urlString = request.request?.url?.absoluteString else {
            completion(false, 0.0) // Don't retry
            return
        }
        
        var timeInterval: TimeInterval = 3.0
        
        switch error {
        case TMDBApiError.requestLimitExceeded(let seconds):
            timeInterval = TimeInterval(seconds)
            fallthrough
        default:
            if let retryCount = retriedRequests[urlString]{
                if retryCount < maxRetries {
                    // Retry
                    print("Retry: \(retryCount)")
                    retriedRequests[urlString] = retryCount + 1
                    completion(true, timeInterval)
                }
                else {
                    // The request has been retried 5 times. Don't retry anymore.
                    print("The request has been retried 5 times. Don't retry anymore.")
                    removeCachedUrlRequest(url: urlString)
                    completion(false, 0.0)
                }
            }
            else {
                // The request hasn't yet been retried
                // First retry
                print("Retry: \(1)")
                retriedRequests[urlString] = 1
                completion(true, timeInterval)
            }
        }
    }
    
    private func removeCachedUrlRequest(url: String?) {
        guard let url = url else {
            return
        }
        retriedRequests.removeValue(forKey: url)
    }
    
    
}
