//
//  Battle.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/3/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation

class Battle
{
	private var players = [Creature]()
	private var enemies = [Creature]()
	private weak var player:Creature!
	private weak var enemy:Creature!
	
	init()
	{
		players.append(Creature())
		enemies.append(Creature())
		
		//get the first player and the first enemy
		enemy = enemies[0]
		player = players[0]
		
		//TODO: register a bunch of stations to pass messages
	}
	
	deinit
	{
		//TODO: unregister those stations
	}
	
	var playerStat:String
	{
		return player.statLine
	}
	
	var enemyStat:String
	{
		return enemy.statLine
	}
	
	func useAttack(num:Int, messageHandler:(String)->())
	{
		if player.attacks.count > num
		{
			player.useAttackOn(player.attacks[num], on: enemy, messageHandler: messageHandler)
		}
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