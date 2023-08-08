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
        let loadedBasicFinancials = loadBasicFinancialsFromFile(for: symbol)
        guard loadedBasicFinancials == nil else {
            completion(loadedBasicFinancials!)
            return
        }
        updateBasicFinancials(for: symbol, completion: completion)
    }
}

private extension DataManager {
    func updateSymbols(completion: @escaping ([CompanySymbol]) -> ()) {
        let jsonEncoder = JSONEncoder()
        
        FinnhubClient.symbols(exchange: .unitedStates) { result in
            switch result {
            case let .success(symbols):
                for symbol in symbols {
                    let jsonData = try! jsonEncoder.encode(symbol)
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    
                    let pathWithFilename = Self.documentDirectory.appendingPathComponent("\(symbol.displaySymbol)_smbl.json")
                    do {
                        try jsonString.write(to: pathWithFilename,
                                             atomically: true,
                                             encoding: .utf8)
                    } catch {
                        print(error)
                    }
                }
                self.symbolsCache = symbols
                completion(symbols)
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
}
