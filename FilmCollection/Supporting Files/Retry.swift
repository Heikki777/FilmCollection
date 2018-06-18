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
        return body().recover { error -> Promise<T> in
            // Attempt 10 times
            guard attempts < 10 else { throw error }
            // Wait for (1.5 * attempts) second before attempting.
            return after(DispatchTimeInterval.seconds(2*attempts)).then(attempt)
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
