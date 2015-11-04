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
			battle.useAttack(0, messageHandler: runMessage)
		}
		else if sender === secondButton
		{
			battle.useAttack(1, messageHandler: runMessage)
		}
		else if sender === thirdButton
		{
			battle.useAttack(2, messageHandler: runMessage)
		}
		else if sender === fourthButton
		{
			battle.useAttack(3, messageHandler: runMessage)
		}
		setLabels()
	}
	
	private func runMessage(message:String)
	{
		messages.append(message)
	}
	
	private var messages = [String]()
	
	private var battle:Battle!
	
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
		
		//TODO: find some way to terminate if controller is removed
		
		var oldMessages = [String]()
		
		while (true)
		{
			usleep(5000)
			
			if messages.count > 0
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
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		//diagnostics
//		PlistService.jobStatDiagnostic()
		
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
		setLabels()
		
		//launch the message thread
		textParser.text = ""
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), messageThread)
    }
	
	private func setLabels()
	{
		playerStats.text = battle.playerStat
		enemyStats.text = battle.enemyStat
		firstButton.setTitle(battle.getAttackLabel(0), forState: UIControlState.Normal)
		secondButton.setTitle(battle.getAttackLabel(1), forState: UIControlState.Normal)
		thirdButton.setTitle(battle.getAttackLabel(2), forState: UIControlState.Normal)
		fourthButton.setTitle(battle.getAttackLabel(3), forState: UIControlState.Normal)
	}
}
