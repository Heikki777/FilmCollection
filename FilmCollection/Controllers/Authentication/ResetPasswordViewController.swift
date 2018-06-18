//
//  ResetPasswordViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 11/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ResetPasswordViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBAction func resetPassword(_ sender: Any) {
        
        if let email = emailTextField.text{
            Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                if let error = error{
                    self.statusLabel.text = error.localizedDescription
                }
                else{
                    self.statusLabel.text = "A password reset email has been sent to \(email)"
                }
            }
        }
        else{
            statusLabel.text = "Email address is missing"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusLabel.text = ""
        if let email = Auth.auth().currentUser?.email{
            emailTextField.text = email
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
