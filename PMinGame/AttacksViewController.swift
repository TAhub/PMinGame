//
//  AttacksViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/28/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class AttacksViewController: UIViewController {

	var person:Creature?
	
	
	@IBOutlet weak var portraitView: CreatureView!
	@IBOutlet weak var nameLabel: UILabel!
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		nameLabel.text = person!.name
		portraitView.creature = person
	}
	
	@IBAction func returnButton()
	{
		navigationController!.popViewControllerAnimated(true)
	}
}
