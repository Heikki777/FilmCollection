//
//  UIViewController+Extensions.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 10/02/2019.
//  Copyright © 2019 Heikki Hämälistö. All rights reserved.
//

import UIKit

extension UIViewController {

    func showAlert(title: String, message: String, okButtonHandler: ((UIAlertAction) -> Void)? = nil){
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: okButtonHandler))
        present(alert, animated: true, completion: nil)
    }

}
