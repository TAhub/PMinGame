//
//  Creature.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/3/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation

//constants
private let kStatBonus = 5
private let kHealthLevelBonus = 5

class Creature
{
	//identity
	private var job:String = "Sample"
	
	//permanent stats
	private var level:Int = 1
	
	//variables
	private var health:Int = 0
	{
		didSet
		{
			health = min(max(health, 0), maxHealth)
		}
	}
	
	//status
	private var paralysis:Int?
	private var freeze:Int?
	private var bleed:Int?
	private var burning:Int?
	private var attackStep:Int = 0
	{
		didSet
		{
			attackStep = max(min(attackStep, 3), -3)
		}
	}
	private var defenseStep:Int = 0
	{
		didSet
		{
			defenseStep = max(min(defenseStep, 3), -3)
		}
	}
	private var accuracyStep:Int = 0
	{
		didSet
		{
			accuracyStep = max(min(accuracyStep, 3), -3)
		}
	}
	private var dodgeStep:Int = 0
	{
		didSet
		{
			dodgeStep = max(min(dodgeStep, 3), -3)
		}
	}
	
	//derived stats
	private var accuracy:Int
	{
		return PlistService.loadValue("Jobs", job, "accuracy") as! Int + level
	}
	private var dodge:Int
	{
		return PlistService.loadValue("Jobs", job, "dodge") as! Int + level
	}
	private var bruteAttack:Int
	{
		return PlistService.loadValue("Jobs", job, "brute attack") as! Int + level
	}
	private var bruteDefense:Int
	{
		return PlistService.loadValue("Jobs", job, "brute defense") as! Int + level
	}
	private var cleverAttack:Int
	{
		return PlistService.loadValue("Jobs", job, "clever attack") as! Int + level
	}
	private var cleverDefense:Int
	{
		return PlistService.loadValue("Jobs", job, "clever defense") as! Int + level
	}
	private var maxHealth:Int
	{
		let baseHealth = PlistService.loadValue("Jobs", job, "health") as! Int
		let healthMult = 100 + kHealthLevelBonus * min(level, 30)
		return baseHealth * healthMult / 100
	}
	private var type:String
	{
		return PlistService.loadValue("Jobs", job, "type") as! String
	}
	
	//attack functions
	private func stepMultiplier(steps:Int) -> Int
	{
		//TODO: calculate the actual effect of the steps
		switch(steps)
		{
		case -3: return 50
		case -2: return 65
		case -1: return 80
		case 0: return 100
		case 1: return 130
		case 2: return 160
		case 3: return 190
		default: assertionFailure("ERROR: Invalid step modifier!"); return 100
		}
	}
	private func typeMultiplier(attackType:String) -> Int
	{
		switch(PlistService.loadValue("Types", attackType, type) as! Int)
		{
		case -2: return 0
		case -1: return 50
		case 0: return 100
		case 1: return 150
		case 2: return 200
		default: assertionFailure("ERROR: Invalid type modifier!"); return 100
		}
	}
	private func useAttackOn(attack:Attack, on:Creature)
	{
		//TODO: fail here and output a message if you are paralyzed or frozen
		
		//use power points
		attack.powerPoints -= 1
		
		//see if you hit, missed, or crit
		var hit:Bool = false
		var crit:Bool = false
		if let baseAccuracy = attack.accuracy
		{
			var modifiedAccuracy = baseAccuracy
			
			//apply stats
			modifiedAccuracy = modifiedAccuracy * (100 + (accuracy - on.dodge) * kStatBonus) / 100
			
			//apply steps
			modifiedAccuracy = modifiedAccuracy * stepMultiplier(accuracyStep) / on.stepMultiplier(on.dodgeStep)
			
			//apply minimum
			modifiedAccuracy = max(modifiedAccuracy, 5)
			
			if modifiedAccuracy > 100
			{
				//you'll always hit, so this is instead for a crit
				hit = true
				modifiedAccuracy -= 100
			}
			
			let roll = Int(arc4random_uniform(100))
			if roll <= modifiedAccuracy
			{
				//you rolled successfully!
				if hit
				{
					crit = true
				}
				else
				{
					hit = true
				}
			}
			
			//TODO: maybe a small chance to turn a non-critical hit into a crit?
		}
		else
		{
			//the attack is auto-hitting (and thus never crits, either)
			hit = true
		}
		
		if hit
		{
			//TODO: output the attack use message
			
			var applyEffects:Bool = true
			
			if crit
			{
				//TODO: output a "it was a crit" message
			}
			
			if let damage = attack.damage
			{
				//apply element
				var finalDamage = damage * on.typeMultiplier(attack.type!) / 100
				if finalDamage == 0
				{
					//TODO: output a "the attack was ineffective!" message
					applyEffects = false
				}
				else
				{
					//apply crit
					if crit
					{
						finalDamage = finalDamage + finalDamage / 2
					}
					
					//apply stats
					let attackS:Int
					let defenseS:Int
					if attack.clever
					{
						attackS = cleverAttack
						defenseS = on.cleverDefense
					}
					else
					{
						attackS = bruteAttack
						defenseS = on.bruteDefense
					}
					finalDamage = finalDamage * (100 + (attackS - defenseS) * kStatBonus) / 100
					
					//apply steps
					finalDamage = finalDamage * stepMultiplier(attackStep) / on.stepMultiplier(on.defenseStep)
					
					//apply minimum
					finalDamage = max(finalDamage, 1)
					
					//do the damage
					on.health -= finalDamage
					//TODO: output a damage message (be sure to mention the damage type)
				}
			}
			
			if applyEffects
			{
				//TODO: apply all effects
				//that is, step changes, status effects, mug, leech, etc
				//remember that all % chance stuff becomes 50% more likely if it's a crit!
				//also remember to take immunities into account
			}
		}
		else
		{
			//TODO: output a miss message
		}
	}
}