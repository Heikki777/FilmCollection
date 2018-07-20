//
//  FilmPreviewViewController.swift
//  FilmCollection
//
//  Created by Sofia Digital on 22/06/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class FilmPreviewViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var film: Movie?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let film = film else{
            print("FilmPreviewViewController. No film")
            return
        }
        
        attempt{
            film.loadBigPosterImage()
        }
        .done { (posterImage) in
            DispatchQueue.main.async {
                self.imageView.image = posterImage
            }
        }
        .catch { (error) in
            print("")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
