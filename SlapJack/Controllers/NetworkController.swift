//
//  NetworkController.swift
//  SlapJack
//
//  Created by Gabriel Blaine Palmer on 1/15/19.
//  Copyright © 2019 Gabriel Blaine Palmer. All rights reserved.
//

import Foundation

class NetworkController {
    static func performNetworkRequest(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                print("There was a problem fetching data")
                print(error as Any)
            }
            
            completion(data, error)
            
            }.resume()
    }
}
