//
//  MainViewModel.swift
//  Pagination_ScorpCase
//
//  Created by Teyhan.Uslu on 12.02.2023.
//

import Foundation

class MainViewModel {
    weak var view: MainViewController?
    
    var peopleList: [Person] = [] {
        didSet {
            if peopleList.count < 2 * should_standby_people {
                fetchPeople()
            }
        }
    }
    var next: String? = nil
    
    let should_standby_people = 10 // number of rows kept in reserve
    let should_repeated_request = 2 // re-request count limit
    
    var receivedEmptyCounter = 0 // received empty response counter
    var repetitiveErrorCount = 0 // repetitive error counter
    var fetchCurrentCalled = false // fetch func has been called. It is used for to avoid repeated requests.
    var isThereMoreData = true
    
    func viewDidLoad() {
        fetchPeople()
    }
}

//MARK: TableView
extension MainViewModel {
    func tableViewNumberOfRowsInSection() -> Int {
        self.peopleList.count
    }
    
    func tableViewCellInfo(indexPath: IndexPath) -> String {
        guard self.peopleList.count > indexPath.row else { return ""}
        let person = peopleList[indexPath.row]
        return "\(person.fullName) (\(person.id))"
    }
}

// MARK: Refresh
extension MainViewModel {
    func refreshedTableView() {
        next = nil
        peopleList = []
        isThereMoreData = true
        fetchPeople()
    }
}

// MARK: Adding
extension MainViewModel {
    func scrollViewDidScroll() {
        if isThereMoreData {
            view?.startActivityIndicator()
        }
    }

    func handleDisplayingRowsNumber(count: Int) {
        if isThereMoreData, count + should_standby_people > peopleList.count || peopleList.count < 2 * should_standby_people {
            fetchPeople()
        }
    }
}

// MARK: Data Source
extension MainViewModel {
    private func fetchPeople() {
        guard !fetchCurrentCalled else { return }
        fetchCurrentCalled = true
        DataSource.fetch(next: self.next) { [weak self] response, error in
            guard let self = self else { return }
            if let response = response {
                self.next = response.next
                let oldCount = self.peopleList.count
                for person in response.people { // Checking unique person id while adding new people.
                    if !self.peopleList.contains(where: {$0.id == person.id }) {
                        self.peopleList.append(person)
                    }
                }
                self.peopleRetrieved(oldCount: oldCount)
            } else {
                self.errorRetrieved(errorDescription: error?.errorDescription)
            }
            self.fetchCurrentCalled = false
        }
    }
}

// MARK: Handle Data Source
extension MainViewModel {
    func peopleRetrieved(oldCount: Int) {
        self.repetitiveErrorCount = 0
        if self.peopleList.count == oldCount { // no new element, again request
            if receivedEmptyCounter < should_repeated_request {
                fetchPeople()
                receivedEmptyCounter = receivedEmptyCounter + 1
            } else {
                var message: String = "No more row :/"
                if self.peopleList.count == 0 {
                    message  = "No one here :("
                }
                view?.popAlert(description: message)
            }
        } else {    // there are new elements
            if oldCount == 0 { // If there weren't old elements, just view is refreshed.
                view?.updateTableView()
            } else {   // If there were old elements, new elements are added to old ones.
                var indexPathArray: [IndexPath] = []
                for i in oldCount ..< self.peopleList.count {
                    indexPathArray.append(IndexPath(item: i, section: 0))
                }
                view?.addNewPeople(indexPathArray: indexPathArray)
            }
            self.receivedEmptyCounter = 0
        }
        // When the next comes nil, people with new ids don't come either. Therefore, it is necessary not to make new requests.
        if self.next == nil {
            self.errorRetrieved(errorDescription: "No more data :(", isCertain: true)
            self.isThereMoreData = false
        }
    }
    
    func errorRetrieved(errorDescription: String?, isCertain: Bool = false) {
        if isCertain || repetitiveErrorCount >= should_repeated_request {
            view?.popAlert(description: errorDescription ?? "unknown error")
        } else {
            fetchPeople()
            repetitiveErrorCount = repetitiveErrorCount + 1
        }
    }
}
