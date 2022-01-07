//
//  UIStoryBoardSegueWithCompletion.swift
//  QR2Pass
//  override UIStoryboardSegue to provide a completion closure
//  Created by Yorwos Pallikaropoulos on 12/4/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import UIKit

class UIStoryBoardSegueWithCompletion: UIStoryboardSegue {
    var completion: (() -> Void)?


    override func perform() {
        super.perform()
        if let completion = completion {
            completion()
        }
    }
}
