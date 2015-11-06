//
//  BattleViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/4/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

enum MenuState
{
	case Main
	case Attack
	case Switch(Int)
	case Item(Int)
	case ItemTarget(Int)
}

class BattleViewController: UIViewController, BattleDelegate {

	//MARK: outlets and actions
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
	
	@IBOutlet weak var nextButton: UIButton!
	@IBOutlet weak var cancelButton: UIButton!
	
	
	
	@IBAction func pressButton(sender: UIButton)
	{
		if !writingMessages && !animating
		{
			if sender == nextButton
			{
				pressButton(4)
			}
			else if sender == cancelButton
			{
				pressButton(5)
			}
			else if sender === firstButton
			{
				pressButton(0)
			}
			else if sender === secondButton
			{
				pressButton(1)
			}
			else if sender === thirdButton
			{
				pressButton(2)
			}
			else if sender === fourthButton
			{
				pressButton(3)
			}
		}
	}
	
	//MARK: text parser stuff
	private var oldMessages = [String]()
	private var messages = [String]()
	private var writingMessages:Bool = false
	{
		didSet
		{
			labelsChanged()
		}
	}
	
	private func messageThread()
	{
		func messageThreadWrite(messages:[String], extraMessage:String?)
		{
			//set the text parser
			var tParse = ""
			for message in messages
			{
				if tParse != ""
				{
					tParse += "\n"
				}
				tParse += message
			}
			if let extraMessage = extraMessage
			{
				if tParse != ""
				{
					tParse += "\n"
				}
				tParse += extraMessage
			}
			
			dispatch_async(dispatch_get_main_queue())
			{
				self.textParser.text = tParse
			}
		}
		
		while messages.count > 0
		{
			if oldMessages.count >= self.textParser.numberOfLines
			{
				oldMessages.removeAtIndex(0)
			}
			
			let message = messages.removeAtIndex(0)
			for i in message.startIndex..<message.endIndex
			{
				let subMessage = message.substringToIndex(i)
				messageThreadWrite(oldMessages, extraMessage: subMessage)
				usleep(1000)
			}
			
			oldMessages.append(message)
			messageThreadWrite(oldMessages, extraMessage: nil)
		}
		
		dispatch_async(dispatch_get_main_queue(), messageThreadOver)
	}
	
	private func messageThreadOver()
	{
		writingMessages = false
		
		//advance the battle
		battle.turnOperation()
	}
	
	//MARK: central stuff
	private var battle:Battle!
	private var animating:Bool = false
	{
		didSet
		{
			labelsChanged()
		}
	}
	private var menuState:MenuState = .Main
	{
		didSet
		{
			labelsChanged()
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		//diagnostics
//		PlistService.jobStatDiagnostic()
		PlistService.jobAttackDiagnostic()
		
		//do a little animation
		animating = true
		playerPosition.constant = 0
		enemyPosition.constant = 0
		UIView.animateWithDuration(2.0, animations:
		{
			self.view.layoutIfNeeded()
			self.playerStats.alpha = 1
			self.enemyStats.alpha = 1
		})
		{ (finished) in
			self.animating = false
		}
		
		//initialize the battle
		battle = Battle()
		battle.delegate = self
		
		//initialize the labels
		labelsChanged()
		
		textParser.text = ""
    }
	
	private func pressButton(num:Int)
	{
		switch menuState
		{
		case .Main:
			switch num
			{
			case 0: menuState = .Attack
			case 1: menuState = .Item(0)
			case 2: menuState = .Switch(0)
			case 3: print("ATTEMPT TO FLEE")
			default: break
			}
		case .Attack:
			if num == 5
			{
				menuState = .Main
			}
			else if num < 4
			{
				battle.pickAttack(num)
				battle.turnOperation()
				menuState = .Main
			}
		case .Switch(let page):
			if num == 5
			{
				menuState = .Main
			}
			else if num == 4
			{
				let newPage = (page + 1) % Int(ceil(Float(battle.players.count) * 0.25))
				menuState = .Switch(newPage)
			}
			else
			{
				battle.pickSwitch(page * 4 + num)
				battle.turnOperation()
				menuState = .Main
			}
		default: break
		}
	}
	
	private func labelsChanged()
	{
		if playerStats == nil || battle == nil
		{
			return
		}
		
		if !writingMessages
		{
			playerStats.text = battle.playerStat
			enemyStats.text = battle.enemyStat
		}
		
		if animating || writingMessages
		{
			firstButton.setTitle(nil, forState: UIControlState.Normal)
			secondButton.setTitle(nil, forState: UIControlState.Normal)
			thirdButton.setTitle(nil, forState: UIControlState.Normal)
			fourthButton.setTitle(nil, forState: UIControlState.Normal)
			nextButton.setTitle(nil, forState: UIControlState.Normal)
			cancelButton.setTitle(nil, forState: UIControlState.Normal)
			return
		}
		
		switch(menuState)
		{
		case .Main:
			firstButton.setTitle("Attack", forState: UIControlState.Normal)
			secondButton.setTitle("Item", forState: UIControlState.Normal)
			thirdButton.setTitle("Switch", forState: UIControlState.Normal)
			fourthButton.setTitle("Flee", forState: UIControlState.Normal)
			nextButton.setTitle(nil, forState: UIControlState.Normal)
			cancelButton.setTitle(nil, forState: UIControlState.Normal)
		case .Attack:
			firstButton.setTitle(battle.getAttackLabel(0), forState: UIControlState.Normal)
			secondButton.setTitle(battle.getAttackLabel(1), forState: UIControlState.Normal)
			thirdButton.setTitle(battle.getAttackLabel(2), forState: UIControlState.Normal)
			fourthButton.setTitle(battle.getAttackLabel(3), forState: UIControlState.Normal)
			nextButton.setTitle(nil, forState: UIControlState.Normal)
			cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
		case .Switch(let page):
			firstButton.setTitle(battle.getPersonlabel(page * 4), forState: UIControlState.Normal)
			secondButton.setTitle(battle.getPersonlabel(page * 4 + 1), forState: UIControlState.Normal)
			thirdButton.setTitle(battle.getPersonlabel(page * 4 + 2), forState: UIControlState.Normal)
			fourthButton.setTitle(battle.getPersonlabel(page * 4 + 3), forState: UIControlState.Normal)
			nextButton.setTitle("Next", forState: UIControlState.Normal)
			cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
		default: assertionFailure("ERROR: I haven't made the other states yet"); break
		}
	}
	
	//MARK: delegate functions
	func switchAnim(onPlayer: Bool)
	{
//		let actingOn = (onPlayer ? playerView : enemyView)
		let actingOnPosition = (onPlayer ? playerPosition : enemyPosition)
		let actingOnLabel = (onPlayer ? playerStats : enemyStats)
		
		//do the actual animation
		animating = true
		actingOnPosition.constant = 300 * (onPlayer ? 1 : -1)
		UIView.animateWithDuration(1.0, animations:
		{
			self.view.layoutIfNeeded()
			actingOnLabel.alpha = 0
			
		})
		{ (success) in
			//TODO: switch the appearance of actingOn
			//to the new person
			
			self.labelsChanged()
			
			actingOnPosition.constant = 0
			UIView.animateWithDuration(1.0, animations:
			{
				self.view.layoutIfNeeded()
				actingOnLabel.alpha = 1
			})
			{ (success) in
				self.animating = false
			}
		}
	}
	
	func runMessage(message:String)
	{
		messages.append(message)
		if !writingMessages
		{
			writingMessages = true
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), messageThread)
		}
	}
	
	func victory()
	{
		//TODO: you won!
		print("You won!")
	}
	
	func defeat()
	{
		//TODO: you lost!
		print("You lost!")
	}
}
