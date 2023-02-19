//
//  ViewController.swift
//  Previewtify
//
//  Created by Samuel Folledo on 9/9/20.
//  Copyright © 2020 SamuelFolledo. All rights reserved.
//

import SpotifyWebAPI
import UIKit
import SwiftUI
import Combine

enum State {
    case unauthed
    case loading
    case authed
}

class ViewController: UIViewController {
    let spotify = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowManager(
            clientId: "bdc47862fa334584bc6b0d0b5f05f550", clientSecret: "863bd0e110e840668d34fea610498b8d"
        )
    )
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var isAuthed: State = .unauthed
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
    }
    
    func updateViewBasedOnConnected() {
        DispatchQueue.main.async {
            switch self.isAuthed {
            case .unauthed:
                self.disconnectButton.isHidden = true
                self.connectButton.isHidden = false
                self.connectLabel.isHidden = false
                break
            case .loading:
                self.disconnectButton.isHidden = false
                self.connectButton.isHidden = false
                self.connectLabel.isHidden = false
                break
            case .authed:
                self.connectButton.isHidden = true
                self.disconnectButton.isHidden = false
                self.connectLabel.isHidden = true
                break
            }
        }
    }
    
    @objc func didTapDisconnect(_ button: UIButton) {
        print("disconnect pressed")
        self.disconnect()
    }
    
    func disconnect() {

        self.isAuthed = .unauthed;
        updateViewBasedOnConnected()
        createSadPlaylist()
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
        self.isAuthed = .loading
    }
    
    public func checkScopes(_ url: URL) {
        spotify.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url
        )
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                self.isAuthed = .authed
                print("ok")
                self.updateViewBasedOnConnected()
                break
            case .failure(let error):
                if let authError = error as? SpotifyAuthorizationError, authError.accessWasDenied {
                    print("denied auth request")
                } else {
                    print("couldn't auth user: \(error)")
                }
                break
            }
        })
        .store(in: &cancellables)
    }

    func createSadPlaylist() {
        // Set up the API endpoint URL
        let apiUrl = "https://api.spotify.com/v1/recommendations?seed_genres=sad&limit=10"

        // Create a URL object from the API endpoint URL
        guard let url = URL(string: apiUrl) else {
            print("Error: invalid URL")
            return
        }

        // Create a URL request with the necessary headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"


        if let token = spotify.authorizationManager.accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Send the API request using URLSession
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            // Parse the response data into a JSON object
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let tracks = json["tracks"] as? [[String: Any]] {

                // Extract the track URIs from the JSON object
                let trackURIs = tracks.compactMap { $0["uri"] as? String }

                // Create a new playlist with the extracted track URIs
                let playlistUrl = "https://api.spotify.com/v1/users/3d709ub6butki35xnrcnhpunl/playlists"
                guard let playlistRequestUrl = URL(string: playlistUrl) else {
                    print("Error: invalid URL")
                    return
                }

                var playlistRequest = URLRequest(url: playlistRequestUrl)
                playlistRequest.httpMethod = "POST"

                if let token = self.spotify.authorizationManager.accessToken {
                    playlistRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                playlistRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let playlistData = ["name": "Sad Playlist",
                                    "public": false,
                                    "description": "A playlist of sad songs"]

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: playlistData, options: [])
                    playlistRequest.httpBody = jsonData
                } catch {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                let playlistTask = session.dataTask(with: playlistRequest) { (data, response, error) in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                }
                playlistTask.resume()
            }
        }
        task.resume()


    }
    
    func createHappyPlaylist() {
        // Set up the API endpoint URL
        let apiUrl = "https://api.spotify.com/v1/recommendations?seed_genres=happy&limit=10"

        // Create a URL object from the API endpoint URL
        guard let url = URL(string: apiUrl) else {
            print("Error: invalid URL")
            return
        }

        // Create a URL request with the necessary headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        
        if let token = spotify.authorizationManager.accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Send the API request using URLSession
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            // Parse the response data into a JSON object
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let tracks = json["tracks"] as? [[String: Any]] {

                // Extract the track URIs from the JSON object
                let trackURIs = tracks.compactMap { $0["uri"] as? String }

                // Create a new playlist with the extracted track URIs
                let playlistUrl = "https://api.spotify.com/v1/users/3d709ub6butki35xnrcnhpunl/playlists"
                guard let playlistRequestUrl = URL(string: playlistUrl) else {
                    print("Error: invalid URL")
                    return
                }
                
                var playlistRequest = URLRequest(url: playlistRequestUrl)
                playlistRequest.httpMethod = "POST"
                
                if let token = self.spotify.authorizationManager.accessToken {
                    //print("TOKEN \(token)\n")
                    playlistRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                playlistRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let playlistData = ["name": "Happy Playlist",
                                    "public": false,
                                    "description": "A playlist of happy songs"]
                                    //"uris": trackURIs] as [String : Any]

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: playlistData, options: [])
                    playlistRequest.httpBody = jsonData
                } catch {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                let playlistTask = session.dataTask(with: playlistRequest) { (data, response, error) in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        return
                    }
                }
                playlistTask.resume()
            }
        }
        task.resume()
    }
}
