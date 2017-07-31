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
        cell.detailTextLabel?.text = "Tap to resolve IP address"
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
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        serviceResolver?.stop()
        let ipAddress = getIpV4(from: sender.addresses, port: sender.port)
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        let cell = tableView.cellForRow(at: indexPathForSelectedRow)
        cell?.detailTextLabel?.text = ipAddress
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("errorDict = \(errorDict)")
        serviceResolver?.stop()
    }
    
    func getIpV4(from addresses: [Data]?, port: Int) -> String {
        guard let data = addresses?.first as NSData? else { return "N/A" }
        
        var ip1 = UInt8(0)
        var ip2 = UInt8(0)
        var ip3 = UInt8(0)
        var ip4 = UInt8(0)
        
        data.getBytes(&ip1, range: NSMakeRange(4, 1))
        data.getBytes(&ip2, range: NSMakeRange(5, 1))
        data.getBytes(&ip3, range: NSMakeRange(6, 1))
        data.getBytes(&ip4, range: NSMakeRange(7, 1))
        
        return "\(ip1).\(ip2).\(ip3).\(ip4):\(port)"
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
