//
//  LoadingIndicatorViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 02/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class LoadingIndicatorViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var backgroundView: UIView!
    
    override var title: String?{
        didSet{
            if titleLabel != nil{
                titleLabel.text = title
            }
        }
    }
    var message: String?{
        didSet{
            if messageLabel != nil{
                messageLabel.text = message
            }
        }
    }
    var complete: (() -> Void)?
    
    init(title: String?, message: String?, complete: (() -> Void)?){
        super.init(nibName: "LoadingIndicatorViewController", bundle: nil)
        self.title = title
        self.message = message
        self.complete = complete
        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.modalTransitionStyle = .crossDissolve
        let _ = self.view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setProgress(_ progress: Float){
        
        self.progressView.setProgress(progress, animated: true)
        
        if progress == 1 && self.isVisible{
            self.dismiss(animated: true, completion: complete)
        }
        else if progress < 1 && !self.activityIndicator.isAnimating{
            self.activityIndicator.startAnimating()
        }
    }
    
    func finish(){
        self.dismiss(animated: true, completion: complete)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        self.titleLabel.text = title
        self.messageLabel.text = message
        self.activityIndicator.hidesWhenStopped = true
        self.progressView.setProgress(0, animated: false)
        self.backgroundView.layer.cornerRadius = 10
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
