//
//  ViewController.swift
//  Virtual Tourist V2
//
//  Created by Norah Almaneea on 13/03/2021.
//


import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var vMap: MKMapView!
    @IBOutlet weak var pinsToEditView: UIView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    var chosenPin: Pin!
    var currentPage = 0
    var photos : [Photo] = [Photo]()
    var deleteAll = false
    var selectedIndexes = [NSIndexPath]()
    
    var context: NSManagedObjectContext {
        return DataController.shared.viewContext
    }

    fileprivate func setUpFetchedResultsController() {
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            updateVmap()
        } catch {
            fatalError("The fetch couldn't be performed: \(error.localizedDescription)")
        }
    }
    // MARK:Life cycles methods:
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Virtual Tourist"
        navigationItem.rightBarButtonItem = editButtonItem
        pinsToEditView.isHidden = true
        vMap.delegate = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
//
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        pinsToEditView.isHidden = !editing

    }
    
    @IBAction func thisPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began { return }
            
            let pinLocation = sender.location(in: vMap)
            let pin = Pin(context: context)
            pin.coordinate = vMap.convert(pinLocation, toCoordinateFrom: vMap)
            try? context.save()
    
        }
    
    func updateVmap() {
        guard let pins = fetchedResultsController.fetchedObjects else { return }
        for pin in pins {
            if vMap.annotations.contains(where: {pin.compare(to: $0.coordinate)}) { continue }
            let annotation = MKPointAnnotation()
            annotation.coordinate = pin.coordinate
            vMap.addAnnotation(annotation)
        }
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "photosSegue" {
        let controller = segue.destination as! PhotoViewController
        controller.chosenPin = sender as? Pin
    }
}
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
       
        let pin = fetchedResultsController.fetchedObjects?.filter { $0.compare(to: view.annotation!.coordinate)}.first!
        let lon = view.annotation?.coordinate.longitude
        let lat = view.annotation?.coordinate.latitude
        guard let annotation = view.annotation else {
            return
        }
        if pin!.lat == lat, pin!.lon == lon{
            if isEditing {
                vMap.removeAnnotation(annotation)
                context.delete(pin!)
                try! context.save()
                return
            }
        performSegue(withIdentifier: "photosSegue", sender: pin)
    }
    }
   
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateVmap()
    }
}


