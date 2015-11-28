//
//  ItemTableViewCell.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/28/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class ItemTableViewCell: UITableViewCell {

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var useButton: UIButton!
	
	var useClosure:(()->())?
	{
		didSet
		{
			useButton.hidden = useClosure == nil
		}
	}
	
	@IBAction func useAction()
	{
		if let useClosure = useClosure
		{
			useClosure()
		}
	}
}
