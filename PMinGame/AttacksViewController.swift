//
//  AttacksViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/28/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class AttacksViewController: UIViewController, UITableViewDataSource {

	var person:Creature?
	var saveClosure:(()->())!
	
	@IBOutlet weak var portraitView: CreatureView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var attackTable: UITableView!
	{
		didSet
		{
			attackTable.dataSource = self
			attackTable.estimatedRowHeight = 100
			attackTable.rowHeight = UITableViewAutomaticDimension
		}
	}
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		nameLabel.text = person!.name
		portraitView.creature = person
	}
	
	@IBAction func returnButton()
	{
		navigationController!.popViewControllerAnimated(true)
	}
	
	//MARK: table view datasource
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return person!.attacks.count
	}
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("attackCell") as! AttackTableViewCell
		
		let attack = person!.attacks[indexPath.row]
		cell.nameLabel.text = attack.attack
		cell.descriptionLabel.text = attack.description
		
		if person!.attacks.count > 1
		{
			cell.forgetClosure =
			{
				self.person!.attacks.removeAtIndex(indexPath.row)
				self.attackTable.reloadData()
				
				//also save the effect!
				self.saveClosure()
			}
		}
		else
		{
			cell.forgetClosure = nil
		}
		
		return cell
	}
}
