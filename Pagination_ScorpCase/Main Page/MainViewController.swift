//
//  MainViewController.swift
//  Pagination_ScorpCase
//
//  Created by Teyhan.Uslu on 12.02.2023.
//

import UIKit

class MainViewController: UIViewController {
    let viewModel = MainViewModel()
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyInfoLabel: UILabel!
    
    private var activityIndicator: LoadMoreActivityIndicator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.view = self
        viewModel.viewDidLoad()
        activityIndicator = LoadMoreActivityIndicator(scrollView: tableView, spacingFromLastCell: 10, spacingFromLastCellWhenLoadMoreActionStart: 60)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshed), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @objc private func refreshed(sender: UIRefreshControl) {
        sender.beginRefreshing()
        viewModel.refreshedTableView()
        sender.endRefreshing()
    }
    
    func refreshPage() {
        let count = viewModel.tableViewNumberOfRowsInSection()
        countLabel.text = "count: \(viewModel.tableViewNumberOfRowsInSection())"
        emptyInfoLabel.isHidden = ( count != 0 )
        tableView.reloadData()
        activityIndicator?.stop()
    }
    
    func addNewPeople(indexPathArray: [IndexPath]) {
        tableView.insertRows(at: indexPathArray, with: .automatic)
        countLabel.text = "count: \(viewModel.tableViewNumberOfRowsInSection())"
        activityIndicator?.stop()
    }
    
    func popAlert(description: String) {
        activityIndicator?.stop()
        activityIndicator = nil
        let alert = UIAlertController(title: "Data Source Error", message: description, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.tableViewNumberOfRowsInSection()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = viewModel.tableViewCellInfo(indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.handleDisplayingRowsNumber(count: indexPath.row)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        activityIndicator?.start(closure: nil)
        activityIndicator?.start {
            DispatchQueue.global(qos: .utility).async {
                sleep(3)
                DispatchQueue.main.async { [weak self] in
                    self?.activityIndicator?.stop()
                    self?.activityIndicator = nil
                }
            }
        }
    }
}
