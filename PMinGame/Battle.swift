//
//  Battle.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/3/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation

protocol BattleDelegate
{
	func labelsChanged()
	func runMessage(message:String)
	func victory()
	func defeat()
}

class Battle
{
	//contents data
	private var players = [Creature]()
	private var enemies = [Creature]()
	private weak var player:Creature!
	private weak var enemy:Creature!
	
	//turn order data
	private let defaultTurnOrder:Bool
	private var turnOrder:Bool?
	private var playerAttack:Attack?
	private var enemyAttack:Attack?
	
	//external variables
	var delegate:BattleDelegate!
	
	
	init()
	{
		players.append(Creature(job: "inventor", level: 5, good: true))
		enemies.append(Creature(job: "fencer", level: 3, good: false))
		
		//get the first player and the first enemy
		enemy = enemies[0]
		player = players[0]
		
		//get the default turn order
		defaultTurnOrder = arc4random_uniform(100) < 50
	}
	
	//MARK: operation
	func pickAttack(num:Int)
	{
		if player.attacks.count > num && player.attacks[num].powerPoints > 0
		{
			playerAttack = player.attacks[num]
		}
	}
	private func useAttack(user:Creature, usee:Creature, used:Attack)
	{
		user.useAttackOn(used, on: usee)
		{ (message) in
			self.delegate.runMessage(message)
		}
		delegate.labelsChanged()
	}
	func turnOperation()
	{
		if playerAttack != nil && turnOrder == nil
		{
			//pick an attack for the enemy
			enemyAttack = aiPickFor(enemy)
			
			//get the turn order
			if playerAttack!.quick && !enemyAttack!.quick
			{
				turnOrder = true
			}
			else if !playerAttack!.quick && enemyAttack!.quick
			{
				turnOrder = false
			}
			//TODO: if one player is using an item, and the other player isn't, that player goes FIRST
			//TODO: if one player is switching people, and that player's person out is dead, that player goes FIRST
			//TODO: if one player is switching people, that player goes LAST
			else
			{
				turnOrder = defaultTurnOrder
			}
		}
		if turnOrder != nil
		{
			if turnOrder!
			{
				if playerAttack != nil
				{
					useAttack(player, usee: enemy, used: playerAttack!)
					playerAttack = nil
				}
				else
				{
					useAttack(enemy, usee: player, used: enemyAttack!)
					enemyAttack = nil
					turnOrder = nil
				}
			}
			else
			{
				if enemyAttack != nil
				{
					useAttack(enemy, usee: player, used: enemyAttack!)
					enemyAttack = nil
				}
				else
				{
					useAttack(player, usee: enemy, used: playerAttack!)
					playerAttack = nil
					turnOrder = nil
				}
			}
		}
		
		if turnOrder == nil
		{
			//TODO: check for victory or defeat
			//and if they come up, call the "victory" or "defeat" delegate functions
		}
	}
	private func aiPickFor(cr:Creature) -> Attack
	{
		//don't use attacks with no pp
		let valid = cr.attacks.filter() { $0.powerPoints > 0 }
		
		//pick a random attack from that list
		return valid[Int(arc4random_uniform(UInt32(valid.count)))]
	}
	
	//MARK: get data
	var playerStat:String
	{
		return player.statLine
	}
	
	var enemyStat:String
	{
		return enemy.statLine
	}
	
	func getAttackLabel(num:Int) -> String?
	{
		if player.attacks.count > num
		{
			let attack = player.attacks[num]
			var label = attack.label
			if let type = attack.type
			{
				let multiplier = enemy.typeMultiplier(type)
				if multiplier > 100
				{
					label += " 👍"
				}
				else if (multiplier < 100)
				{
					label += " 👎"
				}
			}
			return label
		}
		return nil
	}
}