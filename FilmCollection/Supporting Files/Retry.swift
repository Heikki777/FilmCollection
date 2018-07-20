//
//  Retry.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 27/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import PromiseKit

func attempt<T>(_ body: @escaping () -> Promise<T>) -> Promise<T>{
    var attempts = 0
    func attempt() -> Promise<T> {
        attempts += 1
        //print("Attempt: \(attempts)")
        return body().recover { error -> Promise<T> in
            // Attempt 20 times
            guard attempts < 20 else {
                print("Attempted 20 times")
                throw error
            }
            
            if let tmdbApiError = error as? TMDBApiError{
                switch tmdbApiError{
                case .RequestLimitExceeded(let retryAfterSeconds):
                    let milliseconds = retryAfterSeconds * 1000
                    return after(DispatchTimeInterval.milliseconds(milliseconds)).then(attempt)
                default:
                    break
                }
            }

            //Wait for (2 * attempts) second before attempting.
            let seconds: Double = Double(2 * attempts) + drand48()
            let milliseconds: Int = Int(seconds * 1000)
            //print("Retry after \(milliseconds) ms")
            return after(DispatchTimeInterval.milliseconds(milliseconds)).then(attempt)
        }
    }
    return attempt()
}

func attempt<T>(times: Int = 1, waitSeconds: Int = 2, _ body: @escaping () -> Promise<T>) -> Promise<T>{
    var attempts = 0
    func attempt() -> Promise<T> {
        attempts += 1
        return body().recover { error -> Promise<T> in
            guard attempts < times else { throw error }
            return after(DispatchTimeInterval.seconds(waitSeconds*attempts)).then(attempt)
        }
    }
    return attempt()
}
