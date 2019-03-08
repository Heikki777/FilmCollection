//
//  RatingControl.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 1.2.2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

@IBDesignable
class RatingControl: UIControl {
    
    let maxRating: Int = 7
    
    var rating: Rating = .NotRated{
        didSet{
            if let delegate = ratingControlDelegate{
                delegate.ratingChanged(newRating: rating)
            }
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var itemBackgroundColor: UIColor! = .gray{
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var itemSize: CGFloat = 16{
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var spacing: CGFloat = 16{
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var alignment: UIControl.ContentHorizontalAlignment = .center
    
    weak var ratingControlDelegate: RatingControlDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit(){
        // Tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(tapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tapGestureRecognizer)
        
        // Pan gesture recognizer
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action: #selector(panned))
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        clipsToBounds = true
        
        var xStart: CGFloat = spacing
        let totalWidthOfBalls = CGFloat(maxRating) * itemSize
        let totalWidthOfSpaces = CGFloat(maxRating + 1) * spacing
        if alignment == .center{
            xStart = (rect.width - (totalWidthOfBalls + totalWidthOfSpaces)) / 2
            xStart += spacing
        }
        else if alignment == .left{
            xStart = spacing
        }
        else if alignment == .right{
            xStart = rect.width - (totalWidthOfSpaces + totalWidthOfBalls)
        }
        for i in 0..<maxRating{
            let index: CGFloat = CGFloat(i)
            let origin: CGPoint = CGPoint.init(x: xStart + (index * (itemSize+spacing)), y: (rect.size.height/2 - (itemSize/2)))
            let star = UIView.init(frame: CGRect.init(origin: origin, size: CGSize.init(width: itemSize, height: itemSize)))
            star.layer.cornerRadius = itemSize/2
            star.clipsToBounds = true
            star.backgroundColor = itemBackgroundColor
            if i < self.rating.rawValue{
                star.backgroundColor = self.tintColor
            }
            self.addSubview(star)
        }
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer){
        let location = sender.location(in: self)
        var i: Int = 1
        for ball in self.subviews{
            if ball.frame.contains(location){
                if let rating = Rating(rawValue: i){
                    self.rating = rating
                }
                return
            }
            i += 1
        }
        
        if let firstBall = self.subviews.first{
            if location.x < firstBall.frame.minX{
                self.rating = .NotRated
            }
        }
    }
    
    @objc func panned(_ sender: UIPanGestureRecognizer){
        let location = sender.location(in: self)
        var i: Int = 1
        for ball in self.subviews{
            if ball.frame.contains(location){
                if let rating = Rating(rawValue: i){
                    self.rating = rating
                }
                return
            }
            i += 1
        }
        
        if let firstBall = self.subviews.first{
            if location.x < firstBall.frame.minX{
                self.rating = .NotRated
            }
        }
    }
}
