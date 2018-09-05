//
//  SignUpViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 08/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var authenticationStatusLabel: UILabel!
    
    lazy var ref: DatabaseReference = {
        return Database.database().reference()
    }()
    
    var signedIn: Bool = false{
        didSet{
            print("signedIn: \(signedIn)")
            if signedIn {
                showInitialViewController()
                NotificationCenter.default.post(name: Notifications.AuthorizationNotification.SignedIn.name, object: nil)
            }
            else {
                NotificationCenter.default.post(name: Notifications.AuthorizationNotification.SignedOut.name, object: nil)
            }
        }
    }
    
    func showInitialViewController(){
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        
        let initialViewController = self.storyboard!.instantiateViewController(withIdentifier: "initialTabBarController")
        appDelegate.window?.rootViewController = initialViewController
        appDelegate.window?.makeKeyAndVisible()
    }
    
    @IBAction func signUp(_ sender: Any) {
        createUser()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loadingIndicator = LoadingIndicatorViewController(title: "Signing in", message: nil, complete: nil)
        present(loadingIndicator, animated: true, completion: nil)
        
        if let user = Auth.auth().currentUser, let email = user.email{
            self.authenticationStatusLabel.text = "Signed in as \(email)"
            self.signedIn = true
            loadingIndicator.finish()
        }
        else{
            self.authenticationStatusLabel.text = "Signed out"
            self.signedIn = false
            loadingIndicator.finish()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func createUser(){
        if let email = emailTextField.text, let password = passwordTextField.text{
            Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                
                if let error = error{
                    self.authenticationStatusLabel.text = error.localizedDescription
                }
                
                if let user = user, let userEmail = user.email{
                    self.authenticationStatusLabel.text = "Signed in as \(userEmail)"
                    self.emailTextField.text = nil
                    self.passwordTextField.text = nil
                    self.signedIn = true
                    
                    // Add new user to Database
                    self.ref.child("users").child(user.uid).setValue(email)
                }
            }
        }
    }
    
    // TODO: Sign out
    func signOut(){
        do{
            try Auth.auth().signOut()
            signedIn = false
        }
        catch let error{
            print(error.localizedDescription)
        }
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
