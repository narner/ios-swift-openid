//
//  ViewController.swift
//  OpenId
//
//  Created by Eduard Nita on 18/05/2020.
//

import UIKit
import AppAuth

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var logTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    lazy var config: OIDServiceConfiguration! = {
        guard let authorizeURL = URL(string: ""),
            let tokenURL = URL(string: ""),
            let issuerURL = URL(string: ""),
            let registrationURL = URL(string: ""),
            let logoutURL = URL(string: "") else {
            return nil
        }
        return OIDServiceConfiguration(authorizationEndpoint: authorizeURL, tokenEndpoint: tokenURL, issuer: issuerURL, registrationEndpoint: registrationURL, endSessionEndpoint: logoutURL)
    }()
    
    let clientId = ""
    let clientSecret: String? = nil
    let redirectURL = URL(string: "")
    let authorizeParameters: [String: String]? = nil
    var currentAuthorizeFlow: OIDExternalUserAgentSession?

    @IBAction func doAuthorize(_ sender: Any) {
        guard let redirectURL = redirectURL else {
            return
        }
        let authorizeRequest = OIDAuthorizationRequest(configuration: config, clientId: clientId, scopes: nil, redirectURL: redirectURL, responseType: OIDResponseTypeCode, additionalParameters: authorizeParameters)
        currentAuthorizeFlow = OIDAuthorizationService.present(authorizeRequest, presenting: self, callback: { (response, error) in
            
            self.currentAuthorizeFlow = nil
            if let error = error {
                self.log(text: error.localizedDescription)
            }
            else {
                self.log(text: "Authorization with success")
            }
        })
    }
    
    @IBAction func toTokenRequest(_ sender: Any) {
    }
    
    @IBAction func doRefresh(_ sender: Any) {
    }
    
    @IBAction func doLogout(_ sender: Any) {
    }
    
    @IBAction func doRefreshStatus(_ sender: Any) {
    }
    
    private func log(text: String) {
        logTextView.text = text + "\n" + logTextView.text
    }
}

