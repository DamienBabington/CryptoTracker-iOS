//
//  CoinDataService.swift
//  CryptoTracker
//
//  Created by Damien on 8/29/24.
//

import Foundation

protocol CoinServiceProtocol {
    func fetchCoins() async throws -> [Coin]
    func fetchCoinDetails(id: String) async throws -> CoinDetails?
}

class CoinDataService: CoinServiceProtocol, HTTPDataDownloader {
    
    private var page: Int = 0
    private let fetchLimit: Int = 20
    
    func fetchCoins() async throws -> [Coin] {
        page += 1
        
        guard let endpoint = allCoinsUrlString else {
            throw CoinAPIError.requestFailed(description: "Invalid endpoint")
        }
        return try await fetchData(type: [Coin].self, endpoint: endpoint)
    }
    
    func fetchCoinDetails(id: String) async throws -> CoinDetails? {
        if let cached = CoinDetailsCache.shared.get(forKey: id) {
            return cached
        }
        
        guard let endpoint = coinDetailsURLString(id: id) else {
            throw CoinAPIError.requestFailed(description: "Invalid endpoint")
        }
        
        let details = try await fetchData(type: CoinDetails.self, endpoint: endpoint)
        CoinDetailsCache.shared.set(details, forKey: id)
        return details
    }
    
    private var baseUrlComponents: URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.coingecko.com"
        components.path = "/api/v3/coins/"
        return components
    }
    
    private var allCoinsUrlString: String? {
        var components = baseUrlComponents
        components.path += "markets"
        components.queryItems = [
            .init(name: "vs_currency", value: "usd"),
            .init(name: "order", value: "market_cap_desc"),
            .init(name: "per_page", value: "\(fetchLimit)"),
            .init(name: "page", value: "\(page)"),
            .init(name: "locale", value: "en")
        ]
        return components.url?.absoluteString
    }
    
    private func coinDetailsURLString(id: String) -> String? {
        var components = baseUrlComponents
        components.path += id
        components.queryItems = [
            .init(name: "localization", value: "false")
        ]
        return components.url?.absoluteString
    }
}


// MARK: - Using Completion Handlers

//    // Using a completion handler which returns a Result containining an array of Coins if success and a CoinAPIError if failure
//    func fetchCoinsWithResult(completion: @escaping(Result<[Coin], CoinAPIError>) -> Void) {
//        guard let url = URL(string: allCoinsUrlString ?? "") else { return }
//
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                completion(.failure(.unknownError(error: error)))
//                return
//            }
//            
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(.failure(.requestFailed(description: "Request failed")))
//                return
//            }
//            
//            guard httpResponse.statusCode == 200 else {
//                completion(.failure(.invalidStatusCode(statusCode: httpResponse.statusCode)))
//                return
//            }
//            
//            guard let safeData = data else {
//                completion(.failure(.invalidData))
//                return
//            }
//            
//            do {
//                let coins = try JSONDecoder().decode([Coin].self, from: safeData)
//                completion(.success(coins))
//            } catch {
//                print("Failed to decode with error: \(error)")
//                completion(.failure(.jsonParsingFailure))
//            }
//        }.resume()
//    }
