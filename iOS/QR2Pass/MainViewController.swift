//
//  ViewController.swift
//  QR2Pass
//
//  Created by Yorwos Pallikaropoulos on 1/2/21.
//  Copyright © 2021 Yorwos Pallikaropoulos. All rights reserved.
//

import LocalAuthentication
import UIKit

class MainViewController: UIViewController, CAAnimationDelegate, UINavigationControllerDelegate {

    

    
//    MARK: - application constants
    enum defaults {
        static let circleColor: UIColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
        static let tickColor: UIColor = #colorLiteral(red: 0.139090389, green: 0.7014165521, blue: 0.08948097378, alpha: 1)
        static let xColor: UIColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        static let opacityAnimationStart:Float = 0.1
        static let opacityAnimationEnd:Float = 0.9
        static let mediumAnimationDuration = 1.75
        static let shortAnimationDuration = 0.5
        static let lineWidth:CGFloat = 10.0

    }
    
    enum buttonLabel {
        static var loggedOut = "Authenticate"
        static var loggedIn = "Scan to register/log in"
    }
    
//    MARK: - VC properties

//    var currentAnimations:[CABasicAnimation] = []
    var registeredSites: [WebSite] = []
    lazy var safeAreaRect = view.frame.inset(by: view.safeAreaInsets)
    lazy var center = CGPoint(x: view.frame.midX, y:  view.frame.midY)
    lazy var radius = safeAreaRect.width/4

    var circleShapeLayer = CAShapeLayer()
    var endSymbol = CAShapeLayer()
    var isLoading = false
//    TODO: - I don't particulary like the following approach, maybe change it
    var isResponseOK = false //this will be used to decide how the animation will finish (green tick or red X)
    
    var currentStatus: String?{
        didSet{
            DispatchQueue.main.async{[weak self] in
                self?.statusLabel.text = self?.currentStatus
            }
            // remove the text after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {[weak self] in
                self?.removeStatusText()
                
            }
            
            
        }
    }

    // the app uses (biometric) authentication when started or moved to foreground
    enum AuthenticationState {
        case loggedin, loggedout
    }
    
    

    

    var loggedState: AuthenticationState = .loggedout{
        didSet{
            
            snapButton.setTitle(loggedState == .loggedin ? buttonLabel.loggedIn : buttonLabel.loggedOut,
                for: .normal)
            

        
            
        }
    }
    
    var logoutTimer: Timer?
    
    
//    var biometryType:String{
//        get{
//            let context = LAContext()
//            print("got context:\(context) and \(context.biometryType.rawValue)")
//            switch context.biometryType{
//            case .faceID:
//                print("got face")
//                return "faceID"
//            case .touchID:
//                return "touchID"
//            case .none:
//
//                return "Passcode"
//            default:
//                return "New Bio"
//            }
//        }
//    }
    
    
    
    
//    MARK: - Model properties
    
    var connectionManager:ConnectionManager?
    var cryptoManager:CryptoManager?
//    TODO: - create different key for each site(?)
    let tagString = Bundle.main.bundleIdentifier! + "-key"
    var context = LAContext() //used for the user authentication to the app
    

//    MARK: - outlets
    
    @IBOutlet var snapButton: CustomButton!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var infoItem: UIBarButtonItem!
    
    
//    MARK: - actions
    
    
    @IBAction func tabButton(_ sender: CustomButton) {
        removeStatusText()
        //if user is not authenticated, open touch/face id (or fallback to passcode)
        if loggedState == .loggedout{
               let context = LAContext()
                var error: NSError?
   
                if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                    let reason = "Need authentication for login or register"
                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                        [weak self] success, authenticationError in
                        
                        DispatchQueue.main.async{
                            if success {
                                self?.loggedState = .loggedin
                                self?.currentStatus = "user authenticated"
                                
                            }else {
                                // at this point we may have cancellation (app, system, user) or some type of error
                                var message = ""
                                if let error = authenticationError as? LAError{
                                    switch error.code {
                                    case .appCancel, .systemCancel, .userCancel:
                                        message = "Authentication cancelled: "
                                    default:
                                        message = "Error: "
                                    }
                                    
                                }
                                // alert the user that they are not authenticated
                                let authMessage = message + authenticationError!.localizedDescription
                                if let alertToPresent = self?.createAlert(title: "User not authenticated", message: authMessage){
                                    DispatchQueue.main.async {
                                        self?.present(alertToPresent, animated: true, completion: {
                                            
                                        })
                                    }
                                }

                                self?.loggedState = .loggedout
                                
                            }
                            
                        }
                    }
                }else {
                    
                    // since deviceOwnerAuthentication is used, even if biometrics are disabled or not supported
                    // an (automatic) fallback to passcode should never fail --> we don't expect to hit this part
                    currentStatus = "Unexpected error while evaluating policy"
                    loggedState = .loggedout
                }
                
            }
       
        

    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // renamed list-symbol to list.dash (identical name to the SF-symbol) in the assets
        // !!CHECK!! in < 13.0 if this does the trick (fallback)
//         if #available(iOS 13.0, *) {
//
//
//
// //            infoItem.image = UIImage(named: "list-icon")
//         } else {
//              // Fallback on earlier versions
//             let iconImage = UIImage(named: "list-symbol")
//             infoItem.image = iconImage
//
//
//         }
        

        let notificationCenter = NotificationCenter.default
        // check when app moves to background or becomes active again
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)

        
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)

        // Set the initial app state. This impacts the initial state of the UI as well.
        loggedState = .loggedout
        
//        create a cryptoManager
       
        cryptoManager = CryptoManager(tag: tagString)

//        create a connectionManager
        connectionManager = ConnectionManager()
        
        //load the registeredSites from userDefaults
        registeredSites = getRegisteredSites() ?? []
        
        
        //        create a few dummy Websites for testing purposes
        // let url1 = URL(string:"http://google.com")!
        // let url2 = URL(string:"http://amazon.com")!
        // let user1 = User(username: "george", keyTag: "5234234dewjihd87")
        // let user2 = User(username: "John", keyTag: "5234234dewjihd87")
        
//        let website1 = WebSite(url: url1, siteName: "google", user: user1, isRegistrationComplete: true, lastLoginAt: nil)
//        let website2 = WebSite(url: url1, siteName: "google", user: user2, isRegistrationComplete: true, lastLoginAt: Date())
//        let website3 = WebSite(url: url2, siteName: "amazon", user: user1, isRegistrationComplete: true, lastLoginAt: Date())
//        let website4 = WebSite(url: url2, siteName: "amazon", user: user2, isRegistrationComplete: true, lastLoginAt: Date())
        
//        registeredSites = [website1, website2, website3]
        


        
    
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.delegate = self
        
        // inform the user if crypto manager is not loaded
        // TODO: - maybe create an alert instead?
        if cryptoManager == nil {
            currentStatus = "Cannot initiate cryptographic functions.\nPlease restart the app.\nIf the problem persists, try restarting the phone"
            snapButton.isEnabled = false
         
        }

    

    }
    
    // MARK: - remove status text when user interacts again
    
    private func removeStatusText(){
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseOut) {
            self.statusLabel.layer.opacity = 0
        } completion: {  [weak self] finished in
            self?.statusLabel.text = ""
            self?.statusLabel.layer.opacity = 1
        }

        
    }
    
    

//    MARK: - methods called when app moves to background or foreground
    @objc func appMovedToBackground() {
        // logout if more than two seconds have passed
        logoutTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { timer in
            self.loggedState = .loggedout

        
        })

    }
    
    @objc func appMovedToForeground() {
        // invalidate the timer
        logoutTimer?.invalidate()

    }
    
    
// MARK: - segues
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
       
        if identifier == "take photo"
        {
            // need to be in logged state to scan for QR

            return loggedState == .loggedin
            
        }else {
        

            return true
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//       if we are segueing to RegisterdSitesTVC we need to pass the registeredSites array
        if segue.identifier == "show registered sites"{
            let targetVC = segue.destination as? RegisteredSitesTVC
            targetVC?.listOfRegisteredSites = registeredSites
        }
    
    }
//  MARK: - methods to read/write to user defaults
    
    private func getRegisteredSites(_ key:String = "registered_sites") -> [WebSite]?{
        if let data = UserDefaults.standard.data(forKey: key){
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([WebSite].self, from: data) {
                return decodedData
                
            }else{
                print("failed to decode websites from user defaults")
            }
            
        }else{
            print("failed to read registered sites from user defaults")
        }
        return nil
    }
    
    private func setRegisteredSites(_ websites:[WebSite], for key:String = "registered_sites"){
        let encoder = JSONEncoder()
        do{
            let data = try encoder.encode(registeredSites)
            UserDefaults.standard.set(data, forKey: key)
            
        }catch{
             print("cannot encode web sites")
        }
        

        
        
        
    }
    
    
//    MARK: - standard VC methods

    

     
    
    @IBAction func 	unwindToMainViewController(segue: UIStoryboardSegue){
        if cryptoManager == nil {
            currentStatus = "Crypto is not active, please restart the app.\nIf the problem persists try restarting the phone"
            return
        }
        var alert:UIAlertController? = nil
        if let segue = segue as? UIStoryBoardSegueWithCompletion{
            // on completion of segway (source VC dismissed) present the alert if any
            segue.completion = {
                if let alertToPresent = alert {
                    DispatchQueue.main.async {
                        self.present(alertToPresent, animated: true)
                    }
                    
                }
                
            }
        }
        if let sourceController = segue.source as? ScannerViewController{
            
            if let qrCode = sourceController.qrCode{
                // got a qrCode. Process it
                // check if this is a login or a register qr
                
                switch qrCode.request {
                    
                case .login(let loginRequest):
                                      
                    // TODO: - handle multiple users for the same site
                    // check if token has expired
                    let now = Date()
                    if now > loginRequest.validTill{
                        alert = createAlert(title: "Token has expired", message: "Reload the page to get a new token")
                        return
                    }
                    // check if the user is already registered
                    if let registeredSite = registeredSites.first(where: {$0.siteName == loginRequest.provider})
                    
                    {

                        // ok, moving on
                        isLoading = true
                        startLoading()
                        // !!CHECK!!: maybe better to have the respondTo for login defined in registration as well?
                        let url = loginRequest.respondTo
                        // get the username
                        let username = registeredSite.user.username
                        //  sign the challenge
                        let challenge = loginRequest.challenge
                        guard let response = try? cryptoManager!.sign(challenge) else{

                            // failed to sign the challenge
                            isResponseOK = false
                            currentStatus = "Failed to sign the challenge"
                            isLoading = false
                            return
                        }

                        
                        // send login request to server
                        connectionManager?.login(to: url,
                                                 for: username,
                                                 challenge: challenge,
                                                 response: response,
                        { (error, response) in
                            // We have received a response. Stop animating when it is time
                            self.isLoading = false
                            if let error = error{
                                // some kind of error from the server, present it to the user
                                alert = self.createAlert(title: "Server error", message: "Server responded with error: \(error.errorDescription ?? "unknown error")")
                                self.isResponseOK = false

                            }else{
                                if let response = response{
                                    
                                    if response.status == .nok{
                                        self.currentStatus = "server responded with \(response.responseText)"
                                        self.isResponseOK = false
                                        
                                    }else{
                                        // ok received from the server, user is logged in
                                        self.currentStatus = "logged in \(registeredSite.siteName) as \(registeredSite.user.username)"
                                        self.isResponseOK = true

                                        // update the value in the registeredSites array

                                        var updatedSite = registeredSite
                                        // update the lastLogin value (now)
                                        updatedSite.lastLoginAt = Date()
                                        if let index = self.registeredSites.firstIndex(where: {($0.siteName == updatedSite.siteName)}){
                                            updatedSite.lastLoginAt = Date()
                                            self.registeredSites[index] = updatedSite
                                            self.setRegisteredSites(self.registeredSites)
                                        }
                                        


                                    }
                                }
                                
                                
                            }
                                                    
                                                    
                                                    
                                                    
                                                    
                        })
                    
                    }else{
                        // not registered, cannot move to login action
                        currentStatus = "Not registered to \(loginRequest.provider). Please register first"
                        alert = createAlert(title: "Not registered", message: "You need to registered first to \(loginRequest.provider)")
                        
                    }
                
                case .register(let registerRequest):
                    // check if we are already registered to this site
                    var matchedWebsite: WebSite? = nil
                    if registeredSites.contains(where: { (website) -> Bool in
                        if website.siteName == registerRequest.provider{
                            matchedWebsite = website
                            return true
                        }else{
                            return false
                        }
                        
                    }){
                        // user already registered. notify them
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .medium
                        dateFormatter.timeZone = .current
                        let registeredAt = dateFormatter.string(from: matchedWebsite!.registeredAt)
                         alert = createAlert(title: "Already registerd", message: "You were previously registered to \(registerRequest.provider) at:\(registeredAt)")
                        isResponseOK = true
                        isLoading = false
                        
                    }else{
                        // user is not registered, sending a registration request
                        isLoading = true
                        startLoading()
                        let url = registerRequest.respondTo
                        let siteName = registerRequest.provider
                        let email = registerRequest.email
                        let nonce = registerRequest.nonce
                        currentStatus = "will try to register to:\(siteName) with email:\(email) and nonce:\(nonce)"
                        if let publicKey = cryptoManager!.exportPublicKey(){
                            connectionManager?.register(to: url,
                                                        for: email, with: publicKey,
                                                        and: nonce, { (error, response) in
                            //                            add it to registered sites
                            //                            TODO: - do not add it if registration failed.
                            
                            // We have received a response. Stop animating when it is time
                            self.isLoading = false
                            if let error = error{
                                print("Error receiving data from server: \(error)")
                                self.currentStatus = "Server error (\(error))"
                                self.isResponseOK = false
                                alert = self.createAlert(title: "Server Error", message: "Server responded with:\(error.description)")

                                
                            }else{
                                if let response = response{
                                    // received response
                                    if response.status == .nok{
                                        
                                        self.currentStatus = "server responded with \(response.responseText)"
                                        self.isResponseOK = false
                                        
                                    }else{
                                        print("ok received from server")
                                        self.currentStatus = "server responded with \(response.responseText)"
                                        self.isResponseOK = true
                                        // add an entry in the registered sites
                                        let user = User(username: email, keyTag: self.tagString)
                                        let website = WebSite(url: registerRequest.respondTo, siteName: siteName, user: user, isRegistrationComplete: false, lastLoginAt: nil , registeredAt: Date())
                                        self.registeredSites.append(website)
                                        self.setRegisteredSites(self.registeredSites)
                                    }
                                }
                                
                                // server reposnded with no error and no response text
                                print("no error but also no response text from server")
                                
                            }
                            
                            
                            

                                                        
                            })
                            
                            
                        }else{
                            

                            alert = createAlert(title: "Public Key Error", message: "Could not retrieve public key. Aborting registration")
                            

                            
                        }
                        
                        
                        
                        
                        
                        
                        
                    }
                
                case .none:
                // !!CHECK
                
                    alert = createAlert(title: "No action defined", message: "QR code doesn't define neither login not registration action")
                
                
                }
                

            }else{
                // no qr code scanned. user probably cancelled the operation
                currentStatus = "No QR code scanned"
                
            }
        }else{
            print("no source controller")
            return
        }
        
        
        
    }
    
    
//    MARK: - Alerts
    
   private func createAlert(title: String, message:String) -> UIAlertController{
        
        let alertMessage = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .cancel) { action in
            
        }
        alertMessage.addAction(action)
        return alertMessage
        
    }
    

// MARK: - animations

    /// will create and animate the circle loading animation
    /// animations are executed once and repeated
    /// if we are still in loading mode (see animationDidStop)
    private func startLoading(){

        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.statusLabel.text = "Waiting for server's response, please wait"
            
            
            //hide the button
            self.snapButton.isHidden = true
            
            // create a circle layer and add it to the view
            self.circleShapeLayer = self.createCircle(on: self.center, with: self.radius, and: defaults.circleColor)
            self.view.layer.addSublayer(self.circleShapeLayer)
            
            // set up the animations
            CATransaction.begin()
            CATransaction.setAnimationDuration(defaults.mediumAnimationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            // 1. stroke path from beginning to end
            self.circleShapeLayer.strokeEnd = 0
            let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeAnimation.fromValue = 0
            strokeAnimation.toValue = 1
            strokeAnimation.isRemovedOnCompletion = false
            strokeAnimation.fillMode = .forwards
            strokeAnimation.delegate = self
            // 2. path opacity from transparent to opaque
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = defaults.opacityAnimationStart
            opacityAnimation.toValue = defaults.opacityAnimationEnd
            opacityAnimation.duration = defaults.mediumAnimationDuration
            opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            // 3. status label text opacity (blinking text effect)
            let textOpacityAnimation = CABasicAnimation(keyPath: "opacity")
            textOpacityAnimation.toValue = defaults.opacityAnimationStart
            textOpacityAnimation.duration = defaults.mediumAnimationDuration
            // add the animations
            self.circleShapeLayer.add(strokeAnimation, forKey: "stroke")
            self.circleShapeLayer.add(opacityAnimation, forKey: "opacity")
            self.statusLabel.layer.add(textOpacityAnimation, forKey: "text opacity")
            CATransaction.commit()
            
        }

    }

    /// stop circle animation and initiate a green tick animation if response is ok
    /// or a red X if not
    private func stopLoading(){
        
        
        DispatchQueue.main.async {[weak self] in
            
            guard let self = self else{ return}
            self.isLoading = false
            let finalColor:UIColor = self.isResponseOK ?
                defaults.tickColor :
                defaults.xColor
            let duration = defaults.shortAnimationDuration
            // set up the animation
            CATransaction.begin()
            CATransaction.setAnimationDuration(defaults.shortAnimationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            // endSymbol is either tick (response ok), or X (response nok)
            self.endSymbol = self.isResponseOK ?
                self.createTickInCircle(on: self.center, with: self.radius, and: finalColor) :
                self.createXinCircle(on: self.center, with: self.radius, and: defaults.xColor)
            self.view.layer.addSublayer(self.endSymbol)
            // 1. symbol path stroke animation
            let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeAnimation.fromValue = 0
            strokeAnimation.toValue = 1
            strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            // 2. circle color animation to end color
            let colorAnimation = CABasicAnimation(keyPath: "strokeColor")
            colorAnimation.toValue = finalColor.cgColor
            colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            colorAnimation.isRemovedOnCompletion = false
            colorAnimation.fillMode = .forwards
            // 3. opacity animation for circle and symbol (fade out)
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 1
            opacityAnimation.toValue = 0
            opacityAnimation.fillMode = .backwards  // we want the opacity to have the fromValue before animation starts
            // will start with a little bit of delay
            opacityAnimation.beginTime = CACurrentMediaTime() + duration + 0.2
            
            //opacity animation will be the last to stop so it should have the delegate
            //        opacityAnimation.delegate = self
            CATransaction.setCompletionBlock {
                self.endSymbol.removeAllAnimations()
                self.circleShapeLayer.removeAllAnimations()
                self.circleShapeLayer.removeFromSuperlayer()
                self.endSymbol.removeFromSuperlayer()
                // show again the button
                self.snapButton.isHidden = false
                // set the status text
                // !!CHECK!! do we need the following?
                // self.statusLabel.text = self.currentStatus
            }
            // add the animations
            self.endSymbol.add(opacityAnimation, forKey: "fade out symbol")
            self.endSymbol.opacity = 0
            self.circleShapeLayer.add(opacityAnimation, forKey: "fade out circle")
            self.circleShapeLayer.opacity = 0
            self.circleShapeLayer.add(colorAnimation, forKey: "color circle")
            self.endSymbol.add(strokeAnimation, forKey: "symbol tick")

            CATransaction.commit()
            
        }

        
    }
    
    /// delegate method called when animation stops
    /// if we are still in loading mode start anew
    /// else call stopLoading()
    ///
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {

        if isLoading{
            CATransaction.begin()
            CATransaction.setAnimationDuration(defaults.mediumAnimationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            circleShapeLayer.strokeEnd = 0
            let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeAnimation.toValue = 1
            strokeAnimation.isRemovedOnCompletion = false
            strokeAnimation.fillMode = .forwards
            strokeAnimation.delegate = self

            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            var currentOpacity = circleShapeLayer.opacity
            var targetOpacity:Float = 0.0
            if currentOpacity == defaults.opacityAnimationEnd{
                // opacity is set at maximum opacity flip start and end
                currentOpacity = defaults.opacityAnimationEnd
                targetOpacity = defaults.opacityAnimationStart
            }else{
                currentOpacity = defaults.opacityAnimationStart
                targetOpacity = defaults.opacityAnimationEnd
                
            }

            opacityAnimation.fromValue = currentOpacity
            opacityAnimation.toValue = targetOpacity
            opacityAnimation.duration = defaults.mediumAnimationDuration
            opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let textOpacityAnimation = CABasicAnimation(keyPath: "opacity")
            textOpacityAnimation.toValue = defaults.opacityAnimationStart
            textOpacityAnimation.duration = defaults.mediumAnimationDuration

            circleShapeLayer.add(strokeAnimation, forKey: "stroke")
            //        shapeLayer.add(colorAnimation, forKey: "color")
            circleShapeLayer.add(opacityAnimation, forKey: "opacity")
            //        shapeLayer.add(secondStrokeAnimation, forKey:nil)
            statusLabel.layer.add(textOpacityAnimation, forKey: "text opacity")
            CATransaction.commit()
            
        }else{
            
            stopLoading()
        }

    }


    
    // MARK: - drawing
    
    /// returns a cicrle CAShapeLayer
    /// - Parameters:
    ///   - center:
    ///   - radius:
    ///   - color:
    /// - Returns: the CAShapeLayer
    private func createCircle(on center:CGPoint,  with radius:CGFloat, and color:UIColor ) -> CAShapeLayer{
        
        let circularPath = UIBezierPath(arcCenter: center, radius: radius , startAngle: -CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circularPath.cgPath
        
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = defaults.lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        shapeLayer.lineCap = .round
        return shapeLayer
        
        
    }

    /// returns a tick CAShapeLayer within a circle's boundaries
    /// - Parameters:
    ///   - center: center of the circle bounds
    ///   - radius: radius of the circle bounds
    ///   - color: color of the path
    /// - Returns: the CAShapeLayer
    private func createTickInCircle(on center:CGPoint, with radius:CGFloat, and color:UIColor) -> CAShapeLayer{
        let shapeLayer = CAShapeLayer()
        let lowestPoint = CGPoint(x: center.x, y: center.y + radius/2)
        let leftHighPoint = CGPoint(x: center.x - 0.9*radius/2, y: center.y)
        let rightHighPoint = CGPoint(x: center.x + radius/2, y: lowestPoint.y - radius)
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = defaults.lineWidth
        shapeLayer.lineCap = .round
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        let path = CGMutablePath()
        path.move(to: leftHighPoint)
        path.addLine(to: lowestPoint)
        path.addLine(to: rightHighPoint)
        shapeLayer.path = path
        return shapeLayer
        
    }
    
    /// returns an "X" CAShapeLayer within a circle's boundaries
    /// - Parameters:
    ///   - center: center of the circle bounds
    ///   - radius: radius of the circle bounds
    ///   - color: color of the path
    /// - Returns: the CAShapeLayer
    private func createXinCircle(on center:CGPoint, with radius:CGFloat, and color:UIColor) -> CAShapeLayer{
        let shapeLayer = CAShapeLayer()
        let radiusRatio:CGFloat = 0.5
        let leftHighPoint = CGPoint(x: center.x - radiusRatio*radius, y: center.y - radiusRatio*radius)
        let leftLowPoint = CGPoint(x: center.x - radiusRatio*radius, y: center.y + radiusRatio*radius)
        let rightHightPoint = CGPoint(x: center.x + radiusRatio*radius, y: center.y - radiusRatio*radius)
        let rightLowPoint = CGPoint(x: center.x + radiusRatio*radius, y: center.y + radiusRatio*radius)

        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = defaults.lineWidth
        shapeLayer.lineCap = .round
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        let path = CGMutablePath()
        path.move(to: leftHighPoint)
        path.addLine(to: rightLowPoint)
        path.move(to: rightHightPoint)
        path.addLine(to: leftLowPoint)
        shapeLayer.path = path

        return shapeLayer
        
    }


    private func startApllicationsInParallel(animations:[CABasicAnimation]){
        
    }


}



//extension UIView {
//    @IBInspectable var cornerRadius: CGFloat {
//        get {
//            return layer.cornerRadius
//        }
//        set {
//            layer.cornerRadius = newValue
//            layer.masksToBounds = newValue > 0
//        }
//    }
//    
//    @IBInspectable var maskedCorners: CACornerMask {
//        get{
//            return layer.maskedCorners
//        }
//        set{
//            layer.maskedCorners = newValue
//        }
//    }
//}

