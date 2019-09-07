//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit

class TMDBClient {
    
    static let apiKey = "458203ec805248c07552b52c0bcefa3d"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    // handles the url and the api key
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let baseImage = "https://image.tmdb.org/t/p/w500"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getFavorites
        case getRequestToken
        case createSessionId
        case webAuth
        case login
        case logout
        case search(String)
        case markWatchlist
        case markFavorites
        case posterImageURL(String)
        //URL For endpoints
        var urlValue: String {
            switch self {
                case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                case .getFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
                case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
                case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
                case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
                case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
                case .search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                case .markWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                case .markFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                case .posterImageURL(let posterPath): return Endpoints.baseImage + posterPath
                
            }
        }
        // computable variable
        var url: URL {
            return URL(string: urlValue)!
        }
    }
    
    //MARK: gets the watchlist from the movies array
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            }else{
                completion([],error)
            }        }

    }
    //gets the favorites from the movie array
    class func getFavorites(completionHandler: @escaping ([Movie], Error?) -> Void){
        taskForGETRequest(url: Endpoints.getFavorites.url, response: MovieResults.self) { (response, error) in
            if let response = response{
                completionHandler(response.results,nil)
                
            }else{
                completionHandler([],error)
            }
        }
    }
    // MARK: gets the request token
    class func getRequestToken(completionHandler: @escaping (Bool, Error?) -> Void){
        
        //preparing session for parsing
        let dataTask = URLSession.shared.dataTask(with: Endpoints.getRequestToken.url) { (data, response, error) in
            guard let data = data else{
                DispatchQueue.main.async {
                    completionHandler(false,error)
                }
                return
            }
            //parse json
            do{
                let decoder = JSONDecoder()
                let tokenResponse = try decoder.decode(RequestTokenResponse.self, from: data)
                Auth.requestToken = tokenResponse.requestToken
                DispatchQueue.main.async {
                    completionHandler(true,nil)
                }
                
                
            }catch{
                DispatchQueue.main.async {
                    completionHandler(false,error)
                }
                print(error)
            }
        }
        dataTask.resume()
    }
    //MARK: handles the login post request
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
    //MARK: handles the session response post request
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
    //MARK: handles the logout/delete request
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
    //MARK: handles the get request and parse the response
    class func taskForGETRequest<ResponseType: Decodable>(url:URL, response: ResponseType.Type, completionHandler: @escaping (ResponseType?, Error?) -> Void) ->  URLSessionTask{
        //preparing session for parsing
        let dataTask = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else{
                DispatchQueue.main.async {
                    completionHandler(nil,error)
                }
                return
            }
             //parse json
            let decoder = JSONDecoder()
            do{
                
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(responseObject,nil)
                }
            }catch{
                do{
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(nil, errorResponse)
                    }
                    
                }catch{
                    DispatchQueue.main.async {
                        completionHandler(nil,error)
                    }
                }
            }
        }
        
        dataTask.resume()
        return dataTask
    }
    // handles post request and parse the response
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, response: ResponseType.Type,
                                            body: RequestType, completion: @escaping (ResponseType?, Error?) -> Void){
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let dataTask =  URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else{
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
             //parse json
            let decoder = JSONDecoder()
            do{
                
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject,nil)
                }
                
            }catch{
                do{
                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil,errorResponse)
                    }
                }catch{
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
                
              
                print(error)
            }
        }
        dataTask.resume()
    }
    
    class func search(query:String, completionHandler: @escaping ([Movie],Error?) -> Void) -> URLSessionTask{
       let task = taskForGETRequest(url: Endpoints.search(query).url, response: MovieResults.self) { (response, error) in
            if let response = response {
                completionHandler(response.results, nil)
            }else{
                completionHandler([],error)
            }
        }
        return task
    }
    
    //MARK: handles the send request to post on the watchlist
    class func markWatchlist(movieId: Int, watchlist: Bool, completionHandler: @escaping (Bool, Error?) -> Void){
        let body = MarkWatchlist(mediaType: "movie", mediaId: movieId, watchlist: watchlist)
        
        taskForPOSTRequest(url: Endpoints.markWatchlist.url, response: TMDBResponse.self, body: body) { (response, error) in
            if let response = response {
                completionHandler(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            }else{
                completionHandler(false, error)
            }
        }
    }
   
    //MARK:handes the send request to post on the favoritelist
    class func markFavorites(movieId:Int, favoritelist:Bool, completionHandler:@escaping (Bool,Error?) -> Void){
        let body = MarkFavorite(mediaType: "movie", mediaId: movieId, favorite: favoritelist)
        
        taskForPOSTRequest(url: Endpoints.markFavorites.url, response: TMDBResponse.self, body: body) { (response, error) in
            if let response = response {
                completionHandler(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            }else{
                completionHandler(false,error)
            }
        }
    }
    
    class func downloadPosterImage(posterPath:String, completionHandler: @escaping (Data?,Error?) -> Void){
        let dataTask = URLSession.shared.dataTask(with: Endpoints.posterImageURL(posterPath).url) { (data, response, error) in
            DispatchQueue.main.async {
                completionHandler(data,error)
            }
            
        }
        dataTask.resume()
        
    }
    
}
