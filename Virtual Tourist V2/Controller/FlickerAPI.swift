//
//  FlickerAPI.swift
//  Virtual Tourist V2
//
//  Created by Norah Almaneea on 13/03/2021.
//

import Foundation
import CoreData
import MapKit

class FlickrAPI {
    
    static let sharedInstance = FlickrAPI()
    var session = URLSession.shared
    
    func getImagesFromFlickr(chosenPin: Pin, _ pageNumber: Int, _ completionHandler: @escaping (_ result: [Photo]?, _ error: NSError?) -> Void) {
        
        let methodParameters: [String:String] = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(longitude:chosenPin.lon , latitude: chosenPin.lat),
            Constants.FlickrParameterKeys.Latitude: "\(chosenPin.lat)",
            Constants.FlickrParameterKeys.Longitude: "\(chosenPin.lon)",
            Constants.FlickrParameterKeys.PerPage: "12",
            Constants.FlickrParameterKeys.Page: "\(pageNumber)",
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        let request = URLRequest(url: getURL(methodParameters))
        let task = taskForGETMethod(request: request) { (parsedResult, error) in
            
            func showError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            guard let stat = parsedResult?[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                showError("There is an error with Flickr API")
                return
            }
            guard let photosDictionary = parsedResult?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                showError("Cannot find the key")
                return
            }
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                showError("Cannot find the key")
                return
            }
            DispatchQueue.main.async {
                
                let context = DataController.shared.viewContext
                
                var imageUrlStrings = [Photo]()
                
                for url in photosArray {
                    guard let urlString = url[Constants.FlickrResponseKeys.MediumURL] as? String else {
                        showError("Cannot find the key")
                        return
                    }
                    let photo:Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context ) as! Photo
                    
                    photo.urlString = urlString
                    photo.pin = chosenPin
                    imageUrlStrings.append(photo)
                    try! DataController.shared.viewContext.save()

                }
                completionHandler(imageUrlStrings, nil)
            }
        }
        
        task.resume()
    }
    
    private func taskForGETMethod(request: URLRequest, _ completionHandlerForGET: @escaping(_ result: AnyObject?, _ error: NSError?) -> Void)-> URLSessionDataTask {
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func showError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                showError("There is an error with the request")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                showError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                showError("No data was returned by the request!")
                return
            }
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        task.resume()
        return task
    }
    
    func bboxString(longitude:Double, latitude:Double) -> String {

        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, -180)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, -90)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, 180)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, 90)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    func getDataFromUrl(_ urlString: String, _ completionHandler: @escaping (_ imageData: Data?, _ error: String?) -> Void) {
        
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completionHandler(nil, error?.localizedDescription)
                return
            }
            completionHandler(data, nil)
        }
        task.resume()
    }
    
    func getURL(_ parameters: [String:String]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
}

