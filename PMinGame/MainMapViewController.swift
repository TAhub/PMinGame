//
//  MainMapViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/9/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

let kMaxPartySize:Int = 6

//save stuff
let kSaveStateNone:String = "NONE"
let kSaveStateMap:String = "MAP"
let kSaveStateKey:String = "saveState"

let kSaveStateBattle:String = "BATTLE"
let kSaveStateCamp:String = "CAMP"

var saveState:String
{
	get
	{
		return NSUserDefaults.standardUserDefaults().stringForKey(kSaveStateKey) ?? kSaveStateNone
	}
	set(newSave)
	{
		print("Setting save state to \(newSave)!")
		NSUserDefaults.standardUserDefaults().setObject(newSave, forKey: kSaveStateKey)
	}
}

func savePartyMember(member:Creature, party:Bool, number:Int)
{
	let creatureSaveString = member.creatureString
	NSUserDefaults.standardUserDefaults().setObject(creatureSaveString, forKey: "\(party ? "party" : "reserve")\(number)")
}


class MainMapViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MapDelegate {
	internal var map:Map!
	private var tileImages = [String:UIImage]()
	
	//walkers
	private var partyWalker:UIView!
	private var encounterWalkers = [UIView]()
	
	@IBOutlet weak var mapView: UICollectionView!
	{
		didSet
		{
			mapView.dataSource = self
			mapView.delegate = self
		}
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		//diagnostics
		
		//turn this diagnostic on if you want to see if a job's stats are in-line with the standard
//		PlistService.jobStatDiagnostic()
		
		//turn this diagnostic on if you want to see if a job's attacks have the right balance of brute and clever, types, etc
//		PlistService.jobAttackDiagnostic()
		
		//turn this diagnostic on if you want to see if one type has too many attacks, etc
//		PlistService.attackDiagnostic()
		
		//turn this diagnostic on if you want to see if any attack is overused, underused, or not used at all
//		PlistService.attackUsageDiagnostic()
		
		//turn this diagnostic on if you want to see if any attack is too strong, too weak, etc
//		PlistService.attackPowerDiagnostic()
		
		
		//check save state
		if saveState == kSaveStateNone
		{
			//load the first map
			map = Map(from: nil)
			loadMap()
			
			//sample starting party
			map.party.append(Creature(job: "rogue", level: 5, good: true))
			map.party.append(Creature(job: "mystic", level: 1, good: true))
			map.party.append(Creature(job: "sour knight", level: 1, good: true))
			map.party.append(Creature(job: "pyromaniac", level: 1, good: true))
			map.party.append(Creature(job: "cold killer", level: 1, good: true))
			map.party.append(Creature(job: "cryoman", level: 1, good: true))
			
			//starting inventory
			map.items.append(Item(type: "poultice"))
			map.items[0].number = 6
			map.items.append(Item(type: "smelling salts"))
			map.items[1].number = 2
			map.items.append(Item(type: "miracle cure"))
			
			map.save()
			saveState = kSaveStateMap
		}
		else if saveState != kSaveStateNone
		{
			//load the saved map
			map = Map(from: nil)
			loadMap()
		}
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if saveState == kSaveStateCamp
		{
			//go to the camp instantly
			performSegueWithIdentifier("toCamp", sender: self)
		}
		else if saveState == kSaveStateBattle
		{
			//go to the battle instantly
			performSegueWithIdentifier("startBattle", sender: self)
		}
		else if saveState == kSaveStateNone
		{
			//set the save state
			//this happens because of a transition
			saveState = kSaveStateMap
		}
		
		
		//show the debug minimap
//		loadDebugMinimap()
	}
	
	private func loadMap()
	{
		//set yourself as delegate
		map.delegate = self
		
		//setup the walkers
		partyWalker = setUpWalker(map.partyPosition)
		for position in map.enemyEncounters
		{
			encounterWalkers.append(setUpWalker(position))
		}
		
		print("party position: \(map.partyPosition.0) \(map.partyPosition.1)     map dimensions: \(map.tiles[map.tiles.count - 1].count) \(map.tiles.count)")
		
		//load tile images
		var tiles = Set<String>()
		for col in map.tiles
		{
			for tile in col
			{
				tiles.insert(tile.type)
			}
		}
		tileImages = [String:UIImage]()
		for type in tiles
		{
			let tile = Tile(type: type)
			if let imageString = tile.image, let image = UIImage(named: imageString)
			{
				let coloredImage = image.colorImage(tile.color)
				tileImages[type] = coloredImage
			}
		}
		
		//reload the appearance
		mapView.reloadData()
		
		//move the camera
		self.mapView.layoutIfNeeded()
		self.moveCameraToPlayer(false)
	}
	
	private func loadDebugMinimap()
	{
		MapCurator.drawMap(map.tiles, canvas: view)
		let button = UIButton(frame: CGRect(x: 0, y: 0, width: 3 * CGFloat(map.tiles[0].count), height: 3 * CGFloat(map.tiles.count)))
		view.addSubview(button)
		button.addTarget(self, action: "reloadDebugMinimap", forControlEvents: .TouchUpInside)
	}
	
	func reloadDebugMinimap()
	{
		let newView = UIView(frame: view.bounds)
		view = newView
		map = Map(from: nil)
		loadDebugMinimap()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if let cvc = segue.destinationViewController as? CampViewController
		{
			//set transition
			navigationController?.delegate = nil
			
			if saveState != kSaveStateCamp
			{
				//award EXP for finishing the map
				let mapEXP = expToNextLevel(map.difficulty) * 7 / 10
				print("Awarding \(mapEXP) experience for finishing the map!")
				for person in map.party
				{
					person.experience += mapEXP
				}
				
				
				//unload the walkers
				partyWalker.removeFromSuperview()
				for walker in encounterWalkers
				{
					walker.removeFromSuperview()
				}
				encounterWalkers = [UIView]()
				
				//prepare the segue
				cvc.comparisonMap = map
				
				//generate the next map in another thread
				dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0))
				{
					let nextMap = Map(from: self.map)
					dispatch_async(dispatch_get_main_queue())
					{
						nextMap.money = self.map.money
						nextMap.items = self.map.items
						nextMap.party = self.map.party
						cvc.nextMap = nextMap
						saveState = kSaveStateCamp
						
						//save the next map
						nextMap.save()
					}
				}
				
				cvc.completionCallback =
				{ (nextMap) in
					//generate the next map
					self.map = nextMap
					self.loadMap()
				}
			}
			else
			{
				//set up the camp you are loading
				cvc.nextMap = map
				cvc.completionCallback =
				{ (nextMap) in
				}
			}
		}
		else if let bvc = segue.destinationViewController as? BattleViewController
		{
			//set transition
			navigationController?.delegate = BattleTransition()
			
			if saveState != kSaveStateBattle
			{
				saveState = kSaveStateNone
			}
			
			bvc.setup(map.party, money: map.money, encounterType: map.encounterType, difficulty: map.difficulty, endOfBattleHook: battleCallback)
			{
				self.map.saveParty()
			}
		}
	}
	
	private func battleCallback(lost:Bool, newAdditions:[Creature]?, money:Int)
	{
		if lost
		{
			//because this DOESN'T set the save state, the next time you load it will automatically make a new game
			//TODO: end the game
			print("You lost!")
		}
		else
		{
			map.money = money
			map.items = loadInventory()
			
			if let newAdditions = newAdditions
			{
				for new in newAdditions
				{
					if self.map.party.count < kMaxPartySize
					{
						self.map.party.append(new)
					}
					else
					{
						self.map.reserve.append(new)
					}
				}
			}
			
			saveState = kSaveStateMap
		}
		
		//save the party
		map.saveParty()
	}
	
	//MARK: walker code
	private var animating = false
	private func setUpWalker(position:(Int, Int))->UIView
	{
		let walker = UIView(frame: CGRect(x: kTileSize.width * CGFloat(position.0), y: kTileSize.height * CGFloat(position.1), width: kTileSize.width, height: kTileSize.height))
		walker.backgroundColor = UIColor.redColor()
		mapView.addSubview(walker)
		return walker
	}
	
	private func moveWalker(walker:UIView, to:(Int, Int), completion:()->())
	{
		animating = true
		UIView.animateWithDuration(0.25, animations:
		{
			walker.frame.origin.x = CGFloat(to.0) * kTileSize.width
			walker.frame.origin.y = CGFloat(to.1) * kTileSize.height
		})
		{ (success) in
			self.animating = false
			completion()
		}
	}
	
	//MARK: collection view datasource and delegate
	func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
	{
		return map.tiles.count
	}
	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return map.tiles[section].count
	}
	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("mapCell", forIndexPath: indexPath) as! TileCollectionViewCell
		let tile = map.tiles[indexPath.section][indexPath.row]
		if tile.visible
		{
			cell.backgroundColor = tile.color
			cell.tileImage.image = tileImages[tile.type]
			cell.hidden = false
		}
		else
		{
			cell.hidden = true
		}
		return cell
	}
	func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
	{
		//try to move there
		if !animating
		{
			map.moveTo((indexPath.row, indexPath.section))
		}
		return false
	}
	
	private func moveCameraToPlayer(animated:Bool)
	{
		let scrollPosition = UICollectionViewScrollPosition.CenteredHorizontally.rawValue | UICollectionViewScrollPosition.CenteredVertically.rawValue
		mapView.scrollToItemAtIndexPath(NSIndexPath(forItem: map.partyPosition.0, inSection: map.partyPosition.1), atScrollPosition: UICollectionViewScrollPosition.init(rawValue: scrollPosition), animated: animated)
	}
	
	//MARK: map delegate functions
	func playerMoved(completion:()->())
	{
		//move the player
		moveWalker(partyWalker, to: map.partyPosition, completion: completion)
		
		//and move the "camera"
		moveCameraToPlayer(true)
	}
	func startBattle()
	{
		performSegueWithIdentifier("startBattle", sender: self)
	}
	func partyDamageEffect()
	{
		//play a graphical effect to warn the player that they took damage
		
		//make the view
		let effectView = UIView(frame: view.frame)
		effectView.backgroundColor = UIColor.redColor()
		effectView.alpha = 0
		view.addSubview(effectView)
		
		//and animate it
		UIView.animateWithDuration(0.1, animations: { effectView.alpha = 1 })
		{ (success) in
			UIView.animateWithDuration(0.1, animations: { effectView.alpha = 0 })
			{ (success) in
				effectView.removeFromSuperview()
			}
		}
	}
	func nextMap()
	{
		//go to the next map
		performSegueWithIdentifier("toCamp", sender: self)
	}
}


