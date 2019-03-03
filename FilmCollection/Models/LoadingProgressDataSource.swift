//
//  LoadingProgressDataSource.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 28/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import Foundation

protocol LoadingProgressDataSource: class {
    var isLoadingInProgress: Bool { get }
    func loadingProgressChanged(progress: Float)
    func loadingFinished()
}
