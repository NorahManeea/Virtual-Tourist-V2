//
//  PhotoResponse.swift
//  Virtual Tourist V2
//
//  Created by Norah Almaneea on 13/03/2021.
//

import Foundation

struct PhotoResponse: Codable {
    let photos: Photos
    let stat: String
}
struct Photos: Codable {
    let page, pages, perpage: Int
    let total: String
    let photo: [PhotoParse]
}
struct PhotoParse: Codable {
    let id: String
    let url_m: String
}


