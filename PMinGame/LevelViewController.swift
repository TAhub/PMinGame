//
//  LevelViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/22/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class LevelViewController: UIViewController {
	
	internal var party:[Creature]!
	private var nextAttack:Attack?
	private var toLevel:Creature!
	{
		didSet
		{
			//default titles and stuff
			button1.setTitle(nil, forState: .Normal)
			label1.text = nil
			button2.setTitle(nil, forState: .Normal)
			label2.text = nil
			button3.setTitle(nil, forState: .Normal)
			label3.text = nil
			button4.setTitle(nil, forState: .Normal)
			label4.text = nil
			button5.setTitle(nil, forState: .Normal)
			label5.text = nil
			
			creatureView.creature = toLevel
			
			nextAttack = toLevel.getAttackForLevel(toLevel.level)
			if nextAttack != nil
			{
				nextAttack!.powerPoints = nextAttack!.maxPowerPoints
			}
			
			if let nextAttack = nextAttack
			{
				if toLevel.attacks.count == kMaxAttacks
				{
					nameLabel.text = "\(toLevel.name) reached level \(toLevel.level) and could learn \(nextAttack.attack), but can only know \(kMaxAttacks) attacks at a time!"
					
					button5.setTitle("Don't learn \(nextAttack.attack)", forState: .Normal)
					label5.text = nextAttack.description

					let attack1 = toLevel.attacks[0]
					button1.setTitle("Forget \(attack1.attack)", forState: .Normal)
					label1.text = attack1.description

					let attack2 = toLevel.attacks[1]
					button2.setTitle("Forget \(attack2.attack)", forState: .Normal)
					label2.text = attack2.description

					let attack3 = toLevel.attacks[2]
					button3.setTitle("Forget \(attack3.attack)", forState: .Normal)
					label3.text = attack3.description

					let attack4 = toLevel.attacks[3]
					button4.setTitle("Forget \(attack4.attack)", forState: .Normal)
					label4.text = attack4.description
				}
				else
				{
					nameLabel.text = "\(toLevel.name) reached level \(toLevel.level) and can learn \(nextAttack.attack)!"
					
					toLevel.attacks.append(nextAttack)
					
					button1.setTitle("Learn \(nextAttack.attack)", forState: .Normal)
					label1.text = nextAttack.description
				}
			}
			else
			{
				nameLabel.text = "\(toLevel.name) reached level \(toLevel.level)!"
				
				button1.setTitle("Go on", forState: .Normal)
			}
		}
	}
	
	//MARK: creature appearance
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var creatureView: CreatureView!
	
	//MARK: attack things
	@IBOutlet weak var button1: UIButton!
	@IBOutlet weak var label1: UILabel!
	@IBOutlet weak var button2: UIButton!
	@IBOutlet weak var label2: UILabel!
	@IBOutlet weak var button3: UIButton!
	@IBOutlet weak var label3: UILabel!
	@IBOutlet weak var button4: UIButton!
	@IBOutlet weak var label4: UILabel!
	@IBOutlet weak var button5: UIButton!
	@IBOutlet weak var label5: UILabel!
	
	@IBAction func press1()
	{
		press(0)
	}
	
	@IBAction func press2()
	{
		press(1)
	}
	
	@IBAction func press3()
	{
		press(2)
	}
	
	@IBAction func press4()
	{
		press(3)
	}
	
	@IBAction func press5()
	{
		press(4)
	}
	
	private func press(num:Int)
	{
		if let nextAttack = nextAttack
		{
			if toLevel.attacks.count < kMaxAttacks
			{
				findToLoad()
			}
			else
			{
				if num < kMaxAttacks
				{
					toLevel.attacks[num] = nextAttack
				}
				findToLoad()
				
			}
		}
		else if num == 0
		{
			findToLoad()
		}
	}
	
	

    override func viewDidLoad() {
        super.viewDidLoad()

		findToLoad()
    }
	
	private func findToLoad()
	{
		if let toLevel = toLevel
		{
			//save them
			//do it NOW, so you can save the player's choice of new attack
			for (i, p) in party.enumerate()
			{
				if p === toLevel
				{
					savePartyMember(p, party: true, number: i)
					break
				}
			}
		}
		
		for p in party
		{
			if p.experience >= expToNextLevel(p.level)
			{
				p.experience -= expToNextLevel(p.level)
				p.level += 1
				p.health = p.maxHealth
				toLevel = p
				return
			}
		}
		
		//return to the camp screen
		navigationController!.popViewControllerAnimated(true)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	
	class func checkLevel(party:[Creature]) -> Bool
	{
		for p in party
		{
			if p.experience >= expToNextLevel(p.level)
			{
				return true
			}
		}
		return false
	}
}
