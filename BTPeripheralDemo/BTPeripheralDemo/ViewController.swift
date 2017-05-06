//
//  ViewController.swift
//  BTPeripheralDemo
//
//  Created by uwei on 06/05/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate {

    fileprivate var peripheralManager:CBPeripheralManager?
    fileprivate var service:CBMutableService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        let cUUID1 = CBUUID(string: "2C270F0C-C9D3-4E56-ACCD-15621FA1568E")
        let cUUID2 = CBUUID(string: "6082238A-C138-42B0-9562-44A1642BE5A5")
        
        let readData = ("uwei").data(using: .utf8)
        
        let c1 = CBMutableCharacteristic(type: cUUID1, properties: .read, value: readData, permissions: .readable)
        let c2 = CBMutableCharacteristic(type: cUUID2, properties: .notify, value: nil, permissions: .writeable)
        
        
        let sUUID = CBUUID(string: "83951652-DF2E-4CF7-8E45-FCE84073F705")
        service = CBMutableService(type: sUUID, primary: true)
        service!.characteristics = [c1, c2]
        
        peripheralManager?.add(service!)
        
    }
    @IBAction func startAd(_ sender: Any) {
        peripheralManager?.startAdvertising([CBAdvertisementDataLocalNameKey:"uwei perihper" , CBAdvertisementDataServiceUUIDsKey : [service!.uuid]])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("did update state")
        switch peripheral.state {
        case .poweredOn:
            print("peripheral on")
            break;
        case .poweredOff:
            print("peripheral off")
            break;
        case .unsupported:
            print("peripheral un")
            break;
        default:
            print("peripheral default")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("didAdd")
        if  error != nil {
            print("add service error\(error!)")
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("didStartAd")
        if error != nil {
            print("didStartad error \(error!)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("request")
        if  request.characteristic.uuid == service?.characteristics?.first?.uuid {
            print("request c1")
            if request.offset > service!.characteristics!.first!.value!.count {
                peripheral.respond(to: request, withResult: .invalidOffset)
            } else {
                let start = service?.characteristics?.first?.value?.index(0, offsetBy: request.offset)
                let end   = service?.characteristics?.first?.value?.index(start!, offsetBy: service!.characteristics!.first!.value!.count - request.offset)
                request.value = service?.characteristics?.first?.value?.subdata(in: start!..<end!)
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        let request = requests.first
        peripheral.respond(to: request!, withResult: .success)
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("didUnsub")
        let data = characteristic.value
        let didSend = peripheral.updateValue(data!, for: characteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil)
        print("send result \(didSend)")
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // resend for update
    }
    
}

