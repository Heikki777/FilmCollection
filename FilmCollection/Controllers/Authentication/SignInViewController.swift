//
//  SignInViewController
//  FilmCollection
//
//  Created by Heikki Hämälistö on 08/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var authenticationStatusLabel: UILabel!
    
    var signedIn: Bool = false{
        didSet{
            if signedIn{
                showInitialViewController()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let user = Auth.auth().currentUser, let email = user.email{
            self.authenticationStatusLabel.text = "Signed in as \(email)"
            signedIn = true
        }
        else{
            self.authenticationStatusLabel.text = "Signed out"
            signedIn = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func createUser(){
        if let email = emailTextField.text, let password = emailTextField.text{
            Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                
                if let error = error{
                    self.authenticationStatusLabel.text = error.localizedDescription
                }
                
                if let user = user, let userEmail = user.email{
                    self.authenticationStatusLabel.text = "Signed in as \(userEmail)"
                    self.emailTextField.text = nil
                    self.passwordTextField.text = nil
                    self.signedIn = true
                }
            }
        }
    }
    
    func showInitialViewController(){
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        
        let initialViewController = self.storyboard!.instantiateViewController(withIdentifier: "initialTabBarController")
        appDelegate.window?.rootViewController = initialViewController
        appDelegate.window?.makeKeyAndVisible()
    }
    
    @IBAction func signIn(_ sender: Any) {
        if let email = emailTextField.text, let password = passwordTextField.text {
            // TODO: Add loading indicator that shows the following message: "Signing in"
            
            let loadingIndicator = LoadingIndicatorViewController(title: "Signing in", message: nil, complete: nil)
            present(loadingIndicator, animated: true, completion: nil)
            
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                
                if let error = error{
                    print(error)
                    self.authenticationStatusLabel.text = error.localizedDescription
                }
                
                if let user = user, let userEmail = user.email{
                    self.authenticationStatusLabel.text = "Signed in as \(userEmail)"
                    self.emailTextField.text = nil
                    self.passwordTextField.text = nil
                    self.signedIn = true
                }
                
                loadingIndicator.finish()
            }
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
