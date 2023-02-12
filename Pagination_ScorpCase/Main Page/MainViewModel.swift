//
//  MainViewModel.swift
//  Pagination_ScorpCase
//
//  Created by Teyhan.Uslu on 12.02.2023.
//

import Foundation

class MainViewModel {
    weak var view: MainViewController?
    
    var peopleList: [Person] = []
    var next: String? = nil
    
    let should_standby_people = 10
    let should_repeated_request = 2
    
    var howManyRequested = 0
    var howManyError = 0
    var fetchCalled = false
    
    
    func viewDidLoad() {
        fetchPeople()
    }
    
    func tableViewNumberOfRowsInSection() -> Int {
        self.peopleList.count
    }
    
    func tableViewCellInfo(indexPath: IndexPath) -> String {
        guard self.peopleList.count > indexPath.row else { return ""}
        let person = peopleList[indexPath.row]
        return "\(person.fullName) (\(person.id))"
    }
    
    func peopleRetrived(oldCount: Int) {
        if oldCount == 0 {  //ilk dizi bomboş
           view?.refreshPage()
       } else if self.peopleList.count == oldCount { // newcount is 0 yeni eleman gelmemiş
            if howManyRequested < should_repeated_request {
                fetchPeople()
                howManyRequested = howManyRequested + 1
            } else {
                view?.popAlert(description: "No one here :(")
            }
        } else {  
            var indexPathArray: [IndexPath] = []
            for i in oldCount ..< self.peopleList.count {
                indexPathArray.append(IndexPath(item: i, section: 0))
            }
            view?.addNewPeople(indexPathArray: indexPathArray)
        }
        fetchCalled = false
    }
    
    func errorRetrived(errorDescription: String?) {
        if howManyError < should_repeated_request {
            fetchPeople()
            howManyError = howManyError + 1
        } else {
            view?.popAlert(description: errorDescription ?? "unknown error")
        }
    }
}

// MARK: Refresh
extension MainViewModel {
    func refreshTableView() {
        next = nil
        peopleList = []
        fetchPeople()
    }
    
    func tableViewElementCount(count: Int) {
        if !fetchCalled,
           count + should_standby_people > peopleList.count {
            fetchPeople()
            fetchCalled = true
        }
    }
}

// MARK: Data Source
extension MainViewModel {
    private func fetchPeople() {
        DataSource.fetch(next: self.next) { [weak self] response, error in
            guard let self = self else { return }
            if let response = response {
                self.next = response.next
                let oldCount = self.peopleList.count
                self.peopleList.append(contentsOf: response.people)
                
                print(self.next)
                print(response.people.count)
                print(oldCount)
                print(self.peopleList.count)
                
                // Checking unique person id while adding new people
                for person in response.people {
                    if !self.peopleList.contains(where: {$0.id == person.id }) {
                        self.peopleList.append(person)
                    }
                }
                self.peopleRetrived(oldCount: oldCount)
            } else {
                self.errorRetrived(errorDescription: error?.errorDescription)
//                self.view?.popAlert(description: error?.errorDescription ?? "")
            }
        }
    }
    
}
