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
        guard let authorizeURL = URL(string: ""),
            let tokenURL = URL(string: ""),
            var logoutURL = URL(string: "") else {
            log(text: "Please check the configuration parameters!")
            return nil
        }
//        var issuerURL = URL(string: ""),
//        var registrationURL = URL(string: ""),
        return OIDServiceConfiguration(authorizationEndpoint: authorizeURL, tokenEndpoint: tokenURL, issuer: nil, registrationEndpoint: nil, endSessionEndpoint: logoutURL)
    }()
    
    private let clientId = ""
    private let authorizeScopes: [String] = []
    private let clientSecret: String? = nil
    private let redirectURL = URL(string: "")
    private let authorizeParameters: [String: String]? = [:]
    private let tokenParameters: [String: String]? = nil
    private static var currentAuthorizeFlow: OIDExternalUserAgentSession?
    private var authorizationState: OIDAuthState? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logTextView.text = ""
        loadState()
        updateStatusText()
    }
    
    @IBAction func doAuthorize(_ sender: Any) {
        guard let redirectURL = redirectURL else {
            log(text: "Check configuration: no redirect URI defined")
            return
        }
        let authorizeRequest = OIDAuthorizationRequest(configuration: config, clientId: clientId, scopes: authorizeScopes, redirectURL: redirectURL, responseType: OIDResponseTypeCode, additionalParameters: authorizeParameters)
        ViewController.currentAuthorizeFlow = OIDAuthorizationService.present(authorizeRequest, presenting: self, callback: { (response, error) in
            // current authorization flow has ended
            ViewController.currentAuthorizeFlow = nil
            // check authorization flow status
            if let authorizeResponse = response {
                self.authorizationState = OIDAuthState(authorizationResponse: authorizeResponse)
                self.saveState()
                self.log(text: "Authorization with success")
            }
            else {
                self.clearState()
                self.log(text: error?.localizedDescription ?? "Unknown error")
            }
            self.updateStatusText()
        })
    }
    
    static func process(redirectURL: URL) -> Bool {
        if let authorizeFlow = self.currentAuthorizeFlow {
            self.currentAuthorizeFlow = nil
            return authorizeFlow.resumeExternalUserAgentFlow(with: redirectURL)
        }
        return false
    }
    
    @IBAction func doTokenRequest(_ sender: Any) {
        guard let lastAuthroizationResponse = self.authorizationState?.lastAuthorizationResponse else {
            return
        }
        guard let tokenRequest = lastAuthroizationResponse.tokenExchangeRequest(withAdditionalParameters: tokenParameters) else {
            return
        }
        OIDAuthorizationService.perform(tokenRequest) { (response, error) in
            self.authorizationState?.update(with: response, error: error)
            if let _ = response {
                self.saveState()
                self.log(text: "Token request with success")
            }
            else {
                self.clearState()
                self.log(text: error?.localizedDescription ?? "Unknown error")
            }
            self.updateStatusText()
        }
    }
    
    @IBAction func doRefreshToken(_ sender: Any) {
        if let state = self.authorizationState {
            state.setNeedsTokenRefresh()
            state.performAction(freshTokens: { (accessToken, idToken, error) in
                if accessToken?.count ?? 0 > 0 || idToken?.count ?? 0 > 0 {
                    self.log(text: "Refreshed tokens")
                }
                else {
                    self.log(text: "Couldn't refresh tokens")
                }
            })
        }
        else {
            log(text: "Cannot refresh tokens: no authroization state")
        }
    }
    
    @IBAction func doLogout(_ sender: Any) {
        guard let redirectURL = redirectURL else {
            log(text: "Check config: logout redirect url not present")
            return
        }
        guard let agent = OIDExternalUserAgentIOS(presenting: self) else {
            log(text: "Error generating external user agent")
            return
        }
        let logoutParams: [String: String]? = nil
        let logoutRequest = OIDEndSessionRequest(configuration: config, idTokenHint: "hint?", postLogoutRedirectURL: redirectURL, additionalParameters: logoutParams)
        OIDAuthorizationService.present(logoutRequest, externalUserAgent: agent) { (response, error) in
            if let _ = response {
                self.clearState()
            }
            else {
                self.log(text: error?.localizedDescription ?? "Unknown error")
            }
            self.updateStatusText()
        }
    }
    
    @IBAction func doRefreshStatus(_ sender: Any) {
        updateStatusText()
    }
    
    private func updateStatusText() {
        if authorizationState?.isAuthorized ?? false {
            statusLabel.text = "Authorized"
        }
        else {
            statusLabel.text = "Not authorized"
        }
    }
    
    private func clearState() {
        let keychain = KeychainSwift()
        keychain.delete("openid.state")
        authorizationState = nil
    }
    
    private func saveState() {
        let keychain = KeychainSwift()
        if let state = self.authorizationState,
            let dataObject = try? NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: true) {
            keychain.set(dataObject, forKey: "openid.state")
            log(text: "Saved authroize state")
        }
        else {
            keychain.delete("openid.state")
            log(text: "Couldn't save authroize state")
        }
    }
    
    private func loadState() {
        let keychain = KeychainSwift()
        if let dataObject = keychain.getData("openid.state"),
            let codedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: dataObject) {
            self.authorizationState = codedObject
            log(text: "Restored authroize state")
        }
        else {
            log(text: "Couldn't restore authroize state")
        }
    }
    
    private func log(text: String) {
        logTextView.text = text + "\n" + logTextView.text
    }
}

