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
		saveState = kSaveStateNone
		completionCallback(nextMap)
		navigationController!.popViewControllerAnimated(true)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		//TODO: you can access money with "nextMap.money"

		saveState = kSaveStateCamp
		
		if LevelViewController.checkLevel(party)
		{
			//level up
			performSegueWithIdentifier("levelUp", sender: self)
		}
		else
		{
			//set up labels and stuff
			nextMapButton.setTitle(nextMap.name, forState: .Normal)
		}
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		//set transition
		navigationController?.delegate = nil
		
		if let dest = segue.destinationViewController as? LevelViewController
		{
			dest.party = party
		}
	}
}
