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
	func runMessage(message:String, shake: Bool)
	func victory()
	func defeat()
	func flee()
	func switchAnim(onPlayer:Bool)
}

enum Order
{
	case UseAttack(Attack)
	case SwitchTo(Creature)
	case UseItem(Item, Creature)
	case TryFlee()
	case TryCapture()
}

class Battle
{
	//contents data
	internal var players:[Creature]
	internal var enemies = [Creature]()
	internal var playerItems = [Item]()
	internal weak var player:Creature!
	internal weak var enemy:Creature!
	
	internal var playerTurnDist = [Int]()
	internal var money:Int
	
	//turn order data
	private let defaultTurnOrder:Bool
	private var turnOrder:Bool?
	private var playerOrder:Order?
	private var enemyOrder:Order?
	
	//external variables
	var delegate:BattleDelegate!
	var savePlayersCallback:(()->())!
	
	private func save()
	{
		let d = NSUserDefaults.standardUserDefaults()
		d.setInteger(money, forKey: "battleMoney")
		d.setBool(defaultTurnOrder, forKey: "battleTurnOrder")
		d.setInteger(enemies.count, forKey: "battleEnemies")
		for (i, en) in enemies.enumerate()
		{
			d.setObject(en.creatureString, forKey: "battleEnemy\(i)")
		}
		savePlayersCallback()
		for (i, en) in enemies.enumerate()
		{
			if en === enemy
			{
				d.setInteger(i, forKey: "battleActiveEnemy")
				break
			}
		}
		for (i, pl) in players.enumerate()
		{
			if pl === player
			{
				d.setInteger(i, forKey: "battleActivePlayer")
				break
			}
		}
		for i in 0..<players.count
		{
			d.setInteger(playerTurnDist[i], forKey: "battlePlayerTurnDist\(i)")
		}
	}
	
	init(players:[Creature], money:Int, encounterType:String, difficulty:Int, savePlayersCallback: ()->())
	{
		self.money = money
		self.players = players
		self.savePlayersCallback = savePlayersCallback
		
		//TODO: get the real inventory
		playerItems.append(Item(type: "poultice"))
		playerItems.append(Item(type: "miracle cure"))
		playerItems.append(Item(type: "smelling salts"))
		
		if saveState == kSaveStateBattle
		{
			//load battle
			let d = NSUserDefaults.standardUserDefaults()
			self.money = d.integerForKey("battleMoney")
			defaultTurnOrder = d.boolForKey("battleTurnOrder")
			let battleEnemies = d.integerForKey("battleEnemies")
			for i in 0..<battleEnemies
			{
				enemies.append(Creature(string: d.stringForKey("battleEnemy\(i)")!))
			}
			
			let enI = d.integerForKey("battleActiveEnemy")
			let plI = d.integerForKey("battleActivePlayer")
			enemy = enemies[enI]
			player = players[plI]
			
			for i in 0..<players.count
			{
				playerTurnDist.append(d.integerForKey("battlePlayerTurnDist\(i)"))
			}
		}
		else
		{
			//load an encounter
			let numberEnemies = 1
			let encounterFlat = PlistService.loadValueFlat("EncounterGenerator", encounterType) as! [[String : AnyObject]]
			for _ in 0..<numberEnemies
			{
				var possibilities = [String]()
				for enemy in encounterFlat
				{
					if difficulty >= enemy["minimum level"] as! Int
					{
						possibilities.append(enemy["job"] as! String)
					}
				}
				let pick = Int(arc4random_uniform(UInt32(possibilities.count)))
				enemies.append(Creature(job: possibilities[pick], level: difficulty, good: false))
			}
			
			//reset everyone's status
			for player in players
			{
				player.resetStatus()
				playerTurnDist.append(0)
			}
			//it's probably not strictly necessary to reset the status of the enemies, but I'm doing it just in case
			//I add the ability to fight the same group of enemies again
			for enemy in enemies
			{
				enemy.resetStatus()
			}
			
			//get the first player and the first enemy
			for cr in enemies
			{
				if !cr.dead
				{
					enemy = cr
					break
				}
			}
			for cr in players
			{
				if !cr.dead
				{
					player = cr
					break
				}
			}
			
			//get the default turn order
			defaultTurnOrder = arc4random_uniform(100) < 50
			
			save()
		}
	}
	
	//MARK: operation
	func pickSwitch(num:Int) -> Bool
	{
		if players.count > num && !players[num].dead && !(players[num] === player)
		{
			playerOrder = .SwitchTo(players[num])
			turnOperation()
			return true
		}
		return false
	}
	
	func pickAttack(num:Int) -> Bool
	{
		if getValidAttacksFor(player).count == 0
		{
			if num == 0
			{
				playerOrder = .UseAttack(player.desperationAttack)
				turnOperation()
				return true
			}
		}
		else if player.attacks.count > num && player.attacks[num].powerPoints > 0
		{
			playerOrder = .UseAttack(player.attacks[num])
			turnOperation()
			return true
		}
		return false
	}
	
	func pickCapture()
	{
		//TODO: you shouldn't be able to capture bosses, etc
		if !player.dead && !enemy.dead && enemy.injured
		{
			playerOrder = .TryCapture()
			turnOperation()
		}
	}
	
	func pickFlee()
	{
		if !player.dead
		{
			playerOrder = .TryFlee()
			turnOperation()
		}
	}
	
	func pickItem(num:Int, item:Item) -> Bool
	{
		if players.count > num && ((players[num].dead && item.targetsDead) || (!players[num].dead && item.targetsAlive))
		{
			playerOrder = .UseItem(item, players[num])
			turnOperation()
			return true
		}
		return false
	}
	
	private func messageHandler(message:String, shake:Bool = false)
	{
		self.delegate.runMessage(message, shake: shake)
	}
	
	private func useAttack(user:Creature, usee:Creature, used:Attack)
	{
		if user.statusEffectTurn(messageHandler)
		{
			if (user.useAttackOn(used, on: usee, messageHandler: messageHandler) && used.mug)
			{
				let moneyAmount = moneyForLevel(usee.level) / 2
				messageHandler("\(user.name) stole \(moneyAmount) karma from \(usee.name)!")
				if user.good
				{
					money += moneyAmount
				}
				else
				{
					money -= moneyAmount
				}
			}
		}
	}
	private func useSwitch(from:Creature, to:Creature)
	{
		from.statusEffectTurn(messageHandler)
		
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
			delegate.runMessage("\(to.name) switched in!", shake: false)
		}
		else if from.injured && !to.injured
		{
			delegate.runMessage("\(to.name) leapt in to protect \(from.name)!", shake: false)
		}
		else
		{
			delegate.runMessage("\(to.name) switched in for \(from.name)!", shake: false)
		}
		delegate.switchAnim(from.good)
	}
	private func useItem(user:Creature, item:Item, on:Creature)
	{
		if user.statusEffectTurn(messageHandler) || (item.useWhileImmobile && on === user)
		{
			on.useItem(item, messageHandler: messageHandler)
		}
		
		if on.good
		{
			playerItems = playerItems.filter() { $0.number > 0 }
		}
		else
		{
			//TODO: remove expended items from the enemy item list
			//dunno if I'll let enemies use items, though
		}
	}
	private func useFlee(user:Creature)
	{
		if user.statusEffectTurn(messageHandler)
		{
			let chance:UInt32
			if user.jobSneaky
			{
				chance = 85
			}
			else
			{
				chance = 45
			}
			
			if arc4random_uniform(100) < chance
			{
				messageHandler("\(user.name) ran away!")
				delegate.flee()
			}
			else
			{
				messageHandler("\(user.name) tried to run away, but failed!")
			}
		}
	}
	private func useCapture(user:Creature)
	{
		if Int(arc4random_uniform(100)) < enemy.captureChance
		{
			messageHandler("\(user.name) successfully captured \(enemy.name)!")
			enemy.capture()
		}
		else
		{
			messageHandler("\(user.name) tried to capture \(enemy.name), but failed!")
		}
	}
	
	private func useOrder(user:Creature, usee:Creature, used:Order)
	{
		switch(used)
		{
		case .UseAttack(let attack): useAttack(user, usee: usee, used: attack)
		case .SwitchTo(let to): useSwitch(user, to: to)
		case .UseItem(let item, let on): useItem(user, item: item, on: on)
		case .TryFlee(): useFlee(user)
		case .TryCapture(): useCapture(user)
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
	
	private var playerItem:Item?
	{
		switch(playerOrder!)
		{
		case .UseItem(let item, _): return item
		default: return nil
		}
	}
	
	private var enemyItem:Item?
	{
		switch(enemyOrder!)
		{
		case .UseItem(let item, _): return item
		default: return nil
		}
	}
	
	private var playerFlee:Bool
	{
		switch(playerOrder!)
		{
		case .TryFlee(): return true
		default: return false
		}
	}
	
	private var enemyFlee:Bool
	{
		switch(enemyOrder!)
		{
		case .TryFlee(): return true
		default: return false
		}
	}
	
	private var playerCapture:Bool
	{
		switch(playerOrder!)
		{
		case .TryCapture(): return true
		default: return false
		}
	}
	
	//no need for an enemyCapture, enemies will never try to capture players
	
	func turnOperation()
	{
		if playerOrder != nil && turnOrder == nil
		{
			//award a turn of player turn distribution
			for (i, pl) in players.enumerate()
			{
				if pl === player
				{
					playerTurnDist[i] += 1
					break
				}
			}
			
			
			//give the enemy AI an order
			if enemy.dead
			{
				//switch to another enemy if you can
				for enemy in enemies
				{
					if !enemy.dead
					{
						enemyOrder = .SwitchTo(enemy)
						break
					}
				}
			}
			else
			{
				//pick an attack for the enemy
				enemyOrder = .UseAttack(aiPickFor(enemy))
			}
			
			//get the turn order
			if playerAttack != nil && enemyAttack != nil && playerAttack!.quick && !enemyAttack!.quick
			{
				turnOrder = true
			}
			else if playerAttack != nil && enemyAttack != nil && !playerAttack!.quick && enemyAttack!.quick
			{
				turnOrder = false
			}
			else if playerCapture
			{
				turnOrder = true
			}
			else if playerFlee && !enemyFlee
			{
				turnOrder = true
			}
			else if !playerFlee && enemyFlee
			{
				turnOrder = false
			}
			else if playerItem != nil && enemyItem == nil
			{
				turnOrder = true
			}
			else if playerItem == nil && enemyItem != nil
			{
				turnOrder = false
			}
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
			if player.dead && playerOrder != nil && playerAttack != nil
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
			//check for victory or defeat
			var playerAlive = false
			for player in players
			{
				if !player.dead
				{
					playerAlive = true
					break
				}
			}
			if !playerAlive
			{
				delegate.defeat()
				return
			}
			
			var enemyAlive = false
			for enemy in enemies
			{
				if !enemy.dead
				{
					enemyAlive = true
					break
				}
			}
			if !enemyAlive
			{
				delegate.victory()
				return
			}
			
			//save the battle
			save()
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
			let label = getEffectivenessLabel(attack.type, ranged: attack.ranged)
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
	
	private func getEffectivenessLabel(type:String?, ranged:Bool) -> String
	{
		if let type = type
		{
			let multiplier = enemy.typeAndRangeMultiplier(type, attackRanged: ranged)
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
	
	func getItemTargetlabel(num:Int) -> String?
	{
		if players.count > num
		{
			return players[num].name
		}
		return nil
	}
	
	func getPersonLabel(num:Int) -> String?
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
				return attack.label + getEffectivenessLabel(attack.type, ranged: attack.ranged)
			}
		}
		else if player.attacks.count > num
		{
			let attack = player.attacks[num]
			return attack.label + getEffectivenessLabel(attack.type, ranged: attack.ranged)
		}
		return nil
	}
}