//
//  PhotoViewController.swift
//  Virtual Tourist V2
//
//  Created by Norah Almaneea on 13/03/2021.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var photoAlbumCollection: UICollectionView!
    @IBOutlet weak var collectionButton: UIButton!
    @IBOutlet weak var indicatorIcon: UIActivityIndicatorView!
    @IBOutlet weak var theLabel: UILabel!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var chosenPin: Pin!
    var currentPage = 0
    var photos : [Photo] = [Photo]()
    var deleteAll = false
    var selectedIndexes = [NSIndexPath]()
    
    var context: NSManagedObjectContext {
        return DataController.shared.viewContext
    }
        
    var areTherePhotos: Bool {
        return (fetchedResultsController.fetchedObjects?.count ?? 0) != 0
    }
    
    //Life Cycles:
    override func viewDidLoad() {
        super.viewDidLoad()
        theLabel.isHidden = true
        setupFetchedResultController()
      
}
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func setupFetchedResultController() {
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", chosenPin)
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            if areTherePhotos {
            updateTheUI(processing: false)
            }else {
                newCollectionButton(self)
            }
        } catch {
            fatalError("The fetch couldn't be performed: \(error.localizedDescription)")
        }
    }
    
    func displayAlert(title:String, message:String?) {
        
        if let message = message {
            let alert = UIAlertController(title: title, message: "\(message)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Add New Collection Button
    @IBAction func newCollectionButton(_ sender: Any) {
        
        updateTheUI(processing: true)
        if areTherePhotos {
            deleteAll = true
            for photo in fetchedResultsController.fetchedObjects! {
            context.delete(photo)
            }
            try? context.save()
            deleteAll = false
        }
        
        FlickrAPI.sharedInstance.getImagesFromFlickr(chosenPin: chosenPin, currentPage) { (results, error) in
            
            self.updateTheUI(processing: false)
            guard error == nil else {
                self.displayAlert(title: "Unable to get photos", message: error?.localizedDescription)
                return
            }
            if results!.isEmpty {
                self.theLabel.isHidden = false
                return
            }
            DispatchQueue.main.async {
                if results != nil {
                self.photos = results!
                try? self.context.save()
                }
            }
        }
        currentPage += 1
    }
    
    func updateTheUI(processing: Bool){
        photoAlbumCollection.isUserInteractionEnabled = !processing
        if processing {
            //collectionButton.title = ""
            indicatorIcon.startAnimating()
            indicatorIcon.isHidden = false
        }else{
            //collectionButton.title = "New Collection"
            indicatorIcon.stopAnimating()
            indicatorIcon.isHidden = true
        }
    }
    // MARK:NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let indexPath = indexPath, type == .delete && !deleteAll{
            photoAlbumCollection.deleteItems(at: [indexPath])
            return
        }
        if let indexPath = indexPath, type == .insert {
            photoAlbumCollection.insertItems(at: [indexPath])
            return
        }
        
        if type != .update {
            photoAlbumCollection.reloadData()
        }
    }

    // MARK:UICollectionViewDataSource, UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath)
        cell.activityInd.startAnimating()
        
        if photo.imageData != nil {
            DispatchQueue.main.async {
                cell.activityInd.stopAnimating()
                cell.activityInd.isHidden = true

            }
            cell.image.image = UIImage(data: photo.imageData! as Data)
        } else {
            
            FlickrAPI.sharedInstance.getDataFromUrl(photo.urlString!) { (results, error) in
                guard let imageData = results else {
                    self.displayAlert(title: "Image data error", message: error)
                    return
                }
                DispatchQueue.main.async {
                    photo.imageData = imageData as Data?
                    cell.activityInd.stopAnimating()
                    cell.activityInd.isHidden = true
                    cell.image.image = UIImage(data: photo.imageData! as Data)
                }
            }
        }
        
        if selectedIndexes.firstIndex(of: indexPath as NSIndexPath) != nil {
            cell.image.alpha = 0.25
        } else {
            cell.image.alpha = 1.0
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        context.delete(photo)
        try? context.save()
    }
    
    
    // MARK:UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (photoAlbumCollection.frame.width-30) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
}



