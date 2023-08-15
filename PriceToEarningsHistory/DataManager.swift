//
//  DataManager.swift
//  PriceToEarningsHistory
//
//  Created by Mykhailishyn, Mykola (ADM) on 08.08.2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class DataManager {
    private static let documentDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!
    
    static let shared = DataManager()
    private var symbolsCache: [CompanySymbol] = []
    private var basicFinancialsCache: [String: BasicFinancials] = [:]
    private var pricesCache: [String: Quote] = [:]
    private let database = Firestore.firestore()
    private let jsonEncoder = JSONEncoder()
    
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
            symbolsCache = loadedSymbols
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
            basicFinancialsCache[symbol] = loaded!
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
        basicFinancialsCache = loaded
        completion(loaded)
        return
    }
    
    func getPrices(symbol: String, completion: @escaping (Quote) -> ()) {
        guard pricesCache[symbol] == nil else {
            completion(pricesCache[symbol]!)
            return
        }
        let loaded = loadPricesFromFile(for: symbol)
        guard loaded == nil else {
            pricesCache[symbol] = loaded!
            completion(loaded!)
            return
        }
        updatePrices(for: symbol, completion: completion)
    }
    
    func getCachedPrices(completion: @escaping ([String: Quote]) -> ()) {
        guard pricesCache.isEmpty else {
            completion(pricesCache)
            return
        }
        let loaded = loadPricesFromFile()
        pricesCache = loaded
        completion(loaded)
        return
    }
    
    func fs_uploadSymbols() {
        for symbol in symbolsCache {
            try? database
                .collection("symbols")
                .document(symbol.symbol)
                .setData(from: symbol) { error in
                    guard let error = error else {
                        return
                    }
                    print("Firestore Symbols collection: \(error)")
                }
        }
    }
    
    func fs_uploadPrices() {
        for pr in pricesCache {
            do {
                try database
                    .collection("prices")
                    .document(pr.key)
                    .setData(from: pr.value) { error in
                        guard let error = error else {
                            return
                        }
                        print("Firestore Prices collection: \(error)")
                    }
            } catch {
                print("Firestore Prices collection: \(error)")
            }
        }
    }
    
    func fs_uploadBasicFinancials() {
        for bf in basicFinancialsCache {
            try? database
                .collection("fundamentals")
                .document(bf.key)
                .setData(from: bf.value) { error in
                    guard let error = error else {
                        return
                    }
                    print("Firestore Fundamentals collection: \(error)")
                }
        }
    }
    
    func fs_download() {
        database
           .collection("symbols")
           .getDocuments { [weak self] snapshot, error in
               if let error = error {
                   print("read error: \(error)")
               } else if let snapshot = snapshot {
                   let symbols = snapshot.documents.compactMap { try? $0.data(as: CompanySymbol.self) }
                   self?.saveSymbolsToFiles(symbols)
                   self?.symbolsCache = symbols
               }
           }
        
        database
            .collection("fundamentals")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("read error: \(error)")
                } else if let snapshot = snapshot {
                    let basicFinancials = snapshot.documents.compactMap { try? $0.data(as: BasicFinancials.self) }
                    basicFinancials.forEach {
                        self?.saveBasicFinancials($0, symbol: $0.symbol)
                        self?.basicFinancialsCache[$0.symbol] = $0
                    }
                    
                }
            }
        
//        database
//            .collection("prices")
//            .getDocuments { [weak self] snapshot, error in
//                if let error = error {
//                    print("read error: \(error)")
//                } else if let snapshot = snapshot {
//                    let quotes = snapshot.documents.compactMap { doc: FIRQueryDocumentSnapshot in
//                        if let quote = try? doc.data(as: Quote.self) {
//                            return (doc.documentID, quote)
//                        }
//                        return nil
//                    }
//                    quotes.forEach {
//                        self?.saveQuoteToFile($0.value, symbol: $0.key)
//                        self?.pricesCache[$0.key] = $0.value
//                    }
//
//                }
//            }
    }
}

// MARK: FinnhubClient
private extension DataManager {
    func updateSymbols(completion: @escaping ([CompanySymbol]) -> ()) {
        let whitelist = self.whitelist
        FinnhubClient.symbols(exchange: .unitedStates) { [weak self] result in
            switch result {
            case let .success(symbols):
                let filteredSymbols = symbols.filter { whitelist.contains($0.symbol) }
                self?.saveSymbolsToFiles(filteredSymbols)
                self?.symbolsCache = filteredSymbols
                completion(filteredSymbols)
            case .failure(.invalidData):
                print("Invalid data")
            case let .failure(.networkFailure(error)):
                print(error)
            }
        }
    }
    
    func updateBasicFinancials(for symbol: String, completion: @escaping (BasicFinancials) -> ()) {
        FinnhubClient.basicFinancials(symbol: symbol) { [weak self] result in
            switch result {
            case let .success(basicFinancials):
                self?.saveBasicFinancials(basicFinancials, symbol: symbol)
                self?.basicFinancialsCache[symbol] = basicFinancials
                completion(basicFinancials)
            case .failure(.invalidData):
                print("Invalid data")
            case let .failure(.networkFailure(error)):
                print(error)
            }
        }
    }
    
    func updatePrices(for symbol: String, completion: @escaping (Quote) -> ()) {
        FinnhubClient.quote(symbol: symbol) { [weak self] result in
            switch result {
            case let .success(quote):
                self?.saveQuoteToFile(quote, symbol: symbol)
                self?.pricesCache[symbol] = quote
                completion(quote)
            case .failure(.invalidData):
                print("Invalid data")
            case let .failure(.networkFailure(error)):
                print(error)
            }
        }
    }
}

// MARK: FileManager save
extension DataManager {
    func saveSymbolsToFiles(_ symbols: [CompanySymbol]) {
        let whitelist = self.whitelist
        
        for symbol in symbols {
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
    }
    
    func saveQuoteToFile(_ quote: Quote, symbol: String) {
        let jsonData = try! jsonEncoder.encode(quote)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        let pathWithFilename = Self.documentDirectory.appendingPathComponent("\(symbol)_pr.json")
        do {
            try jsonString.write(to: pathWithFilename,
                                 atomically: true,
                                 encoding: .utf8)
        } catch {
            print(error)
        }
    }
    
    func saveBasicFinancials(_ bf: BasicFinancials, symbol: String) {
        let jsonData = try! jsonEncoder.encode(bf)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        let pathWithFilename = Self.documentDirectory.appendingPathComponent("\(symbol)_bf.json")
        do {
            try jsonString.write(to: pathWithFilename,
                                 atomically: true,
                                 encoding: .utf8)
        } catch {
            print(error)
        }
    }
}

// MARK: FileManager load
private extension DataManager {
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
    
    func loadPricesFromFile(for symbol: String) -> Quote? {
        do {
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: Self.documentDirectory.path)
            if fileNames.contains("\(symbol)_pr") {
                let url = Self.documentDirectory.appendingPathComponent("\(symbol)_pr")
                if let jsonData = try String(contentsOfFile: url.path).data(using: .utf8) {
                    let quote = try JSONDecoder().decode(Quote.self, from: jsonData)
                    pricesCache[symbol] = quote
                    return quote
                }
            }
        } catch {
            print(error)
        }
        return nil
    }
    
    func loadPricesFromFile() -> [String: Quote] {
        do {
            var result: [String: Quote] = [:]
            let fileNames = try FileManager.default.contentsOfDirectory(atPath: Self.documentDirectory.path)
            for fileName in fileNames {
                guard fileName.contains("_pr.json") else {
                    continue
                }
                let url = Self.documentDirectory.appendingPathComponent(fileName)
                if let jsonData = try String(contentsOfFile: url.path).data(using: .utf8) {
                    let bf = try JSONDecoder().decode(Quote.self, from: jsonData)
                    let symbol = String(fileName.dropLast("_pr.json".count))
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
