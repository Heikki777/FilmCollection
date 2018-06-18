//
//  ImagePageViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 01/02/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class ImagePageViewController: UIPageViewController {

    var images: MovieImages = MovieImages()
    var orderedViewControllers: [UIViewController] = []
    var startPageIdx: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        guard startPageIdx < images.all.count else{
            print("ImagePageViewController. startPageIdx is too big")
            return
        }
        
        for imageTuple in images.all{
            let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePreviewController") as! ImagePreviewController
            vc.image = imageTuple.image
            self.orderedViewControllers.append(vc)
        }
        
        let firstViewController = orderedViewControllers[startPageIdx]
        setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        
        dataSource = self
        
        setupPageControl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupPageControl() {
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.gray
        appearance.currentPageIndicatorTintColor = UIColor.white
        appearance.backgroundColor = UIColor.lightGray
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

extension ImagePageViewController: UIPageViewControllerDataSource{
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let index = orderedViewControllers.index(of: viewController) else{
            return nil
        }
        if index > 0{
            return orderedViewControllers[index-1]
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let index = orderedViewControllers.index(of: viewController) else{
            return nil
        }
        if index < orderedViewControllers.count - 1 {
            return orderedViewControllers[index+1]
        }
        return nil
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
