//
//  ViewController.swift
//  Previewtify
//
//  Created by Samuel Folledo on 9/9/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import SpotifyWebAPI
import UIKit
import Combine

class ViewController: UIViewController {
    let spotify = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowManager(
            clientId: "bdc47862fa334584bc6b0d0b5f05f550", clientSecret: "863bd0e110e840668d34fea610498b8d"
        )
    )
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var isAuthed: Bool = false
    private var currentAuthURL: Optional<URL> = Optional.none
    private lazy var connectLabel: UILabel = {
        let label = UILabel()
        label.text = "Connect your Spotify account"
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor(red:(29.0 / 255.0), green:(185.0 / 255.0), blue:(84.0 / 255.0), alpha:1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var connectButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red:(29.0 / 255.0), green:(185.0 / 255.0), blue:(84.0 / 255.0), alpha:1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 11.75, left: 32.0, bottom: 11.75, right: 32.0)
        button.layer.cornerRadius = 20.0
        button.setTitle("Continue with Spotify", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.sizeToFit()
        button.addTarget(self, action: #selector(didTapConnect(_:)), for: .touchUpInside)
        return button
    }()
    private lazy var disconnectButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red:(29.0 / 255.0), green:(185.0 / 255.0), blue:(84.0 / 255.0), alpha:1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 11.75, left: 32.0, bottom: 11.75, right: 32.0)
        button.layer.cornerRadius = 20.0
        button.setTitle("Sign out", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.sizeToFit()
        button.addTarget(self, action: #selector(didTapDisconnect(_:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateViewBasedOnConnected()
    }
    
    //MARK: Methods
    func setupViews() {
        view.backgroundColor = UIColor.white
        view.addSubview(connectLabel)
        view.addSubview(connectButton)
        view.addSubview(disconnectButton)
        let constant: CGFloat = 16.0
        connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        connectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        disconnectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        disconnectButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        connectLabel.centerXAnchor.constraint(equalTo: connectButton.centerXAnchor).isActive = true
        connectLabel.bottomAnchor.constraint(equalTo: connectButton.topAnchor, constant: -constant).isActive = true
        updateViewBasedOnConnected()
        
        spotify.setupDebugging()
    }
    
    func updateViewBasedOnConnected() {
        if isAuthed {
            connectButton.isHidden = true
            disconnectButton.isHidden = false
            connectLabel.isHidden = true
            createPlaylistAPICall()
        } else { //show login
            disconnectButton.isHidden = true
            connectButton.isHidden = false
            connectLabel.isHidden = false
        }
    }
    
    @objc func didTapDisconnect(_ button: UIButton) {
        if isAuthed {
            self.disconnect()
        }
    }
    
    func disconnect() {
        // TODO
    }
    
    @objc func didTapConnect(_ button: UIButton) {
        // make the url
        let url = spotify.authorizationManager.makeAuthorizationURL(
            redirectURI: URL(string: "musings://login-callback")!,
            showDialog: true,
            scopes: [
                .playlistModifyPublic,
                .playlistModifyPrivate,
            ]
        )!
        
        // show the url to the user
        currentAuthURL = Optional.some(url)
        UIApplication.shared.open(url)
    }
    
    public func checkScopes(_ url: URL) {
        spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url
        )
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("ok")
                self.isAuthed = true
            case .failure(let error):
                if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                    print("denied auth request")
                } else {
                    print("couldn't auth user: \(error)")
                }
            }
        })
        .store(in: &cancellables)
    }
    
    
    // MARK: - Private Helpers
    
    private func presentAlertController(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            controller.addAction(action)
            self.present(controller, animated: true)
        }
    }
    
    func createPlaylistAPICall() {
        spotify.createPlaylist(for: "srihitaramini", PlaylistDetails.init(name: "test"))
    }
}
