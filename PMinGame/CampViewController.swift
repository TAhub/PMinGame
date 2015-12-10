//
//  CampViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/19/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class CampViewController: UIViewController {

	var completionCallback:((Map)->())!
	var comparisonMap:Map!
	var nextMap:Map!
	{
		didSet
		{
			comparisonMap = nextMap
			if nextMapButton != nil
			{
				//set the button
				nextMapButton.setTitle(nextMap.name, forState: .Normal)
			}
		}
	}
	
	@IBOutlet weak var nextMapButton: UIButton!
	@IBAction func nextMapAction()
	{
		if nextMap != nil
		{
			saveState = kSaveStateNone
			completionCallback(nextMap)
			navigationController!.popViewControllerAnimated(true)
		}
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		//heal the entire party
		for person in comparisonMap.party
		{
			person.fillResources()
		}
		
		if LevelViewController.checkLevel(comparisonMap.party)
		{
			//level up
			performSegueWithIdentifier("levelUp", sender: self)
		}
		else if nextMap != nil
		{
			//set up labels and stuff
			nextMapButton.setTitle(nextMap.name, forState: .Normal)
		}
		else
		{
			//set the next map label to a temporary value
			nextMapButton.setTitle("Traveling...", forState: .Normal)
		}
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		//set transition
		navigationController?.delegate = nil
		
		if let dest = segue.destinationViewController as? LevelViewController
		{
			dest.party = comparisonMap.party
		}
		if let dest = segue.destinationViewController as? ShopViewController
		{
			dest.items = comparisonMap.items
			dest.money = comparisonMap.money
			dest.saveCompletion =
			{
				self.comparisonMap.items = dest.items
				self.comparisonMap.money = dest.money
				self.comparisonMap.saveParty()
				saveInventory(dest.items)
			}
		}
	}
}
