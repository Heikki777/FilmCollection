//
//  ProfileViewController.swift
//  FilmCollection
//
//  Created by Heikki Hämälistö on 10/04/2018.
//  Copyright © 2018 Heikki Hämälistö. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import MessageUI

class ProfileViewController: UIViewController {

    let filmCollection = FilmCollection.shared
    
    @IBOutlet weak var profileLabel: UILabel!
    
    @IBAction func sendCollectionToEmail(_ sender: Any) {
        if let user = Auth.auth().currentUser, let userEmail = user.email{
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients([userEmail])
                
                let titles = filmCollection.getAllFilms().map { (film) -> String in
                    return "<p>\(film.titleYear)</p>"
                }.sorted().joined(separator: "")

                mail.setMessageBody(titles, isHTML: true)
                
                present(mail, animated: true)
            } else {
                // show failure alert
            }
        }

    }
    
    @IBAction func signOut(_ sender: Any) {
        do{
            try Auth.auth().signOut()
            let appDelegate = UIApplication.shared.delegate! as! AppDelegate
            
            let loginViewController = self.storyboard!.instantiateViewController(withIdentifier: "loginViewController")
            appDelegate.window?.rootViewController = loginViewController
            appDelegate.window?.makeKeyAndVisible()
        }
        catch let error{
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Auth.auth().currentUser, let email = user.email{
            self.profileLabel.text = "Signed in as \(email)"
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

extension ProfileViewController: MFMailComposeViewControllerDelegate{
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
