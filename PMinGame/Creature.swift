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
let kMaxAttacks = 4

func expToNextLevel(level:Int) -> Int
{
	return 30 * (10 + level)
}

class Creature
{
	//MARK: identity
	private var job:String
	internal var name:String
	internal var good:Bool
	private var gender:Bool?
	
	//MARK: appearance stats
	internal var sprites = [String]()
	internal var colors = [String]()
	
	//MARK: level-up stats
	internal var level:Int
	var experience:Int
	
	//MARK: variable stats
	var health:Int = 0
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
	var maxHealth:Int
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
	
	//MARK: saving and loading via creature strings
	var creatureString:String
	{
		//save basic values
		var s = "\(job)%\(level)%\(good)%\(name)%\(experience)%\(health)%"
		if let gender = gender
		{
			s += gender ? "female%" : "male%"
		}
		else
		{
			s += "neither%"
		}
		
		//save attacks
		s += "\(attacks.count)%"
		for attack in attacks
		{
			s += "\(attack.attack)%\(attack.powerPoints)%"
		}
		
		//save appearance
		s += "\(sprites.count)%"
		for i in 0..<sprites.count
		{
			s += "\(sprites[i])%\(colors[i])%"
		}
		
		//save status
		s += "\(attackStep)%\(defenseStep)%\(accuracyStep)%\(dodgeStep)%"
		
		func saveStatusString(status:Int?)->String
		{
			if let status = status
			{
				return "\(status)%"
			}
			return "no%"
		}
		s += saveStatusString(freeze)
		s += saveStatusString(sleep)
		s += saveStatusString(paralysis)
		s += saveStatusString(bleed)
		s += saveStatusString(burning)
		
		return s
	}
	
	//MARK: initialize and level up functions
	convenience init(string:String)
	{
		let broken = string.characters.split{ $0 == "%" }.map(String.init)
		var i = 0
		
		self.init(job: broken[i++], level: Int(broken[i++])!, good: broken[i++] == "true")
		name = broken[i++]
		experience = Int(broken[i++])!
		health = Int(broken[i++])!
		switch broken[i++]
		{
		case "male": gender = false
		case "female": gender = true
		default: break
		}
		
		//load attacks
		let numAttacks = Int(broken[i++])!
		attacks = [Attack]()
		for _ in 0..<numAttacks
		{
			let attack = Attack(attack: broken[i++])
			attack.powerPoints = Int(broken[i++])!
			attacks.append(attack)
		}
		
		//load appearance
		let numSprites = Int(broken[i++])!
		sprites = [String]()
		colors = [String]()
		for _ in 0..<numSprites
		{
			sprites.append(broken[i++])
			colors.append(broken[i++])
		}
		
		//load status
		attackStep = Int(broken[i++])!
		defenseStep = Int(broken[i++])!
		accuracyStep = Int(broken[i++])!
		dodgeStep = Int(broken[i++])!
		freeze = Int(broken[i++])
		sleep = Int(broken[i++])
		paralysis = Int(broken[i++])
		bleed = Int(broken[i++])
		burning = Int(broken[i++])
	}
	
	init(job:String, level:Int, good:Bool)
	{
		self.job = job
		name = job.capitalizedString
		self.level = level
		self.good = good
		
		//set exp
		if good
		{
			experience = 0
		}
		else
		{
			experience = expToNextLevel(level) / 11
		}
		
		//pick a gender and an appearance
		if PlistService.loadValue("Races", race, "gendered") != nil
		{
			gender = arc4random_uniform(100) < 50
		}
		generateAppearance()
		
		if good
		{
			generateName()
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
			colors = generateAppearancePart(appearanceColors)
		}
		else
		{
			colors = [String]()
		}
		while colors.count < sprites.count
		{
			colors.append("FFFFFF")
		}
	}
	
	func generateName()
	{
		var nameGen = (PlistService.loadValue("Races", race, "name generator") as! String) as NSString
		if let gender = gender
		{
			nameGen = "\(nameGen) \(gender ? "female" : "male")"
		}
		
		do
		{
			let regex = try NSRegularExpression(pattern: "\\([a-zA-Z\\s]+\\)", options: NSRegularExpressionOptions())
			
			func getFromGen(gen:NSString)->NSString
			{
				let ar = PlistService.loadValueFlat("NameGenerator", gen as String) as! [String]
				let pick = Int(arc4random_uniform(UInt32(ar.count)))
				return ar[pick] as NSString
			}
			
			var nameString = getFromGen(nameGen)
			while (true)
			{
				let match = regex.firstMatchInString(nameString as String, options: NSMatchingOptions(), range: NSMakeRange(0, nameString.length))
				if let match = match
				{
					var matchWithoutParens = match.range
					matchWithoutParens.location += 1
					matchWithoutParens.length -= 2
					let matchString = nameString.substringWithRange(matchWithoutParens)
					let newPiece = getFromGen(matchString)
					nameString = regex.stringByReplacingMatchesInString(nameString as String, options: NSMatchingOptions(), range: match.range, withTemplate: newPiece as String)
				}
				else
				{
					//no more matches, so you're done
					break
				}
			}
			
			//if you got this far, you have a new name!
			name = nameString as String
		}
		catch _
		{
			//you had an exception
		}
	}
	
	var jobDescription:String
	{
		return formatMessagePersonal(PlistService.loadValue("Jobs", job, "description") as! String)
	}
	
	var jobSneaky:Bool
	{
		//this increases your chance of running successfully
		return PlistService.loadValue("Jobs", job, "sneaky") != nil
	}
	
	var jobHardy:Bool
	{
		//this makes you immune to environmental damage
		return PlistService.loadValue("Jobs", job, "hardy") != nil
	}
	
	var jobParrying:Bool
	{
		//this makes you take half damage from melee attacks
		return PlistService.loadValue("Jobs", job, "parrying") != nil
	}
	
	var jobShielding:Bool
	{
		//this makes you take half damage from ranged attacks
		return PlistService.loadValue("Jobs", job, "shielding") != nil
	}
	
	var jobMain:Bool
	{
		//this means you can't be put in reserve
		return PlistService.loadValue("Jobs", job, "main character") != nil
	}
	
	var jobBlendColor:UIColor
	{
		return PlistService.loadColor(PlistService.loadValue("Jobs", job, "blend color") as! String)
	}
	
	var weaponSprite:String?
	{
		return PlistService.loadValue("Jobs", job, "weapon appearance") as? String
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
				
				if attacks.count > kMaxAttacks
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
	
	internal func getAttackForLevel(level:Int) -> Attack?
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
	internal func typeAndRangeMultiplier(attackType:String?, attackRanged:Bool) -> Int
	{
		var tM:Int
		if let attackType = attackType
		{
			switch(PlistService.loadValue("Types", attackType, type) as! Int)
			{
			case -2: tM = 0
			case -1: tM = 50
			case 0: tM = 100
			case 1: tM = 140
			case 2: tM = 180
			default: assertionFailure("ERROR: Invalid type modifier!"); return 100
			}
			if (jobShielding && attackRanged) || (jobParrying && !attackRanged)
			{
				return tM / 2
			}
			return tM
		}
		return 100 //you do full damage always
	}
	private func formatMessagePersonal(message:String)->String
	{
		let he =  (gender == nil ? "it" : (gender! ? "she" : "he"))
		let him = (gender == nil ? "it" : (gender! ? "her" : "him"))
		let his = (gender == nil ? "its" : (gender! ? "her" : "his"))
		let himself = (gender == nil ? "itself" : (gender! ? "herself" : "himself"))
		return message.stringByReplacingOccurrencesOfString("*Name", withString: name).stringByReplacingOccurrencesOfString("*his", withString: his).stringByReplacingOccurrencesOfString("*him", withString: him).stringByReplacingOccurrencesOfString("*himself", withString: himself).stringByReplacingOccurrencesOfString("*he", withString: he)
		
	}
	private func runMessage(messageHandler:(String, Bool)->(), on:Creature)(message:String, shake:Bool)
	{ 
		let onName = on.name
		let finalMessage = formatMessagePersonal(message).stringByReplacingOccurrencesOfString("*OnName", withString: onName)
		messageHandler(finalMessage, shake)
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
	
	internal func statusEffectTurn(messageHandler:(String, Bool)->())->Bool
	{
		let runM = runMessage(messageHandler, on: self)
		
		//check status effects that do damage to you
		let bleedFunction = shouldShakeOffStatus(baseChance: 10, chanceRamp: 5)
		if bleed != nil
		{
			if health < 2 || bleedFunction(status: bleed!)
			{
				runM(message: "*Name stopped bleeding!", shake: false)
				bleed = nil
			}
			else
			{
				bleed! += 1
				let bleedDamage = takeBleedDamage()
				runM(message: "*Name bled out \(bleedDamage) health!", shake: false)
			}
		}
		if burning != nil
		{
			if health < 2 || bleedFunction(status: burning!)
			{
				runM(message: "*Name put *himself out!", shake: false)
				burning = nil
			}
			else
			{
				burning! += 1
				let burnDamage = takeBleedDamage()
				runM(message: "*Name burned away \(burnDamage) health!", shake: false)
			}
		}
		
		//check status effects that end your turn
		let paralFunction = shouldShakeOffStatus(baseChance: 50, chanceRamp: 25)
		if paralysis != nil
		{
			if paralFunction(status: paralysis!)
			{
				runM(message: "*Name shook off paralysis!", shake: false)
				paralysis = nil
			}
			else
			{
				paralysis! += 1
				if shouldSkipTurnFromParalysis()
				{
					runM(message: "*Name was still paralyzed!", shake: false)
					return false
				}
			}
		}
		if freeze != nil
		{
			if paralFunction(status: freeze!)
			{
				runM(message: "*Name stopped being frozen!", shake: false)
				freeze = nil
			}
			else
			{
				freeze! += 1
				if shouldSkipTurnFromParalysis()
				{
					runM(message: "*Name was still frozen!", shake: false)
					return false
				}
			}
		}
		if sleep != nil
		{
			if shouldShakeOffStatus(baseChance: 25, chanceRamp: 20)(status: sleep!)
			{
				runM(message: "*Name woke up!", shake: false)
				sleep = nil
			}
			else
			{
				sleep! += 1
				runM(message: "*Name was still asleep!", shake: false)
				return false
			}
		}
		
		return true
	}
	
	internal func useItem(item:Item, messageHandler:(String, Bool)->())
	{
		//play the message
		runMessage(messageHandler, on: self)(message: item.message, shake: false)
		
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
	
	internal func useAttackOn(attack:Attack, on:Creature, messageHandler:(String, Bool)->()) -> Bool
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
			runM(message: attack.message, shake: false)
			
			var applyEffects:Bool = true
			
			if let damage = attack.damage
			{
				//apply element
				let typeMultiplier = on.typeAndRangeMultiplier(attack.type, attackRanged: attack.ranged)
				var finalDamage = damage * typeMultiplier / 100
				if finalDamage == 0
				{
					runM(message: "The attack was ineffective!", shake: false)
					applyEffects = false
				}
				else
				{
					//apply crit
					if crit
					{
						finalDamage = finalDamage + finalDamage / 2
						
						runM(message: "WHAM!", shake: true)
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
					
					//the damage message shakes if it's a crit, or has a high multiplier
					runM(message: "*OnName took \(finalDamage) damage!", shake: typeMultiplier >= 150 || crit)
					
					if on.sleep != nil
					{
						runM(message: "*OnName woke up!", shake: false)
						on.sleep = nil
					}
					
					if attack.leech
					{
						health += finalDamage
						runM(message: "*Name is healed for \(finalDamage) health!", shake: false)
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
					runM(message: PlistService.loadValue("Races", on.race, "unconscious message") as! String, shake: false)
				}
				else
				{
					runM(message: PlistService.loadValue("Races", on.race, "death message") as! String, shake: false)
				}
				
				//restore status too, so if you are revived you don't come back with status effects
				resetStatus()
			}
		}
		else
		{
			//output a miss message
			runM(message: attack.missMessage, shake: false)
		}
		
		return hit
	}
	
	private func stepEffectMessage(descriptor:String, oldStep:Int, newStep:Int, messageHandler:(String, Bool)->())
	{
		let runM = runMessage(messageHandler, on: self)
		
		if oldStep > newStep
		{
			runM(message: "*Name's \(descriptor) lowered!", shake: false)
		}
		else if oldStep < newStep
		{
			runM(message: "*Name's \(descriptor) rose!", shake: false)
		}
	}
	
	private func applyEffectsTo(attackEffect:AttackEffect?, crit:Bool, messageHandler:(String, Bool)->())
	{
		let runM = runMessage(messageHandler, on: self)
		
		if let attackEffect = attackEffect
		{
			if attackEffect.nonlethal && health == 0
			{
				health = 1
			}
			
			if !dead
			{
				//don't bother inflicting status effects on dead people
				
				if bleedImmunity && attackEffect.bleedChance != nil
				{
					runM(message: "*Name was immune to bleeding!", shake: false)
				}
				else if statusEffectCheck(attackEffect.bleedChance, crit: crit)
				{
					bleed = 0
					runM(message: "*Name was given a bleeding wound!", shake: false)
				}
				
				if paralysisImmunity && attackEffect.paralysisChance != nil
				{
					runM(message: "*Name was immune to being paralyized!", shake: false)
				}
				else if statusEffectCheck(attackEffect.paralysisChance, crit: crit)
				{
					paralysis = 0
					runM(message: "*Name was paralyzed!", shake: false)
				}
				
				if burningImmunity && attackEffect.burningChance != nil
				{
					runM(message: "*Name was immune to being set on fire!", shake: false)
				}
				else if statusEffectCheck(attackEffect.burningChance, crit: crit)
				{
					burning = 0
					runM(message: "*Name was set on fire!", shake: false)
				}
				
				if freezeImmunity && attackEffect.freezeChance != nil
				{
					runM(message: "*Name was immune to being frozen!", shake: false)
				}
				else if statusEffectCheck(attackEffect.freezeChance, crit: crit)
				{
					freeze = 0
					runM(message: "*Name was frozen!", shake: false)
				}
				
				if sleepImmunity && attackEffect.sleepChance != nil
				{
					runM(message: "*Name was immune to being put to sleep!", shake: false)
				}
				else if statusEffectCheck(attackEffect.sleepChance, crit: crit)
				{
					sleep = 0
					runM(message: "*Name fell asleep!", shake: false)
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
					runM(message: "*Name was cleansed of *his ailments!", shake: false)
					
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
		var label = "level \(level) \(genderLabel)\(job) (\(type))"
		label += "\n\(health) health   \(accuracy) accuracy   \(dodge) dodge"
		label += "\n\(bruteAttack) attack   \(bruteDefense) defense   \(cleverAttack) sp. attack   \(cleverDefense) sp. defense"
		label += "\n\(jobDescription)"
		label += "\n\nAttacks:\n"
		for (num, attack) in attacks.enumerate()
		{
			if num == 2
			{
				label += "\n"
			}
			label += "  \(attack.attack) (\(attack.type ?? "typeless"))"
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
		var chance = 70 - (health * 100 / maxHealth)
		if health <= maxHealth / 4
		{
			//bonus capture chance for bringing their health under 25%
			chance += 20
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
		
		//fall unconscious and make sure all of your attacks have at least one use
		health = 0
		for attack in attacks
		{
			attack.powerPoints = max(attack.powerPoints, 1)
		}
	}
}