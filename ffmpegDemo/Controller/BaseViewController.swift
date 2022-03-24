// ffmpegDemo
//
// Created by ffmpegDemo on 14/03/22.
// Copyright © 2021 ffmpegDemo. All rights reserved.
//

import UIKit

// Base viewcontroller class , will use for alll viewcontroller as base controller
class BaseViewController: UIViewController {
        
    //MARK: Controllers override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        debugPrint("Class name ==> %@", self)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
            
    }
    
    func showAlertSuccess(complition: @escaping (() -> Void)) {
        UIAlertController.showAlertWithOkButton(controller: self, message: "Saved.") { _, _ in
            complition()
        }
    }
    
    func showAlertCancel() {
        UIAlertController.showAlertWithOkButton(controller: self, message: "Command execution cancelled by user..") { _, _ in
        }
    }
    
    func showAlertError() {
        UIAlertController.showAlertWithOkButton(controller: self, message: "Command failed. Please check output for the details.") { _, _ in
        }
    }

}
