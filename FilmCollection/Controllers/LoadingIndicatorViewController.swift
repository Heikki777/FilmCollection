//
//  LoadingIndicatorViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 02/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class LoadingIndicatorViewController: UIViewController, LoadingProgressDataSource {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBAction func handleCancelButtonPress() {
        delegate?.loadingIndicatorViewControllerCancelButtonPressed()
        dismiss(animated: true, completion: nil)
    }
    
    override var title: String? {
        didSet{
            if titleLabel != nil{
                titleLabel.text = title
            }
        }
    }
    var message: String? {
        didSet{
            messageLabel?.text = message
        }
    }
    
    private var complete: (() -> Void)?
    private var dismissWhenBecomesVisible: Bool = false
    
    weak var delegate: LoadingIndicatorViewControllerDelegate?
    
    convenience init(delegate: LoadingIndicatorViewControllerDelegate? = nil, dataSource: LoadingProgressDataSource? = nil) {
        self.init(delegate: delegate, title: nil, message: nil, complete: nil)
    }
    
    init(delegate: LoadingIndicatorViewControllerDelegate?, title: String?, message: String?, showCancelButton: Bool = false, complete: (() -> Void)? = nil) {
        super.init(nibName: "LoadingIndicatorViewController", bundle: nil)
        self.delegate = delegate
        self.title = title
        self.message = message
        self.complete = complete
        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.modalTransitionStyle = .crossDissolve
        _ = self.view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setProgress(_ progress: Float){
        self.progressView.setProgress(progress, animated: true)
        if progress.isEqual(to: 1.0){
            finish()
        }
        else if progress < 1 && !self.activityIndicator.isAnimating{
            self.activityIndicator.startAnimating()
        }
    }
    
    func finish(){
        print("LoadingIndicatorViewController: finish()")
        if !self.isVisible{
            dismissWhenBecomesVisible = true
        }
        else {
            self.dismiss(animated: true, completion: complete)
        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let showCancelButton = delegate?.shouldShowCancelButton() ?? true
        self.cancelButton.isHidden = !showCancelButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if dismissWhenBecomesVisible {
            self.dismiss(animated: true, completion: complete)
            dismissWhenBecomesVisible = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - LoadingProgressDataSource
    var isLoadingInProgress: Bool = false
    
    func loadingProgressChanged(progress: Float) {
        isLoadingInProgress = true
        progressView.progress = progress
        let percentage: Int = Int(progress * 100)
        message = "\(percentage) % loaded"
    }
    
    func loadingFinished() {
        isLoadingInProgress = false
        dismiss(animated: true, completion: nil)
    }
}
