//
//  ImageCollectionViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 23/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import PromiseKit

class ImageCollectionViewController: UICollectionViewController {
    
    private let reuseIdentifier = "imageCollectionViewCell"
    
    var movieId: Int?
    var images: [String: [UIImage]] = [:]
    var largeImages: [String: [UIImage]] = [:]

    var sectionTitles: [String]{
        return images.keys.map{ $0 }
    }
    
    lazy var api: TMDBApi = {
        return TMDBApi.shared
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        
        // Check if 3D Touch is available
        if traitCollection.forceTouchCapability == .available{
            print("3D touch is available")
            registerForPreviewing(with: self, sourceView: view)
        }
        else{
            print("3D Touch not available")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showImagePageController(startPageIdx: Int = 0){
        print("showImagePageController")
        var imageArray: [UIImage] = []
        for arr in images.values{
            imageArray += arr
        }
        instantiateImagePageViewController(images: imageArray, startPageIdx: startPageIdx)
    }
    
    func instantiateImagePageViewController(images: [UIImage], startPageIdx: Int = 0){
        if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePageViewController") as? ImagePageViewController{
            if !images.isEmpty{
                vc.images = images
                vc.startPageIdx = startPageIdx
                self.show(vc, sender: self)
            }
        }
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return images.keys.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                withReuseIdentifier: "ImageCollectionReusableView",
                for: indexPath) as! ImageCollectionReusableView
            
            if indexPath.section < sectionTitles.count{
                let header = sectionTitles[indexPath.section]
                headerView.label.text = header
                return headerView
            }
            
        default:
            break
        }
        return UICollectionReusableView()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionTitle = sectionTitles[section]
        return images[sectionTitle]?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        let sectionTitle = sectionTitles[indexPath.section]
        cell.configure(image: images[sectionTitle]?[indexPath.row])
        return cell
    }
    


    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionTitle = sectionTitles[indexPath.section]
        if let selectedImage = images[sectionTitle]?[indexPath.row]{
            if let index = images.values.reduce([], +).index(of: selectedImage){
                showImagePageController(startPageIdx: index)
            }
        }
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

// MARK: - UIViewControllerPreviewingDelegate
extension ImageCollectionViewController: UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let locationInCollectionView: CGPoint = collectionView?.convert(location, from: self.view) else {
            print("Location not in CollectionView")
            return nil
        }
        
        guard let indexPath = collectionView?.indexPathForItem(at: locationInCollectionView) else {
            print("No indexPath")
            return nil
        }
        
        guard let cell = collectionView?.cellForItem(at: indexPath) as? ImageCollectionViewCell else {
            print("No cell at indexPath: \(indexPath)")
            return nil
        }
        
        guard let image = cell.imageView.image else {
            print("No image in the cell")
            return nil
        }
        
        
        if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePreviewController") as? ImagePreviewController{
            previewingContext.sourceRect = self.view.convert(cell.frame, from: self.collectionView)
            
            vc.image = image
            vc.preferredContentSize = image.size
            return vc
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        guard !images.isEmpty else{
            return
        }
        
        if let imagePreviewController = viewControllerToCommit as? ImagePreviewController{
            if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePageViewController") as? ImagePageViewController{
                if let firstImage = imagePreviewController.image{
                    vc.images = images.values.reduce([], +)
                    vc.startPageIdx = vc.images.index(of: firstImage) ?? 0
                    
                    if vc.images.count > 0{
                        vc.preferredContentSize = CGSize(width: 0, height: 0)
                    }
                    
                    show(vc, sender: self)
                }

            }
        }
    }
}
