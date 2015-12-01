//
//  PartyViewController.swift
//  PMinGame
//
//  Created by Theodore Abshire on 11/10/15.
//  Copyright © 2015 Theodore Abshire. All rights reserved.
//

import UIKit

class PartyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var table: UITableView!
	{
		didSet
		{
			table.delegate = self
			table.dataSource = self
			
			table.editing = true
		}
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 2
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return (section == 0 ? mvc.map.party.count : mvc.map.reserve.count)
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = table.dequeueReusableCellWithIdentifier("personCell") as! PartyMemberTableViewCell
		let person = personAtIndexPath(indexPath)
		
		cell.nameLabel.text = "\(person.name)  \(person.health)/\(person.maxHealth)"
		cell.personSelectCallback =
		{
			self.selectedPerson = person
		}
		
		return cell
	}

	private var selectedPerson:Creature?
//	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
//	{
//		selectedPerson = personAtIndexPath(indexPath)
//		performSegueWithIdentifier("showDetail", sender: self)
//	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		let saveClosure:(()->()) =
		{
			if let partyPos = self.mvc.map.party.indexOf(self.selectedPerson!)
			{
				savePartyMember(self.selectedPerson!, party: true, number: partyPos)
			}
			else if let reservePos = self.mvc.map.reserve.indexOf(self.selectedPerson!)
			{
				savePartyMember(self.selectedPerson!, party: false, number: reservePos)
			}
		}
		
		//set transition
		navigationController?.delegate = nil
		
		if let pdvc = segue.destinationViewController as? PersonDetailViewController
		{
			pdvc.person = selectedPerson
		}
		else if let avc = segue.destinationViewController as? AttacksViewController
		{
			avc.person = selectedPerson
			avc.saveClosure = saveClosure
		}
		else if let ivc = segue.destinationViewController as? ItemsViewController
		{
			ivc.person = selectedPerson
			ivc.items = mvc.map.items
			ivc.saveClosure = saveClosure
		}
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return (section == 0 ? "Party" : "Recently Captured")
	}
	
	private func personAtIndexPath(indexPath: NSIndexPath) -> Creature
	{
		return (indexPath.section == 0 ? mvc.map.party[indexPath.row] : mvc.map.reserve[indexPath.row])
	}
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		table.reloadData()
	}
	
	//MARK: get map view controller
	private var mvc:MainMapViewController
	{
		return (tabBarController!.viewControllers!)[0] as! MainMapViewController
	}
	
	//MARK: delegate stuff for move
	func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)
	{
		if destinationIndexPath.section == 0 && sourceIndexPath.section != 0 && mvc.map.party.count >= kMaxPartySize
		{
			//can't do anything
			table.reloadData()
			return
		}
		
		let from = personAtIndexPath(sourceIndexPath)
		
		if destinationIndexPath.section != 0 && sourceIndexPath.section == 0 && from.jobMain
		{
			//can't move the main character to the reserve
			table.reloadData()
			return
		}
		
		if sourceIndexPath.section == 0
		{
			mvc.map.party.removeAtIndex(sourceIndexPath.row)
		}
		else
		{
			mvc.map.reserve.removeAtIndex(sourceIndexPath.row)
		}
		
		if destinationIndexPath.section == 0
		{
			mvc.map.party.insert(from, atIndex: destinationIndexPath.row)
		}
		else
		{
			mvc.map.reserve.insert(from, atIndex: destinationIndexPath.row)
		}
		
		mvc.map.saveParty()
		
		table.reloadData()
	}
	func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
	{
		return UITableViewCellEditingStyle.None
	}
	func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool
	{
		return false
	}
	func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
	{
		return true
	}
}
