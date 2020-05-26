//
//  ViewController.swift
//  OpenId
//
//  Created by Eduard Nita on 18/05/2020.
//

import UIKit
import AppAuth
import KeychainSwift

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var logTextView: UITextView!
        
    lazy var config: OIDServiceConfiguration! = {
            let issuerURL = URL(string: ""),
            let registrationURL = URL(string: ""),
        guard let authorizeURL = URL(string: "https://saml.pre.coop.dk/nidp/oauth/nam/authz"),
            let tokenURL = URL(string: "https://saml.pre.coop.dk/nidp/oauth/nam/token"),
            var logoutURL = URL(string: "https://saml.pre.coop.dk/nidp/app/logout") else {
            return nil
        }
        return OIDServiceConfiguration(authorizationEndpoint: authorizeURL, tokenEndpoint: tokenURL, issuer: issuerURL, registrationEndpoint: registrationURL, endSessionEndpoint: logoutURL)
    }()
    
    let clientSecret: String? = nil
    private let clientId = "9d3bf844-ff98-4a82-8803-6e05b316c9b4"
    private let authorizeScopes = ["oic"]
    private let redirectURL = URL(string: "coop://dk.bridgeit.coop.employeeapp/")
    private let authorizeParameters: [String: String]? = [
      "acr_values" : "http://coop/level2a",
      "resourceServer" : "COOPIdentityProvider"
    ]
    private let tokenParameters: [String: String]? = [
        "resourceServer" : "COOPIdentityProvider"
    ]
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

