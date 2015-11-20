//
//  CampViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/19/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class CampViewController: UIViewController {

	var party:[Creature]!
	var completionCallback:((Map)->())!
	var nextMap:Map!
	
	@IBOutlet weak var nextMapButton: UIButton!
	@IBAction func nextMapAction()
	{
		completionCallback(nextMap)
		navigationController!.popViewControllerAnimated(true)
	}
	
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		//TODO: there should be leveling up and whatnot
		
		//set up labels and stuff
		nextMapButton.titleLabel!.text = nextMap.name
	}
}
