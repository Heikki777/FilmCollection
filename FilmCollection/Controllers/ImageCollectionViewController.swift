//
//  ImageCollectionViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 23/03/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit

class ImageCollectionViewController: UICollectionViewController {
    
    private let reuseIdentifier = "imageCollectionViewCell"
    
    var movieId: Int?
    var sections: [String] = []
    var imageUrls: [String: [URL]] = [:] {
        didSet {
            sections = Array(imageUrls.keys).sorted().reversed()
            collectionView?.reloadData()
        }
    }
    var largeImages: [String: [URL]] = [:]

    var sectionTitles: [String]{
        return imageUrls.keys.map{ $0 }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        
        // Check if 3D Touch is available
        if traitCollection.forceTouchCapability == .available{
            registerForPreviewing(with: self, sourceView: view)
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
        var imageArray: [URL] = []
        for arr in imageUrls.values{
            imageArray += arr
        }
        performSegue(withIdentifier: Segue.showImagePageViewControllerSegue.rawValue, sender: (images: imageArray, startPageIdx: startPageIdx))
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageVC = segue.destination as? ImagePageViewController, let senderTuple = sender as? (images: [URL], startPageIdx: Int){
            pageVC.images = senderTuple.images
            pageVC.startPageIdx = senderTuple.startPageIdx
        }
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return imageUrls.keys.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
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
        return imageUrls[sectionTitle]?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        let sectionTitle = sectionTitles[indexPath.section]
        cell.configure(imageUrl: imageUrls[sectionTitle]?[indexPath.row])
        return cell
    }
    
    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionTitle = sectionTitles[indexPath.section]
        if let selectedImage = imageUrls[sectionTitle]?[indexPath.row]{
            if let index = imageUrls.values.reduce([], +).index(of: selectedImage){
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
            return nil
        }
        
        guard let indexPath = collectionView?.indexPathForItem(at: locationInCollectionView) else {
            return nil
        }
        
        guard let cell = collectionView?.cellForItem(at: indexPath) as? ImageCollectionViewCell else {
            return nil
        }
        
        let section = sections[indexPath.section]
        guard let imageUrl = imageUrls[section]?[indexPath.row] else {
            return nil
        }
        
        
        if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePreviewController") as? ImagePreviewController{
            previewingContext.sourceRect = self.view.convert(cell.frame, from: self.collectionView)
            
            vc.imageUrl = imageUrl
            vc.preferredContentSize = self.view.frame.size
            return vc
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        guard !imageUrls.isEmpty else{
            return
        }
        
        if let imagePreviewController = viewControllerToCommit as? ImagePreviewController{
            if let vc = self.storyboard!.instantiateViewController(withIdentifier: "ImagePageViewController") as? ImagePageViewController{
                if let firstImage = imagePreviewController.imageUrl {
                    vc.images = imageUrls.values.reduce([], +)
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
