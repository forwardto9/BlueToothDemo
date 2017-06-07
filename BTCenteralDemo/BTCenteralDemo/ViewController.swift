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
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        
        peripheralTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
//        centralManager = CBCentralManager(delegate: self, queue: nil)
        //使用这个方法是为了做到 State Preservation and Restoration
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey:true, CBCentralManagerOptionRestoreIdentifierKey:"E9368926-1C37-4461-BE6A-DABA8EEE68CC"])
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
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        
        if self.peripherals.count > 0 {
            cell.textLabel?.text = (peripherals[indexPath.row].name ?? "name is null")
            cell.detailTextLabel?.text = peripherals[indexPath.row].identifier.uuidString
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
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            print("didStop")
        }
        
        centralManager?.connect(centralCBPeripheral!, options: [CBConnectPeripheralOptionNotifyOnConnectionKey:true, CBConnectPeripheralOptionNotifyOnDisconnectionKey:true])
    }
    
    
    func findPerihperal() {
        // 第一个参数为nil，将搜索所有
//        let sUUID = CBUUID(string: "83951652-DF2E-4CF7-8E45-FCE84073F705")
//        centralManager?.scanForPeripherals(withServices: [sUUID], options: nil)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.navigationItem.leftBarButtonItem?.isEnabled  = true
        peripherals.removeAll()
        peripheralTableView.reloadData()
        
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }

    func trashPeripheral() -> Void {
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        peripherals.removeAll()
        peripheralTableView.reloadData()
        
        if let _ = centralManager?.isScanning {
            centralManager?.stopScan()
        }
        
        for p in peripherals {
            if p.state == .connected {
                centralManager?.cancelPeripheralConnection(p)
            }
        }
    }
    
    
    // MARK:- Monitoring Changes to the Central Manager’s State
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
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        //
        let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey]
        print(peripherals ?? "peripherals is nil")
    }
    
    // MARK:- Discovering and Retrieving Peripherals
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("did discover peripheral ad data is \(advertisementData)")
        if peripherals.contains(peripheral) {
            //
        } else {
            peripherals.append(peripheral)
            peripheralTableView.reloadData()
        }
    }
    
    
    // MARK:- Monitoring Connections with Peripherals
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected!")
        centralCBPeripheral!.delegate = self
        centralCBPeripheral?.readRSSI()
        centralCBPeripheral!.discoverServices([notifyUUID, rwUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        //
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        //
    }
    
    // MARK:- Retrieving a Peripheral’s Received Signal Strength Indicator (RSSI) Data
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("RSSI is \(RSSI.floatValue)")
    }
    
    // MARK:- Discovering Services
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
    
    //Invoked when you discover the included services of a specified service.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        //
    }
    
    // MARK:- Discovering Characteristics and Characteristic Descriptors
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("discover characteristic \(characteristic)")
//            if characteristic.uuid == notifyChracatorUUID {
//                centralCBPeripheral!.setNotifyValue(true, for: characteristic)
//            }
            if characteristic.uuid == rwChracatorUUID {
                let readData = ("uwei").data(using: .utf8)
                centralCBPeripheral?.writeValue(readData!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        //
    }
    
    //MARK:- Managing Notifications for a Characteristic’s Value
    //This method is invoked when your app calls the setNotifyValue(_:for:) method.
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("error changing notification state \(error!)")
        } else {
//            centralCBPeripheral!.readValue(for: characteristic)
        }
    }
    
    // MARK:- Retrieving Characteristic and Characteristic Descriptor Values
    //This method is invoked when your app calls the readValue(for:) method, or when the peripheral notifies your app that the value of the characteristic for which notifications and indications are enabled (via a successful call to setNotifyValue(_:for:)) has changed.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let data = characteristic.value
        
        if data != nil {
            print("did update value is \(NSString.init(data: data!, encoding: String.Encoding.utf8.rawValue)!)")
        } else {
            print("did update value is nil")
        }
    }
    
    // This method is invoked when your app calls the readValue(for:) method.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        //
    }
    
    //MARK:- Writing Characteristic and Characteristic Descriptor Values
    //Invoked when you write data to a characteristic’s value.
    //This method is invoked only when your app calls the writeValue(_:for:type:) method with the withResponse constant specified as the write type
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("did write value")
        if error != nil {
            print("error is \(error!)")
        } else {
            centralCBPeripheral!.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        //
    }
    
    // MARK:- Monitoring Changes to a Peripheral’s Name or Services
    // name
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        //
    }
    
    // service
    
    //A service is removed from the peripheral’s database
    //A new service is added to the peripheral’s database
    //A service that was previously removed from the peripheral’s database is readded to the database at a different location
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        //
        centralCBPeripheral?.discoverServices([invalidatedServices[0].uuid])
    }
}

