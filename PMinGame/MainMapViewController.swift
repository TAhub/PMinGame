//
//  MainMapViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/9/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

let kMaxPartySize:Int = 6

class MainMapViewController: UIViewController {
	//TODO: this should have a collection view in it
	//each cell has a background color and (optionally) a transparent png in front of it
	//for example, a tile of red brick would have a dark red background color and a generic "brick pattern" image in front of it
	//this should be a nice way to handle the map, and using background colors will make the images popping in as they load not be too bad
	//obviously you then draw the map objects over this, etc
	
	internal var party = [Creature]()
	internal var reserve = [Creature]()
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		//diagnostics
		
		//turn this diagnostic on if you want to see if a job's stats are in-line with the standard
//		PlistService.jobStatDiagnostic()
		
		//turn this diagnostic on if you want to see if a job's attacks have the right balance of brute and clever, types, etc
//		PlistService.jobAttackDiagnostic()
		
		//turn this diagnostic on if you want to see if one type has too many attacks, etc
//		PlistService.attackDiagnostic()
		
		//turn this diagnostic on if you want to see if any attack is overused, underused, or not used at all
//		PlistService.attackUsageDiagnostic()
		
		//turn this diagnostic on if you want to see if any attack is too strong, too weak, etc
//		PlistService.attackPowerDiagnostic()
		
		
		//sample starting party
		party.append(Creature(job: "barbarian", level: 1, good: true))
		party.append(Creature(job: "mystic", level: 1, good: true))
		party.append(Creature(job: "inventor", level: 1, good: true))
		party.append(Creature(job: "soldier", level: 1, good: true))
		reserve.append(Creature(job: "rogue", level: 1, good: true))
		
		//TODO: the reserve should be cleared when you get to a new map
		//output a message in the camp screen saying those people ran away, whatever
	}
	
	
	@IBAction func tempBattleButton()
	{
		startBattle()
	}
	
	private func startBattle()
	{
		performSegueWithIdentifier("startBattle", sender: self)
		
		//TODO: this should have a cool custom transition
		//some kind of dissolve maybe
		//think a final fantasy battle start
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if let bvc = segue.destinationViewController as? BattleViewController
		{
			bvc.setup(party)
			{ (lost, newAdditions, moneyChange) in
				
				if lost
				{
					//TODO: end the game or whatever
					print("You lost!")
				}
				else
				{
					//TODO: change your money total based on moneyChange
					
					if let newAdditions = newAdditions
					{
						for new in newAdditions
						{
							if self.party.count < kMaxPartySize
							{
								self.party.append(new)
							}
							else
							{
								self.reserve.append(new)
							}
						}
					}
				}
			}
		}
	}
}
