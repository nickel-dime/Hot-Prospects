//
//  Prospect.swift
//  Hot Prospects
//
//  Created by Nikhil Goel on 7/31/20.
//

import SwiftUI

class Prospect: Identifiable, Codable {
    let id = UUID()
    var name = "Anonymous"
    var emailAddress = ""
    let date = Date()
    fileprivate(set) var isContacted = false
}

class Prospects: ObservableObject {
    @Published private(set) var people: [Prospect]
    
    static let saveKey = "SavedData"
    
    init() {
        let url = getDocumentsDirectory().appendingPathComponent(Self.saveKey)
        do {
            let data = try Data(contentsOf: url)
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
                people = decoded
                return
            }
        } catch {
            print(error.localizedDescription)
        }
       
        people = []
    }
    
    private func save() {
        let url = getDocumentsDirectory().appendingPathComponent(Self.saveKey)
        if let encoded = try? JSONEncoder().encode(people) {
            do {
                try encoded.write(to: url)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
    
    func sortByName() {
        people.sort(by: {
            $0.name < $1.name
        })
        save()
    }
    func sortByDate() {
        people.sort(by: {
            $0.date.timeIntervalSinceNow > $1.date.timeIntervalSinceNow
        })
        save()
    }
}

func getDocumentsDirectory() -> URL {
    // find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    // just send back the first one, which ought to be the only one
    return paths[0]
}

