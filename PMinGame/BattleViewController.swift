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
	case ItemPick(Int)
	case ItemTarget(Int, Item)
}

class BattleViewController: UIViewController, BattleDelegate {
	
	//MARK: outlets and actions
	@IBOutlet weak var playerPosition: NSLayoutConstraint!
	@IBOutlet weak var playerView: CreatureView!
	@IBOutlet weak var playerStats: UILabel!
	
	@IBOutlet weak var enemyPosition: NSLayoutConstraint!
	@IBOutlet weak var enemyView: CreatureView!
	@IBOutlet weak var enemyStats: UILabel!
	
	@IBOutlet weak var textParser: UITextView!
	
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
	private var messages = [String]()
	private var storeMessages = [String]()
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
			var fullMessages = messages
			if let extraMessage = extraMessage
			{
				if extraMessage.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) != ""
				{
					fullMessages.append(extraMessage)
				}
			}
			let joinedText = fullMessages.joinWithSeparator("\n")
			dispatch_async(dispatch_get_main_queue())
				{
					if self.textParser.text.characters.count < joinedText.characters.count
					{
						//set text
						self.textParser.text = joinedText
						self.textParser.layoutIfNeeded()
						
						//move to bottom
						UIView.setAnimationsEnabled(false)
						let range = NSMakeRange(self.textParser.text.characters.count, 0)
						self.textParser.scrollRangeToVisible(range)
						UIView.setAnimationsEnabled(true)
					}
			}
		}
		
		while messages.count > 0
		{
			var message = messages.removeAtIndex(0)
			if message.characters.first == "%"
			{
				message = message.substringFromIndex(message.startIndex.advancedBy(1))
				dispatch_async(dispatch_get_main_queue())
					{
						self.shake()
				}
			}
			for i in message.startIndex..<message.endIndex
			{
				let subMessage = message.substringToIndex(i)
				messageThreadWrite(storeMessages, extraMessage: subMessage)
				usleep(800)
			}
			
			storeMessages.append(message)
			messageThreadWrite(storeMessages, extraMessage: nil)
		}
		
		dispatch_async(dispatch_get_main_queue(), messageThreadOver)
	}
	
	private func messageThreadOver()
	{
		writingMessages = false
		
		if let endingHook = endingHook
		{
			endingHook()
		}
		else
		{
			//advance the battle
			battle.turnOperation()
		}
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
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		textParser.text = ""
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		//do a little animation
		animating = true
		playerPosition.constant = 0
		enemyPosition.constant = 0
		UIView.animateWithDuration(1.5, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations:
			{
				self.view.layoutIfNeeded()
				self.playerStats.alpha = 1
				self.enemyStats.alpha = 1
			})
			{ (finished) in
				self.animating = false
		}
		
		//initialize the labels
		labelsChanged()
	}
	
	private var endOfBattleHook:((Bool, [Creature]?, Int)->())!
	private var endingHook:(()->())?
	func setup(party:[Creature], money:Int, encounterType:String, difficulty:Int, endOfBattleHook:(Bool, [Creature]?, Int)->(), savePlayersCallback:()->())
	{
		let items = loadInventory()
		battle = Battle(players: party, money: money, items: items, encounterType: encounterType, difficulty: difficulty, savePlayersCallback: savePlayersCallback)
		
		saveState = kSaveStateBattle
		
		battle.delegate = self
		self.endOfBattleHook = endOfBattleHook
	}
	
	private func pressButton(num:Int)
	{
		switch menuState
		{
		case .Main:
			switch num
			{
			case 0:
				if !battle.player.dead
				{
					menuState = .Attack
				}
			case 1:
				if !battle.player.dead
				{
					menuState = .ItemPick(0)
				}
			case 2: menuState = .Switch(0)
			case 3: battle.pickFlee()
			case 4: battle.pickCapture()
			default: break
			}
		case .Attack:
			if num == 5
			{
				menuState = .Main
			}
			else if num < 4
			{
				if battle.pickAttack(num)
				{
					menuState = .Main
				}
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
				if battle.pickSwitch(page * 4 + num)
				{
					menuState = .Main
				}
			}
		case .ItemPick(let page):
			if num == 5
			{
				menuState = .Main
			}
			else if num == 4
			{
				let newPage = (page + 1) % Int(ceil(Float(battle.playerItems.count) * 0.25))
				menuState = .ItemPick(newPage)
			}
			else
			{
				menuState = .ItemTarget(0, battle.playerItems[num + page * 4])
			}
		case .ItemTarget(let page, let item):
			if num == 5
			{
				menuState = .ItemPick(0)
			}
			else if num == 4
			{
				let newPage = (page + 1) % Int(ceil(Float(battle.players.count) * 0.25))
				menuState = .ItemTarget(newPage, item)
			}
			else
			{
				if battle.pickItem(page * 4 + num, item: item)
				{
					menuState = .Main
				}
			}
			break
		}
	}
	
	private var firstLabelSet = true
	
	private func labelsChanged()
	{
		if playerStats == nil || battle == nil
		{
			return
		}
		
		if !animating
		{
			firstLabelSet = false
		}
		
		if !writingMessages
		{
			if !firstLabelSet
			{
				playerStats.text = battle.playerStat
				enemyStats.text = battle.enemyStat
			}
			else
			{
				playerStats.text = ""
				enemyStats.text = ""
			}
			
			playerView.creature = battle.player
			enemyView.creature = battle.enemy
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
			nextButton.setTitle("Capture", forState: UIControlState.Normal)
			cancelButton.setTitle(nil, forState: UIControlState.Normal)
		case .Attack:
			firstButton.setTitle(battle.getAttackLabel(0), forState: UIControlState.Normal)
			secondButton.setTitle(battle.getAttackLabel(1), forState: UIControlState.Normal)
			thirdButton.setTitle(battle.getAttackLabel(2), forState: UIControlState.Normal)
			fourthButton.setTitle(battle.getAttackLabel(3), forState: UIControlState.Normal)
			nextButton.setTitle(nil, forState: UIControlState.Normal)
			cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
		case .Switch(let page):
			firstButton.setTitle(battle.getPersonLabel(page * 4), forState: UIControlState.Normal)
			secondButton.setTitle(battle.getPersonLabel(page * 4 + 1), forState: UIControlState.Normal)
			thirdButton.setTitle(battle.getPersonLabel(page * 4 + 2), forState: UIControlState.Normal)
			fourthButton.setTitle(battle.getPersonLabel(page * 4 + 3), forState: UIControlState.Normal)
			nextButton.setTitle("Next", forState: UIControlState.Normal)
			cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
		case .ItemPick(let page):
			firstButton.setTitle(battle.getItemLabel(page * 4), forState: UIControlState.Normal)
			secondButton.setTitle(battle.getItemLabel(page * 4 + 1), forState: UIControlState.Normal)
			thirdButton.setTitle(battle.getItemLabel(page * 4 + 2), forState: UIControlState.Normal)
			fourthButton.setTitle(battle.getItemLabel(page * 4 + 3), forState: UIControlState.Normal)
			nextButton.setTitle("Next", forState: UIControlState.Normal)
			cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
		case .ItemTarget(let page, _):
			firstButton.setTitle(battle.getItemTargetlabel(page * 4), forState: UIControlState.Normal)
			secondButton.setTitle(battle.getItemTargetlabel(page * 4 + 1), forState: UIControlState.Normal)
			thirdButton.setTitle(battle.getItemTargetlabel(page * 4 + 2), forState: UIControlState.Normal)
			fourthButton.setTitle(battle.getItemTargetlabel(page * 4 + 3), forState: UIControlState.Normal)
			nextButton.setTitle("Next", forState: UIControlState.Normal)
			cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
			break
		}
	}
	
	//MARK: delegate functions
	func switchAnim(onPlayer: Bool)
	{
		let actingOnPosition = (onPlayer ? playerPosition : enemyPosition)
		let actingOnLabel = (onPlayer ? playerStats : enemyStats)
		
		//do the actual animation
		animating = true
		actingOnPosition.constant = 300 * (onPlayer ? 1 : -1)
		UIView.animateWithDuration(1.0, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations:
			{
				self.view.layoutIfNeeded()
				actingOnLabel.alpha = 0
				
			})
			{ (success) in
				self.labelsChanged()
				
				actingOnPosition.constant = 0
				UIView.animateWithDuration(1.0, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations:
					{
						self.view.layoutIfNeeded()
						actingOnLabel.alpha = 1
					})
					{ (success) in
						self.animating = false
				}
		}
	}
	
	func runMessage(message:String, shake:Bool)
	{
		messages.append("\(shake ? "%" : "")\(message)")
		if !writingMessages
		{
			writingMessages = true
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), messageThread)
		}
	}
	
	func shake()
	{
		textParser.shake()
	}
	
	func victory()
	{
		endingHook = victoryHook
		runMessage("The party was victorious!", shake: false)
		
		//award money
		var battleMoney = 0
		for enemy in battle.enemies
		{
			battleMoney += moneyForLevel(enemy.level)
		}
		battle.money += battleMoney
		runMessage("You got \(battleMoney) karma!", shake: false)
		
		//award EXP
		var battleEXP = 0
		for enemy in battle.enemies
		{
			if !enemy.good
			{
				//you don't get experience for captured enemies
				//so please don't capture everyone
				battleEXP += enemy.experience
			}
		}
		
		//award EXP based on turns spent in battle
		let netTurns = battle.playerTurnDist.reduce(0) { $0 + $1 }
		for (i, player) in battle.players.enumerate()
		{
			let exp = netTurns * battle.playerTurnDist[i] / netTurns
			if exp != 0
			{
				player.experience += exp
				runMessage("\(player.name) got \(exp) experience!", shake: false)
			}
		}
		
		printFillerLine()
	}
	
	private func victoryHook()
	{
		//any enemies who are good should join the party reserve
		var newAdditions = [Creature]()
		for enemy in battle.enemies
		{
			if enemy.good
			{
				//give that enemy a name now that they're a party member
				//this is done here and not in the capture code, because otherwise you'd see
				//the enemy suddenly become named when you capture it
				enemy.generateName()
				
				//add it to the new additions list
				newAdditions.append(enemy)
			}
		}
		
		saveState = kSaveStateNone
		endOfBattleHook(false, newAdditions, battle.money)
		navigationController!.popViewControllerAnimated(true)
	}
	
	func defeat()
	{
		endingHook = defeatHook
		runMessage("The party was annihilated!", shake: true)
		printFillerLine()
	}
	
	private func defeatHook()
	{
		saveState = kSaveStateNone
		endOfBattleHook(true, nil, 0)
		navigationController!.popViewControllerAnimated(true)
	}
	
	func flee()
	{
		endingHook = fleeHook
		runMessage("The battle is over!", shake: false)
		for enemy in battle.enemies
		{
			if enemy.good
			{
				runMessage("\(enemy.name) was left behind!", shake: false)
			}
		}
		printFillerLine()
	}
	
	private func fleeHook()
	{
		saveState = kSaveStateNone
		endOfBattleHook(false, nil, 0)
		navigationController!.popViewControllerAnimated(true)
	}
	
	private func printFillerLine()
	{
		runMessage("                                                             ", shake: false)
	}
}