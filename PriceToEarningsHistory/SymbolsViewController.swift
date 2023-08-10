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
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    fileprivate var basicFinancials: [String: BasicFinancials] = [:] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    fileprivate var symbolsInProgress: [String] = []
    private var timer: Timer?
    private var counter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @IBAction private func loadButtonPressed(_ sender: Any) {
        view.isUserInteractionEnabled = false
        DataManager.shared.getSymbols { [weak self] symbols in
            self?.symbols = symbols.sorted(by: { $0.symbol < $1.symbol })
            DispatchQueue.main.async { [weak self] in
                self?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    @IBAction private func loadNumbersButtonPressed(_ sender: Any) {
        view.isUserInteractionEnabled = false
        DataManager.shared.getCachedFundamentals { [weak self] basicFinancials in
            self?.basicFinancials = basicFinancials
            DispatchQueue.main.async { [weak self] in
                self?.view.isUserInteractionEnabled = true
            }
            self?.startTimer()
        }
    }
}

private extension SymbolsViewController {
    // MARK: - Timer
    
    func startTimer() {
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        self.timer = timer
    }
    
    @objc func timerFired() {
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
        if peHistory != 0 {
            cell.title = "\(indexPath.item+1). \(symbol.symbol) - p/e: \(peAnnual) h_p/e: \(peHistory)"
        } else {
            cell.title = "\(indexPath.item+1). \(symbol.symbol) - p/e: \(peAnnual)"
        }
        return cell
    }
}

extension SymbolsViewController: UITableViewDelegate {
    
}
