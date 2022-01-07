//
//  CustomButton.swift
//  QR2Pass
//  button with rounded corners (designable and inspectable)
//
//
//  Created by Yorwos Pallikaropoulos on 1/9/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import UIKit
import LocalAuthentication

@IBDesignable class CustomButton: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
     
     
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    

    @IBInspectable var borderWidth: CGFloat{
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
            
        }
    }
    @IBInspectable var borderColor: UIColor?{
        get {
            if let color = self.layer.borderColor{
                return UIColor(cgColor:color)
            }else{
                return nil
            }
            
        }
        set {
            self.layer.borderColor = newValue?.cgColor
           
        }
    }
    
        @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
            self.layer.masksToBounds = newValue > 0
        }
    }
}
