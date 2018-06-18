//
//  Downloader.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 13/02/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import PromiseKit

class Downloader{

    private init(){
        return
    }
    
    static let shared: Downloader = Downloader()
    
    func loadImage(url: URL) -> Promise<UIImage>{
            return Promise { result in
                let request = URLRequest.init(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)
                let queue = DispatchQueue.init(label: "backgroundThread", qos: .background, attributes: .concurrent)
                
                Alamofire.request(request)
                .validate()
                .responseData(queue: queue, completionHandler: { (response) in
                    if let data = response.data{
                        if let image = UIImage.init(data: data){
                            result.fulfill(image)
                        }
                    }
                    if let error = response.error{
                        result.reject(error)
                    }
                })
            }
        }
    }
    
    func load(request: URLRequest, complete: @escaping (Result) -> Void) -> URLSessionDataTask{
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            
            var result: Result = .Success("")
            
            defer{
                complete(result)
            }
            
            if let error = error{
                result = .Fail(error)
            }
            else if let data = data{
                result = .Success(data)
            }
        }
        dataTask.resume()
        
        return dataTask
    }


enum DownloaderError: Error{
    case NetworkError(Int)
}

enum Result{
    case Success(Any)
    case Fail(Error)
}
