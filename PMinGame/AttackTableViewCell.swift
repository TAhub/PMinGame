//
//  AttackTableViewCell.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/28/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class AttackTableViewCell: UITableViewCell {

	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var forgetButtonOutlet: UIButton!
	
	var forgetClosure:(()->())?
	{
		didSet
		{
			forgetButtonOutlet.hidden = forgetClosure == nil
		}
	}
	
	@IBAction func forgetButton()
	{
		if let forgetClosure = forgetClosure
		{
			forgetClosure()
		}
	}
	
	
}
