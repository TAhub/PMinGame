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
		}
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int
	{
		return 2
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return (section == 0 ? mvc.party.count : mvc.reserve.count)
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = table.dequeueReusableCellWithIdentifier("personCell")!
		let person = personAtIndexPath(indexPath)
		
		cell.textLabel!.text = person.name
		
		return cell
	}

	private var selectedPerson:Creature?
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		selectedPerson = personAtIndexPath(indexPath)
		performSegueWithIdentifier("showDetail", sender: self)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		if segue.identifier == "showDetail"
		{
			if let pdvc = segue.destinationViewController as? PersonDetailViewController
			{
				pdvc.person = selectedPerson
			}
		}
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return (section == 0 ? "Party" : "Recently Captured")
	}
	
	private func personAtIndexPath(indexPath: NSIndexPath) -> Creature
	{
		return (indexPath.section == 0 ? mvc.party[indexPath.row] : mvc.reserve[indexPath.row])
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
}
