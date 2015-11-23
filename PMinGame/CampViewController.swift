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
		
		//set up labels and stuff
		nextMapButton.titleLabel!.text = nextMap.name
		
		//level up
		if LevelViewController.checkLevel(party)
		{
			performSegueWithIdentifier("levelUp", sender: self)
		}
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let dest = segue.destinationViewController as? LevelViewController
		{
			dest.party = party
		}
	}
}
