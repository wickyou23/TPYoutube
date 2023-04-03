//
//  TPYTAuthManager.swift
//  TPYoutube
//
//  Created by Thang Phung on 22/02/2023.
//

import Foundation
import GTMAppAuth
import AppAuth
import Combine

private let kURLAuth = "https://accounts.google.com"
private let kGTMAppAuthExampleAuthorizerKey = "TPYoutubeAuthorizerKey"
private let kGoogleScopes = ["profile"]
private let kYoutubeScopes = [
    "https://www.googleapis.com/auth/youtube",
    "https://www.googleapis.com/auth/youtube.channel-memberships.creator",
    "https://www.googleapis.com/auth/youtube.force-ssl",
    "https://www.googleapis.com/auth/youtube.readonly",
    "https://www.googleapis.com/auth/youtube.upload",
    "https://www.googleapis.com/auth/youtubepartner",
    "https://www.googleapis.com/auth/youtubepartner-channel-audit"
]

enum TPYTAuthManagerState {
    case unAuthorized, processing, authorized
}

class TPGGAuthManager: NSObject, ObservableObject {
    static let shared = TPGGAuthManager()
    
    @Published private(set) var state: TPYTAuthManagerState = .unAuthorized
    @Published private(set) var profile: TPGGProfile?
    
    private(set) var authorization: GTMAppAuthFetcherAuthorization?
    private(set) var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private(set) var externalUserAgent: OIDExternalUserAgentIOS!
    
    private var myProfileSubscriptions: AnyCancellable?
    
    func checkSession() {
        if let authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: kGTMAppAuthExampleAuthorizerKey) {
            iLog("Access token: \(authorization.authState.lastTokenResponse?.accessToken ?? "Not Found")")
            self.authorization = authorization
            self.authorization?.authState.stateChangeDelegate = self
            self.state = .authorized
            
            if let ggProfile = TPStorageManager.gg.getProfile() {
                self.profile = ggProfile
            }
            
            //Get my profile
            getProfile()
        }
    }
    
    func loginWithYoutubeAccount() {
        self.state = .processing
        guard let authorizationEndpoint = URL(string: kURLAuth),
              let urlScheme = URL(string: AppViewModel.appKeys.authURLScheme) else {
            self.state = .unAuthorized
            return
        }
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: authorizationEndpoint) {
            [unowned self] configuration, error in
            guard let configuration = configuration else {
                eLog("\(error?.localizedDescription ?? "Unknown")")
                DispatchQueue.main.async {
                    [unowned self] in
                    self.state = .unAuthorized
                }
                
                return
            }
            
            guard let presentingVC = UIApplication.topMostController() else {
                eLog("presentingVC not found")
                DispatchQueue.main.async {
                    [unowned self] in
                    self.state = .unAuthorized
                }
                
                return
            }
            
            let request = OIDAuthorizationRequest(configuration: configuration,
                                                  clientId: AppViewModel.appKeys.clientID,
                                                  scopes: kYoutubeScopes + kGoogleScopes,
                                                  redirectURL: urlScheme,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)
            self.externalUserAgent = OIDExternalUserAgentIOS(presenting: presentingVC)
            self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                                   externalUserAgent: self.externalUserAgent) {
                [unowned self] authState, error in
                if let error = error {
                    eLog(error.localizedDescription)
                    self.authorization = nil
                    self.externalUserAgent = nil
                    self.currentAuthorizationFlow = nil
                    DispatchQueue.main.async {
                        [unowned self] in
                        self.state = .unAuthorized
                    }
                    
                    return
                }
                
                guard let authState = authState else {
                    eLog("authState not found")
                    self.authorization = nil
                    self.externalUserAgent = nil
                    DispatchQueue.main.async {
                        [unowned self] in
                        self.state = .unAuthorized
                    }
                    
                    return
                }
                
                sLog("Access token: \(authState.lastTokenResponse?.accessToken ?? "Not Found")")
                self.authorization = GTMAppAuthFetcherAuthorization(authState: authState)
                self.authorization?.authState.stateChangeDelegate = self
                self.externalUserAgent = nil
                self.currentAuthorizationFlow = nil
                
                //Save to keychain
                GTMAppAuthFetcherAuthorization.save(self.authorization!,
                                                    toKeychainForName: kGTMAppAuthExampleAuthorizerKey)
                
                DispatchQueue.main.async {
                    [unowned self] in
                    self.state = .authorized
                }
                
                //Get profile
                self.getProfile()
            }
        }
    }
    
    func verifyCallBack(url: URL) -> Bool {
        guard let mCurrentAuthorizationFlow = self.currentAuthorizationFlow else {
            eLog("currentAuthorizationFlow not found")
            return false
        }
        
        if mCurrentAuthorizationFlow.resumeExternalUserAgentFlow(with: url) {
            self.currentAuthorizationFlow = nil
            return true
        }
        
        eLog("verifyCallBack failed")
        return false
    }
    
    func refreshYoutubeToken(_ completion: @escaping ((Bool) -> Void)) {
        guard let authorization = self.authorization,
        let request = authorization.authState.tokenRefreshRequest() else {
            completion(false)
            return
        }
        
        OIDAuthorizationService.perform(request, originalAuthorizationResponse: authorization.authState.lastAuthorizationResponse) {
            newResponse, error in
            if let error = error {
                eLog(error.localizedDescription)
                completion(false)
                return
            }
            
            sLog(String(describing: newResponse))
            authorization.authState.update(with: newResponse, error: nil)
            GTMAppAuthFetcherAuthorization.save(authorization,
                                                toKeychainForName: kGTMAppAuthExampleAuthorizerKey)
            completion(true)
        }
    }
    
    func logout() {
        GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: kGTMAppAuthExampleAuthorizerKey)
        authorization = nil
        DispatchQueue.main.async {
            [unowned self] in
            state = .unAuthorized
        }
    }
    
    private func getProfile() {
        guard let _ = self.authorization else { return }
        myProfileSubscriptions?.cancel()
        myProfileSubscriptions = nil
        myProfileSubscriptions = TPYTAPIManager.ggService.getMyProfile()
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                eLog(error.localizedDescription)
            } receiveValue: { value in
                sLog(value)
                TPStorageManager.gg.saveProfile(profile: value)
                DispatchQueue.main.async {
                    [weak self] in
                    self?.profile = value
                }
            }
    }
}

extension TPGGAuthManager: OIDAuthStateChangeDelegate {
    func didChange(_ state: OIDAuthState) {
        guard let authorization = self.authorization else {
            return
        }
        
        sLog(state.isAuthorized)
        GTMAppAuthFetcherAuthorization.save(authorization,
                                            toKeychainForName: kGTMAppAuthExampleAuthorizerKey)
    }
}
