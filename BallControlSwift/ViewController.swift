
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var connectButton: UIBarButtonItem!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    
    private let SHARED_OBJECT_NAME = "BallObject"
    private let LOCATION_COEFITIENTS = "LocationCoeficients"
    
    private let backendless = Backendless.sharedInstance()!
    private let HOST_URL = "http://apitest.backendless.com"
    private let APP_ID = "A81AB58A-FC85-EF00-FFE4-1A1C0FEADB00"
    private let API_KEY = "FE202648-517E-B0A5-FF89-CBA9D7DFDD00"
    
    private var statusBarHeight: CGFloat = 0
    private var navigationBarHeight: CGFloat = 0
    private var imageViewWidth: CGFloat = 0
    private var imageViewHeight: CGFloat = 0
    private var workspaceMinX: CGFloat = 0
    private var workspaceMaxX: CGFloat = 0
    private var workspaceMinY: CGFloat = 0
    private var workspaceMaxY: CGFloat = 0
    private var coefficientX: CGFloat = 0
    private var coefficientY: CGFloat = 0
    private var imageViewOriginX: CGFloat = 0
    private var imageViewOriginY: CGFloat = 0
    private var imageMoveEnabled: Bool = false
    private var isDragging: Bool = false
    private var sharedObject: SharedObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.isHidden = false
        imageView.isHidden = true
        connectButton.isEnabled = false
        
        if (view.frame.size.width <= view.frame.size.height) {
            imageView.frame = CGRect(x: imageView.frame.origin.x, y: imageView.frame.origin.y, width: view.frame.size.width * 0.25, height: view.frame.size.width * 0.25)
        }
        else {
            imageView.frame = CGRect(x: imageView.frame.origin.x, y: imageView.frame.origin.y, width: view.frame.size.height * 0.25, height: view.frame.size.height * 0.25)
        }
        
        imageViewWidth = imageView.frame.size.width
        imageViewHeight = imageView.frame.size.height
        imageView.layer.cornerRadius = imageViewWidth / 2
        
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        navigationBarHeight = (navigationController?.navigationBar.frame.size.height)!
        workspaceMinX = 0
        workspaceMaxX = view.frame.size.width
        workspaceMinY = statusBarHeight + navigationBarHeight
        workspaceMaxY = view.frame.size.height
        
        calculateCoefficients()
        
        imageMoveEnabled = false
        isDragging = false
        
        backendless.hostURL = HOST_URL
        backendless.initApp(APP_ID, apiKey: API_KEY)
        
        sharedObject = backendless.sharedObject .connect(SHARED_OBJECT_NAME)
        sharedObject?.get(LOCATION_COEFITIENTS, response: { result in
            if let coefs = result as? [String : Any] {
                let coefX = coefs["coefX"] as! CGFloat
                let coefY = coefs["coefY"] as! CGFloat
                self.animateImageViewMoving(coefX, coefY)
            }
        }, error: { fault in
            self.showErrorAlert(fault!.message)
        })
        addRTListeners()
    }
    
    func calculateCoefficients() {
        if (imageViewOriginX == workspaceMinX) {
            coefficientX = 0
        }
        else if (imageViewOriginX + imageViewWidth == workspaceMaxX) {
            coefficientX = 1
        }
        else {
            coefficientX = imageViewOriginX / workspaceMaxX
        }
        
        if (imageViewOriginY == workspaceMinY) {
            coefficientY = 0
        }
        else if (imageViewOriginY + imageViewHeight == workspaceMaxY) {
            coefficientY = 1
        }
        else {
            coefficientY = imageViewOriginY / workspaceMaxY
        }
    }
    
    func animateImageViewMoving(_ coefX: CGFloat, _ coefY: CGFloat) {
        if (coefX == 0) {
            imageViewOriginX = workspaceMinX
        }
        else if (coefX == 1) {
            imageViewOriginX = workspaceMaxX - imageViewWidth
        }
        else {
            imageViewOriginX = coefX * (workspaceMaxX - imageViewWidth)
        }
        if (coefY == 0) {
            imageViewOriginY = workspaceMinY
        }
        else if (coefY == 1) {
            imageViewOriginY = workspaceMaxY - imageViewHeight
        }
        else {
            imageViewOriginY = coefY * (workspaceMaxY - imageViewWidth)
        }
        if (!isDragging) {
            UIView.animate(withDuration: 0.3, animations: {
                self.imageView.frame = CGRect(x: self.imageViewOriginX, y: self.imageViewOriginY, width: self.imageViewWidth, height: self.imageViewHeight)
            })
        }
    }
    
    func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancek", style: .cancel, handler: nil))
        present(alert, animated: true, completion: {
            self.textView.isHidden = false
            self.imageView.isHidden = true
            self.imageMoveEnabled = false
        })
    }
    
    func addRTListeners() {
        backendless.rt.addConnectEventListener({
            DispatchQueue.main.async {
                self.connectButton.isEnabled = true
                if (self.connectButton.title == "Connect") {
                    self.navigationItem.title = "Status: disconnected"
                }
                else if (self.connectButton.title == "Disconnect") {
                    self.navigationItem.title = "Status: connected"
                }
                if (self.sharedObject?.isConnected)! {
                    self.sharedObject?.connect()
                }
            }
        })
        backendless.rt.addConnectErrorEventListener({ connectError in
            DispatchQueue.main.async {
                self.connectButton.isEnabled = false
                self.sharedObject = self.backendless.sharedObject.connect(self.SHARED_OBJECT_NAME)
                self.navigationItem.title = String(format: "Status: %@", connectError!)
            }
        })
        backendless.rt.addDisonnectEventListener({ disconnectReason in
            DispatchQueue.main.async {
                self.connectButton.isEnabled = false
                self.sharedObject = self.backendless.sharedObject.connect(self.SHARED_OBJECT_NAME)
                self.navigationItem.title = String(format: "Status: %@", disconnectReason!)
            }
        })
    }
    
    func addOnChangesListener() {
        sharedObject?.addChangesListener({ changes in
            if let coefs = changes?.data as? [String : Any] {
                let coefX = coefs["coefX"] as! CGFloat
                let coefY = coefs["coefY"] as! CGFloat
                self.animateImageViewMoving(coefX, coefY)
            }
        }, error: { fault in
            self.showErrorAlert(fault!.message)
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (imageMoveEnabled) {
            let touch = touches.first
            var location = touch?.location(in: view)
            imageView.center = location!
            
            imageViewOriginX = imageView.frame.origin.x
            imageViewOriginY = imageView.frame.origin.y
            
            if (imageViewOriginX <= workspaceMinX) {
                imageViewOriginX = workspaceMinX
                location?.x = workspaceMinX + imageViewWidth / 2
            }
            if (imageViewOriginX + imageViewWidth >= workspaceMaxX) {
                imageViewOriginX = workspaceMaxX - imageViewWidth
                location?.x = workspaceMaxX - imageViewWidth / 2
            }
            if (imageViewOriginY <= workspaceMinY) {
                imageViewOriginY = workspaceMinY
                location?.y = workspaceMinY + imageViewHeight / 2
            }
            if (imageViewOriginY + imageViewHeight >= workspaceMaxY) {
                imageViewOriginY = workspaceMaxY - imageViewHeight
                location?.y = workspaceMaxY - imageViewHeight / 2
            }
            imageView.center = location!
            calculateCoefficients()
            
            sharedObject?.set(LOCATION_COEFITIENTS, data: ["coefX" : coefficientX, "coefY" : coefficientY], response: { setResponse in
            }, error: { fault in
                self.showErrorAlert(fault!.message)
            })
        }
    }
    
    @IBAction func pressedConnect(_ sender: Any) {
        if (connectButton.title == "Connect") {
            connectButton.title = "Disconnect"
            if (!(sharedObject?.isConnected)!) {
                sharedObject?.connect()
                addOnChangesListener()
            }
            sharedObject?.addConnectListener({
                self.navigationItem.title = "Status: connected"
                self.textView.isHidden = true
                self.imageView.isHidden = false
                self.imageMoveEnabled = true
            
            }, error: { fault in
                self.showErrorAlert(fault!.message)
            })
        }
        else if (connectButton.title == "Disconnect") {
            connectButton.title = "Connect"
            navigationItem.title = "Status: disconnected"
            textView.isHidden = false
            imageView.isHidden = true
            imageMoveEnabled = false
            sharedObject?.disconnect()
        }
    }
}





