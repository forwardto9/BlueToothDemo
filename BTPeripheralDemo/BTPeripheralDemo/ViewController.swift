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
    fileprivate var notifyService:CBMutableService?
    fileprivate var rwService:CBMutableService?
    fileprivate var notifyCharacteristic:CBMutableCharacteristic?
    fileprivate var rwableCharacteristic:CBMutableCharacteristic?
    
    fileprivate var sendDataTimer:Timer?
    
    let cUUID1 = CBUUID(string: "2C270F0C-C9D3-4E56-ACCD-15621FA1568E")
    let cUUID2 = CBUUID(string: "6082238A-C138-42B0-9562-44A1642BE5A5")
    let notifyUUID = CBUUID(string: "83951652-DF2E-4CF7-8E45-FCE84073F705")
    let rwUUID = CBUUID(string: "3ECDBC04-441D-4A7A-A62E-43081CD67ED7")
    
    fileprivate var serviceCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }
    @IBAction func startAd(_ sender: Any) {
        if serviceCount == 2 {
            peripheralManager?.startAdvertising([CBAdvertisementDataLocalNameKey:"uwei_service" , CBAdvertisementDataServiceUUIDsKey : [notifyUUID, rwUUID]])
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setPeripheralService() -> Void {
        
        notifyCharacteristic = CBMutableCharacteristic(type: cUUID1, properties: .notify, value: nil, permissions: .readable)
        rwableCharacteristic = CBMutableCharacteristic(type: cUUID2, properties: [.read, .write], value: nil, permissions: [.writeable, .readable])
        
        notifyService = CBMutableService(type: notifyUUID, primary: true)
        notifyService!.characteristics = [notifyCharacteristic!]
        
        rwService = CBMutableService(type: rwUUID, primary: true)
        rwService!.characteristics = [rwableCharacteristic!]
        
        peripheralManager?.add(notifyService!)
        peripheralManager?.add(rwService!)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("did update state")
        switch peripheral.state {
        case .poweredOn:
            print("peripheral on")
            
            setPeripheralService()
            
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
        } else {
            serviceCount += 1
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("didStartAd")
        if error != nil {
            print("didStartad error \(error!)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("read request")
        if request.characteristic == notifyCharacteristic {
            let data = request.characteristic.value
            request.value = data
            peripheralManager?.respond(to: request, withResult: .success)
        }
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        let request = requests.first
        if request?.characteristic == rwableCharacteristic {
            let c = request?.characteristic as! CBMutableCharacteristic
            c.value = request?.value
            peripheral.respond(to: request!, withResult: .success)
        }
    }
    
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        sendDataTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.sendCurrentTime), userInfo: characteristic, repeats: true)
        sendDataTimer?.fire()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        sendDataTimer?.invalidate()
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // resend for update
    }
    
    
    func sendCurrentTime() -> Void {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd hh:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        
        let didSend = peripheralManager!.updateValue((dateString as NSString).data(using: String.Encoding.utf8.rawValue)!, for: notifyCharacteristic!, onSubscribedCentrals: nil)
        print("send result \(didSend)")
    }
}

