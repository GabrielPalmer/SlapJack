//
//  ViewBackground.swift
//  SlapJack
//
//  Created by Gabriel Blaine Palmer on 1/15/19.
//  Copyright © 2019 Gabriel Blaine Palmer. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func updateBackground(size: CGSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)) {
        
        let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        if size.height > size.width {
            imageViewBackground.image = UIImage(named: "verticalBackground")
        } else {
            imageViewBackground.image = UIImage(named: "horizontalBackground")
        }
        
        imageViewBackground.contentMode = UIView.ContentMode.scaleAspectFill
        self.addSubview(imageViewBackground)
        self.sendSubviewToBack(imageViewBackground)
    }
}
