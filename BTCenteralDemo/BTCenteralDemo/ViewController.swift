//
//  ViewController.swift
//  BTCenteralDemo
//
//  Created by uwei on 06/05/2017.
//  Copyright © 2017 Tencent. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var peripheralTableView: UITableView!
    
    fileprivate var centralManager:CBCentralManager?
    fileprivate var centralCBPeripheral:CBPeripheral?
    fileprivate var peripherals = [CBPeripheral]()
    
    let notifyChracatorUUID = CBUUID(string: "2C270F0C-C9D3-4E56-ACCD-15621FA1568E")
    let rwChracatorUUID = CBUUID(string: "6082238A-C138-42B0-9562-44A1642BE5A5")
    let notifyUUID = CBUUID(string: "83951652-DF2E-4CF7-8E45-FCE84073F705")
    let rwUUID = CBUUID(string: "3ECDBC04-441D-4A7A-A62E-43081CD67ED7")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(ViewController.findPerihperal))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(ViewController.trashPeripheral))
        
        peripheralTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if self.peripherals.count > 0 {
            cell.textLabel?.text = peripherals[indexPath.row].name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if centralCBPeripheral != nil {
            centralManager?.cancelPeripheralConnection(centralCBPeripheral!)
        }
        
        centralCBPeripheral = peripherals[indexPath.row]
        
        if let _ = centralManager?.isScanning {
            centralManager?.stopScan()
            print("didStop")
        }
        
        centralManager?.connect(centralCBPeripheral!, options: [CBConnectPeripheralOptionNotifyOnConnectionKey:true])
    }
    
    
    func findPerihperal() {
        // 第一个参数为nil，将搜索所有
//        let sUUID = CBUUID(string: "83951652-DF2E-4CF7-8E45-FCE84073F705")
//        centralManager?.scanForPeripherals(withServices: [sUUID], options: nil)
        peripherals.removeAll()
        peripheralTableView.reloadData()
        
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }

    func trashPeripheral() -> Void {
        peripherals.removeAll()
        peripheralTableView.reloadData()
        for p in peripherals {
            centralManager?.cancelPeripheralConnection(p)
        }
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
        print("did discover peripheral ad data is \(advertisementData)")
        if peripherals.contains(peripheral) {
            //
        } else {
            peripherals.append(peripheral)
            peripheralTableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected!")
        centralCBPeripheral!.delegate = self
        centralCBPeripheral!.discoverServices([notifyUUID, rwUUID])
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if centralCBPeripheral!.services != nil {
            for service in centralCBPeripheral!.services! {
                print("service is \(service.uuid.uuidString)")
                if service.uuid == notifyUUID {
                    centralCBPeripheral!.discoverCharacteristics([notifyChracatorUUID], for: service)
                }
                if service.uuid == rwUUID {
                    centralCBPeripheral!.discoverCharacteristics([rwChracatorUUID], for: service)
                }
                
            }
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("discover characteristic \(characteristic)")
            if characteristic.uuid == notifyChracatorUUID {
                centralCBPeripheral!.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == rwChracatorUUID {
                let readData = ("uwei").data(using: .utf8)
                centralCBPeripheral?.writeValue(readData!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("error changing notification state \(error!)")
        } else {
            centralCBPeripheral!.readValue(for: characteristic)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        
        
        if data != nil {
            print("did update value is \(NSString.init(data: data!, encoding: String.Encoding.utf8.rawValue)!)")
        } else {
            print("did update value is nil")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("did write value")
        if error != nil {
            print("error is \(error!)")
        }
    }
}

