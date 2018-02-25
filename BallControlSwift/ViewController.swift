
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var connectButton: UIBarButtonItem!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    
    private var location = CGPoint.init(x: 0, y: 0)
    private var locationDictionary: [String : CGFloat]?
    private var sharedObject: SharedObject?
    private var imageMoveEnabled: Bool?
    
    private let backendless = Backendless.sharedInstance()!
    private let HOST_URL = "http://apitest.backendless.com"
    private let APP_ID = "A81AB58A-FC85-EF00-FFE4-1A1C0FEADB00"
    private let API_KEY = "FE202648-517E-B0A5-FF89-CBA9D7DFDD00"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.isHidden = false
        imageView.isHidden = true
        imageMoveEnabled = false
        connectButton.isEnabled = false
        
        backendless.hostURL = "http://apitest.backendless.com"
        backendless.initApp(APP_ID, apiKey: API_KEY)
        
        sharedObject = self.backendless.sharedObject.connect("BallObject")
        addRTListeners()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.locationDictionary = ["x": self.location.x, "y": self.location.y]
            self.animate(self.locationDictionary as Any)
        }, completion: { context in
        })
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (imageMoveEnabled!) {
            let touch = touches.first!
            location = touch.location(in: self.view)
            
            let statusBarHeigth = UIApplication.shared.statusBarFrame.size.height
            let navBarHeight = navigationController?.navigationBar.frame.height
            
            if (location.x - imageView.frame.width / 2 <= view.frame.minX) {
                location.x = imageView.frame.width / 2
            }
            if (location.x + imageView.frame.width / 2 >= view.frame.maxX) {
                location.x = view.frame.maxX - imageView.frame.width / 2
            }
            if (location.y - imageView.frame.height / 2 <= statusBarHeigth + navBarHeight!) {
                location.y = statusBarHeigth + navBarHeight! + imageView.frame.height / 2
            }
            if (location.y + imageView.frame.height / 2 >= view.frame.maxY) {
                location.y = view.frame.maxY - imageView.frame.height / 2
            }
            
            imageView.center = location
            let locationDictionary = ["x": location.x, "y": location.y]
            sharedObject?.invoke(on: "animate", targets: [NSNull()], args: [locationDictionary], response:{ res in }, error: {fault in})
        }
    }
    
    func addRTListeners() {
        backendless.rt.addConnectEventListener({
            if (self.connectButton.title == "Connect") {
                self.navigationItem.title = "Status: disconnected"
            }
            else if (self.connectButton.title == "Disconnect") {
                self.navigationItem.title = "Status: connected"
            }
            self.connectButton.isEnabled = true
        })
        
        backendless.rt.addConnectErrorEventListener({ connectError in
            self.sharedObject = self.backendless.sharedObject.connect("BallObject")
            self.navigationItem.title = "Status: connection failed: \(connectError!)"
            self.connectButton.isEnabled = false
        })
        
        backendless.rt.addDisonnectEventListener({ disconnectReason in
            self.sharedObject = self.backendless.sharedObject.connect("BallObject")
            self.navigationItem.title = "Status: disconnected: \(disconnectReason!)"
            self.connectButton.isEnabled = false
        })
        
        backendless.rt.addReconnectAttemptEventListener({ reconnectAttempt in
            self.navigationItem.title = "Status: trying to connect"
        })
    }
    
    func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: {
            self.textView.isHidden = false
            self.imageView.isHidden = true
            self.imageMoveEnabled = false
        })
    }
    
    @IBAction func animate(_ sender: Any) {
        locationDictionary = sender as? [String : CGFloat]
        let locationX = locationDictionary!["x"]
        let locationY = locationDictionary!["y"]
        
        var originX = locationX! - imageView.frame.size.width / 2
        var originY = locationY! - imageView.frame.size.height / 2
        
        let statusBarHeigth = UIApplication.shared.statusBarFrame.height
        let navBarHeight = navigationController?.navigationBar.frame.height
        
        if (originX <= view.frame.minX) {
            originX = view.frame.minX
        }
        if (originX + imageView.frame.width >= view.frame.maxX) {
            originX = view.frame.maxX - imageView.frame.width
        }
        if (originY <= statusBarHeigth + navBarHeight!) {
            originY = statusBarHeigth + navBarHeight!
        }
        if (originY + imageView.frame.height >= view.frame.maxY) {
            originY = view.frame.maxY - imageView.frame.height
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.imageView.frame = CGRect(x: originX, y: originY, width: self.imageView.frame.size.width, height: self.imageView.frame.size.height)
        })
    }
    
    @IBAction func pressedConnect(_ sender: Any) {
        if (self.connectButton.title == "Connect") {
            self.connectButton.title = "Disconnect"
            if (!(self.sharedObject?.isConnected)!) {
                self.sharedObject?.connect()
            }
            self.sharedObject?.invocationTarget = self
            
            self.sharedObject?.addConnectListener({
                self.navigationItem.title = "Status: connected"
                self.textView.isHidden = true
                self.imageView.isHidden = false
                self.imageMoveEnabled = true
            }, error: { fault in
                self.self.showErrorAlert(fault!.detail)
            })
            
            self.sharedObject?.addInvokeListener({ invocationObject in
            }, error: { fault in
                self.showErrorAlert(fault!.detail)
            })
        }
            
        else if (self.connectButton.title == "Disconnect") {
            self.connectButton.title = "Connect"
            self.navigationItem.title = "Status: disconnected"
            self.sharedObject?.disconnect()
            self.textView.isHidden = false
            self.imageView.isHidden = true
            self.imageMoveEnabled = false
        }
    }
}





