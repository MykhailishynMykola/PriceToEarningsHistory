//
//  SymbolCell.swift
//  PriceToEarningsHistory
//
//  Created by Mykhailishyn, Mykola (ADM) on 08.08.2023.
//

import UIKit

final class SymbolCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
}
