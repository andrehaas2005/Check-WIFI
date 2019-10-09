
import UIKit
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import NetworkExtension
import Network

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var ssidText: UITextField!

    var locationManager = CLLocationManager()
    var currentNetworkInfos: Array<NetworkInfo>? {
        get {
            return SSID.fetchNetworkInfo()
        }
    }
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var bssidLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            let status = CLLocationManager.authorizationStatus()
            if status == .authorizedWhenInUse {
                updateWiFi()
            } else {
                locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
            }
        } else {
            updateWiFi()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func updateWiFi() {
        ssidLabel.text = currentNetworkInfos?.first?.ssid
        bssidLabel.text = currentNetworkInfos?.first?.bssid
        table.reloadData()
    }
    @IBAction func save(_ sender: Any) {

        let configuration = NEHotspotConfiguration.init(ssid: ssidText.text!, passphrase: passwordText.text!, isWEP: false)
        configuration.joinOnce = true
        


        NEHotspotConfigurationManager.shared.apply(configuration) { (error) in
            if error != nil {

                if error?.localizedDescription == "already associated."
                {
                    self.alertMessage("Connected")
                    print("Connected")
                }
                else{
                     self.alertMessage("\(String(describing: error!.localizedDescription))")
                    print("No Connected: \(String(describing: error!.localizedDescription))")
                }
            }
            else {
                 self.alertMessage("Connected")

            }
        }

    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            updateWiFi()
        }
    }

    func limpar() {
        self.ssidText.text = ""
        self.passwordText.text = ""
    }

    func alertMessage(_ text: String) {
        let controller = UIAlertController(title: "Alerta !!", message: text, preferredStyle: .alert)
        let btnOk = UIAlertAction(title: "Continuar", style: .default) { acao in
            self.updateWiFi()
            self.limpar()

        }
        controller.addAction(btnOk)
        present(controller, animated: true, completion: nil)
    }
}



public class SSID {
    class func fetchNetworkInfo() -> [NetworkInfo]? {
        if let interfaces: NSArray = CNCopySupportedInterfaces() {
            var networkInfos = [NetworkInfo]()
            for interface in interfaces {
                let interfaceName = interface as! String
                var networkInfo = NetworkInfo(interface: interfaceName,
                                              success: false,
                                              ssid: nil,
                                              bssid: nil)

                if let dict = CNCopyCurrentNetworkInfo(interfaceName as CFString) as NSDictionary? {
                    networkInfo.success = true
                    networkInfo.ssid = dict[kCNNetworkInfoKeySSID as String] as? String
                    networkInfo.bssid = dict[kCNNetworkInfoKeyBSSID as String] as? String
                }
                networkInfos.append(networkInfo)
            }
            return networkInfos
        }
        return nil
    }
}

struct NetworkInfo {
    var interface: String
    var success: Bool = false
    var ssid: String?
    var bssid: String?
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentNetworkInfos?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = currentNetworkInfos?[indexPath.row].ssid
        cell.detailTextLabel?.text = currentNetworkInfos?[indexPath.row].bssid
        return cell
    }


}
