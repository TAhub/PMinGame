//
//  BattleViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/4/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

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
	
	@IBAction func pressButton(sender: UIButton)
	{
		if !writingMessages && !animating
		{
			if sender === firstButton
			{
				battle.pickAttack(0)
			}
			else if sender === secondButton
			{
				battle.pickAttack(1)
			}
			else if sender === thirdButton
			{
				battle.pickAttack(2)
			}
			else if sender === fourthButton
			{
				battle.pickAttack(3)
			}
			battle.turnOperation()
			labelsChanged()
		}
	}
	
	//MARK: text parser stuff
	private var oldMessages = [String]()
	private var messages = [String]()
	private var writingMessages:Bool = false
	
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
			if oldMessages.count >= 3
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
			self.enemyView.layoutIfNeeded()
			self.playerView.layoutIfNeeded()
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
	
	//MARK: delegate functions
	func labelsChanged()
	{
		playerStats.text = battle.playerStat
		enemyStats.text = battle.enemyStat
		firstButton.setTitle(battle.getAttackLabel(0), forState: UIControlState.Normal)
		secondButton.setTitle(battle.getAttackLabel(1), forState: UIControlState.Normal)
		thirdButton.setTitle(battle.getAttackLabel(2), forState: UIControlState.Normal)
		fourthButton.setTitle(battle.getAttackLabel(3), forState: UIControlState.Normal)
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
