//
//  PartyMemberTableViewCell.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/28/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class PartyMemberTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

	var personSelectCallback:(()->())!
	
	@IBOutlet weak var nameLabel: UILabel!
	
	@IBAction func buttonAction()
	{
		personSelectCallback()
	}
	
}
