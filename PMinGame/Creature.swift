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
private let kBleedDamage = 5

class Creature
{
	//identity
	private var job:String = "barbarian"
	private var name:String = "NAME"
	
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
	
	//attacks
	internal var attacks:[Attack] = [Attack(attack: "electric sight"), Attack(attack: "freeze ray"), Attack(attack: "brand")]
	
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
		let healthMult = 100 + kHealthLevelBonus * min(level - 1, 30)
		return baseHealth * healthMult / 100
	}
	private var type:String
	{
		return PlistService.loadValue("Jobs", job, "type") as! String
	}
	private var burningImmunity:Bool
	{
		return PlistService.loadValue("Jobs", job, "burning immunity") != nil
	}
	private var bleedImmunity:Bool
	{
		return PlistService.loadValue("Jobs", job, "bleed immunity") != nil
	}
	private var paralysisImmunity:Bool
	{
		return PlistService.loadValue("Jobs", job, "paralysis immunity") != nil
	}
	private var freezeImmunity:Bool
	{
		return PlistService.loadValue("Jobs", job, "freeze immunity") != nil
	}
	
	//attack functions
	private func stepMultiplier(steps:Int) -> Int
	{
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
	internal func typeMultiplier(attackType:String) -> Int
	{
		switch(PlistService.loadValue("Types", attackType, type) as! Int)
		{
		case -2: return 0
		case -1: return 50
		case 0: return 100
		case 1: return 140
		case 2: return 180
		default: assertionFailure("ERROR: Invalid type modifier!"); return 100
		}
	}
	private func runMessage(messageHandler:(String)->(), on:Creature)(message:String)
	{
		let onName = on.name
		let he = "he"
		let his = "his"
		let himself = "himself"
		let finalMessage = message.stringByReplacingOccurrencesOfString("*Name", withString: name).stringByReplacingOccurrencesOfString("*OnName", withString: onName).stringByReplacingOccurrencesOfString("*his", withString: his).stringByReplacingOccurrencesOfString("*himself", withString: himself).stringByReplacingOccurrencesOfString("*he", withString: he)
		messageHandler(finalMessage)
	}
	
	private func shouldShakeOffStatus(baseChance baseChance:Int, chanceRamp:Int)(status:Int)->Bool
	{
		if status == 0
		{
			//can't shake off a status on the first round
			return false
		}
		let roll = Int(arc4random_uniform(100))
		return roll <= status * chanceRamp + baseChance
	}
	
	private func takeBleedDamage()->Int
	{
		var damage = maxHealth * kBleedDamage / 100
		damage = min(damage, health - 1)
		health -= damage
		return damage
	}
	
	private func shouldSkipTurnFromParalysis()->Bool
	{
		return arc4random_uniform(100) <= 90
	}
	
	internal func useAttackOn(attack:Attack, on:Creature, messageHandler:(String)->())
	{
		let runM = runMessage(messageHandler, on: on)
		
		//check status effects that do damage to you
		let bleedFunction = shouldShakeOffStatus(baseChance: 10, chanceRamp: 5)
		if bleed != nil
		{
			if health < 2 || bleedFunction(status: bleed!)
			{
				runM(message: "*Name stopped bleeding!")
				bleed = nil
			}
			else
			{
				bleed! += 1
				let bleedDamage = takeBleedDamage()
				runM(message: "*Name bled out \(bleedDamage) health!")
			}
		}
		if burning != nil
		{
			if health < 2 || bleedFunction(status: burning!)
			{
				runM(message: "*Name put *himself out!")
				burning = nil
			}
			else
			{
				burning! += 1
				let burnDamage = takeBleedDamage()
				runM(message: "*Name burned away \(burnDamage) health!")
			}
		}
		
		//check status effects that end your turn
		let paralFunction = shouldShakeOffStatus(baseChance: 50, chanceRamp: 25)
		if paralysis != nil
		{
			if paralFunction(status: paralysis!)
			{
				runM(message: "*Name shook off paralysis!")
				paralysis = nil
			}
			else
			{
				paralysis! += 1
				if shouldSkipTurnFromParalysis()
				{
					runM(message: "*Name was unable to act due to being paralyzed!")
					return
				}
			}
		}
		if freeze != nil
		{
			if paralFunction(status: freeze!)
			{
				runM(message: "*Name stopped being frozen!")
				freeze = nil
			}
			else
			{
				freeze! += 1
				if shouldSkipTurnFromParalysis()
				{
					runM(message: "*Name was unable to act due to being frozen!")
					return
				}
			}
		}
		
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
			runM(message: attack.message)
			
			var applyEffects:Bool = true
			
			if let damage = attack.damage
			{
				//apply element
				var finalDamage = damage * on.typeMultiplier(attack.type!) / 100
				if finalDamage == 0
				{
					//TODO: output a "the attack was ineffective!" message
					runM(message: "The attack was ineffective!")
					applyEffects = false
				}
				else
				{
					//apply crit
					if crit
					{
						finalDamage = finalDamage + finalDamage / 2
						
						//TODO: output a "it was a crit" message
						//this is the crit message for damaging attacks
						runM(message: "WHAM!")
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
					
					//apply random factor
					finalDamage = finalDamage * (100 - Int(arc4random_uniform(5))) / 100
					
					//apply minimum
					finalDamage = max(finalDamage, 1)
					
					//do the damage
					on.health -= finalDamage
					//TODO: output a damage message (be sure to mention the damage type)
					runM(message: "*OnName took \(finalDamage) damage!")
					
					if attack.leech
					{
						health += finalDamage
						runM(message: "*Name is healed for \(finalDamage) health!")
					}
				}
			}
			else if crit
			{
				//TODO: output a "it was a crit" message
				//this is the crit message for non-damaging attacks
				runM(message: "WHAM!")
			}
			
			if applyEffects
			{
				//apply effects
				applyEffectsTo(attack.userEffects, crit: crit, messageHandler: messageHandler)
				on.applyEffectsTo(attack.enemyEffects, crit: crit, messageHandler: messageHandler)
			}
		}
		else
		{
			//TODO: output a miss message
			runM(message: "*Name tried to use \(attack.attack), but *he missed!")
		}
	}
	
	private func stepEffectMessage(descriptor:String, oldStep:Int, newStep:Int, messageHandler:(String)->())
	{
		let runM = runMessage(messageHandler, on: self)
		
		if oldStep > newStep
		{
			runM(message: "*Name's \(descriptor) lowered!")
		}
		else if oldStep < newStep
		{
			runM(message: "*Name's \(descriptor) rose!")
		}
	}
	
	private func applyEffectsTo(attackEffect:AttackEffect?, crit:Bool, messageHandler:(String)->())
	{
		let runM = runMessage(messageHandler, on: self)
		
		if let attackEffect = attackEffect
		{
			//TODO: maybe status effect messages?
			
			if !bleedImmunity && statusEffectCheck(attackEffect.bleedChance, crit: crit)
			{
				bleed = 0
				runM(message: "*Name was given a bleeding wound!")
			}
			if !paralysisImmunity && statusEffectCheck(attackEffect.paralysisChance, crit: crit)
			{
				paralysis = 0
				runM(message: "*Name was paralyzed!")
			}
			if !burningImmunity && statusEffectCheck(attackEffect.burningChance, crit: crit)
			{
				burning = 0
				runM(message: "*Name was set on fire!")
			}
			if !freezeImmunity && statusEffectCheck(attackEffect.freezeChance, crit: crit)
			{
				freeze = 0
				runM(message: "*Name was frozen!")
			}
			
			let oldAS = attackStep
			attackStep += attackEffect.attackStep ?? 0
			stepEffectMessage("attack", oldStep: oldAS, newStep: attackStep, messageHandler: messageHandler)
			
			let oldDS = defenseStep
			defenseStep += attackEffect.defenseStep ?? 0
			stepEffectMessage("defense", oldStep: oldDS, newStep: defenseStep, messageHandler: messageHandler)
			
			let oldCS = accuracyStep
			accuracyStep += attackEffect.accuracyStep ?? 0
			stepEffectMessage("accuracy", oldStep: oldCS, newStep: accuracyStep, messageHandler: messageHandler)
			
			let oldGS = dodgeStep
			dodgeStep += attackEffect.dodgeStep ?? 0
			stepEffectMessage("dodge", oldStep: oldGS, newStep: dodgeStep, messageHandler: messageHandler)
			
			if attackEffect.mug
			{
				//TODO: if this is targeting an enemy, create money based on level
				//otherwise, destroy money based on level
			}
			
			if attackEffect.nonlethal && health == 0
			{
				health = 1
			}
			
			if attackEffect.cleanse && (freeze != nil || burning != nil || bleed != nil || paralysis != nil || attackStep < 0 || defenseStep < 0 || accuracyStep < 0 || dodgeStep < 0)
			{
				//only display the message if there's something to be cleansed
				runM(message: "*Name was cleansed of *his ailments!")
				
				freeze = nil
				burning = nil
				bleed = nil
				paralysis = nil
				attackStep = max(attackStep, 0)
				defenseStep = max(defenseStep, 0)
				accuracyStep = max(accuracyStep, 0)
				dodgeStep = max(dodgeStep, 0)
			}
		}
	}
	
	private func statusEffectCheck(chance:Int?, crit:Bool) -> Bool
	{
		if let chance = chance
		{
			let roll = Int(arc4random_uniform(100))
			if roll <= chance + (crit ? chance / 2 : 0) //raise status effect chance on a crit
			{
				return true
			}
		}
		return false
	}
	
	//get stuff
	private func getStepLabel(step:Int, name:String) -> String
	{
		return (step == 0 ? "" : (step > 0 ? " +\(step) \(name)" : " \(step) \(name)"))
	}
	internal var statLine:String
	{
		var label = "NAME\nlevel \(level) \(type)\n\(health)/\(maxHealth) health"
		if attackStep != 0 || defenseStep != 0 || accuracyStep != 0 || dodgeStep != 0
		{
			label += "\n"
			label += getStepLabel(attackStep, name: "ATTACK")
			label += getStepLabel(defenseStep, name: "DEFENSE")
			label += getStepLabel(accuracyStep, name: "ACCURACY")
			label += getStepLabel(dodgeStep, name: "DODGE")
		}
		if freeze != nil || burning != nil || paralysis != nil || bleed != nil
		{
			label += "\n"
			label += (freeze != nil ? " frozen" : "")
			label += (paralysis != nil ? " paralyzed" : "")
			label += (bleed != nil ? " bleeding" : "")
			label += (burning != nil ? " burning" : "")
		}
		return label
	}
}