//
//  Creature.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/3/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import Foundation
import UIKit

//constants
private let kStatBonus = 5
private let kHealthLevelBonus = 5
private let kBleedDamage = 5

class Creature
{
	//MARK: identity
	private var job:String
	internal var name:String
	internal var good:Bool
	private var gender:Bool?
	
	//MARK* appearance stats
	internal var sprites = [String]()
	internal var colors = [UIColor]()
	
	//MARK: permanent stats
	private var level:Int
	
	//MARK: variable stats
	private var health:Int = 0
	{
		didSet
		{
			health = min(max(health, 0), maxHealth)
		}
	}
	internal var attacks = [Attack]()
	internal var dead:Bool { return health == 0 }
	internal var injured:Bool { return health < maxHealth / 2 }
	
	//MARK: status
	private var paralysis:Int?
	private var freeze:Int?
	private var bleed:Int?
	private var sleep:Int?
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
	
	//MARK: derived stats
	private var accuracy:Int
	{
		return PlistService.loadValue("Jobs", job, "accuracy") as! Int + level - 1
	}
	private var dodge:Int
	{
		return PlistService.loadValue("Jobs", job, "dodge") as! Int + level - 1
	}
	private var bruteAttack:Int
	{
		return PlistService.loadValue("Jobs", job, "brute attack") as! Int + level - 1
	}
	private var bruteDefense:Int
	{
		return PlistService.loadValue("Jobs", job, "brute defense") as! Int + level - 1
	}
	private var cleverAttack:Int
	{
		return PlistService.loadValue("Jobs", job, "clever attack") as! Int + level - 1
	}
	private var cleverDefense:Int
	{
		return PlistService.loadValue("Jobs", job, "clever defense") as! Int + level - 1
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
	private var race:String
	{
		return PlistService.loadValue("Jobs", job, "race") as! String
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
	private var sleepImmunity:Bool
	{
		return PlistService.loadValue("Jobs", job, "sleep immunity") != nil
	}
	
	//MARK: initialize and level up functions
	init(job:String, level:Int, good:Bool)
	{
		self.job = job
		name = job.capitalizedString
		self.level = level
		self.good = good
		
		//pick a gender and an appearance
		if PlistService.loadValue("Races", race, "gendered") != nil
		{
			gender = arc4random_uniform(100) < 50
		}
		generateAppearance()
		
		if good
		{
			//TODO: generate a name
		}
		
		getLevelAppropriateAttacks()
		
		//fill up resources
		health = maxHealth
		for attack in attacks
		{
			if good
			{
				attack.powerPoints = attack.maxPowerPoints
			}
			else
			{
				attack.powerPoints = Int(ceil(Float(attack.maxPowerPoints) * 0.25))
			}
		}
	}
	
	private func generateAppearance()
	{
		func generateAppearancePart(list:[AnyObject]) -> [String]
		{
			return list.map()
			{ (element) in
				if let array = element as? [String]
				{
					let pick = Int(arc4random_uniform(UInt32(array.count)))
					return array[pick]
				}
				else if let string = element as? String
				{
					return string
				}
				else
				{
					return "INVALID"
				}
			}
		}
		
		sprites = [String]()
		if let gender = gender
		{
			if gender
			{
				if let appearance = PlistService.loadValue("Races", race, "appearance female") as? [AnyObject]
				{
					sprites = generateAppearancePart(appearance)
				}
			}
			else
			{
				if let appearance = PlistService.loadValue("Races", race, "appearance male") as? [AnyObject]
				{
					sprites = generateAppearancePart(appearance)
				}
			}
		}
		else if let appearance = PlistService.loadValue("Races", race, "appearance") as? [AnyObject]
		{
			sprites = generateAppearancePart(appearance)
		}
		
		if let appearanceColors = PlistService.loadValue("Races", race, "appearance color") as? [AnyObject]
		{
			colors = generateAppearancePart(appearanceColors).map() { PlistService.loadColor($0) }
		}
		else
		{
			colors = [UIColor]()
		}
		while colors.count < sprites.count
		{
			colors.append(UIColor.whiteColor())
		}
	}
	
	var jobSprite:String
	{
		var baseName:String
		if let specialBaseName = PlistService.loadValue("Jobs", job, "job appearance") as? String
		{
			baseName = specialBaseName
		}
		else
		{
			baseName = job.stringByReplacingOccurrencesOfString(" ", withString: "_")
		}
		
		if let gender = gender
		{
			if gender
			{
				return "\(baseName)_f"
			}
			else
			{
				return "\(baseName)_m"
			}
		}
		else
		{
			return baseName
		}
	}
	
	func resetStatus()
	{
		sleep = nil
		bleed = nil
		paralysis = nil
		burning = nil
		freeze = nil
		attackStep = 0
		defenseStep = 0
		accuracyStep = 0
		dodgeStep = 0
	}
	
	private func unlearnObsoleteAttack() -> Bool
	{
		//try to unlearn a single obsolete attack
		for attack in attacks
		{
			if let upgradeFor = attack.upgradeFor
			{
				if let forPosition = attacks.map({$0.attack}).indexOf(upgradeFor)
				{
					attacks.removeAtIndex(forPosition)
					return true
				}
			}
		}
		return false
	}
	
	private func unlearnNoDamageAttack() -> Bool
	{
		//try to unlearn a random attack that does no damage
		let startPosition = Int(arc4random_uniform(UInt32(attacks.count)))
		for i in 0..<attacks.count
		{
			let aI = (i + startPosition) % attacks.count
			if attacks[aI].damage == nil
			{
				attacks.removeAtIndex(aI)
				return true
			}
		}
		return false
	}
	
	private func getLevelAppropriateAttacks()
	{
		for i in 1...level
		{
			if let attack = getAttackForLevel(i)
			{
				//learn that attack!
				attacks.append(attack)
				
				if attacks.count > 4
				{
					//uh-oh, too many attacks
					//time to unlearn one

					//first, try to unlearn something that's obsolete
					if !unlearnObsoleteAttack()
					{
						//if that didn't work, unlearn an attack that does no damage
						if !unlearnNoDamageAttack()
						{
							//otherwise, unlearn a random attack
							attacks.removeAtIndex(Int(arc4random_uniform(UInt32(attacks.count))))
						}
					}
				}
			}
		}
	}
	
	private func getAttackForLevel(level:Int) -> Attack?
	{
		let attacks = PlistService.loadValue("Jobs", job, "attacks") as! [String : String]
		for (attackLevel, attackName) in attacks
		{
			if attackLevel == "\(level)"
			{
				return Attack(attack: attackName)
			}
		}
		return nil
	}
	
	//MARK: attack functions
	internal var desperationAttack:Attack
	{
		let desp:Attack
		switch(type)
		{
		case "physical": desp = Attack(attack: "struggle")
		case "frost": desp = Attack(attack: "ice tackle")
		case "flame": desp = Attack(attack: "heat")
		case "spark": desp = Attack(attack: "jolt")
		case "astral": desp = Attack(attack: "spook")
		default:
			assertionFailure("ERROR: invalid type for desperation attack")
			desp = Attack(attack: "struggle")
		}
		desp.powerPoints = desp.maxPowerPoints
		return desp
	}
	
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
	internal func typeMultiplier(attackType:String?) -> Int
	{
		if let attackType = attackType
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
		return 100 //you do full damage always
	}
	private func runMessage(messageHandler:(String)->(), on:Creature)(message:String)
	{ 
		let onName = on.name
		let he =  (gender == nil ? "it" : (gender! ? "she" : "he"))
		let his = (gender == nil ? "its" : (gender! ? "her" : "his"))
		let himself = (gender == nil ? "itself" : (gender! ? "herself" : "himself"))
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
	
	internal func statusEffectTurn(messageHandler:(String)->())->Bool
	{
		let runM = runMessage(messageHandler, on: self)
		
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
					runM(message: "*Name was still paralyzed!")
					return false
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
					runM(message: "*Name was still frozen!")
					return false
				}
			}
		}
		if sleep != nil
		{
			if shouldShakeOffStatus(baseChance: 25, chanceRamp: 20)(status: sleep!)
			{
				runM(message: "*Name woke up!")
				sleep = nil
			}
			else
			{
				sleep! += 1
				runM(message: "*Name was still asleep!")
				return false
			}
		}
		
		return true
	}
	
	internal func useItem(item:Item, messageHandler:(String)->())
	{
		//play the message
		runMessage(messageHandler, on: self)(message: item.message)
		
		//remove the item count
		item.number -= 1
		
		//also, like, use the item, haha
		if let heals = item.heals
		{
			health += heals
		}
		
		if item.cureStatus
		{
			bleed = nil
			freeze = nil
			paralysis = nil
			burning = nil
			sleep = nil
		}
		
		if item.cureSteps
		{
			attackStep = max(attackStep, 0)
			defenseStep = max(defenseStep, 0)
			accuracyStep = max(accuracyStep, 0)
			dodgeStep = max(dodgeStep, 0)
		}
	}
	
	internal func useAttackOn(attack:Attack, on:Creature, messageHandler:(String)->())
	{
		let runM = runMessage(messageHandler, on: on)
		
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
				let typeMultiplier = on.typeMultiplier(attack.type)
				var finalDamage = damage * typeMultiplier / 100
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
						
						//TODO: this message should shake
						//to get some shaking, maybe use
						//https://github.com/haaakon/SingleLineShakeAnimation
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
					
					//TODO: if typeMultiplier > 150 or if it's a crit, this message should shake
					runM(message: "*OnName took \(finalDamage) damage!")
					
					if on.sleep != nil
					{
						runM(message: "*OnName woke up!")
						on.sleep = nil
					}
					
					if attack.leech
					{
						health += finalDamage
						runM(message: "*Name is healed for \(finalDamage) health!")
					}
				}
			}
			//there's no crit message for non-damaging attacks
			//because it's not immediately obvious what non-damaging crits DO
			
			if applyEffects
			{
				//apply effects
				applyEffectsTo(attack.userEffects, crit: crit, messageHandler: messageHandler)
				on.applyEffectsTo(attack.enemyEffects, crit: crit, messageHandler: messageHandler)
			}
			
			//detect death, to give special messages for that
			if on.health == 0
			{
				if on.good
				{
					runM(message: PlistService.loadValue("Races", on.race, "unconscious message") as! String)
				}
				else
				{
					runM(message: PlistService.loadValue("Races", on.race, "death message") as! String)
				}
				
				//restore status too, so if you are revived you don't come back with status effects
				resetStatus()
			}
		}
		else
		{
			//output a miss message
			runM(message: attack.missMessage)
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
			if attackEffect.nonlethal && health == 0
			{
				health = 1
			}
			
			if attackEffect.mug
			{
				if good
				{
					//this is targeting the player, so the player should lose money
					//TODO: destroy money based on level
				}
				else
				{
					//this is targeting an enemy, so the player should get money
					//TODO: create money based on level
				}
			}
			
			if !dead
			{
				//don't bother inflicting status effects on dead people
				
				if bleedImmunity && attackEffect.bleedChance != nil
				{
					runM(message: "*Name was immune to bleeding!")
				}
				else if statusEffectCheck(attackEffect.bleedChance, crit: crit)
				{
					bleed = 0
					runM(message: "*Name was given a bleeding wound!")
				}
				
				if paralysisImmunity && attackEffect.paralysisChance != nil
				{
					runM(message: "*Name was immune to being paralyized!")
				}
				else if statusEffectCheck(attackEffect.paralysisChance, crit: crit)
				{
					paralysis = 0
					runM(message: "*Name was paralyzed!")
				}
				
				if burningImmunity && attackEffect.burningChance != nil
				{
					runM(message: "*Name was immune to being set on fire!")
				}
				else if statusEffectCheck(attackEffect.burningChance, crit: crit)
				{
					burning = 0
					runM(message: "*Name was set on fire!")
				}
				
				if freezeImmunity && attackEffect.freezeChance != nil
				{
					runM(message: "*Name was immune to being frozen!")
				}
				else if statusEffectCheck(attackEffect.freezeChance, crit: crit)
				{
					freeze = 0
					runM(message: "*Name was frozen!")
				}
				
				if sleepImmunity && attackEffect.sleepChance != nil
				{
					runM(message: "*Name was immune to being put to sleep!")
				}
				else if statusEffectCheck(attackEffect.sleepChance, crit: crit)
				{
					sleep = 0
					runM(message: "*Name fell asleep!")
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
				
				if attackEffect.cleanse && (freeze != nil || burning != nil || bleed != nil || paralysis != nil || attackStep < 0 || defenseStep < 0 || accuracyStep < 0 || dodgeStep < 0)
				{
					//only display the message if there's something to be cleansed
					runM(message: "*Name was cleansed of *his ailments!")
					
					freeze = nil
					burning = nil
					bleed = nil
					paralysis = nil
					sleep = nil
					attackStep = max(attackStep, 0)
					defenseStep = max(defenseStep, 0)
					accuracyStep = max(accuracyStep, 0)
					dodgeStep = max(dodgeStep, 0)
				}
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
	
	//MARK: label
	private func getStepLabel(step:Int, name:String) -> String
	{
		return (step == 0 ? "" : (step > 0 ? " +\(step) \(name)" : " \(step) \(name)"))
	}
	internal var statLine:String
	{
		var label = "\(name): level \(level) \(type)\n\(health)/\(maxHealth) health"
		if dead
		{
			label += "\n\((good ? "UNCONSCIOUS" : "DEAD"))"
			return label
		}
		if attackStep != 0 || defenseStep != 0 || accuracyStep != 0 || dodgeStep != 0
		{
			label += "\n"
			label += getStepLabel(attackStep, name: "ATTACK")
			label += getStepLabel(defenseStep, name: "DEFENSE")
			label += getStepLabel(accuracyStep, name: "ACCURACY")
			label += getStepLabel(dodgeStep, name: "DODGE")
		}
		if freeze != nil || burning != nil || paralysis != nil || bleed != nil || sleep != nil
		{
			label += "\n"
			label += (freeze != nil ? " frozen" : "")
			label += (paralysis != nil ? " paralyzed" : "")
			label += (bleed != nil ? " bleeding" : "")
			label += (burning != nil ? " burning" : "")
			label += (sleep != nil ? " asleep" : "")
		}
		return label
	}
	internal var longLabel:String
	{
		let genderLabel = (gender == nil ? "" : (gender! ? "female " : "male "))
		var label = "level \(level) \(genderLabel)\(job)"
		label += "\n\(type)"
		label += "\n\(health) health   \(accuracy) accuracy   \(dodge) dodge"
		label += "\n\(bruteAttack) attack   \(bruteDefense) defense   \(cleverAttack) sp. attack   \(cleverDefense) sp. defense"
		//TODO: add a job description
		label += "\n\nAttacks:"
		for attack in attacks
		{
			label += "\n  \(attack.attack) (\(attack.type ?? "typeless"))"
		}
		return label
	}
	
	//MARK: capturing
	internal var captureChance:Int
	{
		if !injured
		{
			return 0
		}
		var chance = 60 - (health * 100 / maxHealth)
		if health <= maxHealth / 4
		{
			//bonus capture chance for bringing their health under 25%
			chance += 25
		}
		
		if health <= 10
		{
			//bonus capture chance for bringing their health very low
			//because this is an absolute value rather than a percentage, it's easy at the beginning
			//but complicated later on
			//consider getting subdue!
			chance += 10
		}
		
		return chance
	}
	internal func capture()
	{
		//you've become a good guy!
		good = true
		//TODO: generate a real name, not just your creature name
		
		//fall unconscious and make sure all of your attacks have at least one use
		health = 0
		for attack in attacks
		{
			attack.powerPoints = max(attack.powerPoints, 1)
		}
	}
}