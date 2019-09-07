//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    //MARK: OUTLETS
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    //MARK: ACTIONS
    @IBAction func loginTapped(_ sender: UIButton) {
        setloggIn(true)
        TMDBClient.getRequestToken(completionHandler: handleResponseToken(success:error:))
    }
    
    @IBAction func loginViaWebsiteTapped() {
        setloggIn(true)
        TMDBClient.getRequestToken { (success, error) in
            if success {
                    UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil)
            }
        }
    }
    
    //MARK: HANDLERS
    func handleResponseToken(success: Bool, error: Error?) {
        setloggIn(false)
        if success{
                TMDBClient.login(username: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completion: self.handleLoginResponse(success:error:))
        }else{
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    
    func handleLoginResponse(success:Bool, error: Error?){
        if success{
            TMDBClient.sessionResponse(completionHandler: handleSessionResponse(success:error:))
        }else{
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    
    func handleSessionResponse(success:Bool, error:Error?) {
        if success{
                self.performSegue(withIdentifier: "completeLogin", sender: nil)
        }else{
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    func setloggIn(_ loggin:Bool) {
        if loggin{
            activityIndicator.startAnimating()
        }else{
            activityIndicator.stopAnimating()
            emailTextField.isEnabled = !loggin
            passwordTextField.isEnabled = !loggin
            loginButton.isEnabled = !loggin
            loginViaWebsiteButton.isEnabled = !loggin
        }
    }
    
    func showLoginFailure(message: String) {
        let alertVC = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
}
