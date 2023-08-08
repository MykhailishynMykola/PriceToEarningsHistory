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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataManager.shared.getSymbols { [weak self] symbols in
            guard let self = self else { return }
            self.symbols = symbols.sorted(by: { $0.displaySymbol < $1.displaySymbol })
            
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            self.timer?.fire()
        }
    }
    
    private var counter = 0
    @objc private func timerFired() {
        guard symbols.indices.contains(counter) else {
            timer?.invalidate()
            return
        }
        var nextSymbol = symbols[counter].displaySymbol
        while basicFinancials.keys.contains(nextSymbol) || symbolsInProgress.contains(nextSymbol) {
            counter += 1
            
            guard symbols.indices.contains(counter) else {
                timer?.invalidate()
                return
            }
            nextSymbol = symbols[counter].displaySymbol
        }
        symbolsInProgress.append(nextSymbol)
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
        let peAnnual = basicFinancials[symbol.displaySymbol]?.metric.peAnnual ?? 0
        cell.title = "\(indexPath.item+1). \(symbol.displaySymbol) - \(peAnnual)"
        return cell
    }
}

extension SymbolsViewController: UITableViewDelegate {
    
}
