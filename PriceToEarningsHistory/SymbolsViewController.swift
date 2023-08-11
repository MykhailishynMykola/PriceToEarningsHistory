//
//  SymbolsViewController.swift
//  PriceToEarningsHistory
//
//  Created by Mykhailishyn, Mykola (ADM) on 08.08.2023.
//

import UIKit

final class SymbolsViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    
    fileprivate var symbols: [CompanySymbol] = [] {
        didSet {
            reloadTableView()
        }
    }
    
    fileprivate var basicFinancials: [String: BasicFinancials] = [:] {
        didSet {
            reloadTableView()
        }
    }
    
    fileprivate var prices: [String: Quote] = [:] {
        didSet {
            reloadTableView()
        }
    }
    
    fileprivate var symbolsInProgress: [String] = []
    private var timer: Timer?
    private var counter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func reloadTableView() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func symbolsButtonPressed(_ sender: Any) {
        view.isUserInteractionEnabled = false
        DataManager.shared.getSymbols { [weak self] symbols in
            self?.symbols = symbols.sorted(by: { $0.symbol < $1.symbol })
            DispatchQueue.main.async { [weak self] in
                self?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    @IBAction private func pricesButtonPressed(_ sender: Any) {
        view.isUserInteractionEnabled = false
        DataManager.shared.getCachedPrices { [weak self] prices in
            guard let self = self else { return }
            self.prices = prices
            DispatchQueue.main.async { [weak self] in
                self?.view.isUserInteractionEnabled = true
            }
            self.startTimer(with: #selector(self.pricesTimerFired))
        }
    }
    
    @IBAction private func peButtonPressed(_ sender: Any) {
        view.isUserInteractionEnabled = false
        DataManager.shared.getCachedFundamentals { [weak self] basicFinancials in
            guard let self = self else { return }
            self.basicFinancials = basicFinancials
            DispatchQueue.main.async { [weak self] in
                self?.view.isUserInteractionEnabled = true
            }
            self.startTimer(with: #selector(self.basicFinancialsTimerFired))
        }
    }
}

private extension SymbolsViewController {
    // MARK: - Timer
    
    func startTimer(with selector: Selector) {
        counter = 0
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: selector, userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        self.timer = timer
    }
    
    @objc func basicFinancialsTimerFired() {
        guard symbols.indices.contains(counter) else {
            symbolsInProgress = []
            timer?.invalidate()
            return
        }
        var nextSymbol = symbols[counter].symbol
        while basicFinancials.keys.contains(nextSymbol) || symbolsInProgress.contains(nextSymbol) {
            counter += 1
            
            guard symbols.indices.contains(counter) else {
                symbolsInProgress = []
                timer?.invalidate()
                return
            }
            nextSymbol = symbols[counter].symbol
        }
        symbolsInProgress.append(nextSymbol)
        print("BF loading: \(counter+1). \(nextSymbol)")
        DataManager.shared.getFundamentals(symbol: nextSymbol) { [weak self] basicFinancials in
            self?.basicFinancials[nextSymbol] = basicFinancials
        }
    }
    
    @objc func pricesTimerFired() {
        guard symbols.indices.contains(counter) else {
            symbolsInProgress = []
            timer?.invalidate()
            return
        }
        var nextSymbol = symbols[counter].symbol
        while prices.keys.contains(nextSymbol) || symbolsInProgress.contains(nextSymbol) {
            counter += 1
            
            guard symbols.indices.contains(counter) else {
                symbolsInProgress = []
                timer?.invalidate()
                return
            }
            nextSymbol = symbols[counter].symbol
        }
        symbolsInProgress.append(nextSymbol)
        print("PR loading: \(counter+1). \(nextSymbol)")
        DataManager.shared.getPrices(symbol: nextSymbol) { [weak self] prices in
            self?.prices[nextSymbol] = prices
        }
    }
}

extension SymbolsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        symbols.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SymbolCell") as? SymbolCell else {
            return UITableViewCell()
        }
        let symbol = symbols[indexPath.item]
        let price = prices[symbol.symbol]?.current ?? 0
        let peAnnual = basicFinancials[symbol.symbol]?.metric.peAnnual ?? 0
        
        
        var peHistory: Float = 0
        if let historyNotes = basicFinancials[symbol.symbol]?.series.annual.pe {
            var sum: Float = 0
            for note in historyNotes {
                sum += note.value
            }
            if historyNotes.count != 0 {
                peHistory = sum / Float(historyNotes.count)
            }
        }
        
        let priceString = String(format: "%.1f", price)
        let peAnnualString = String(format: "%.1f", peAnnual)
        let peHistoryString = String(format: "%.1f", peHistory)
        
        cell.title = "\(indexPath.item+1).\(symbol.symbol) pr: \(priceString) p/e: \(peAnnualString) h_p/e: \(peHistoryString)"
        return cell
    }
}

extension SymbolsViewController: UITableViewDelegate {
    
}
