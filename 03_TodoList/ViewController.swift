//
//  ViewController.swift
//  03_TodoList
//
//  Created by Jacob Ko on 2021/12/01.
//

import UIKit

class ViewController: UIViewController {

	
	// 재사용이 가능하도록 weak 가 아니라 strong 으로 설정해 줘야함
	@IBOutlet var editBtn: UIBarButtonItem!
	var doneBtn: UIBarButtonItem?

	@IBOutlet weak var tableView: UITableView!
	
	// task 의 list 생성: property observer 생성
	var tasks = [Task]() {
		// tasks 의 value 가 추가 될때 마다 UserDefaults 에 할일이 저장되게 됨
		didSet {
			self.saveTasks()
		}
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// 생성자로 barButtonSystemItem 에는 .done 을 넘기고, target 에는 self, action 에는 selector 를 넘겨줘야 하는데 버튼을 선택하였을때, 호출되는 method 의 이름을 적어줘야 함
		// selector 는 구조체 형식으로 정의가 되고, #selector() 하여 해당값을 생성 할 수 있게 됨
		self.doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneBtnTap))
		// UIView source 의 프로토콜 채택 - 생성된 tasks 의 list 를 불러오기
		self.tableView.dataSource = self
		// 체크표시가 되게 하기
		self.tableView.delegate = self
		// UserDefaults 에 저장되어 있는 할일들을 불러오기
		self.loadTasks()
	}
	
	// doneBtn 이 호출되었을때의 method selector type으로 전달한 인자에는 func 앞에 @objc 를 붙여줘야 함 (object C 와의 호환성을 위한 것으로, objectC 에서도 인식할 수 있도록 만들어 줌)
	@objc func doneBtnTap() {
		// dontBtn 을 누를때 다시 editBtn 될 수 있게 설정함
		self.navigationItem.leftBarButtonItem = self.editBtn
		// 빠져 나오면 다시 edit 모드가 아니게 빠져 나올수 있게 함
		self.tableView.setEditing(false, animated: true)
	}
	
	
	// Edit 버튼을 누르면 textField 가 변경될수 있게 만듬
	@IBAction func tabEditButton(_ sender: UIBarButtonItem) {
		// tasks 가 비어 있지 않을 경우에만 실행 가능하도록 함
		guard !self.tasks.isEmpty else { return }
		self.navigationItem.leftBarButtonItem = self.doneBtn
		self.tableView.setEditing(true, animated: true)
	}
	
	@IBAction func tabAddButton(_ sender: UIBarButtonItem) {
		// add 버튼을 누르면 alert 이 생성되는 btn 생성
		let alert = UIAlertController(title: "Create Todo", message: nil, preferredStyle: .alert)
		
		// Add 버튼 생성 - 등록 버튼을 누를때 textField 의 버튼을 가져오기
		let registerBtn = UIAlertAction(title: "ADD", style: .default, handler: { [weak self] _ in
			guard let title = alert.textFields?[0].text else { return }
			let task = Task(title: title, done: false)
			self?.tasks.append(task)
			// task 가 추가 될때 마다 tableView 를 reload 하기
			self?.tableView.reloadData()
		})
		
		// cancel 되는 btn 생성
		let cancelBtn = UIAlertAction(title: "CANCEL", style: .cancel, handler: nil)
		// add, cancel btn 을 alert 에 추가하기
		alert.addAction(cancelBtn)
		alert.addAction(registerBtn)
		// textField 생성하기
		alert.addTextField(configurationHandler: { textField in
			textField.placeholder = "Write your task."
		})
		// 화면에 present 하기
		self.present(alert, animated: true, completion: nil)
	}
	
	
	// useDefault method 생성
	func saveTasks(){
		// 배열에 있는 tasks 를 dic 형태로 mapping 하기
		let data = self.tasks.map {
			[
				"title": $0.title,
				"done": $0.done
			]
		}
		let userDefaults = UserDefaults.standard
		// userDefaults 의 data 를 넣고, Key 값으로는 tasks 로 설정함
		userDefaults.set(data, forKey: "tasks")
	}
	
	// 저장된 data load 하는 method
	func loadTasks() {
		let userDefaults = UserDefaults.standard
		guard let data = userDefaults.object(forKey: "tasks") as? [[String: Any]] else { return }
		// 불러온 data 를 tasks 에 다시 저장
		self.tasks = data.compactMap {
			guard let title = $0["title"] as? String else { return nil }
			guard let done = $0["done"] as? Bool else { return nil }
			return Task(title: title, done: done)
		}
	}
}


extension ViewController: UITableViewDataSource {
	// 행의 갯수를 묻는 method : tasks 의 갯수
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.tasks.count
	}
	// 특정 row 를 그리기위해 특정 cell 을 반환하는 method: todo 목록이 표시되게 작성
	// dequeueReusableCell : 재사용 가능한 cell 을 반환하여, 이를 table view 에 추가 하는 역활 queue 를 사용해서 cell 을 재사용 (즉, 메모리 누수를 방지하기 위해서 만약 view 에서 5개의 list 가 보이게 되면 5개의 cell 만 메모리를 사용하고 스크롤을 내렸을때, 안보이는 전의 cell 을 다시 재사용해서 재할당하는것임)
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		// 0부터 tasks의 count 갯수 까지의 task list
		let task = self.tasks[indexPath.row]
		cell.textLabel?.text = task.title
		if task.done {
			// task 의 done 값이 true 이면 checkmark 가 나타나게 함
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		return cell
	}
	
	//  commit forRowAt 는 삭제버튼을 누를때 그 누른 cell 이 어떤 버튼인지 알려주는 기능
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		self.tasks.remove(at: indexPath.row)
		tableView.deleteRows(at: [indexPath], with: .automatic)
		
		// 모든 셀이 삭제되면 편집모드로 빠져나오게 함
		if self.tasks.isEmpty {
			self.doneBtnTap()
		}
	}
	
	// 재정렬 할 수 있게 움직이게 하는 canMoveAt
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	// 편집모드에서 할일의 순서를 변경하는 기능 : moveRowAt: 행이 다른 위치로 이동하면, sourceIndexPath 의 위치를 통해 원래 있었던 위치를 알려 주고, destinationIndexPath 를 통해 어디로 이동했는지 알려주는 logic
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		// 재정렬 된것을 다시 tasks 에 저장해줘야 함
		var tasks = self.tasks
		let task = tasks[sourceIndexPath.row]
		// 원래 위치에 있던 할일을 삭제하고
		tasks.remove(at: sourceIndexPath.row)
		// 이동한 위치에 값을 넣어주고
		tasks.insert(task, at: destinationIndexPath.row)
		// 재정렬된 tasks 를 원래 tasks 의 값에 넣어줌
		self.tasks = tasks
	}
}


// check 표시를 하기위한 delegate extension
extension ViewController: UITableViewDelegate {
	// cell 이 선택되었을때 어떠한 cell 이 선택 되었는지 알려주는 method
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		var task = self.tasks[indexPath.row]
		task.done = !task.done // done 의 값이 초기값은 false 인데 false 이면 true 로, true 이면 false 로 변환
		// 변경된 done 을 원래 tasks 에 덮어 씌우기
		self.tasks[indexPath.row] = task
		// 선택된 cell 만 reload 하기 at 은 선택된 index 위치를 indexPath , with 은 animation 속성인데 .automatic 하면 system의 속성을 그대로 사용한다는 의미임
		self.tableView.reloadRows(at: [indexPath], with: .automatic)
	}
}
