//
//  BattleViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/4/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class BattleViewController: UIViewController {

	@IBOutlet weak var playerPosition: NSLayoutConstraint!
	@IBOutlet weak var playerView: UIView!
	@IBOutlet weak var playerStats: UILabel!
	
	@IBOutlet weak var enemyPosition: NSLayoutConstraint!
	@IBOutlet weak var enemyView: UIView!
	@IBOutlet weak var enemyStats: UILabel!
	
	@IBOutlet weak var textParser: UILabel!
	
	@IBOutlet weak var firstButton: UIButton!
	@IBOutlet weak var secondButton: UIButton!
	@IBOutlet weak var thirdButton: UIButton!
	@IBOutlet weak var fourthButton: UIButton!
	
	@IBAction func pressButton(sender: UIButton)
	{
		if sender === firstButton
		{
			battle.useAttack(0)
		}
		else if sender === secondButton
		{
			battle.useAttack(1)
		}
		else if sender === thirdButton
		{
			battle.useAttack(2)
		}
		else if sender === fourthButton
		{
			battle.useAttack(3)
		}
	}
	
	
	private var battle:Battle!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		PlistService.jobStatDiagnostic()
		
		//do a little animation
		playerPosition.constant = 0
		enemyPosition.constant = 0
		UIView.animateWithDuration(2)
		{
			self.enemyView.layoutIfNeeded()
			self.playerView.layoutIfNeeded()
			self.playerStats.alpha = 1
			self.enemyStats.alpha = 1
		}
		
		//initialize the battle
		battle = Battle()
		
		//initialize the labels
		playerStats.text = battle.playerStat
		enemyStats.text = battle.enemyStat
		firstButton.setTitle(battle.getAttackLabel(0), forState: UIControlState.Normal)
		secondButton.setTitle(battle.getAttackLabel(1), forState: UIControlState.Normal)
		thirdButton.setTitle(battle.getAttackLabel(2), forState: UIControlState.Normal)
		fourthButton.setTitle(battle.getAttackLabel(3), forState: UIControlState.Normal)
    }
}
