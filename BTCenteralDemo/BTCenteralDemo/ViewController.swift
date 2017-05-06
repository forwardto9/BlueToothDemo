//
//  ViewController.swift
//  BTCenteralDemo
//
//  Created by uwei on 06/05/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    fileprivate var centralManager:CBCentralManager?
    fileprivate var centralCBPeripheral:CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func findPerihperal(_ sender: Any) {
        // 第一个参数为nil，将搜索所有
        let sUUID = CBUUID(string: "83951652-DF2E-4CF7-8E45-FCE84073F705")
        centralManager?.scanForPeripherals(withServices: [sUUID], options: nil)
//        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centeral did update")
        switch central.state {
        case .poweredOn:
            print("power on")
            
            break
        case .poweredOff:
            print("power off")
            
            break
        case .unsupported:
            print("unsupport")
            break
        default:
            print("default")
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("did discover peripheral")
        if central.isScanning {
            central.stopScan()
            print("didStop")
            centralCBPeripheral = peripheral
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected!")
        centralCBPeripheral!.delegate = self
//        centralCBPeripheral!.discoverServices(nil)
        centralCBPeripheral?.discoverServices([CBUUID(string: "83951652-DF2E-4CF7-8E45-FCE84073F705")])
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if centralCBPeripheral!.services != nil {
            for service in centralCBPeripheral!.services! {
                
                if service.uuid == CBUUID(string: "83951652-DF2E-4CF7-8E45-FCE84073F705") {
                    print("service \(service)")
                    centralCBPeripheral!.discoverCharacteristics(nil, for: service)
                }
                
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for ch in service.characteristics! {
            print("discover characteristic \(ch)")
            centralCBPeripheral!.readValue(for: ch)
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        
        let w = ("test" as NSString).utf8String
        let d = Data.init(bytes: w!, count: "test".characters.count)
        centralCBPeripheral!.writeValue(d, for: characteristic, type: .withResponse)
        
        if data != nil {
            print("did update value is \(data!)")
        } else {
            print("did update value is nil")
        }
        
        centralCBPeripheral!.setNotifyValue(true, for: characteristic)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("error changing notification state \(error!)")
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("did write value")
        if error != nil {
            print("error is \(error!)")
        }
    }
}

