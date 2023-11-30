//
//  TaskListsViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

final class TaskListViewController: UITableViewController {

	private var taskLists: Results<TaskList>!
   // var currentTasks2: Results<Task>!
    private let storageManager = StorageManager.shared
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
		createTempData()
		taskLists = storageManager.realm.objects(TaskList.self)
		
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        
        navigationItem.rightBarButtonItem = addButton
        navigationItem.leftBarButtonItem = editButtonItem
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		tableView.reloadData()
        
	}
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let taskList = taskLists[indexPath.row]
        content.text = taskList.title
        
        let curentTasks = taskList.tasks.filter("isComplete = false")
       
        if storageManager.getIsCompleted(taskList) {
            content.secondaryText = nil
            cell.accessoryType = .checkmark
        } else {
           //content.secondaryText = currentTasks2.count.formatted()
            content.secondaryText = curentTasks.count.formatted()
            cell.accessoryType = .none
        }
        
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _, _, _ in
            storageManager.delete(taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, isDone in
            showAlert(with: taskList) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { [unowned self] _, _, isDone in
            storageManager.done(taskList)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        guard let tasksVC = segue.destination as? TasksViewController else { return }
        let taskList = taskLists[indexPath.row]
        tasksVC.taskList = taskList
        //        tasksVC.complition = {[weak self] undoneTasks in
        //            self?.currentTasks2 = undoneTasks
        
    }
        
    
    

    @IBAction func sortingList(_ sender: UISegmentedControl) {

        taskLists = sender.selectedSegmentIndex == 0 ?
        taskLists.sorted(byKeyPath: "title",ascending: true) :
        taskLists.sorted(byKeyPath: "date", ascending: false)
                
        tableView.reloadData()
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
}

// MARK: - AlertController
extension TaskListViewController {
    private func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let alertBuilder = AlertControllerBuilder(
            title: taskList != nil ? "Edit List" : "New List",
            message: "Please set title for new task list"
        )
        
        alertBuilder
            .setTextField(taskList?.title)
            .addAction(title: taskList != nil ? "Update List" : "Save List", style: .default) { [weak self] newValue, _ in
                if let taskList, let completion {
                    self?.storageManager.edit(taskList, newValue: newValue)
                    completion()
                    return
                }
                
                self?.save(taskList: newValue)
            }
            .addAction(title: "Cancel", style: .destructive)
            tableView.reloadData()
        
        let alertController = alertBuilder.build()
        present(alertController, animated: true)
    }
    
    private func save(taskList: String) {
		storageManager.save(taskList) { taskList in
			let rowIndex = IndexPath(row: taskLists.firstIndex(of: taskList) ?? 0, section: 0)
			tableView.insertRows(at: [rowIndex], with: .automatic)
		}
    }
	
	private func createTempData() {
		if !UserDefaults.standard.bool(forKey: "doneSt") {
			DataManager.shared.createTempData { [unowned self] in
				UserDefaults.standard.set(true, forKey: "doneSt")
				tableView.reloadData()
			}
		}
	}
}

