//
//  ProspectView.swift
//  Hot Prospects
//
//  Created by Nikhil Goel on 7/31/20.
//

import SwiftUI
import CodeScanner
import UserNotifications

enum FilterType {
    case none, contacted, uncontacted
}

struct ProspectView: View {
    @EnvironmentObject var prospects: Prospects
    
    @State private var isShowingScanner = false
    @State private var isShowingSortingOptions = false
    
    var data = ["Nikhil Goel\npaul@hackingwithswift.com", "Ansu Fati\npaul@hackingwithswift.com", "Paul Hudson\npaul@hackingwithswift.com", "Hermione Granger\npaul@hackingwithswift.com", "Tim Cook\npaul@hackingwithswift.com", "Craig Federighi\npaul@hackingwithswift.com", "Shane Bieber\npaul@hackingwithswift.com", "Kendrick Lamar\npaul@hackingwithswift.com", "Anthony Fantano\npaul@hackingwithswift.com", "Conan O'Brien\npaul@hackingwithswift.com", "Steve Jobs\npaul@hackingwithswift.com", "Shawn Spencer\npaul@hackingwithswift.com"]
    
    let filter: FilterType
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted People"
        case .uncontacted:
            return "Uncontacted People"
        }
    }
    
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredProspects) { (prospect: Prospect) in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if filter == FilterType.none {
                            Image(systemName: prospect.isContacted ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.xmark")
                                .resizable(capInsets: EdgeInsets(), resizingMode: .stretch)
                                .frame(width: 35, height: 30)
                                .foregroundColor(prospect.isContacted ? .green : .red)
                        }
                    }
                    .contextMenu(/*@START_MENU_TOKEN@*/ContextMenu(menuItems: {
                        Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted") {
                            prospects.toggle(prospect)
                        }
                        if !prospect.isContacted {
                            Button("Remind Me") {
                                addNotification(for: prospect)
                            }
                        }
                    })/*@END_MENU_TOKEN@*/)
                }
            }
                .navigationBarTitle(title)
            .navigationBarItems(leading: Button(action: {
                isShowingSortingOptions = true
            }, label: {
                Text("Sort")
            }), trailing: Button(action: {
                    isShowingScanner = true
                }, label: {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan")
                }))
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], simulatedData: data[Int.random(in: 0...11)], completion: self.handleScan)
            }
            .actionSheet(isPresented: $isShowingSortingOptions) {
                ActionSheet(title: Text("Choose Sorting Method"), buttons: [
                    .default(Text("Name")) {
                        prospects.sortByName()
                    },
                    .default(Text("Most Recent")) {
                        prospects.sortByDate()
                    }
                ])
            }
        }
    }
    
    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else {
                return
            }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            
            prospects.add(person)
            
        case .failure(let error):
            print("Scanning Alert \(error)")
        }
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
}

struct ProspectView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectView(filter: .none)
    }
}
