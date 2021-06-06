//
//  Pages.swift
//  MyMapTest
//
//  Created by D02020015 on 2021/5/20.
//

import Foundation
import UIKit

struct Pages {
    static var mainStoryboard: UIStoryboard { UIStoryboard(name: "Main", bundle: nil) }
    
    static func mainViewController() -> MainViewController? {
        let mainViewController = mainStoryboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController
        if let vc = mainViewController {
            vc.isModalInPresentation = true
            vc.modalPresentationStyle = .fullScreen
            //vc.view.backgroundColor = .red
            
            // overrideUserInterfaceStyle is available with iOS 13
            if #available(iOS 13.0, *) {
                // Always adopt a light interface style.
                vc.overrideUserInterfaceStyle = .light
            }
        }
        return mainViewController
    }
    
    static func placesViewController() -> PlacesViewController? {
        let placesViewController = mainStoryboard.instantiateViewController(withIdentifier: "PlacesViewController") as? PlacesViewController
        if let vc = placesViewController {
            vc.isModalInPresentation = true
            vc.modalPresentationStyle = .fullScreen
            //vc.view.backgroundColor = .red
            
            // overrideUserInterfaceStyle is available with iOS 13
            if #available(iOS 13.0, *) {
                // Always adopt a light interface style.
                vc.overrideUserInterfaceStyle = .light
            }
        }
        return placesViewController
    }
    
}
