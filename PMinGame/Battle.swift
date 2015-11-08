//
//  Battle.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/3/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation

let kWorstEffectivenessLabel = " 👎"
let kBestEffectivenessLabel = " 👍"

protocol BattleDelegate
{
	func runMessage(message:String)
	func victory()
	func defeat()
	func switchAnim(onPlayer:Bool)
}

enum Order
{
	case UseAttack(Attack)
	case SwitchTo(Creature)
	case UseItem(Item, Creature)
}

class Battle
{
	//contents data
	internal var players = [Creature]()
	internal var enemies = [Creature]()
	internal var playerItems = [Item]()
	private weak var player:Creature!
	private weak var enemy:Creature!
	
	//turn order data
	private let defaultTurnOrder:Bool
	private var turnOrder:Bool?
	private var playerOrder:Order?
	private var enemyOrder:Order?
	
	//external variables
	var delegate:BattleDelegate!
	
	
	init()
	{
		//TODO: load the real party
		players.append(Creature(job: "inventor", level: 10, good: true))
		players.append(Creature(job: "barbarian", level: 10, good: true))
		players.append(Creature(job: "soldier", level: 10, good: true))
		players.append(Creature(job: "mystic", level: 10, good: true))
		players.append(Creature(job: "rogue", level: 10, good: true))
		players.append(Creature(job: "honored dead", level: 10, good: true))
		
		//TODO: load the real encounter
		enemies.append(Creature(job: "shape of fire", level: 10, good: false))
		
		//TODO: get the real inventory
		playerItems.append(Item(type: "poultice"))
		playerItems.append(Item(type: "miracle cure"))
		playerItems.append(Item(type: "smelling salts"))
		
		//reset everyone's status
		for player in players
		{
			player.resetStatus()
		}
		//it's probably not strictly necessary to reset the status of the enemies, but I'm doing it just in case
		//I add the ability to fight the same group of enemies again
		for enemy in enemies
		{
			enemy.resetStatus()
		}
		
		//get the first player and the first enemy
		//TODO: make sure you don't pick a 0 health party member as the first person out, etc
		enemy = enemies[0]
		player = players[0]
		
		//get the default turn order
		defaultTurnOrder = arc4random_uniform(100) < 50
	}
	
	//MARK: operation
	func pickSwitch(num:Int)
	{
		if players.count > num && !players[num].dead && !(players[num] === player)
		{
			playerOrder = .SwitchTo(players[num])
		}
	}
	
	func pickAttack(num:Int)
	{
		if getValidAttacksFor(player).count == 0
		{
			if num == 0
			{
				playerOrder = .UseAttack(player.desperationAttack)
			}
		}
		else if player.attacks.count > num && player.attacks[num].powerPoints > 0
		{
			playerOrder = .UseAttack(player.attacks[num])
		}
	}
	private func useAttack(user:Creature, usee:Creature, used:Attack)
	{
		user.useAttackOn(used, on: usee)
		{ (message) in
			self.delegate.runMessage(message)
		}
	}
	private func useSwitch(from:Creature, to:Creature)
	{
		if from.good
		{
			player = to
		}
		else
		{
			enemy = to
		}
		if from.dead
		{
			delegate.runMessage("\(to.name) switched in!")
		}
		else if from.injured && !to.injured
		{
			delegate.runMessage("\(to.name) leapt in to protect \(from.name)!")
		}
		else
		{
			delegate.runMessage("\(to.name) switched in for \(from.name)!")
		}
		delegate.switchAnim(from.good)
	}
	private func useOrder(user:Creature, usee:Creature, used:Order)
	{
		switch(used)
		{
		case .UseAttack(let attack): useAttack(user, usee: usee, used: attack)
		case .SwitchTo(let to): useSwitch(user, to: to)
		}
	}
	
	//organizational getters
	private var playerAttack:Attack?
	{
		switch(playerOrder!)
		{
		case .UseAttack(let attack): return attack
		default: return nil
		}
	}
	
	private var enemyAttack:Attack?
		{
			switch(enemyOrder!)
			{
			case .UseAttack(let attack): return attack
			default: return nil
			}
	}
	private var playerSwitch:Creature?
	{
		switch(playerOrder!)
		{
		case .SwitchTo(let to): return to
		default: return nil
		}
	}
	
	private var enemySwitch:Creature?
	{
		switch(enemyOrder!)
		{
		case .SwitchTo(let to): return to
		default: return nil
		}
	}
	
	func turnOperation()
	{
		if playerOrder != nil && turnOrder == nil
		{
			//pick an attack for the enemy
			enemyOrder = .UseAttack(aiPickFor(enemy))
			
			//get the turn order
			if playerAttack != nil && enemyAttack != nil && playerAttack!.quick && !enemyAttack!.quick
			{
				turnOrder = true
			}
			else if playerAttack != nil && enemyAttack != nil && !playerAttack!.quick && enemyAttack!.quick
			{
				turnOrder = false
			}
			//TODO: if one player is using an item, and the other player isn't, that player goes FIRST
			else if playerSwitch != nil && enemySwitch == nil
			{
				turnOrder = player.dead
			}
			else if playerSwitch == nil && enemySwitch != nil
			{
				turnOrder = !enemy.dead
			}
			else
			{
				turnOrder = defaultTurnOrder
			}
		}
		if turnOrder != nil
		{
			//null the attacks of dead people
			if player.dead && playerAttack != nil && playerAttack != nil
			{
				playerOrder = nil
			}
			if enemy.dead && enemyOrder != nil && enemyAttack != nil
			{
				enemyOrder = nil
			}
			
			//also null the turn order, if both sides died
			if playerOrder == nil && enemyOrder == nil
			{
				turnOrder = nil
			}
			else if turnOrder!
			{
				if playerOrder != nil
				{
					useOrder(player, usee: enemy, used: playerOrder!)
					playerOrder = nil
				}
				else
				{
					useOrder(enemy, usee: player, used: enemyOrder!)
					enemyOrder = nil
					turnOrder = nil
				}
			}
			else
			{
				if enemyOrder != nil
				{
					useOrder(enemy, usee: player, used: enemyOrder!)
					enemyOrder = nil
				}
				else
				{
					useOrder(player, usee: enemy, used: playerOrder!)
					playerOrder = nil
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
	
	private func getValidAttacksFor(cr:Creature) -> [Attack]
	{
		return cr.attacks.filter() { $0.powerPoints > 0 }
	}
	
	private func aiPickFor(cr:Creature) -> Attack
	{
		//don't use attacks with no pp
		let valid = getValidAttacksFor(cr)
		
		//if there are no valid attacks, use a desperation attack
		if valid.count == 0
		{
			return cr.desperationAttack
		}
		
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
	
	private func getBestEffectivenessLabel(player:Creature) -> String
	{
		var bestLabel = ""
		for attack in player.attacks
		{
			let label = getEffectivenessLabel(attack.type)
			if label == kBestEffectivenessLabel
			{
				return label
			}
			else if label != kWorstEffectivenessLabel || bestLabel == ""
			{
				bestLabel = label
			}
		}
		return bestLabel
	}
	
	private func getEffectivenessLabel(type:String?) -> String
	{
		if let type = type
		{
			let multiplier = enemy.typeMultiplier(type)
			if multiplier > 100
			{
				return kBestEffectivenessLabel
			}
			else if (multiplier < 100)
			{
				return kWorstEffectivenessLabel
			}
		}
		return ""
	}
	
	func getItemLabel(num:Int) -> String?
	{
		if playerItems.count > num
		{
			return playerItems[num].type
		}
		return nil
	}
	
	func getPersonlabel(num:Int) -> String?
	{
		if players.count > num
		{
			if players[num] === player
			{
				return "ALREADY OUT"
			}
			else if players[num].dead
			{
				return "UNCONSCIOUS"
			}
			else
			{
				let player = players[num]
				return player.name + getBestEffectivenessLabel(player)
			}
		}
		return nil
	}
	
	func getAttackLabel(num:Int) -> String?
	{
		if getValidAttacksFor(player).count == 0
		{
			if num == 0
			{
				let attack = player.desperationAttack
				return attack.label + getEffectivenessLabel(attack.type)
			}
		}
		else if player.attacks.count > num
		{
			let attack = player.attacks[num]
			return attack.label + getEffectivenessLabel(attack.type)
		}
		return nil
	}
}