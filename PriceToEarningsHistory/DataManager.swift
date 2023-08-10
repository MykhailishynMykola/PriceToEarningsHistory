//
//  DataManager.swift
//  PriceToEarningsHistory
//
//  Created by Mykhailishyn, Mykola (ADM) on 08.08.2023.
//

import Foundation

final class DataManager {
    private static let documentDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!
    
    static let shared = DataManager()
    private var symbolsCache: [CompanySymbol] = []
    private var basicFinancialsCache: [String: BasicFinancials] = [:]
    
    private var whitelist: [String] {
        guard let path = Bundle.main.path(forResource: "whitelist", ofType: "json"),
              let jsonData = try? String(contentsOfFile: path).data(using: .utf8) else {
            return []
        }
        let result = (try? JSONDecoder().decode([String].self, from: jsonData)) ?? []
        return result
    }
    
    private init() {}
    
    func getSymbols(completion: @escaping ([CompanySymbol]) -> ())  {
        guard symbolsCache.isEmpty else {
            completion(symbolsCache)
            return
        }
        let loadedSymbols = loadSymbolsFromFile()
        guard loadedSymbols.isEmpty else {
            completion(loadedSymbols)
            return
        }
        updateSymbols(completion: completion)
    }
    
    func getFundamentals(symbol: String, completion: @escaping (BasicFinancials) -> ()) {
        guard basicFinancialsCache[symbol] == nil else {
            completion(basicFinancialsCache[symbol]!)
            return
        }
        let loaded = loadBasicFinancialsFromFile(for: symbol)
        guard loaded == nil else {
            completion(loaded!)
            return
        }
        updateBasicFinancials(for: symbol, completion: completion)
    }
    
    func getCachedFundamentals(completion: @escaping ([String: BasicFinancials]) -> ()) {
        guard basicFinancialsCache.isEmpty else {
            completion(basicFinancialsCache)
            return
        }
        let loaded = loadBasicFinancialsFromFile()
        completion(loaded)
        return
    }
}

private extension DataManager {
    func updateSymbols(completion: @escaping ([CompanySymbol]) -> ()) {
        let jsonEncoder = JSONEncoder()
        let whitelist = self.whitelist
        
        FinnhubClient.symbols(exchange: .unitedStates) { result in
            switch result {
            case let .success(symbols):
                let filteredSymbols = symbols.filter { whitelist.contains($0.symbol) }
                for symbol in filteredSymbols {
                    guard whitelist.contains(symbol.symbol) else { continue }
                    let jsonData = try! jsonEncoder.encode(symbol)
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    
                    let pathWithFilename = Self.documentDirectory.appendingPathComponent("\(symbol.symbol)_smbl.json")
                    do {
                        try jsonString.write(to: pathWithFilename,
                                             atomically: true,
                                             encoding: .utf8)
                    } catch {
                        print(error)
                    }
                }
                self.symbolsCache = filteredSymbols
                completion(filteredSymbols)
            case .failure(.invalidData):
                print("Invalid data")
            case let .failure(.networkFailure(error)):
                print(error)
            }
        }
    }
    
    func updateBasicFinancials(for symbol: String, completion: @escaping (BasicFinancials) -> ()) {
        let jsonEncoder = JSONEncoder()
        
        FinnhubClient.basicFinancials(symbol: symbol) { result in
            switch result {
            case let .success(basicFinancials):
                let jsonData = try! jsonEncoder.encode(basicFinancials)
                let jsonString = String(data: jsonData, encoding: .utf8)!
                
                let pathWithFilename = Self.documentDirectory.appendingPathComponent("\(symbol)_bf.json")
                do {
                    try jsonString.write(to: pathWithFilename,
                                         atomically: true,
                                         encoding: .utf8)
                } catch {
                    print(error)
                }
                
                self.basicFinancialsCache[symbol] = basicFinancials
                completion(basicFinancials)
            case .failure(.invalidData):
                print("Invalid data")
            case let .failure(.networkFailure(error)):
                print(error)
            }
        }
    }
    
    func loadSymbolsFromFile() -> [CompanySymbol] {
        do {
            var symbols: [CompanySymbol] = []
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: Self.documentDirectory.path)

            for filename in fileNames {
                guard filename.contains("_smbl") else {
                    continue
                }
                
                let url = Self.documentDirectory.appendingPathComponent(filename)
                if let jsonData = try String(contentsOfFile: url.path).data(using: .utf8) {
                    let symbol = try JSONDecoder().decode(CompanySymbol.self, from: jsonData)
                    symbols.append(symbol)
                }
            }
            self.symbolsCache = symbols
            return symbols
        } catch {
            print(error)
        }
        return []
    }
    
    func loadBasicFinancialsFromFile(for symbol: String) -> BasicFinancials? {
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: Self.documentDirectory.path)
            if fileNames.contains("\(symbol)_bf") {
                let url = Self.documentDirectory.appendingPathComponent("\(symbol)_bf")
                if let jsonData = try String(contentsOfFile: url.path).data(using: .utf8) {
                    let bf = try JSONDecoder().decode(BasicFinancials.self, from: jsonData)
                    basicFinancialsCache[symbol] = bf
                    return bf
                }
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func loadBasicFinancialsFromFile() -> [String: BasicFinancials] {
        do {
            var result: [String: BasicFinancials] = [:]
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: Self.documentDirectory.path)
            for fileName in fileNames {
                guard fileName.contains("_bf.json") else {
                    continue
                }
                let url = Self.documentDirectory.appendingPathComponent(fileName)
                if let jsonData = try String(contentsOfFile: url.path).data(using: .utf8) {
                    let bf = try JSONDecoder().decode(BasicFinancials.self, from: jsonData)
                    let symbol = String(fileName.dropLast("_bf.json".count))
                    result[symbol] = bf
                }
            }
            return result
        } catch {
            print(error)
        }
        return [:]
    }
}
