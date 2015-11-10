//
//  PersonDetailViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/10/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class PersonDetailViewController: UIViewController {

	internal var person:Creature?
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var portraitView: CreatureView!
	@IBOutlet weak var textLabel: UILabel!
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		nameLabel.text = person!.name
		portraitView.creature = person
		textLabel.text = person!.longLabel
	}
	
	@IBAction func returnButton()
	{
		navigationController!.popViewControllerAnimated(true)
	}
}
