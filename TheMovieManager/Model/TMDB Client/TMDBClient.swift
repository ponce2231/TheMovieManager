//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "458203ec805248c07552b52c0bcefa3d"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=moviemanager:authenticate"
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            }else{
                completion([],error)
            }
        }

    }
    
    class func getRequestToken(completionHandler: @escaping (Bool, Error?) -> Void){
        
        
        let dataTask = URLSession.shared.dataTask(with: Endpoints.getRequestToken.url) { (data, response, error) in
            guard let data = data else{
                completionHandler(false,error)
                return
            }
            let decoder = JSONDecoder()
            do{
                let tokenResponse = try decoder.decode(RequestTokenResponse.self, from: data)
                Auth.requestToken = tokenResponse.requestToken
                completionHandler(true,nil)
                
            }catch{
                completionHandler(false,error)
                print(error)
            }
        }
        
        dataTask.resume()
    }
    
    class func login(username: String, password: String, completion: @escaping (Bool, Error?) -> Void){
        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        taskForPOSTRequest(url: Endpoints.login.url, response: RequestTokenResponse.self, body: body ) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completion(true,nil)
            }else{
                completion(false,error)
            }
        }
    }
    
    class func sessionResponse(completionHandler: @escaping (Bool, Error?) -> Void){
        let body = PostSession(requestToken: Auth.requestToken)
        taskForPOSTRequest(url: Endpoints.createSessionId.url, response: SessionResponse.self, body: body) { (response, error) in
            if let response = response {
                Auth.sessionId = response.sessionId
                completionHandler(true,nil)
            }else{
                completionHandler(false,error)
            }
        }
    }
    
   class func logout(completionHandler: @escaping () -> Void) {
        var request = URLRequest(url:Endpoints.logout.url)
        
        request.httpMethod = "DELETE"
        
        
        let body = LogoutRequest(sessionId: Auth.sessionId)
        
        request.httpBody = try! JSONEncoder().encode(body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            Auth.requestToken = ""
            Auth.sessionId = ""
            completionHandler()
        }
        dataTask.resume()
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url:URL, response: ResponseType.Type, completionHandler: @escaping (ResponseType?, Error?) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else{
                DispatchQueue.main.async {
                    completionHandler(nil,error)
                }
                return
            }
            let decoder = JSONDecoder()
            do{
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(responseObject,nil)
                }
            }catch{
                DispatchQueue.main.async {
                    completionHandler(nil,error)
                }
                print(error)
            }
        }
        
        dataTask.resume()
    }
    
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, response: ResponseType.Type, body: RequestType, completion: @escaping (ResponseType?, Error?) -> Void){
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        

        let dataTask =  URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else{
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                print(error)
                return
            }
            do{
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject,nil)
                }
                
            }catch{
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                print(error)
            }
        }
        dataTask.resume()
    }
}
