//
//  ViewController.swift
//  BonjourTest
//
//  Created by Scott Gardner on 7/31/17.
//  Copyright © 2017 Scott Gardner. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var serviceBrowser = NetServiceBrowser()
    var serviceResolver: NetService?
    lazy var services = [NetService]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        serviceBrowser.delegate = self
        searchForServices()
    }
    
    func searchForServices() {
        serviceBrowser.searchForServices(ofType: "_afpovertcp._tcp", inDomain: "local.")
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let service = services[indexPath.row]
        cell.textLabel?.text = service.name
        cell.detailTextLabel?.text = "Tap to resolve"
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard services.count > 0 else { return }
        
        if let serviceResolver = self.serviceResolver {
            serviceResolver.stop()
        }
        
        let serviceResolver = services[indexPath.row]
        serviceResolver.delegate = self
        serviceResolver.resolve(withTimeout: 0.0)
    }
}

extension ViewController: NetServiceDelegate {
    
    enum IPError: Error {
        case unableToGetIpAddress
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        serviceResolver?.stop()
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        
        guard let data = sender.addresses?.first,
            let indexPathForSelectedRow = tableView.indexPathForSelectedRow
            else { return }
        
        do {
            try data.withUnsafeBytes { (pointer: UnsafePointer<sockaddr>) in
                guard getnameinfo(pointer, socklen_t(data.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                    throw IPError.unableToGetIpAddress
                }
            }
            
            let ipAddress = String(cString: hostname)
            let cell = tableView.cellForRow(at: indexPathForSelectedRow)
            cell?.detailTextLabel?.text = "\(sender.hostName ?? "No hostname")\n\(ipAddress):\(sender.port)"
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
        } catch {
            print(error)
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("errorDict = \(errorDict)")
        serviceResolver?.stop()
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
    }
}

extension ViewController: NetServiceBrowserDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print(errorDict)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("Found service:", terminator: "")
        dump(service)
        services.append(service)
        
        if moreComing == false {
            tableView.reloadData()
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("Removed service:", terminator: "")
        dump(service)
        guard let index = services.index(of: service) else { return }
        services.remove(at: index)
        
        if moreComing == false {
            tableView.reloadData()
        }
    }
}
